package cryptolite_env_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import cryptolite_pkg::*;
    import ahb_agent_pkg::*;
    import irq_agent_pkg::*;

    `include "cryptolite_scoreboard.sv"
    `include "cryptolite_coverage.sv"
    `include "cryptolite_virtual_sequencer.sv"
    `include "cryptolite_env.sv"

endpackage
