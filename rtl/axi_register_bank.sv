module axi_register_bank #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 6
) (
    input  logic                    clk,
    input  logic                    rst_n,

    input  logic                    wr_en,
    input  logic [ADDR_WIDTH-1:0]    wr_addr,
    input  logic [DATA_WIDTH-1:0]    wr_data,
    input  logic [(DATA_WIDTH/8)-1:0] wr_strb,

    input  logic [ADDR_WIDTH-1:0]    rd_addr,
    output logic [DATA_WIDTH-1:0]    rd_data,

    output logic                    start_pulse,
    output logic [DATA_WIDTH-1:0]    operand_a,
    output logic [DATA_WIDTH-1:0]    operand_b,
    output logic [3:0]              opcode,

    input  logic [DATA_WIDTH-1:0]    core_result,
    input  logic                    core_done,
    input  logic                    core_error
);

    localparam logic [ADDR_WIDTH-1:0] ADDR_CTRL   = 6'h00;
    localparam logic [ADDR_WIDTH-1:0] ADDR_STATUS = 6'h04;
    localparam logic [ADDR_WIDTH-1:0] ADDR_A      = 6'h08;
    localparam logic [ADDR_WIDTH-1:0] ADDR_B      = 6'h0C;
    localparam logic [ADDR_WIDTH-1:0] ADDR_OPCODE = 6'h10;
    localparam logic [ADDR_WIDTH-1:0] ADDR_RESULT = 6'h14;

    logic [DATA_WIDTH-1:0] result_reg;
    logic [2:0]            status_reg;
    logic [DATA_WIDTH-1:0] opcode_word;

    function automatic logic [DATA_WIDTH-1:0] apply_strb(
        input logic [DATA_WIDTH-1:0] old_data,
        input logic [DATA_WIDTH-1:0] new_data,
        input logic [(DATA_WIDTH/8)-1:0] strb
    );
        logic [DATA_WIDTH-1:0] merged;

        merged = old_data;
        for (int i = 0; i < DATA_WIDTH/8; i++) begin
            if (strb[i]) begin
                merged[i*8 +: 8] = new_data[i*8 +: 8];
            end
        end

        return merged;
    endfunction

    assign opcode_word = apply_strb({{DATA_WIDTH-4{1'b0}}, opcode}, wr_data, wr_strb);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            operand_a   <= '0;
            operand_b   <= '0;
            opcode      <= '0;
            result_reg  <= '0;
            status_reg  <= '0;
            start_pulse <= 1'b0;
        end else begin
            start_pulse <= 1'b0;

            if (wr_en) begin
                unique case (wr_addr)
                    ADDR_CTRL: begin
                        if (wr_strb[0] && wr_data[0] && !status_reg[0]) begin
                            start_pulse <= 1'b1;
                            status_reg   <= 3'b001;
                        end
                    end
                    ADDR_A:      operand_a <= apply_strb(operand_a, wr_data, wr_strb);
                    ADDR_B:      operand_b <= apply_strb(operand_b, wr_data, wr_strb);
                    ADDR_OPCODE: opcode    <= opcode_word[3:0];
                    default: ;
                endcase
            end

            if (core_done) begin
                result_reg <= core_result;
                status_reg  <= {core_error, 1'b1, 1'b0};
            end
        end
    end

    always_comb begin
        unique case (rd_addr)
            ADDR_CTRL:   rd_data = '0;
            ADDR_STATUS: rd_data = {{DATA_WIDTH-3{1'b0}}, status_reg};
            ADDR_A:      rd_data = operand_a;
            ADDR_B:      rd_data = operand_b;
            ADDR_OPCODE: rd_data = {{DATA_WIDTH-4{1'b0}}, opcode};
            ADDR_RESULT: rd_data = result_reg;
            default:     rd_data = '0;
        endcase
    end

endmodule
