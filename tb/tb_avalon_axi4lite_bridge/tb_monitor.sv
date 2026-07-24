class avalon_bridge_monitor;
    virtual avalon_bridge_tb_if #(AVALON_BRIDGE_ADDR_WIDTH, AVALON_BRIDGE_DATA_WIDTH) vif;

    function new(virtual avalon_bridge_tb_if #(AVALON_BRIDGE_ADDR_WIDTH, AVALON_BRIDGE_DATA_WIDTH) vif);
        this.vif = vif;
    endfunction

    task run();
        forever begin
            @(posedge vif.clk);
        end
    endtask
endclass
