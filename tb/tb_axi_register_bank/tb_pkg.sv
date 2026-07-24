package axi_register_bank_tb_pkg;
    localparam int AXI_REG_BANK_DATA_WIDTH = 32;
    localparam int AXI_REG_BANK_ADDR_WIDTH = 6;

    localparam logic [AXI_REG_BANK_ADDR_WIDTH-1:0] ADDR_CTRL   = 6'h00;
    localparam logic [AXI_REG_BANK_ADDR_WIDTH-1:0] ADDR_STATUS = 6'h04;
    localparam logic [AXI_REG_BANK_ADDR_WIDTH-1:0] ADDR_A      = 6'h08;
    localparam logic [AXI_REG_BANK_ADDR_WIDTH-1:0] ADDR_B      = 6'h0C;
    localparam logic [AXI_REG_BANK_ADDR_WIDTH-1:0] ADDR_OPCODE = 6'h10;
    localparam logic [AXI_REG_BANK_ADDR_WIDTH-1:0] ADDR_RESULT = 6'h14;
    localparam logic [AXI_REG_BANK_ADDR_WIDTH-1:0] ADDR_BAD    = 6'h3C;

    `include "tb_transaction.sv"
    `include "tb_scoreboard.sv"
    `include "tb_coverage.sv"
    `include "tb_generator.sv"
    `include "tb_driver.sv"
    `include "tb_monitor.sv"
    `include "tb_directed.sv"
    `include "tb_random.sv"
    `include "tb_environment.sv"
endpackage
