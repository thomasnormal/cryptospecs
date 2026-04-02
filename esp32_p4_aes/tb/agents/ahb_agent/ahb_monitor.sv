// AHB-Lite Monitor
// Passively observes the AHB-Lite bus and reconstructs completed transfers.

class ahb_monitor extends uvm_monitor;

    `uvm_component_utils(ahb_monitor)

    virtual ahb_if vif;

    uvm_analysis_port #(ahb_seq_item) analysis_port;

    function new(string name = "ahb_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_port = new("analysis_port", this);
        if (!uvm_config_db#(virtual ahb_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not found in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        ahb_seq_item txn;
        bit [31:0]   saved_addr;
        bit          saved_write;
        bit [2:0]    saved_hsize;
        bit          addr_phase_valid;

        // Wait for reset de-assertion
        @(posedge vif.rst_n);

        forever begin
            @(posedge vif.clk);

            // Detect a completed data phase: the PREVIOUS cycle had a valid address phase
            if (addr_phase_valid && vif.hreadyout) begin
                txn = ahb_seq_item::type_id::create("txn");
                txn.addr  = saved_addr;
                txn.hsize = saved_hsize;

                if (saved_write) begin
                    txn.op    = AHB_WRITE;
                    txn.wdata = vif.hwdata;
                    txn.rdata = 32'h0;
                end else begin
                    txn.op    = AHB_READ;
                    txn.rdata = vif.hrdata;
                    txn.wdata = 32'h0;
                end

                analysis_port.write(txn);
                addr_phase_valid = 1'b0;
            end

            // Detect a valid address phase this cycle
            if (vif.hsel && (vif.htrans == 2'b10) && vif.hreadyout) begin
                saved_addr  = vif.haddr;
                saved_write = vif.hwrite;
                saved_hsize = vif.hsize;
                addr_phase_valid = 1'b1;
            end
        end
    endtask

endclass
