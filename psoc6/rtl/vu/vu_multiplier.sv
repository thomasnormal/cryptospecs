// vu_multiplier.sv
// VU Multiplier — unsigned integer multiply (UMUL) and
// GF(2^m) polynomial multiply (XMUL) for the PSoC 6 Vector Unit.
//
// UMUL (0x33):  dst = src0 * src1  (unsigned schoolbook)
//   Outer loop i=0..nwords0-1:
//     partial_carry = 0
//     Inner loop j=0..nwords1-1:
//       product64 = src0[i]*src1[j] + dst[i+j] + partial_carry
//       dst[i+j]  = product64[31:0]
//       partial_carry = product64[63:32]
//     dst[i+nwords1] += partial_carry
//
// XMUL (0x32):  dst = src0 XOR-multiply src1  (polynomial multiply over GF(2^m))
//   Outer loop i=0..nwords0-1:
//     Read src0[i].
//     For each bit b=0..31 that is set in src0[i]:
//       Inner loop j=0..nwords1-1:
//         dst[i+j]   ^= src1[j] << b          (low part)
//         dst[i+j+1] ^= src1[j] >> (32-b)     (high spill, only if b>0)
//
// Memory timing: synchronous, 1-cycle read latency.
//   b_addr/b_wdata/b_we are registered outputs.
//   A value clocked into these registers at edge T drives the memory during cycle T.
//   Write: b_we=1 at edge T → write occurs; b_rdata unrelated.
//   Read:  b_we=0 at edge T → b_rdata valid at edge T+1.
//
// b_addr protocol: Write and read address NEVER compete in the same registered cycle.
//   Every ST_WR_* state only drives b_addr=WRITE_ADDR + b_we=1.
//   The FOLLOWING state issues the next read address (b_we stays 0).
//   This strict separation prevents the "last-wins" NB-assign bug.
//
// State sequence (UMUL, per inner word j):
//   ST_RD_SRC1      → issue src1[j] read
//   ST_RD_DST       → issue dst[i+j] read; latch src1[j]
//   ST_COMPUTE      → latch dst[i+j]; compute 64-bit product; stage wr_data
//   ST_WR_DST       → write dst[i+j]; advance j or route to carry/next-i
//   ST_ISSUE_SRC1   → issue src1[j] read for next iteration  (read only!)
//   ... (back to ST_RD_DST)
//   ST_RD_CARRY     → issue dst[i+nwords1] read
//   ST_COMPUTE_CARRY→ latch dst; add carry; stage wr_data
//   ST_WR_CARRY     → write dst[i+nwords1]; advance i
//   ST_ISSUE_SRC0   → issue src0[i] read for next outer iteration  (read only!)
//   ST_RD_SRC0      → wait 1 cycle for src0[i] latency
//   ST_LATCH_SRC0   → latch src0[i]; restart inner loop
//
// State sequence (XMUL, per inner word j, per set bit b):
//   ST_RD_SRC1      → issue src1[j] read
//   ST_RD_DST       → issue dst[i+j] read; latch src1[j]
//   ST_COMPUTE      → latch dst[i+j]; compute XOR; stage wr_data + spill
//   ST_WR_DST       → write dst[i+j]
//   if b>0 and spill!=0:
//     ST_RD_DST_HI  → issue dst[i+j+1] read
//     ST_COMPUTE_HI → latch dst; XOR spill; stage wr_data
//     ST_WR_DST_HI  → write dst[i+j+1]; advance j
//     ST_ISSUE_SRC1 → issue src1[j] read for next j  (read only!)
//   else:
//     advance j → ST_ISSUE_SRC1 → ST_RD_DST
//   end-of-j-loop: advance bit b → ST_ISSUE_SRC1
//   end-of-b-loop: advance i → ST_ISSUE_SRC0 → ST_RD_SRC0 → ST_LATCH_SRC0

`include "crypto_pkg.sv"
`include "crypto_isa_pkg.sv"

