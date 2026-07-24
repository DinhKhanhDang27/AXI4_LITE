class avalon_bridge_generator;
    int unsigned seed;

    function new(int unsigned seed = 32'hB41D_6E00);
        this.seed = seed;
    endfunction

    function int unsigned rand32();
        seed = (seed * 32'd1664525) + 32'd1013904223;
        return seed;
    endfunction

    function avalon_bridge_transaction random_transaction();
        avalon_bridge_transaction tr = new();

        tr.addr = rand32();
        tr.data = rand32();
        tr.be = rand32();
        if (tr.be == 4'b0000) begin
            tr.be = 4'b0001 << (rand32() % 4);
        end
        tr.aw_delay = rand32() % 5;
        tr.w_delay = rand32() % 5;
        tr.resp_delay = rand32() % 5;
        if ((rand32() % 3) == 0) begin
            tr.kind = avalon_bridge_transaction::TR_READ;
            tr.name = "random Avalon read";
        end else begin
            tr.kind = avalon_bridge_transaction::TR_WRITE;
            tr.name = "random Avalon write";
        end

        return tr;
    endfunction
endclass
