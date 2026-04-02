// PSoC 6 Crypto — SHA-3 / Keccak-f[1600,24] Core (FIPS 202)
//
// Applies 24 rounds of the Keccak-f[1600] permutation.
// State layout: sha_rb_rd[1599:0] = A[0..24] (25 × 64-bit lanes, little-endian)
//   Lane A[i] = sha_rb_rd[i*64 +: 64]   (NO bswap — Keccak uses little-endian lanes)
//   A[i] = x + 5*y indexing per FIPS 202
//
// Write-back: 13 cycles (BLOCK0-11 = 2 lanes each; BLOCK12 = A[24] + 64'h0 pad)
// Latency: 1 (LOAD) + 24 (ROUND) + 13 (WRITEBACK) = 38 cycles

`include "crypto_pkg.sv"
`include "crypto_isa_pkg.sv"

module sha3_keccak
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

    // Keccak-f[1600] round constants (FIPS 202 Table 1)
    logic [63:0] RC [0:23];
    assign RC[ 0]=64'h0000000000000001; assign RC[ 1]=64'h0000000000008082;
    assign RC[ 2]=64'h800000000000808A; assign RC[ 3]=64'h8000000080008000;
    assign RC[ 4]=64'h000000000000808B; assign RC[ 5]=64'h0000000080000001;
    assign RC[ 6]=64'h8000000080008081; assign RC[ 7]=64'h8000000000008009;
    assign RC[ 8]=64'h000000000000008A; assign RC[ 9]=64'h0000000000000088;
    assign RC[10]=64'h0000000080008009; assign RC[11]=64'h000000008000000A;
    assign RC[12]=64'h000000008000808B; assign RC[13]=64'h800000000000008B;
    assign RC[14]=64'h8000000000008089; assign RC[15]=64'h8000000000008003;
    assign RC[16]=64'h8000000000008002; assign RC[17]=64'h8000000000000080;
    assign RC[18]=64'h000000000000800A; assign RC[19]=64'h800000008000000A;
    assign RC[20]=64'h8000000080008081; assign RC[21]=64'h8000000000008080;
    assign RC[22]=64'h0000000080000001; assign RC[23]=64'h8000000080008008;

    // ρ rotation offsets per lane index i = x + 5*y (FIPS 202 Table 2)
    localparam int RHO [0:24] =
        '{0,1,62,28,27, 36,44,6,55,20, 3,10,43,25,39, 41,45,15,21,8, 18,2,61,56,14};

    // π permutation: A'[i] = A[PI_SRC[i]]  (from FIPS 202 §3.2.3 applied to linear index)
    localparam int PI_SRC [0:24] =
        '{0,6,12,18,24, 3,9,10,16,22, 1,7,13,19,20, 4,5,11,17,23, 2,8,14,15,21};

    function automatic logic [63:0] rotl64(input logic [63:0] x, input int unsigned n);
        if (n == 0) return x;
        return (x << n) | (x >> (64 - n));
    endfunction

    // ---------------------------------------------------------------
    // Keccak round: combinational, given state A[0..24]
    // ---------------------------------------------------------------
    function automatic void keccak_round(
        input  logic [63:0] A_in [0:24],
        input  logic [63:0] rc,
        output logic [63:0] A_out [0:24]
    );
        logic [63:0] C [0:4], D [0:4];
        logic [63:0] A_t [0:24]; // after theta
        logic [63:0] B   [0:24]; // after rho+pi
        int col, row;
        // Theta
        for (int x = 0; x < 5; x++)
            C[x] = A_in[x] ^ A_in[x+5] ^ A_in[x+10] ^ A_in[x+15] ^ A_in[x+20];
        for (int x = 0; x < 5; x++)
            D[x] = C[(x+4)%5] ^ rotl64(C[(x+1)%5], 1);
        for (int i = 0; i < 25; i++)
            A_t[i] = A_in[i] ^ D[i%5];
        // Rho + Pi combined → B
        for (int i = 0; i < 25; i++)
            B[i] = rotl64(A_t[PI_SRC[i]], RHO[PI_SRC[i]]);
        // Chi
        for (int i = 0; i < 25; i++) begin
            col = i % 5; row = i / 5;
            A_out[i] = B[i] ^ (~B[(col+1)%5 + row*5] & B[(col+2)%5 + row*5]);
        end
        // Iota
        A_out[0] ^= rc;
    endfunction

    typedef enum logic [1:0] { ST_IDLE, ST_ROUND, ST_WRITEBACK } state_e;
    state_e state_q;

    logic [63:0] A_q [0:24];
    logic [4:0]  rnd_q;   // 0-23 Keccak rounds
    logic [3:0]  wb_q;    // 0-12 writeback block counter

    assign busy = (state_q != ST_IDLE);

    // eng_wr
    assign eng_wr_en   = (state_q == ST_WRITEBACK);
    assign eng_wr_addr = wb_q; // wb_q 0-12, 4-bit linear block index
    always_comb begin
        if (wb_q < 4'd12)
            eng_wr_data = {A_q[wb_q*2+1], A_q[wb_q*2]};
        else
            eng_wr_data = {64'h0, A_q[24]};
    end

    // Next-round combinational
    logic [63:0] A_next [0:24];
    always_comb begin
        keccak_round(A_q, RC[rnd_q], A_next);
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= ST_IDLE;
            rnd_q   <= '0;
            wb_q    <= '0;
            for (int i = 0; i < 25; i++) A_q[i] <= '0;
        end else begin
            case (state_q)

                ST_IDLE: if (start) begin
                    // Load state: lane i at sha_rb_rd[i*64 +: 64] (no bswap for Keccak)
                    for (int i = 0; i < 25; i++)
                        A_q[i] <= sha_rb_rd[i*64 +: 64];
                    rnd_q   <= '0;
                    wb_q    <= '0;
                    state_q <= ST_ROUND;
                end

                ST_ROUND: begin
                    for (int i = 0; i < 25; i++) A_q[i] <= A_next[i];
                    if (rnd_q == 5'd23)
                        state_q <= ST_WRITEBACK;
                    else
                        rnd_q <= rnd_q + 1;
                end

                ST_WRITEBACK: begin
                    if (wb_q == 4'd12)
                        state_q <= ST_IDLE;
                    else
                        wb_q <= wb_q + 1;
                end

                default: state_q <= ST_IDLE;
            endcase
        end
    end

endmodule
