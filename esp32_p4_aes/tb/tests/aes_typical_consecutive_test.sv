// AES Typical Consecutive ECB Test
// Runs 4 back-to-back AES-128 ECB encryptions with different plaintexts
// but the same key, without re-writing the key registers between operations.
// Uses all 4 NIST SP 800-38A AES-128 ECB encrypt vectors.

class aes_typical_consecutive_test extends aes_base_test;
    `uvm_component_utils(aes_typical_consecutive_test)

    function new(string name = "aes_typical_consecutive_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        aes_consecutive_ecb_seq seq;

        phase.raise_objection(this);
        #200; // Wait for reset

        seq = aes_consecutive_ecb_seq::type_id::create("seq");
        seq.start(env.v_sqr);

        #100;
        phase.drop_objection(this);
    endtask

endclass
