// ---------------------------------------------------------------------------
// AES Environment Package
// Imports all agent packages, the RAL package, and includes environment
// source files.
// UVM 1.2 methodology.
// ---------------------------------------------------------------------------

package aes_env_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import ahb_agent_pkg::*;
    import axi_agent_pkg::*;
    import aes_ral_pkg::*;
    import aes_accel_pkg::*;
    import aes_ref_model_pkg::*;

    `include "aes_scoreboard.sv"
    `include "aes_coverage.sv"
    `include "aes_virtual_sequencer.sv"
    `include "aes_env.sv"

endpackage
