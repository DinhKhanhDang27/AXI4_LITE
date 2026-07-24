class axi_register_bank_random;
    axi_register_bank_driver drv;
    axi_register_bank_scoreboard sb;
    axi_register_bank_generator gen;
    axi_register_bank_coverage cov;

    logic [AXI_REG_BANK_DATA_WIDTH-1:0] exp_a;
    logic [AXI_REG_BANK_DATA_WIDTH-1:0] exp_b;
    logic [AXI_REG_BANK_DATA_WIDTH-1:0] exp_result;
    logic [3:0] exp_opcode;
    logic [2:0] exp_status;

    function new(
        axi_register_bank_driver drv,
        axi_register_bank_scoreboard sb,
        axi_register_bank_generator gen,
        axi_register_bank_coverage cov
    );
        this.drv = drv;
        this.sb = sb;
        this.gen = gen;
        this.cov = cov;
    endfunction

    function logic [AXI_REG_BANK_DATA_WIDTH-1:0] apply_strb_model(
        input logic [AXI_REG_BANK_DATA_WIDTH-1:0] old_data,
        input logic [AXI_REG_BANK_DATA_WIDTH-1:0] new_data,
        input logic [(AXI_REG_BANK_DATA_WIDTH/8)-1:0] strb
    );
        logic [AXI_REG_BANK_DATA_WIDTH-1:0] merged;

        merged = old_data;
        for (int i = 0; i < AXI_REG_BANK_DATA_WIDTH/8; i++) begin
            if (strb[i]) begin
                merged[i*8 +: 8] = new_data[i*8 +: 8];
            end
        end

        return merged;
    endfunction

    task run(input int iterations);
        logic [AXI_REG_BANK_DATA_WIDTH-1:0] data;
        logic [(AXI_REG_BANK_DATA_WIDTH/8)-1:0] strb;
        logic [AXI_REG_BANK_ADDR_WIDTH-1:0] addr;
        logic done_error;
        int choice;
        axi_register_bank_transaction tr;

        exp_a = drv.vif.operand_a;
        exp_b = drv.vif.operand_b;
        exp_opcode = drv.vif.opcode;
        exp_result = 32'h0;
        exp_status = 3'b110;

        for (int i = 0; i < iterations; i++) begin
            choice = gen.rand32() % 9;
            data = gen.rand32();
            strb = gen.rand32();
            if (strb == 4'b0000) begin
                strb = 4'b0001 << (gen.rand32() % 4);
            end

            tr = new(axi_register_bank_transaction::TR_WRITE);
            tr.data = data;
            tr.strb = strb;

            case (choice)
                0, 1: begin
                    tr.addr = ADDR_A; cov.sample(tr);
                    drv.bus_write(ADDR_A, data, strb);
                    exp_a = apply_strb_model(exp_a, data, strb);
                    sb.read_check(ADDR_A, exp_a, "random operand A byte lanes");
                end
                2, 3: begin
                    tr.addr = ADDR_B; cov.sample(tr);
                    drv.bus_write(ADDR_B, data, strb);
                    exp_b = apply_strb_model(exp_b, data, strb);
                    sb.read_check(ADDR_B, exp_b, "random operand B byte lanes");
                end
                4: begin
                    tr.addr = ADDR_OPCODE; cov.sample(tr);
                    drv.bus_write(ADDR_OPCODE, data, strb);
                    if (strb[0]) begin
                        exp_opcode = data[3:0];
                    end
                    sb.read_check(ADDR_OPCODE, {{AXI_REG_BANK_DATA_WIDTH-4{1'b0}}, exp_opcode}, "random opcode low nibble");
                end
                5: begin
                    tr.addr = ADDR_CTRL; tr.data = data | 32'h1; tr.strb = strb | 4'b0001; cov.sample(tr);
                    drv.bus_write(ADDR_CTRL, data | 32'h1, strb | 4'b0001);
                    @(posedge drv.vif.clk);
                    sb.check("random start when idle", drv.vif.start_pulse == 1'b1);
                    exp_status = 3'b001;

                    drv.bus_write(ADDR_CTRL, 32'h1, 4'b1111);
                    @(posedge drv.vif.clk);
                    sb.check("random busy rejects restart", drv.vif.start_pulse == 1'b0);

                    exp_result = gen.rand32();
                    done_error = gen.rand32() & 1;
                    drv.complete_core(exp_result, done_error);
                    exp_status = done_error ? 3'b110 : 3'b010;
                    sb.read_check(ADDR_STATUS, {{AXI_REG_BANK_DATA_WIDTH-3{1'b0}}, exp_status}, "random completion status");
                    sb.read_check(ADDR_RESULT, exp_result, "random completion result");
                end
                6: begin
                    tr.addr = ADDR_STATUS; cov.sample(tr);
                    drv.bus_write(ADDR_STATUS, data, strb);
                    sb.read_check(ADDR_STATUS, {{AXI_REG_BANK_DATA_WIDTH-3{1'b0}}, exp_status}, "random status write ignored");
                end
                7: begin
                    tr.addr = ADDR_RESULT; cov.sample(tr);
                    drv.bus_write(ADDR_RESULT, data, strb);
                    sb.read_check(ADDR_RESULT, exp_result, "random result write ignored");
                end
                default: begin
                    addr = gen.rand32();
                    addr = (addr ^ ADDR_BAD) & 6'h3F;
                    if (addr inside {ADDR_CTRL, ADDR_STATUS, ADDR_A, ADDR_B, ADDR_OPCODE, ADDR_RESULT}) begin
                        addr = ADDR_BAD;
                    end
                    tr.addr = addr; cov.sample(tr);
                    drv.bus_write(addr, data, strb);
                    sb.read_check(addr, 32'h0, "random invalid address reads zero");
                    sb.read_check(ADDR_A, exp_a, "random invalid write leaves operand A");
                    sb.read_check(ADDR_B, exp_b, "random invalid write leaves operand B");
                end
            endcase
        end
    endtask
endclass
