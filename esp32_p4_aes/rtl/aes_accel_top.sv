// AES Accelerator Top-Level
// Integrates: AHB slave, AES core, block mode controller, GCM unit,
// DMA engine, and AXI master.

module aes_accel_top
    import aes_accel_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    // AHB-Lite Slave Interface
    input  logic        hsel,
    input  logic [31:0] haddr,
    input  logic [1:0]  htrans,
    input  logic        hwrite,
    input  logic [2:0]  hsize,
    input  logic [31:0] hwdata,
    output logic [31:0] hrdata,
    output logic        hreadyout,
    output logic        hresp,

    // AXI4 Master Interface
    output logic [3:0]  awid,
    output logic [31:0] awaddr,
    output logic [7:0]  awlen,
    output logic [2:0]  awsize,
    output logic [1:0]  awburst,
    output logic        awvalid,
    input  logic        awready,
    output logic [31:0] wdata,
    output logic [3:0]  wstrb,
    output logic        wlast,
    output logic        wvalid,
    input  logic        wready,
    input  logic [3:0]  bid,
    input  logic [1:0]  bresp,
    input  logic        bvalid,
    output logic        bready,
    output logic [3:0]  arid,
    output logic [31:0] araddr,
    output logic [7:0]  arlen,
    output logic [2:0]  arsize,
    output logic [1:0]  arburst,
    output logic        arvalid,
    input  logic        arready,
    input  logic [3:0]  rid,
    input  logic [31:0] rdata,
    input  logic [1:0]  rresp,
    input  logic        rlast,
    input  logic        rvalid,
    output logic        rready,

    // Interrupt
    output logic        irq
);

    // ---------------------------------------------------------------
    // Register file signals
    // ---------------------------------------------------------------
    logic [255:0] reg_key;
    logic [127:0] reg_text_in;
    logic [2:0]   reg_mode;
    logic [127:0] reg_iv;
    logic [127:0] reg_j0;
    logic         reg_dma_enable;
    logic [2:0]   reg_block_mode;
    logic [31:0]  reg_block_num;
    logic         reg_inc_sel;
    logic [31:0]  reg_aad_block_num;
    logic [6:0]   reg_remainder_bit_num;
    logic         reg_int_ena;
    logic [31:0]  reg_dma_src_addr;
    logic [31:0]  reg_dma_dst_addr;

    logic [127:0] reg_text_out;
    logic [127:0] reg_h_mem;
    logic [127:0] reg_t0_mem;
    logic [1:0]   reg_state;

    logic         trigger_start;
    logic         continue_op;
    logic         dma_exit;
    logic         int_clr;
    logic         irq_raw;
    logic         gcm_p2_done_latch;

    // Derived control signals
    wire decrypt = reg_mode[2];
    wire aes256  = reg_mode[1];
    wire is_gcm  = (blk_mode_e'(reg_block_mode) == BLK_GCM);

    // ---------------------------------------------------------------
    // AHB Slave
    // ---------------------------------------------------------------
    ahb_slave u_ahb_slave (
        .clk               (clk),
        .rst_n             (rst_n),
        .hsel              (hsel),
        .haddr             (haddr[11:0]),
        .htrans            (htrans),
        .hwrite            (hwrite),
        .hsize             (hsize),
        .hwdata            (hwdata),
        .hrdata            (hrdata),
        .hreadyout         (hreadyout),
        .hresp             (hresp),
        .key               (reg_key),
        .text_in           (reg_text_in),
        .mode_reg          (reg_mode),
        .iv                (reg_iv),
        .j0                (reg_j0),
        .dma_enable        (reg_dma_enable),
        .block_mode        (reg_block_mode),
        .block_num         (reg_block_num),
        .inc_sel           (reg_inc_sel),
        .aad_block_num     (reg_aad_block_num),
        .remainder_bit_num (reg_remainder_bit_num),
        .int_ena           (reg_int_ena),
        .dma_src_addr      (reg_dma_src_addr),
        .dma_dst_addr      (reg_dma_dst_addr),
        .text_out          (reg_text_out),
        .h_mem             (reg_h_mem),
        .t0_mem            (reg_t0_mem),
        .state             (reg_state),
        .trigger_start     (trigger_start),
        .continue_op       (continue_op),
        .dma_exit          (dma_exit),
        .int_clr           (int_clr),
        .irq_raw           (irq_raw),
        .irq               (irq)
    );

    // ---------------------------------------------------------------
    // AES Core
    // ---------------------------------------------------------------
    logic         core_start;
    logic         core_decrypt;
    logic [127:0] core_data_in;
    logic [127:0] core_data_out;
    logic         core_busy;
    logic         core_done;

    aes_core u_aes_core (
        .clk      (clk),
        .rst_n    (rst_n),
        .start    (core_start),
        .decrypt  (core_decrypt),
        .aes256   (aes256),
        .key      (reg_key),
        .data_in  (core_data_in),
        .data_out (core_data_out),
        .busy     (core_busy),
        .done     (core_done)
    );

    // ---------------------------------------------------------------
    // Block Mode Controller
    // ---------------------------------------------------------------
    logic [127:0] bmc_data_in;
    logic         bmc_data_in_valid;
    logic         bmc_data_in_ready;
    logic [127:0] bmc_data_out;
    logic         bmc_data_out_valid;
    logic         bmc_flush;
    logic         bmc_busy;

    // BMC core interface
    logic [127:0] bmc_core_data_in;
    logic         bmc_core_start;

    block_mode_ctrl u_block_mode_ctrl (
        .clk            (clk),
        .rst_n          (rst_n),
        .block_mode     (blk_mode_e'(reg_block_mode)),
        .decrypt        (decrypt),
        .iv_in          (reg_iv),
        .inc_sel        (reg_inc_sel),
        .data_in        (bmc_data_in),
        .data_in_valid  (bmc_data_in_valid),
        .data_in_ready  (bmc_data_in_ready),
        .core_data_in   (bmc_core_data_in),
        .core_start     (bmc_core_start),
        .core_data_out  (core_data_out),
        .core_done      (core_done),
        .data_out       (bmc_data_out),
        .data_out_valid (bmc_data_out_valid),
        .flush          (bmc_flush),
        .busy           (bmc_busy)
    );

    // ---------------------------------------------------------------
    // GCM Unit
    // ---------------------------------------------------------------
    logic [127:0] gcm_core_data_in;
    logic         gcm_core_start;
    logic         gcm_core_decrypt;
    logic [127:0] gcm_data_out;
    logic         gcm_data_out_valid;
    logic         gcm_data_in_ready;
    logic         gcm_phase1_done;
    logic         gcm_phase2_done;
    logic         gcm_busy;
    logic [127:0] gcm_h_out;
    logic [127:0] gcm_t0_out;

    gcm_unit u_gcm_unit (
        .clk               (clk),
        .rst_n             (rst_n),
        .start             (is_gcm && trigger_start && reg_dma_enable),
        .continue_op       (continue_op),
        .decrypt           (decrypt),
        .key               (reg_key),
        .aes256            (aes256),
        .iv                (reg_iv),
        .j0_in             (reg_j0),
        .aad_block_num     (reg_aad_block_num),
        .block_num         (reg_block_num),
        .remainder_bit_num (reg_remainder_bit_num),
        .data_in           (bmc_data_in),       // Shared with DMA path
        .data_in_valid     (1'b0),              // GCM gets data from DMA
        .data_in_ready     (gcm_data_in_ready),
        .data_out          (gcm_data_out),
        .data_out_valid    (gcm_data_out_valid),
        .core_data_in      (gcm_core_data_in),
        .core_start        (gcm_core_start),
        .core_decrypt      (gcm_core_decrypt),
        .core_data_out     (core_data_out),
        .core_done         (core_done),
        .core_busy         (core_busy),
        .h_out             (gcm_h_out),
        .t0_out            (gcm_t0_out),
        .phase1_done       (gcm_phase1_done),
        .phase2_done       (gcm_phase2_done),
        .busy              (gcm_busy)
    );

    assign reg_h_mem  = gcm_h_out;
    assign reg_t0_mem = gcm_t0_out;

    // ---------------------------------------------------------------
    // DMA Engine
    // ---------------------------------------------------------------
    logic [31:0]  dma_axi_rd_addr;
    logic [7:0]   dma_axi_rd_len;
    logic         dma_axi_rd_req;
    logic         dma_axi_rd_grant;
    logic [31:0]  dma_axi_rd_data;
    logic         dma_axi_rd_valid;
    logic         dma_axi_rd_last;

    logic [31:0]  dma_axi_wr_addr;
    logic [7:0]   dma_axi_wr_len;
    logic         dma_axi_wr_req;
    logic         dma_axi_wr_grant;
    logic [31:0]  dma_axi_wr_data;
    logic         dma_axi_wr_valid;
    logic         dma_axi_wr_ready;
    logic         dma_axi_wr_resp_ok;

    logic [127:0] dma_cipher_data_in;
    logic         dma_cipher_data_valid;
    logic         dma_cipher_data_ready;
    logic [127:0] dma_cipher_data_out;
    logic         dma_cipher_data_out_valid;
    logic         dma_done;
    accel_state_e dma_state;

    dma_engine u_dma_engine (
        .clk                 (clk),
        .rst_n               (rst_n),
        .start               (!is_gcm && trigger_start && reg_dma_enable),
        .dma_enable          (reg_dma_enable),
        .block_num           (reg_block_num),
        .src_addr            (reg_dma_src_addr),
        .dst_addr            (reg_dma_dst_addr),
        .dma_exit_cmd        (dma_exit),
        .axi_rd_addr         (dma_axi_rd_addr),
        .axi_rd_len          (dma_axi_rd_len),
        .axi_rd_req          (dma_axi_rd_req),
        .axi_rd_grant        (dma_axi_rd_grant),
        .axi_rd_data         (dma_axi_rd_data),
        .axi_rd_valid        (dma_axi_rd_valid),
        .axi_rd_last         (dma_axi_rd_last),
        .axi_wr_addr         (dma_axi_wr_addr),
        .axi_wr_len          (dma_axi_wr_len),
        .axi_wr_req          (dma_axi_wr_req),
        .axi_wr_grant        (dma_axi_wr_grant),
        .axi_wr_data         (dma_axi_wr_data),
        .axi_wr_valid        (dma_axi_wr_valid),
        .axi_wr_ready        (dma_axi_wr_ready),
        .axi_wr_resp_ok      (dma_axi_wr_resp_ok),
        .cipher_data_in      (dma_cipher_data_in),
        .cipher_data_valid   (dma_cipher_data_valid),
        .cipher_data_ready   (dma_cipher_data_ready),
        .cipher_data_out     (dma_cipher_data_out),
        .cipher_data_out_valid(dma_cipher_data_out_valid),
        .dma_done            (dma_done),
        .dma_state           (dma_state)
    );

    // ---------------------------------------------------------------
    // AXI Master
    // ---------------------------------------------------------------
    axi_master u_axi_master (
        .clk          (clk),
        .rst_n        (rst_n),
        .rd_addr      (dma_axi_rd_addr),
        .rd_len       (dma_axi_rd_len),
        .rd_req       (dma_axi_rd_req),
        .rd_grant     (dma_axi_rd_grant),
        .rd_data      (dma_axi_rd_data),
        .rd_valid     (dma_axi_rd_valid),
        .rd_last      (dma_axi_rd_last),
        .wr_addr      (dma_axi_wr_addr),
        .wr_len       (dma_axi_wr_len),
        .wr_req       (dma_axi_wr_req),
        .wr_grant     (dma_axi_wr_grant),
        .wr_data      (dma_axi_wr_data),
        .wr_valid_in  (dma_axi_wr_valid),
        .wr_ready_out (dma_axi_wr_ready),
        .wr_resp_ok   (dma_axi_wr_resp_ok),
        .awid         (awid),
        .awaddr       (awaddr),
        .awlen        (awlen),
        .awsize       (awsize),
        .awburst      (awburst),
        .awvalid      (awvalid),
        .awready      (awready),
        .wdata        (wdata),
        .wstrb        (wstrb),
        .wlast        (wlast),
        .wvalid       (wvalid),
        .wready       (wready),
        .bid          (bid),
        .bresp        (bresp),
        .bvalid       (bvalid),
        .bready       (bready),
        .arid         (arid),
        .araddr       (araddr),
        .arlen        (arlen),
        .arsize       (arsize),
        .arburst      (arburst),
        .arvalid      (arvalid),
        .arready      (arready),
        .rid          (rid),
        .rdata        (rdata),
        .rresp        (rresp),
        .rlast        (rlast),
        .rvalid       (rvalid),
        .rready       (rready)
    );

    // ---------------------------------------------------------------
    // Top-Level Control: Mux between typical, DMA, and GCM paths
    // ---------------------------------------------------------------
    // Typical mode state machine
    typedef enum logic [1:0] {
        TYP_IDLE,
        TYP_WORK,
        TYP_DONE
    } typical_state_e;

    typical_state_e typ_state_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            typ_state_q  <= TYP_IDLE;
            reg_text_out <= '0;
        end else begin
            case (typ_state_q)
                TYP_IDLE: begin
                    if (trigger_start && !reg_dma_enable) begin
                        typ_state_q <= TYP_WORK;
                    end
                end
                TYP_WORK: begin
                    if (core_done) begin
                        reg_text_out <= core_data_out;
                        typ_state_q  <= TYP_IDLE;
                    end
                end
                default: typ_state_q <= TYP_IDLE;
            endcase
        end
    end

    // GCM phase-2 done latch — gcm_phase2_done is a 1-cycle pulse;
    // hold it until software writes DMA_EXIT.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            gcm_p2_done_latch <= 1'b0;
        else if (dma_exit)
            gcm_p2_done_latch <= 1'b0;
        else if (gcm_phase2_done)
            gcm_p2_done_latch <= 1'b1;
    end

    // AES core input mux
    always_comb begin
        if (is_gcm && reg_dma_enable) begin
            // GCM mode: GCM unit controls the core
            core_data_in = gcm_core_data_in;
            core_start   = gcm_core_start;
            core_decrypt = gcm_core_decrypt;
        end else if (reg_dma_enable) begin
            // DMA non-GCM: block mode controller controls the core
            core_data_in = bmc_core_data_in;
            core_start   = bmc_core_start;
            core_decrypt = decrypt;
        end else begin
            // Typical mode: direct from registers
            core_data_in = reg_text_in;
            core_start   = trigger_start && !reg_dma_enable;
            core_decrypt = decrypt;
        end
    end

    // DMA cipher interface: connect DMA engine to block mode controller
    assign bmc_data_in       = dma_cipher_data_in;
    assign bmc_data_in_valid = dma_cipher_data_valid;
    assign dma_cipher_data_ready     = bmc_data_in_ready;
    assign dma_cipher_data_out       = bmc_data_out;
    assign dma_cipher_data_out_valid = bmc_data_out_valid;
    assign bmc_flush = trigger_start; // Reset block mode state on new operation

    // State register output mux
    always_comb begin
        if (reg_dma_enable) begin
            if (is_gcm) begin
                if (gcm_busy)
                    reg_state = ST_WORK;
                else if (gcm_phase1_done || gcm_p2_done_latch)
                    reg_state = ST_DONE;
                else
                    reg_state = ST_IDLE;
            end else begin
                reg_state = dma_state;
            end
        end else begin
            // Typical mode
            reg_state = (typ_state_q == TYP_WORK) ? ST_WORK : ST_IDLE;
        end
    end

    // IRQ raw: asserted on DMA completion or GCM phase 2 done
    assign irq_raw = dma_done || gcm_p2_done_latch;

endmodule
