// AES Consecutive ECB Sequence
// Runs 4 back-to-back AES-128 ECB encryptions with different plaintexts
// but the same key, without re-writing the key registers between operations.
// Uses all 4 NIST SP 800-38A AES-128 ECB encrypt vectors (F.1.1).

class aes_consecutive_ecb_seq extends aes_base_seq;
    `uvm_object_utils(aes_consecutive_ecb_seq)

    function new(string name = "aes_consecutive_ecb_seq");
        super.new(name);
    endfunction

    virtual task body();
        logic [255:0] key;
        logic [127:0] plaintext [4];
        logic [127:0] ciphertext[4];
        logic [127:0] result;

        super.pre_body();

        // NIST SP 800-38A F.1.1: AES-128 ECB Encrypt, all 4 blocks
        key = {128'h2b7e1516_28aed2a6_abf71588_09cf4f3c, 128'h0};

        plaintext[0]  = 128'h6bc1bee2_2e409f96_e93d7e11_7393172a;
        ciphertext[0] = 128'h3ad77bb4_0d7a3660_a89ecaf3_2466ef97;

        plaintext[1]  = 128'hae2d8a57_1e03ac9c_9eb76fac_45af8e51;
        ciphertext[1] = 128'hf5d3d585_03b9699d_e785895a_96fdbaaf;

        plaintext[2]  = 128'h30c81c46_a35ce411_e5fbc119_1a0a52ef;
        ciphertext[2] = 128'h43b1cd7f_598ece23_881b00e3_ed030688;

        plaintext[3]  = 128'hf69f2445_df4f9b17_ad2b417b_e66c3710;
        ciphertext[3] = 128'h7b0c785e_27e8ad3f_82232071_04725dd4;

        `uvm_info("CONSEC_ECB", "Starting 4 consecutive AES-128 ECB encryptions", UVM_LOW)

        // Configure mode and key once
        set_mode(.decrypt(0), .aes256(0));
        write_reg(reg_model.dma_enable, 32'h0);  // Typical mode
        write_key(key, .aes256(0));

        // Run 4 encryptions without re-writing the key
        for (int i = 0; i < 4; i++) begin
            `uvm_info("CONSEC_ECB",
                $sformatf("Block %0d: encrypting 0x%032h", i, plaintext[i]), UVM_MEDIUM)

            write_text_in(plaintext[i]);
            trigger_and_wait();
            read_text_out(result);

            if (!compare_128(result, ciphertext[i],
                    $sformatf("Consecutive ECB Block %0d", i)))
                `uvm_error("CONSEC_ECB",
                    $sformatf("Block %0d FAILED", i))
            else
                `uvm_info("CONSEC_ECB",
                    $sformatf("Block %0d PASSED", i), UVM_LOW)
        end

        `uvm_info("CONSEC_ECB", "All 4 consecutive ECB encryptions complete", UVM_LOW)
    endtask

endclass
