class cryptolite_aes_ecb_seq extends cryptolite_base_seq;
    `uvm_object_utils(cryptolite_aes_ecb_seq)
    function new(string name = "cryptolite_aes_ecb_seq");
        super.new(name);
    endfunction
    virtual task body();
        localparam bit [31:0] DESCR = 32'h0000_0100;
        localparam bit [31:0] KEY   = 32'h0000_0140;
        localparam bit [31:0] PT    = 32'h0000_0180;
        localparam bit [31:0] CT    = 32'h0000_01c0;
        super.pre_body();
        mem_clear();
        mem_write_word(DESCR + 0, KEY);
        mem_write_word(DESCR + 4, PT);
        mem_write_word(DESCR + 8, CT);
        mem_write_word(KEY +  0, 32'h2b7e1516);
        mem_write_word(KEY +  4, 32'h28aed2a6);
        mem_write_word(KEY +  8, 32'habf71588);
        mem_write_word(KEY + 12, 32'h09cf4f3c);
        mem_write_word(PT  +  0, 32'h6bc1bee2);
        mem_write_word(PT  +  4, 32'h2e409f96);
        mem_write_word(PT  +  8, 32'he93d7e11);
        mem_write_word(PT  + 12, 32'h7393172a);
        write_reg(AES_DESCR, DESCR);
        wait_operation_complete();
        expect_mem_word(CT +  0, 32'h3ad77bb4, "aes");
        expect_mem_word(CT +  4, 32'h0d7a3660, "aes");
        expect_mem_word(CT +  8, 32'ha89ecaf3, "aes");
        expect_mem_word(CT + 12, 32'h2466ef97, "aes");
    endtask
endclass

class cryptolite_sha256_sch_seq extends cryptolite_base_seq;
    `uvm_object_utils(cryptolite_sha256_sch_seq)
    function new(string name = "cryptolite_sha256_sch_seq");
        super.new(name);
    endfunction
    virtual task body();
        localparam bit [31:0] DESCR = 32'h0000_0200;
        localparam bit [31:0] BLOCK = 32'h0000_0240;
        localparam bit [31:0] SCHED = 32'h0000_0300;
        bit [31:0] block[0:15];
        bit [31:0] sched[0:63];
        bit [31:0] hash_init[0:7];
        bit [31:0] hash_exp[0:7];
        int i;
        super.pre_body();
        mem_clear();
        prepare_sha_abc(block, sched, hash_init, hash_exp);
        mem_write_word(DESCR + 0, 32'h0);
        mem_write_word(DESCR + 4, BLOCK);
        mem_write_word(DESCR + 8, SCHED);
        for (i = 0; i < 16; i++) mem_write_word(BLOCK + (i * 4), block[i]);
        write_reg(SHA_DESCR, DESCR);
        wait_operation_complete();
        for (i = 0; i < 64; i++) expect_mem_word(SCHED + (i * 4), sched[i], "sha_sched");
    endtask
endclass

class cryptolite_sha256_proc_seq extends cryptolite_base_seq;
    `uvm_object_utils(cryptolite_sha256_proc_seq)
    function new(string name = "cryptolite_sha256_proc_seq");
        super.new(name);
    endfunction
    virtual task body();
        localparam bit [31:0] DESCR = 32'h0000_0400;
        localparam bit [31:0] HMEM  = 32'h0000_0440;
        localparam bit [31:0] SCHED = 32'h0000_0500;
        bit [31:0] block[0:15];
        bit [31:0] sched[0:63];
        bit [31:0] hash_init[0:7];
        bit [31:0] hash_exp[0:7];
        int i;
        super.pre_body();
        mem_clear();
        prepare_sha_abc(block, sched, hash_init, hash_exp);
        mem_write_word(DESCR + 0, 32'h1000_0000);
        mem_write_word(DESCR + 4, HMEM);
        mem_write_word(DESCR + 8, SCHED);
        for (i = 0; i < 8; i++) mem_write_word(HMEM + (i * 4), hash_init[i]);
        for (i = 0; i < 64; i++) mem_write_word(SCHED + (i * 4), sched[i]);
        write_reg(SHA_DESCR, DESCR);
        wait_operation_complete();
        for (i = 0; i < 8; i++) expect_mem_word(HMEM + (i * 4), hash_exp[i], "sha_proc");
    endtask
endclass

class cryptolite_sha256_full_seq extends cryptolite_base_seq;
    `uvm_object_utils(cryptolite_sha256_full_seq)
    function new(string name = "cryptolite_sha256_full_seq");
        super.new(name);
    endfunction
    virtual task body();
        localparam bit [31:0] DESCR0 = 32'h0000_0600;
        localparam bit [31:0] DESCR1 = 32'h0000_0610;
        localparam bit [31:0] BLOCK  = 32'h0000_0640;
        localparam bit [31:0] SCHED  = 32'h0000_0700;
        localparam bit [31:0] HMEM   = 32'h0000_0800;
        bit [31:0] block[0:15];
        bit [31:0] sched[0:63];
        bit [31:0] hash_init[0:7];
        bit [31:0] hash_exp[0:7];
        int i;
        super.pre_body();
        mem_clear();
        prepare_sha_abc(block, sched, hash_init, hash_exp);
        mem_write_word(DESCR0 + 0, 32'h0);
        mem_write_word(DESCR0 + 4, BLOCK);
        mem_write_word(DESCR0 + 8, SCHED);
        mem_write_word(DESCR1 + 0, 32'h1000_0000);
        mem_write_word(DESCR1 + 4, HMEM);
        mem_write_word(DESCR1 + 8, SCHED);
        for (i = 0; i < 16; i++) mem_write_word(BLOCK + (i * 4), block[i]);
        for (i = 0; i < 8; i++) mem_write_word(HMEM + (i * 4), hash_init[i]);
        write_reg(SHA_DESCR, DESCR0);
        wait_operation_complete();
        write_reg(SHA_DESCR, DESCR1);
        wait_operation_complete();
        for (i = 0; i < 8; i++) expect_mem_word(HMEM + (i * 4), hash_exp[i], "sha_full");
    endtask
endclass

class cryptolite_trng_basic_seq extends cryptolite_base_seq;
    `uvm_object_utils(cryptolite_trng_basic_seq)
    function new(string name = "cryptolite_trng_basic_seq");
        super.new(name);
    endfunction
    virtual task body();
        bit [31:0] rnd;
        bit [31:0] intr_word;
        super.pre_body();
        mem_clear();
        write_reg(TRNG_CTL1, 32'h0000_0001);
        write_reg(INTR_TRNG_MASK, 32'h0000_0002);
        read_reg(TRNG_RESULT, rnd);
        read_reg(INTR_TRNG, intr_word);
        if (!intr_word[INTR_TRNG_BIT_INITIALIZED] || !intr_word[INTR_TRNG_BIT_DATA_AVAILABLE])
            `uvm_fatal("TRNG_BASIC", $sformatf("Unexpected INTR_TRNG value 0x%08h", intr_word))
        if (!irq_vif.irq)
            `uvm_fatal("TRNG_BASIC", "IRQ was not asserted")
        write_reg(INTR_TRNG, 32'h0000_0002);
        expect_reg(INTR_TRNG_MASKED, 32'h0, "trng_basic");
    endtask
endclass

class cryptolite_trng_vn_seq extends cryptolite_base_seq;
    `uvm_object_utils(cryptolite_trng_vn_seq)
    function new(string name = "cryptolite_trng_vn_seq");
        super.new(name);
    endfunction
    virtual task body();
        bit [31:0] rnd0, rnd1;
        super.pre_body();
        mem_clear();
        write_reg(TRNG_CTL0, 32'h0103_0000);
        write_reg(TRNG_CTL1, 32'h0000_0001);
        read_reg(TRNG_RESULT, rnd0);
        read_reg(TRNG_RESULT, rnd1);
        `uvm_info("TRNG_VN", $sformatf("VN samples 0x%08h 0x%08h", rnd0, rnd1), UVM_LOW)
    endtask
endclass

class cryptolite_trng_rc_seq extends cryptolite_base_seq;
    `uvm_object_utils(cryptolite_trng_rc_seq)
    function new(string name = "cryptolite_trng_rc_seq");
        super.new(name);
    endfunction
    virtual task body();
        bit [31:0] intr_word;
        super.pre_body();
        mem_clear();
        write_reg(TRNG_CTL1, 32'h0000_0001);
        write_reg(TRNG_MON_CTL, 32'h0000_0200);
        write_reg(TRNG_MON_RC_CTL, 32'h0000_0001);
        write_reg(INTR_TRNG_MASK, 32'h0000_0008);
        wait_irq_high(10000);
        read_reg(INTR_TRNG, intr_word);
        if (!intr_word[INTR_TRNG_BIT_RC_DETECT])
            `uvm_fatal("TRNG_RC", $sformatf("RC bit missing: 0x%08h", intr_word))
    endtask
endclass

class cryptolite_trng_ap_seq extends cryptolite_base_seq;
    `uvm_object_utils(cryptolite_trng_ap_seq)
    function new(string name = "cryptolite_trng_ap_seq");
        super.new(name);
    endfunction
    virtual task body();
        bit [31:0] intr_word;
        super.pre_body();
        mem_clear();
        write_reg(TRNG_CTL1, 32'h0000_0001);
        write_reg(TRNG_MON_CTL, 32'h0000_0100);
        write_reg(TRNG_MON_AP_CTL, 32'h0000_0002);
        write_reg(INTR_TRNG_MASK, 32'h0000_0004);
        expect_reg(TRNG_MON_CTL, 32'h0000_0100, "trng_ap");
        expect_reg(TRNG_MON_AP_CTL, 32'h0000_0002, "trng_ap");
        wait_irq_high(10000);
        read_reg(INTR_TRNG, intr_word);
        if (!intr_word[INTR_TRNG_BIT_AP_DETECT])
            `uvm_fatal("TRNG_AP", $sformatf("AP bit missing: 0x%08h", intr_word))
    endtask
endclass

class cryptolite_vu_add_seq extends cryptolite_base_seq;
    `uvm_object_utils(cryptolite_vu_add_seq)
    function new(string name = "cryptolite_vu_add_seq");
        super.new(name);
    endfunction
    virtual task body();
        localparam bit [31:0] DESCR = 32'h0000_0900;
        localparam bit [31:0] SRC0  = 32'h0000_0940;
        localparam bit [31:0] SRC1  = 32'h0000_0980;
        localparam bit [31:0] DST   = 32'h0000_09c0;
        super.pre_body();
        mem_clear();
        mem_write_word(DESCR + 0, (VU_ADD << 28) | ((2 - 1) << 16) | ((2 - 1) << 8) | (2 - 1));
        mem_write_word(DESCR + 4, SRC0);
        mem_write_word(DESCR + 8, SRC1);
        mem_write_word(DESCR + 12, DST);
        mem_write_word(SRC0 + 0, 32'hffff_ffff);
        mem_write_word(SRC0 + 4, 32'h0000_0000);
        mem_write_word(SRC1 + 0, 32'h0000_0001);
        mem_write_word(SRC1 + 4, 32'h0000_0000);
        write_reg(VU_DESCR, DESCR);
        wait_operation_complete();
        expect_mem_word(DST + 0, 32'h0000_0000, "vu_add");
        expect_mem_word(DST + 4, 32'h0000_0001, "vu_add");
    endtask
endclass

class cryptolite_vu_mul_seq extends cryptolite_base_seq;
    `uvm_object_utils(cryptolite_vu_mul_seq)
    function new(string name = "cryptolite_vu_mul_seq");
        super.new(name);
    endfunction
    virtual task body();
        localparam bit [31:0] DESCR = 32'h0000_0a00;
        localparam bit [31:0] SRC0  = 32'h0000_0a40;
        localparam bit [31:0] SRC1  = 32'h0000_0a80;
        localparam bit [31:0] DST   = 32'h0000_0ac0;
        super.pre_body();
        mem_clear();
        mem_write_word(DESCR + 0, (VU_MUL << 28) | ((2 - 1) << 16) | ((1 - 1) << 8) | (1 - 1));
        mem_write_word(DESCR + 4, SRC0);
        mem_write_word(DESCR + 8, SRC1);
        mem_write_word(DESCR + 12, DST);
        mem_write_word(SRC0 + 0, 32'd3);
        mem_write_word(SRC1 + 0, 32'd5);
        mem_write_word(DST + 0, 32'hfeed_face);
        mem_write_word(DST + 4, 32'hdead_beef);
        write_reg(VU_DESCR, DESCR);
        wait_operation_complete();
        expect_mem_word(DST + 0, 32'd15, "vu_mul");
        expect_mem_word(DST + 4, 32'd0, "vu_mul");
    endtask
endclass

class cryptolite_intr_seq extends cryptolite_base_seq;
    `uvm_object_utils(cryptolite_intr_seq)
    function new(string name = "cryptolite_intr_seq");
        super.new(name);
    endfunction
    virtual task body();
        localparam bit [31:0] DESCR = 32'h0000_0b00;
        localparam bit [31:0] KEY   = 32'h0000_0b40;
        localparam bit [31:0] PT    = 32'h0000_0b80;
        localparam bit [31:0] CT    = 32'h0000_0bc0;
        bit [31:0] intr_word;
        super.pre_body();
        mem_clear();
        mem_write_word(DESCR + 0, KEY);
        mem_write_word(DESCR + 4, PT);
        mem_write_word(DESCR + 8, CT);
        inject_mem_error(KEY, KEY + 16);
        write_reg(AES_DESCR, DESCR);
        wait_operation_complete();
        read_reg(INTR_ERROR, intr_word);
        if (!intr_word[INTR_ERR_BIT_BUS_ERROR])
            `uvm_fatal("INTR", "Bus error bit did not latch")
        write_reg(INTR_ERROR_MASK, 32'h1);
        expect_reg(INTR_ERROR_MASKED, 32'h1, "intr_masked");
        if (!irq_vif.irq)
            `uvm_fatal("INTR", "IRQ did not assert after masked bus error")
        write_reg(INTR_ERROR, 32'h1);
        expect_reg(INTR_ERROR_MASKED, 32'h0, "intr_clear");
        clear_mem_error();
    endtask
endclass

class cryptolite_busy_block_seq extends cryptolite_base_seq;
    `uvm_object_utils(cryptolite_busy_block_seq)
    function new(string name = "cryptolite_busy_block_seq");
        super.new(name);
    endfunction
    virtual task body();
        localparam bit [31:0] AES_DESCR_PTR = 32'h0000_0c00;
        localparam bit [31:0] KEY           = 32'h0000_0c40;
        localparam bit [31:0] PT            = 32'h0000_0c80;
        localparam bit [31:0] CT            = 32'h0000_0cc0;
        localparam bit [31:0] VU_DESCR_PTR  = 32'h0000_0d00;
        localparam bit [31:0] VU_SRC0       = 32'h0000_0d40;
        localparam bit [31:0] VU_DST        = 32'h0000_0d80;
        super.pre_body();
        mem_clear();
        mem_write_word(AES_DESCR_PTR + 0, KEY);
        mem_write_word(AES_DESCR_PTR + 4, PT);
        mem_write_word(AES_DESCR_PTR + 8, CT);
        mem_write_word(KEY +  0, 32'h2b7e1516);
        mem_write_word(KEY +  4, 32'h28aed2a6);
        mem_write_word(KEY +  8, 32'habf71588);
        mem_write_word(KEY + 12, 32'h09cf4f3c);
        mem_write_word(PT  +  0, 32'h6bc1bee2);
        mem_write_word(PT  +  4, 32'h2e409f96);
        mem_write_word(PT  +  8, 32'he93d7e11);
        mem_write_word(PT  + 12, 32'h7393172a);

        mem_write_word(VU_DESCR_PTR + 0, (VU_MOV << 28) | ((1 - 1) << 16) | (1 - 1));
        mem_write_word(VU_DESCR_PTR + 4, VU_SRC0);
        mem_write_word(VU_DESCR_PTR + 8, 32'h0);
        mem_write_word(VU_DESCR_PTR + 12, VU_DST);
        mem_write_word(VU_SRC0 + 0, 32'h1234_5678);

        write_reg(AES_DESCR, AES_DESCR_PTR);
        wait_busy_value(1'b1);
        write_reg(VU_DESCR, VU_DESCR_PTR);
        wait_operation_complete();
        expect_reg(VU_DESCR, 32'h0, "busy_block");
        expect_mem_word(VU_DST, 32'h0, "busy_block");
    endtask
endclass
