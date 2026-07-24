class axi4lite_slave_driver;
    virtual axi4lite_slave_tb_if #(AXI4LITE_SLAVE_ADDR_WIDTH, AXI4LITE_SLAVE_DATA_WIDTH) vif;
    axi4lite_slave_scoreboard sb;

    function new(
        virtual axi4lite_slave_tb_if #(AXI4LITE_SLAVE_ADDR_WIDTH, AXI4LITE_SLAVE_DATA_WIDTH) vif,
        axi4lite_slave_scoreboard sb
    );
        this.vif = vif;
        this.sb = sb;
    endfunction

    task reset_dut();
        vif.s_axi_awaddr = '0;
        vif.s_axi_awvalid = 1'b0;
        vif.s_axi_wdata = '0;
        vif.s_axi_wstrb = '0;
        vif.s_axi_wvalid = 1'b0;
        vif.s_axi_bready = 1'b0;
        vif.s_axi_araddr = '0;
        vif.s_axi_arvalid = 1'b0;
        vif.s_axi_rready = 1'b0;
        vif.rd_data = '0;
        vif.aresetn = 1'b0;
        repeat (3) @(posedge vif.aclk);
        vif.aresetn = 1'b1;
        @(posedge vif.aclk);
    endtask

    task axi_write_aw_first(axi4lite_slave_transaction tr);
        @(negedge vif.aclk);
        vif.s_axi_awaddr = tr.addr;
        vif.s_axi_awvalid = 1'b1;
        @(posedge vif.aclk);
        @(negedge vif.aclk);
        vif.s_axi_awvalid = 1'b0;
        vif.s_axi_wdata = tr.data;
        vif.s_axi_wstrb = tr.strb;
        vif.s_axi_wvalid = 1'b1;
        @(posedge vif.aclk);
        @(negedge vif.aclk);
        vif.s_axi_wvalid = 1'b0;
        sb.wait_write_pulse(tr.addr, tr.data, tr.strb, tr.name);
        sb.check("BVALID held before BREADY", vif.s_axi_bvalid == 1'b1);
        repeat (2) @(posedge vif.aclk);
        sb.check("BVALID still held", vif.s_axi_bvalid == 1'b1);
        @(negedge vif.aclk);
        vif.s_axi_bready = 1'b1;
        @(posedge vif.aclk);
        @(negedge vif.aclk);
        vif.s_axi_bready = 1'b0;
        sb.check("BRESP OKAY", vif.s_axi_bresp == 2'b00);
    endtask

    task axi_write_w_first(axi4lite_slave_transaction tr);
        @(negedge vif.aclk);
        vif.s_axi_wdata = tr.data;
        vif.s_axi_wstrb = tr.strb;
        vif.s_axi_wvalid = 1'b1;
        @(posedge vif.aclk);
        @(negedge vif.aclk);
        vif.s_axi_wvalid = 1'b0;
        vif.s_axi_awaddr = tr.addr;
        vif.s_axi_awvalid = 1'b1;
        @(posedge vif.aclk);
        @(negedge vif.aclk);
        vif.s_axi_awvalid = 1'b0;
        sb.wait_write_pulse(tr.addr, tr.data, tr.strb, tr.name);
        vif.s_axi_bready = 1'b1;
        @(posedge vif.aclk);
        @(negedge vif.aclk);
        vif.s_axi_bready = 1'b0;
    endtask

    task axi_write_same_cycle(axi4lite_slave_transaction tr);
        @(negedge vif.aclk);
        vif.s_axi_awaddr = tr.addr;
        vif.s_axi_awvalid = 1'b1;
        vif.s_axi_wdata = tr.data;
        vif.s_axi_wstrb = tr.strb;
        vif.s_axi_wvalid = 1'b1;
        @(posedge vif.aclk);
        @(negedge vif.aclk);
        vif.s_axi_awvalid = 1'b0;
        vif.s_axi_wvalid = 1'b0;
        sb.wait_write_pulse(tr.addr, tr.data, tr.strb, tr.name);
        vif.s_axi_bready = 1'b1;
        @(posedge vif.aclk);
        @(negedge vif.aclk);
        vif.s_axi_bready = 1'b0;
    endtask

    task axi_read(axi4lite_slave_transaction tr);
        @(negedge vif.aclk);
        vif.rd_data = tr.data;
        vif.s_axi_araddr = tr.addr;
        vif.s_axi_arvalid = 1'b1;
        @(posedge vif.aclk);
        while (!vif.s_axi_arready) @(posedge vif.aclk);
        @(negedge vif.aclk);
        vif.s_axi_arvalid = 1'b0;
        wait (vif.s_axi_rvalid);
        sb.check({tr.name, " address"}, vif.rd_addr == tr.addr);
        sb.check({tr.name, " data/resp"}, vif.s_axi_rdata == tr.data && vif.s_axi_rresp == 2'b00);
        sb.check({tr.name, " RVALID held"}, vif.s_axi_rvalid == 1'b1);
        repeat (2) @(posedge vif.aclk);
        sb.check({tr.name, " RVALID held during stall"}, vif.s_axi_rvalid == 1'b1);
        @(negedge vif.aclk);
        vif.s_axi_rready = 1'b1;
        @(posedge vif.aclk);
        @(negedge vif.aclk);
        vif.s_axi_rready = 1'b0;
    endtask

    task axi_write_random(axi4lite_slave_transaction tr);
        fork
            begin
                repeat (tr.aw_delay) @(posedge vif.aclk);
                @(negedge vif.aclk);
                vif.s_axi_awaddr = tr.addr;
                vif.s_axi_awvalid = 1'b1;
                @(posedge vif.aclk);
                while (!vif.s_axi_awready) @(posedge vif.aclk);
                @(negedge vif.aclk);
                vif.s_axi_awvalid = 1'b0;
            end
            begin
                repeat (tr.w_delay) @(posedge vif.aclk);
                @(negedge vif.aclk);
                vif.s_axi_wdata = tr.data;
                vif.s_axi_wstrb = tr.strb;
                vif.s_axi_wvalid = 1'b1;
                @(posedge vif.aclk);
                while (!vif.s_axi_wready) @(posedge vif.aclk);
                @(negedge vif.aclk);
                vif.s_axi_wvalid = 1'b0;
            end
        join

        sb.wait_write_pulse(tr.addr, tr.data, tr.strb, "random AXI write");
        sb.check("random BVALID asserted", vif.s_axi_bvalid == 1'b1);
        repeat (tr.resp_delay) begin
            @(posedge vif.aclk);
            sb.check("random BVALID held during stall", vif.s_axi_bvalid == 1'b1 && vif.s_axi_bresp == 2'b00);
        end
        @(negedge vif.aclk);
        vif.s_axi_bready = 1'b1;
        @(posedge vif.aclk);
        @(negedge vif.aclk);
        vif.s_axi_bready = 1'b0;
    endtask

    task axi_read_random(axi4lite_slave_transaction tr);
        repeat (tr.aw_delay) @(posedge vif.aclk);
        @(negedge vif.aclk);
        vif.rd_data = tr.data;
        vif.s_axi_araddr = tr.addr;
        vif.s_axi_arvalid = 1'b1;
        @(posedge vif.aclk);
        while (!vif.s_axi_arready) @(posedge vif.aclk);
        @(negedge vif.aclk);
        vif.s_axi_arvalid = 1'b0;

        wait (vif.s_axi_rvalid);
        sb.check("random read address", vif.rd_addr == tr.addr);
        sb.check("random read data/resp", vif.s_axi_rdata == tr.data && vif.s_axi_rresp == 2'b00);
        repeat (tr.resp_delay) begin
            @(posedge vif.aclk);
            sb.check("random RVALID held during stall", vif.s_axi_rvalid == 1'b1 && vif.s_axi_rdata == tr.data);
        end
        @(negedge vif.aclk);
        vif.s_axi_rready = 1'b1;
        @(posedge vif.aclk);
        @(negedge vif.aclk);
        vif.s_axi_rready = 1'b0;
    endtask

    task drive(axi4lite_slave_transaction tr);
        case (tr.kind)
            axi4lite_slave_transaction::TR_WRITE_AW_FIRST: axi_write_aw_first(tr);
            axi4lite_slave_transaction::TR_WRITE_W_FIRST: axi_write_w_first(tr);
            axi4lite_slave_transaction::TR_WRITE_SAME_CYCLE: axi_write_same_cycle(tr);
            axi4lite_slave_transaction::TR_READ: axi_read(tr);
            default: axi_write_same_cycle(tr);
        endcase
    endtask

    task drive_random(axi4lite_slave_transaction tr);
        if (tr.kind == axi4lite_slave_transaction::TR_READ) begin
            axi_read_random(tr);
        end else begin
            axi_write_random(tr);
        end
    endtask
endclass
