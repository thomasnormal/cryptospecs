// vu_shifter.sv
// VU Shifter for the PSoC 6 Vector Unit.
//
// Supported opcodes (shf_op / op_q):
//   OPC_LSL            (0x20) : dst = src << shift_amt   (N single-bit left passes)
//   OPC_LSL1           (0x21) : dst = src << 1
//   OPC_LSL1_WITH_CARRY(0x22) : dst = (src << 1) | carry_in
//   OPC_LSR            (0x23) : dst = src >> shift_amt   (N single-bit right passes)
//   OPC_LSR1           (0x24) : dst = src >> 1
//   OPC_LSR1_WITH_CARRY(0x25) : dst = (src >> 1) | (carry_in << msb_pos)
//   OPC_CLSAME         (0x26) : count leading bits equal to MSB
//   OPC_CTSAME         (0x27) : count trailing bits equal to LSB
//   OPC_SET_BIT_IMM    (0x2C) : set   bit[shift_amt] in dst
//   OPC_CLR_BIT_IMM    (0x2D) : clear bit[shift_amt] in dst
//   OPC_INV_BIT_IMM    (0x2E) : invert bit[shift_amt] in dst
//
// Memory interface (single port B, synchronous, 1-cycle read latency):
//   Write: b_addr, b_wdata, b_we=1 presented at clock edge T → write completes.
//   Read:  b_addr presented at clock edge T → b_rdata valid at edge T+1.
//
// The FSM uses a strict 4-state-per-word protocol to avoid address conflicts:
//   ST_RD_ISSUE  : drive b_addr = read address; b_we=0.
//   ST_RD_WAIT   : wait one cycle; b_rdata not yet valid.
//   ST_COMPUTE   : b_rdata is valid; compute result; stage into wr_data_q/wr_addr_q.
//   ST_WR        : drive b_addr = wr_addr_q; b_wdata = wr_data_q; b_we=1.
//                  Then transition to ST_RD_ISSUE for next word, or ST_DONE.
//
// CLSAME/CTSAME skip ST_WR (read-only). BIT_IMM uses all four states once.

`include "crypto_pkg.sv"
`include "crypto_isa_pkg.sv"

