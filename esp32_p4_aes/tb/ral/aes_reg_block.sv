// ---------------------------------------------------------------------------
// AES Accelerator UVM RAL Register Block
// Auto-generated register model matching aes_accel_pkg register map.
// UVM 1.2 methodology.
// ---------------------------------------------------------------------------

// ===== KEY_n registers (n=0..7) at 0x000-0x01C, 32-bit R/W =====
class aes_reg_key extends uvm_reg;
    `uvm_object_utils(aes_reg_key)

    rand uvm_reg_field data;

    function new(string name = "aes_reg_key");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        data = uvm_reg_field::type_id::create("data");
        data.configure(this, 32, 0, "RW", 0, 32'h0, 1, 1, 1);
    endfunction
endclass

// ===== TEXT_IN_m registers (m=0..3) at 0x020-0x02C, 32-bit R/W =====
class aes_reg_text_in extends uvm_reg;
    `uvm_object_utils(aes_reg_text_in)

    rand uvm_reg_field data;

    function new(string name = "aes_reg_text_in");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        data = uvm_reg_field::type_id::create("data");
        data.configure(this, 32, 0, "RW", 0, 32'h0, 1, 1, 1);
    endfunction
endclass

// ===== TEXT_OUT_m registers (m=0..3) at 0x030-0x03C, 32-bit RO =====
class aes_reg_text_out extends uvm_reg;
    `uvm_object_utils(aes_reg_text_out)

    uvm_reg_field data;

    function new(string name = "aes_reg_text_out");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        data = uvm_reg_field::type_id::create("data");
        data.configure(this, 32, 0, "RO", 0, 32'h0, 1, 0, 1);
    endfunction
endclass

// ===== MODE register at 0x040, bits[2:0] R/W =====
class aes_reg_mode extends uvm_reg;
    `uvm_object_utils(aes_reg_mode)

    rand uvm_reg_field mode;
    uvm_reg_field      rsvd;

    function new(string name = "aes_reg_mode");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        mode = uvm_reg_field::type_id::create("mode");
        mode.configure(this, 3, 0, "RW", 0, 3'h0, 1, 1, 1);
        rsvd = uvm_reg_field::type_id::create("rsvd");
        rsvd.configure(this, 29, 3, "RO", 0, 29'h0, 0, 0, 1);
    endfunction
endclass

// ===== TRIGGER register at 0x048, bit[0] W1C (write-trigger) =====
class aes_reg_trigger extends uvm_reg;
    `uvm_object_utils(aes_reg_trigger)

    rand uvm_reg_field trigger;
    uvm_reg_field      rsvd;

    function new(string name = "aes_reg_trigger");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        trigger = uvm_reg_field::type_id::create("trigger");
        trigger.configure(this, 1, 0, "W1C", 0, 1'b0, 1, 1, 1);
        rsvd = uvm_reg_field::type_id::create("rsvd");
        rsvd.configure(this, 31, 1, "RO", 0, 31'h0, 0, 0, 1);
    endfunction
endclass

// ===== STATE register at 0x04C, bits[1:0] RO =====
class aes_reg_state extends uvm_reg;
    `uvm_object_utils(aes_reg_state)

    uvm_reg_field state;
    uvm_reg_field rsvd;

    function new(string name = "aes_reg_state");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        state = uvm_reg_field::type_id::create("state");
        state.configure(this, 2, 0, "RO", 1, 2'h0, 1, 0, 1);
        rsvd = uvm_reg_field::type_id::create("rsvd");
        rsvd.configure(this, 30, 2, "RO", 0, 30'h0, 0, 0, 1);
    endfunction
endclass

// ===== IV_n registers (n=0..3) at 0x050-0x05C, 32-bit R/W =====
class aes_reg_iv extends uvm_reg;
    `uvm_object_utils(aes_reg_iv)

    rand uvm_reg_field data;

    function new(string name = "aes_reg_iv");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        data = uvm_reg_field::type_id::create("data");
        data.configure(this, 32, 0, "RW", 0, 32'h0, 1, 1, 1);
    endfunction
endclass

// ===== H_n registers (n=0..3) at 0x060-0x06C, 32-bit RO =====
class aes_reg_h extends uvm_reg;
    `uvm_object_utils(aes_reg_h)

    uvm_reg_field data;

    function new(string name = "aes_reg_h");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        data = uvm_reg_field::type_id::create("data");
        data.configure(this, 32, 0, "RO", 0, 32'h0, 1, 0, 1);
    endfunction
endclass

// ===== J0_n registers (n=0..3) at 0x070-0x07C, 32-bit R/W =====
class aes_reg_j0 extends uvm_reg;
    `uvm_object_utils(aes_reg_j0)

    rand uvm_reg_field data;

    function new(string name = "aes_reg_j0");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        data = uvm_reg_field::type_id::create("data");
        data.configure(this, 32, 0, "RW", 0, 32'h0, 1, 1, 1);
    endfunction
endclass

// ===== T0_n registers (n=0..3) at 0x080-0x08C, 32-bit RO =====
class aes_reg_t0 extends uvm_reg;
    `uvm_object_utils(aes_reg_t0)

    uvm_reg_field data;

    function new(string name = "aes_reg_t0");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        data = uvm_reg_field::type_id::create("data");
        data.configure(this, 32, 0, "RO", 0, 32'h0, 1, 0, 1);
    endfunction
endclass

// ===== DMA_ENABLE register at 0x090, bit[0] R/W =====
class aes_reg_dma_enable extends uvm_reg;
    `uvm_object_utils(aes_reg_dma_enable)

    rand uvm_reg_field enable;
    uvm_reg_field      rsvd;

    function new(string name = "aes_reg_dma_enable");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        enable = uvm_reg_field::type_id::create("enable");
        enable.configure(this, 1, 0, "RW", 0, 1'b0, 1, 1, 1);
        rsvd = uvm_reg_field::type_id::create("rsvd");
        rsvd.configure(this, 31, 1, "RO", 0, 31'h0, 0, 0, 1);
    endfunction
endclass

// ===== BLOCK_MODE register at 0x094, bits[2:0] R/W =====
class aes_reg_block_mode extends uvm_reg;
    `uvm_object_utils(aes_reg_block_mode)

    rand uvm_reg_field block_mode;
    uvm_reg_field      rsvd;

    function new(string name = "aes_reg_block_mode");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        block_mode = uvm_reg_field::type_id::create("block_mode");
        block_mode.configure(this, 3, 0, "RW", 0, 3'h0, 1, 1, 1);
        rsvd = uvm_reg_field::type_id::create("rsvd");
        rsvd.configure(this, 29, 3, "RO", 0, 29'h0, 0, 0, 1);
    endfunction
endclass

// ===== BLOCK_NUM register at 0x098, 32-bit R/W =====
class aes_reg_block_num extends uvm_reg;
    `uvm_object_utils(aes_reg_block_num)

    rand uvm_reg_field block_num;

    function new(string name = "aes_reg_block_num");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        block_num = uvm_reg_field::type_id::create("block_num");
        block_num.configure(this, 32, 0, "RW", 0, 32'h0, 1, 1, 1);
    endfunction
endclass

// ===== INC_SEL register at 0x09C, bit[0] R/W =====
class aes_reg_inc_sel extends uvm_reg;
    `uvm_object_utils(aes_reg_inc_sel)

    rand uvm_reg_field inc_sel;
    uvm_reg_field      rsvd;

    function new(string name = "aes_reg_inc_sel");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        inc_sel = uvm_reg_field::type_id::create("inc_sel");
        inc_sel.configure(this, 1, 0, "RW", 0, 1'b0, 1, 1, 1);
        rsvd = uvm_reg_field::type_id::create("rsvd");
        rsvd.configure(this, 31, 1, "RO", 0, 31'h0, 0, 0, 1);
    endfunction
endclass

// ===== AAD_BLOCK_NUM register at 0x0A0, 32-bit R/W =====
class aes_reg_aad_block_num extends uvm_reg;
    `uvm_object_utils(aes_reg_aad_block_num)

    rand uvm_reg_field aad_block_num;

    function new(string name = "aes_reg_aad_block_num");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        aad_block_num = uvm_reg_field::type_id::create("aad_block_num");
        aad_block_num.configure(this, 32, 0, "RW", 0, 32'h0, 1, 1, 1);
    endfunction
endclass

// ===== REMAINDER_BIT_NUM register at 0x0A4, bits[6:0] R/W =====
class aes_reg_remainder_bit_num extends uvm_reg;
    `uvm_object_utils(aes_reg_remainder_bit_num)

    rand uvm_reg_field remainder_bit_num;
    uvm_reg_field      rsvd;

    function new(string name = "aes_reg_remainder_bit_num");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        remainder_bit_num = uvm_reg_field::type_id::create("remainder_bit_num");
        remainder_bit_num.configure(this, 7, 0, "RW", 0, 7'h0, 1, 1, 1);
        rsvd = uvm_reg_field::type_id::create("rsvd");
        rsvd.configure(this, 25, 7, "RO", 0, 25'h0, 0, 0, 1);
    endfunction
endclass

// ===== CONTINUE_OP register at 0x0A8, bit[0] WO =====
class aes_reg_continue_op extends uvm_reg;
    `uvm_object_utils(aes_reg_continue_op)

    rand uvm_reg_field continue_op;
    uvm_reg_field      rsvd;

    function new(string name = "aes_reg_continue_op");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        continue_op = uvm_reg_field::type_id::create("continue_op");
        continue_op.configure(this, 1, 0, "WO", 0, 1'b0, 1, 1, 0);
        rsvd = uvm_reg_field::type_id::create("rsvd");
        rsvd.configure(this, 31, 1, "RO", 0, 31'h0, 0, 0, 0);
    endfunction
endclass

// ===== INT_CLR register at 0x0AC, bit[0] W1C =====
class aes_reg_int_clr extends uvm_reg;
    `uvm_object_utils(aes_reg_int_clr)

    rand uvm_reg_field int_clr;
    uvm_reg_field      rsvd;

    function new(string name = "aes_reg_int_clr");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        int_clr = uvm_reg_field::type_id::create("int_clr");
        int_clr.configure(this, 1, 0, "W1C", 0, 1'b0, 1, 1, 1);
        rsvd = uvm_reg_field::type_id::create("rsvd");
        rsvd.configure(this, 31, 1, "RO", 0, 31'h0, 0, 0, 1);
    endfunction
endclass

// ===== INT_ENA register at 0x0B0, bit[0] R/W =====
class aes_reg_int_ena extends uvm_reg;
    `uvm_object_utils(aes_reg_int_ena)

    rand uvm_reg_field int_ena;
    uvm_reg_field      rsvd;

    function new(string name = "aes_reg_int_ena");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        int_ena = uvm_reg_field::type_id::create("int_ena");
        int_ena.configure(this, 1, 0, "RW", 0, 1'b0, 1, 1, 1);
        rsvd = uvm_reg_field::type_id::create("rsvd");
        rsvd.configure(this, 31, 1, "RO", 0, 31'h0, 0, 0, 1);
    endfunction
endclass

// ===== DMA_EXIT register at 0x0B8, bit[0] WO =====
class aes_reg_dma_exit extends uvm_reg;
    `uvm_object_utils(aes_reg_dma_exit)

    rand uvm_reg_field dma_exit;
    uvm_reg_field      rsvd;

    function new(string name = "aes_reg_dma_exit");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        dma_exit = uvm_reg_field::type_id::create("dma_exit");
        dma_exit.configure(this, 1, 0, "WO", 0, 1'b0, 1, 1, 0);
        rsvd = uvm_reg_field::type_id::create("rsvd");
        rsvd.configure(this, 31, 1, "RO", 0, 31'h0, 0, 0, 0);
    endfunction
endclass

// ===== DMA_SRC_ADDR register at 0x0BC, 32-bit R/W =====
class aes_reg_dma_src_addr extends uvm_reg;
    `uvm_object_utils(aes_reg_dma_src_addr)

    rand uvm_reg_field addr;

    function new(string name = "aes_reg_dma_src_addr");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        addr = uvm_reg_field::type_id::create("addr");
        addr.configure(this, 32, 0, "RW", 0, 32'h0, 1, 1, 1);
    endfunction
endclass

// ===== DMA_DST_ADDR register at 0x0C0, 32-bit R/W =====
class aes_reg_dma_dst_addr extends uvm_reg;
    `uvm_object_utils(aes_reg_dma_dst_addr)

    rand uvm_reg_field addr;

    function new(string name = "aes_reg_dma_dst_addr");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        addr = uvm_reg_field::type_id::create("addr");
        addr.configure(this, 32, 0, "RW", 0, 32'h0, 1, 1, 1);
    endfunction
endclass


// ===========================================================================
// AES Register Block
// ===========================================================================
class aes_reg_block extends uvm_reg_block;
    `uvm_object_utils(aes_reg_block)

    // KEY_n (n=0..7)
    rand aes_reg_key          key[8];

    // TEXT_IN_m (m=0..3)
    rand aes_reg_text_in      text_in[4];

    // TEXT_OUT_m (m=0..3)
    aes_reg_text_out           text_out[4];

    // MODE
    rand aes_reg_mode          mode;

    // TRIGGER
    rand aes_reg_trigger       trigger;

    // STATE
    aes_reg_state              state;

    // IV_n (n=0..3)
    rand aes_reg_iv            iv[4];

    // H_n (n=0..3)
    aes_reg_h                  h[4];

    // J0_n (n=0..3)
    rand aes_reg_j0            j0[4];

    // T0_n (n=0..3)
    aes_reg_t0                 t0[4];

    // DMA_ENABLE
    rand aes_reg_dma_enable    dma_enable;

    // BLOCK_MODE
    rand aes_reg_block_mode    block_mode;

    // BLOCK_NUM
    rand aes_reg_block_num     block_num;

    // INC_SEL
    rand aes_reg_inc_sel       inc_sel;

    // AAD_BLOCK_NUM
    rand aes_reg_aad_block_num aad_block_num;

    // REMAINDER_BIT_NUM
    rand aes_reg_remainder_bit_num remainder_bit_num;

    // CONTINUE_OP
    rand aes_reg_continue_op   continue_op;

    // INT_CLR
    rand aes_reg_int_clr       int_clr;

    // INT_ENA
    rand aes_reg_int_ena       int_ena;

    // DMA_EXIT
    rand aes_reg_dma_exit      dma_exit;

    // DMA_SRC_ADDR
    rand aes_reg_dma_src_addr  dma_src_addr;

    // DMA_DST_ADDR
    rand aes_reg_dma_dst_addr  dma_dst_addr;

    // Address map
    uvm_reg_map default_map;

    function new(string name = "aes_reg_block");
        super.new(name, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();

        // ---- KEY_n registers ----
        foreach (key[i]) begin
            key[i] = aes_reg_key::type_id::create($sformatf("key_%0d", i));
            key[i].configure(this, null, "");
            key[i].build();
        end

        // ---- TEXT_IN_m registers ----
        foreach (text_in[i]) begin
            text_in[i] = aes_reg_text_in::type_id::create($sformatf("text_in_%0d", i));
            text_in[i].configure(this, null, "");
            text_in[i].build();
        end

        // ---- TEXT_OUT_m registers ----
        foreach (text_out[i]) begin
            text_out[i] = aes_reg_text_out::type_id::create($sformatf("text_out_%0d", i));
            text_out[i].configure(this, null, "");
            text_out[i].build();
        end

        // ---- MODE ----
        mode = aes_reg_mode::type_id::create("mode");
        mode.configure(this, null, "");
        mode.build();

        // ---- TRIGGER ----
        trigger = aes_reg_trigger::type_id::create("trigger");
        trigger.configure(this, null, "");
        trigger.build();

        // ---- STATE ----
        state = aes_reg_state::type_id::create("state");
        state.configure(this, null, "");
        state.build();

        // ---- IV_n registers ----
        foreach (iv[i]) begin
            iv[i] = aes_reg_iv::type_id::create($sformatf("iv_%0d", i));
            iv[i].configure(this, null, "");
            iv[i].build();
        end

        // ---- H_n registers ----
        foreach (h[i]) begin
            h[i] = aes_reg_h::type_id::create($sformatf("h_%0d", i));
            h[i].configure(this, null, "");
            h[i].build();
        end

        // ---- J0_n registers ----
        foreach (j0[i]) begin
            j0[i] = aes_reg_j0::type_id::create($sformatf("j0_%0d", i));
            j0[i].configure(this, null, "");
            j0[i].build();
        end

        // ---- T0_n registers ----
        foreach (t0[i]) begin
            t0[i] = aes_reg_t0::type_id::create($sformatf("t0_%0d", i));
            t0[i].configure(this, null, "");
            t0[i].build();
        end

        // ---- DMA_ENABLE ----
        dma_enable = aes_reg_dma_enable::type_id::create("dma_enable");
        dma_enable.configure(this, null, "");
        dma_enable.build();

        // ---- BLOCK_MODE ----
        block_mode = aes_reg_block_mode::type_id::create("block_mode");
        block_mode.configure(this, null, "");
        block_mode.build();

        // ---- BLOCK_NUM ----
        block_num = aes_reg_block_num::type_id::create("block_num");
        block_num.configure(this, null, "");
        block_num.build();

        // ---- INC_SEL ----
        inc_sel = aes_reg_inc_sel::type_id::create("inc_sel");
        inc_sel.configure(this, null, "");
        inc_sel.build();

        // ---- AAD_BLOCK_NUM ----
        aad_block_num = aes_reg_aad_block_num::type_id::create("aad_block_num");
        aad_block_num.configure(this, null, "");
        aad_block_num.build();

        // ---- REMAINDER_BIT_NUM ----
        remainder_bit_num = aes_reg_remainder_bit_num::type_id::create("remainder_bit_num");
        remainder_bit_num.configure(this, null, "");
        remainder_bit_num.build();

        // ---- CONTINUE_OP ----
        continue_op = aes_reg_continue_op::type_id::create("continue_op");
        continue_op.configure(this, null, "");
        continue_op.build();

        // ---- INT_CLR ----
        int_clr = aes_reg_int_clr::type_id::create("int_clr");
        int_clr.configure(this, null, "");
        int_clr.build();

        // ---- INT_ENA ----
        int_ena = aes_reg_int_ena::type_id::create("int_ena");
        int_ena.configure(this, null, "");
        int_ena.build();

        // ---- DMA_EXIT ----
        dma_exit = aes_reg_dma_exit::type_id::create("dma_exit");
        dma_exit.configure(this, null, "");
        dma_exit.build();

        // ---- DMA_SRC_ADDR ----
        dma_src_addr = aes_reg_dma_src_addr::type_id::create("dma_src_addr");
        dma_src_addr.configure(this, null, "");
        dma_src_addr.build();

        // ---- DMA_DST_ADDR ----
        dma_dst_addr = aes_reg_dma_dst_addr::type_id::create("dma_dst_addr");
        dma_dst_addr.configure(this, null, "");
        dma_dst_addr.build();

        // ----------------------------------------------------------------
        // Create default address map
        // Byte-addressable, 32-bit bus width, little-endian
        // ----------------------------------------------------------------
        default_map = create_map("default_map", 'h0, 4, UVM_LITTLE_ENDIAN);

        // KEY_n at 0x000-0x01C (stride 4)
        foreach (key[i])
            default_map.add_reg(key[i],       'h000 + i * 4, "RW");

        // TEXT_IN_m at 0x020-0x02C
        foreach (text_in[i])
            default_map.add_reg(text_in[i],   'h020 + i * 4, "RW");

        // TEXT_OUT_m at 0x030-0x03C
        foreach (text_out[i])
            default_map.add_reg(text_out[i],  'h030 + i * 4, "RO");

        // MODE at 0x040
        default_map.add_reg(mode,             'h040, "RW");

        // TRIGGER at 0x048
        default_map.add_reg(trigger,          'h048, "RW");

        // STATE at 0x04C
        default_map.add_reg(state,            'h04C, "RO");

        // IV_n at 0x050-0x05C
        foreach (iv[i])
            default_map.add_reg(iv[i],        'h050 + i * 4, "RW");

        // H_n at 0x060-0x06C
        foreach (h[i])
            default_map.add_reg(h[i],         'h060 + i * 4, "RO");

        // J0_n at 0x070-0x07C
        foreach (j0[i])
            default_map.add_reg(j0[i],        'h070 + i * 4, "RW");

        // T0_n at 0x080-0x08C
        foreach (t0[i])
            default_map.add_reg(t0[i],        'h080 + i * 4, "RO");

        // DMA_ENABLE at 0x090
        default_map.add_reg(dma_enable,       'h090, "RW");

        // BLOCK_MODE at 0x094
        default_map.add_reg(block_mode,       'h094, "RW");

        // BLOCK_NUM at 0x098
        default_map.add_reg(block_num,        'h098, "RW");

        // INC_SEL at 0x09C
        default_map.add_reg(inc_sel,          'h09C, "RW");

        // AAD_BLOCK_NUM at 0x0A0
        default_map.add_reg(aad_block_num,    'h0A0, "RW");

        // REMAINDER_BIT_NUM at 0x0A4
        default_map.add_reg(remainder_bit_num,'h0A4, "RW");

        // CONTINUE_OP at 0x0A8
        default_map.add_reg(continue_op,      'h0A8, "WO");

        // INT_CLR at 0x0AC
        default_map.add_reg(int_clr,          'h0AC, "RW");

        // INT_ENA at 0x0B0
        default_map.add_reg(int_ena,          'h0B0, "RW");

        // DMA_EXIT at 0x0B8
        default_map.add_reg(dma_exit,         'h0B8, "WO");

        // DMA_SRC_ADDR at 0x0BC
        default_map.add_reg(dma_src_addr,     'h0BC, "RW");

        // DMA_DST_ADDR at 0x0C0
        default_map.add_reg(dma_dst_addr,     'h0C0, "RW");

        lock_model();
    endfunction

endclass
