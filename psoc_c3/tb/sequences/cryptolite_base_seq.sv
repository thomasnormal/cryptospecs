class cryptolite_base_seq extends uvm_sequence;
    `uvm_object_utils(cryptolite_base_seq)
    `uvm_declare_p_sequencer(cryptolite_virtual_sequencer)

    ahb_master_sequencer      ahb_sqr;
    virtual cryptolite_mem_if mem_vif;
    virtual irq_if            irq_vif;

    localparam bit [31:0] BASE = CRYPTOLITE_BASE;
    localparam bit [31:0] SHA256_H0 = 32'h6a09e667;
    localparam bit [31:0] SHA256_H1 = 32'hbb67ae85;
    localparam bit [31:0] SHA256_H2 = 32'h3c6ef372;
    localparam bit [31:0] SHA256_H3 = 32'ha54ff53a;
    localparam bit [31:0] SHA256_H4 = 32'h510e527f;
    localparam bit [31:0] SHA256_H5 = 32'h9b05688c;
    localparam bit [31:0] SHA256_H6 = 32'h1f83d9ab;
    localparam bit [31:0] SHA256_H7 = 32'h5be0cd19;

    function new(string name = "cryptolite_base_seq");
        super.new(name);
    endfunction

    virtual task pre_body();
        ahb_sqr = p_sequencer.ahb_sqr;
        mem_vif = p_sequencer.mem_vif;
        irq_vif = p_sequencer.irq_vif;

        if (ahb_sqr == null)
            `uvm_fatal("NOAHB", "AHB sequencer handle is null")
        if (mem_vif == null)
            `uvm_fatal("NOMEM", "Memory interface handle is null")
        if (irq_vif == null)
            `uvm_fatal("NOIRQ", "IRQ interface handle is null")
    endtask

    virtual task ahb_write(bit [31:0] addr, bit [31:0] data);
        ahb_seq_item item;
        item = ahb_seq_item::type_id::create("ahb_wr");
        item.addr  = addr;
        item.wdata = data;
        item.op    = AHB_WRITE;
        item.hsize = HSIZE_WORD;
        start_item(item, -1, ahb_sqr);
        finish_item(item);
    endtask

    virtual task ahb_read(bit [31:0] addr, output bit [31:0] data);
        ahb_seq_item item;
        item = ahb_seq_item::type_id::create("ahb_rd");
        item.addr  = addr;
        item.op    = AHB_READ;
        item.hsize = HSIZE_WORD;
        start_item(item, -1, ahb_sqr);
        finish_item(item);
        data = item.rdata;
    endtask

    virtual task write_reg(bit [11:0] reg_ofs, bit [31:0] data);
        ahb_write(BASE + reg_ofs, data);
    endtask

    virtual task read_reg(bit [11:0] reg_ofs, output bit [31:0] data);
        ahb_read(BASE + reg_ofs, data);
    endtask

    virtual task wait_busy_value(bit expected, int max_polls = 2000);
        bit [31:0] status_word;
        int polls;
        for (polls = 0; polls < max_polls; polls++) begin
            read_reg(STATUS, status_word);
            if (status_word[STATUS_BIT_BUSY] == expected)
                return;
        end
        `uvm_fatal("TIMEOUT", $sformatf("STATUS.BUSY did not reach %0d", expected))
    endtask

    virtual task wait_operation_complete(int max_polls = 2000);
        bit [31:0] status_word;
        bit saw_busy;
        int polls;
        saw_busy = 0;
        for (polls = 0; polls < max_polls; polls++) begin
            read_reg(STATUS, status_word);
            if (status_word[STATUS_BIT_BUSY])
                saw_busy = 1;
            else if (saw_busy)
                return;
        end
        `uvm_fatal("TIMEOUT", "Operation did not complete")
    endtask

    virtual task expect_reg(bit [11:0] reg_ofs, bit [31:0] expected, string label);
        bit [31:0] actual;
        read_reg(reg_ofs, actual);
        if (actual !== expected)
            `uvm_fatal("EXPECT_REG",
                $sformatf("%s reg 0x%03h mismatch: got 0x%08h expected 0x%08h",
                          label, reg_ofs, actual, expected))
    endtask

    virtual task mem_clear();
        mem_vif.clear();
    endtask

    virtual task mem_write_word(bit [31:0] addr, bit [31:0] data);
        mem_vif.write_word(addr, data);
    endtask

    virtual task mem_read_word(bit [31:0] addr, output bit [31:0] data);
        data = mem_vif.read_word(addr);
    endtask

    virtual task expect_mem_word(bit [31:0] addr, bit [31:0] expected, string label);
        bit [31:0] actual;
        actual = mem_vif.read_word(addr);
        if (actual !== expected)
            `uvm_fatal("EXPECT_MEM",
                $sformatf("%s mem 0x%08h mismatch: got 0x%08h expected 0x%08h",
                          label, addr, actual, expected))
    endtask

    virtual task inject_mem_error(bit [31:0] base_addr, bit [31:0] limit_addr);
        mem_vif.set_error_range(base_addr, limit_addr);
    endtask

    virtual task clear_mem_error();
        mem_vif.clear_error_range();
    endtask

    virtual task wait_irq_high(int max_cycles = 1000);
        int cycles;
        for (cycles = 0; cycles < max_cycles; cycles++) begin
            @(posedge irq_vif.clk);
            if (irq_vif.irq)
                return;
        end
        `uvm_fatal("TIMEOUT", "IRQ did not assert")
    endtask

    function automatic bit [31:0] rotr32(bit [31:0] x, int n);
        return (x >> n) | (x << (32 - n));
    endfunction

    function automatic bit [31:0] sigma0_fn(bit [31:0] x);
        return rotr32(x, 7) ^ rotr32(x, 18) ^ (x >> 3);
    endfunction

    function automatic bit [31:0] sigma1_fn(bit [31:0] x);
        return rotr32(x, 17) ^ rotr32(x, 19) ^ (x >> 10);
    endfunction

    function automatic bit [31:0] Sigma0_fn(bit [31:0] x);
        return rotr32(x, 2) ^ rotr32(x, 13) ^ rotr32(x, 22);
    endfunction

    function automatic bit [31:0] Sigma1_fn(bit [31:0] x);
        return rotr32(x, 6) ^ rotr32(x, 11) ^ rotr32(x, 25);
    endfunction

    function automatic bit [31:0] Ch_fn(bit [31:0] e, bit [31:0] f, bit [31:0] g);
        return (e & f) ^ (~e & g);
    endfunction

    function automatic bit [31:0] Maj_fn(bit [31:0] a, bit [31:0] b, bit [31:0] c);
        return (a & b) ^ (a & c) ^ (b & c);
    endfunction

    function automatic bit [31:0] sha_k(int idx);
        case (idx)
            0: sha_k = 32'h428a2f98;   1: sha_k = 32'h71374491;
            2: sha_k = 32'hb5c0fbcf;   3: sha_k = 32'he9b5dba5;
            4: sha_k = 32'h3956c25b;   5: sha_k = 32'h59f111f1;
            6: sha_k = 32'h923f82a4;   7: sha_k = 32'hab1c5ed5;
            8: sha_k = 32'hd807aa98;   9: sha_k = 32'h12835b01;
            10: sha_k = 32'h243185be; 11: sha_k = 32'h550c7dc3;
            12: sha_k = 32'h72be5d74; 13: sha_k = 32'h80deb1fe;
            14: sha_k = 32'h9bdc06a7; 15: sha_k = 32'hc19bf174;
            16: sha_k = 32'he49b69c1; 17: sha_k = 32'hefbe4786;
            18: sha_k = 32'h0fc19dc6; 19: sha_k = 32'h240ca1cc;
            20: sha_k = 32'h2de92c6f; 21: sha_k = 32'h4a7484aa;
            22: sha_k = 32'h5cb0a9dc; 23: sha_k = 32'h76f988da;
            24: sha_k = 32'h983e5152; 25: sha_k = 32'ha831c66d;
            26: sha_k = 32'hb00327c8; 27: sha_k = 32'hbf597fc7;
            28: sha_k = 32'hc6e00bf3; 29: sha_k = 32'hd5a79147;
            30: sha_k = 32'h06ca6351; 31: sha_k = 32'h14292967;
            32: sha_k = 32'h27b70a85; 33: sha_k = 32'h2e1b2138;
            34: sha_k = 32'h4d2c6dfc; 35: sha_k = 32'h53380d13;
            36: sha_k = 32'h650a7354; 37: sha_k = 32'h766a0abb;
            38: sha_k = 32'h81c2c92e; 39: sha_k = 32'h92722c85;
            40: sha_k = 32'ha2bfe8a1; 41: sha_k = 32'ha81a664b;
            42: sha_k = 32'hc24b8b70; 43: sha_k = 32'hc76c51a3;
            44: sha_k = 32'hd192e819; 45: sha_k = 32'hd6990624;
            46: sha_k = 32'hf40e3585; 47: sha_k = 32'h106aa070;
            48: sha_k = 32'h19a4c116; 49: sha_k = 32'h1e376c08;
            50: sha_k = 32'h2748774c; 51: sha_k = 32'h34b0bcb5;
            52: sha_k = 32'h391c0cb3; 53: sha_k = 32'h4ed8aa4a;
            54: sha_k = 32'h5b9cca4f; 55: sha_k = 32'h682e6ff3;
            56: sha_k = 32'h748f82ee; 57: sha_k = 32'h78a5636f;
            58: sha_k = 32'h84c87814; 59: sha_k = 32'h8cc70208;
            60: sha_k = 32'h90befffa; 61: sha_k = 32'ha4506ceb;
            62: sha_k = 32'hbef9a3f7; 63: sha_k = 32'hc67178f2;
            default: sha_k = 32'h0;
        endcase
    endfunction

    virtual task prepare_sha_abc(
        output bit [31:0] block[0:15],
        output bit [31:0] sched[0:63],
        output bit [31:0] hash_init[0:7],
        output bit [31:0] hash_exp[0:7]
    );
        int i;
        bit [31:0] a, b, c, d, e, f, g, h;
        bit [31:0] t1, t2;

        block[0] = 32'h61626380;
        for (i = 1; i < 15; i++) block[i] = 32'h0000_0000;
        block[15] = 32'h0000_0018;

        for (i = 0; i < 16; i++) sched[i] = block[i];
        for (i = 16; i < 64; i++) begin
            sched[i] = sigma1_fn(sched[i - 2]) +
                       sched[i - 7] +
                       sigma0_fn(sched[i - 15]) +
                       sched[i - 16];
        end

        hash_init[0] = SHA256_H0;
        hash_init[1] = SHA256_H1;
        hash_init[2] = SHA256_H2;
        hash_init[3] = SHA256_H3;
        hash_init[4] = SHA256_H4;
        hash_init[5] = SHA256_H5;
        hash_init[6] = SHA256_H6;
        hash_init[7] = SHA256_H7;

        a = hash_init[0];
        b = hash_init[1];
        c = hash_init[2];
        d = hash_init[3];
        e = hash_init[4];
        f = hash_init[5];
        g = hash_init[6];
        h = hash_init[7];
        for (i = 0; i < 64; i++) begin
            t1 = h + Sigma1_fn(e) + Ch_fn(e, f, g) + sha_k(i) + sched[i];
            t2 = Sigma0_fn(a) + Maj_fn(a, b, c);
            h = g;
            g = f;
            f = e;
            e = d + t1;
            d = c;
            c = b;
            b = a;
            a = t1 + t2;
        end

        hash_exp[0] = hash_init[0] + a;
        hash_exp[1] = hash_init[1] + b;
        hash_exp[2] = hash_init[2] + c;
        hash_exp[3] = hash_init[3] + d;
        hash_exp[4] = hash_init[4] + e;
        hash_exp[5] = hash_init[5] + f;
        hash_exp[6] = hash_init[6] + g;
        hash_exp[7] = hash_init[7] + h;
    endtask
endclass
