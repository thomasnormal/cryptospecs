// AES Typical Mode ECB Sequence
// Tests single-block AES-128/256 ECB encrypt and decrypt using NIST SP 800-38A vectors.

class aes_typical_ecb_seq extends aes_base_seq;
    `uvm_object_utils(aes_typical_ecb_seq)

    bit use_aes256;
    bit use_decrypt;

    function new(string name = "aes_typical_ecb_seq");
        super.new(name);
    endfunction

    virtual task body();
        logic [127:0] plaintext, ciphertext, result;
        logic [255:0] key;

        super.pre_body();

        if (!use_aes256) begin
            // NIST SP 800-38A: AES-128 ECB test vector (Block #1)
            key        = {128'h2b7e1516_28aed2a6_abf71588_09cf4f3c, 128'h0};
            plaintext  = 128'h6bc1bee2_2e409f96_e93d7e11_7393172a;
            ciphertext = 128'h3ad77bb4_0d7a3660_a89ecaf3_2466ef97;
        end else begin
            // NIST SP 800-38A: AES-256 ECB test vector (Block #1)
            key        = 256'h603deb10_15ca71be_2b73aef0_857d7781_1f352c07_3b6108d7_2d9810a3_0914dff4;
            plaintext  = 128'h6bc1bee2_2e409f96_e93d7e11_7393172a;
            ciphertext = 128'hf3eed1bd_b5d2a03c_064b5a7e_3db181f8;
        end

        `uvm_info("AES_ECB", $sformatf("Running AES-%0d ECB %s test",
                   use_aes256 ? 256 : 128, use_decrypt ? "decrypt" : "encrypt"), UVM_LOW)

        // Configure
        set_mode(use_decrypt, use_aes256);
        write_reg(reg_model.dma_enable, 32'h0);  // Typical mode
        write_key(key, use_aes256);

        if (use_decrypt)
            write_text_in(ciphertext);
        else
            write_text_in(plaintext);

        // Execute
        trigger_and_wait();

        // Read and check result
        read_text_out(result);

        if (use_decrypt)
            compare_128(result, plaintext, "AES ECB Decrypt");
        else
            compare_128(result, ciphertext, "AES ECB Encrypt");
    endtask

endclass
