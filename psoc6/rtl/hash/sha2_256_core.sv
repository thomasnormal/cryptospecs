// PSoC 6 Crypto — SHA-2 256 Core (FIPS 180-4)
//
// Register buffer layout (little-endian AHB, big-endian SHA words):
//   Message (64 B) : sha_rb_rd[511:0]    — BLOCK0-3
//   State   (32 B) : sha_rb_rd[1279:1024] — BLOCK8-9  (H[i] stored bswap32'd)
//
// Write-back: BLOCK8 ← H[0..3], BLOCK9 ← H[4..7]  (2 eng_wr cycles)
// Latency: 1 (LOAD) + 64 (COMPRESS) + 1 (FINALIZE) + 2 (WRITEBACK) = 68 cycles

`include "crypto_pkg.sv"
`include "crypto_isa_pkg.sv"

module sha2_256_core
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

    // SHA-256 round constants (FIPS 180-4 §4.2.2)
    logic [31:0] K [0:63];
    assign K[ 0]=32'h428a2f98; assign K[ 1]=32'h71374491; assign K[ 2]=32'hb5c0fbcf; assign K[ 3]=32'he9b5dba5;
    assign K[ 4]=32'h3956c25b; assign K[ 5]=32'h59f111f1; assign K[ 6]=32'h923f82a4; assign K[ 7]=32'hab1c5ed5;
    assign K[ 8]=32'hd807aa98; assign K[ 9]=32'h12835b01; assign K[10]=32'h243185be; assign K[11]=32'h550c7dc3;
    assign K[12]=32'h72be5d74; assign K[13]=32'h80deb1fe; assign K[14]=32'h9bdc06a7; assign K[15]=32'hc19bf174;
    assign K[16]=32'he49b69c1; assign K[17]=32'hefbe4786; assign K[18]=32'h0fc19dc6; assign K[19]=32'h240ca1cc;
    assign K[20]=32'h2de92c6f; assign K[21]=32'h4a7484aa; assign K[22]=32'h5cb0a9dc; assign K[23]=32'h76f988da;
    assign K[24]=32'h983e5152; assign K[25]=32'ha831c66d; assign K[26]=32'hb00327c8; assign K[27]=32'hbf597fc7;
    assign K[28]=32'hc6e00bf3; assign K[29]=32'hd5a79147; assign K[30]=32'h06ca6351; assign K[31]=32'h14292967;
    assign K[32]=32'h27b70a85; assign K[33]=32'h2e1b2138; assign K[34]=32'h4d2c6dfc; assign K[35]=32'h53380d13;
    assign K[36]=32'h650a7354; assign K[37]=32'h766a0abb; assign K[38]=32'h81c2c92e; assign K[39]=32'h92722c85;
    assign K[40]=32'ha2bfe8a1; assign K[41]=32'ha81a664b; assign K[42]=32'hc24b8b70; assign K[43]=32'hc76c51a3;
    assign K[44]=32'hd192e819; assign K[45]=32'hd6990624; assign K[46]=32'hf40e3585; assign K[47]=32'h106aa070;
    assign K[48]=32'h19a4c116; assign K[49]=32'h1e376c08; assign K[50]=32'h2748774c; assign K[51]=32'h34b0bcb5;
    assign K[52]=32'h391c0cb3; assign K[53]=32'h4ed8aa4a; assign K[54]=32'h5b9cca4f; assign K[55]=32'h682e6ff3;
    assign K[56]=32'h748f82ee; assign K[57]=32'h78a5636f; assign K[58]=32'h84c87814; assign K[59]=32'h8cc70208;
    assign K[60]=32'h90befffa; assign K[61]=32'ha4506ceb; assign K[62]=32'hbef9a3f7; assign K[63]=32'hc67178f2;

    // Utility functions
    function automatic logic [31:0] bswap32(input logic [31:0] x);
        return {x[7:0], x[15:8], x[23:16], x[31:24]};
    endfunction
    function automatic logic [31:0] rotr32(input logic [31:0] x, input int unsigned n);
        return (x >> n) | (x << (32 - n));
    endfunction
    function automatic logic [31:0] S0(input logic [31:0] x);
        return rotr32(x,2) ^ rotr32(x,13) ^ rotr32(x,22);
    endfunction
    function automatic logic [31:0] S1(input logic [31:0] x);
        return rotr32(x,6) ^ rotr32(x,11) ^ rotr32(x,25);
    endfunction
    function automatic logic [31:0] s0(input logic [31:0] x);
        return rotr32(x,7) ^ rotr32(x,18) ^ (x >> 3);
    endfunction
    function automatic logic [31:0] s1(input logic [31:0] x);
        return rotr32(x,17) ^ rotr32(x,19) ^ (x >> 10);
    endfunction
    function automatic logic [31:0] Ch(input logic [31:0] x, y, z);
        return (x & y) ^ (~x & z);
    endfunction
    function automatic logic [31:0] Maj(input logic [31:0] x, y, z);
        return (x & y) ^ (x & z) ^ (y & z);
    endfunction

    typedef enum logic [2:0] { ST_IDLE, ST_COMPRESS, ST_FINALIZE, ST_WB0, ST_WB1 } state_e;
    state_e state_q;

    logic [31:0] H_q [0:7];   // initial hash values held from LOAD until FINALIZE
    logic [31:0] a_q, b_q, c_q, d_q, e_q, f_q, g_q, h_q;  // working variables
    logic [31:0] W_q [0:15];  // circular message schedule
    logic [5:0]  rnd_q;       // round 0-63

    assign busy = (state_q != ST_IDLE);

    // Combinational: message schedule word for current round
    logic [31:0] Wt;
    always_comb begin
        if (rnd_q < 6'd16)
            Wt = W_q[rnd_q];
        else
            Wt = s1(W_q[(rnd_q + 14) % 16]) + W_q[(rnd_q + 9) % 16]
               + s0(W_q[(rnd_q +  1) % 16]) + W_q[rnd_q % 16];
    end

    // eng_wr outputs
    assign eng_wr_en   = (state_q == ST_WB0) || (state_q == ST_WB1);
    assign eng_wr_addr = (state_q == ST_WB0) ? 4'd8 : 4'd9;
    always_comb begin
        if (state_q == ST_WB0)
            eng_wr_data = {bswap32(H_q[3]), bswap32(H_q[2]),
                           bswap32(H_q[1]), bswap32(H_q[0])};
        else
            eng_wr_data = {bswap32(H_q[7]), bswap32(H_q[6]),
                           bswap32(H_q[5]), bswap32(H_q[4])};
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
                    // Load H[0..7] from blocks[8-9] (state region, reg_buff[1279:1024])
                    for (int i = 0; i < 8; i++)
                        H_q[i] <= bswap32(sha_rb_rd[1024 + i*32 +: 32]);
                    // Load W[0..15] from blocks[0-3] (message region, reg_buff[511:0])
                    for (int j = 0; j < 16; j++)
                        W_q[j] <= bswap32(sha_rb_rd[j*32 +: 32]);
                    // Init working vars = H (same source as H_q)
                    a_q <= bswap32(sha_rb_rd[1024 +: 32]);
                    b_q <= bswap32(sha_rb_rd[1056 +: 32]);
                    c_q <= bswap32(sha_rb_rd[1088 +: 32]);
                    d_q <= bswap32(sha_rb_rd[1120 +: 32]);
                    e_q <= bswap32(sha_rb_rd[1152 +: 32]);
                    f_q <= bswap32(sha_rb_rd[1184 +: 32]);
                    g_q <= bswap32(sha_rb_rd[1216 +: 32]);
                    h_q <= bswap32(sha_rb_rd[1248 +: 32]);
                    rnd_q   <= '0;
                    state_q <= ST_COMPRESS;
                end

                ST_COMPRESS: begin
                    // Expand schedule (for rounds >= 16, Wt is already combinational above)
                    if (rnd_q >= 6'd16) W_q[rnd_q % 16] <= Wt;
                    // One round
                    begin
                        automatic logic [31:0] T1, T2;
                        T1 = h_q + S1(e_q) + Ch(e_q,f_q,g_q) + K[rnd_q] + Wt;
                        T2 = S0(a_q) + Maj(a_q,b_q,c_q);
                        h_q <= g_q;  g_q <= f_q;  f_q <= e_q;  e_q <= d_q + T1;
                        d_q <= c_q;  c_q <= b_q;  b_q <= a_q;  a_q <= T1 + T2;
                    end
                    if (rnd_q == 6'd63)
                        state_q <= ST_FINALIZE;
                    else
                        rnd_q <= rnd_q + 1;
                end

                ST_FINALIZE: begin
                    // H[i] += working_var[i]; a_q..h_q now hold final values
                    H_q[0] <= H_q[0] + a_q;  H_q[1] <= H_q[1] + b_q;
                    H_q[2] <= H_q[2] + c_q;  H_q[3] <= H_q[3] + d_q;
                    H_q[4] <= H_q[4] + e_q;  H_q[5] <= H_q[5] + f_q;
                    H_q[6] <= H_q[6] + g_q;  H_q[7] <= H_q[7] + h_q;
                    state_q <= ST_WB0;
                end

                ST_WB0: state_q <= ST_WB1;  // eng_wr_en=1, addr=8, data=H[0..3]

                ST_WB1: state_q <= ST_IDLE; // eng_wr_en=1, addr=9, data=H[4..7]

                default: state_q <= ST_IDLE;
            endcase
        end
    end

endmodule
