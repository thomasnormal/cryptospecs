// AES GCM Sequence — NIST SP 800-38D Test Case 1
// AES-128, empty plaintext and AAD, verifies H and authentication tag T.
//
// K  = 0x00000000000000000000000000000000
// IV = 0x000000000000000000000000 (96-bit)
// J0 = IV || 0x00000001 = 0x00000000000000000000000000000001
// H  = AES_K(0^128) = 0x66e94bd4ef8a2c3b884cfa59ca342b2e
// C  = ""  (no plaintext)
// T  = AES_K(J0) = 0x58e2fccefa7e3061367f1d57a4e7455a

class aes_dma_gcm_seq extends aes_base_seq;
    `uvm_object_utils(aes_dma_gcm_seq)

    function new(string name = "aes_dma_gcm_seq");
        super.new(name);
    endfunction

    virtual task body();
        logic [255:0] key;
        logic [127:0] iv;
        logic [127:0] j0;
        logic [127:0] h_actual, t0_actual;

        // NIST expected values
        logic [127:0] h_expected  = 128'h66e94bd4_ef8a2c3b_884cfa59_ca342b2e;
        logic [127:0] t0_expected = 128'h58e2fcce_fa7e3061_367f1d57_a4e7455a;

        super.pre_body();

        key = 256'h0;           // AES-128: all-zero key (bits[255:128] used)
        iv  = 128'h0;           // IV not used directly for GCM tag computation
        j0  = 128'h00000000_00000000_00000000_00000001;

        `uvm_info("DMA_GCM", "Running GCM TC1: AES-128, empty PT/AAD, verify H and T", UVM_LOW)

        // -------------------------------------------------------
        // GCM Phase 1: compute H (GHASH subkey) and process data
        // -------------------------------------------------------
        set_mode(1'b0, 1'b0);           // AES-128 encrypt
        write_key(key, 1'b0);
        write_iv(iv);
        write_reg(reg_model.dma_enable,         32'h1); // DMA mode (required for GCM)
        write_reg(reg_model.block_mode,         32'h6); // GCM
        write_reg(reg_model.block_num,          32'h0); // 0 data blocks (TC1)
        write_reg(reg_model.aad_block_num,      32'h0); // 0 AAD blocks (TC1)
        write_reg(reg_model.remainder_bit_num,  32'h0); // no partial blocks
        write_reg(reg_model.int_ena,            32'h0); // interrupt disabled for polling

        // Trigger Phase 1
        write_reg(reg_model.trigger, 32'h1);

        // Wait for Phase 1 complete (STATE == DONE)
        poll_until_done();

        // Read and verify H
        read_h(h_actual);
        void'(compare_128(h_actual, h_expected, "GCM H (GHASH subkey)"));

        // -------------------------------------------------------
        // GCM Phase 2: write J0 then trigger tag computation
        // -------------------------------------------------------
        write_j0(j0);
        write_reg(reg_model.continue_op, 32'h1);

        // Wait for Phase 2 complete (gcm_p2_done_latch → STATE == DONE)
        poll_until_done();

        // Read and verify authentication tag
        read_t0(t0_actual);
        void'(compare_128(t0_actual, t0_expected, "GCM authentication tag T"));

        // Return to IDLE (clears gcm_p2_done_latch)
        write_reg(reg_model.dma_exit, 32'h1);

    endtask

endclass
