class axi4lite_slave_scoreboard;
    virtual axi4lite_slave_tb_if #(AXI4LITE_SLAVE_ADDR_WIDTH, AXI4LITE_SLAVE_DATA_WIDTH) vif;
    int errors;

    function new(virtual axi4lite_slave_tb_if #(AXI4LITE_SLAVE_ADDR_WIDTH, AXI4LITE_SLAVE_DATA_WIDTH) vif);
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

    task wait_write_pulse(
        input logic [AXI4LITE_SLAVE_ADDR_WIDTH-1:0] exp_addr,
        input logic [AXI4LITE_SLAVE_DATA_WIDTH-1:0] exp_data,
        input logic [(AXI4LITE_SLAVE_DATA_WIDTH/8)-1:0] exp_strb,
        input string name
    );
        do begin
            @(posedge vif.aclk);
            #1;
        end while (!vif.wr_en);
        #1;
        check({name, " wr_en"}, vif.wr_addr == exp_addr && vif.wr_data == exp_data && vif.wr_strb == exp_strb);
        @(posedge vif.aclk);
        #1;
        check({name, " wr_en one cycle"}, vif.wr_en == 1'b0);
    endtask

    function void finish(input string test_name);
        if (errors == 0) begin
            $display("%s PASSED", test_name);
            $finish;
        end
        $fatal(1, "%s FAILED with %0d errors", test_name, errors);
    endfunction
endclass
