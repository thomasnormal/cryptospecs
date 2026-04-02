// AXI4 Monitor
// Passively observes all AXI4 channel handshakes and reconstructs
// complete read and write transactions. Provides separate analysis
// ports for read and write transactions.

class axi_monitor extends uvm_monitor;

    `uvm_component_utils(axi_monitor)

    // ---------------------------------------------------------------
    // Virtual interface
    // ---------------------------------------------------------------
    virtual axi_if.MONITOR vif;

    // ---------------------------------------------------------------
    // Analysis ports - separate for read and write transactions
    // ---------------------------------------------------------------
    uvm_analysis_port #(axi_seq_item) rd_ap;
    uvm_analysis_port #(axi_seq_item) wr_ap;

    // ---------------------------------------------------------------
    // Constructor
    // ---------------------------------------------------------------
    function new(string name = "axi_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    // ---------------------------------------------------------------
    // Build Phase
    // ---------------------------------------------------------------
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        rd_ap = new("rd_ap", this);
        wr_ap = new("wr_ap", this);

        if (!uvm_config_db#(virtual axi_if.MONITOR)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "Virtual interface not found in config_db for axi_monitor")
    endfunction : build_phase

    // ---------------------------------------------------------------
    // Run Phase - Launch read and write monitors in parallel
    // ---------------------------------------------------------------
    virtual task run_phase(uvm_phase phase);
        // Wait for reset de-assertion
        @(posedge vif.clk);
        wait (vif.rst_n === 1'b1);
        @(posedge vif.clk);

        fork
            monitor_reads();
            monitor_writes();
        join
    endtask : run_phase

    // ---------------------------------------------------------------
    // Monitor Read Transactions
    // Captures AR channel, then collects all R channel beats
    // ---------------------------------------------------------------
    virtual task monitor_reads();
        axi_seq_item txn;
        bit [31:0]   addr;
        bit [7:0]    len;
        bit [2:0]    size;
        bit [1:0]    burst;
        bit [3:0]    id;
        int          num_beats;

        forever begin
            // Wait for AR handshake (arvalid && arready)
            @(vif.mon_cb);
            while (!(vif.mon_cb.arvalid && vif.mon_cb.arready))
                @(vif.mon_cb);

            // Capture address phase
            id    = vif.mon_cb.arid;
            addr  = vif.mon_cb.araddr;
            len   = vif.mon_cb.arlen;
            size  = vif.mon_cb.arsize;
            burst = vif.mon_cb.arburst;

            num_beats = len + 1;

            // Create transaction item
            txn = axi_seq_item::type_id::create("rd_txn");
            txn.rw         = axi_seq_item::AXI_READ;
            txn.id         = id;
            txn.addr       = addr;
            txn.burst_len  = len;
            txn.burst_size = size;
            txn.burst_type = burst;
            txn.data       = new[num_beats];

            // Collect R channel beats
            for (int beat = 0; beat < num_beats; beat++) begin
                @(vif.mon_cb);
                while (!(vif.mon_cb.rvalid && vif.mon_cb.rready))
                    @(vif.mon_cb);

                txn.data[beat] = vif.mon_cb.rdata;

                // Capture response from last beat
                if (beat == num_beats - 1) begin
                    txn.resp = axi_seq_item::axi_resp_e'(vif.mon_cb.rresp);
                end
            end

            `uvm_info("AXI_MON", {"Read transaction captured:", txn.convert2string()}, UVM_HIGH)

            // Broadcast to analysis port
            rd_ap.write(txn);
        end
    endtask : monitor_reads

    // ---------------------------------------------------------------
    // Monitor Write Transactions
    // Captures AW channel + W channel beats + B channel response
    // ---------------------------------------------------------------
    virtual task monitor_writes();
        axi_seq_item txn;
        bit [31:0]   addr;
        bit [7:0]    len;
        bit [2:0]    size;
        bit [1:0]    burst;
        bit [3:0]    id;
        int          num_beats;

        forever begin
            // Wait for AW handshake (awvalid && awready)
            @(vif.mon_cb);
            while (!(vif.mon_cb.awvalid && vif.mon_cb.awready))
                @(vif.mon_cb);

            // Capture address phase
            id    = vif.mon_cb.awid;
            addr  = vif.mon_cb.awaddr;
            len   = vif.mon_cb.awlen;
            size  = vif.mon_cb.awsize;
            burst = vif.mon_cb.awburst;

            num_beats = len + 1;

            // Create transaction item
            txn = axi_seq_item::type_id::create("wr_txn");
            txn.rw         = axi_seq_item::AXI_WRITE;
            txn.id         = id;
            txn.addr       = addr;
            txn.burst_len  = len;
            txn.burst_size = size;
            txn.burst_type = burst;
            txn.data       = new[num_beats];
            txn.wstrb      = new[num_beats];

            // Collect W channel beats
            for (int beat = 0; beat < num_beats; beat++) begin
                @(vif.mon_cb);
                while (!(vif.mon_cb.wvalid && vif.mon_cb.wready))
                    @(vif.mon_cb);

                txn.data[beat]  = vif.mon_cb.wdata;
                txn.wstrb[beat] = vif.mon_cb.wstrb;
            end

            // Wait for B channel handshake (bvalid && bready)
            @(vif.mon_cb);
            while (!(vif.mon_cb.bvalid && vif.mon_cb.bready))
                @(vif.mon_cb);

            txn.resp = axi_seq_item::axi_resp_e'(vif.mon_cb.bresp);

            `uvm_info("AXI_MON", {"Write transaction captured:", txn.convert2string()}, UVM_HIGH)

            // Broadcast to analysis port
            wr_ap.write(txn);
        end
    endtask : monitor_writes

endclass : axi_monitor
