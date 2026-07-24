`timescale 1ns/1ps

`include "tb_if.sv"
`include "tb_pkg.sv"

module tb_avalon_axi4lite_bridge;
    import avalon_bridge_tb_pkg::*;

    logic clk;

    initial clk = 1'b0;
    always #5 clk = ~clk;

    avalon_bridge_tb_if #(AVALON_BRIDGE_ADDR_WIDTH, AVALON_BRIDGE_DATA_WIDTH) tb_if (.clk(clk));

    avalon_axi4lite_bridge #(
        .ADDR_WIDTH(AVALON_BRIDGE_ADDR_WIDTH),
        .DATA_WIDTH(AVALON_BRIDGE_DATA_WIDTH)
    ) dut (
        .clk(clk),
        .reset_n(tb_if.reset_n),
        .avs_address(tb_if.avs_address),
        .avs_read(tb_if.avs_read),
        .avs_write(tb_if.avs_write),
        .avs_writedata(tb_if.avs_writedata),
        .avs_byteenable(tb_if.avs_byteenable),
        .avs_readdata(tb_if.avs_readdata),
        .avs_waitrequest(tb_if.avs_waitrequest),
        .avs_readdatavalid(tb_if.avs_readdatavalid),
        .m_axi_awaddr(tb_if.m_axi_awaddr),
        .m_axi_awvalid(tb_if.m_axi_awvalid),
        .m_axi_awready(tb_if.m_axi_awready),
        .m_axi_wdata(tb_if.m_axi_wdata),
        .m_axi_wstrb(tb_if.m_axi_wstrb),
        .m_axi_wvalid(tb_if.m_axi_wvalid),
        .m_axi_wready(tb_if.m_axi_wready),
        .m_axi_bresp(tb_if.m_axi_bresp),
        .m_axi_bvalid(tb_if.m_axi_bvalid),
        .m_axi_bready(tb_if.m_axi_bready),
        .m_axi_araddr(tb_if.m_axi_araddr),
        .m_axi_arvalid(tb_if.m_axi_arvalid),
        .m_axi_arready(tb_if.m_axi_arready),
        .m_axi_rdata(tb_if.m_axi_rdata),
        .m_axi_rresp(tb_if.m_axi_rresp),
        .m_axi_rvalid(tb_if.m_axi_rvalid),
        .m_axi_rready(tb_if.m_axi_rready)
    );

    initial begin
        avalon_bridge_environment env;
        env = new(tb_if);
        env.run();
    end
endmodule
