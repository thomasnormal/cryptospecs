// PSoC 6 Crypto — PRNG Engine (3-LFSR Pseudo-Random Number Generator)
//
// Three Fibonacci LFSRs running in parallel; their outputs are XOR'd to
// produce the 32-bit pseudo-random result.  The LFSRs are seeded from the
// corresponding AHB registers and advance every clock when the crypto block
// is enabled.  The engine is purely combinational/registered — no instruction
// trigger is needed; pr_result is always valid.
//
// LFSR polynomials (from Registers TRM §3.1.12-14):
//   LFSR0: 32-bit, x^32 + x^30 + x^26 + x^25 + 1
//   LFSR1: 31-bit, x^31 + x^28 + 1
//   LFSR2: 29-bit, x^29 + x^27 + 1
//
// Each LFSR uses the Galois (right-shift) form with the corresponding mask.
// The internal state is initialised from the seed registers at reset; software
// can reseed by writing new values to the seed registers — the engine captures
// them via the comb compare (seed_changed detection not implemented here;
// integration notes below).
//
// Integration note: this module owns its own state registers.  The AHB slave
// provides seed values (reg_pr_lfsr0/1/2); software writes to these to reseed.
// The PRNG captures the seed once at reset and then free-runs.  If live
// reseeding is required, connect a pulse on pr_reseed from the AHB write path.

`include "crypto_pkg.sv"

module prng_engine
    import crypto_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        enabled,      // CRYPTO_CTL.ENABLED

    // Seed inputs (from AHB slave registers)
    input  logic [31:0] seed0,        // PR_LFSR_CTL0 initial value
    input  logic [30:0] seed1,        // PR_LFSR_CTL1 [30:0]
    input  logic [28:0] seed2,        // PR_LFSR_CTL2 [28:0]
    input  logic        pr_reseed,    // one-cycle pulse: reload from seeds

    // Output
    output logic [31:0] pr_result
);

    // Galois LFSR masks for right-shift form:
    // LFSR0: x^32+x^30+x^26+x^25+1 → coefficients at x^0..x^31 (excl. x^32):
    //   x^30: bit30, x^26: bit26, x^25: bit25, x^0: bit0
    //   mask = 0x46000001
    // LFSR1: x^31+x^28+1 → mask (30-bit range for right-shift on 31-bit LFSR):
    //   x^28: bit27 in 30..0 index, x^0: bit0 → mask = 0x08000001 (31-bit, but bit27)
    // LFSR2: x^29+x^27+1 → mask for 29-bit right-shift:
    //   x^27: bit26, x^0: bit0 → mask = 0x04000001 (but 29-bit)

    // Galois right-shift: next_lfsr = {1'b0, lfsr[n-1:1]} ^ (lfsr[0] ? mask : 0)

    function automatic logic [31:0] lfsr0_step(input logic [31:0] s);
        return {1'b0, s[31:1]} ^ (s[0] ? 32'h46000001 : 32'h0);
    endfunction

    function automatic logic [30:0] lfsr1_step(input logic [30:0] s);
        return {1'b0, s[30:1]} ^ (s[0] ? 31'h08000001 : 31'h0);
    endfunction

    function automatic logic [28:0] lfsr2_step(input logic [28:0] s);
        return {1'b0, s[28:1]} ^ (s[0] ? 29'h04000001 : 29'h0);
    endfunction

    logic [31:0] state0_q;
    logic [30:0] state1_q;
    logic [28:0] state2_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state0_q <= PR_LFSR0_DEFAULT;
            state1_q <= PR_LFSR1_DEFAULT;
            state2_q <= PR_LFSR2_DEFAULT;
        end else if (pr_reseed) begin
            state0_q <= seed0;
            state1_q <= seed1;
            state2_q <= seed2;
        end else if (enabled) begin
            state0_q <= lfsr0_step(state0_q);
            state1_q <= lfsr1_step(state1_q);
            state2_q <= lfsr2_step(state2_q);
        end
    end

    assign pr_result = state0_q ^ {1'b0, state1_q} ^ {3'b0, state2_q};

endmodule
