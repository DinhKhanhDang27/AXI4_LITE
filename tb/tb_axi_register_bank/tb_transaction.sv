class axi_register_bank_transaction;
    typedef enum {TR_WRITE, TR_READ_CHECK, TR_CORE_DONE, TR_START_CHECK, TR_WAIT_CHECK} kind_e;

    kind_e kind;
    logic [AXI_REG_BANK_ADDR_WIDTH-1:0] addr;
    logic [AXI_REG_BANK_DATA_WIDTH-1:0] data;
    logic [AXI_REG_BANK_DATA_WIDTH-1:0] exp;
    logic [(AXI_REG_BANK_DATA_WIDTH/8)-1:0] strb;
    logic error;
    string name;

    function new(kind_e kind = TR_WRITE);
        this.kind = kind;
        this.addr = '0;
        this.data = '0;
        this.exp = '0;
        this.strb = '1;
        this.error = 1'b0;
        this.name = "";
    endfunction
endclass
