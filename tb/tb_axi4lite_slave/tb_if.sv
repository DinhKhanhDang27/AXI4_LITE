interface axi4lite_slave_tb_if #(
    parameter int ADDR_WIDTH = 6,
    parameter int DATA_WIDTH = 32
) (
    input logic aclk
);
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
endinterface
