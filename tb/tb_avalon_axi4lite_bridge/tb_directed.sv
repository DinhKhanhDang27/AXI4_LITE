class avalon_bridge_directed;
    avalon_bridge_driver drv;
    avalon_bridge_coverage cov;

    function new(avalon_bridge_driver drv, avalon_bridge_coverage cov);
        this.drv = drv;
        this.cov = cov;
    endfunction

    task run();
        avalon_bridge_transaction tr;

        tr = new(avalon_bridge_transaction::TR_WRITE);
        tr.addr = 6'h08; tr.data = 32'hAAAA_5555; tr.be = 4'b1111;
        tr.aw_delay = 0; tr.w_delay = 0; tr.resp_delay = 2; tr.name = "write AW/W same cycle";
        cov.sample(tr); drv.drive(tr);

        tr = new(avalon_bridge_transaction::TR_WRITE);
        tr.addr = 6'h0C; tr.data = 32'h1111_2222; tr.be = 4'b0011;
        tr.aw_delay = 0; tr.w_delay = 3; tr.resp_delay = 1; tr.name = "write AW before W";
        cov.sample(tr); drv.drive(tr);

        tr = new(avalon_bridge_transaction::TR_WRITE_W_FIRST);
        tr.addr = 6'h10; tr.data = 32'h0000_0002; tr.be = 4'b1111; tr.name = "write W before AW";
        cov.sample(tr); drv.drive(tr);

        tr = new(avalon_bridge_transaction::TR_READ);
        tr.addr = 6'h14; tr.data = 32'hDEAD_BEEF;
        tr.aw_delay = 2; tr.resp_delay = 3; tr.name = "read with delays";
        cov.sample(tr); drv.drive(tr);

        tr = new(avalon_bridge_transaction::TR_SIMULTANEOUS_RW);
        tr.name = "simultaneous read/write";
        cov.sample(tr); drv.drive(tr);
    endtask
endclass
