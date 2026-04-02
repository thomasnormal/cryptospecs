// PSoC 6 Crypto — GHASH Accumulator
//
// Implements GCM GHASH per NIST SP 800-38D §6.4:
//   Y_0 = 0^128
//   Y_i = (Y_{i-1} XOR X_i) * H    for i = 1 .. m
//
// Configuration (via AHB registers written before starting):
//   ghash_h[127:0]     — hash subkey H (= E_K(0^128), loaded from block6)
//   ghash_y[127:0]     — running Y state (input from block7, output back to block7)
//
// The PSoC 6 implements GHASH iteratively using the OPC_GHASH instruction which
// feeds one 128-bit block at a time from the register buffer.  This module:
//   - takes one data block on ghash_start (from block5)
//   - XORs with current Y, calls gf_mult_128, updates Y
//
// Operand mapping (fixed by ISA):
//   X block:  block5[127:0]  — current message / ciphertext block
//   H:        block6[127:0]  — hash subkey (constant per key)
//   Y_in/out: block7[127:0]  — accumulated tag (zero-initialised before first call)
//
// Latency: 1 (setup) + 128 (GF multiply) + 1 (writeback) = 130 cycles

`include "crypto_pkg.sv"

module ghash
    import crypto_pkg::*;
(
    input  logic          clk,
    input  logic          rst_n,

    input  logic          ghash_start,
    output logic          ghash_busy,

    // Full register-buffer read
    input  logic [2047:0] sha_rb_rd,

    // Engine write-back
    output logic [3:0]    eng_wr_addr,
    output logic [127:0]  eng_wr_data,
    output logic          eng_wr_en
);

    // GF multiplier instantiation
    logic          gfm_start, gfm_done, gfm_busy;
    logic [127:0]  gfm_a, gfm_b, gfm_result;

    gf_mult_128 u_gfm (
        .clk        (clk),
        .rst_n      (rst_n),
        .gfm_start  (gfm_start),
        .gfm_a      (gfm_a),
        .gfm_b      (gfm_b),
        .gfm_result (gfm_result),
        .gfm_done   (gfm_done),
        .gfm_busy   (gfm_busy)
    );

    typedef enum logic [1:0] {
        ST_IDLE = 2'd0,
        ST_MULT = 2'd1,
        ST_WB   = 2'd2
    } state_t;

    state_t state_q;

    // Latch operands on start
    logic [127:0] xor_xy_q;  // X XOR Y (input to GF mult)
    logic [127:0] h_q;        // hash subkey H

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q    <= ST_IDLE;
            ghash_busy <= 1'b0;
            eng_wr_en  <= 1'b0;
            gfm_start  <= 1'b0;
            xor_xy_q   <= '0;
            h_q        <= '0;
        end else begin
            eng_wr_en <= 1'b0;
            gfm_start <= 1'b0;

            unique case (state_q)

                ST_IDLE: begin
                    if (ghash_start) begin
                        // X = block5, H = block6, Y = block7
                        xor_xy_q   <= sha_rb_rd[767:640] ^ sha_rb_rd[1023:896];
                        h_q        <= sha_rb_rd[895:768];
                        ghash_busy <= 1'b1;
                        gfm_start  <= 1'b1;
                        state_q    <= ST_MULT;
                    end
                end

                ST_MULT: begin
                    if (gfm_done) begin
                        state_q <= ST_WB;
                    end
                end

                ST_WB: begin
                    eng_wr_addr <= 4'd7;      // write result back to block7
                    eng_wr_data <= gfm_result;
                    eng_wr_en   <= 1'b1;
                    ghash_busy  <= 1'b0;
                    state_q     <= ST_IDLE;
                end

                default: state_q <= ST_IDLE;

            endcase
        end
    end

    assign gfm_a = xor_xy_q;
    assign gfm_b = h_q;

endmodule
