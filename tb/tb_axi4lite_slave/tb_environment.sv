class axi4lite_slave_environment;
    virtual axi4lite_slave_tb_if #(AXI4LITE_SLAVE_ADDR_WIDTH, AXI4LITE_SLAVE_DATA_WIDTH) vif;
    axi4lite_slave_scoreboard sb;
    axi4lite_slave_driver drv;
    axi4lite_slave_monitor mon;
    axi4lite_slave_generator gen;
    axi4lite_slave_coverage cov;
    axi4lite_slave_directed directed;
    axi4lite_slave_random random_test;

    function new(virtual axi4lite_slave_tb_if #(AXI4LITE_SLAVE_ADDR_WIDTH, AXI4LITE_SLAVE_DATA_WIDTH) vif);
        this.vif = vif;
        sb = new(vif);
        drv = new(vif, sb);
        mon = new(vif);
        gen = new();
        cov = new();
        directed = new(drv, cov);
        random_test = new(drv, gen, cov);
    endfunction

    task run();
        fork
            mon.run();
        join_none

        drv.reset_dut();
        sb.check("reset outputs", !vif.s_axi_bvalid && !vif.s_axi_rvalid && !vif.wr_en && vif.s_axi_awready && vif.s_axi_wready && vif.s_axi_arready);
        directed.run();
        random_test.run(80);
        cov.report();
        sb.finish("tb_axi4lite_slave");
    endtask
endclass
