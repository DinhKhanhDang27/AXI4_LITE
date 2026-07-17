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

    initial begin
        errors = 0;
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

        if (errors == 0) begin
            $display("tb_axi_register_bank PASSED");
            $finish;
        end
        $fatal(1, "tb_axi_register_bank FAILED with %0d errors", errors);
    end
endmodule
