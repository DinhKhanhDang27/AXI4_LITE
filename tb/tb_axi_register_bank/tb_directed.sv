class axi_register_bank_directed;
    axi_register_bank_driver drv;
    axi_register_bank_scoreboard sb;
    axi_register_bank_coverage cov;

    function new(axi_register_bank_driver drv, axi_register_bank_scoreboard sb, axi_register_bank_coverage cov);
        this.drv = drv;
        this.sb = sb;
        this.cov = cov;
    endfunction

    task write_sample(input logic [AXI_REG_BANK_ADDR_WIDTH-1:0] addr, input logic [AXI_REG_BANK_DATA_WIDTH-1:0] data, input logic [(AXI_REG_BANK_DATA_WIDTH/8)-1:0] strb);
        axi_register_bank_transaction tr = new(axi_register_bank_transaction::TR_WRITE);
        tr.addr = addr;
        tr.data = data;
        tr.strb = strb;
        cov.sample(tr);
        drv.bus_write(addr, data, strb);
    endtask

    task run();
        sb.check("reset operand/status/start", drv.vif.operand_a == 0 && drv.vif.operand_b == 0 && drv.vif.opcode == 0 && drv.vif.start_pulse == 0);
        sb.read_check(ADDR_STATUS, 32'h0, "reset status read");
        sb.read_check(ADDR_RESULT, 32'h0, "reset result read");

        write_sample(ADDR_A, 32'h1122_3344, 4'b1111);
        sb.read_check(ADDR_A, 32'h1122_3344, "write/read operand A");

        write_sample(ADDR_A, 32'hAAAA_5555, 4'b0101);
        sb.read_check(ADDR_A, 32'h11AA_3355, "byte-enable partial operand A");

        write_sample(ADDR_B, 32'hCAFE_BABE, 4'b1111);
        sb.read_check(ADDR_B, 32'hCAFE_BABE, "write/read operand B");

        write_sample(ADDR_OPCODE, 32'hFFFF_FF03, 4'b1111);
        sb.read_check(ADDR_OPCODE, 32'h3, "opcode keeps low nibble");

        write_sample(ADDR_OPCODE, 32'h0000_000A, 4'b1110);
        sb.read_check(ADDR_OPCODE, 32'h3, "opcode unchanged when byte 0 strobe is clear");

        write_sample(ADDR_CTRL, 32'h1, 4'b1111);
        @(posedge drv.vif.clk);
        sb.check("start pulse asserted for one cycle", drv.vif.start_pulse == 1'b1);
        @(posedge drv.vif.clk);
        sb.check("start pulse clears", drv.vif.start_pulse == 1'b0);
        sb.read_check(ADDR_STATUS, 32'h1, "status busy after start");

        write_sample(ADDR_CTRL, 32'h1, 4'b1111);
        @(posedge drv.vif.clk);
        sb.check("start ignored while busy", drv.vif.start_pulse == 1'b0);

        @(negedge drv.vif.clk);
        drv.vif.core_result = 32'hDEAD_BEEF;
        drv.vif.core_error = 1'b0;
        drv.vif.core_done = 1'b1;
        @(negedge drv.vif.clk);
        drv.vif.core_done = 1'b0;
        drv.vif.core_result = '0;
        sb.read_check(ADDR_STATUS, 32'h2, "status done without error");
        sb.read_check(ADDR_RESULT, 32'hDEAD_BEEF, "result latched on done");

        write_sample(ADDR_CTRL, 32'h0, 4'b1111);
        @(posedge drv.vif.clk);
        sb.check("ctrl zero does not start", drv.vif.start_pulse == 1'b0);

        write_sample(ADDR_CTRL, 32'h1, 4'b1111);
        @(posedge drv.vif.clk);
        sb.check("start after done accepted", drv.vif.start_pulse == 1'b1);
        @(negedge drv.vif.clk);
        drv.vif.core_result = 32'h0;
        drv.vif.core_error = 1'b1;
        drv.vif.core_done = 1'b1;
        @(negedge drv.vif.clk);
        drv.vif.core_done = 1'b0;
        drv.vif.core_error = 1'b0;
        sb.read_check(ADDR_STATUS, 32'h6, "status done with error");
        sb.read_check(ADDR_RESULT, 32'h0, "error result latched");

        write_sample(ADDR_BAD, 32'hFFFF_FFFF, 4'b1111);
        sb.read_check(ADDR_BAD, 32'h0, "invalid read returns zero");
        sb.read_check(ADDR_A, 32'h11AA_3355, "invalid write does not corrupt A");
    endtask
endclass
