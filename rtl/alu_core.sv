module alu_core #(
    parameter int DATA_WIDTH   = 32,
    parameter int OPCODE_WIDTH = 4,
) (
    input  logic                         clk,
    input  logic                         rst_n,
    input  logic                         start,
    input  logic [DATA_WIDTH-1:0]        operand_a,
    input  logic [DATA_WIDTH-1:0]        operand_b,
    input  logic [OPCODE_WIDTH-1:0]      opcode,
    output logic [DATA_WIDTH-1:0]        result,
    output logic                         busy,
    output logic                         done,
    output logic                         error
);

    // Opcodes used by the register bank / software flow.
    localparam logic [OPCODE_WIDTH-1:0] OP_ADD = 4'd0;
    localparam logic [OPCODE_WIDTH-1:0] OP_SUB = 4'd1;
    localparam logic [OPCODE_WIDTH-1:0] OP_MUL = 4'd2;
    localparam logic [OPCODE_WIDTH-1:0] OP_DIV = 4'd3;

    logic [DATA_WIDTH-1:0] result_next;
    logic                   error_next;

    always_comb begin
        result_next = '0;
        error_next  = 1'b0;

        unique case (opcode)
            OP_ADD: result_next = operand_a + operand_b;
            OP_SUB: result_next = operand_a - operand_b;
            OP_MUL: result_next = operand_a * operand_b;
            OP_DIV: begin
                if (operand_b == '0) begin
                    result_next = '0;
                    error_next  = 1'b1;
                end else begin
                    result_next = operand_a / operand_b;
                end
            end
            default: begin
                result_next = '0;
                error_next  = 1'b1;
            end
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= '0;
            busy   <= 1'b0;
            done   <= 1'b0;
            error  <= 1'b0;
        end else begin
            done <= 1'b0;

            if (start && !busy) begin
                busy   <= 1'b1;
                result <= result_next;
                error  <= error_next;
            end else if (busy) begin
                busy <= 1'b0;
                done <= 1'b1;
            end
        end
    end

endmodule
