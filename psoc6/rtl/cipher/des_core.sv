// PSoC 6 Crypto — DES / Triple-DES Core
//
// Implements FIPS 46-3 DES and NIST SP 800-67 TDES (3-key EDE).
//
// Operand mapping (fixed by ISA):
//   src:  block0[63:0]   — 64-bit plaintext  / ciphertext
//   key1: block4[63:0]   — DES key or TDES key1
//   key2: block4[127:64] — TDES key2
//   key3: block5[63:0]   — TDES key3
//   dst:  block1[63:0]   — 64-bit result (upper 64 bits zeroed)
//
// des_mode[1:0]:
//   2'b00 OPC_DES      — DES encrypt
//   2'b01 OPC_DES_INV  — DES decrypt
//   2'b10 OPC_TDES     — TDES encrypt (EDE: E(K1), D(K2), E(K3))
//   2'b11 OPC_TDES_INV — TDES decrypt (DED: D(K3), E(K2), D(K1))
//
// Latency:
//   DES:  1 (key schedule) + 16 (rounds) + 1 (writeback) = 18 cycles
//   TDES: 3 × 16 + 3 (key schedule) + 1 (writeback) = 52 cycles

`include "crypto_pkg.sv"
`include "crypto_isa_pkg.sv"

module des_core
    import crypto_pkg::*;
    import crypto_isa_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    input  logic [3:0]  des_mode,   // {2'b0, tdes, decrypt}
    input  logic        des_start,
    output logic        des_busy,

    // Full register-buffer read (SHA bus reused for DES)
    input  logic [2047:0] sha_rb_rd,

    // Engine write-back
    output logic [3:0]   eng_wr_addr,
    output logic [127:0] eng_wr_data,
    output logic         eng_wr_en
);

    // ------------------------------------------------------------------
    // DES table constants (1-indexed values, all arrays 0-indexed)
    // Conventions: input bit position p (1=MSB) maps to signal[64-p]
    // ------------------------------------------------------------------

    localparam int IP [0:63] = '{
        58,50,42,34,26,18,10, 2,  60,52,44,36,28,20,12, 4,
        62,54,46,38,30,22,14, 6,  64,56,48,40,32,24,16, 8,
        57,49,41,33,25,17, 9, 1,  59,51,43,35,27,19,11, 3,
        61,53,45,37,29,21,13, 5,  63,55,47,39,31,23,15, 7
    };

    localparam int FP [0:63] = '{
        40, 8,48,16,56,24,64,32,  39, 7,47,15,55,23,63,31,
        38, 6,46,14,54,22,62,30,  37, 5,45,13,53,21,61,29,
        36, 4,44,12,52,20,60,28,  35, 3,43,11,51,19,59,27,
        34, 2,42,10,50,18,58,26,  33, 1,41, 9,49,17,57,25
    };

    localparam int PC1_C [0:27] = '{
        57,49,41,33,25,17, 9, 1,
        58,50,42,34,26,18,10, 2,
        59,51,43,35,27,19,11, 3,
        60,52,44,36
    };

    localparam int PC1_D [0:27] = '{
        63,55,47,39,31,23,15, 7,
        62,54,46,38,30,22,14, 6,
        61,53,45,37,29,21,13, 5,
        28,20,12, 4
    };

    // PC-2: 56-bit CD (C=bits55..28, D=bits27..0) → 48-bit subkey
    localparam int PC2 [0:47] = '{
        14,17,11,24, 1, 5,  3,28,15, 6,21,10,
        23,19,12, 4,26, 8, 16, 7,27,20,13, 2,
        41,52,31,37,47,55, 30,40,51,45,33,48,
        44,49,39,56,34,53, 46,42,50,36,29,32
    };

    localparam int E_EXP [0:47] = '{
        32, 1, 2, 3, 4, 5,  4, 5, 6, 7, 8, 9,
         8, 9,10,11,12,13, 12,13,14,15,16,17,
        16,17,18,19,20,21, 20,21,22,23,24,25,
        24,25,26,27,28,29, 28,29,30,31,32, 1
    };

    localparam int P_PERM [0:31] = '{
        16, 7,20,21, 29,12,28,17,  1,15,23,26,  5,18,31,10,
         2, 8,24,14, 32,27, 3, 9, 19,13,30, 6, 22,11, 4,25
    };

    localparam int LS [0:15] = '{1,1,2,2,2,2,2,2,1,2,2,2,2,2,2,1};

    localparam logic [3:0] SBOX [0:7][0:63] = '{
        '{4'hE,4'h4,4'hD,4'h1,4'h2,4'hF,4'hB,4'h8,4'h3,4'hA,4'h6,4'hC,4'h5,4'h9,4'h0,4'h7,
          4'h0,4'hF,4'h7,4'h4,4'hE,4'h2,4'hD,4'h1,4'hA,4'h6,4'hC,4'hB,4'h9,4'h5,4'h3,4'h8,
          4'h4,4'h1,4'hE,4'h8,4'hD,4'h6,4'h2,4'hB,4'hF,4'hC,4'h9,4'h7,4'h3,4'hA,4'h5,4'h0,
          4'hF,4'hC,4'h8,4'h2,4'h4,4'h9,4'h1,4'h7,4'h5,4'hB,4'h3,4'hE,4'hA,4'h0,4'h6,4'hD},
        '{4'hF,4'h1,4'h8,4'hE,4'h6,4'hB,4'h3,4'h4,4'h9,4'h7,4'h2,4'hD,4'hC,4'h0,4'h5,4'hA,
          4'h3,4'hD,4'h4,4'h7,4'hF,4'h2,4'h8,4'hE,4'hC,4'h0,4'h1,4'hA,4'h6,4'h9,4'hB,4'h5,
          4'h0,4'hE,4'h7,4'hB,4'hA,4'h4,4'hD,4'h1,4'h5,4'h8,4'hC,4'h6,4'h9,4'h3,4'h2,4'hF,
          4'hD,4'h8,4'hA,4'h1,4'h3,4'hF,4'h4,4'h2,4'hB,4'h6,4'h7,4'hC,4'h0,4'h5,4'hE,4'h9},
        '{4'hA,4'h0,4'h9,4'hE,4'h6,4'h3,4'hF,4'h5,4'h1,4'hD,4'hC,4'h7,4'hB,4'h4,4'h2,4'h8,
          4'hD,4'h7,4'h0,4'h9,4'h3,4'h4,4'h6,4'hA,4'h2,4'h8,4'h5,4'hE,4'hC,4'hB,4'hF,4'h1,
          4'hD,4'h6,4'h4,4'h9,4'h8,4'hF,4'h3,4'h0,4'hB,4'h1,4'h2,4'hC,4'h5,4'hA,4'hE,4'h7,
          4'h1,4'hA,4'hD,4'h0,4'h6,4'h9,4'h8,4'h7,4'h4,4'hF,4'hE,4'h3,4'hB,4'h5,4'h2,4'hC},
        '{4'h7,4'hD,4'hE,4'h3,4'h0,4'h6,4'h9,4'hA,4'h1,4'h2,4'h8,4'h5,4'hB,4'hC,4'h4,4'hF,
          4'hD,4'h8,4'hB,4'h5,4'h6,4'hF,4'h0,4'h3,4'h4,4'h7,4'h2,4'hC,4'h1,4'hA,4'hE,4'h9,
          4'hA,4'h6,4'h9,4'h0,4'hC,4'hB,4'h7,4'hD,4'hF,4'h1,4'h3,4'hE,4'h5,4'h2,4'h8,4'h4,
          4'h3,4'hF,4'h0,4'h6,4'hA,4'h1,4'hD,4'h8,4'h9,4'h4,4'h5,4'hB,4'hC,4'h7,4'h2,4'hE},
        '{4'h2,4'hC,4'h4,4'h1,4'h7,4'hA,4'hB,4'h6,4'h8,4'h5,4'h3,4'hF,4'hD,4'h0,4'hE,4'h9,
          4'hE,4'hB,4'h2,4'hC,4'h4,4'h7,4'hD,4'h1,4'h5,4'h0,4'hF,4'hA,4'h3,4'h9,4'h8,4'h6,
          4'h4,4'h2,4'h1,4'hB,4'hA,4'hD,4'h7,4'h8,4'hF,4'h9,4'hC,4'h5,4'h6,4'h3,4'h0,4'hE,
          4'hB,4'h8,4'hC,4'h7,4'h1,4'hE,4'h2,4'hD,4'h6,4'hF,4'h0,4'h9,4'hA,4'h4,4'h5,4'h3},
        '{4'hC,4'h1,4'hA,4'hF,4'h9,4'h2,4'h6,4'h8,4'h0,4'hD,4'h3,4'h4,4'hE,4'h7,4'h5,4'hB,
          4'hA,4'hF,4'h4,4'h2,4'h7,4'hC,4'h9,4'h5,4'h6,4'h1,4'hD,4'hE,4'h0,4'hB,4'h3,4'h8,
          4'h9,4'hE,4'hF,4'h5,4'h2,4'h8,4'hC,4'h3,4'h7,4'h0,4'h4,4'hA,4'h1,4'hD,4'hB,4'h6,
          4'h4,4'h3,4'h2,4'hC,4'h9,4'h5,4'hF,4'hA,4'hB,4'hE,4'h1,4'h7,4'h6,4'h0,4'h8,4'hD},
        '{4'h4,4'hB,4'h2,4'hE,4'hF,4'h0,4'h8,4'hD,4'h3,4'hC,4'h9,4'h7,4'h5,4'hA,4'h6,4'h1,
          4'hD,4'h0,4'hB,4'h7,4'h4,4'h9,4'h1,4'hA,4'hE,4'h3,4'h5,4'hC,4'h2,4'hF,4'h8,4'h6,
          4'h1,4'h4,4'hB,4'hD,4'hC,4'h3,4'h7,4'hE,4'hA,4'hF,4'h6,4'h8,4'h0,4'h5,4'h9,4'h2,
          4'h6,4'hB,4'hD,4'h8,4'h1,4'h4,4'hA,4'h7,4'h9,4'h5,4'h0,4'hF,4'hE,4'h2,4'h3,4'hC},
        '{4'hD,4'h2,4'h8,4'h4,4'h6,4'hF,4'hB,4'h1,4'hA,4'h9,4'h3,4'hE,4'h5,4'h0,4'hC,4'h7,
          4'h1,4'hF,4'hD,4'h8,4'hA,4'h3,4'h7,4'h4,4'hC,4'h5,4'h6,4'hB,4'h0,4'hE,4'h9,4'h2,
          4'h7,4'hB,4'h4,4'h1,4'h9,4'hC,4'hE,4'h2,4'h0,4'h6,4'hA,4'hD,4'hF,4'h3,4'h5,4'h8,
          4'h2,4'h1,4'hE,4'h7,4'h4,4'hA,4'h8,4'hD,4'hF,4'hC,4'h9,4'h0,4'h3,4'h5,4'h6,4'hB}
    };

    // ------------------------------------------------------------------
    // Pure combinational DES building blocks
    // ------------------------------------------------------------------

    function automatic logic [63:0] perm64(
        input logic [63:0] x, input int tab [0:63]
    );
        logic [63:0] r;
        for (int i = 0; i < 64; i++) r[63-i] = x[64 - tab[i]];
        return r;
    endfunction

    function automatic logic [55:0] pc1_fn(input logic [63:0] key);
        logic [27:0] C, D;
        for (int i = 0; i < 28; i++) C[27-i] = key[64 - PC1_C[i]];
        for (int i = 0; i < 28; i++) D[27-i] = key[64 - PC1_D[i]];
        return {C, D};
    endfunction

    function automatic logic [27:0] rotl28(input logic [27:0] x, input int n);
        return (x << n) | (x >> (28 - n));
    endfunction

    function automatic logic [47:0] pc2_fn(input logic [55:0] CD);
        logic [47:0] k;
        for (int i = 0; i < 48; i++) k[47-i] = CD[56 - PC2[i]];
        return k;
    endfunction

    // Compute subkey for round r (0-indexed) from a 64-bit raw key
    function automatic logic [47:0] keysched_r(
        input logic [63:0] key64, input int r
    );
        logic [27:0] C, D;
        logic [55:0] CD;
        CD = pc1_fn(key64);
        C  = CD[55:28]; D = CD[27:0];
        for (int i = 0; i <= r; i++) begin
            C = rotl28(C, LS[i]);
            D = rotl28(D, LS[i]);
        end
        return pc2_fn({C, D});
    endfunction

    function automatic logic [47:0] expand_E_fn(input logic [31:0] R);
        logic [47:0] e;
        for (int i = 0; i < 48; i++) e[47-i] = R[32 - E_EXP[i]];
        return e;
    endfunction

    function automatic logic [31:0] perm_P_fn(input logic [31:0] x);
        logic [31:0] r;
        for (int i = 0; i < 32; i++) r[31-i] = x[32 - P_PERM[i]];
        return r;
    endfunction

    function automatic logic [31:0] feistel_f(
        input logic [31:0] R, input logic [47:0] K
    );
        logic [47:0] ER;
        logic [31:0] sout;
        logic [5:0]  s6;
        logic [1:0]  row;
        logic [3:0]  col;
        ER = expand_E_fn(R) ^ K;
        sout = '0;
        for (int b = 0; b < 8; b++) begin
            s6  = ER[47 - b*6 -: 6];
            row = {s6[5], s6[0]};
            col = s6[4:1];
            sout[31 - b*4 -: 4] = SBOX[b][{row, col}];
        end
        return perm_P_fn(sout);
    endfunction

    function automatic logic [63:0] des_round_fn(
        input logic [63:0] LR, input logic [47:0] K
    );
        logic [31:0] L, R;
        L = LR[63:32]; R = LR[31:0];
        return {R, L ^ feistel_f(R, K)};
    endfunction

    // Return 64-bit key for the given phase
    function automatic logic [63:0] key_for_phase(
        input logic [2047:0] rb,
        input logic [3:0]    mode,
        input logic [1:0]    phase
    );
        logic [63:0] k1, k2, k3;
        logic [1:0]  kidx;
        k1 = rb[575:512];   // block4[63:0]
        k2 = rb[639:576];   // block4[127:64]
        k3 = rb[703:640];   // block5[63:0]
        if (!mode[1]) return k1;
        kidx = mode[0] ? (2'd2 - phase) : phase;
        unique case (kidx)
            2'd0: return k1;
            2'd1: return k2;
            2'd2: return k3;
            default: return k1;
        endcase
    endfunction

    // ------------------------------------------------------------------
    // FSM
    // ------------------------------------------------------------------
    typedef enum logic [1:0] {
        ST_IDLE  = 2'd0,
        ST_ROUND = 2'd1,
        ST_WB    = 2'd2
    } state_t;

    state_t      state_q;
    logic [3:0]  rnd_q;
    logic [1:0]  phase_q;
    logic [63:0] lr_q;
    logic [47:0] sk_q [0:15];
    logic [3:0]  mode_q;

    // Current subkey index (decrypt: reverse order)
    logic dec_phase;
    assign dec_phase = mode_q[1] ? (mode_q[0] ^ phase_q[0]) : mode_q[0];

    always_ff @(posedge clk or negedge rst_n) begin : p_des_fsm
        integer j;
        if (!rst_n) begin
            state_q   <= ST_IDLE;
            des_busy  <= 1'b0;
            eng_wr_en <= 1'b0;
            rnd_q     <= '0;
            phase_q   <= '0;
            lr_q      <= '0;
            mode_q    <= '0;
        end else begin
            eng_wr_en <= 1'b0;

            unique case (state_q)

                ST_IDLE: begin
                    if (des_start) begin
                        des_busy  <= 1'b1;
                        mode_q    <= des_mode;
                        phase_q   <= 2'd0;
                        rnd_q     <= 4'd0;
                        for (j = 0; j < 16; j++)
                            sk_q[j] <= keysched_r(
                                key_for_phase(sha_rb_rd, des_mode, 2'd0), j);
                        lr_q <= perm64(sha_rb_rd[63:0], IP);
                        state_q  <= ST_ROUND;
                    end
                end

                ST_ROUND: begin
                    begin : rnd_blk
                        logic [3:0] sk_idx;
                        sk_idx = dec_phase ? (4'd15 - rnd_q) : rnd_q;
                        lr_q <= des_round_fn(lr_q, sk_q[sk_idx]);
                    end
                    if (rnd_q == 4'd15) begin
                        if (mode_q[1] && (phase_q < 2'd2)) begin
                            phase_q <= phase_q + 2'd1;
                            rnd_q   <= 4'd0;
                            for (j = 0; j < 16; j++)
                                sk_q[j] <= keysched_r(
                                    key_for_phase(sha_rb_rd, mode_q,
                                                  phase_q + 2'd1), j);
                        end else begin
                            state_q <= ST_WB;
                        end
                    end else begin
                        rnd_q <= rnd_q + 4'd1;
                    end
                end

                ST_WB: begin
                    // Pre-output swap R||L then apply FP
                    eng_wr_addr <= 4'd1;
                    eng_wr_data <= {64'h0,
                                    perm64({lr_q[31:0], lr_q[63:32]}, FP)};
                    eng_wr_en   <= 1'b1;
                    des_busy    <= 1'b0;
                    state_q     <= ST_IDLE;
                end

                default: state_q <= ST_IDLE;

            endcase
        end
    end

endmodule
