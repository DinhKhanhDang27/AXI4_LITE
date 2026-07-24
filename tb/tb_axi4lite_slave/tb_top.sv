`timescale 1ns/1ps

`include "tb_if.sv"
`include "tb_pkg.sv"

module tb_axi4lite_slave;
    import axi4lite_slave_tb_pkg::*;

    logic aclk;

    initial aclk = 1'b0;
    always #5 aclk = ~aclk;

    axi4lite_slave_tb_if #(AXI4LITE_SLAVE_ADDR_WIDTH, AXI4LITE_SLAVE_DATA_WIDTH) tb_if (.aclk(aclk));

    axi4lite_slave #(
        .ADDR_WIDTH(AXI4LITE_SLAVE_ADDR_WIDTH),
        .DATA_WIDTH(AXI4LITE_SLAVE_DATA_WIDTH)
    ) dut (
        .aclk(aclk),
        .aresetn(tb_if.aresetn),
        .s_axi_awaddr(tb_if.s_axi_awaddr),
        .s_axi_awvalid(tb_if.s_axi_awvalid),
        .s_axi_awready(tb_if.s_axi_awready),
        .s_axi_wdata(tb_if.s_axi_wdata),
        .s_axi_wstrb(tb_if.s_axi_wstrb),
        .s_axi_wvalid(tb_if.s_axi_wvalid),
        .s_axi_wready(tb_if.s_axi_wready),
        .s_axi_bresp(tb_if.s_axi_bresp),
        .s_axi_bvalid(tb_if.s_axi_bvalid),
        .s_axi_bready(tb_if.s_axi_bready),
        .s_axi_araddr(tb_if.s_axi_araddr),
        .s_axi_arvalid(tb_if.s_axi_arvalid),
        .s_axi_arready(tb_if.s_axi_arready),
        .s_axi_rdata(tb_if.s_axi_rdata),
        .s_axi_rresp(tb_if.s_axi_rresp),
        .s_axi_rvalid(tb_if.s_axi_rvalid),
        .s_axi_rready(tb_if.s_axi_rready),
        .wr_en(tb_if.wr_en),
        .wr_addr(tb_if.wr_addr),
        .wr_data(tb_if.wr_data),
        .wr_strb(tb_if.wr_strb),
        .rd_addr(tb_if.rd_addr),
        .rd_data(tb_if.rd_data)
    );

    initial begin
        axi4lite_slave_environment env;
        env = new(tb_if);
        env.run();
    end
endmodule