module vu_shifter
    import crypto_pkg::*;
    import crypto_isa_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    input  logic [7:0]  shf_op,
    input  logic [9:0]  src_addr,
    input  logic [12:0] src_size,       // operand size in bits minus 1
    input  logic [9:0]  dst_addr,
    input  logic [12:0] shift_amt,      // shift amount or bit index
    input  logic        shf_carry_in,
    input  logic        shf_start,
    output logic        shf_done,
    output logic        shf_busy,
    output logic        stat_carry,
    output logic [12:0] stat_count,

    output logic [9:0]  b_addr,
    output logic [31:0] b_wdata,
    output logic        b_we,
    input  logic [31:0] b_rdata
);

    // -----------------------------------------------------------------
    // FSM
    // -----------------------------------------------------------------
    typedef enum logic [2:0] {
        ST_IDLE     = 3'd0,
        ST_RD_ISSUE = 3'd1,
        ST_RD_WAIT  = 3'd2,
        ST_COMPUTE  = 3'd3,
        ST_WR       = 3'd4,
        ST_DONE     = 3'd5
    } state_e;

    state_e state_q;

    // -----------------------------------------------------------------
    // Registers
    // -----------------------------------------------------------------
    logic [9:0]  word_q;        // current word index
    logic [9:0]  nwords_q;      // total words in operand
    logic [4:0]  msb_bit_q;     // index of MSB within top word
    logic [31:0] top_mask_q;    // valid-bit mask for top word
    logic        carry_q;       // inter-word carry
    logic [12:0] loop_cnt_q;    // remaining single-bit passes (LSL/LSR by N)
    logic [9:0]  rd_base_q;     // source base for reads
    logic [12:0] count_q;       // CLSAME/CTSAME counter
    logic        ref_bit_q;     // reference bit
    logic        found_diff_q;  // mismatch found
    logic [9:0]  bimm_word_q;   // BIT_IMM word address
    logic [4:0]  bimm_pos_q;    // BIT_IMM bit position within word
    logic [7:0]  op_q;          // latched opcode
    // Staged write (computed in ST_COMPUTE, applied in ST_WR)
    logic [9:0]  wr_addr_q;
    logic [31:0] wr_data_q;
    logic        carry_next_q;  // carry to propagate after this word

    // -----------------------------------------------------------------
    // Outputs
    // -----------------------------------------------------------------
    assign shf_busy = (state_q != ST_IDLE);
    assign shf_done = (state_q == ST_DONE);

    // -----------------------------------------------------------------
    // Combinational geometry
    // -----------------------------------------------------------------
    logic [13:0] nwords_c;
    logic [4:0]  msb_bit_c;
    logic [31:0] top_mask_c;

    assign nwords_c   = ({1'b0, src_size} + 14'd32) >> 5;
    assign msb_bit_c  = src_size[4:0];
    assign top_mask_c = (msb_bit_c == 5'd31)
                       ? 32'hFFFF_FFFF
                       : (32'hFFFF_FFFF >> (6'd31 - {1'b0, msb_bit_c}));

    // -----------------------------------------------------------------
    // Helper: next read address for shift ops
    // -----------------------------------------------------------------
    function automatic logic [9:0] shift_rd_addr(
        input logic [9:0]  base,
        input logic [9:0]  w
    );
        return base + w;
    endfunction

    // -----------------------------------------------------------------
    // FSM
    // -----------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q      <= ST_IDLE;
            op_q         <= 8'd0;
            word_q       <= 10'd0;
            nwords_q     <= 10'd0;
            msb_bit_q    <= 5'd0;
            top_mask_q   <= 32'hFFFF_FFFF;
            carry_q      <= 1'b0;
            loop_cnt_q   <= 13'd0;
            rd_base_q    <= 10'd0;
            count_q      <= 13'd0;
            ref_bit_q    <= 1'b0;
            found_diff_q <= 1'b0;
            bimm_word_q  <= 10'd0;
            bimm_pos_q   <= 5'd0;
            wr_addr_q    <= 10'd0;
            wr_data_q    <= 32'd0;
            carry_next_q <= 1'b0;
            stat_carry   <= 1'b0;
            stat_count   <= 13'd0;
            b_addr       <= 10'd0;
            b_wdata      <= 32'd0;
            b_we         <= 1'b0;
        end else begin
            b_we <= 1'b0;

            case (state_q)

                // ======================================================
                ST_IDLE: begin
                    if (shf_start) begin
                        op_q         <= shf_op;
                        nwords_q     <= nwords_c[9:0];
                        msb_bit_q    <= msb_bit_c;
                        top_mask_q   <= top_mask_c;
                        count_q      <= 13'd0;
                        found_diff_q <= 1'b0;

                        case (shf_op)
                            OPC_SET_BIT_IMM,
                            OPC_CLR_BIT_IMM,
                            OPC_INV_BIT_IMM: begin
                                bimm_word_q <= shift_amt[12:5];
                                bimm_pos_q  <= shift_amt[4:0];
                                b_addr      <= dst_addr + shift_amt[12:5];
                                state_q     <= ST_RD_WAIT;
                            end

                            OPC_CLSAME: begin
                                word_q  <= nwords_c[9:0] - 10'd1;
                                b_addr  <= src_addr + (nwords_c[9:0] - 10'd1);
                                state_q <= ST_RD_WAIT;
                            end

                            OPC_CTSAME: begin
                                word_q  <= 10'd0;
                                b_addr  <= src_addr;
                                state_q <= ST_RD_WAIT;
                            end

                            OPC_LSL: begin
                                carry_q    <= 1'b0;
                                loop_cnt_q <= shift_amt;
                                rd_base_q  <= src_addr;
                                if (shift_amt == 13'd0)
                                    state_q <= ST_DONE;
                                else begin
                                    word_q  <= 10'd0;
                                    b_addr  <= src_addr;
                                    state_q <= ST_RD_WAIT;
                                end
                            end

                            OPC_LSR: begin
                                carry_q    <= 1'b0;
                                loop_cnt_q <= shift_amt;
                                rd_base_q  <= src_addr;
                                if (shift_amt == 13'd0)
                                    state_q <= ST_DONE;
                                else begin
                                    word_q  <= nwords_c[9:0] - 10'd1;
                                    b_addr  <= src_addr + (nwords_c[9:0] - 10'd1);
                                    state_q <= ST_RD_WAIT;
                                end
                            end

                            OPC_LSL1,
                            OPC_LSL1_WITH_CARRY: begin
                                carry_q   <= (shf_op == OPC_LSL1_WITH_CARRY)
                                             ? shf_carry_in : 1'b0;
                                rd_base_q <= src_addr;
                                word_q    <= 10'd0;
                                b_addr    <= src_addr;
                                state_q   <= ST_RD_WAIT;
                            end

                            OPC_LSR1,
                            OPC_LSR1_WITH_CARRY: begin
                                carry_q   <= (shf_op == OPC_LSR1_WITH_CARRY)
                                             ? shf_carry_in : 1'b0;
                                rd_base_q <= src_addr;
                                word_q    <= nwords_c[9:0] - 10'd1;
                                b_addr    <= src_addr + (nwords_c[9:0] - 10'd1);
                                state_q   <= ST_RD_WAIT;
                            end

                            default: state_q <= ST_DONE;
                        endcase
                    end
                end

                // ======================================================
                // ST_RD_ISSUE: drive next read address (after ST_WR).
                // word_q has already been advanced by ST_COMPUTE/ST_WR.
                // ======================================================
                ST_RD_ISSUE: begin
                    case (op_q)
                        OPC_CLSAME,
                        OPC_CTSAME:       b_addr <= src_addr + word_q;
                        default:           b_addr <= rd_base_q + word_q;
                    endcase
                    state_q <= ST_RD_WAIT;
                end

                // ======================================================
                // ST_RD_WAIT: b_addr issued; wait for b_rdata.
                // ======================================================
                ST_RD_WAIT: begin
                    state_q <= ST_COMPUTE;
                end

                // ======================================================
                // ST_COMPUTE: b_rdata is the word we requested.
                // ======================================================
                ST_COMPUTE: begin
                    case (op_q)

                        // ---- BIT_IMM ----
                        OPC_SET_BIT_IMM,
                        OPC_CLR_BIT_IMM,
                        OPC_INV_BIT_IMM: begin
                            wr_data_q <= (op_q == OPC_SET_BIT_IMM)
                                        ? (b_rdata |  (32'h1 << {27'd0, bimm_pos_q}))
                                        : (op_q == OPC_CLR_BIT_IMM)
                                          ? (b_rdata & ~(32'h1 << {27'd0, bimm_pos_q}))
                                          : (b_rdata ^  (32'h1 << {27'd0, bimm_pos_q}));
                            wr_addr_q <= dst_addr + bimm_word_q;
                            state_q   <= ST_WR;
                        end

                        // ---- CLSAME ----
                        OPC_CLSAME: begin
                            begin : clsame_proc
                                integer      bv;
                                reg          is_top;
                                reg          rb;
                                reg [4:0]    tb;
                                reg [31:0]   wv;
                                reg [31:0]   exp;
                                reg          full;
                                reg [12:0]   lc;

                                is_top = (word_q == (nwords_q - 10'd1));
                                rb     = is_top ? b_rdata[msb_bit_q] : ref_bit_q;
                                tb     = is_top ? msb_bit_q : 5'd31;
                                wv     = is_top ? (b_rdata & top_mask_q) : b_rdata;
                                exp    = is_top ? (rb ? top_mask_q    : 32'd0)
                                               : (rb ? 32'hFFFF_FFFF  : 32'd0);
                                full   = (wv == exp);

                                if (is_top) ref_bit_q <= rb;

                                if (!found_diff_q) begin
                                    if (full) begin
                                        lc = is_top ? ({8'd0, msb_bit_q} + 13'd1) : 13'd32;
                                        count_q <= count_q + lc;
                                    end else begin
                                        lc = 13'd0;
                                        for (bv = 31; bv >= 0; bv--) begin
                                            if (bv <= int'(tb)) begin
                                                if (lc == 13'(int'(tb) - bv)) begin
                                                    if (wv[bv] == rb) lc = lc + 13'd1;
                                                end
                                            end
                                        end
                                        count_q      <= count_q + lc;
                                        found_diff_q <= 1'b1;
                                    end
                                end

                                if ((word_q == 10'd0) || found_diff_q || !full) begin
                                    state_q <= ST_DONE;
                                end else begin
                                    word_q  <= word_q - 10'd1;
                                    state_q <= ST_RD_ISSUE;
                                end
                            end
                        end

                        // ---- CTSAME ----
                        OPC_CTSAME: begin
                            begin : ctsame_proc
                                integer      bv;
                                reg          is_lsw;
                                reg          is_top;
                                reg          rb;
                                reg [4:0]    tb;
                                reg [31:0]   wv;
                                reg [31:0]   exp;
                                reg          full;
                                reg [12:0]   lc;

                                is_lsw = (word_q == 10'd0);
                                is_top = (word_q == (nwords_q - 10'd1));
                                rb     = is_lsw ? b_rdata[0] : ref_bit_q;
                                tb     = is_top ? msb_bit_q : 5'd31;
                                wv     = is_top ? (b_rdata & top_mask_q) : b_rdata;
                                exp    = is_top ? (rb ? top_mask_q    : 32'd0)
                                               : (rb ? 32'hFFFF_FFFF  : 32'd0);
                                full   = (wv == exp);

                                if (is_lsw) ref_bit_q <= rb;

                                if (!found_diff_q) begin
                                    if (full) begin
                                        lc = is_top ? ({8'd0, msb_bit_q} + 13'd1) : 13'd32;
                                        count_q <= count_q + lc;
                                    end else begin
                                        lc = 13'd0;
                                        for (bv = 0; bv < 32; bv++) begin
                                            if (bv <= int'(tb)) begin
                                                if (lc == 13'(bv)) begin
                                                    if (wv[bv] == rb) lc = lc + 13'd1;
                                                end
                                            end
                                        end
                                        count_q      <= count_q + lc;
                                        found_diff_q <= 1'b1;
                                    end
                                end

                                if (is_top || found_diff_q || !full) begin
                                    state_q <= ST_DONE;
                                end else begin
                                    word_q  <= word_q + 10'd1;
                                    state_q <= ST_RD_ISSUE;
                                end
                            end
                        end

                        // ---- LSL1 / LSL1_WITH_CARRY / LSL ----
                        OPC_LSL1,
                        OPC_LSL1_WITH_CARRY,
                        OPC_LSL: begin
                            begin : lsl_proc
                                reg [31:0] sw;
                                reg        nc;
                                nc = b_rdata[31];
                                sw = {b_rdata[30:0], carry_q};
                                if (word_q == (nwords_q - 10'd1))
                                    sw = sw & top_mask_q;
                                carry_next_q <= nc;
                                wr_data_q    <= sw;
                                wr_addr_q    <= dst_addr + word_q;
                                state_q      <= ST_WR;
                            end
                        end

                        // ---- LSR1 / LSR1_WITH_CARRY / LSR ----
                        OPC_LSR1,
                        OPC_LSR1_WITH_CARRY,
                        OPC_LSR: begin
                            begin : lsr_proc
                                reg [31:0] sw;
                                reg        nc;
                                nc = b_rdata[0];
                                if (word_q == (nwords_q - 10'd1))
                                    sw = (({31'd0, carry_q} << {27'd0, msb_bit_q})
                                         | (b_rdata >> 1)) & top_mask_q;
                                else
                                    sw = {carry_q, b_rdata[31:1]};
                                carry_next_q <= nc;
                                wr_data_q    <= sw;
                                wr_addr_q    <= dst_addr + word_q;
                                state_q      <= ST_WR;
                            end
                        end

                        default: state_q <= ST_DONE;
                    endcase
                end

                // ======================================================
                // ST_WR: write wr_data_q to wr_addr_q.
                // Advance word_q and loop state, then go to ST_RD_ISSUE.
                // b_addr = wr_addr_q (WRITE); no read-address competition.
                // ======================================================
                ST_WR: begin
                    b_addr  <= wr_addr_q;
                    b_wdata <= wr_data_q;
                    b_we    <= 1'b1;

                    case (op_q)
                        OPC_SET_BIT_IMM,
                        OPC_CLR_BIT_IMM,
                        OPC_INV_BIT_IMM: state_q <= ST_DONE;

                        OPC_LSL1,
                        OPC_LSL1_WITH_CARRY,
                        OPC_LSL: begin
                            carry_q <= carry_next_q;
                            if (word_q == (nwords_q - 10'd1)) begin
                                if (op_q != OPC_LSL) begin
                                    stat_carry <= carry_next_q;
                                    state_q    <= ST_DONE;
                                end else if (loop_cnt_q <= 13'd1) begin
                                    stat_carry <= carry_next_q;
                                    state_q    <= ST_DONE;
                                end else begin
                                    loop_cnt_q <= loop_cnt_q - 13'd1;
                                    carry_q    <= 1'b0;
                                    rd_base_q  <= dst_addr;
                                    word_q     <= 10'd0;
                                    state_q    <= ST_RD_ISSUE;
                                end
                            end else begin
                                word_q  <= word_q + 10'd1;
                                state_q <= ST_RD_ISSUE;
                            end
                        end

                        OPC_LSR1,
                        OPC_LSR1_WITH_CARRY,
                        OPC_LSR: begin
                            carry_q <= carry_next_q;
                            if (word_q == 10'd0) begin
                                if (op_q != OPC_LSR) begin
                                    stat_carry <= carry_next_q;
                                    state_q    <= ST_DONE;
                                end else if (loop_cnt_q <= 13'd1) begin
                                    stat_carry <= carry_next_q;
                                    state_q    <= ST_DONE;
                                end else begin
                                    loop_cnt_q <= loop_cnt_q - 13'd1;
                                    carry_q    <= 1'b0;
                                    rd_base_q  <= dst_addr;
                                    word_q     <= nwords_q - 10'd1;
                                    state_q    <= ST_RD_ISSUE;
                                end
                            end else begin
                                word_q  <= word_q - 10'd1;
                                state_q <= ST_RD_ISSUE;
                            end
                        end

                        default: state_q <= ST_DONE;
                    endcase
                end

                // ======================================================
                ST_DONE: begin
                    stat_count <= count_q;
                    state_q    <= ST_IDLE;
                end

                default: state_q <= ST_IDLE;
            endcase
        end
    end

endmodule
