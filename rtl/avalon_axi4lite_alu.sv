module avalon_axi4lite_alu #(
    parameter int ADDR_WIDTH = 6,
    parameter int DATA_WIDTH = 32
) (
    input  logic                     clk,
    input  logic                     reset_n,

    input  logic [ADDR_WIDTH-1:0]    avs_address,
    input  logic                     avs_read,
    input  logic                     avs_write,
    input  logic [DATA_WIDTH-1:0]    avs_writedata,
    input  logic [(DATA_WIDTH/8)-1:0] avs_byteenable,
    output logic [DATA_WIDTH-1:0]    avs_readdata,
    output logic                     avs_waitrequest,
    output logic                     avs_readdatavalid
);

    logic [ADDR_WIDTH-1:0]     axi_awaddr;
    logic                      axi_awvalid;
    logic                      axi_awready;
    logic [DATA_WIDTH-1:0]     axi_wdata;
    logic [(DATA_WIDTH/8)-1:0] axi_wstrb;
    logic                      axi_wvalid;
    logic                      axi_wready;
    logic [1:0]                axi_bresp;
    logic                      axi_bvalid;
    logic                      axi_bready;
    logic [ADDR_WIDTH-1:0]     axi_araddr;
    logic                      axi_arvalid;
    logic                      axi_arready;
    logic [DATA_WIDTH-1:0]     axi_rdata;
    logic [1:0]                axi_rresp;
    logic                      axi_rvalid;
    logic                      axi_rready;
    logic                      wr_en;
    logic [ADDR_WIDTH-1:0]     wr_addr;
    logic [DATA_WIDTH-1:0]     wr_data;
    logic [(DATA_WIDTH/8)-1:0] wr_strb;
    logic [ADDR_WIDTH-1:0]     rd_addr;
    logic [DATA_WIDTH-1:0]     rd_data;
    logic                      start_pulse;
    logic [DATA_WIDTH-1:0]     operand_a;
    logic [DATA_WIDTH-1:0]     operand_b;
    logic [DATA_WIDTH-1:0]     result;
    logic [3:0]                opcode;
    logic                      busy;
    logic                      done;
    logic                      error;

    avalon_axi4lite_bridge #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_bridge (
        .clk               (clk),
        .reset_n           (reset_n),
        .avs_address       (avs_address),
        .avs_read          (avs_read),
        .avs_write         (avs_write),
        .avs_writedata     (avs_writedata),
        .avs_byteenable    (avs_byteenable),
        .avs_readdata      (avs_readdata),
        .avs_waitrequest   (avs_waitrequest),
        .avs_readdatavalid (avs_readdatavalid),
        .m_axi_awaddr      (axi_awaddr),
        .m_axi_awvalid     (axi_awvalid),
        .m_axi_awready     (axi_awready),
        .m_axi_wdata       (axi_wdata),
        .m_axi_wstrb       (axi_wstrb),
        .m_axi_wvalid      (axi_wvalid),
        .m_axi_wready      (axi_wready),
        .m_axi_bresp       (axi_bresp),
        .m_axi_bvalid      (axi_bvalid),
        .m_axi_bready      (axi_bready),
        .m_axi_araddr      (axi_araddr),
        .m_axi_arvalid     (axi_arvalid),
        .m_axi_arready     (axi_arready),
        .m_axi_rdata       (axi_rdata),
        .m_axi_rresp       (axi_rresp),
        .m_axi_rvalid      (axi_rvalid),
        .m_axi_rready      (axi_rready)
    );

    axi4lite_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_axi_slave (
        .aclk          (clk),
        .aresetn       (reset_n),
        .s_axi_awaddr  (axi_awaddr),
        .s_axi_awvalid (axi_awvalid),
        .s_axi_awready (axi_awready),
        .s_axi_wdata   (axi_wdata),
        .s_axi_wstrb   (axi_wstrb),
        .s_axi_wvalid  (axi_wvalid),
        .s_axi_wready  (axi_wready),
        .s_axi_bresp   (axi_bresp),
        .s_axi_bvalid  (axi_bvalid),
        .s_axi_bready  (axi_bready),
        .s_axi_araddr  (axi_araddr),
        .s_axi_arvalid (axi_arvalid),
        .s_axi_arready (axi_arready),
        .s_axi_rdata   (axi_rdata),
        .s_axi_rresp   (axi_rresp),
        .s_axi_rvalid  (axi_rvalid),
        .s_axi_rready  (axi_rready),
        .wr_en         (wr_en),
        .wr_addr       (wr_addr),
        .wr_data       (wr_data),
        .wr_strb       (wr_strb),
        .rd_addr       (rd_addr),
        .rd_data       (rd_data)
    );

    axi_register_bank #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_bank (
        .clk         (clk),
        .rst_n       (reset_n),
        .wr_en       (wr_en),
        .wr_addr     (wr_addr),
        .wr_data     (wr_data),
        .wr_strb     (wr_strb),
        .rd_addr     (rd_addr),
        .rd_data     (rd_data),
        .start_pulse (start_pulse),
        .operand_a   (operand_a),
        .operand_b   (operand_b),
        .opcode      (opcode),
        .core_result (result),
        .core_done   (done),
        .core_error  (error)
    );

    alu_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .OPCODE_WIDTH(4)
    ) u_alu (
        .clk       (clk),
        .rst_n     (reset_n),
        .start     (start_pulse),
        .operand_a (operand_a),
        .operand_b (operand_b),
        .opcode    (opcode),
        .result    (result),
        .busy      (busy),
        .done      (done),
        .error     (error)
    );

endmodule
