// AES-128 ECB Typical Mode Test
// Runs AES-128 ECB encrypt and decrypt using NIST test vectors.

class aes_typical_128_ecb_test extends aes_base_test;
    `uvm_component_utils(aes_typical_128_ecb_test)

    function new(string name = "aes_typical_128_ecb_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        aes_typical_ecb_seq enc_seq, dec_seq;

        phase.raise_objection(this);
        #200; // Wait for reset

        // Test encrypt
        enc_seq = aes_typical_ecb_seq::type_id::create("enc_seq");
        enc_seq.use_aes256  = 0;
        enc_seq.use_decrypt = 0;
        enc_seq.start(env.v_sqr);

        #100;

        // Test decrypt
        dec_seq = aes_typical_ecb_seq::type_id::create("dec_seq");
        dec_seq.use_aes256  = 0;
        dec_seq.use_decrypt = 1;
        dec_seq.start(env.v_sqr);

        #100;
        phase.drop_objection(this);
    endtask

endclass
