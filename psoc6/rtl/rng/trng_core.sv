// PSoC 6 Crypto — TRNG Core
//
// Synthesizable approximation of the PSoC 6 True Random Number Generator.
// Real ring oscillators are not synthesizable; this model uses free-running
// counters XOR'd with LFSR feedback to approximate entropy sources.
//
// Six oscillator types can be enabled via TR_CTL1 bits:
//   [5] FIRO31, [4] FIRO15, [3] GARO31, [2] GARO15, [1] RO15, [0] RO11
//
// Output pipeline:
//   1. Each enabled oscillator contributes 1 bit per sample cycle
//   2. Von-Neumann de-biaser removes bias from sequential bit pairs
//   3. 32 de-biased bits are packed into tr_result
//
// TR_CTL0 fields used:
//   [31:24] SAMPLE_CLOCK_DIV — sample clock divider (not modelled, runs at clk/1)
//   [16]    DATA_SEL         — 0=use ring-osc bits, 1=use counter bits (debug)
//   [0]     STOP_ON_AP_DETECT, [1] STOP_ON_RC_DETECT — not modelled here
//
// Health monitors (RC and AP tests) are implemented in trng_health_mon.sv.

`include "crypto_pkg.sv"
`include "crypto_isa_pkg.sv"

module trng_core
    import crypto_pkg::*;
    import crypto_isa_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    // Configuration
    input  logic [31:0] reg_tr_ctl0,       // TR_CTL0
    input  logic [31:0] reg_tr_ctl1,       // TR_CTL1: oscillator enables
    input  logic [30:0] reg_tr_garo_ctl,   // GARO31 polynomial
    input  logic [30:0] reg_tr_firo_ctl,   // FIRO31 polynomial

    // Result
    output logic [31:0] tr_result,
    output logic        tr_result_valid,   // pulses when a new 32-bit word is ready

    // Bitstream output to health monitors
    output logic        tr_bit,            // raw bitstream output
    output logic        tr_bit_valid       // one-cycle valid pulse per bit
);

    // ---------------------------------------------------------------
    // Six synthesizable "ring oscillator" models (free-running counters)
    // In real silicon these are ring oscillators with thermal noise; here
    // they are simple counters XOR'd with each other for entropy approximation.
    // ---------------------------------------------------------------
    logic [10:0] ro11_q;   // RO11 (11-stage ring)
    logic [14:0] ro15_q;   // RO15
    logic [14:0] garo15_q; // GARO15 (Galois ring-oscillator)
    logic [30:0] garo31_q; // GARO31 with programmable polynomial
    logic [14:0] firo15_q; // Fibonacci RO15
    logic [30:0] firo31_q; // Fibonacci RO31 with programmable polynomial

    logic [5:0]  osc_en;   // enables from TR_CTL1[5:0]
    assign osc_en = reg_tr_ctl1[5:0];

    // Each "oscillator" is a free-running LFSR counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ro11_q   <= 11'h001;
            ro15_q   <= 15'h0001;
            garo15_q <= 15'h0001;
            garo31_q <= 31'h0000001;
            firo15_q <= 15'h0001;
            firo31_q <= 31'h0000001;
        end else begin
            // RO11: polynomial x^11+x^9+1
            ro11_q   <= {ro11_q[9:0], ro11_q[10] ^ ro11_q[8]};
            // RO15: polynomial x^15+x^14+1
            ro15_q   <= {ro15_q[13:0], ro15_q[14] ^ ro15_q[13]};
            // GARO15: Galois form, fixed polynomial
            garo15_q <= {1'b0, garo15_q[14:1]} ^ (garo15_q[0] ? 15'h6000 : 15'h0);
            // GARO31: Galois form, programmable polynomial from reg_tr_garo_ctl
            garo31_q <= {1'b0, garo31_q[30:1]} ^
                        (garo31_q[0] ? reg_tr_garo_ctl : 31'h0);
            // FIRO15: Fibonacci polynomial x^15+x^14+1
            firo15_q <= {firo15_q[13:0], firo15_q[14] ^ firo15_q[13]};
            // FIRO31: Fibonacci, programmable (use garo polynomial for FIRO too)
            firo31_q <= {firo31_q[29:0], ^(firo31_q & {reg_tr_firo_ctl, 1'b0})};
        end
    end

    // Combine enabled oscillators into a single raw bit (majority or XOR)
    logic [5:0] osc_bits;
    assign osc_bits = {firo31_q[0],  firo15_q[0],
                       garo31_q[0],  garo15_q[0],
                       ro15_q[0],    ro11_q[0]};

    logic raw_bit;
    always_comb begin
        raw_bit = 1'b0;
        for (int i = 0; i < 6; i++)
            if (osc_en[i]) raw_bit ^= osc_bits[i];
    end

    // ---------------------------------------------------------------
    // Von-Neumann de-biaser:
    //   Sample pairs of bits; if pair is 01 → output 1;
    //   if pair is 10 → output 0; if pair is 00 or 11 → discard.
    // ---------------------------------------------------------------
    logic        vn_phase_q;   // 0 = first of pair, 1 = second
    logic        vn_bit0_q;    // stored first bit
    logic        vn_out;
    logic        vn_valid;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vn_phase_q <= 1'b0;
            vn_bit0_q  <= 1'b0;
        end else begin
            vn_phase_q <= ~vn_phase_q;
            if (!vn_phase_q)
                vn_bit0_q <= raw_bit;
        end
    end

    assign vn_out   = raw_bit;  // second bit of the pair = output
    assign vn_valid = vn_phase_q && (raw_bit != vn_bit0_q);  // discard equal pairs

    // ---------------------------------------------------------------
    // Bitstream output to health monitor
    // ---------------------------------------------------------------
    assign tr_bit       = vn_out;
    assign tr_bit_valid = vn_valid;

    // ---------------------------------------------------------------
    // Pack 32 de-biased bits into tr_result
    // ---------------------------------------------------------------
    logic [5:0]  bit_cnt_q;
    logic [31:0] shift_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_cnt_q   <= '0;
            shift_q     <= '0;
            tr_result   <= '0;
            tr_result_valid <= 1'b0;
        end else begin
            tr_result_valid <= 1'b0;
            if (vn_valid) begin
                shift_q   <= {shift_q[30:0], vn_out};
                bit_cnt_q <= bit_cnt_q + 1;
                if (bit_cnt_q == 6'd31) begin
                    tr_result       <= {shift_q[30:0], vn_out};
                    tr_result_valid <= 1'b1;
                    bit_cnt_q       <= '0;
                end
            end
        end
    end

endmodule
