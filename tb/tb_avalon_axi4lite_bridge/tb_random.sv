class avalon_bridge_random;
    avalon_bridge_driver drv;
    avalon_bridge_generator gen;
    avalon_bridge_coverage cov;

    function new(avalon_bridge_driver drv, avalon_bridge_generator gen, avalon_bridge_coverage cov);
        this.drv = drv;
        this.gen = gen;
        this.cov = cov;
    endfunction

    task run(input int iterations);
        avalon_bridge_transaction tr;

        for (int i = 0; i < iterations; i++) begin
            tr = gen.random_transaction();
            cov.sample(tr);
            drv.drive(tr);
        end
    endtask
endclass
