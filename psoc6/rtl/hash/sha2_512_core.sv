// PSoC 6 Crypto — SHA-2 512 Core (FIPS 180-4)
//
// Register buffer layout (little-endian AHB, big-endian SHA words):
//   Message (128 B) : sha_rb_rd[1023:0]   — BLOCK0-7  (W[0..15], 64-bit each)
//   State   ( 64 B) : sha_rb_rd[1535:1024] — BLOCK8-11 (H[0..7], 64-bit each)
//
// Write-back: 4 cycles (BLOCK8=H[0..1], BLOCK9=H[2..3], BLOCK10=H[4..5], BLOCK11=H[6..7])
// Latency: 1 + 80 + 1 + 4 = 86 cycles

`include "crypto_pkg.sv"
`include "crypto_isa_pkg.sv"

module sha2_512_core
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

    // SHA-512 round constants (FIPS 180-4 §4.2.3)
    logic [63:0] K [0:79];
    assign K[ 0]=64'h428a2f98d728ae22; assign K[ 1]=64'h7137449123ef65cd;
    assign K[ 2]=64'hb5c0fbcfec4d3b2f; assign K[ 3]=64'he9b5dba58189dbbc;
    assign K[ 4]=64'h3956c25bf348b538; assign K[ 5]=64'h59f111f1b605d019;
    assign K[ 6]=64'h923f82a4af194f9b; assign K[ 7]=64'hab1c5ed5da6d8118;
    assign K[ 8]=64'hd807aa98a3030242; assign K[ 9]=64'h12835b0145706fbe;
    assign K[10]=64'h243185be4ee4b28c; assign K[11]=64'h550c7dc3d5ffb4e2;
    assign K[12]=64'h72be5d74f27b896f; assign K[13]=64'h80deb1fe3b1696b1;
    assign K[14]=64'h9bdc06a725c71235; assign K[15]=64'hc19bf174cf692694;
    assign K[16]=64'he49b69c19ef14ad2; assign K[17]=64'hefbe4786384f25e3;
    assign K[18]=64'h0fc19dc68b8cd5b5; assign K[19]=64'h240ca1cc77ac9c65;
    assign K[20]=64'h2de92c6f592b0275; assign K[21]=64'h4a7484aa6ea6e483;
    assign K[22]=64'h5cb0a9dcbd41fbd4; assign K[23]=64'h76f988da831153b5;
    assign K[24]=64'h983e5152ee66dfab; assign K[25]=64'ha831c66d2db43210;
    assign K[26]=64'hb00327c898fb213f; assign K[27]=64'hbf597fc7beef0ee4;
    assign K[28]=64'hc6e00bf33da88fc2; assign K[29]=64'hd5a79147930aa725;
    assign K[30]=64'h06ca6351e003826f; assign K[31]=64'h142929670a0e6e70;
    assign K[32]=64'h27b70a8546d22ffc; assign K[33]=64'h2e1b21385c26c926;
    assign K[34]=64'h4d2c6dfc5ac42aed; assign K[35]=64'h53380d139d95b3df;
    assign K[36]=64'h650a73548baf63de; assign K[37]=64'h766a0abb3c77b2a8;
    assign K[38]=64'h81c2c92e47edaee6; assign K[39]=64'h92722c851482353b;
    assign K[40]=64'ha2bfe8a14cf10364; assign K[41]=64'ha81a664bbc423001;
    assign K[42]=64'hc24b8b70d0f89791; assign K[43]=64'hc76c51a30654be30;
    assign K[44]=64'hd192e819d6ef5218; assign K[45]=64'hd69906245565a910;
    assign K[46]=64'hf40e35855771202a; assign K[47]=64'h106aa07032bbd1b8;
    assign K[48]=64'h19a4c116b8d2d0c8; assign K[49]=64'h1e376c085141ab53;
    assign K[50]=64'h2748774cdf8eeb99; assign K[51]=64'h34b0bcb5e19b48a8;
    assign K[52]=64'h391c0cb3c5c95a63; assign K[53]=64'h4ed8aa4ae3418acb;
    assign K[54]=64'h5b9cca4f7763e373; assign K[55]=64'h682e6ff3d6b2b8a3;
    assign K[56]=64'h748f82ee5defb2fc; assign K[57]=64'h78a5636f43172f60;
    assign K[58]=64'h84c87814a1f0ab72; assign K[59]=64'h8cc702081a6439ec;
    assign K[60]=64'h90befffa23631e28; assign K[61]=64'ha4506cebde82bde9;
    assign K[62]=64'hbef9a3f7b2c67915; assign K[63]=64'hc67178f2e372532b;
    assign K[64]=64'hca273eceea26619c; assign K[65]=64'hd186b8c721c0c207;
    assign K[66]=64'heada7dd6cde0eb1e; assign K[67]=64'hf57d4f7fee6ed178;
    assign K[68]=64'h06f067aa72176fba; assign K[69]=64'h0a637dc5a2c898a6;
    assign K[70]=64'h113f9804bef90dae; assign K[71]=64'h1b710b35131c471b;
    assign K[72]=64'h28db77f523047d84; assign K[73]=64'h32caab7b40c72493;
    assign K[74]=64'h3c9ebe0a15c9bebc; assign K[75]=64'h431d67c49c100d4c;
    assign K[76]=64'h4cc5d4becb3e42b6; assign K[77]=64'h597f299cfc657e2a;
    assign K[78]=64'h5fcb6fab3ad6faec; assign K[79]=64'h6c44198c4a475817;

    function automatic logic [63:0] bswap64(input logic [63:0] x);
        return {x[7:0],x[15:8],x[23:16],x[31:24],x[39:32],x[47:40],x[55:48],x[63:56]};
    endfunction
    function automatic logic [63:0] rotr64(input logic [63:0] x, input int unsigned n);
        return (x >> n) | (x << (64 - n));
    endfunction
    function automatic logic [63:0] S0(input logic [63:0] x);
        return rotr64(x,28) ^ rotr64(x,34) ^ rotr64(x,39);
    endfunction
    function automatic logic [63:0] S1(input logic [63:0] x);
        return rotr64(x,14) ^ rotr64(x,18) ^ rotr64(x,41);
    endfunction
    function automatic logic [63:0] s0(input logic [63:0] x);
        return rotr64(x,1) ^ rotr64(x,8) ^ (x >> 7);
    endfunction
    function automatic logic [63:0] s1(input logic [63:0] x);
        return rotr64(x,19) ^ rotr64(x,61) ^ (x >> 6);
    endfunction
    function automatic logic [63:0] Ch(input logic [63:0] x, y, z);
        return (x & y) ^ (~x & z);
    endfunction
    function automatic logic [63:0] Maj(input logic [63:0] x, y, z);
        return (x & y) ^ (x & z) ^ (y & z);
    endfunction

    typedef enum logic [2:0] { ST_IDLE, ST_COMPRESS, ST_FINALIZE,
                                ST_WB0, ST_WB1, ST_WB2, ST_WB3 } state_e;
    state_e state_q;

    logic [63:0] H_q [0:7];
    logic [63:0] a_q, b_q, c_q, d_q, e_q, f_q, g_q, h_q;
    logic [63:0] W_q [0:15];
    logic [6:0]  rnd_q;  // 0-79

    assign busy = (state_q != ST_IDLE);

    logic [63:0] Wt;
    always_comb begin
        if (rnd_q < 7'd16)
            Wt = W_q[rnd_q];
        else
            Wt = s1(W_q[(rnd_q+14)%16]) + W_q[(rnd_q+9)%16]
               + s0(W_q[(rnd_q+ 1)%16]) + W_q[rnd_q%16];
    end

    logic [1:0] wb_idx;
    always_comb begin
        case (state_q)
            ST_WB0: wb_idx = 2'd0;
            ST_WB1: wb_idx = 2'd1;
            ST_WB2: wb_idx = 2'd2;
            default: wb_idx = 2'd3;
        endcase
    end

    assign eng_wr_en   = (state_q == ST_WB0) || (state_q == ST_WB1) ||
                         (state_q == ST_WB2) || (state_q == ST_WB3);
    assign eng_wr_addr = 4'd8 + {2'b0, wb_idx};
    always_comb begin
        eng_wr_data = {bswap64(H_q[wb_idx*2+1]), bswap64(H_q[wb_idx*2])};
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= ST_IDLE;
            rnd_q   <= '0;
            for (int i = 0; i < 8;  i++) H_q[i] <= '0;
            for (int i = 0; i < 16; i++) W_q[i]  <= '0;
            {a_q,b_q,c_q,d_q,e_q,f_q,g_q,h_q} <= '0;
        end else begin
            case (state_q)

                ST_IDLE: if (start) begin
                    for (int i = 0; i < 8; i++)
                        H_q[i] <= bswap64(sha_rb_rd[1024 + i*64 +: 64]);
                    for (int j = 0; j < 16; j++)
                        W_q[j] <= bswap64(sha_rb_rd[j*64 +: 64]);
                    a_q <= bswap64(sha_rb_rd[1024+: 64]);
                    b_q <= bswap64(sha_rb_rd[1088+: 64]);
                    c_q <= bswap64(sha_rb_rd[1152+: 64]);
                    d_q <= bswap64(sha_rb_rd[1216+: 64]);
                    e_q <= bswap64(sha_rb_rd[1280+: 64]);
                    f_q <= bswap64(sha_rb_rd[1344+: 64]);
                    g_q <= bswap64(sha_rb_rd[1408+: 64]);
                    h_q <= bswap64(sha_rb_rd[1472+: 64]);
                    rnd_q   <= '0;
                    state_q <= ST_COMPRESS;
                end

                ST_COMPRESS: begin
                    if (rnd_q >= 7'd16) W_q[rnd_q % 16] <= Wt;
                    begin
                        automatic logic [63:0] T1, T2;
                        T1 = h_q + S1(e_q) + Ch(e_q,f_q,g_q) + K[rnd_q] + Wt;
                        T2 = S0(a_q) + Maj(a_q,b_q,c_q);
                        h_q <= g_q; g_q <= f_q; f_q <= e_q; e_q <= d_q + T1;
                        d_q <= c_q; c_q <= b_q; b_q <= a_q; a_q <= T1 + T2;
                    end
                    if (rnd_q == 7'd79) state_q <= ST_FINALIZE;
                    else rnd_q <= rnd_q + 1;
                end

                ST_FINALIZE: begin
                    H_q[0]<=H_q[0]+a_q; H_q[1]<=H_q[1]+b_q; H_q[2]<=H_q[2]+c_q; H_q[3]<=H_q[3]+d_q;
                    H_q[4]<=H_q[4]+e_q; H_q[5]<=H_q[5]+f_q; H_q[6]<=H_q[6]+g_q; H_q[7]<=H_q[7]+h_q;
                    state_q <= ST_WB0;
                end

                ST_WB0: state_q <= ST_WB1;
                ST_WB1: state_q <= ST_WB2;
                ST_WB2: state_q <= ST_WB3;
                ST_WB3: state_q <= ST_IDLE;

                default: state_q <= ST_IDLE;
            endcase
        end
    end

endmodule