module vu_multiplier
    import crypto_pkg::*;
    import crypto_isa_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    input  logic [7:0]  mul_op,
    input  logic [9:0]  src0_addr,
    input  logic [9:0]  src1_addr,
    input  logic [9:0]  dst_addr,
    input  logic [12:0] src0_size,
    input  logic [12:0] src1_size,
    input  logic [12:0] dst_size,
    input  logic        mul_start,
    output logic        mul_done,
    output logic        mul_busy,

    output logic [9:0]  b_addr,
    output logic [31:0] b_wdata,
    output logic        b_we,
    input  logic [31:0] b_rdata
);

    // ---------------------------------------------------------------
    // FSM state encoding
    // ---------------------------------------------------------------
    typedef enum logic [3:0] {
        ST_IDLE         = 4'd0,
        ST_CLEAR        = 4'd1,   // write 0 to each dst word
        ST_ISSUE_SRC0   = 4'd2,   // issue src0[i] read (read-only, after a write)
        ST_RD_SRC0      = 4'd3,   // wait for src0[i] read latency
        ST_LATCH_SRC0   = 4'd4,   // latch src0[i]; dispatch to inner loop
        ST_ISSUE_SRC1   = 4'd5,   // issue src1[j] read (read-only, after a write)
        ST_RD_SRC1      = 4'd6,   // wait for src1[j] read latency  (also: issue dst read)
        ST_RD_DST       = 4'd7,   // wait for dst[i+j] read latency; latch src1
        ST_COMPUTE      = 4'd8,   // latch dst; compute; stage wr_data
        ST_WR_DST       = 4'd9,   // write dst[i+j]; route to next state
        ST_RD_CARRY     = 4'd10,  // UMUL: issue dst[i+nwords1] read
        ST_COMPUTE_CARRY= 4'd11,  // UMUL: latch; add carry; stage wr_data
        ST_WR_CARRY     = 4'd12,  // UMUL: write dst[i+nwords1]; advance outer i
        ST_RD_DST_HI    = 4'd13,  // XMUL: issue dst[i+j+1] read (spill)
        ST_COMPUTE_HI   = 4'd14,  // XMUL: latch; XOR spill; stage wr_data
        ST_WR_DST_HI    = 4'd15   // XMUL: write dst[i+j+1]; advance j
        // ST_DONE is encoded as ST_IDLE (mul_done pulses for one cycle after mul_busy falls)
    } state_e;

    state_e state_q;

    // ---------------------------------------------------------------
    // Registers
    // ---------------------------------------------------------------
    logic [9:0]  i_q;           // outer loop index (src0 word)
    logic [9:0]  j_q;           // inner loop index (src1 word)
    logic [9:0]  nwords0_q;
    logic [9:0]  nwords1_q;
    logic [9:0]  nwords_dst_q;
    logic [9:0]  clear_idx_q;
    logic [31:0] src0_word_q;   // latched src0[i]
    logic [31:0] src1_word_q;   // latched src1[j]
    logic [31:0] partial_carry_q;
    logic [4:0]  xmul_bit_q;   // current set-bit position in src0[i]
    logic [31:0] xmul_spill_q; // high part of XMUL shift, for dst[i+j+1]
    logic [7:0]  op_q;
    // Staged write
    logic [31:0] wr_data_q;
    logic [9:0]  wr_addr_q;
    // Full 64-bit product (UMUL) — carry extracted in ST_WR_DST
    logic [63:0] umul_prod_q;
    // done pulse
    logic        mul_done_q;

    // ---------------------------------------------------------------
    // Outputs
    // ---------------------------------------------------------------
    assign mul_busy = (state_q != ST_IDLE);
    assign mul_done = mul_done_q;

    // ---------------------------------------------------------------
    // Geometry (combinational from input ports — valid at mul_start)
    // ---------------------------------------------------------------
    logic [13:0] nwords0_c, nwords1_c, nwords_dst_c;
    assign nwords0_c    = ({1'b0, src0_size} + 14'd32) >> 5;
    assign nwords1_c    = ({1'b0, src1_size} + 14'd32) >> 5;
    assign nwords_dst_c = ({1'b0, dst_size}  + 14'd32) >> 5;

    // ---------------------------------------------------------------
    // UMUL: 64-bit product (evaluated in ST_COMPUTE when b_rdata=dst[i+j])
    // ---------------------------------------------------------------
    logic [63:0] umul_prod_comb;
    assign umul_prod_comb = ({32'd0, src0_word_q} * {32'd0, src1_word_q})
                           + {32'd0, b_rdata}
                           + {32'd0, partial_carry_q};

    // ---------------------------------------------------------------
    // XMUL: shift outputs (based on src1_word_q + xmul_bit_q)
    // ---------------------------------------------------------------
    logic [31:0] xmul_low_comb;
    logic [31:0] xmul_high_comb;

    always_comb begin : blk_xmul
        if (xmul_bit_q == 5'd0) begin
            xmul_low_comb  = src1_word_q;
            xmul_high_comb = 32'd0;
        end else begin
            xmul_low_comb  = src1_word_q << {27'd0, xmul_bit_q};
            xmul_high_comb = src1_word_q >> (6'd32 - {1'b0, xmul_bit_q});
        end
    end

    // ---------------------------------------------------------------
    // XMUL: find lowest set bit in src0_word_q strictly above xmul_bit_q
    // ---------------------------------------------------------------
    logic        xmul_next_found;
    logic [4:0]  xmul_next_bit;

    always_comb begin : blk_next_bit
        integer nb;
        xmul_next_found = 1'b0;
        xmul_next_bit   = 5'd0;
        for (nb = 0; nb < 32; nb++) begin
            if ((nb > int'(xmul_bit_q)) && src0_word_q[nb] && !xmul_next_found) begin
                xmul_next_found = 1'b1;
                xmul_next_bit   = 5'(nb);
            end
        end
    end

    // ---------------------------------------------------------------
    // XMUL: find lowest set bit in b_rdata (for initial dispatch)
    // Iterates downward so lowest index wins.
    // ---------------------------------------------------------------
    logic [4:0] xmul_first_bit;

    always_comb begin : blk_first_bit
        integer fb;
        xmul_first_bit = 5'd0;
        for (fb = 31; fb >= 0; fb--) begin
            if (b_rdata[fb])
                xmul_first_bit = 5'(fb);
        end
    end

    // ---------------------------------------------------------------
    // Main FSM
    // ---------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q         <= ST_IDLE;
            mul_done_q      <= 1'b0;
            op_q            <= 8'd0;
            i_q             <= 10'd0;
            j_q             <= 10'd0;
            nwords0_q       <= 10'd0;
            nwords1_q       <= 10'd0;
            nwords_dst_q    <= 10'd0;
            clear_idx_q     <= 10'd0;
            src0_word_q     <= 32'd0;
            src1_word_q     <= 32'd0;
            partial_carry_q <= 32'd0;
            xmul_bit_q      <= 5'd0;
            xmul_spill_q    <= 32'd0;
            wr_data_q       <= 32'd0;
            wr_addr_q       <= 10'd0;
            umul_prod_q     <= 64'd0;
            b_addr          <= 10'd0;
            b_wdata         <= 32'd0;
            b_we            <= 1'b0;
        end else begin
            b_we       <= 1'b0;
            mul_done_q <= 1'b0;

            case (state_q)

                // ====================================================
                // ST_IDLE: wait for mul_start.
                // ====================================================
                ST_IDLE: begin
                    if (mul_start) begin
                        op_q            <= mul_op;
                        nwords0_q       <= nwords0_c[9:0];
                        nwords1_q       <= nwords1_c[9:0];
                        nwords_dst_q    <= nwords_dst_c[9:0];
                        i_q             <= 10'd0;
                        j_q             <= 10'd0;
                        clear_idx_q     <= 10'd0;
                        partial_carry_q <= 32'd0;
                        xmul_bit_q      <= 5'd0;
                        xmul_spill_q    <= 32'd0;
                        // Begin clearing dst: write dst[0] = 0
                        b_addr          <= dst_addr;
                        b_wdata         <= 32'd0;
                        b_we            <= 1'b1;
                        state_q         <= ST_CLEAR;
                    end
                end

                // ====================================================
                // ST_CLEAR: write 0 to each dst word sequentially.
                // clear_idx_q = index of word just written.
                // When all words are zeroed, transition to read src0[0].
                // ====================================================
                ST_CLEAR: begin
                    if (clear_idx_q < (nwords_dst_q - 10'd1)) begin
                        // Issue next zero-write (this is still a write-only cycle)
                        clear_idx_q <= clear_idx_q + 10'd1;
                        b_addr      <= dst_addr + clear_idx_q + 10'd1;
                        b_wdata     <= 32'd0;
                        b_we        <= 1'b1;
                    end else begin
                        // Done clearing; issue src0[0] read (no write this cycle)
                        b_addr  <= src0_addr;
                        state_q <= ST_RD_SRC0;
                    end
                end

                // ====================================================
                // ST_ISSUE_SRC0: after a write, issue src0[i] read.
                // i_q must already be updated before entering this state.
                // ====================================================
                ST_ISSUE_SRC0: begin
                    b_addr  <= src0_addr + i_q;
                    state_q <= ST_RD_SRC0;
                end

                // ====================================================
                // ST_RD_SRC0: src0[i] address on bus; wait one cycle.
                // ====================================================
                ST_RD_SRC0: begin
                    state_q <= ST_LATCH_SRC0;
                end

                // ====================================================
                // ST_LATCH_SRC0: b_rdata = src0[i].
                // For UMUL: always start inner loop.
                // For XMUL: if word is zero, skip to next i.
                //           Otherwise, find lowest set bit and start inner.
                // ====================================================
                ST_LATCH_SRC0: begin
                    src0_word_q     <= b_rdata;
                    partial_carry_q <= 32'd0;
                    j_q             <= 10'd0;

                    if (op_q == OPC_XMUL) begin
                        if (b_rdata == 32'd0) begin
                            // src0[i] is zero — skip to next i
                            if (i_q < (nwords0_q - 10'd1)) begin
                                i_q     <= i_q + 10'd1;
                                b_addr  <= src0_addr + i_q + 10'd1;
                                state_q <= ST_RD_SRC0;
                            end else begin
                                // All outer words done
                                mul_done_q <= 1'b1;
                                state_q    <= ST_IDLE;
                            end
                        end else begin
                            // Dispatch to lowest set bit; issue src1[0] read
                            xmul_bit_q <= xmul_first_bit;
                            b_addr     <= src1_addr;
                            state_q    <= ST_RD_SRC1;
                        end
                    end else begin
                        // UMUL: issue src1[0] read
                        b_addr  <= src1_addr;
                        state_q <= ST_RD_SRC1;
                    end
                end

                // ====================================================
                // ST_ISSUE_SRC1: after a write, issue src1[j] read.
                // j_q must already be updated before entering this state.
                // ====================================================
                ST_ISSUE_SRC1: begin
                    b_addr  <= src1_addr + j_q;
                    state_q <= ST_RD_SRC1;
                end

                // ====================================================
                // ST_RD_SRC1: src1[j] address on bus.
                // Issue dst[i+j] read so it arrives one cycle later.
                // ====================================================
                ST_RD_SRC1: begin
                    b_addr  <= dst_addr + i_q + j_q;
                    state_q <= ST_RD_DST;
                end

                // ====================================================
                // ST_RD_DST: b_rdata = src1[j]; latch it.
                //            dst[i+j] is now on the address bus.
                // ====================================================
                ST_RD_DST: begin
                    src1_word_q <= b_rdata;
                    state_q     <= ST_COMPUTE;
                end

                // ====================================================
                // ST_COMPUTE: b_rdata = dst[i+j].
                // Stage the write data.  Do NOT set b_we here.
                // ====================================================
                ST_COMPUTE: begin
                    if (op_q == OPC_UMUL) begin
                        umul_prod_q  <= umul_prod_comb;
                        wr_data_q    <= umul_prod_comb[31:0];
                        wr_addr_q    <= dst_addr + i_q + j_q;
                    end else begin
                        // XMUL
                        wr_data_q    <= b_rdata ^ xmul_low_comb;
                        wr_addr_q    <= dst_addr + i_q + j_q;
                        xmul_spill_q <= xmul_high_comb;
                    end
                    state_q <= ST_WR_DST;
                end

                // ====================================================
                // ST_WR_DST: write dst[i+j].
                // Determine where to go next WITHOUT touching b_addr
                // for any read (that is done in the subsequent state).
                // ====================================================
                ST_WR_DST: begin
                    b_addr  <= wr_addr_q;
                    b_wdata <= wr_data_q;
                    b_we    <= 1'b1;

                    if (op_q == OPC_UMUL) begin
                        partial_carry_q <= umul_prod_q[63:32];

                        if (j_q < (nwords1_q - 10'd1)) begin
                            // More inner words: advance j, then issue src1[j+1] read
                            j_q     <= j_q + 10'd1;
                            state_q <= ST_ISSUE_SRC1;
                        end else begin
                            // Inner loop done; go handle carry word
                            state_q <= ST_RD_CARRY;
                        end
                    end else begin
                        // XMUL
                        if (xmul_bit_q != 5'd0 && xmul_spill_q != 32'd0) begin
                            // Has high spill → read dst[i+j+1]
                            state_q <= ST_RD_DST_HI;
                        end else if (j_q < (nwords1_q - 10'd1)) begin
                            // No spill, more inner words
                            j_q     <= j_q + 10'd1;
                            state_q <= ST_ISSUE_SRC1;
                        end else begin
                            // End of j-loop for this bit b
                            // Advance to next set bit or next outer word
                            if (xmul_next_found) begin
                                xmul_bit_q <= xmul_next_bit;
                                j_q        <= 10'd0;
                                state_q    <= ST_ISSUE_SRC1;
                            end else if (i_q < (nwords0_q - 10'd1)) begin
                                i_q     <= i_q + 10'd1;
                                j_q     <= 10'd0;
                                state_q <= ST_ISSUE_SRC0;
                            end else begin
                                mul_done_q <= 1'b1;
                                state_q    <= ST_IDLE;
                            end
                        end
                    end
                end

                // ====================================================
                // ST_RD_CARRY: UMUL — issue read of dst[i+nwords1].
                // (Previous state was ST_WR_DST which only wrote.)
                // ====================================================
                ST_RD_CARRY: begin
                    b_addr  <= dst_addr + i_q + nwords1_q;
                    state_q <= ST_COMPUTE_CARRY;
                end

                // ====================================================
                // ST_COMPUTE_CARRY: b_rdata = dst[i+nwords1].
                // Add carry and stage the write.
                // ====================================================
                ST_COMPUTE_CARRY: begin
                    wr_data_q <= b_rdata + partial_carry_q;
                    wr_addr_q <= dst_addr + i_q + nwords1_q;
                    state_q   <= ST_WR_CARRY;
                end

                // ====================================================
                // ST_WR_CARRY: write dst[i+nwords1]; advance outer loop.
                // ====================================================
                ST_WR_CARRY: begin
                    b_addr          <= wr_addr_q;
                    b_wdata         <= wr_data_q;
                    b_we            <= 1'b1;
                    partial_carry_q <= 32'd0;

                    if (i_q < (nwords0_q - 10'd1)) begin
                        // Advance i; issue src0[i+1] read in NEXT cycle
                        i_q     <= i_q + 10'd1;
                        j_q     <= 10'd0;
                        state_q <= ST_ISSUE_SRC0;
                    end else begin
                        mul_done_q <= 1'b1;
                        state_q    <= ST_IDLE;
                    end
                end

                // ====================================================
                // ST_RD_DST_HI: XMUL — issue read of dst[i+j+1] for spill.
                // (Previous state was ST_WR_DST which only wrote.)
                // ====================================================
                ST_RD_DST_HI: begin
                    b_addr  <= dst_addr + i_q + j_q + 10'd1;
                    state_q <= ST_COMPUTE_HI;
                end

                // ====================================================
                // ST_COMPUTE_HI: b_rdata = dst[i+j+1]. XOR spill; stage write.
                // ====================================================
                ST_COMPUTE_HI: begin
                    wr_data_q <= b_rdata ^ xmul_spill_q;
                    wr_addr_q <= dst_addr + i_q + j_q + 10'd1;
                    state_q   <= ST_WR_DST_HI;
                end

                // ====================================================
                // ST_WR_DST_HI: write dst[i+j+1]; advance inner loop.
                // ====================================================
                ST_WR_DST_HI: begin
                    b_addr  <= wr_addr_q;
                    b_wdata <= wr_data_q;
                    b_we    <= 1'b1;

                    if (j_q < (nwords1_q - 10'd1)) begin
                        // More src1 words for this bit b
                        j_q     <= j_q + 10'd1;
                        state_q <= ST_ISSUE_SRC1;
                    end else begin
                        // End of j-loop for this bit b; advance to next set bit
                        if (xmul_next_found) begin
                            xmul_bit_q <= xmul_next_bit;
                            j_q        <= 10'd0;
                            state_q    <= ST_ISSUE_SRC1;
                        end else if (i_q < (nwords0_q - 10'd1)) begin
                            i_q     <= i_q + 10'd1;
                            j_q     <= 10'd0;
                            state_q <= ST_ISSUE_SRC0;
                        end else begin
                            mul_done_q <= 1'b1;
                            state_q    <= ST_IDLE;
                        end
                    end
                end

                default: state_q <= ST_IDLE;

            endcase
        end
    end

endmodule
