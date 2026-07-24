class axi_register_bank_monitor;
    virtual axi_register_bank_tb_if #(AXI_REG_BANK_DATA_WIDTH, AXI_REG_BANK_ADDR_WIDTH) vif;
    int start_pulses;

    function new(virtual axi_register_bank_tb_if #(AXI_REG_BANK_DATA_WIDTH, AXI_REG_BANK_ADDR_WIDTH) vif);
        this.vif = vif;
        start_pulses = 0;
    endfunction

    task run();
        forever begin
            @(posedge vif.clk);
            if (vif.rst_n && vif.start_pulse) begin
                start_pulses++;
            end
        end
    endtask
endclass
