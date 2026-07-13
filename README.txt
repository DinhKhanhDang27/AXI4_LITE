
rtl/
 ├── axi4lite_slave.sv
 ├── axi_register_bank.sv
 └── alu_core.sv

tb/
 ├── axi4lite_if.sv
 ├── axi_transaction.sv
 ├── axi_driver.sv
 ├── axi_monitor.sv
 ├── axi_scoreboard.sv
 ├── axi_assertions.sv
 ├── axi_coverage.sv
 └── tb_top.sv

software/
 └── main.c

quartus/
 ├── platform_designer_system.qsys
 └── top.sv

docs/
 ├── specification.md
 ├── verification_plan.md
 ├── register_map.md
 └── test_report.md





                          +----------------------+
                         |      Nios II CPU     |
                         | Avalon-MM Masters    |
                         +----------+-----------+
                                    |
                     Platform Designer Interconnect
              +---------------------+---------------------+
              |                     |                     |
              v                     v                     v
     +----------------+    +----------------+    +------------------+
     | On-Chip Memory |    |   JTAG UART    |    | Avalon/AXI Bridge|
     | Program + Data |    | printf console |    | or Interconnect  |
     +----------------+    +----------------+    +---------+--------+
                                                          |
                                                          | AXI4-Lite
                                                          v
                                                 +------------------+
                                                 | AXI4-Lite Slave  |
                                                 | Register Bank    |
                                                 +---------+--------+
                                                           |
                                                           v
                                                 +------------------+
                                                 | Custom HW Core   |
                                                 | ALU / Counter    |
                                                 +------------------+