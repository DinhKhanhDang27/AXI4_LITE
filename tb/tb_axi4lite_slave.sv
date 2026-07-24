`timescale 1ns/1ps

module tb_axi4lite_slave;
    localparam int ADDR_WIDTH = 6;
    localparam int DATA_WIDTH = 32;

    logic aclk;
    logic aresetn;
    logic [ADDR_WIDTH-1:0] s_axi_awaddr;
    logic s_axi_awvalid;
    logic s_axi_awready;
    logic [DATA_WIDTH-1:0] s_axi_wdata;
    logic [(DATA_WIDTH/8)-1:0] s_axi_wstrb;
    logic s_axi_wvalid;
    logic s_axi_wready;
    logic [1:0] s_axi_bresp;
    logic s_axi_bvalid;
    logic s_axi_bready;
    logic [ADDR_WIDTH-1:0] s_axi_araddr;
    logic s_axi_arvalid;
    logic s_axi_arready;
    logic [DATA_WIDTH-1:0] s_axi_rdata;
    logic [1:0] s_axi_rresp;
    logic s_axi_rvalid;
    logic s_axi_rready;
    logic wr_en;
    logic [ADDR_WIDTH-1:0] wr_addr;
    logic [DATA_WIDTH-1:0] wr_data;
    logic [(DATA_WIDTH/8)-1:0] wr_strb;
    logic [ADDR_WIDTH-1:0] rd_addr;
    logic [DATA_WIDTH-1:0] rd_data;

    int errors;
    int wr_pulses;
    int unsigned seed;

    axi4lite_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (.*);

    initial aclk = 1'b0;
    always #5 aclk = ~aclk;

    always @(posedge aclk) begin
        if (aresetn && wr_en) begin
            wr_pulses++;
        end
    end

    function automatic int unsigned rand32();
        seed = (seed * 32'd1664525) + 32'd1013904223;
        return seed;
    endfunction

    task automatic check(input string name, input bit ok);
        if (!ok) begin
            errors++;
            $error("FAIL: %s", name);
        end else begin
            $display("PASS: %s", name);
        end
    endtask

    task automatic reset_dut;
        s_axi_awaddr = '0;
        s_axi_awvalid = 1'b0;
        s_axi_wdata = '0;
        s_axi_wstrb = '0;
        s_axi_wvalid = 1'b0;
        s_axi_bready = 1'b0;
        s_axi_araddr = '0;
        s_axi_arvalid = 1'b0;
        s_axi_rready = 1'b0;
        rd_data = '0;
        wr_pulses = 0;
        aresetn = 1'b0;
        repeat (3) @(posedge aclk);
        aresetn = 1'b1;
        @(posedge aclk);
    endtask

    task automatic wait_write_pulse(
        input logic [ADDR_WIDTH-1:0] exp_addr,
        input logic [DATA_WIDTH-1:0] exp_data,
        input logic [(DATA_WIDTH/8)-1:0] exp_strb,
        input string name
    );
        do begin
            @(posedge aclk);
            #1;
        end while (!wr_en);
        #1;
        check({name, " wr_en"}, wr_addr == exp_addr && wr_data == exp_data && wr_strb == exp_strb);
        @(posedge aclk);
        #1;
        check({name, " wr_en one cycle"}, wr_en == 1'b0);
    endtask

    task automatic axi_write_aw_first(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] data,
        input logic [(DATA_WIDTH/8)-1:0] strb
    );
        @(negedge aclk);
        s_axi_awaddr = addr;
        s_axi_awvalid = 1'b1;
        @(posedge aclk);
        @(negedge aclk);
        s_axi_awvalid = 1'b0;
        s_axi_wdata = data;
        s_axi_wstrb = strb;
        s_axi_wvalid = 1'b1;
        @(posedge aclk);
        @(negedge aclk);
        s_axi_wvalid = 1'b0;
        wait_write_pulse(addr, data, strb, "AW before W");
        check("BVALID held before BREADY", s_axi_bvalid == 1'b1);
        repeat (2) @(posedge aclk);
        check("BVALID still held", s_axi_bvalid == 1'b1);
        @(negedge aclk);
        s_axi_bready = 1'b1;
        @(posedge aclk);
        @(negedge aclk);
        s_axi_bready = 1'b0;
        check("BRESP OKAY", s_axi_bresp == 2'b00);
    endtask

    task automatic axi_write_w_first(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] data,
        input logic [(DATA_WIDTH/8)-1:0] strb
    );
        @(negedge aclk);
        s_axi_wdata = data;
        s_axi_wstrb = strb;
        s_axi_wvalid = 1'b1;
        @(posedge aclk);
        @(negedge aclk);
        s_axi_wvalid = 1'b0;
        s_axi_awaddr = addr;
        s_axi_awvalid = 1'b1;
        @(posedge aclk);
        @(negedge aclk);
        s_axi_awvalid = 1'b0;
        wait_write_pulse(addr, data, strb, "W before AW");
        s_axi_bready = 1'b1;
        @(posedge aclk);
        @(negedge aclk);
        s_axi_bready = 1'b0;
    endtask

    task automatic axi_write_same_cycle(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] data,
        input logic [(DATA_WIDTH/8)-1:0] strb
    );
        @(negedge aclk);
        s_axi_awaddr = addr;
        s_axi_awvalid = 1'b1;
        s_axi_wdata = data;
        s_axi_wstrb = strb;
        s_axi_wvalid = 1'b1;
        @(posedge aclk);
        @(negedge aclk);
        s_axi_awvalid = 1'b0;
        s_axi_wvalid = 1'b0;
        wait_write_pulse(addr, data, strb, "AW and W same cycle");
        s_axi_bready = 1'b1;
        @(posedge aclk);
        @(negedge aclk);
        s_axi_bready = 1'b0;
    endtask

    task automatic axi_read(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] data,
        input string name
    );
        @(negedge aclk);
        rd_data = data;
        s_axi_araddr = addr;
        s_axi_arvalid = 1'b1;
        @(posedge aclk);
        while (!s_axi_arready) @(posedge aclk);
        @(negedge aclk);
        s_axi_arvalid = 1'b0;
        wait (s_axi_rvalid);
        check({name, " address"}, rd_addr == addr);
        check({name, " data/resp"}, s_axi_rdata == data && s_axi_rresp == 2'b00);
        check({name, " RVALID held"}, s_axi_rvalid == 1'b1);
        repeat (2) @(posedge aclk);
        check({name, " RVALID held during stall"}, s_axi_rvalid == 1'b1);
        @(negedge aclk);
        s_axi_rready = 1'b1;
        @(posedge aclk);
        @(negedge aclk);
        s_axi_rready = 1'b0;
    endtask

    task automatic axi_write_random(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] data,
        input logic [(DATA_WIDTH/8)-1:0] strb,
        input int aw_delay,
        input int w_delay,
        input int bready_delay
    );
        fork
            begin
                repeat (aw_delay) @(posedge aclk);
                @(negedge aclk);
                s_axi_awaddr = addr;
                s_axi_awvalid = 1'b1;
                @(posedge aclk);
                while (!s_axi_awready) @(posedge aclk);
                @(negedge aclk);
                s_axi_awvalid = 1'b0;
            end
            begin
                repeat (w_delay) @(posedge aclk);
                @(negedge aclk);
                s_axi_wdata = data;
                s_axi_wstrb = strb;
                s_axi_wvalid = 1'b1;
                @(posedge aclk);
                while (!s_axi_wready) @(posedge aclk);
                @(negedge aclk);
                s_axi_wvalid = 1'b0;
            end
        join

        wait_write_pulse(addr, data, strb, "random AXI write");
        check("random BVALID asserted", s_axi_bvalid == 1'b1);
        repeat (bready_delay) begin
            @(posedge aclk);
            check("random BVALID held during stall", s_axi_bvalid == 1'b1 && s_axi_bresp == 2'b00);
        end
        @(negedge aclk);
        s_axi_bready = 1'b1;
        @(posedge aclk);
        @(negedge aclk);
        s_axi_bready = 1'b0;
    endtask

    task automatic axi_read_random(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] data,
        input int ar_delay,
        input int rready_delay
    );
        repeat (ar_delay) @(posedge aclk);
        @(negedge aclk);
        rd_data = data;
        s_axi_araddr = addr;
        s_axi_arvalid = 1'b1;
        @(posedge aclk);
        while (!s_axi_arready) @(posedge aclk);
        @(negedge aclk);
        s_axi_arvalid = 1'b0;

        wait (s_axi_rvalid);
        check("random read address", rd_addr == addr);
        check("random read data/resp", s_axi_rdata == data && s_axi_rresp == 2'b00);
        repeat (rready_delay) begin
            @(posedge aclk);
            check("random RVALID held during stall", s_axi_rvalid == 1'b1 && s_axi_rdata == data);
        end
        @(negedge aclk);
        s_axi_rready = 1'b1;
        @(posedge aclk);
        @(negedge aclk);
        s_axi_rready = 1'b0;
    endtask

    task automatic random_axi_tests(input int iterations);
        logic [ADDR_WIDTH-1:0] addr;
        logic [DATA_WIDTH-1:0] data;
        logic [(DATA_WIDTH/8)-1:0] strb;
        int aw_delay;
        int w_delay;
        int resp_delay;

        for (int i = 0; i < iterations; i++) begin
            addr = rand32();
            data = rand32();
            strb = rand32();
            if (strb == 4'b0000) begin
                strb = 4'b0001 << (rand32() % 4);
            end
            aw_delay = rand32() % 4;
            w_delay = rand32() % 4;
            resp_delay = rand32() % 4;

            if ((rand32() & 1) == 0) begin
                axi_write_random(addr, data, strb, aw_delay, w_delay, resp_delay);
            end else begin
                axi_read_random(addr, data, aw_delay, resp_delay);
            end
        end
    endtask

    initial begin
        errors = 0;
        seed = 32'h4A11_5EED;
        reset_dut();

        check("reset outputs", !s_axi_bvalid && !s_axi_rvalid && !wr_en && s_axi_awready && s_axi_wready && s_axi_arready);

        axi_write_aw_first(6'h08, 32'h1111_2222, 4'b1111);
        axi_write_w_first(6'h0C, 32'h3333_4444, 4'b0011);
        axi_write_same_cycle(6'h10, 32'h0000_0003, 4'b1111);
        axi_write_same_cycle(6'h14, 32'h5555_AAAA, 4'b1111);

        axi_read(6'h04, 32'hCAFE_BABE, "read transaction");
        axi_read(6'h14, 32'h1234_5678, "back-to-back read");

        random_axi_tests(80);

        if (errors == 0) begin
            $display("tb_axi4lite_slave PASSED");
            $finish;
        end
        $fatal(1, "tb_axi4lite_slave FAILED with %0d errors", errors);
    end
endmodule
