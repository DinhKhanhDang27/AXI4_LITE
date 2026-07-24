class axi4lite_slave_transaction;
    typedef enum {TR_WRITE_AW_FIRST, TR_WRITE_W_FIRST, TR_WRITE_SAME_CYCLE, TR_READ} kind_e;

    kind_e kind;
    logic [AXI4LITE_SLAVE_ADDR_WIDTH-1:0] addr;
    logic [AXI4LITE_SLAVE_DATA_WIDTH-1:0] data;
    logic [(AXI4LITE_SLAVE_DATA_WIDTH/8)-1:0] strb;
    int aw_delay;
    int w_delay;
    int resp_delay;
    string name;

    function new(kind_e kind = TR_WRITE_SAME_CYCLE);
        this.kind = kind;
        this.addr = '0;
        this.data = '0;
        this.strb = '1;
        this.aw_delay = 0;
        this.w_delay = 0;
        this.resp_delay = 0;
        this.name = "";
    endfunction
endclass
