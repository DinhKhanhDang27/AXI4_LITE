class axi4lite_slave_random;
    axi4lite_slave_driver drv;
    axi4lite_slave_generator gen;
    axi4lite_slave_coverage cov;

    function new(axi4lite_slave_driver drv, axi4lite_slave_generator gen, axi4lite_slave_coverage cov);
        this.drv = drv;
        this.gen = gen;
        this.cov = cov;
    endfunction

    task run(input int iterations);
        axi4lite_slave_transaction tr;

        for (int i = 0; i < iterations; i++) begin
            tr = gen.random_transaction();
            cov.sample(tr);
            drv.drive_random(tr);
        end
    endtask
endclass
