// PSoC 6 Crypto Block — Top Level
//
// Wires together AHB slave, instruction FIFO, instruction decoder,
// register buffer, memory buffer, load/store FIFO DMA, and AHB master.
//
// Engine stubs (aes_core, sha_*_core, des_core, crc_engine, prng_engine,
// trng_core, vu_top) are instantiated below.  Each stub drives busy=0 and
// done=1 so the decoder sees immediate completion.  Replace each stub with
// the real module as each phase is implemented.

`include "crypto_pkg.sv"
`include "crypto_isa_pkg.sv"

module crypto_top
    import crypto_pkg::*;
    import crypto_isa_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    // AHB-Lite Slave (CPU configuration)
    input  logic        hsel,
    input  logic [14:0] haddr,
    input  logic [1:0]  htrans,
    input  logic        hwrite,
    input  logic [2:0]  hsize,
    input  logic [31:0] hwdata,
    output logic [31:0] hrdata,
    output logic        hreadyout,
    output logic        hresp,

    // AHB Master (DMA for LOAD/STORE FIFOs)
    output logic [31:0] m_haddr,
    output logic [1:0]  m_htrans,
    output logic        m_hwrite,
    output logic [2:0]  m_hsize,
    output logic [2:0]  m_hburst,
    output logic [31:0] m_hwdata,
    input  logic [31:0] m_hrdata,
    input  logic        m_hready,
    input  logic        m_hresp,

    // Interrupt output
    output logic        irq
);

    // ------------------------------------------------------------------
    // Internal signal declarations
    // ------------------------------------------------------------------

    // INSTR_FF_WR push
    logic [31:0] instr_push_data;
    logic        instr_push_en;
    logic [3:0]  instr_used;
    logic        instr_full, instr_empty, instr_event;

    // Decoder → instr_fifo
    logic [31:0] instr_pop_data;
    logic        instr_pop_en;

    // Decoder → reg_buffer
    logic [7:0]  bop_opcode;
    logic [3:0]  bop_src0, bop_src1, bop_dst, bop_size;
    logic [7:0]  bop_byte;
    logic        bop_reflect, bop_start;
    logic        bop_done, bop_cmp_eq, rb_bop_done;
    logic        rbuf_clear, rbuf_swap;

    // Decoder → load_store_fifo
    logic [3:0]  ff_id;
    logic [31:0] ff_addr, ff_size;
    logic        ff_start, ff_continue, ff_stop, ff_done;
    logic [3:0]  st_arm_src;
    logic        st_arm_valid;

    // reg_buffer staging
    logic [127:0] ld0_staging, ld1_staging;
    logic         ld0_valid_raw, ld1_valid_raw;
    logic [127:0] ld0_to_rb, ld1_to_rb;
    logic [3:0]   ld0_dst_to_rb, ld1_dst_to_rb;
    logic         ld0_vld_to_rb, ld1_vld_to_rb;
    logic [127:0] st_staging;
    logic         st_arm;
    logic [127:0] st_data_from_rb;

    // AHB master DMA
    logic [31:0]  dma_cmd_addr;
    logic         dma_cmd_read, dma_cmd_start, dma_cmd_done, dma_cmd_error;
    logic [31:0]  dma_rd_data [0:3];
    logic [31:0]  dma_wr_data [0:3];

    // Engine busy / done
    logic aes_busy, sha_busy, des_busy, crc_busy, vu_busy;
    logic decoder_busy;

    // Engine start/control from decoder
    logic aes_start, aes_decrypt;
    logic [2:0] sha_mode;
    logic sha_start;
    logic [3:0] des_mode;
    logic des_start;
    logic crc_start;
    logic [31:0] vu_instr;
    logic vu_start;

    // AHB slave register outputs
    logic [1:0]  reg_aes_key_size;
    logic        reg_aes_gcm_mode;
    logic [2:0]  reg_sha_mode;
    logic        reg_ctl_enabled;
    logic [1:0]  reg_pwr_mode;
    logic        reg_crc_rem_reverse, reg_crc_data_reverse;
    logic [7:0]  reg_crc_data_xor;
    logic [31:0] reg_crc_polynomial, reg_crc_lfsr, reg_crc_rem_xor;
    logic [31:0] reg_pr_lfsr0;
    logic [30:0] reg_pr_lfsr1;
    logic [28:0] reg_pr_lfsr2;
    logic [31:0] reg_tr_ctl0, reg_tr_ctl1;
    logic [30:0] reg_tr_garo_ctl, reg_tr_firo_ctl;
    logic [1:0]  reg_tr_mon_ctl;
    logic [7:0]  reg_tr_mon_rc_cutoff;
    logic [31:0] reg_tr_mon_ap_ctl;
    logic        reg_vu_ctl0_always;
    logic [31:0] reg_vu_ctl1_addr;
    logic [31:0] reg_intr_mask;
    logic        intr_clear, intr_set;
    logic [31:0] intr_set_val;
    logic [31:0] reg_ext_aad_addr, reg_ext_aad_len, reg_ext_mac_addr;
    logic [31:0] reg_ext_key_addr, reg_ext_ctx_addr;
    logic [7:0]  reg_ext_key_id;
    logic        reg_ext_cancel;

    // Stub engine outputs
    logic [31:0] crc_rem_result, pr_result, tr_result;
    logic [3:0]  vu_status;
    logic [31:0] vu_rf_data [0:RF_NREGS-1];

    // Interrupt
    logic [31:0] intr_raw;
    logic        bus_error_irq, overflow_irq, opc_error_irq, cc_error_irq;
    logic        intr_clear_w, intr_set_w;
    logic [31:0] intr_masked_w;
    logic        instr_ff_ctl_clear;
    logic [2:0]  instr_ff_ctl_event_level;

    // mem_buffer
    logic [9:0]  mb_a_addr;
    logic [31:0] mb_a_wdata, mb_a_rdata;
    logic        mb_a_we;

    // eng ports on reg_buffer
    logic [127:0] eng_rd_data;
    logic [3:0]   eng_rd_addr, eng_wr_addr;
    logic [127:0] eng_wr_data;
    logic         eng_wr_en;

    // SHA: full 2048-bit register buffer read port
    logic [2047:0] sha_rb_rd;

    // aes_core engine port sub-signals
    logic [3:0]   aes_eng_rd_addr;
    logic [3:0]   aes_eng_wr_addr;
    logic [127:0] aes_eng_wr_data;
    logic         aes_eng_wr_en;

    // DES engine write signals
    logic [3:0]   des_eng_wr_addr;
    logic [127:0] des_eng_wr_data;
    logic         des_eng_wr_en;

    // GHASH engine write signals
    logic [3:0]   ghash_eng_wr_addr;
    logic [127:0] ghash_eng_wr_data;
    logic         ghash_eng_wr_en;
    logic         ghash_start_sig, ghash_busy_sig;

    // SHA engine write-bus (muxed output from all 4 SHA cores)
    logic [3:0]   sha_eng_wr_addr;
    logic [127:0] sha_eng_wr_data;
    logic         sha_eng_wr_en;

    // Per-SHA-core busy + wr signals
    logic sha1_busy, sha256_busy, sha512_busy, sha3_busy_sig;
    logic [3:0]   sha1_wr_addr, sha256_wr_addr, sha512_wr_addr, sha3_wr_addr;
    logic [127:0] sha1_wr_data, sha256_wr_data, sha512_wr_data, sha3_wr_data;
    logic         sha1_wr_en,   sha256_wr_en,   sha512_wr_en,   sha3_wr_en;

    // ------------------------------------------------------------------
    // AHB Slave
    // ------------------------------------------------------------------
    ahb_slave u_ahb_slave (
        .clk                (clk),
        .rst_n              (rst_n),
        .hsel               (hsel),
        .haddr              (haddr),
        .htrans             (htrans),
        .hwrite             (hwrite),
        .hsize              (hsize),
        .hwdata             (hwdata),
        .hrdata             (hrdata),
        .hreadyout          (hreadyout),
        .hresp              (hresp),
        .instr_push_data    (instr_push_data),
        .instr_push_en      (instr_push_en),
        .instr_used         (instr_used),
        .instr_full         (instr_full),
        .instr_empty        (instr_empty),
        .instr_event        (instr_event),
        .aes_busy           (aes_busy),
        .des_busy           (des_busy),
        .sha_busy           (sha_busy),
        .crc_busy           (crc_busy),
        .prng_busy          (1'b0),
        .trng_busy          (1'b0),
        .vu_busy            (vu_busy),
        .decoder_busy       (decoder_busy),
        .reg_aes_key_size   (reg_aes_key_size),
        .reg_aes_gcm_mode   (reg_aes_gcm_mode),
        .reg_sha_mode       (reg_sha_mode),
        .reg_ctl_enabled    (reg_ctl_enabled),
        .reg_pwr_mode       (reg_pwr_mode),
        .reg_crc_rem_reverse(reg_crc_rem_reverse),
        .reg_crc_data_reverse(reg_crc_data_reverse),
        .reg_crc_data_xor   (reg_crc_data_xor),
        .reg_crc_polynomial (reg_crc_polynomial),
        .reg_crc_lfsr       (reg_crc_lfsr),
        .reg_crc_rem_xor    (reg_crc_rem_xor),
        .crc_rem_result     (crc_rem_result),
        .reg_pr_lfsr0       (reg_pr_lfsr0),
        .reg_pr_lfsr1       (reg_pr_lfsr1),
        .reg_pr_lfsr2       (reg_pr_lfsr2),
        .pr_result          (pr_result),
        .reg_tr_ctl0        (reg_tr_ctl0),
        .reg_tr_ctl1        (reg_tr_ctl1),
        .reg_tr_garo_ctl    (reg_tr_garo_ctl),
        .reg_tr_firo_ctl    (reg_tr_firo_ctl),
        .reg_tr_mon_ctl     (reg_tr_mon_ctl),
        .reg_tr_mon_rc_cutoff(reg_tr_mon_rc_cutoff),
        .reg_tr_mon_ap_ctl  (reg_tr_mon_ap_ctl),
        .tr_result          (tr_result),
        .reg_vu_ctl0_always (reg_vu_ctl0_always),
        .reg_vu_ctl1_addr   (reg_vu_ctl1_addr),
        .vu_status          (vu_status),
        .reg_intr_mask      (reg_intr_mask),
        .intr_raw           (intr_raw),
        .intr_clear         (intr_clear),
        .intr_set           (intr_set),
        .intr_set_val       (intr_set_val),
        .vu_rf_data         (vu_rf_data),
        .mem_addr           (mb_a_addr),
        .mem_wdata          (mb_a_wdata),
        .mem_we             (mb_a_we),
        .mem_rdata          (mb_a_rdata),
        .reg_ext_aad_addr   (reg_ext_aad_addr),
        .reg_ext_aad_len    (reg_ext_aad_len),
        .reg_ext_mac_addr   (reg_ext_mac_addr),
        .reg_ext_key_addr   (reg_ext_key_addr),
        .reg_ext_key_id     (reg_ext_key_id),
        .reg_ext_ctx_addr   (reg_ext_ctx_addr),
        .reg_ext_cancel     (reg_ext_cancel)
    );

    // ------------------------------------------------------------------
    // Instruction FIFO
    // ------------------------------------------------------------------
    assign instr_ff_ctl_clear       = 1'b0; // driven from INSTR_FF_CTL.CLEAR bit
    assign instr_ff_ctl_event_level = 3'd1;

    instr_fifo u_instr_fifo (
        .clk          (clk),
        .rst_n        (rst_n),
        .push_data    (instr_push_data),
        .push_en      (instr_push_en),
        .pop_data     (instr_pop_data),
        .pop_en       (instr_pop_en),
        .fifo_clear   (instr_ff_ctl_clear),
        .event_level  (instr_ff_ctl_event_level),
        .used         (instr_used),
        .fifo_full    (instr_full),
        .fifo_empty   (instr_empty),
        .event_flag   (instr_event),
        .busy         (/* unused */),
        .overflow_irq (overflow_irq)
    );

    // ------------------------------------------------------------------
    // Instruction Decoder
    // ------------------------------------------------------------------
    instr_decoder u_decoder (
        .clk            (clk),
        .rst_n          (rst_n),
        .instr_data     (instr_pop_data),
        .instr_pop      (instr_pop_en),
        .instr_empty    (instr_empty),
        .bop_opcode     (bop_opcode),
        .bop_src0       (bop_src0),
        .bop_src1       (bop_src1),
        .bop_dst        (bop_dst),
        .bop_size       (bop_size),
        .bop_byte       (bop_byte),
        .bop_reflect    (bop_reflect),
        .bop_start      (bop_start),
        .bop_done       (bop_done),
        .rbuf_clear     (rbuf_clear),
        .rbuf_swap      (rbuf_swap),
        .ff_id          (ff_id),
        .ff_addr        (ff_addr),
        .ff_size        (ff_size),
        .ff_start       (ff_start),
        .ff_continue    (ff_continue),
        .ff_stop        (ff_stop),
        .ff_done        (ff_done),
        .st_arm_src     (st_arm_src),
        .st_arm_valid   (st_arm_valid),
        .aes_start      (aes_start),
        .aes_decrypt    (aes_decrypt),
        .aes_busy       (aes_busy),
        .sha_mode       (sha_mode),
        .sha_start      (sha_start),
        .sha_busy       (sha_busy),
        .des_mode       (des_mode),
        .des_start      (des_start),
        .des_busy       (des_busy),
        .crc_start      (crc_start),
        .crc_busy       (crc_busy),
        .vu_instr       (vu_instr),
        .vu_start       (vu_start),
        .vu_busy        (vu_busy),
        .aes_key_size   (reg_aes_key_size),
        .sha_ctl_mode   (reg_sha_mode),
        .opc_error      (opc_error_irq),
        .cc_error       (cc_error_irq),
        .decoder_busy   (decoder_busy)
    );

    // ------------------------------------------------------------------
    // Register Buffer
    // ------------------------------------------------------------------
    // Wire LOAD_FIFO staging data to reg_buffer inputs
    // After BLOCK_MOV(LOAD0→BLOCKn), ld0_valid fires and loads staging into block
    // We use the block ID from the most recent BLOCK_MOV dst
    // (tracked in the decoder's bop_dst when bop_src0==BLKID_LOAD_FIFO0)
    logic [3:0] ld0_dst_latch_q, ld1_dst_latch_q;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ld0_dst_latch_q <= BLKID_BLOCK0;
            ld1_dst_latch_q <= BLKID_BLOCK1;
        end else if (bop_start && bop_opcode == OPC_BLOCK_MOV) begin
            if (bop_src0 == BLKID_LOAD_FIFO0) ld0_dst_latch_q <= bop_dst;
            if (bop_src0 == BLKID_LOAD_FIFO1) ld1_dst_latch_q <= bop_dst;
        end
    end

    assign ld0_to_rb     = ld0_staging;
    assign ld0_dst_to_rb = ld0_dst_latch_q;
    assign ld0_vld_to_rb = ld0_valid_raw &&
                           (bop_opcode == OPC_BLOCK_MOV) && bop_done &&
                           (bop_src0 == BLKID_LOAD_FIFO0);
    assign ld1_to_rb     = ld1_staging;
    assign ld1_dst_to_rb = ld1_dst_latch_q;
    assign ld1_vld_to_rb = ld1_valid_raw &&
                           (bop_opcode == OPC_BLOCK_MOV) && bop_done &&
                           (bop_src0 == BLKID_LOAD_FIFO1);

    // STORE staging: on BLOCK_MOV(BLOCKn→STORE), latch block content
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st_staging <= '0;
            st_arm     <= 1'b0;
        end else begin
            st_arm <= 1'b0;
            if (st_arm_valid) begin
                st_staging <= eng_rd_data; // combinational read from reg_buffer via eng_rd_addr
                st_arm     <= 1'b1;
            end
        end
    end

    // eng_rd_addr mux: aes_core gets priority when busy, else store-staging path
    assign eng_rd_addr = aes_busy     ? aes_eng_rd_addr :
                         st_arm_valid ? st_arm_src : 4'd0;

    // SHA write-bus mux (only one SHA core active at a time)
    assign sha_eng_wr_en   = sha1_wr_en | sha256_wr_en | sha512_wr_en | sha3_wr_en;
    assign sha_eng_wr_addr = sha1_wr_en   ? sha1_wr_addr   :
                             sha256_wr_en ? sha256_wr_addr  :
                             sha512_wr_en ? sha512_wr_addr  :
                                            sha3_wr_addr;
    assign sha_eng_wr_data = sha1_wr_en   ? sha1_wr_data   :
                             sha256_wr_en ? sha256_wr_data  :
                             sha512_wr_en ? sha512_wr_data  :
                                            sha3_wr_data;

    // eng_wr: priority: AES > SHA > DES > GHASH
    assign eng_wr_addr = aes_eng_wr_en   ? aes_eng_wr_addr  :
                         sha_eng_wr_en   ? sha_eng_wr_addr  :
                         des_eng_wr_en   ? des_eng_wr_addr  :
                         ghash_eng_wr_en ? ghash_eng_wr_addr : 4'd0;
    assign eng_wr_data = aes_eng_wr_en   ? aes_eng_wr_data  :
                         sha_eng_wr_en   ? sha_eng_wr_data  :
                         des_eng_wr_en   ? des_eng_wr_data  :
                         ghash_eng_wr_en ? ghash_eng_wr_data : '0;
    assign eng_wr_en   = aes_eng_wr_en | sha_eng_wr_en | des_eng_wr_en | ghash_eng_wr_en;

    reg_buffer u_reg_buffer (
        .clk         (clk),
        .rst_n       (rst_n),
        .bop_opcode  (bop_opcode),
        .bop_src0    (bop_src0),
        .bop_src1    (bop_src1),
        .bop_dst     (bop_dst),
        .bop_size    (bop_size),
        .bop_byte    (bop_byte),
        .bop_reflect (bop_reflect),
        // Suppress CMP_GCM execution in reg_buffer when in GCM mode (GHASH handles it)
        .bop_start   (bop_start && (bop_dst != BLKID_STORE_FIFO)
                      && !(reg_aes_gcm_mode && (bop_opcode == OPC_BLOCK_CMP_GCM))),
        .bop_done    (rb_bop_done),
        .bop_cmp_eq  (bop_cmp_eq),
        .rbuf_clear  (rbuf_clear),
        .rbuf_swap   (rbuf_swap),
        .ld0_data    (ld0_to_rb),
        .ld0_dst     (ld0_dst_to_rb),
        .ld0_valid   (ld0_vld_to_rb),
        .ld1_data    (ld1_to_rb),
        .ld1_dst     (ld1_dst_to_rb),
        .ld1_valid   (ld1_vld_to_rb),
        .st_data     (st_data_from_rb),
        .st_src      (st_arm_src),
        .eng_rd_addr (eng_rd_addr),
        .eng_rd_data (eng_rd_data),
        .eng_wr_addr (eng_wr_addr),
        .eng_wr_data (eng_wr_data),
        .eng_wr_en   (eng_wr_en),
        .sha_rb_rd   (sha_rb_rd)
    );
    // bop_done: from reg_buffer normally; ghash writeback pulse in GCM mode
    assign bop_done = reg_aes_gcm_mode ? ghash_eng_wr_en : rb_bop_done;

    // ------------------------------------------------------------------
    // Memory Buffer
    // ------------------------------------------------------------------
    mem_buffer u_mem_buffer (
        .clk     (clk),
        .a_addr  (mb_a_addr),
        .a_wdata (mb_a_wdata),
        .a_we    (mb_a_we),
        .a_rdata (mb_a_rdata),
        .b_addr  (vu_mb_b_addr),
        .b_wdata (vu_mb_b_wdata),
        .b_we    (vu_mb_b_we),
        .b_rdata (vu_mb_b_rdata)
    );

    // ------------------------------------------------------------------
    // Load/Store FIFO + AHB Master
    // ------------------------------------------------------------------
    logic [31:0] lsf_rd_flat [0:3];
    logic [31:0] lsf_wr_flat [0:3];

    // Flatten store staging into write array
    always_comb begin
        for (int i = 0; i < 4; i++)
            lsf_wr_flat[i] = st_staging[i*32 +: 32];
    end

    // Pack read data into 128-bit load staging (handled inside load_store_fifo)

    load_store_fifo u_lsfifo (
        .clk          (clk),
        .rst_n        (rst_n),
        .cmd_ff_id    (ff_id),
        .cmd_addr     (ff_addr),
        .cmd_size     (ff_size),
        .cmd_start    (ff_start),
        .cmd_continue (ff_continue),
        .cmd_stop     (ff_stop),
        .cmd_done     (ff_done),
        .ld0_staging  (ld0_staging),
        .ld0_valid    (ld0_valid_raw),
        .ld1_staging  (ld1_staging),
        .ld1_valid    (ld1_valid_raw),
        .st_staging   (st_staging),
        .st_arm       (st_arm),
        .m_haddr      (m_haddr),
        .m_htrans     (m_htrans),
        .m_hwrite     (m_hwrite),
        .m_hsize      (m_hsize),
        .m_hburst     (m_hburst),
        .m_hwdata     (m_hwdata),
        .m_hrdata     (m_hrdata),
        .m_hready     (m_hready),
        .m_hresp      (m_hresp),
        .bus_error_irq(/* tied to intr_raw below */)
    );

    // ------------------------------------------------------------------
    // AES Core (Phase 2)
    // ------------------------------------------------------------------
    aes_core u_aes_core (
        .clk         (clk),
        .rst_n       (rst_n),
        .key_size    (reg_aes_key_size),
        .decrypt     (aes_decrypt),
        .start       (aes_start),
        .busy        (aes_busy),
        .eng_rd_addr (aes_eng_rd_addr),
        .eng_rd_data (eng_rd_data),
        .eng_wr_addr (aes_eng_wr_addr),
        .eng_wr_data (aes_eng_wr_data),
        .eng_wr_en   (aes_eng_wr_en)
    );

    // ------------------------------------------------------------------
    // Engine stubs (replaced phase-by-phase)
    // ------------------------------------------------------------------

    // ------------------------------------------------------------------
    // SHA Cores (Phase 3)
    // ------------------------------------------------------------------
    // sha_mode[2:0]: 0=SHA1, 1=SHA256, 2=SHA512, 3=SHA3/Keccak
    // sha_start fires for all SHA opcodes; mode gates the correct core
    sha1_core u_sha1 (
        .clk         (clk),
        .rst_n       (rst_n),
        .start       (sha_start && (sha_mode == 3'd0)),
        .busy        (sha1_busy),
        .sha_rb_rd   (sha_rb_rd),
        .eng_wr_addr (sha1_wr_addr),
        .eng_wr_data (sha1_wr_data),
        .eng_wr_en   (sha1_wr_en)
    );

    sha2_256_core u_sha256 (
        .clk         (clk),
        .rst_n       (rst_n),
        .start       (sha_start && (sha_mode == 3'd1)),
        .busy        (sha256_busy),
        .sha_rb_rd   (sha_rb_rd),
        .eng_wr_addr (sha256_wr_addr),
        .eng_wr_data (sha256_wr_data),
        .eng_wr_en   (sha256_wr_en)
    );

    sha2_512_core u_sha512 (
        .clk         (clk),
        .rst_n       (rst_n),
        .start       (sha_start && (sha_mode == 3'd2)),
        .busy        (sha512_busy),
        .sha_rb_rd   (sha_rb_rd),
        .eng_wr_addr (sha512_wr_addr),
        .eng_wr_data (sha512_wr_data),
        .eng_wr_en   (sha512_wr_en)
    );

    sha3_keccak u_sha3 (
        .clk         (clk),
        .rst_n       (rst_n),
        .start       (sha_start && (sha_mode >= 3'd3)),
        .busy        (sha3_busy_sig),
        .sha_rb_rd   (sha_rb_rd),
        .eng_wr_addr (sha3_wr_addr),
        .eng_wr_data (sha3_wr_data),
        .eng_wr_en   (sha3_wr_en)
    );

    assign sha_busy = sha1_busy | sha256_busy | sha512_busy | sha3_busy_sig;

    // ------------------------------------------------------------------
    // DES / Triple-DES Engine (Phase 6)
    // ------------------------------------------------------------------
    des_core u_des (
        .clk         (clk),
        .rst_n       (rst_n),
        .des_mode    (des_mode),
        .des_start   (des_start),
        .des_busy    (des_busy),
        .sha_rb_rd   (sha_rb_rd),
        .eng_wr_addr (des_eng_wr_addr),
        .eng_wr_data (des_eng_wr_data),
        .eng_wr_en   (des_eng_wr_en)
    );

    // ------------------------------------------------------------------
    // GHASH Engine (Phase 6) — GCM GF(2^128) multiply-accumulate
    // Triggered when OPC_BLOCK_CMP_GCM fires in AES_CTL.GCM_MODE=1
    // ------------------------------------------------------------------
    assign ghash_start_sig = bop_start && (bop_opcode == OPC_BLOCK_CMP_GCM) && reg_aes_gcm_mode;

    ghash u_ghash (
        .clk         (clk),
        .rst_n       (rst_n),
        .ghash_start (ghash_start_sig),
        .ghash_busy  (ghash_busy_sig),
        .sha_rb_rd   (sha_rb_rd),
        .eng_wr_addr (ghash_eng_wr_addr),
        .eng_wr_data (ghash_eng_wr_data),
        .eng_wr_en   (ghash_eng_wr_en)
    );

    // ------------------------------------------------------------------
    // CRC Engine (Phase 4)
    // ------------------------------------------------------------------
    crc_engine u_crc (
        .clk                 (clk),
        .rst_n               (rst_n),
        .crc_start           (crc_start),
        .crc_busy            (crc_busy),
        .ld0_staging         (ld0_staging),
        .ld0_valid           (ld0_valid_raw),
        .ff_done             (ff_done),
        .reg_crc_polynomial  (reg_crc_polynomial),
        .reg_crc_lfsr        (reg_crc_lfsr),
        .reg_crc_rem_xor     (reg_crc_rem_xor),
        .reg_crc_rem_reverse (reg_crc_rem_reverse),
        .reg_crc_data_reverse(reg_crc_data_reverse),
        .reg_crc_data_xor    (reg_crc_data_xor),
        .crc_rem_result      (crc_rem_result)
    );

    // ------------------------------------------------------------------
    // PRNG Engine (Phase 4)
    // ------------------------------------------------------------------
    prng_engine u_prng (
        .clk       (clk),
        .rst_n     (rst_n),
        .enabled   (reg_ctl_enabled),
        .seed0     (reg_pr_lfsr0),
        .seed1     (reg_pr_lfsr1),
        .seed2     (reg_pr_lfsr2),
        .pr_reseed (1'b0),       // reseed from AHB write not yet implemented
        .pr_result (pr_result)
    );

    // ------------------------------------------------------------------
    // TRNG Core + Health Monitor (Phase 5)
    // ------------------------------------------------------------------
    logic        trng_bit, trng_bit_valid, trng_result_valid;
    logic        trng_rc_fail, trng_ap_fail;

    trng_core u_trng (
        .clk             (clk),
        .rst_n           (rst_n),
        .reg_tr_ctl0     (reg_tr_ctl0),
        .reg_tr_ctl1     (reg_tr_ctl1),
        .reg_tr_garo_ctl (reg_tr_garo_ctl),
        .reg_tr_firo_ctl (reg_tr_firo_ctl),
        .tr_result       (tr_result),
        .tr_result_valid (trng_result_valid),
        .tr_bit          (trng_bit),
        .tr_bit_valid    (trng_bit_valid)
    );

    trng_health_mon u_trng_hmon (
        .clk                 (clk),
        .rst_n               (rst_n),
        .tr_bit              (trng_bit),
        .tr_bit_valid        (trng_bit_valid),
        .reg_tr_mon_ctl      (reg_tr_mon_ctl),
        .reg_tr_mon_rc_cutoff(reg_tr_mon_rc_cutoff),
        .reg_tr_mon_ap_ctl   (reg_tr_mon_ap_ctl),
        .rc_fail             (trng_rc_fail),
        .ap_fail             (trng_ap_fail)
    );

    // ------------------------------------------------------------------
    // Vector Unit (Phase 7)
    // ------------------------------------------------------------------
    logic [9:0]  vu_mb_b_addr;
    logic [31:0] vu_mb_b_wdata;
    logic        vu_mb_b_we;
    logic [31:0] vu_mb_b_rdata;

    vu_top u_vu (
        .clk        (clk),
        .rst_n      (rst_n),
        .vu_instr   (vu_instr),
        .vu_start   (vu_start),
        .vu_busy    (vu_busy),
        .vu_status  (vu_status),
        .vu_rf_data (vu_rf_data),
        .b_addr     (vu_mb_b_addr),
        .b_wdata    (vu_mb_b_wdata),
        .b_we       (vu_mb_b_we),
        .b_rdata    (vu_mb_b_rdata)
    );

    // ------------------------------------------------------------------
    // Interrupt aggregation
    // ------------------------------------------------------------------
    assign intr_raw = {
        11'h0,
        trng_rc_fail,          // [20] TR_RC
        trng_ap_fail,          // [19] TR_AP
        1'b0,                  // [18] BUS_ERROR
        cc_error_irq,          // [17] INSTR_CC_ERROR
        opc_error_irq,         // [16] INSTR_OPC_ERROR
        11'h0,
        1'b0,                  // [4] PR_DATA_AVAIL
        1'b0,                  // [3] TR_DATA_AVAIL
        1'b0,                  // [2] TR_INITIALIZED
        overflow_irq,          // [1] INSTR_FF_OFLOW
        instr_event            // [0] INSTR_FF_LEVEL
    };

    assign irq = |(intr_raw & reg_intr_mask);

endmodule
