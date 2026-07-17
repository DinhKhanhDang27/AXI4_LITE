`timescale 1ns/1ps

module tb_avalon_axi4lite_bridge;
    localparam int ADDR_WIDTH = 6;
    localparam int DATA_WIDTH = 32;

    logic clk;
    logic reset_n;
    logic [ADDR_WIDTH-1:0] avs_address;
    logic avs_read;
    logic avs_write;
    logic [DATA_WIDTH-1:0] avs_writedata;
    logic [(DATA_WIDTH/8)-1:0] avs_byteenable;
    logic [DATA_WIDTH-1:0] avs_readdata;
    logic avs_waitrequest;
    logic avs_readdatavalid;
    logic [ADDR_WIDTH-1:0] m_axi_awaddr;
    logic m_axi_awvalid;
    logic m_axi_awready;
    logic [DATA_WIDTH-1:0] m_axi_wdata;
    logic [(DATA_WIDTH/8)-1:0] m_axi_wstrb;
    logic m_axi_wvalid;
    logic m_axi_wready;
    logic [1:0] m_axi_bresp;
    logic m_axi_bvalid;
    logic m_axi_bready;
    logic [ADDR_WIDTH-1:0] m_axi_araddr;
    logic m_axi_arvalid;
    logic m_axi_arready;
    logic [DATA_WIDTH-1:0] m_axi_rdata;
    logic [1:0] m_axi_rresp;
    logic m_axi_rvalid;
    logic m_axi_rready;

    int errors;

    avalon_axi4lite_bridge #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (.*);

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
        avs_address = '0;
        avs_read = 1'b0;
        avs_write = 1'b0;
        avs_writedata = '0;
        avs_byteenable = '0;
        m_axi_awready = 1'b0;
        m_axi_wready = 1'b0;
        m_axi_bresp = 2'b00;
        m_axi_bvalid = 1'b0;
        m_axi_arready = 1'b0;
        m_axi_rdata = '0;
        m_axi_rresp = 2'b00;
        m_axi_rvalid = 1'b0;
        reset_n = 1'b0;
        repeat (3) @(posedge clk);
        reset_n = 1'b1;
        @(posedge clk);
    endtask

    task automatic avalon_write(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] data,
        input logic [(DATA_WIDTH/8)-1:0] be,
        input int aw_delay,
        input int w_delay,
        input int b_delay,
        input string name
    );
        @(negedge clk);
        avs_address = addr;
        avs_writedata = data;
        avs_byteenable = be;
        avs_write = 1'b1;
        @(posedge clk);
        @(negedge clk);
        avs_write = 1'b0;
        check({name, " waitrequest busy"}, avs_waitrequest == 1'b1);

        repeat (aw_delay) @(posedge clk);
        check({name, " AW stable"}, m_axi_awaddr == addr && m_axi_awvalid);
        @(negedge clk);
        m_axi_awready = 1'b1;
        @(posedge clk);
        @(negedge clk);
        m_axi_awready = 1'b0;

        repeat (w_delay) @(posedge clk);
        check({name, " W stable"}, m_axi_wdata == data && m_axi_wstrb == be && m_axi_wvalid);
        @(negedge clk);
        m_axi_wready = 1'b1;
        @(posedge clk);
        @(negedge clk);
        m_axi_wready = 1'b0;

        repeat (b_delay) @(posedge clk);
        check({name, " BREADY before response"}, m_axi_bready == 1'b1);
        @(negedge clk);
        m_axi_bvalid = 1'b1;
        @(posedge clk);
        @(negedge clk);
        m_axi_bvalid = 1'b0;
        @(posedge clk);
        check({name, " idle after response"}, avs_waitrequest == 1'b0);
    endtask

    task automatic avalon_write_w_first(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] data,
        input logic [(DATA_WIDTH/8)-1:0] be
    );
        @(negedge clk);
        avs_address = addr;
        avs_writedata = data;
        avs_byteenable = be;
        avs_write = 1'b1;
        @(posedge clk);
        @(negedge clk);
        avs_write = 1'b0;
        m_axi_wready = 1'b1;
        @(posedge clk);
        @(negedge clk);
        m_axi_wready = 1'b0;
        repeat (2) @(posedge clk);
        check("W before AW keeps AWVALID", m_axi_awvalid && !m_axi_wvalid);
        m_axi_awready = 1'b1;
        @(posedge clk);
        @(negedge clk);
        m_axi_awready = 1'b0;
        m_axi_bvalid = 1'b1;
        @(posedge clk);
        @(negedge clk);
        m_axi_bvalid = 1'b0;
    endtask

    task automatic avalon_read(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] data,
        input int ar_delay,
        input int r_delay,
        input string name
    );
        @(negedge clk);
        avs_address = addr;
        avs_read = 1'b1;
        @(posedge clk);
        @(negedge clk);
        avs_read = 1'b0;
        repeat (ar_delay) @(posedge clk);
        check({name, " AR stable"}, m_axi_arvalid && m_axi_araddr == addr);
        @(negedge clk);
        m_axi_arready = 1'b1;
        @(posedge clk);
        @(negedge clk);
        m_axi_arready = 1'b0;
        repeat (r_delay) @(posedge clk);
        check({name, " RREADY waiting"}, m_axi_rready == 1'b1);
        @(negedge clk);
        m_axi_rdata = data;
        m_axi_rvalid = 1'b1;
        @(posedge clk);
        @(negedge clk);
        m_axi_rvalid = 1'b0;
        @(posedge clk);
        check({name, " read data valid pulse"}, avs_readdatavalid && avs_readdata == data);
        @(posedge clk);
        check({name, " read data valid one cycle"}, !avs_readdatavalid);
    endtask

    initial begin
        errors = 0;
        reset_dut();

        check("reset outputs", !avs_waitrequest && !avs_readdatavalid && !m_axi_awvalid && !m_axi_wvalid && !m_axi_arvalid);

        avalon_write(6'h08, 32'hAAAA_5555, 4'b1111, 0, 0, 2, "write AW/W same cycle");
        avalon_write(6'h0C, 32'h1111_2222, 4'b0011, 0, 3, 1, "write AW before W");
        avalon_write_w_first(6'h10, 32'h0000_0002, 4'b1111);
        avalon_read(6'h14, 32'hDEAD_BEEF, 2, 3, "read with delays");

        @(negedge clk);
        avs_address = 6'h20;
        avs_writedata = 32'h1234_5678;
        avs_byteenable = 4'b1111;
        avs_write = 1'b1;
        avs_read = 1'b1;
        @(posedge clk);
        @(negedge clk);
        avs_write = 1'b0;
        avs_read = 1'b0;
        check("simultaneous read/write chooses write", m_axi_awvalid && m_axi_wvalid && !m_axi_arvalid);
        m_axi_awready = 1'b1;
        m_axi_wready = 1'b1;
        @(posedge clk);
        @(negedge clk);
        m_axi_awready = 1'b0;
        m_axi_wready = 1'b0;
        m_axi_bresp = 2'b10;
        m_axi_bvalid = 1'b1;
        @(posedge clk);
        @(negedge clk);
        m_axi_bvalid = 1'b0;
        m_axi_bresp = 2'b00;
        @(posedge clk);

        if (errors == 0) begin
            $display("tb_avalon_axi4lite_bridge PASSED");
            $finish;
        end
        $fatal(1, "tb_avalon_axi4lite_bridge FAILED with %0d errors", errors);
    end
endmodule
