// PSoC 6 Crypto — AHB-Lite Slave
//
// Decodes AHB-Lite transactions and drives the crypto block's internal
// register file.  All register offsets come from crypto_pkg.sv.
//
// Address map:
//   0x0000 – 0x07CC : standard registers (see crypto_pkg.sv)
//   0x0800 – 0x0874 : extension registers
//   0x4000 – 0x4FFC : MEM_BUFF (1024 × 32-bit SRAM, forwarded to mem_buffer)
//
// Pipeline: standard AHB-Lite two-phase (address phase → data phase).
// Zero wait states; hreadyout always 1.

`include "crypto_pkg.sv"

module ahb_slave
    import crypto_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    // AHB-Lite slave port
    input  logic        hsel,
    input  logic [14:0] haddr,
    input  logic [1:0]  htrans,
    input  logic        hwrite,
    input  logic [2:0]  hsize,
    input  logic [31:0] hwdata,
    output logic [31:0] hrdata,
    output logic        hreadyout,
    output logic        hresp,

    // ---- Instruction FIFO push ----
    output logic [31:0] instr_push_data,
    output logic        instr_push_en,
    input  logic [3:0]  instr_used,
    input  logic        instr_full,
    input  logic        instr_empty,
    input  logic        instr_event,

    // ---- Status inputs (RO) ----
    input  logic        aes_busy,
    input  logic        des_busy,
    input  logic        sha_busy,
    input  logic        crc_busy,
    input  logic        prng_busy,
    input  logic        trng_busy,
    input  logic        vu_busy,
    input  logic        decoder_busy,

    // ---- Register outputs to engines ----
    output logic [1:0]  reg_aes_key_size,    // AES_CTL.KEY_SIZE
    output logic [2:0]  reg_sha_mode,        // SHA_CTL.MODE
    output logic        reg_ctl_enabled,     // CTL.ENABLED
    output logic [1:0]  reg_pwr_mode,        // CTL.PWR_MODE

    // CRC registers
    output logic        reg_crc_rem_reverse,
    output logic        reg_crc_data_reverse,
    output logic [7:0]  reg_crc_data_xor,
    output logic [31:0] reg_crc_polynomial,
    output logic [31:0] reg_crc_lfsr,
    output logic [31:0] reg_crc_rem_xor,
    input  logic [31:0] crc_rem_result,

    // PRNG registers
    output logic [31:0] reg_pr_lfsr0,
    output logic [30:0] reg_pr_lfsr1,
    output logic [28:0] reg_pr_lfsr2,
    input  logic [31:0] pr_result,

    // TRNG registers
    output logic [31:0] reg_tr_ctl0,
    output logic [31:0] reg_tr_ctl1,
    output logic [30:0] reg_tr_garo_ctl,
    output logic [30:0] reg_tr_firo_ctl,
    output logic [1:0]  reg_tr_mon_ctl,
    output logic [7:0]  reg_tr_mon_rc_cutoff,
    output logic [31:0] reg_tr_mon_ap_ctl,
    input  logic [31:0] tr_result,

    // VU registers
    output logic        reg_vu_ctl0_always,
    output logic [31:0] reg_vu_ctl1_addr,
    input  logic [3:0]  vu_status,

    // Interrupt quad
    output logic [31:0] reg_intr_mask,
    input  logic [31:0] intr_raw,         // raw interrupt sources
    output logic        intr_clear,       // RW1C write (any bit set → clear pulse)
    output logic        intr_set,         // RW1S write
    output logic [31:0] intr_set_val,

    // VU register file (RF_DATA0-15)
    input  logic [31:0] vu_rf_data [0:RF_NREGS-1],

    // MEM_BUFF port
    output logic [9:0]  mem_addr,
    output logic [31:0] mem_wdata,
    output logic        mem_we,
    input  logic [31:0] mem_rdata,

    // Extension registers
    output logic [31:0] reg_ext_aad_addr,
    output logic [31:0] reg_ext_aad_len,
    output logic [31:0] reg_ext_mac_addr,
    output logic [31:0] reg_ext_key_addr,
    output logic [7:0]  reg_ext_key_id,
    output logic [31:0] reg_ext_ctx_addr,
    output logic        reg_ext_cancel
);
    // ------------------------------------------------------------------
    // AHB pipeline registers
    // ------------------------------------------------------------------
    logic        dph_sel_q;    // data phase: transaction is valid
    logic        dph_write_q;  // data phase: write
    logic [14:0] dph_addr_q;   // data phase: address

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dph_sel_q   <= 1'b0;
            dph_write_q <= 1'b0;
            dph_addr_q  <= '0;
        end else begin
            dph_sel_q   <= hsel && (htrans == HTRANS_NONSEQ || htrans == HTRANS_SEQ);
            dph_write_q <= hwrite;
            dph_addr_q  <= haddr;
        end
    end

    assign hreadyout = 1'b1;
    assign hresp     = HRESP_OKAY;

    // ------------------------------------------------------------------
    // Decode helpers
    // ------------------------------------------------------------------
    wire is_mem_buff = (dph_addr_q >= 15'(MEM_BUFF_OFFSET));
    wire [9:0] mem_word_addr = dph_addr_q[11:2]; // word address within 4KB

    // ------------------------------------------------------------------
    // Register write
    // ------------------------------------------------------------------
    // Write-enable for each register
    wire wr_en = dph_sel_q && dph_write_q && !is_mem_buff;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_ctl_enabled      <= 1'b0;
            reg_pwr_mode         <= 2'd3; // PWR_ENABLED default
            reg_aes_key_size     <= 2'd0;
            reg_sha_mode         <= 3'd1;
            reg_crc_rem_reverse  <= 1'b0;
            reg_crc_data_reverse <= 1'b0;
            reg_crc_data_xor     <= '0;
            reg_crc_polynomial   <= 32'hEDB88320; // CRC-32 default (reflected)
            reg_crc_lfsr         <= 32'hFFFFFFFF;
            reg_crc_rem_xor      <= 32'hFFFFFFFF;
            reg_pr_lfsr0         <= PR_LFSR0_DEFAULT;
            reg_pr_lfsr1         <= PR_LFSR1_DEFAULT;
            reg_pr_lfsr2         <= PR_LFSR2_DEFAULT;
            reg_tr_ctl0          <= '0;
            reg_tr_ctl1          <= '0;
            reg_tr_garo_ctl      <= '0;
            reg_tr_firo_ctl      <= '0;
            reg_tr_mon_ctl       <= '0;
            reg_tr_mon_rc_cutoff <= TR_MON_RC_CUTOFF_DEFAULT;
            reg_tr_mon_ap_ctl    <= {TR_MON_AP_WINDOW_DEFAULT, TR_MON_AP_CUTOFF_DEFAULT};
            reg_vu_ctl0_always   <= 1'b1;
            reg_vu_ctl1_addr     <= '0;
            reg_intr_mask        <= '0;
            intr_clear           <= 1'b0;
            intr_set             <= 1'b0;
            intr_set_val         <= '0;
            reg_ext_aad_addr     <= '0;
            reg_ext_aad_len      <= '0;
            reg_ext_mac_addr     <= '0;
            reg_ext_key_addr     <= '0;
            reg_ext_key_id       <= '0;
            reg_ext_ctx_addr     <= '0;
            reg_ext_cancel       <= 1'b0;
        end else begin
            intr_clear <= 1'b0;
            intr_set   <= 1'b0;
            reg_ext_cancel <= 1'b0;

            if (wr_en) begin
                unique casez (dph_addr_q)
                    CRYPTO_CTL: begin
                        reg_ctl_enabled <= hwdata[CTL_BIT_ENABLED];
                        reg_pwr_mode    <= hwdata[CTL_BIT_PWR_MODE_HI:CTL_BIT_PWR_MODE_LO];
                    end
                    CRYPTO_AES_CTL:      reg_aes_key_size     <= hwdata[1:0];
                    CRYPTO_SHA_CTL:      reg_sha_mode         <= hwdata[2:0];
                    CRYPTO_CRC_CTL: begin
                        reg_crc_rem_reverse  <= hwdata[8];
                        reg_crc_data_reverse <= hwdata[0];
                    end
                    CRYPTO_CRC_DATA_CTL: reg_crc_data_xor   <= hwdata[7:0];
                    CRYPTO_CRC_POL_CTL:  reg_crc_polynomial  <= hwdata;
                    CRYPTO_CRC_LFSR_CTL: reg_crc_lfsr        <= hwdata;
                    CRYPTO_CRC_REM_CTL:  reg_crc_rem_xor     <= hwdata;
                    CRYPTO_PR_LFSR_CTL0: reg_pr_lfsr0        <= hwdata;
                    CRYPTO_PR_LFSR_CTL1: reg_pr_lfsr1        <= hwdata[30:0];
                    CRYPTO_PR_LFSR_CTL2: reg_pr_lfsr2        <= hwdata[28:0];
                    CRYPTO_TR_CTL0:      reg_tr_ctl0         <= hwdata;
                    CRYPTO_TR_CTL1:      reg_tr_ctl1         <= hwdata;
                    CRYPTO_TR_GARO_CTL:  reg_tr_garo_ctl     <= hwdata[30:0];
                    CRYPTO_TR_FIRO_CTL:  reg_tr_firo_ctl     <= hwdata[30:0];
                    CRYPTO_TR_MON_CTL:   reg_tr_mon_ctl      <= hwdata[1:0];
                    CRYPTO_TR_MON_RC_CTL: reg_tr_mon_rc_cutoff <= hwdata[7:0];
                    CRYPTO_TR_MON_AP_CTL: reg_tr_mon_ap_ctl  <= hwdata;
                    CRYPTO_VU_CTL0:      reg_vu_ctl0_always  <= hwdata[0];
                    CRYPTO_VU_CTL1:      reg_vu_ctl1_addr    <= hwdata;
                    CRYPTO_INTR_MASK:    reg_intr_mask       <= hwdata;
                    CRYPTO_INTR: begin
                        intr_clear <= |hwdata; // RW1C: any set bit clears
                    end
                    CRYPTO_INTR_SET: begin
                        intr_set     <= |hwdata;
                        intr_set_val <= hwdata;
                    end
                    // Extension registers
                    EXT_AAD_ADDR:  reg_ext_aad_addr  <= hwdata;
                    EXT_AAD_LEN:   reg_ext_aad_len   <= hwdata;
                    EXT_MAC_ADDR:  reg_ext_mac_addr  <= hwdata;
                    EXT_KEY_ADDR:  reg_ext_key_addr  <= hwdata;
                    EXT_KEY_ID:    reg_ext_key_id    <= hwdata[7:0];
                    EXT_CTX_ADDR:  reg_ext_ctx_addr  <= hwdata;
                    EXT_CANCEL:    reg_ext_cancel    <= hwdata[0];
                    default: ;
                endcase
            end
        end
    end

    // INSTR_FF_WR is write-only; handle combinatorially (one cycle pulse)
    assign instr_push_data = hwdata;
    assign instr_push_en   = dph_sel_q && dph_write_q &&
                             (dph_addr_q == CRYPTO_INSTR_FF_WR);

    // MEM_BUFF write
    assign mem_addr  = mem_word_addr;
    assign mem_wdata = hwdata;
    assign mem_we    = dph_sel_q && dph_write_q && is_mem_buff;

    // ------------------------------------------------------------------
    // INTR register (RW1C)
    // ------------------------------------------------------------------
    logic [31:0] intr_reg_q;
    logic [31:0] intr_masked_w;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) intr_reg_q <= '0;
        else begin
            // Set on raw interrupt
            intr_reg_q <= (intr_reg_q | intr_raw);
            // Clear on RW1C write
            if (intr_clear)
                intr_reg_q <= intr_reg_q & ~(wr_en ? hwdata : '0);
            // Force-set via RW1S
            if (intr_set)
                intr_reg_q <= intr_reg_q | intr_set_val;
        end
    end

    assign intr_masked_w = intr_reg_q & reg_intr_mask;

    // ------------------------------------------------------------------
    // STATUS register (combinational)
    // ------------------------------------------------------------------
    wire [31:0] status_w = {
        decoder_busy,             // [31] CMD_FF_BUSY
        23'h0,
        vu_busy,                  // [7]
        trng_busy,                // [6]
        prng_busy,                // [5]
        1'b0,                     // [4] STR_BUSY (not implemented)
        crc_busy,                 // [3]
        sha_busy,                 // [2]
        des_busy,                 // [1]
        aes_busy                  // [0]
    };

    // INSTR_FF_STATUS
    wire [31:0] ff_status_w = {
        instr_full | decoder_busy,// [31] BUSY
        15'h0,
        instr_event,              // [16] EVENT
        12'h0,
        instr_used                // [3:0] USED
    };

    // ------------------------------------------------------------------
    // Read mux
    // ------------------------------------------------------------------
    always_comb begin
        hrdata = '0;
        if (dph_sel_q && !dph_write_q) begin
            if (is_mem_buff) begin
                hrdata = mem_rdata;
            end else begin
                unique casez (dph_addr_q)
                    CRYPTO_CTL:             hrdata = {reg_ctl_enabled, 29'h0, reg_pwr_mode};
                    CRYPTO_STATUS:          hrdata = status_w;
                    CRYPTO_INSTR_FF_CTL:    hrdata = '0; // WO fields, return 0
                    CRYPTO_INSTR_FF_STATUS: hrdata = ff_status_w;
                    CRYPTO_AES_CTL:         hrdata = {30'h0, reg_aes_key_size};
                    CRYPTO_SHA_CTL:         hrdata = {29'h0, reg_sha_mode};
                    CRYPTO_CRC_CTL:         hrdata = {23'h0, reg_crc_rem_reverse, 7'h0, reg_crc_data_reverse};
                    CRYPTO_CRC_DATA_CTL:    hrdata = {24'h0, reg_crc_data_xor};
                    CRYPTO_CRC_POL_CTL:     hrdata = reg_crc_polynomial;
                    CRYPTO_CRC_LFSR_CTL:    hrdata = reg_crc_lfsr;
                    CRYPTO_CRC_REM_CTL:     hrdata = reg_crc_rem_xor;
                    CRYPTO_CRC_REM_RESULT:  hrdata = crc_rem_result;
                    CRYPTO_PR_LFSR_CTL0:    hrdata = reg_pr_lfsr0;
                    CRYPTO_PR_LFSR_CTL1:    hrdata = {1'h0, reg_pr_lfsr1};
                    CRYPTO_PR_LFSR_CTL2:    hrdata = {3'h0, reg_pr_lfsr2};
                    CRYPTO_PR_RESULT:       hrdata = pr_result;
                    CRYPTO_TR_CTL0:         hrdata = reg_tr_ctl0;
                    CRYPTO_TR_CTL1:         hrdata = reg_tr_ctl1;
                    CRYPTO_TR_RESULT:       hrdata = tr_result;
                    CRYPTO_TR_GARO_CTL:     hrdata = {1'h0, reg_tr_garo_ctl};
                    CRYPTO_TR_FIRO_CTL:     hrdata = {1'h0, reg_tr_firo_ctl};
                    CRYPTO_TR_MON_CTL:      hrdata = {30'h0, reg_tr_mon_ctl};
                    CRYPTO_TR_MON_AP_CTL:   hrdata = reg_tr_mon_ap_ctl;
                    CRYPTO_TR_MON_RC_CTL:   hrdata = {24'h0, reg_tr_mon_rc_cutoff};
                    CRYPTO_VU_CTL0:         hrdata = {31'h0, reg_vu_ctl0_always};
                    CRYPTO_VU_CTL1:         hrdata = reg_vu_ctl1_addr;
                    CRYPTO_VU_STATUS:       hrdata = {28'h0, vu_status};
                    CRYPTO_INTR:            hrdata = intr_reg_q;
                    CRYPTO_INTR_SET:        hrdata = '0; // WO
                    CRYPTO_INTR_MASK:       hrdata = reg_intr_mask;
                    CRYPTO_INTR_MASKED:     hrdata = intr_masked_w;
                    EXT_AAD_ADDR:           hrdata = reg_ext_aad_addr;
                    EXT_AAD_LEN:            hrdata = reg_ext_aad_len;
                    EXT_MAC_ADDR:           hrdata = reg_ext_mac_addr;
                    EXT_KEY_ADDR:           hrdata = reg_ext_key_addr;
                    EXT_KEY_ID:             hrdata = {24'h0, reg_ext_key_id};
                    EXT_CTX_ADDR:           hrdata = reg_ext_ctx_addr;
                    default: begin
                        // VU register file (0x080 + 4*n)
                        if (dph_addr_q >= CRYPTO_RF_DATA0 &&
                            dph_addr_q <= CRYPTO_RF_DATA15) begin
                            logic [3:0] idx;
                            idx = (dph_addr_q - CRYPTO_RF_DATA0) >> 2;
                            hrdata = vu_rf_data[idx];
                        end
                    end
                endcase
            end
        end
    end

endmodule
