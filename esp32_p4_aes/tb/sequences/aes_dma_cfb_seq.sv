// AES DMA Mode CFB-128 Sequence
// Tests 2-block AES-128 CFB-128 encrypt/decrypt via DMA path.
// NIST SP 800-38A Appendix F.3.13/F.3.14 vectors.
// CFB-128: AES core always encrypts the feedback; direction controls feedback source.

class aes_dma_cfb_seq extends aes_base_seq;
    `uvm_object_utils(aes_dma_cfb_seq)

    bit use_decrypt;

    static bit [31:0] SRC_ADDR = 32'h1000_4000;
    static bit [31:0] DST_ADDR = 32'h2000_4000;

    function new(string name = "aes_dma_cfb_seq");
        super.new(name);
    endfunction

    virtual task body();
        logic [255:0] key;
        logic [127:0] iv;
        logic [127:0] pt[2], ct[2], result[2];

        super.pre_body();

        // NIST SP 800-38A F.3.13/F.3.14: AES-128 CFB-128, 2 blocks
        key   = {128'h2b7e1516_28aed2a6_abf71588_09cf4f3c, 128'h0};
        iv    = 128'h00010203_04050607_08090a0b_0c0d0e0f;

        pt[0] = 128'h6bc1bee2_2e409f96_e93d7e11_7393172a;
        pt[1] = 128'hae2d8a57_1e03ac9c_9eb76fac_45af8e51;

        // CT[0] = AES_enc(IV) XOR PT[0]
        // CT[1] = AES_enc(CT[0]) XOR PT[1]  (ciphertext feedback)
        ct[0] = 128'h3b3fd92e_b72dad20_333449f8_e83cfb4a;
        ct[1] = 128'hc8a64537_a0b3a93f_cde3cdad_9f1ce58b;

        `uvm_info("DMA_CFB", $sformatf("Running AES-128 CFB-128 DMA %s test (2 blocks)",
                   use_decrypt ? "decrypt" : "encrypt"), UVM_LOW)

        if (use_decrypt) begin
            preload_block(SRC_ADDR,      ct[0]);
            preload_block(SRC_ADDR + 16, ct[1]);
        end else begin
            preload_block(SRC_ADDR,      pt[0]);
            preload_block(SRC_ADDR + 16, pt[1]);
        end

        // CFB-128: AES core always runs encrypt, direction controls feedback.
        // The decrypt bit in MODE must be set correctly so RTL knows feedback source.
        set_mode(use_decrypt, 1'b0);  // AES-128
        write_key(key, 1'b0);
        write_iv(iv);
        write_reg(reg_model.dma_enable,   32'h1); // DMA mode
        write_reg(reg_model.block_mode,   32'h5); // CFB128
        write_reg(reg_model.block_num,    32'h2); // 2 blocks
        write_reg(reg_model.dma_src_addr, SRC_ADDR);
        write_reg(reg_model.dma_dst_addr, DST_ADDR);

        trigger_and_wait_dma();

        result[0] = read_block(DST_ADDR);
        result[1] = read_block(DST_ADDR + 16);

        if (use_decrypt) begin
            void'(compare_128(result[0], pt[0], "AES DMA CFB128 Decrypt Block 0"));
            void'(compare_128(result[1], pt[1], "AES DMA CFB128 Decrypt Block 1"));
        end else begin
            void'(compare_128(result[0], ct[0], "AES DMA CFB128 Encrypt Block 0"));
            void'(compare_128(result[1], ct[1], "AES DMA CFB128 Encrypt Block 1"));
        end

    endtask

endclass
