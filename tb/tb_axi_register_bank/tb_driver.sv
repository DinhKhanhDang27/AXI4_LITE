class axi_register_bank_driver;
    virtual axi_register_bank_tb_if #(AXI_REG_BANK_DATA_WIDTH, AXI_REG_BANK_ADDR_WIDTH) vif;

    function new(virtual axi_register_bank_tb_if #(AXI_REG_BANK_DATA_WIDTH, AXI_REG_BANK_ADDR_WIDTH) vif);
        this.vif = vif;
    endfunction

    task reset_dut();
        vif.wr_en = 1'b0;
        vif.wr_addr = '0;
        vif.wr_data = '0;
        vif.wr_strb = '0;
        vif.rd_addr = '0;
        vif.core_result = '0;
        vif.core_done = 1'b0;
        vif.core_error = 1'b0;
        vif.rst_n = 1'b0;
        repeat (3) @(posedge vif.clk);
        vif.rst_n = 1'b1;
        @(posedge vif.clk);
    endtask

    task bus_write(
        input logic [AXI_REG_BANK_ADDR_WIDTH-1:0] addr,
        input logic [AXI_REG_BANK_DATA_WIDTH-1:0] data,
        input logic [(AXI_REG_BANK_DATA_WIDTH/8)-1:0] strb
    );
        @(negedge vif.clk);
        vif.wr_addr = addr;
        vif.wr_data = data;
        vif.wr_strb = strb;
        vif.wr_en = 1'b1;
        @(negedge vif.clk);
        vif.wr_en = 1'b0;
        vif.wr_addr = '0;
        vif.wr_data = '0;
        vif.wr_strb = '0;
    endtask

    task complete_core(input logic [AXI_REG_BANK_DATA_WIDTH-1:0] result, input logic error);
        @(negedge vif.clk);
        vif.core_result = result;
        vif.core_error = error;
        vif.core_done = 1'b1;
        @(negedge vif.clk);
        vif.core_done = 1'b0;
        vif.core_result = '0;
        vif.core_error = 1'b0;
    endtask
endclass
