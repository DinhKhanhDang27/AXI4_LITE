class avalon_bridge_transaction;
    typedef enum {TR_READ, TR_WRITE, TR_WRITE_W_FIRST, TR_SIMULTANEOUS_RW} kind_e;

    kind_e kind;
    logic [AVALON_BRIDGE_ADDR_WIDTH-1:0] addr;
    logic [AVALON_BRIDGE_DATA_WIDTH-1:0] data;
    logic [(AVALON_BRIDGE_DATA_WIDTH/8)-1:0] be;
    int aw_delay;
    int w_delay;
    int resp_delay;
    string name;

    function new(kind_e kind = TR_WRITE);
        this.kind = kind;
        this.addr = '0;
        this.data = '0;
        this.be = '1;
        this.aw_delay = 0;
        this.w_delay = 0;
        this.resp_delay = 0;
        this.name = "";
    endfunction
endclass
