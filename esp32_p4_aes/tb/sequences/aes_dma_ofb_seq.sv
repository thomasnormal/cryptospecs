// AES DMA Mode OFB Sequence
// Tests 2-block AES-128 or AES-256 OFB encrypt/decrypt via DMA.
// NIST SP 800-38A Appendix F.4 vectors.
// OFB is self-inverse: encrypt and decrypt use the same sequence.

class aes_dma_ofb_seq extends aes_base_seq;
    `uvm_object_utils(aes_dma_ofb_seq)

    // OFB direction flag — kept for symmetry with CBC/CTR, but the
    // hardware always runs AES-encrypt internally regardless.
    bit use_decrypt;
    bit use_aes256;

    static bit [31:0] SRC_ADDR = 32'h1000_2000;
    static bit [31:0] DST_ADDR = 32'h2000_2000;

    function new(string name = "aes_dma_ofb_seq");
        super.new(name);
    endfunction

    virtual task body();
        logic [255:0] key;
        logic [127:0] iv;
        logic [127:0] pt[2], ct[2], result[2];

        super.pre_body();

        if (use_aes256) begin
            // NIST SP 800-38A F.4.5/F.4.6: AES-256 OFB, 2 blocks
            key = 256'h603deb10_15ca71be_2b73aef0_857d7781_1f352c07_3b6108d7_2d9810a3_0914dff4;
            iv  = 128'h00010203_04050607_08090a0b_0c0d0e0f;
            pt[0] = 128'h6bc1bee2_2e409f96_e93d7e11_7393172a;
            pt[1] = 128'hae2d8a57_1e03ac9c_9eb76fac_45af8e51;
            ct[0] = 128'hdc7e84bf_da79164b_7ecd8486_985d3860;
            ct[1] = 128'h4febdc67_40d20b3a_c88f6ad8_2a4fb08d;
        end else begin
            // NIST SP 800-38A F.4.1/F.4.2: AES-128 OFB, 2 blocks
            key = {128'h2b7e1516_28aed2a6_abf71588_09cf4f3c, 128'h0};
            iv  = 128'h00010203_04050607_08090a0b_0c0d0e0f;
            pt[0] = 128'h6bc1bee2_2e409f96_e93d7e11_7393172a;
            pt[1] = 128'hae2d8a57_1e03ac9c_9eb76fac_45af8e51;
            ct[0] = 128'h3b3fd92e_b72dad20_333449f8_e83cfb4a;
            ct[1] = 128'h7789508d_16918f03_f53c52da_c54ed825;
        end

        `uvm_info("DMA_OFB", $sformatf("Running AES-%0d OFB DMA %s test (2 blocks)",
                   use_aes256 ? 256 : 128,
                   use_decrypt ? "decrypt" : "encrypt"), UVM_LOW)

        if (use_decrypt) begin
            preload_block(SRC_ADDR,      ct[0]);
            preload_block(SRC_ADDR + 16, ct[1]);
        end else begin
            preload_block(SRC_ADDR,      pt[0]);
            preload_block(SRC_ADDR + 16, pt[1]);
        end

        // OFB: MODE decrypt bit is irrelevant (hardware always encrypts the IV);
        // use encrypt mode as the canonical setting.
        set_mode(1'b0, use_aes256);
        write_key(key, use_aes256);
        write_iv(iv);
        write_reg(reg_model.dma_enable,   32'h1); // DMA mode
        write_reg(reg_model.block_mode,   32'h2); // OFB
        write_reg(reg_model.block_num,    32'h2); // 2 blocks
        write_reg(reg_model.dma_src_addr, SRC_ADDR);
        write_reg(reg_model.dma_dst_addr, DST_ADDR);

        trigger_and_wait_dma();

        result[0] = read_block(DST_ADDR);
        result[1] = read_block(DST_ADDR + 16);

        if (use_decrypt) begin
            void'(compare_128(result[0], pt[0], "AES DMA OFB Decrypt Block 0"));
            void'(compare_128(result[1], pt[1], "AES DMA OFB Decrypt Block 1"));
        end else begin
            void'(compare_128(result[0], ct[0], "AES DMA OFB Encrypt Block 0"));
            void'(compare_128(result[1], ct[1], "AES DMA OFB Encrypt Block 1"));
        end

    endtask

endclass
