// AES Register Smoke Test
// Runs the register smoke sequence to verify R/W, RO, and WT register behavior.

class aes_reg_smoke_test extends aes_base_test;
    `uvm_component_utils(aes_reg_smoke_test)

    function new(string name = "aes_reg_smoke_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        aes_reg_smoke_seq smoke_seq;

        phase.raise_objection(this);
        #200; // Wait for reset

        smoke_seq = aes_reg_smoke_seq::type_id::create("smoke_seq");
        smoke_seq.start(env.v_sqr);

        #100;
        phase.drop_objection(this);
    endtask

endclass
