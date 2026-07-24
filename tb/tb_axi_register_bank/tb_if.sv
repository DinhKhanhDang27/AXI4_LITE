interface axi_register_bank_tb_if #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 6
) (
    input logic clk
);
    logic rst_n;
    logic wr_en;
    logic [ADDR_WIDTH-1:0] wr_addr;
    logic [DATA_WIDTH-1:0] wr_data;
    logic [(DATA_WIDTH/8)-1:0] wr_strb;
    logic [ADDR_WIDTH-1:0] rd_addr;
    logic [DATA_WIDTH-1:0] rd_data;
    logic start_pulse;
    logic [DATA_WIDTH-1:0] operand_a;
    logic [DATA_WIDTH-1:0] operand_b;
    logic [3:0] opcode;
    logic [DATA_WIDTH-1:0] core_result;
    logic core_done;
    logic core_error;
endinterface
