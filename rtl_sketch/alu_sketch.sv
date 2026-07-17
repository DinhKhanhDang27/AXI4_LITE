module alu_core  #(
    parameter logic DATA_WIDTH = 32,
    parameter logic OPCODE_WIDTH = 4
)(
    input logic clk, 
    input logic rst_n,
    input logic start,
    input logic [DATA_WIDTH-1:0] operand_a,
    input logic [DATA_WIDTH-1:0] operand_b,
    input logic [OPCODE_WIDTH-1:0] opcode,
    output logic [DATA_WIDTH-1:0] result,
    output logic done, error, busy
);

localparam logic [OPCODE_WIDTH-1: 0] OP_ADD = 4'd0;
localparam logic [OPCODE_WIDTH-1: 0] OP_SUB = 4'd1;
localparam logic [OPCODE_WIDTH-1: 0] OP_MUL = 4'd2;
localparam logic [OPCODE_WIDTH-1: 0] OP_DIV = 4'd3;

logic [DATA_WIDTH-1:0] result_next;
logic error_next;

function automatic [DATA_WIDTH-1:0] divide_unsigned (
    
);

    endfunction

endmodule 