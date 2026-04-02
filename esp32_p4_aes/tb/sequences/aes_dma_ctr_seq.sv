// AES DMA Mode CTR Sequence
// Tests 2-block AES-128 or AES-256 CTR encrypt/decrypt via DMA.
// NIST SP 800-38A Appendix F.5 vectors (INC32 / INC(T) with T=32).
// CTR is self-inverse: same sequence for encrypt and decrypt.

class aes_dma_ctr_seq extends aes_base_seq;
    `uvm_object_utils(aes_dma_ctr_seq)

    bit use_decrypt;
    bit use_aes256;

    static bit [31:0] SRC_ADDR = 32'h1000_3000;
    static bit [31:0] DST_ADDR = 32'h2000_3000;

    function new(string name = "aes_dma_ctr_seq");
        super.new(name);
    endfunction

    virtual task body();
        logic [255:0] key;
        logic [127:0] iv;
        logic [127:0] pt[2], ct[2], result[2];

        super.pre_body();

        if (use_aes256) begin
            // NIST SP 800-38A F.5.5/F.5.6: AES-256 CTR, 2 blocks
            key = 256'h603deb10_15ca71be_2b73aef0_857d7781_1f352c07_3b6108d7_2d9810a3_0914dff4;
            iv  = 128'hf0f1f2f3_f4f5f6f7_f8f9fafb_fcfdfeff;
            pt[0] = 128'h6bc1bee2_2e409f96_e93d7e11_7393172a;
            pt[1] = 128'hae2d8a57_1e03ac9c_9eb76fac_45af8e51;
            ct[0] = 128'h601ec313_775789a5_b7a7f504_bbf3d228;
            ct[1] = 128'hf443e3ca_4d62b59a_ca84e990_cacaf5c5;
        end else begin
            // NIST SP 800-38A F.5.1/F.5.2: AES-128 CTR, 2 blocks
            // Initial counter: f0f1f2f3_f4f5f6f7_f8f9fafb_fcfdfeff
            // INC32 increments bits[31:0]: fcfdfeff → fcfdff00 → fcfdff01
            key = {128'h2b7e1516_28aed2a6_abf71588_09cf4f3c, 128'h0};
            iv  = 128'hf0f1f2f3_f4f5f6f7_f8f9fafb_fcfdfeff;
            pt[0] = 128'h6bc1bee2_2e409f96_e93d7e11_7393172a;
            pt[1] = 128'hae2d8a57_1e03ac9c_9eb76fac_45af8e51;
            ct[0] = 128'h874d6191_b620e326_1bef6864_990db6ce;
            ct[1] = 128'h9806f66b_7970fdff_8617187b_b9fffdff;
        end

        `uvm_info("DMA_CTR", $sformatf("Running AES-%0d CTR DMA %s test (2 blocks)",
                   use_aes256 ? 256 : 128,
                   use_decrypt ? "decrypt" : "encrypt"), UVM_LOW)

        if (use_decrypt) begin
            preload_block(SRC_ADDR,      ct[0]);
            preload_block(SRC_ADDR + 16, ct[1]);
        end else begin
            preload_block(SRC_ADDR,      pt[0]);
            preload_block(SRC_ADDR + 16, pt[1]);
        end

        // CTR: direction bit is ignored by RTL (always encrypts the counter).
        // Set encrypt mode to be explicit.
        set_mode(1'b0, use_aes256);
        write_key(key, use_aes256);
        write_iv(iv);
        write_reg(reg_model.dma_enable,   32'h1); // DMA mode
        write_reg(reg_model.block_mode,   32'h3); // CTR
        write_reg(reg_model.block_num,    32'h2); // 2 blocks
        write_reg(reg_model.inc_sel,      32'h0); // INC32
        write_reg(reg_model.dma_src_addr, SRC_ADDR);
        write_reg(reg_model.dma_dst_addr, DST_ADDR);

        trigger_and_wait_dma();

        result[0] = read_block(DST_ADDR);
        result[1] = read_block(DST_ADDR + 16);

        if (use_decrypt) begin
            void'(compare_128(result[0], pt[0], "AES DMA CTR Decrypt Block 0"));
            void'(compare_128(result[1], pt[1], "AES DMA CTR Decrypt Block 1"));
        end else begin
            void'(compare_128(result[0], ct[0], "AES DMA CTR Encrypt Block 0"));
            void'(compare_128(result[1], ct[1], "AES DMA CTR Encrypt Block 1"));
        end

    endtask

endclass
