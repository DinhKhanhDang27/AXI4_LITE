interface avalon_bridge_tb_if #(
    parameter int ADDR_WIDTH = 6,
    parameter int DATA_WIDTH = 32
) (
    input logic clk
);
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
endinterface
