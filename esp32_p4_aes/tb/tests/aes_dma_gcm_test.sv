// AES DMA GCM Test
// NIST SP 800-38D TC1: AES-128 GCM with empty plaintext and AAD.
// Verifies GHASH subkey H and authentication tag T via two-phase GCM flow.

class aes_dma_gcm_test extends aes_base_test;
    `uvm_component_utils(aes_dma_gcm_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        aes_dma_gcm_seq seq;
        phase.raise_objection(this);

        seq = aes_dma_gcm_seq::type_id::create("seq");
        seq.start(env.v_sqr);

        phase.drop_objection(this);
        `uvm_info("TEST", "*** TEST PASSED ***", UVM_LOW)
    endtask

endclass
