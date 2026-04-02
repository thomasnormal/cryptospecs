// PSoC 6 Crypto — Register Buffer
//
// 16 × 128-bit blocks (2048 bits total) split into two 1024-bit halves:
//   Lower half — BLOCK0–BLOCK7 (IDs 0-7), named in ISA block operations
//   Upper half — BLOCK8–BLOCK15, used by SHA engines and accessed via OPC_SWAP
//
// Block IDs 8 (LOAD_FIFO0), 9 (LOAD_FIFO1), 12 (STORE_FIFO) are virtual FIFO
// identifiers used in instruction source/dest fields; they are NOT physical
// blocks and do not alias BLOCK8/9/12.
//
// SHA engine layout (crypto_isa_pkg comments):
//   reg_buff[1023:0]   = message block (lower half, BLOCK0-7)
//   reg_buff[1535:1024] = hash value in/out (BLOCK8-11)
//   reg_buff[2047:1536] = working copy (BLOCK12-15)
//   SHA3: reg_buff[1599:0] = 1600-bit Keccak state (BLOCK0-12)
//
// OPC_SWAP exchanges the two 1024-bit halves (BLOCK0-7 ↔ BLOCK8-15).
// Block operations execute in one cycle; bop_done fires the following cycle.

`include "crypto_pkg.sv"
`include "crypto_isa_pkg.sv"

