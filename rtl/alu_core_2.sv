module alu_core_2 #(
    parameter int DATA_WIDTH = 32;
    parameter int OPCODE_WIDTH = 4; 
)(
    input logic clk,
    input logic rst_n,
    input logic start,
    input logic [DATA_WIDTH-1: 0] operand_a,
    input logic [DATA_WIDTH-1: 0] operand_b,
    input logic [OPCODE_WIDTH-1 :0] opcode,
    output logic [DATA_WIDTH-1:0] result,
    output logic busy , done, error
);
logic [DATA_WIDTH-1:0] result_next;
logic  error_next;


endmodule