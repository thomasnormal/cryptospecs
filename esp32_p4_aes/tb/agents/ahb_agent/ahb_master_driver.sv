// AHB-Lite Master Driver
// Drives AHB-Lite using direct signal assignments (no clocking block delay).

class ahb_master_driver extends uvm_driver #(ahb_seq_item);

    `uvm_component_utils(ahb_master_driver)

    virtual ahb_if vif;

    function new(string name = "ahb_master_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ahb_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not found in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        ahb_seq_item item;

        // Initialize bus to idle
        @(negedge vif.clk);
        vif.hsel   = 1'b0;
        vif.htrans = 2'b00;
        vif.haddr  = 32'h0;
        vif.hwrite = 1'b0;
        vif.hsize  = 3'b010;
        vif.hwdata = 32'h0;

        // Wait for reset de-assertion
        @(posedge vif.rst_n);
        @(posedge vif.clk);

        forever begin
            seq_item_port.get_next_item(item);
            drive_item(item);
            seq_item_port.item_done();
        end
    endtask

    task drive_item(ahb_seq_item item);
        // Address phase: drive at negedge so signals are stable at next posedge
        @(negedge vif.clk);
        vif.hsel   = 1'b1;
        vif.htrans = 2'b10; // NONSEQ
        vif.haddr  = item.addr;
        vif.hwrite = (item.op == AHB_WRITE);
        vif.hsize  = item.hsize;
        if (item.op == AHB_WRITE)
            vif.hwdata = item.wdata;

        // Wait for posedge (slave captures address phase)
        @(posedge vif.clk);

        // Wait for slave ready
        while (!vif.hreadyout) @(posedge vif.clk);

        // Data phase: go idle on address bus
        @(negedge vif.clk);
        vif.hsel   = 1'b0;
        vif.htrans = 2'b00;

        // Wait for posedge (slave executes data phase)
        @(posedge vif.clk);

        // Wait for slave ready
        while (!vif.hreadyout) @(posedge vif.clk);

        // Capture read data
        if (item.op == AHB_READ)
            item.rdata = vif.hrdata;
    endtask

endclass
