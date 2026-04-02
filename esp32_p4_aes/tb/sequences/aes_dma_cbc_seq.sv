// AES DMA Mode CBC Sequence
// Tests 2-block AES-128 or AES-256 CBC encrypt/decrypt via DMA path.
// NIST SP 800-38A Appendix F.2 vectors.

class aes_dma_cbc_seq extends aes_base_seq;
    `uvm_object_utils(aes_dma_cbc_seq)

    bit use_decrypt;
    bit use_aes256;

    // Fixed AXI memory addresses
    static bit [31:0] SRC_ADDR = 32'h1000_1000;
    static bit [31:0] DST_ADDR = 32'h2000_1000;

    function new(string name = "aes_dma_cbc_seq");
        super.new(name);
    endfunction

    virtual task body();
        logic [255:0] key;
        logic [127:0] iv;
        logic [127:0] pt[2], ct[2], result[2];

        super.pre_body();

        if (use_aes256) begin
            // NIST SP 800-38A F.2.5/F.2.6: AES-256 CBC, 2 blocks
            key = 256'h603deb10_15ca71be_2b73aef0_857d7781_1f352c07_3b6108d7_2d9810a3_0914dff4;
            iv  = 128'h00010203_04050607_08090a0b_0c0d0e0f;
            pt[0] = 128'h6bc1bee2_2e409f96_e93d7e11_7393172a;
            pt[1] = 128'hae2d8a57_1e03ac9c_9eb76fac_45af8e51;
            ct[0] = 128'hf58c4c04_d6e5f1ba_779eabfb_5f7bfbd6;
            ct[1] = 128'h9cfc4e96_7edb808d_679f777b_c6702c7d;
        end else begin
            // NIST SP 800-38A F.2.1/F.2.2: AES-128 CBC, 2 blocks
            key   = {128'h2b7e1516_28aed2a6_abf71588_09cf4f3c, 128'h0};
            iv    = 128'h00010203_04050607_08090a0b_0c0d0e0f;
            pt[0] = 128'h6bc1bee2_2e409f96_e93d7e11_7393172a;
            pt[1] = 128'hae2d8a57_1e03ac9c_9eb76fac_45af8e51;
            ct[0] = 128'h7649abac_8119b246_cee98e9b_12e9197d;
            ct[1] = 128'h5086cb9b_507219ee_95db113a_917678b2;
        end

        `uvm_info("DMA_CBC", $sformatf("Running AES-%0d CBC DMA %s test (2 blocks)",
                   use_aes256 ? 256 : 128,
                   use_decrypt ? "decrypt" : "encrypt"), UVM_LOW)

        // Preload source memory with 2 blocks
        if (use_decrypt) begin
            preload_block(SRC_ADDR,      ct[0]);
            preload_block(SRC_ADDR + 16, ct[1]);
        end else begin
            preload_block(SRC_ADDR,      pt[0]);
            preload_block(SRC_ADDR + 16, pt[1]);
        end

        // Configure DUT
        set_mode(use_decrypt, use_aes256);
        write_key(key, use_aes256);
        write_iv(iv);
        write_reg(reg_model.dma_enable,   32'h1); // DMA mode
        write_reg(reg_model.block_mode,   32'h1); // CBC
        write_reg(reg_model.block_num,    32'h2); // 2 blocks
        write_reg(reg_model.dma_src_addr, SRC_ADDR);
        write_reg(reg_model.dma_dst_addr, DST_ADDR);

        // Trigger and wait for DMA completion
        trigger_and_wait_dma();

        // Read back and verify both blocks
        result[0] = read_block(DST_ADDR);
        result[1] = read_block(DST_ADDR + 16);

        if (use_decrypt) begin
            void'(compare_128(result[0], pt[0], "AES DMA CBC Decrypt Block 0"));
            void'(compare_128(result[1], pt[1], "AES DMA CBC Decrypt Block 1"));
        end else begin
            void'(compare_128(result[0], ct[0], "AES DMA CBC Encrypt Block 0"));
            void'(compare_128(result[1], ct[1], "AES DMA CBC Encrypt Block 1"));
        end

    endtask

endclass
