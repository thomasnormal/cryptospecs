// AES DMA AES-256 CBC Test
// Runs AES-256 CBC encrypt then decrypt via DMA path (2 blocks each).
// NIST SP 800-38A F.2.5/F.2.6 vectors.

class aes_dma_256_cbc_test extends aes_base_test;
    `uvm_component_utils(aes_dma_256_cbc_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        aes_dma_cbc_seq seq;
        phase.raise_objection(this);

        // Encrypt
        seq = aes_dma_cbc_seq::type_id::create("seq");
        seq.use_decrypt = 0;
        seq.use_aes256  = 1;
        seq.start(env.v_sqr);

        // Decrypt
        seq = aes_dma_cbc_seq::type_id::create("seq");
        seq.use_decrypt = 1;
        seq.use_aes256  = 1;
        seq.start(env.v_sqr);

        phase.drop_objection(this);
        `uvm_info("TEST", "*** TEST PASSED ***", UVM_LOW)
    endtask

endclass
