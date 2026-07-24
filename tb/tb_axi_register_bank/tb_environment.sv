class axi_register_bank_environment;
    virtual axi_register_bank_tb_if #(AXI_REG_BANK_DATA_WIDTH, AXI_REG_BANK_ADDR_WIDTH) vif;
    axi_register_bank_scoreboard sb;
    axi_register_bank_driver drv;
    axi_register_bank_monitor mon;
    axi_register_bank_generator gen;
    axi_register_bank_coverage cov;
    axi_register_bank_directed directed;
    axi_register_bank_random random_test;

    function new(virtual axi_register_bank_tb_if #(AXI_REG_BANK_DATA_WIDTH, AXI_REG_BANK_ADDR_WIDTH) vif);
        this.vif = vif;
        sb = new(vif);
        drv = new(vif);
        mon = new(vif);
        gen = new();
        cov = new();
        directed = new(drv, sb, cov);
        random_test = new(drv, sb, gen, cov);
    endfunction

    task run();
        fork
            mon.run();
        join_none

        drv.reset_dut();
        directed.run();
        random_test.run(80);
        cov.report();
        sb.finish("tb_axi_register_bank");
    endtask
endclass
