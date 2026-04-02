// AES Base Virtual Sequence
// Provides helper tasks for register access, polling, and common operations.

class aes_base_seq extends uvm_sequence;
    `uvm_object_utils(aes_base_seq)

    `uvm_declare_p_sequencer(aes_virtual_sequencer)

    function new(string name = "aes_base_seq");
        super.new(name);
    endfunction

    // Convenience handles (set in body preamble)
    aes_reg_block          reg_model;
    ahb_master_sequencer   ahb_sqr;
    axi_mem_model          mem;

    virtual task pre_body();
        reg_model = p_sequencer.reg_block;
        ahb_sqr   = p_sequencer.ahb_sqr;
        mem       = p_sequencer.mem;
    endtask

    // ---------------------------------------------------------------
    // Helper: Write a 32-bit register via RAL
    // ---------------------------------------------------------------
    virtual task write_reg(uvm_reg r, uvm_reg_data_t value);
        uvm_status_e status;
        r.write(status, value, .parent(this));
        if (status != UVM_IS_OK)
            `uvm_error("REG_WR", $sformatf("Write to %s failed", r.get_name()))
    endtask

    // ---------------------------------------------------------------
    // Helper: Read a 32-bit register via RAL
    // ---------------------------------------------------------------
    virtual task read_reg(uvm_reg r, output uvm_reg_data_t value);
        uvm_status_e status;
        r.read(status, value, .parent(this));
        if (status != UVM_IS_OK)
            `uvm_error("REG_RD", $sformatf("Read from %s failed", r.get_name()))
    endtask

    // ---------------------------------------------------------------
    // Helper: Write 128-bit key (AES-128: upper 128 bits, AES-256: all)
    // ---------------------------------------------------------------
    virtual task write_key(logic [255:0] key_val, bit aes256);
        write_reg(reg_model.key[0], key_val[255:224]);
        write_reg(reg_model.key[1], key_val[223:192]);
        write_reg(reg_model.key[2], key_val[191:160]);
        write_reg(reg_model.key[3], key_val[159:128]);
        if (aes256) begin
            write_reg(reg_model.key[4], key_val[127:96]);
            write_reg(reg_model.key[5], key_val[95:64]);
            write_reg(reg_model.key[6], key_val[63:32]);
            write_reg(reg_model.key[7], key_val[31:0]);
        end
    endtask

    // ---------------------------------------------------------------
    // Helper: Write 128-bit text_in
    // ---------------------------------------------------------------
    virtual task write_text_in(logic [127:0] text);
        write_reg(reg_model.text_in[0], text[127:96]);
        write_reg(reg_model.text_in[1], text[95:64]);
        write_reg(reg_model.text_in[2], text[63:32]);
        write_reg(reg_model.text_in[3], text[31:0]);
    endtask

    // ---------------------------------------------------------------
    // Helper: Read 128-bit text_out
    // ---------------------------------------------------------------
    virtual task read_text_out(output logic [127:0] text);
        uvm_reg_data_t d;
        read_reg(reg_model.text_out[0], d); text[127:96] = d[31:0];
        read_reg(reg_model.text_out[1], d); text[95:64]  = d[31:0];
        read_reg(reg_model.text_out[2], d); text[63:32]  = d[31:0];
        read_reg(reg_model.text_out[3], d); text[31:0]   = d[31:0];
    endtask

    // ---------------------------------------------------------------
    // Helper: Set mode register (MODE[2:0] = {decrypt, aes256, 0})
    // ---------------------------------------------------------------
    virtual task set_mode(bit decrypt, bit aes256);
        uvm_reg_data_t mode_val = {29'b0, decrypt, aes256, 1'b0};
        `uvm_info("SET_MODE", $sformatf("Writing mode=0x%h (decrypt=%0b aes256=%0b)", mode_val, decrypt, aes256), UVM_MEDIUM)
        write_reg(reg_model.mode, mode_val);
    endtask

    // Raw AHB write bypassing RAL (guarantees bus transaction)
    virtual task ahb_raw_write(bit [31:0] addr, bit [31:0] data);
        ahb_seq_item item = ahb_seq_item::type_id::create("raw_wr");
        if (ahb_sqr == null)
            `uvm_fatal("BASE_SEQ", "ahb_sqr handle is null!")
        item.addr  = addr;
        item.wdata = data;
        item.op    = AHB_WRITE;
        item.hsize = 3'b010;
        `uvm_info("RAW_WR", $sformatf("Writing addr=0x%08h data=0x%08h", addr, data), UVM_MEDIUM)
        start_item(item, -1, ahb_sqr);
        finish_item(item);
    endtask

    // ---------------------------------------------------------------
    // Helper: Trigger and poll for completion (typical mode)
    // ---------------------------------------------------------------
    virtual task trigger_and_wait(int timeout_cycles = 1000);
        uvm_reg_data_t state_val;
        int count = 0;

        write_reg(reg_model.trigger, 32'h1);

        do begin
            read_reg(reg_model.state, state_val);
            count++;
            if (count > timeout_cycles) begin
                `uvm_fatal("TIMEOUT", "AES operation did not complete")
            end
        end while (state_val[1:0] != 2'b00); // Wait for IDLE
    endtask

    // ---------------------------------------------------------------
    // Helper: Compare 128-bit values
    // ---------------------------------------------------------------
    function bit compare_128(logic [127:0] actual, logic [127:0] expected, string label);
        if (actual !== expected) begin
            `uvm_error("COMPARE", $sformatf("%s mismatch: got 0x%032h, expected 0x%032h",
                        label, actual, expected))
            return 0;
        end else begin
            `uvm_info("COMPARE", $sformatf("%s matched: 0x%032h", label, actual), UVM_MEDIUM)
            return 1;
        end
    endfunction

    // ---------------------------------------------------------------
    // Helper: Write 128-bit IV registers
    // ---------------------------------------------------------------
    virtual task write_iv(logic [127:0] iv_val);
        write_reg(reg_model.iv[0], iv_val[127:96]);
        write_reg(reg_model.iv[1], iv_val[95:64]);
        write_reg(reg_model.iv[2], iv_val[63:32]);
        write_reg(reg_model.iv[3], iv_val[31:0]);
    endtask

    // ---------------------------------------------------------------
    // Helper: Preload one 128-bit block into AXI memory
    // Stored as 4 x 32-bit words, MSB word first (big-endian word order)
    // ---------------------------------------------------------------
    function void preload_block(bit [31:0] addr, logic [127:0] data);
        mem.write_word(addr,      data[127:96]);
        mem.write_word(addr + 4,  data[95:64]);
        mem.write_word(addr + 8,  data[63:32]);
        mem.write_word(addr + 12, data[31:0]);
    endfunction

    // ---------------------------------------------------------------
    // Helper: Read one 128-bit block from AXI memory
    // ---------------------------------------------------------------
    function logic [127:0] read_block(bit [31:0] addr);
        logic [127:0] result;
        result[127:96] = mem.read_word(addr);
        result[95:64]  = mem.read_word(addr + 4);
        result[63:32]  = mem.read_word(addr + 8);
        result[31:0]   = mem.read_word(addr + 12);
        return result;
    endfunction

    // ---------------------------------------------------------------
    // Helper: Write 128-bit J0 registers (GCM phase-2 input)
    // ---------------------------------------------------------------
    virtual task write_j0(logic [127:0] j0_val);
        write_reg(reg_model.j0[0], j0_val[127:96]);
        write_reg(reg_model.j0[1], j0_val[95:64]);
        write_reg(reg_model.j0[2], j0_val[63:32]);
        write_reg(reg_model.j0[3], j0_val[31:0]);
    endtask

    // ---------------------------------------------------------------
    // Helper: Read 128-bit H_MEM (GCM GHASH subkey)
    // ---------------------------------------------------------------
    virtual task read_h(output logic [127:0] h_val);
        uvm_reg_data_t d;
        read_reg(reg_model.h[0], d); h_val[127:96] = d[31:0];
        read_reg(reg_model.h[1], d); h_val[95:64]  = d[31:0];
        read_reg(reg_model.h[2], d); h_val[63:32]  = d[31:0];
        read_reg(reg_model.h[3], d); h_val[31:0]   = d[31:0];
    endtask

    // ---------------------------------------------------------------
    // Helper: Read 128-bit T0_MEM (GCM authentication tag)
    // ---------------------------------------------------------------
    virtual task read_t0(output logic [127:0] t0_val);
        uvm_reg_data_t d;
        read_reg(reg_model.t0[0], d); t0_val[127:96] = d[31:0];
        read_reg(reg_model.t0[1], d); t0_val[95:64]  = d[31:0];
        read_reg(reg_model.t0[2], d); t0_val[63:32]  = d[31:0];
        read_reg(reg_model.t0[3], d); t0_val[31:0]   = d[31:0];
    endtask

    // ---------------------------------------------------------------
    // Helper: Poll STATE until ST_DONE (2'b10) without writing DMA_EXIT.
    // Used for GCM phase-1 (so software can inspect H before continuing).
    // ---------------------------------------------------------------
    virtual task poll_until_done(int timeout_cycles = 5000);
        uvm_reg_data_t state_val;
        int count = 0;
        do begin
            read_reg(reg_model.state, state_val);
            count++;
            if (count > timeout_cycles)
                `uvm_fatal("POLL_TIMEOUT", "Operation did not reach DONE state")
        end while (state_val[1:0] != 2'b10);
    endtask

    // ---------------------------------------------------------------
    // Helper: Trigger DMA and poll until STATE == DONE (2'b10),
    //         then write DMA_EXIT to return to IDLE
    // ---------------------------------------------------------------
    virtual task trigger_and_wait_dma(int timeout_cycles = 5000);
        uvm_reg_data_t state_val;
        int count = 0;

        write_reg(reg_model.trigger, 32'h1);

        do begin
            read_reg(reg_model.state, state_val);
            count++;
            if (count > timeout_cycles)
                `uvm_fatal("DMA_TIMEOUT", "DMA operation did not reach DONE state")
        end while (state_val[1:0] != 2'b10); // ST_DONE = 2

        // Return DMA FSM to IDLE
        write_reg(reg_model.dma_exit, 32'h1);
    endtask

endclass
