module axi4lite_peripheral #(
    parameter int ADDR_WIDTH = 6,
    parameter int DATA_WIDTH = 32
) (
    input  logic                    aclk,
    input  logic                    aresetn,

    input  logic [ADDR_WIDTH-1:0]    s_axi_awaddr,
    input  logic                    s_axi_awvalid,
    output logic                    s_axi_awready,

    input  logic [DATA_WIDTH-1:0]    s_axi_wdata,
    input  logic [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  logic                    s_axi_wvalid,
    output logic                    s_axi_wready,

    output logic [1:0]              s_axi_bresp,
    output logic                    s_axi_bvalid,
    input  logic                    s_axi_bready,

    input  logic [ADDR_WIDTH-1:0]    s_axi_araddr,
    input  logic                    s_axi_arvalid,
    output logic                    s_axi_arready,

    output logic [DATA_WIDTH-1:0]    s_axi_rdata,
    output logic [1:0]              s_axi_rresp,
    output logic                    s_axi_rvalid,
    input  logic                    s_axi_rready
);

    logic                    wr_en, start_pulse;
    logic [ADDR_WIDTH-1:0]    wr_addr, rd_addr;
    logic [DATA_WIDTH-1:0]    wr_data, rd_data;
    logic [DATA_WIDTH-1:0]    a, b, result;
    logic [3:0]              opcode;
    logic                    busy;
    logic                    done, error;

    axi4lite_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_slave (
        .aclk          (aclk),
        .aresetn       (aresetn),
        .s_axi_awaddr  (s_axi_awaddr),
        .s_axi_awvalid (s_axi_awvalid),
        .s_axi_awready (s_axi_awready),
        .s_axi_wdata   (s_axi_wdata),
        .s_axi_wstrb   (s_axi_wstrb),
        .s_axi_wvalid  (s_axi_wvalid),
        .s_axi_wready  (s_axi_wready),
        .s_axi_bresp   (s_axi_bresp),
        .s_axi_bvalid  (s_axi_bvalid),
        .s_axi_bready  (s_axi_bready),
        .s_axi_araddr  (s_axi_araddr),
        .s_axi_arvalid (s_axi_arvalid),
        .s_axi_arready (s_axi_arready),
        .s_axi_rdata   (s_axi_rdata),
        .s_axi_rresp   (s_axi_rresp),
        .s_axi_rvalid  (s_axi_rvalid),
        .s_axi_rready  (s_axi_rready),
        .wr_en         (wr_en),
        .wr_addr       (wr_addr),
        .wr_data       (wr_data),
        .rd_addr       (rd_addr),
        .rd_data       (rd_data)
    );

    axi_register_bank #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_bank (
        .clk         (aclk),
        .rst_n       (aresetn),
        .wr_en       (wr_en),
        .wr_addr     (wr_addr),
        .wr_data     (wr_data),
        .rd_addr     (rd_addr),
        .rd_data     (rd_data),
        .start_pulse (start_pulse),
        .operand_a   (a),
        .operand_b   (b),
        .opcode      (opcode),
        .core_result (result),
        .core_done   (done),
        .core_error  (error)
    );

    alu_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .OPCODE_WIDTH(4)
    ) u_alu (
        .clk        (aclk),
        .rst_n      (aresetn),
        .start      (start_pulse),
        .operand_a  (a),
        .operand_b  (b),
        .opcode     (opcode),
        .result     (result),
        .busy       (busy),
        .done       (done),
        .error      (error)
    );

endmodule
