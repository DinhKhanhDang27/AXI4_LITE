module avalon_axi4lite_bridge #(
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
    output logic                     avs_readdatavalid,

    output logic [ADDR_WIDTH-1:0]    m_axi_awaddr,
    output logic                     m_axi_awvalid,
    input  logic                     m_axi_awready,

    output logic [DATA_WIDTH-1:0]    m_axi_wdata,
    output logic [(DATA_WIDTH/8)-1:0] m_axi_wstrb,
    output logic                     m_axi_wvalid,
    input  logic                     m_axi_wready,

    input  logic [1:0]               m_axi_bresp,
    input  logic                     m_axi_bvalid,
    output logic                     m_axi_bready,

    output logic [ADDR_WIDTH-1:0]    m_axi_araddr,
    output logic                     m_axi_arvalid,
    input  logic                     m_axi_arready,

    input  logic [DATA_WIDTH-1:0]    m_axi_rdata,
    input  logic [1:0]               m_axi_rresp,
    input  logic                     m_axi_rvalid,
    output logic                     m_axi_rready
);

    typedef enum logic [2:0] {
        ST_IDLE,
        ST_WRITE,
        ST_WRITE_RESP,
        ST_READ_ADDR,
        ST_READ_DATA
    } state_t;

    state_t state_q, state_d;

    logic [ADDR_WIDTH-1:0]     addr_q;
    logic [DATA_WIDTH-1:0]     writedata_q;
    logic [(DATA_WIDTH/8)-1:0] byteenable_q;
    logic                      aw_done_q;
    logic                      w_done_q;

    assign avs_waitrequest = (state_q != ST_IDLE);

    assign m_axi_awaddr  = addr_q;
    assign m_axi_wdata   = writedata_q;
    assign m_axi_wstrb   = byteenable_q;
    assign m_axi_araddr  = addr_q;

    assign m_axi_awvalid = (state_q == ST_WRITE) && !aw_done_q;
    assign m_axi_wvalid  = (state_q == ST_WRITE) && !w_done_q;
    assign m_axi_bready  = (state_q == ST_WRITE_RESP);
    assign m_axi_arvalid = (state_q == ST_READ_ADDR);
    assign m_axi_rready  = (state_q == ST_READ_DATA);

    always_comb begin
        state_d = state_q;

        unique case (state_q)
            ST_IDLE: begin
                if (avs_write) begin
                    state_d = ST_WRITE;
                end else if (avs_read) begin
                    state_d = ST_READ_ADDR;
                end
            end

            ST_WRITE: begin
                if ((aw_done_q || m_axi_awready) && (w_done_q || m_axi_wready)) begin
                    state_d = ST_WRITE_RESP;
                end
            end

            ST_WRITE_RESP: begin
                if (m_axi_bvalid) begin
                    state_d = ST_IDLE;
                end
            end

            ST_READ_ADDR: begin
                if (m_axi_arready) begin
                    state_d = ST_READ_DATA;
                end
            end

            ST_READ_DATA: begin
                if (m_axi_rvalid) begin
                    state_d = ST_IDLE;
                end
            end

            default: state_d = ST_IDLE;
        endcase
    end

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state_q            <= ST_IDLE;
            addr_q             <= '0;
            writedata_q        <= '0;
            byteenable_q       <= '0;
            aw_done_q          <= 1'b0;
            w_done_q           <= 1'b0;
            avs_readdata       <= '0;
            avs_readdatavalid  <= 1'b0;
        end else begin
            state_q           <= state_d;
            avs_readdatavalid <= 1'b0;

            if (state_q == ST_IDLE && !avs_waitrequest) begin
                if (avs_write || avs_read) begin
                    addr_q       <= avs_address;
                    writedata_q  <= avs_writedata;
                    byteenable_q <= avs_byteenable;
                    aw_done_q    <= 1'b0;
                    w_done_q     <= 1'b0;
                end
            end

            if (state_q == ST_WRITE && m_axi_awready) begin
                aw_done_q <= 1'b1;
            end

            if (state_q == ST_WRITE && m_axi_wready) begin
                w_done_q <= 1'b1;
            end

            if (state_q == ST_WRITE_RESP && m_axi_bvalid) begin
                aw_done_q <= 1'b0;
                w_done_q  <= 1'b0;
            end

            if (state_q == ST_READ_DATA && m_axi_rvalid) begin
                avs_readdata      <= m_axi_rdata;
                avs_readdatavalid <= 1'b1;
            end
        end
    end

    // The current peripheral always returns OKAY. These are kept visible for
    // easy extension if decode/slave-error reporting is added later.
    logic unused_resp;
    assign unused_resp = |m_axi_bresp | |m_axi_rresp;

endmodule
