// AES DMA Mode ECB Sequence
// Tests single-block AES-128/256 ECB encrypt/decrypt via DMA path.
// NIST SP 800-38A Appendix F.1 vectors.

class aes_dma_ecb_seq extends aes_base_seq;
    `uvm_object_utils(aes_dma_ecb_seq)

    bit use_aes256;
    bit use_decrypt;

    // Fixed AXI memory addresses for source and destination
    static bit [31:0] SRC_ADDR = 32'h1000_0000;
    static bit [31:0] DST_ADDR = 32'h2000_0000;

    function new(string name = "aes_dma_ecb_seq");
        super.new(name);
    endfunction

    virtual task body();
        logic [127:0] plaintext, ciphertext, result;
        logic [255:0] key;

        super.pre_body();

        if (!use_aes256) begin
            // NIST SP 800-38A F.1.1/F.1.2: AES-128 ECB
            key        = {128'h2b7e1516_28aed2a6_abf71588_09cf4f3c, 128'h0};
            plaintext  = 128'h6bc1bee2_2e409f96_e93d7e11_7393172a;
            ciphertext = 128'h3ad77bb4_0d7a3660_a89ecaf3_2466ef97;
        end else begin
            // NIST SP 800-38A F.1.5/F.1.6: AES-256 ECB
            key        = 256'h603deb10_15ca71be_2b73aef0_857d7781_1f352c07_3b6108d7_2d9810a3_0914dff4;
            plaintext  = 128'h6bc1bee2_2e409f96_e93d7e11_7393172a;
            ciphertext = 128'hf3eed1bd_b5d2a03c_064b5a7e_3db181f8;
        end

        `uvm_info("DMA_ECB", $sformatf("Running AES-%0d ECB DMA %s test",
                   use_aes256 ? 256 : 128,
                   use_decrypt ? "decrypt" : "encrypt"), UVM_LOW)

        // Preload source memory with input data
        if (use_decrypt)
            preload_block(SRC_ADDR, ciphertext);
        else
            preload_block(SRC_ADDR, plaintext);

        // Configure DUT
        set_mode(use_decrypt, use_aes256);
        write_key(key, use_aes256);
        write_reg(reg_model.dma_enable,   32'h1); // DMA mode
        write_reg(reg_model.block_mode,   32'h0); // ECB
        write_reg(reg_model.block_num,    32'h1); // 1 block
        write_reg(reg_model.dma_src_addr, SRC_ADDR);
        write_reg(reg_model.dma_dst_addr, DST_ADDR);

        // Trigger and wait for DMA completion
        trigger_and_wait_dma();

        // Read result from destination memory and verify
        result = read_block(DST_ADDR);

        if (use_decrypt)
            void'(compare_128(result, plaintext,  "AES DMA ECB Decrypt"));
        else
            void'(compare_128(result, ciphertext, "AES DMA ECB Encrypt"));

    endtask

endclass
