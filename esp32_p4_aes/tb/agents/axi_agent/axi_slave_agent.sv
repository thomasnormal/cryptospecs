// AXI4 Slave Agent
// Reactive agent that responds to a DUT's AXI master port.
// Instantiates the reactive slave driver and monitor.
// No sequencer is used - the driver responds directly based
// on the memory model.

class axi_slave_agent extends uvm_agent;

    `uvm_component_utils(axi_slave_agent)

    // ---------------------------------------------------------------
    // Sub-components
    // ---------------------------------------------------------------
    axi_slave_driver  driver;
    axi_monitor       monitor;
    axi_mem_model     mem;

    // ---------------------------------------------------------------
    // Constructor
    // ---------------------------------------------------------------
    function new(string name = "axi_slave_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    // ---------------------------------------------------------------
    // Build Phase
    // ---------------------------------------------------------------
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Always create the memory model
        mem = axi_mem_model::type_id::create("mem");

        // Always create the monitor
        monitor = axi_monitor::type_id::create("monitor", this);

        // Create the driver only in ACTIVE mode
        if (get_is_active() == UVM_ACTIVE) begin
            driver = axi_slave_driver::type_id::create("driver", this);
        end
    endfunction : build_phase

    // ---------------------------------------------------------------
    // Connect Phase
    // ---------------------------------------------------------------
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Share the memory model with the driver
        if (get_is_active() == UVM_ACTIVE) begin
            driver.mem = mem;
        end
    endfunction : connect_phase

endclass : axi_slave_agent
