package axi4lite_slave_tb_pkg;
    localparam int AXI4LITE_SLAVE_ADDR_WIDTH = 6;
    localparam int AXI4LITE_SLAVE_DATA_WIDTH = 32;

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
