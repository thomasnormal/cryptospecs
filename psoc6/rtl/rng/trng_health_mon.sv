// PSoC 6 Crypto — TRNG Health Monitor
//
// Implements NIST SP 800-90B §4.4 continuous tests:
//   RC (Repetition Count) test  — detects stuck-at faults
//   AP (Adaptive Proportion) test — detects correlated or biased outputs
//
// Inputs from trng_core: raw bitstream (tr_bit, tr_bit_valid)
// Configuration from AHB slave:
//   reg_tr_mon_ctl[1:0]      — bitstream selector (ignored here, uses tr_bit)
//   reg_tr_mon_rc_cutoff[7:0] — RC cutoff C (default 255)
//   reg_tr_mon_ap_ctl[31:16] — AP window size W (default 65535)
//   reg_tr_mon_ap_ctl[15:0]  — AP cutoff C_ap (default 65535)
//
// On test failure:
//   rc_fail — RC failure (1-cycle pulse → drives INTR[TR_RC_DETECT_ERR])
//   ap_fail — AP failure (1-cycle pulse → drives INTR[TR_AP_DETECT_ERR])

`include "crypto_pkg.sv"

module trng_health_mon
    import crypto_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    // Bitstream from trng_core
    input  logic        tr_bit,
    input  logic        tr_bit_valid,

    // Configuration
    input  logic [1:0]  reg_tr_mon_ctl,
    input  logic [7:0]  reg_tr_mon_rc_cutoff,
    input  logic [31:0] reg_tr_mon_ap_ctl,

    // Failure outputs (one-cycle pulses)
    output logic        rc_fail,
    output logic        ap_fail
);

    // ---------------------------------------------------------------
    // RC (Repetition Count) Test — NIST SP 800-90B §4.4.1
    // Counts consecutive identical bits; fails if count >= cutoff C.
    // ---------------------------------------------------------------
    logic [7:0]  rc_count_q;
    logic        rc_prev_bit_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rc_count_q    <= 8'd1;
            rc_prev_bit_q <= 1'b0;
            rc_fail       <= 1'b0;
        end else begin
            rc_fail <= 1'b0;
            if (tr_bit_valid) begin
                if (tr_bit == rc_prev_bit_q) begin
                    if (rc_count_q >= reg_tr_mon_rc_cutoff) begin
                        rc_fail    <= 1'b1;
                        rc_count_q <= 8'd1;
                    end else
                        rc_count_q <= rc_count_q + 1;
                end else begin
                    rc_count_q    <= 8'd1;
                    rc_prev_bit_q <= tr_bit;
                end
            end
        end
    end

    // ---------------------------------------------------------------
    // AP (Adaptive Proportion) Test — NIST SP 800-90B §4.4.2
    // Within a sliding window of W bits, counts occurrences of the
    // "sample bit" (first bit of window).  Fails if count >= C_ap.
    // ---------------------------------------------------------------
    logic [15:0] ap_window_size;  // W
    logic [15:0] ap_cutoff;       // C_ap
    assign ap_window_size = reg_tr_mon_ap_ctl[31:16];
    assign ap_cutoff      = reg_tr_mon_ap_ctl[15:0];

    logic [15:0] ap_win_cnt_q;   // bits seen in current window
    logic [15:0] ap_occ_cnt_q;   // occurrences of sample bit in window
    logic        ap_sample_bit_q; // first bit of current window

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ap_win_cnt_q    <= '0;
            ap_occ_cnt_q    <= '0;
            ap_sample_bit_q <= 1'b0;
            ap_fail         <= 1'b0;
        end else begin
            ap_fail <= 1'b0;
            if (tr_bit_valid) begin
                if (ap_win_cnt_q == 16'd0) begin
                    // Start new window; sample bit = first bit
                    ap_sample_bit_q <= tr_bit;
                    ap_occ_cnt_q    <= 16'd1;
                    ap_win_cnt_q    <= 16'd1;
                end else begin
                    ap_win_cnt_q <= ap_win_cnt_q + 1;
                    if (tr_bit == ap_sample_bit_q)
                        ap_occ_cnt_q <= ap_occ_cnt_q + 1;
                    if (ap_occ_cnt_q + (tr_bit == ap_sample_bit_q ? 1 : 0)
                                    >= ap_cutoff)
                        ap_fail <= 1'b1;
                    if (ap_win_cnt_q + 1 >= ap_window_size)
                        ap_win_cnt_q <= '0;  // reset window
                end
            end
        end
    end

endmodule
