class axi_register_bank_scoreboard;
    virtual axi_register_bank_tb_if #(AXI_REG_BANK_DATA_WIDTH, AXI_REG_BANK_ADDR_WIDTH) vif;
    int errors;

    function new(virtual axi_register_bank_tb_if #(AXI_REG_BANK_DATA_WIDTH, AXI_REG_BANK_ADDR_WIDTH) vif);
        this.vif = vif;
        errors = 0;
    endfunction

    function void check(input string name, input bit ok);
        if (!ok) begin
            errors++;
            $error("FAIL: %s", name);
        end else begin
            $display("PASS: %s", name);
        end
    endfunction

    task read_check(
        input logic [AXI_REG_BANK_ADDR_WIDTH-1:0] addr,
        input logic [AXI_REG_BANK_DATA_WIDTH-1:0] exp,
        input string name
    );
        vif.rd_addr = addr;
        #1;
        check(name, vif.rd_data === exp);
    endtask

    function void finish(input string test_name);
        if (errors == 0) begin
            $display("%s PASSED", test_name);
            $finish;
        end
        $fatal(1, "%s FAILED with %0d errors", test_name, errors);
    endfunction
endclass
