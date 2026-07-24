class axi4lite_slave_directed;
    axi4lite_slave_driver drv;
    axi4lite_slave_coverage cov;

    function new(axi4lite_slave_driver drv, axi4lite_slave_coverage cov);
        this.drv = drv;
        this.cov = cov;
    endfunction

    task run();
        axi4lite_slave_transaction tr;

        tr = new(axi4lite_slave_transaction::TR_WRITE_AW_FIRST);
        tr.addr = 6'h08; tr.data = 32'h1111_2222; tr.strb = 4'b1111; tr.name = "AW before W";
        cov.sample(tr); drv.drive(tr);

        tr = new(axi4lite_slave_transaction::TR_WRITE_W_FIRST);
        tr.addr = 6'h0C; tr.data = 32'h3333_4444; tr.strb = 4'b0011; tr.name = "W before AW";
        cov.sample(tr); drv.drive(tr);

        tr = new(axi4lite_slave_transaction::TR_WRITE_SAME_CYCLE);
        tr.addr = 6'h10; tr.data = 32'h0000_0003; tr.strb = 4'b1111; tr.name = "AW and W same cycle";
        cov.sample(tr); drv.drive(tr);

        tr = new(axi4lite_slave_transaction::TR_WRITE_SAME_CYCLE);
        tr.addr = 6'h14; tr.data = 32'h5555_AAAA; tr.strb = 4'b1111; tr.name = "AW and W same cycle";
        cov.sample(tr); drv.drive(tr);

        tr = new(axi4lite_slave_transaction::TR_READ);
        tr.addr = 6'h04; tr.data = 32'hCAFE_BABE; tr.name = "read transaction";
        cov.sample(tr); drv.drive(tr);

        tr = new(axi4lite_slave_transaction::TR_READ);
        tr.addr = 6'h14; tr.data = 32'h1234_5678; tr.name = "back-to-back read";
        cov.sample(tr); drv.drive(tr);
    endtask
endclass
