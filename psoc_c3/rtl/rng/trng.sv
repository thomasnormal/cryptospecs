// PSoC Control C3 CryptoLite — TRNG Behavioral Model
//
// Behavioral model of the ring-oscillator-based TRNG.
// Ring oscillators are modelled as LFSRs (not physically accurate; simulation only).
// Supports: raw bit collection, Von Neumann corrector, RC and AP health tests.
//
// Source: PSoC Control C3 Architecture TRM §TRNG

module trng
    import cryptolite_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    // Config registers (from regfile)
    input  logic [31:0] ctl0,          // TRNG_CTL0
    input  logic [31:0] ctl1,          // TRNG_CTL1 — ring oscillator enables
    input  logic [30:0] garo_ctl,      // TRNG_GARO_CTL  polynomial
    input  logic [30:0] firo_ctl,      // TRNG_FIRO_CTL  polynomial
    input  logic [31:0] mon_ctl,       // TRNG_MON_CTL   — AP/RC test enables + BSEL
    input  logic [31:0] mon_rc_ctl,    // TRNG_MON_RC_CTL — RC cutoff
    input  logic [31:0] mon_ap_ctl,    // TRNG_MON_AP_CTL — AP window + cutoff

    // Status / result (to regfile)
    output logic [31:0] status,
    output logic [31:0] result,
    output logic        data_valid,    // 1 = result holds fresh 32-bit sample
    input  logic        result_read,   // regfile consumed result; prepare next sample

    output logic [31:0] mon_rc_status0,
    output logic [31:0] mon_rc_status1,
    output logic [31:0] mon_ap_status0,
    output logic [31:0] mon_ap_status1,

    // Interrupt outputs to regfile (level signals)
    output logic        initialized,   // TRNG has produced at least one sample
    output logic        ap_detect,     // AP health test fail
    output logic        rc_detect      // RC health test fail
);

    // ---------------------------------------------------------------
    // CTL0 fields
    // ---------------------------------------------------------------
    wire        von_neumann_en = ctl0[TRNG_CTL0_BIT_VON_NEUMANN];
    wire        stop_on_ap     = ctl0[TRNG_CTL0_BIT_STOP_ON_AP];
    wire        stop_on_rc     = ctl0[TRNG_CTL0_BIT_STOP_ON_RC];

    // CTL1: ring oscillator enables
    wire ro11_en   = ctl1[TRNG_CTL1_BIT_RO11_EN];
    wire ro15_en   = ctl1[TRNG_CTL1_BIT_RO15_EN];
    wire garo15_en = ctl1[TRNG_CTL1_BIT_GARO15_EN];
    wire garo31_en = ctl1[TRNG_CTL1_BIT_GARO31_EN];
    wire firo15_en = ctl1[TRNG_CTL1_BIT_FIRO15_EN];
    wire firo31_en = ctl1[TRNG_CTL1_BIT_FIRO31_EN];

    wire any_ro_en = ro11_en | ro15_en | garo15_en | garo31_en | firo15_en | firo31_en;

    // ---------------------------------------------------------------
    // Behavioral ring oscillator models (LFSRs)
    // Each produces one pseudo-random bit per clock.
    // ---------------------------------------------------------------

    // 11-bit maximal LFSR (polynomial x^11 + x^2 + 1)
    logic [10:0] ro11_q;
    wire         ro11_bit;
    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n)    ro11_q <= 11'b1;
        else if (ro11_en) ro11_q <= {ro11_q[9:0], ro11_q[10] ^ ro11_q[1]};
    assign ro11_bit = ro11_en ? ro11_q[0] : 1'b0;

    // 15-bit maximal LFSR (polynomial x^15 + x + 1)
    logic [14:0] ro15_q;
    wire         ro15_bit;
    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n)    ro15_q <= 15'b1;
        else if (ro15_en) ro15_q <= {ro15_q[13:0], ro15_q[14] ^ ro15_q[0]};
    assign ro15_bit = ro15_en ? ro15_q[0] : 1'b0;

    // GARO15 and GARO31: Galois ring oscillator — use the programmer-supplied polynomial
    // Modelled as a Galois LFSR with taps from garo_ctl[14:0] or [30:0]
    logic [14:0] garo15_q;
    wire         garo15_bit;
    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) garo15_q <= 15'b1;
        else if (garo15_en) begin
            logic feedback;
            feedback  = garo15_q[0];
            garo15_q <= (garo15_q >> 1) ^ (feedback ? garo_ctl[14:0] : 15'h0);
        end
    assign garo15_bit = garo15_en ? garo15_q[0] : 1'b0;

    logic [30:0] garo31_q;
    wire         garo31_bit;
    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) garo31_q <= 31'b1;
        else if (garo31_en) begin
            logic feedback;
            feedback  = garo31_q[0];
            garo31_q <= (garo31_q >> 1) ^ (feedback ? garo_ctl : 31'h0);
        end
    assign garo31_bit = garo31_en ? garo31_q[0] : 1'b0;

    // FIRO15 and FIRO31: Fibonacci ring oscillator — similar to Galois
    logic [14:0] firo15_q;
    wire         firo15_bit;
    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) firo15_q <= 15'h7FFF;
        else if (firo15_en) begin
            logic feedback;
            feedback  = ^(firo15_q & {1'b0, firo_ctl[13:0]}) ^ firo15_q[14];
            firo15_q <= {firo15_q[13:0], feedback};
        end
    assign firo15_bit = firo15_en ? firo15_q[0] : 1'b0;

    logic [30:0] firo31_q;
    wire         firo31_bit;
    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) firo31_q <= 31'h7FFF_FFFF;
        else if (firo31_en) begin
            logic feedback;
            feedback  = ^(firo31_q & {1'b0, firo_ctl[29:0]}) ^ firo31_q[30];
            firo31_q <= {firo31_q[29:0], feedback};
        end
    assign firo31_bit = firo31_en ? firo31_q[0] : 1'b0;

    // XOR all enabled sources → raw analog sample bit
    wire raw_bit = ro11_bit ^ ro15_bit ^ garo15_bit ^ garo31_bit ^ firo15_bit ^ firo31_bit;

    // ---------------------------------------------------------------
    // Von Neumann corrector (optional)
    // Processes bit pairs: 01→0, 10→1, 00/11→discard
    // Uses a 2-bit shift register for the pair.
    // ---------------------------------------------------------------
    logic        vn_prev_q;    // previous raw bit
    logic        vn_have_prev; // 1 = vn_prev_q is valid (waiting for second bit)
    logic        vn_out;       // de-biased output bit
    logic        vn_valid;     // 1 = vn_out is valid this cycle

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vn_prev_q    <= 1'b0;
            vn_have_prev <= 1'b0;
        end else if (any_ro_en) begin
            if (!vn_have_prev) begin
                vn_prev_q    <= raw_bit;
                vn_have_prev <= 1'b1;
            end else begin
                vn_have_prev <= 1'b0;
            end
        end
    end

    always_comb begin
        if (!von_neumann_en) begin
            vn_out   = raw_bit;
            vn_valid = any_ro_en;
        end else begin
            // Output only on the second bit of a pair, and only if they differ
            vn_out   = !vn_prev_q;          // 01→0 (prev=0), 10→1 (prev=1)
            vn_valid = any_ro_en && vn_have_prev && (raw_bit != vn_prev_q);
        end
    end

    // ---------------------------------------------------------------
    // Bitstream selector (TRNG_MON_CTL.BSEL)
    // ---------------------------------------------------------------
    trng_bsel_e bsel;
    assign bsel = trng_bsel_e'(mon_ctl[TRNG_MON_CTL_BSEL_HI:TRNG_MON_CTL_BSEL_LO]);

    logic mon_bit;
    logic mon_valid;
    always_comb begin
        case (bsel)
            BSEL_DAS: begin mon_bit = raw_bit; mon_valid = any_ro_en;    end // digitized analog
            BSEL_RED: begin mon_bit = raw_bit; mon_valid = any_ro_en;    end // reduction bits (same in model)
            default:  begin mon_bit = vn_out;  mon_valid = vn_valid;     end // BSEL_TR = true random
        endcase
    end

    // ---------------------------------------------------------------
    // RC (Repetition Count) health test
    // If the same bit repeats >= CUTOFF times, flag a failure.
    // mon_rc_ctl[7:0] = cutoff (default 8)
    // ---------------------------------------------------------------
    wire rc_en     = mon_ctl[TRNG_MON_CTL_BIT_RC];
    wire [7:0] rc_cutoff = mon_rc_ctl[7:0];

    logic        rc_last_bit_q;
    logic [7:0]  rc_run_q;      // length of current run
    logic        rc_fail_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rc_last_bit_q <= 1'b0;
            rc_run_q      <= 8'd1;
            rc_fail_q     <= 1'b0;
        end else if (rc_en && mon_valid) begin
            if (mon_bit == rc_last_bit_q) begin
                if (rc_run_q >= rc_cutoff)
                    rc_fail_q <= 1'b1;
                else
                    rc_run_q <= rc_run_q + 1;
            end else begin
                rc_last_bit_q <= mon_bit;
                rc_run_q      <= 8'd1;
                rc_fail_q     <= 1'b0;
            end
        end
    end

    assign rc_detect = rc_fail_q && rc_en;
    assign mon_rc_status0 = {24'b0, rc_run_q};
    assign mon_rc_status1 = {31'b0, rc_fail_q};

    // Stop TRNG if rc_fail and stop_on_rc set
    wire trng_stopped = (stop_on_rc && rc_detect) || (stop_on_ap && ap_detect);

    // ---------------------------------------------------------------
    // AP (Adaptive Proportion) health test
    // In a window of W bits, count 1s. If count > C_H or < C_L, fail.
    // mon_ap_ctl[15:0] = window size W, mon_ap_ctl[31:16] = C_H threshold
    // ---------------------------------------------------------------
    wire ap_en = mon_ctl[TRNG_MON_CTL_BIT_AP];
    wire [15:0] ap_window = mon_ap_ctl[15:0];
    wire [15:0] ap_cutoff = mon_ap_ctl[31:16];
    wire        ap_window_valid = (ap_window != 16'h0000);
    wire [15:0] ap_window_last  = ap_window - 16'd1;

    logic [15:0] ap_cnt_q;     // position within current window
    logic [15:0] ap_ones_q;    // count of 1s in current window
    logic        ap_fail_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ap_cnt_q  <= '0;
            ap_ones_q <= '0;
            ap_fail_q <= 1'b0;
        end else if (ap_en && mon_valid && ap_window_valid) begin
            if (ap_cnt_q == ap_window_last) begin
                // End of window: check
                if (ap_ones_q + {15'b0, mon_bit} > ap_cutoff)
                    ap_fail_q <= 1'b1;
                else
                    ap_fail_q <= 1'b0;
                ap_cnt_q  <= '0;
                ap_ones_q <= '0;
            end else begin
                ap_cnt_q  <= ap_cnt_q + 1;
                ap_ones_q <= ap_ones_q + {15'b0, mon_bit};
            end
        end
    end

    assign ap_detect = ap_fail_q && ap_en;
    assign mon_ap_status0 = {16'b0, ap_cnt_q};
    assign mon_ap_status1 = {16'b0, ap_ones_q};

    // ---------------------------------------------------------------
    // 32-bit result shift register
    // Accumulate bits from vn_out (post-corrector) or raw_bit into result.
    // ---------------------------------------------------------------
    logic [31:0] shift_q;
    logic [5:0]  bit_cnt_q;   // 0..31; result ready when 32 bits accumulated
    logic        data_valid_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_q      <= '0;
            bit_cnt_q    <= '0;
            data_valid_q <= 1'b0;
            initialized  <= 1'b0;
        end else begin
            if (result_read) begin
                data_valid_q <= 1'b0;
                bit_cnt_q    <= '0;
            end
            if (!data_valid_q && !trng_stopped && vn_valid) begin
                shift_q   <= {shift_q[30:0], vn_out};
                bit_cnt_q <= bit_cnt_q + 1;
                if (bit_cnt_q == 6'd31) begin
                    data_valid_q <= 1'b1;
                    initialized  <= 1'b1;
                end
            end
        end
    end

    assign data_valid = data_valid_q;
    assign result     = shift_q;
    assign status     = {31'b0, data_valid_q};  // bit[0] = INITIALIZED (data ready)

endmodule
