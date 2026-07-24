class axi4lite_slave_monitor;
    virtual axi4lite_slave_tb_if #(AXI4LITE_SLAVE_ADDR_WIDTH, AXI4LITE_SLAVE_DATA_WIDTH) vif;
    int wr_pulses;

    function new(virtual axi4lite_slave_tb_if #(AXI4LITE_SLAVE_ADDR_WIDTH, AXI4LITE_SLAVE_DATA_WIDTH) vif);
        this.vif = vif;
        wr_pulses = 0;
    endfunction

    task run();
        forever begin
            @(posedge vif.aclk);
            if (vif.aresetn && vif.wr_en) begin
                wr_pulses++;
            end
        end
    endtask
endclass
