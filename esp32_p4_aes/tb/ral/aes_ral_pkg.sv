// ---------------------------------------------------------------------------
// AES RAL Package
// Imports uvm_pkg and ahb_agent_pkg; includes all RAL source files.
// UVM 1.2 methodology.
// ---------------------------------------------------------------------------

package aes_ral_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import ahb_agent_pkg::*;

    `include "aes_reg_block.sv"
    `include "aes_reg_adapter.sv"

endpackage
