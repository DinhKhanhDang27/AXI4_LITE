`timescale 1ns/1ps

module tb_axi_register_bank;
    localparam int DATA_WIDTH = 32;
    localparam int ADDR_WIDTH = 6;

    localparam logic [ADDR_WIDTH-1:0] ADDR_CTRL   = 6'h00;
    localparam logic [ADDR_WIDTH-1:0] ADDR_STATUS = 6'h04;
    localparam logic [ADDR_WIDTH-1:0] ADDR_A      = 6'h08;
    localparam logic [ADDR_WIDTH-1:0] ADDR_B      = 6'h0C;
    localparam logic [ADDR_WIDTH-1:0] ADDR_OPCODE = 6'h10;
    localparam logic [ADDR_WIDTH-1:0] ADDR_RESULT = 6'h14;
    localparam logic [ADDR_WIDTH-1:0] ADDR_BAD    = 6'h3C;

    logic clk;
    logic rst_n;
    logic wr_en;
    logic [ADDR_WIDTH-1:0] wr_addr;
    logic [DATA_WIDTH-1:0] wr_data;
    logic [(DATA_WIDTH/8)-1:0] wr_strb;
    logic [ADDR_WIDTH-1:0] rd_addr;
    logic [DATA_WIDTH-1:0] rd_data;
    logic start_pulse;
    logic [DATA_WIDTH-1:0] operand_a;
    logic [DATA_WIDTH-1:0] operand_b;
    logic [3:0] opcode;
    logic [DATA_WIDTH-1:0] core_result;
    logic core_done;
    logic core_error;

    int errors;
    int unsigned seed;

    function automatic logic [DATA_WIDTH-1:0] apply_strb_model(
        input logic [DATA_WIDTH-1:0] old_data,
        input logic [DATA_WIDTH-1:0] new_data,
        input logic [(DATA_WIDTH/8)-1:0] strb
    );
        logic [DATA_WIDTH-1:0] merged;

        merged = old_data;
        for (int i = 0; i < DATA_WIDTH/8; i++) begin
            if (strb[i]) begin
                merged[i*8 +: 8] = new_data[i*8 +: 8];
            end
        end

        return merged;
    endfunction

    function automatic int unsigned rand32();
        seed = (seed * 32'd1664525) + 32'd1013904223;
        return seed;
    endfunction

    axi_register_bank #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk,
        .rst_n,
        .wr_en,
        .wr_addr,
        .wr_data,
        .wr_strb,
        .rd_addr,
        .rd_data,
        .start_pulse,
        .operand_a,
        .operand_b,
        .opcode,
        .core_result,
        .core_done,
        .core_error
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic check(input string name, input bit ok);
        if (!ok) begin
            errors++;
            $error("FAIL: %s", name);
        end else begin
            $display("PASS: %s", name);
        end
    endtask

    task automatic reset_dut;
        wr_en = 1'b0;
        wr_addr = '0;
        wr_data = '0;
        wr_strb = '0;
        rd_addr = '0;
        core_result = '0;
        core_done = 1'b0;
        core_error = 1'b0;
        rst_n = 1'b0;
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);
    endtask

    task automatic bus_write(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] data,
        input logic [(DATA_WIDTH/8)-1:0] strb
    );
        @(negedge clk);
        wr_addr = addr;
        wr_data = data;
        wr_strb = strb;
        wr_en = 1'b1;
        @(negedge clk);
        wr_en = 1'b0;
        wr_addr = '0;
        wr_data = '0;
        wr_strb = '0;
    endtask

    task automatic read_check(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] exp,
        input string name
    );
        rd_addr = addr;
        #1;
        check(name, rd_data === exp);
    endtask

    task automatic complete_core(
        input logic [DATA_WIDTH-1:0] result,
        input logic error
    );
        @(negedge clk);
        core_result = result;
        core_error = error;
        core_done = 1'b1;
        @(negedge clk);
        core_done = 1'b0;
        core_result = '0;
        core_error = 1'b0;
    endtask

    task automatic random_register_tests(input int iterations);
        logic [DATA_WIDTH-1:0] exp_a;
        logic [DATA_WIDTH-1:0] exp_b;
        logic [DATA_WIDTH-1:0] exp_result;
        logic [3:0] exp_opcode;
        logic [2:0] exp_status;
        logic [DATA_WIDTH-1:0] data;
        logic [(DATA_WIDTH/8)-1:0] strb;
        logic [ADDR_WIDTH-1:0] addr;
        logic done_error;
        int choice;

        exp_a = operand_a;
        exp_b = operand_b;
        exp_opcode = opcode;
        exp_result = 32'h0;
        exp_status = 3'b110;

        for (int i = 0; i < iterations; i++) begin
            choice = rand32() % 9;
            data = rand32();
            strb = rand32();
            if (strb == 4'b0000) begin
                strb = 4'b0001 << (rand32() % 4);
            end

            case (choice)
                0, 1: begin
                    bus_write(ADDR_A, data, strb);
                    exp_a = apply_strb_model(exp_a, data, strb);
                    read_check(ADDR_A, exp_a, "random operand A byte lanes");
                end
                2, 3: begin
                    bus_write(ADDR_B, data, strb);
                    exp_b = apply_strb_model(exp_b, data, strb);
                    read_check(ADDR_B, exp_b, "random operand B byte lanes");
                end
                4: begin
                    bus_write(ADDR_OPCODE, data, strb);
                    if (strb[0]) begin
                        exp_opcode = data[3:0];
                    end
                    read_check(ADDR_OPCODE, {{DATA_WIDTH-4{1'b0}}, exp_opcode}, "random opcode low nibble");
                end
                5: begin
                    bus_write(ADDR_CTRL, data | 32'h1, strb | 4'b0001);
                    @(posedge clk);
                    check("random start when idle", start_pulse == 1'b1);
                    exp_status = 3'b001;

                    bus_write(ADDR_CTRL, 32'h1, 4'b1111);
                    @(posedge clk);
                    check("random busy rejects restart", start_pulse == 1'b0);

                    exp_result = rand32();
                    done_error = rand32() & 1;
                    complete_core(exp_result, done_error);
                    exp_status = done_error ? 3'b110 : 3'b010;
                    read_check(ADDR_STATUS, {{DATA_WIDTH-3{1'b0}}, exp_status}, "random completion status");
                    read_check(ADDR_RESULT, exp_result, "random completion result");
                end
                6: begin
                    addr = ADDR_STATUS;
                    bus_write(addr, data, strb);
                    read_check(ADDR_STATUS, {{DATA_WIDTH-3{1'b0}}, exp_status}, "random status write ignored");
                end
                7: begin
                    addr = ADDR_RESULT;
                    bus_write(addr, data, strb);
                    read_check(ADDR_RESULT, exp_result, "random result write ignored");
                end
                default: begin
                    addr = rand32();
                    addr = (addr ^ ADDR_BAD) & 6'h3F;
                    if (addr inside {ADDR_CTRL, ADDR_STATUS, ADDR_A, ADDR_B, ADDR_OPCODE, ADDR_RESULT}) begin
                        addr = ADDR_BAD;
                    end
                    bus_write(addr, data, strb);
                    read_check(addr, 32'h0, "random invalid address reads zero");
                    read_check(ADDR_A, exp_a, "random invalid write leaves operand A");
                    read_check(ADDR_B, exp_b, "random invalid write leaves operand B");
                end
            endcase
        end
    endtask

    initial begin
        errors = 0;
        seed = 32'hA51C_0D3D;
        reset_dut();

        check("reset operand/status/start", operand_a == 0 && operand_b == 0 && opcode == 0 && start_pulse == 0);
        read_check(ADDR_STATUS, 32'h0, "reset status read");
        read_check(ADDR_RESULT, 32'h0, "reset result read");

        bus_write(ADDR_A, 32'h1122_3344, 4'b1111);
        read_check(ADDR_A, 32'h1122_3344, "write/read operand A");

        bus_write(ADDR_A, 32'hAAAA_5555, 4'b0101);
        read_check(ADDR_A, 32'h11AA_3355, "byte-enable partial operand A");

        bus_write(ADDR_B, 32'hCAFE_BABE, 4'b1111);
        read_check(ADDR_B, 32'hCAFE_BABE, "write/read operand B");

        bus_write(ADDR_OPCODE, 32'hFFFF_FF03, 4'b1111);
        read_check(ADDR_OPCODE, 32'h3, "opcode keeps low nibble");

        bus_write(ADDR_OPCODE, 32'h0000_000A, 4'b1110);
        read_check(ADDR_OPCODE, 32'h3, "opcode unchanged when byte 0 strobe is clear");

        bus_write(ADDR_CTRL, 32'h1, 4'b1111);
        @(posedge clk);
        check("start pulse asserted for one cycle", start_pulse == 1'b1);
        @(posedge clk);
        check("start pulse clears", start_pulse == 1'b0);
        read_check(ADDR_STATUS, 32'h1, "status busy after start");

        bus_write(ADDR_CTRL, 32'h1, 4'b1111);
        @(posedge clk);
        check("start ignored while busy", start_pulse == 1'b0);

        @(negedge clk);
        core_result = 32'hDEAD_BEEF;
        core_error = 1'b0;
        core_done = 1'b1;
        @(negedge clk);
        core_done = 1'b0;
        core_result = '0;
        read_check(ADDR_STATUS, 32'h2, "status done without error");
        read_check(ADDR_RESULT, 32'hDEAD_BEEF, "result latched on done");

        bus_write(ADDR_CTRL, 32'h0, 4'b1111);
        @(posedge clk);
        check("ctrl zero does not start", start_pulse == 1'b0);

        bus_write(ADDR_CTRL, 32'h1, 4'b1111);
        @(posedge clk);
        check("start after done accepted", start_pulse == 1'b1);
        @(negedge clk);
        core_result = 32'h0;
        core_error = 1'b1;
        core_done = 1'b1;
        @(negedge clk);
        core_done = 1'b0;
        core_error = 1'b0;
        read_check(ADDR_STATUS, 32'h6, "status done with error");
        read_check(ADDR_RESULT, 32'h0, "error result latched");

        bus_write(ADDR_BAD, 32'hFFFF_FFFF, 4'b1111);
        read_check(ADDR_BAD, 32'h0, "invalid read returns zero");
        read_check(ADDR_A, 32'h11AA_3355, "invalid write does not corrupt A");

        random_register_tests(80);

        if (errors == 0) begin
            $display("tb_axi_register_bank PASSED");
            $finish;
        end
        $fatal(1, "tb_axi_register_bank FAILED with %0d errors", errors);
    end
endmodule
