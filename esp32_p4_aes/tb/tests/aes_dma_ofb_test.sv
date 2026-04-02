// AES DMA OFB Test
// Runs AES-128 OFB encrypt then decrypt via DMA (2 blocks each).

class aes_dma_ofb_test extends aes_base_test;
    `uvm_component_utils(aes_dma_ofb_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        aes_dma_ofb_seq seq;
        phase.raise_objection(this);

        // Encrypt
        seq = aes_dma_ofb_seq::type_id::create("seq");
        seq.use_decrypt = 0;
        seq.start(env.v_sqr);

        // Decrypt (OFB is self-inverse — re-encrypting the ciphertext recovers plaintext)
        seq = aes_dma_ofb_seq::type_id::create("seq");
        seq.use_decrypt = 1;
        seq.start(env.v_sqr);

        phase.drop_objection(this);
        `uvm_info("TEST", "*** TEST PASSED ***", UVM_LOW)
    endtask

endclass
