// ---------------------------------------------------------------------------
// AES Scoreboard
// Shadows register writes via AHB, computes expected output with the C DPI
// reference model, and compares against DUT output observed on AXI.
//
// For DMA mode:
//   - AXI READ  transactions  → input blocks fed to ref model → expected_q
//   - AXI WRITE transactions  → compared against expected_q entries
//
// For typical mode:
//   - TRIGGER write → ref model computes expected text_out
//   - TEXT_OUT AHB reads → compared word-by-word against expected
// ---------------------------------------------------------------------------

`uvm_analysis_imp_decl(_axi)
`uvm_analysis_imp_decl(_axi_rd)

class aes_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(aes_scoreboard)

    // Analysis imports
    uvm_analysis_imp       #(ahb_seq_item, aes_scoreboard) ahb_export;
    uvm_analysis_imp_axi   #(axi_seq_item, aes_scoreboard) axi_export;
    uvm_analysis_imp_axi_rd#(axi_seq_item, aes_scoreboard) axi_rd_export;

    // Transaction counters
    int unsigned ahb_txn_count;
    int unsigned axi_txn_count;
    int unsigned check_count;
    int unsigned error_count;

    // ------------------------------------------------------------------
    // Register shadow (updated by AHB writes)
    // ------------------------------------------------------------------
    bit [255:0]  cfg_key;
    bit          cfg_decrypt;      // MODE[2]
    bit          cfg_aes256;       // MODE[1]
    bit [127:0]  cfg_iv;
    bit [2:0]    cfg_block_mode;   // 0=ECB,1=CBC,2=OFB,3=CTR,...
    bit          cfg_dma_enable;
    int          cfg_block_num;
    bit [31:0]   cfg_src_addr;
    bit [31:0]   cfg_dst_addr;
    bit          cfg_inc_sel;

    // ------------------------------------------------------------------
    // Typical-mode tracking
    // ------------------------------------------------------------------
    bit [127:0]  cfg_text_in;      // shadowed TEXT_IN value
    bit [127:0]  typ_expected;     // expected text_out from ref model
    bit          typ_pending;      // true after trigger, before all text_out reads
    bit [31:0]   typ_out_words[4]; // collected rdata words
    int          typ_words_seen;

    // ------------------------------------------------------------------
    // DMA-mode tracking
    // ------------------------------------------------------------------
    bit [127:0]  dma_expected_q[$];  // FIFO of expected output blocks
    bit          dma_active;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ahb_export    = new("ahb_export",    this);
        axi_export    = new("axi_export",    this);
        axi_rd_export = new("axi_rd_export", this);
        reset_shadow();
    endfunction

    function void reset_shadow();
        cfg_key        = '0;
        cfg_decrypt    = 0;
        cfg_aes256     = 0;
        cfg_iv         = '0;
        cfg_block_mode = 0;
        cfg_dma_enable = 0;
        cfg_block_num  = 0;
        cfg_src_addr   = '0;
        cfg_dst_addr   = '0;
        cfg_inc_sel    = 0;
        cfg_text_in    = '0;
        typ_pending    = 0;
        typ_words_seen = 0;
        dma_expected_q.delete();
        dma_active     = 0;
    endfunction

    // ------------------------------------------------------------------
    // AHB monitor callback — track writes, detect TRIGGER
    // ------------------------------------------------------------------
    virtual function void write(ahb_seq_item item);
        bit [11:0] offset;
        ahb_txn_count++;
        offset = item.addr[11:0];

        `uvm_info("SCB/AHB", $sformatf("AHB %s addr=0x%03h data=0x%08h",
                  item.op.name(), offset, item.op==AHB_WRITE ? item.wdata : item.rdata),
                  UVM_HIGH)

        if (item.op == AHB_WRITE) begin

            // TEXT_IN[0..3]: 0x020-0x02C
            if (offset >= 12'h020 && offset <= 12'h02C) begin
                int idx = (offset - 12'h020) / 4;
                case (idx)
                    0: cfg_text_in[127:96] = item.wdata;
                    1: cfg_text_in[95:64]  = item.wdata;
                    2: cfg_text_in[63:32]  = item.wdata;
                    3: cfg_text_in[31:0]   = item.wdata;
                endcase
            end

            // KEY[0..7]: 0x000-0x01C
            else if (offset >= 12'h000 && offset <= 12'h01C) begin
                int idx = (offset - 12'h000) / 4;  // 0..7
                case (idx)
                    0: cfg_key[255:224] = item.wdata;
                    1: cfg_key[223:192] = item.wdata;
                    2: cfg_key[191:160] = item.wdata;
                    3: cfg_key[159:128] = item.wdata;
                    4: cfg_key[127:96]  = item.wdata;
                    5: cfg_key[95:64]   = item.wdata;
                    6: cfg_key[63:32]   = item.wdata;
                    7: cfg_key[31:0]    = item.wdata;
                endcase
            end

            // IV[0..3]: 0x050-0x05C
            else if (offset >= 12'h050 && offset <= 12'h05C) begin
                int idx = (offset - 12'h050) / 4;
                case (idx)
                    0: cfg_iv[127:96] = item.wdata;
                    1: cfg_iv[95:64]  = item.wdata;
                    2: cfg_iv[63:32]  = item.wdata;
                    3: cfg_iv[31:0]   = item.wdata;
                endcase
            end

            // MODE: 0x040 — bits [2:0] = {decrypt, aes256, 0}
            else if (offset == 12'h040) begin
                cfg_decrypt = item.wdata[2];
                cfg_aes256  = item.wdata[1];
            end

            // DMA_ENABLE: 0x090
            else if (offset == 12'h090) cfg_dma_enable = item.wdata[0];

            // BLOCK_MODE: 0x094
            else if (offset == 12'h094) cfg_block_mode = item.wdata[2:0];

            // BLOCK_NUM: 0x098
            else if (offset == 12'h098) cfg_block_num = int'(item.wdata);

            // INC_SEL: 0x09C
            else if (offset == 12'h09C) cfg_inc_sel = item.wdata[0];

            // DMA_SRC_ADDR: 0x0BC
            else if (offset == 12'h0BC) cfg_src_addr = item.wdata;

            // DMA_DST_ADDR: 0x0C0
            else if (offset == 12'h0C0) cfg_dst_addr = item.wdata;

            // TRIGGER: 0x048 — bit[0] starts an operation
            else if (offset == 12'h048 && item.wdata[0]) begin
                if (!cfg_dma_enable)
                    handle_typical_trigger();
                else begin
                    // DMA: init ref model; blocks arrive via AXI rd_ap
                    init_ref_model();
                    dma_expected_q.delete();
                    dma_active = 1;
                    `uvm_info("SCB", $sformatf(
                        "DMA trigger: mode=%s key=%0d blocks=%0d",
                        blk_mode_str(cfg_block_mode),
                        cfg_aes256 ? 256 : 128,
                        cfg_block_num), UVM_MEDIUM)
                end
            end

        end else begin // AHB_READ

            // TEXT_OUT[0..3]: 0x030-0x03C — collect for typical-mode check
            if (typ_pending && offset >= 12'h030 && offset <= 12'h03C) begin
                int idx = (offset - 12'h030) / 4;
                typ_out_words[idx] = item.rdata;
                typ_words_seen++;
                if (typ_words_seen == 4)
                    check_typical_output();
            end

        end
    endfunction

    // ------------------------------------------------------------------
    // AXI READ monitor callback — DMA input block arrives
    // ------------------------------------------------------------------
    virtual function void write_axi_rd(axi_seq_item item);
        bit [127:0] input_block, expected_out;
        if (!dma_active) return;

        // Reconstruct 128-bit block from 4 beats (MSB first)
        input_block = {item.data[0], item.data[1], item.data[2], item.data[3]};

        // Compute expected output for this block using ref model
        case (cfg_block_mode)
            3'd0: aes_ref_ecb_block(int'(cfg_decrypt),  input_block, expected_out);
            3'd1: aes_ref_cbc_block(int'(cfg_decrypt),  input_block, expected_out);
            3'd2: aes_ref_ofb_block(                    input_block, expected_out);
            3'd3: aes_ref_ctr_block(int'(cfg_inc_sel),  input_block, expected_out);
            3'd5: aes_ref_cfb128_block(int'(cfg_decrypt), input_block, expected_out);
            default: begin
                `uvm_warning("SCB", $sformatf("Block mode %0d not yet covered by ref model (e.g. GCM TC1 = expected)",
                             cfg_block_mode))
                return;
            end
        endcase

        dma_expected_q.push_back(expected_out);

        `uvm_info("SCB/DMA_IN", $sformatf("Input block: 0x%032h → expected out: 0x%032h",
                  input_block, expected_out), UVM_HIGH)
    endfunction

    // ------------------------------------------------------------------
    // AXI WRITE monitor callback — DMA output block from DUT
    // ------------------------------------------------------------------
    virtual function void write_axi(axi_seq_item item);
        bit [127:0] actual_block, expected_block;
        axi_txn_count++;
        if (!dma_active) return;

        if (dma_expected_q.size() == 0) begin
            `uvm_error("SCB", "DMA output block received but expected_q is empty")
            return;
        end

        // Reconstruct 128-bit block from 4 beats
        actual_block   = {item.data[0], item.data[1], item.data[2], item.data[3]};
        expected_block = dma_expected_q.pop_front();
        check_count++;

        if (actual_block !== expected_block) begin
            error_count++;
            `uvm_error("SCB/DMA", $sformatf(
                "DMA block MISMATCH — got 0x%032h, expected 0x%032h",
                actual_block, expected_block))
        end else begin
            `uvm_info("SCB/DMA", $sformatf(
                "DMA block OK: 0x%032h", actual_block), UVM_MEDIUM)
        end
    endfunction

    // ------------------------------------------------------------------
    // Internal helpers
    // ------------------------------------------------------------------

    function void init_ref_model();
        int key_bits = cfg_aes256 ? 256 : 128;
        aes_ref_init(cfg_key, key_bits);
        aes_ref_set_iv(cfg_iv);
    endfunction

    function void handle_typical_trigger();
        bit [127:0] expected_out;
        init_ref_model();
        aes_ref_ecb_block(int'(cfg_decrypt), cfg_text_in, expected_out);
        typ_expected   = expected_out;
        typ_pending    = 1;
        typ_words_seen = 0;
        `uvm_info("SCB", $sformatf("Typical trigger: expected 0x%032h", expected_out), UVM_MEDIUM)
    endfunction

    function void check_typical_output();
        bit [127:0] actual;
        actual = {typ_out_words[0], typ_out_words[1], typ_out_words[2], typ_out_words[3]};
        check_count++;
        if (actual !== typ_expected) begin
            error_count++;
            `uvm_error("SCB/TYP", $sformatf(
                "Typical MISMATCH: got 0x%032h, expected 0x%032h", actual, typ_expected))
        end else begin
            `uvm_info("SCB/TYP", $sformatf("Typical OK: 0x%032h", actual), UVM_MEDIUM)
        end
        typ_pending    = 0;
        typ_words_seen = 0;
    endfunction

    function string blk_mode_str(bit [2:0] m);
        case (m)
            3'd0: return "ECB";
            3'd1: return "CBC";
            3'd2: return "OFB";
            3'd3: return "CTR";
            3'd4: return "CFB8";
            3'd5: return "CFB128";
            3'd6: return "GCM";
            default: return "?";
        endcase
    endfunction

    // ------------------------------------------------------------------
    // Report phase
    // ------------------------------------------------------------------
    virtual function void report_phase(uvm_phase phase);
        `uvm_info("SCB/REPORT", $sformatf(
            "Scoreboard: AHB=%0d AXI=%0d checks=%0d errors=%0d",
            ahb_txn_count, axi_txn_count, check_count, error_count), UVM_LOW)
        if (error_count > 0)
            `uvm_error("SCB/REPORT", $sformatf("%0d scoreboard error(s) detected", error_count))
    endfunction

endclass
