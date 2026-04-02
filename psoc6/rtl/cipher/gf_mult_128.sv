// PSoC 6 Crypto — GF(2^128) Multiplier
//
// Implements multiplication in GF(2^128) per NIST SP 800-38D §6.3 (GCM).
// Irreducible polynomial: x^128 + x^7 + x^2 + x + 1
// Bit ordering: [127] = coefficient of x^0 (MSB = "first" bit in NIST notation)
//
// Algorithm (128-cycle iterative):
//   Z = 0, V = B
//   For i = 0..127 (processing A MSB-first):
//     if A[127-i]: Z ^= V
//     if V[0]: V = (V << 1) ^ R     (V[0] is the "rightmost" bit = coeff x^127)
//     else:    V = V << 1
//   where R = 0xE100_0000_..._0000 (x^127+x^126+x^121 reduction terms)
//   Note: "<<" here is GCM left-shift = SV right-shift (drops MSB, appends 0 at bit 0)

`include "crypto_pkg.sv"

module gf_mult_128
    import crypto_pkg::*;
(
    input  logic          clk,
    input  logic          rst_n,

    input  logic          gfm_start,
    input  logic [127:0]  gfm_a,
    input  logic [127:0]  gfm_b,

    output logic [127:0]  gfm_result,
    output logic          gfm_done,
    output logic          gfm_busy
);

    // R = 0xE100...00: bits 127,126,121 set
    localparam logic [127:0] R_POLY =
        {8'hE1, 120'h0};

    logic [127:0] z_q, v_q, x_q;
    logic [6:0]   cnt_q;

    // Combinational next-state for each iteration
    logic [127:0] z_next, v_next;
    always_comb begin
        z_next = x_q[127] ? (z_q ^ v_q) : z_q;
        // GCM left-shift of V: drop MSB (bit 127), append 0 at bit 0
        v_next = v_q[0] ? ({v_q[126:0], 1'b0} ^ R_POLY)
                        :  {v_q[126:0], 1'b0};
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            z_q        <= '0;
            v_q        <= '0;
            x_q        <= '0;
            cnt_q      <= '0;
            gfm_busy   <= 1'b0;
            gfm_done   <= 1'b0;
            gfm_result <= '0;
        end else begin
            gfm_done <= 1'b0;

            if (gfm_start) begin
                z_q      <= '0;
                v_q      <= gfm_b;
                x_q      <= gfm_a;
                cnt_q    <= 7'd128;
                gfm_busy <= 1'b1;
            end else if (gfm_busy) begin
                z_q   <= z_next;
                v_q   <= v_next;
                x_q   <= {x_q[126:0], 1'b0};   // consume MSB of A
                cnt_q <= cnt_q - 7'd1;
                if (cnt_q == 7'd1) begin
                    gfm_result <= z_next;   // z_next is result of last iteration
                    gfm_done   <= 1'b1;
                    gfm_busy   <= 1'b0;
                end
            end
        end
    end

endmodule
