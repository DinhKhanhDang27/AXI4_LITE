class avalon_bridge_driver;
    virtual avalon_bridge_tb_if #(AVALON_BRIDGE_ADDR_WIDTH, AVALON_BRIDGE_DATA_WIDTH) vif;
    avalon_bridge_scoreboard sb;

    function new(
        virtual avalon_bridge_tb_if #(AVALON_BRIDGE_ADDR_WIDTH, AVALON_BRIDGE_DATA_WIDTH) vif,
        avalon_bridge_scoreboard sb
    );
        this.vif = vif;
        this.sb = sb;
    endfunction

    task reset_dut();
        vif.avs_address = '0;
        vif.avs_read = 1'b0;
        vif.avs_write = 1'b0;
        vif.avs_writedata = '0;
        vif.avs_byteenable = '0;
        vif.m_axi_awready = 1'b0;
        vif.m_axi_wready = 1'b0;
        vif.m_axi_bresp = 2'b00;
        vif.m_axi_bvalid = 1'b0;
        vif.m_axi_arready = 1'b0;
        vif.m_axi_rdata = '0;
        vif.m_axi_rresp = 2'b00;
        vif.m_axi_rvalid = 1'b0;
        vif.reset_n = 1'b0;
        repeat (3) @(posedge vif.clk);
        vif.reset_n = 1'b1;
        @(posedge vif.clk);
    endtask

    task avalon_write(avalon_bridge_transaction tr);
        @(negedge vif.clk);
        vif.avs_address = tr.addr;
        vif.avs_writedata = tr.data;
        vif.avs_byteenable = tr.be;
        vif.avs_write = 1'b1;
        @(posedge vif.clk);
        @(negedge vif.clk);
        vif.avs_write = 1'b0;
        sb.check({tr.name, " waitrequest busy"}, vif.avs_waitrequest == 1'b1);

        repeat (tr.aw_delay) @(posedge vif.clk);
        sb.check({tr.name, " AW stable"}, vif.m_axi_awaddr == tr.addr && vif.m_axi_awvalid);
        @(negedge vif.clk);
        vif.m_axi_awready = 1'b1;
        @(posedge vif.clk);
        @(negedge vif.clk);
        vif.m_axi_awready = 1'b0;

        repeat (tr.w_delay) @(posedge vif.clk);
        sb.check({tr.name, " W stable"}, vif.m_axi_wdata == tr.data && vif.m_axi_wstrb == tr.be && vif.m_axi_wvalid);
        @(negedge vif.clk);
        vif.m_axi_wready = 1'b1;
        @(posedge vif.clk);
        @(negedge vif.clk);
        vif.m_axi_wready = 1'b0;

        repeat (tr.resp_delay) @(posedge vif.clk);
        sb.check({tr.name, " BREADY before response"}, vif.m_axi_bready == 1'b1);
        @(negedge vif.clk);
        vif.m_axi_bvalid = 1'b1;
        @(posedge vif.clk);
        @(negedge vif.clk);
        vif.m_axi_bvalid = 1'b0;
        @(posedge vif.clk);
        sb.check({tr.name, " idle after response"}, vif.avs_waitrequest == 1'b0);
    endtask

    task avalon_write_w_first(avalon_bridge_transaction tr);
        @(negedge vif.clk);
        vif.avs_address = tr.addr;
        vif.avs_writedata = tr.data;
        vif.avs_byteenable = tr.be;
        vif.avs_write = 1'b1;
        @(posedge vif.clk);
        @(negedge vif.clk);
        vif.avs_write = 1'b0;
        vif.m_axi_wready = 1'b1;
        @(posedge vif.clk);
        @(negedge vif.clk);
        vif.m_axi_wready = 1'b0;
        repeat (2) @(posedge vif.clk);
        sb.check("W before AW keeps AWVALID", vif.m_axi_awvalid && !vif.m_axi_wvalid);
        vif.m_axi_awready = 1'b1;
        @(posedge vif.clk);
        @(negedge vif.clk);
        vif.m_axi_awready = 1'b0;
        vif.m_axi_bvalid = 1'b1;
        @(posedge vif.clk);
        @(negedge vif.clk);
        vif.m_axi_bvalid = 1'b0;
    endtask

    task avalon_read(avalon_bridge_transaction tr);
        @(negedge vif.clk);
        vif.avs_address = tr.addr;
        vif.avs_read = 1'b1;
        @(posedge vif.clk);
        @(negedge vif.clk);
        vif.avs_read = 1'b0;
        repeat (tr.aw_delay) @(posedge vif.clk);
        sb.check({tr.name, " AR stable"}, vif.m_axi_arvalid && vif.m_axi_araddr == tr.addr);
        @(negedge vif.clk);
        vif.m_axi_arready = 1'b1;
        @(posedge vif.clk);
        @(negedge vif.clk);
        vif.m_axi_arready = 1'b0;
        repeat (tr.resp_delay) @(posedge vif.clk);
        sb.check({tr.name, " RREADY waiting"}, vif.m_axi_rready == 1'b1);
        @(negedge vif.clk);
        vif.m_axi_rdata = tr.data;
        vif.m_axi_rvalid = 1'b1;
        @(posedge vif.clk);
        @(negedge vif.clk);
        vif.m_axi_rvalid = 1'b0;
        @(posedge vif.clk);
        sb.check({tr.name, " read data valid pulse"}, vif.avs_readdatavalid && vif.avs_readdata == tr.data);
        @(posedge vif.clk);
        sb.check({tr.name, " read data valid one cycle"}, !vif.avs_readdatavalid);
    endtask

    task simultaneous_rw();
        @(negedge vif.clk);
        vif.avs_address = 6'h20;
        vif.avs_writedata = 32'h1234_5678;
        vif.avs_byteenable = 4'b1111;
        vif.avs_write = 1'b1;
        vif.avs_read = 1'b1;
        @(posedge vif.clk);
        @(negedge vif.clk);
        vif.avs_write = 1'b0;
        vif.avs_read = 1'b0;
        sb.check("simultaneous read/write chooses write", vif.m_axi_awvalid && vif.m_axi_wvalid && !vif.m_axi_arvalid);
        vif.m_axi_awready = 1'b1;
        vif.m_axi_wready = 1'b1;
        @(posedge vif.clk);
        @(negedge vif.clk);
        vif.m_axi_awready = 1'b0;
        vif.m_axi_wready = 1'b0;
        vif.m_axi_bresp = 2'b10;
        vif.m_axi_bvalid = 1'b1;
        @(posedge vif.clk);
        @(negedge vif.clk);
        vif.m_axi_bvalid = 1'b0;
        vif.m_axi_bresp = 2'b00;
        @(posedge vif.clk);
    endtask

    task drive(avalon_bridge_transaction tr);
        case (tr.kind)
            avalon_bridge_transaction::TR_READ: avalon_read(tr);
            avalon_bridge_transaction::TR_WRITE_W_FIRST: avalon_write_w_first(tr);
            avalon_bridge_transaction::TR_SIMULTANEOUS_RW: simultaneous_rw();
            default: avalon_write(tr);
        endcase
    endtask
endclass