module reg_buffer
    import crypto_pkg::*;
    import crypto_isa_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    // ------------------------------------------------------------------
    // Block operation interface (from instruction decoder)
    // ------------------------------------------------------------------
    input  logic [7:0]  bop_opcode,   // OPC_BLOCK_MOV / XOR / SET / CMP_GCM
    input  logic [3:0]  bop_src0,
    input  logic [3:0]  bop_src1,     // BLOCK_XOR second source
    input  logic [3:0]  bop_dst,
    input  logic [3:0]  bop_size,     // 0 → 16 bytes, 1-15 → N bytes
    input  logic [7:0]  bop_byte,     // fill byte (BLOCK_SET)
    input  logic        bop_reflect,  // byte-reverse flag (BLOCK_MOV)
    input  logic        bop_start,    // one-cycle start pulse
    output logic        bop_done,     // one-cycle done (next cycle after start)
    output logic        bop_cmp_eq,   // BLOCK_CMP result (registered with bop_done)

    // OPC_CLEAR / OPC_SWAP from decoder
    input  logic        rbuf_clear,   // zero all blocks
    input  logic        rbuf_swap,    // swap BLOCK0-3 ↔ BLOCK4-7

    // ------------------------------------------------------------------
    // LOAD_FIFO0 → block (128-bit staging from load_store_fifo)
    // ------------------------------------------------------------------
    input  logic [127:0] ld0_data,
    input  logic [3:0]   ld0_dst,
    input  logic         ld0_valid,

    // ------------------------------------------------------------------
    // LOAD_FIFO1 → block
    // ------------------------------------------------------------------
    input  logic [127:0] ld1_data,
    input  logic [3:0]   ld1_dst,
    input  logic         ld1_valid,

    // ------------------------------------------------------------------
    // block → STORE_FIFO (combinational read)
    // ------------------------------------------------------------------
    output logic [127:0] st_data,
    input  logic [3:0]   st_src,

    // ------------------------------------------------------------------
    // Engine read/write (AES, DES, SHA read plaintext / write ciphertext)
    // eng_wr_addr is a linear block index 0-15 (not a FIFO virtual ID)
    // ------------------------------------------------------------------
    input  logic [3:0]   eng_rd_addr,
    output logic [127:0] eng_rd_data,

    input  logic [3:0]   eng_wr_addr,
    input  logic [127:0] eng_wr_data,
    input  logic         eng_wr_en,

    // ------------------------------------------------------------------
    // SHA: full 2048-bit read port (sha_rb_rd[i*128+:128] = blocks[i])
    // ------------------------------------------------------------------
    output logic [2047:0] sha_rb_rd
);

    logic [127:0] blocks [0:15];

    // Safe read: FIFO virtual IDs (8, 9, 12) return 0; physical blocks 0-15 return data
    function automatic logic [127:0] rd_blk(input logic [3:0] id);
        if (id == BLKID_LOAD_FIFO0 || id == BLKID_LOAD_FIFO1 || id == BLKID_STORE_FIFO)
            return 128'h0;
        return blocks[id];
    endfunction

    // Byte count from bop_size (0 means 16)
    function automatic int unsigned bcnt(input logic [3:0] sz);
        return (sz == 4'd0) ? 16 : int'(sz);
    endfunction

    // ------------------------------------------------------------------
    // Write priority (highest to lowest):
    //   1. rbuf_clear / rbuf_swap
    //   2. ld0 / ld1 stream
    //   3. engine write
    //   4. block operation
    // ------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int b = 0; b < 16; b++) blocks[b] <= '0;

        end else if (rbuf_clear) begin
            for (int b = 0; b < 16; b++) blocks[b] <= '0;

        end else if (rbuf_swap) begin
            // Swap the two 1024-bit halves: BLOCK0-7 ↔ BLOCK8-15
            for (int b = 0; b < 8; b++) begin
                logic [127:0] tmp;
                tmp           = blocks[b];
                blocks[b]    <= blocks[b+8];
                blocks[b+8]  <= tmp;
            end

        end else begin
            // LOAD stream writes (lower half only; upper half loaded via SWAP)
            if (ld0_valid && ld0_dst <= 4'd7) blocks[ld0_dst] <= ld0_data;
            if (ld1_valid && ld1_dst <= 4'd7) blocks[ld1_dst] <= ld1_data;

            // Engine write: AES uses lower half (addr 0-7); SHA uses any block (0-15)
            if (eng_wr_en) blocks[eng_wr_addr] <= eng_wr_data;

            // Block operations
            if (bop_start) begin
                logic [127:0] s0, s1, d, ref_s;
                int unsigned  bc;
                s0 = rd_blk(bop_src0);
                s1 = rd_blk(bop_src1);
                d  = rd_blk(bop_dst);
                bc = bcnt(bop_size);

                unique case (bop_opcode)
                    OPC_BLOCK_MOV: begin
                        if (bop_reflect) begin
                            for (int j = 0; j < 16; j++)
                                ref_s[j*8 +: 8] = s0[(15-j)*8 +: 8];
                            for (int j = 0; j < int'(bc); j++)
                                d[j*8 +: 8] = ref_s[j*8 +: 8];
                        end else begin
                            for (int j = 0; j < int'(bc); j++)
                                d[j*8 +: 8] = s0[j*8 +: 8];
                        end
                        if (bop_dst <= 4'd7) blocks[bop_dst] <= d;
                    end
                    OPC_BLOCK_XOR: begin
                        for (int j = 0; j < int'(bc); j++)
                            d[j*8 +: 8] = s0[j*8 +: 8] ^ s1[j*8 +: 8];
                        if (bop_dst <= 4'd7) blocks[bop_dst] <= d;
                    end
                    OPC_BLOCK_SET: begin
                        for (int j = 0; j < int'(bc); j++)
                            d[j*8 +: 8] = bop_byte;
                        if (bop_dst <= 4'd7) blocks[bop_dst] <= d;
                    end
                    default: ; // OPC_BLOCK_CMP_GCM: no write
                endcase
            end
        end
    end

    // Done: fires one cycle after bop_start
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bop_done   <= 1'b0;
            bop_cmp_eq <= 1'b0;
        end else begin
            bop_done   <= bop_start;
            bop_cmp_eq <= bop_start && (rd_blk(bop_src0) == rd_blk(bop_src1));
        end
    end

    // Combinational read ports
    assign st_data     = rd_blk(st_src);
    assign eng_rd_data = rd_blk(eng_rd_addr);

    // SHA: full 2048-bit view (sha_rb_rd[i*128+:128] = blocks[i])
    genvar gi;
    generate
        for (gi = 0; gi < 16; gi++) begin : gen_sha_rd
            assign sha_rb_rd[gi*128 +: 128] = blocks[gi];
        end
    endgenerate

endmodule
