`timescale 1ns/1ps

`include "tb_if.sv"
`include "tb_pkg.sv"

module tb_axi_register_bank;
    import axi_register_bank_tb_pkg::*;

    logic clk;

    initial clk = 1'b0;
    always #5 clk = ~clk;

    axi_register_bank_tb_if #(AXI_REG_BANK_DATA_WIDTH, AXI_REG_BANK_ADDR_WIDTH) tb_if (.clk(clk));

    axi_register_bank #(
        .DATA_WIDTH(AXI_REG_BANK_DATA_WIDTH),
        .ADDR_WIDTH(AXI_REG_BANK_ADDR_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(tb_if.rst_n),
        .wr_en(tb_if.wr_en),
        .wr_addr(tb_if.wr_addr),
        .wr_data(tb_if.wr_data),
        .wr_strb(tb_if.wr_strb),
        .rd_addr(tb_if.rd_addr),
        .rd_data(tb_if.rd_data),
        .start_pulse(tb_if.start_pulse),
        .operand_a(tb_if.operand_a),
        .operand_b(tb_if.operand_b),
        .opcode(tb_if.opcode),
        .core_result(tb_if.core_result),
        .core_done(tb_if.core_done),
        .core_error(tb_if.core_error)
    );

    initial begin
        axi_register_bank_environment env;
        env = new(tb_if);
        env.run();
    end
endmodule
