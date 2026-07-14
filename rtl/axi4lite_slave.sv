module axi4lite_slave #(
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
    input  logic                    s_axi_rready,

    output logic                    wr_en,
    output logic [ADDR_WIDTH-1:0]    wr_addr,
    output logic [DATA_WIDTH-1:0]    wr_data,
    output logic [ADDR_WIDTH-1:0]    rd_addr,
    input  logic [DATA_WIDTH-1:0]    rd_data
);

    logic [ADDR_WIDTH-1:0] awaddr_q, araddr_q;
    logic [DATA_WIDTH-1:0] wdata_q, rdata_q;
    logic                  aw_v, w_v, bvalid_q, rvalid_q, read_pending;

    assign s_axi_awready = !aw_v;
    assign s_axi_wready   = !w_v;
    assign s_axi_bvalid   = bvalid_q;
    assign s_axi_bresp    = 2'b00;

    assign s_axi_arready  = !read_pending && !rvalid_q;
    assign s_axi_rvalid   = rvalid_q;
    assign s_axi_rdata    = rdata_q;
    assign s_axi_rresp    = 2'b00;

    assign rd_addr = araddr_q;

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            aw_v        <= 1'b0;
            w_v         <= 1'b0;
            bvalid_q    <= 1'b0;
            rvalid_q    <= 1'b0;
            read_pending <= 1'b0;
            wr_en       <= 1'b0;
            wr_addr     <= '0;
            wr_data     <= '0;
            awaddr_q    <= '0;
            araddr_q    <= '0;
            wdata_q     <= '0;
            rdata_q     <= '0;
        end else begin
            wr_en <= 1'b0;

            if (s_axi_awvalid && s_axi_awready) begin
                awaddr_q <= s_axi_awaddr;
                aw_v     <= 1'b1;
            end

            if (s_axi_wvalid && s_axi_wready) begin
                wdata_q <= s_axi_wdata;
                w_v     <= 1'b1;
            end

            if (!bvalid_q && aw_v && w_v) begin
                wr_en    <= 1'b1;
                wr_addr  <= awaddr_q;
                wr_data  <= wdata_q;
                aw_v     <= 1'b0;
                w_v      <= 1'b0;
                bvalid_q <= 1'b1;
            end

            if (bvalid_q && s_axi_bready) begin
                bvalid_q <= 1'b0;
            end

            if (s_axi_arvalid && s_axi_arready) begin
                araddr_q     <= s_axi_araddr;
                read_pending <= 1'b1;
            end

            if (read_pending) begin
                rdata_q      <= rd_data;
                rvalid_q     <= 1'b1;
                read_pending <= 1'b0;
            end

            if (rvalid_q && s_axi_rready) begin
                rvalid_q <= 1'b0;
            end
        end
    end

endmodule
