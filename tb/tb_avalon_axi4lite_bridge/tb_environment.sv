class avalon_bridge_environment;
    virtual avalon_bridge_tb_if #(AVALON_BRIDGE_ADDR_WIDTH, AVALON_BRIDGE_DATA_WIDTH) vif;
    avalon_bridge_scoreboard sb;
    avalon_bridge_driver drv;
    avalon_bridge_monitor mon;
    avalon_bridge_generator gen;
    avalon_bridge_coverage cov;
    avalon_bridge_directed directed;
    avalon_bridge_random random_test;

    function new(virtual avalon_bridge_tb_if #(AVALON_BRIDGE_ADDR_WIDTH, AVALON_BRIDGE_DATA_WIDTH) vif);
        this.vif = vif;
        sb = new();
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
        sb.check("reset outputs", !vif.avs_waitrequest && !vif.avs_readdatavalid && !vif.m_axi_awvalid && !vif.m_axi_wvalid && !vif.m_axi_arvalid);
        directed.run();
        random_test.run(80);
        cov.report();
        sb.finish("tb_avalon_axi4lite_bridge");
    endtask
endclass
