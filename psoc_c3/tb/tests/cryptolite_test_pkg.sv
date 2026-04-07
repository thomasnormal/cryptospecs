package cryptolite_test_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import cryptolite_pkg::*;
    import ahb_agent_pkg::*;
    import irq_agent_pkg::*;
    import cryptolite_env_pkg::*;
    import cryptolite_seq_pkg::*;

    `include "cryptolite_base_test.sv"
    `include "cryptolite_feature_tests.sv"

endpackage
