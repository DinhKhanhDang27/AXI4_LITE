class axi4lite_slave_generator;
    int unsigned seed;

    function new(int unsigned seed = 32'h4A11_5EED);
        this.seed = seed;
    endfunction

    function int unsigned rand32();
        seed = (seed * 32'd1664525) + 32'd1013904223;
        return seed;
    endfunction

    function axi4lite_slave_transaction random_transaction();
        axi4lite_slave_transaction tr = new();

        tr.addr = rand32();
        tr.data = rand32();
        tr.strb = rand32();
        if (tr.strb == 4'b0000) begin
            tr.strb = 4'b0001 << (rand32() % 4);
        end
        tr.aw_delay = rand32() % 4;
        tr.w_delay = rand32() % 4;
        tr.resp_delay = rand32() % 4;
        if ((rand32() & 1) == 0) begin
            tr.kind = axi4lite_slave_transaction::TR_WRITE_AW_FIRST;
            tr.name = "random AXI write";
        end else begin
            tr.kind = axi4lite_slave_transaction::TR_READ;
            tr.name = "random AXI read";
        end

        return tr;
    endfunction
endclass
