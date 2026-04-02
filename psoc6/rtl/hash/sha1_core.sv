// PSoC 6 Crypto — SHA-1 Core (FIPS 180-4)
//
// Register buffer layout (little-endian AHB, big-endian SHA words):
//   Message (64 B) : sha_rb_rd[511:0]    — BLOCK0-3
//   State   (20 B) : sha_rb_rd[1279:1024] — BLOCK8 (H[0..3]) + BLOCK9[31:0] (H[4])
//
// Write-back: BLOCK8 ← H[0..3], BLOCK9 ← {96'h0, bswap32(H[4])}  (2 eng_wr cycles)
// Latency: 1 (LOAD) + 80 (COMPRESS) + 1 (FINALIZE) + 2 (WRITEBACK) = 84 cycles

`include "crypto_pkg.sv"
`include "crypto_isa_pkg.sv"

module sha1_core
    import crypto_pkg::*;
    import crypto_isa_pkg::*;
(
    input  logic          clk,
    input  logic          rst_n,
    input  logic          start,
    output logic          busy,
    input  logic [2047:0] sha_rb_rd,
    output logic [3:0]    eng_wr_addr,
    output logic [127:0]  eng_wr_data,
    output logic          eng_wr_en
);

    function automatic logic [31:0] bswap32(input logic [31:0] x);
        return {x[7:0], x[15:8], x[23:16], x[31:24]};
    endfunction
    function automatic logic [31:0] rotl32(input logic [31:0] x, input int unsigned n);
        return (x << n) | (x >> (32 - n));
    endfunction
    function automatic logic [31:0] ft(input logic [31:0] b, c, d, input logic [6:0] t);
        if      (t < 20) return (b & c) | (~b & d);
        else if (t < 40) return b ^ c ^ d;
        else if (t < 60) return (b & c) | (b & d) | (c & d);
        else             return b ^ c ^ d;
    endfunction
    function automatic logic [31:0] Kt(input logic [6:0] t);
        if      (t < 20) return 32'h5A827999;
        else if (t < 40) return 32'h6ED9EBA1;
        else if (t < 60) return 32'h8F1BBCDC;
        else             return 32'hCA62C1D6;
    endfunction

    typedef enum logic [2:0] { ST_IDLE, ST_COMPRESS, ST_FINALIZE, ST_WB0, ST_WB1 } state_e;
    state_e state_q;

    logic [31:0] H_q [0:4];
    logic [31:0] a_q, b_q, c_q, d_q, e_q;
    logic [31:0] W_q [0:15];
    logic [6:0]  rnd_q;  // 0-79

    assign busy = (state_q != ST_IDLE);

    // Message schedule word for current round
    logic [31:0] Wt;
    always_comb begin
        if (rnd_q < 7'd16)
            Wt = W_q[rnd_q];
        else
            Wt = rotl32(W_q[(rnd_q+13)%16] ^ W_q[(rnd_q+8)%16]
                      ^ W_q[(rnd_q+ 2)%16] ^ W_q[rnd_q%16], 1);
    end

    assign eng_wr_en   = (state_q == ST_WB0) || (state_q == ST_WB1);
    assign eng_wr_addr = (state_q == ST_WB0) ? 4'd8 : 4'd9;
    always_comb begin
        if (state_q == ST_WB0)
            eng_wr_data = {bswap32(H_q[3]), bswap32(H_q[2]),
                           bswap32(H_q[1]), bswap32(H_q[0])};
        else
            eng_wr_data = {96'h0, bswap32(H_q[4])};
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= ST_IDLE;
            rnd_q   <= '0;
            for (int i = 0; i < 5;  i++) H_q[i] <= '0;
            for (int i = 0; i < 16; i++) W_q[i]  <= '0;
            {a_q,b_q,c_q,d_q,e_q} <= '0;
        end else begin
            case (state_q)

                ST_IDLE: if (start) begin
                    // Load H[0..4] from BLOCK8 (H[0..3]) and BLOCK9[31:0] (H[4])
                    for (int i = 0; i < 4; i++)
                        H_q[i] <= bswap32(sha_rb_rd[1024 + i*32 +: 32]);
                    H_q[4] <= bswap32(sha_rb_rd[1152 +: 32]);
                    // Load W[0..15]
                    for (int j = 0; j < 16; j++)
                        W_q[j] <= bswap32(sha_rb_rd[j*32 +: 32]);
                    // Init working vars
                    a_q <= bswap32(sha_rb_rd[1024 +: 32]);
                    b_q <= bswap32(sha_rb_rd[1056 +: 32]);
                    c_q <= bswap32(sha_rb_rd[1088 +: 32]);
                    d_q <= bswap32(sha_rb_rd[1120 +: 32]);
                    e_q <= bswap32(sha_rb_rd[1152 +: 32]);
                    rnd_q   <= '0;
                    state_q <= ST_COMPRESS;
                end

                ST_COMPRESS: begin
                    if (rnd_q >= 7'd16) W_q[rnd_q % 16] <= Wt;
                    begin
                        automatic logic [31:0] T;
                        T   = rotl32(a_q,5) + ft(b_q,c_q,d_q,rnd_q) + e_q + Wt + Kt(rnd_q);
                        e_q <= d_q;
                        d_q <= c_q;
                        c_q <= rotl32(b_q, 30);
                        b_q <= a_q;
                        a_q <= T;
                    end
                    if (rnd_q == 7'd79)
                        state_q <= ST_FINALIZE;
                    else
                        rnd_q <= rnd_q + 1;
                end

                ST_FINALIZE: begin
                    H_q[0] <= H_q[0] + a_q;  H_q[1] <= H_q[1] + b_q;
                    H_q[2] <= H_q[2] + c_q;  H_q[3] <= H_q[3] + d_q;
                    H_q[4] <= H_q[4] + e_q;
                    state_q <= ST_WB0;
                end

                ST_WB0: state_q <= ST_WB1;
                ST_WB1: state_q <= ST_IDLE;

                default: state_q <= ST_IDLE;
            endcase
        end
    end

endmodule
