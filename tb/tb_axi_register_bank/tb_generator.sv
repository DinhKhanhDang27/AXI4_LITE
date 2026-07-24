class axi_register_bank_generator;
    int unsigned seed;

    function new(int unsigned seed = 32'hA51C_0D3D);
        this.seed = seed;
    endfunction

    function int unsigned rand32();
        seed = (seed * 32'd1664525) + 32'd1013904223;
        return seed;
    endfunction

    function axi_register_bank_transaction random_write(input logic [AXI_REG_BANK_ADDR_WIDTH-1:0] addr);
        axi_register_bank_transaction tr = new(axi_register_bank_transaction::TR_WRITE);

        tr.addr = addr;
        tr.data = rand32();
        tr.strb = rand32();
        if (tr.strb == 4'b0000) begin
            tr.strb = 4'b0001 << (rand32() % 4);
        end

        return tr;
    endfunction
endclass
