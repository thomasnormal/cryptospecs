// AXI Agent Package
// Encapsulates all UVM classes for the AXI4 reactive slave agent.

package axi_agent_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "axi_seq_item.sv"
    `include "axi_mem_model.sv"
    `include "axi_slave_driver.sv"
    `include "axi_monitor.sv"
    `include "axi_slave_agent.sv"

endpackage : axi_agent_pkg
