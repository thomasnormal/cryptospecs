// AES DMA 256-bit ECB Test
// Runs AES-256 ECB encrypt then decrypt via DMA path.

class aes_dma_256_ecb_test extends aes_base_test;
    `uvm_component_utils(aes_dma_256_ecb_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        aes_dma_ecb_seq seq;
        phase.raise_objection(this);

        // Encrypt
        seq = aes_dma_ecb_seq::type_id::create("seq");
        seq.use_aes256  = 1;
        seq.use_decrypt = 0;
        seq.start(env.v_sqr);

        // Decrypt
        seq = aes_dma_ecb_seq::type_id::create("seq");
        seq.use_aes256  = 1;
        seq.use_decrypt = 1;
        seq.start(env.v_sqr);

        phase.drop_objection(this);
        `uvm_info("TEST", "*** TEST PASSED ***", UVM_LOW)
    endtask

endclass
