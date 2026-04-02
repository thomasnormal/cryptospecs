// PSoC 6 Crypto — VU Controller
//
// Decodes VU instruction words, evaluates condition codes, dispatches to
// sub-modules (ALU, shifter, multiplier), handles register-file and stack ops.
//
// STATUS register bits (vu_status[3:0]):
//   [0] CARRY, [1] EVEN, [2] ZERO, [3] ONE

`include "crypto_pkg.sv"
`include "crypto_isa_pkg.sv"

module vu_controller
    import crypto_pkg::*;
    import crypto_isa_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    // From instruction decoder
    input  logic [31:0] vu_instr,
    input  logic        vu_start,
    output logic        vu_busy,

    // STATUS register
    output logic [3:0]  vu_status,

    // Register-file write port A (data+size+addr)
    output logic [3:0]  rf_rd_idx,
    output logic [31:0] rf_rd_data,
    output logic [12:0] rf_rd_size,
    output logic [9:0]  rf_rd_addr,
    output logic        rf_rd_we,

    // Register-file write port B (addr+size for ALLOC_MEM)
    output logic [3:0]  rf_rd2_idx,
    output logic [12:0] rf_rd2_size,
    output logic [9:0]  rf_rd2_addr,
    output logic        rf_rd2_we,

    // Register-file read port C
    output logic [3:0]  rs0_idx,
    input  logic [31:0] rs0_data,
    input  logic [12:0] rs0_size,
    input  logic [9:0]  rs0_addr,

    // Register-file read port D
    output logic [3:0]  rs1_idx,
    input  logic [31:0] rs1_data,
    input  logic [12:0] rs1_size,
    input  logic [9:0]  rs1_addr,

    // Stack pointer (r15.data[9:0])
    input  logic [9:0]  sp_addr,

    // All register sizes for FREE_MEM computation
    input  logic [12:0] rf_size_all [0:15],

    // All register data values for PUSH
    input  logic [31:0] rf_data_all [0:15],

    // Sub-module: ALU
    output logic        alu_start,
    output logic [7:0]  alu_op,
    output logic [9:0]  alu_src0_addr,
    output logic [12:0] alu_src0_size,
    output logic [9:0]  alu_src1_addr,
    output logic [9:0]  alu_dst_addr,
    output logic        alu_carry_in,
    input  logic        alu_done,
    input  logic        alu_stat_carry,
    input  logic        alu_stat_zero,
    input  logic        alu_stat_even,
    input  logic        alu_stat_one,

    // Sub-module: shifter
    output logic        shf_start,
    output logic [7:0]  shf_op,
    output logic [9:0]  shf_src_addr,
    output logic [12:0] shf_src_size,
    output logic [9:0]  shf_dst_addr,
    output logic [12:0] shf_shift_amt,
    output logic        shf_carry_in,
    input  logic        shf_done,
    input  logic        shf_stat_carry,
    input  logic [12:0] shf_stat_count,

    // Sub-module: multiplier
    output logic        mul_start,
    output logic [7:0]  mul_op,
    output logic [9:0]  mul_src0_addr,
    output logic [12:0] mul_src0_size,
    output logic [9:0]  mul_src1_addr,
    output logic [12:0] mul_src1_size,
    output logic [9:0]  mul_dst_addr,
    output logic [12:0] mul_dst_size,
    input  logic        mul_done,

    // Direct mem_buffer B port (for LD_REG / ST_REG / PUSH / POP)
    output logic [9:0]  mb_b_addr,
    output logic [31:0] mb_b_wdata,
    output logic        mb_b_we,
    input  logic [31:0] mb_b_rdata,
    output logic        mb_b_own    // 1 = controller owns port B
);

    // ------------------------------------------------------------------
    // Condition code evaluation
    // ------------------------------------------------------------------
    function automatic logic eval_cc(input logic [3:0] cc, input logic [3:0] st);
        logic carry, even, zero, one;
        carry = st[VU_STATUS_CARRY]; even = st[VU_STATUS_EVEN];
        zero  = st[VU_STATUS_ZERO];  one  = st[VU_STATUS_ONE];
        unique case (cc)
            4'h0: return 1'b1;          // ALWAYS
            4'h1: return  zero;         // EQ
            4'h2: return ~zero;         // NE
            4'h3: return  carry;        // CS
            4'h4: return ~carry;        // CC
            4'h5: return  carry & ~zero;// HI
            4'h6: return ~carry |  zero;// LS
            4'h7: return  even;         // EVEN
            4'h8: return ~even;         // ODD
            4'h9: return  one;          // ONE
            4'hA: return ~one;          // NOT_ONE
            default: return 1'b1;
        endcase
    endfunction

    // nwords: ceil((size_bits_minus_1 + 1) / 32)
    function automatic logic [9:0] sz2w(input logic [12:0] sz);
        return {3'h0, sz[12:5]} + (|sz[4:0] ? 10'd1 : 10'd0);
    endfunction

    // free_mem total words from bitmask
    function automatic logic [9:0] free_words(
        input logic [15:0] mask, input logic [12:0] szs [0:15]
    );
        logic [9:0] tot;
        tot = '0;
        for (int k = 0; k < 15; k++)
            if (mask[k]) tot = tot + sz2w(szs[k]);
        return tot;
    endfunction

    // ------------------------------------------------------------------
    // Instruction field decode (combinational)
    // ------------------------------------------------------------------
    logic [7:0]  iw_opc;
    logic [3:0]  iw_cc, iw_dst, iw_src1, iw_src0;
    logic [12:0] iw_sz, iw_imm13;
    logic [3:0]  iw_sr_dst;
    logic        is_set_reg;

    assign iw_opc    = vu_instr[31:24];
    assign iw_cc     = vu_instr[IW_CC_HI:IW_CC_LO];
    assign iw_dst    = vu_instr[IW_DST_HI:IW_DST_LO];
    assign iw_src1   = vu_instr[IW_SRC1_HI:IW_SRC1_LO];
    assign iw_src0   = vu_instr[IW_SRC0_HI:IW_SRC0_LO];
    assign iw_sz     = vu_instr[IW_SETREG_SIZE_HI:IW_SETREG_SIZE_LO];
    assign iw_imm13  = vu_instr[IW_SETREG_DATA_HI:IW_SETREG_DATA_LO];
    assign iw_sr_dst = vu_instr[IW_SETREG_DST_HI:IW_SETREG_DST_LO];
    assign is_set_reg = (vu_instr[IW_SETREG_OPC_HI:IW_SETREG_OPC_LO] == SETREG_OPC_PATTERN);

    // Route register read ports
    assign rs0_idx = is_set_reg ? iw_sr_dst : iw_src0;
    assign rs1_idx = iw_src1;

    // ------------------------------------------------------------------
    // STATE
    // ------------------------------------------------------------------
    typedef enum logic [2:0] {
        ST_IDLE   = 3'd0,
        ST_EXEC   = 3'd1,
        ST_WAIT   = 3'd2,
        ST_MEM_RD = 3'd3,
        ST_PUSH   = 3'd4,
        ST_POP    = 3'd5
    } state_t;

    state_t      state_q;
    logic [31:0] iw_q;          // latched instruction
    logic [3:0]  status_q;
    logic [3:0]  iter_q;        // PUSH/POP word counter
    logic [9:0]  sp_snap_q;     // SP snapshot for PUSH/POP
    logic [3:0]  ld_dst_q;      // LD_REG destination register
    logic [1:0]  sub_q;         // 0=ALU 1=SHF 2=MUL
    logic        pop_rd_valid_q;// POP: have issued first read

    assign vu_status = status_q;

    // ------------------------------------------------------------------
    // reg_alu helper
    // ------------------------------------------------------------------
    function automatic logic [31:0] reg_alu(
        input logic [7:0] op, input logic [31:0] d0, d1
    );
        unique case (op)
            OPC_ADD_REG : return d1 + d0;
            OPC_SUB_REG : return d1 - d0;
            OPC_OR_REG  : return d1 | d0;
            OPC_AND_REG : return d1 & d0;
            OPC_XOR_REG : return d1 ^ d0;
            OPC_NOR_REG : return ~(d1 | d0);
            OPC_NAND_REG: return ~(d1 & d0);
            OPC_MIN_REG : return (d0 < d1) ? d0 : d1;
            OPC_MAX_REG : return (d0 > d1) ? d0 : d1;
            default     : return d0;
        endcase
    endfunction

    // ------------------------------------------------------------------
    // RF write helper
    // ------------------------------------------------------------------
    task automatic rf_write(
        input logic [3:0]  idx,
        input logic [31:0] data,
        input logic [12:0] sz,
        input logic [9:0]  addr
    );
        rf_rd_idx  <= idx;
        rf_rd_data <= data;
        rf_rd_size <= sz;
        rf_rd_addr <= addr;
        rf_rd_we   <= 1'b1;
    endtask

    // ------------------------------------------------------------------
    // Sequential FSM
    // ------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin : p_fsm
        if (!rst_n) begin
            state_q      <= ST_IDLE;
            vu_busy      <= 1'b0;
            status_q     <= 4'b0000;
            iw_q         <= '0;
            iter_q       <= '0;
            sp_snap_q    <= '0;
            ld_dst_q     <= '0;
            sub_q        <= 2'd0;
            pop_rd_valid_q <= 1'b0;
            rf_rd_we     <= 1'b0;
            rf_rd2_we    <= 1'b0;
            alu_start    <= 1'b0;
            shf_start    <= 1'b0;
            mul_start    <= 1'b0;
            mb_b_own     <= 1'b0;
            mb_b_we      <= 1'b0;
            mb_b_addr    <= '0;
            mb_b_wdata   <= '0;
        end else begin
            rf_rd_we  <= 1'b0;
            rf_rd2_we <= 1'b0;
            alu_start <= 1'b0;
            shf_start <= 1'b0;
            mul_start <= 1'b0;
            mb_b_we   <= 1'b0;
            mb_b_own  <= 1'b0;

            unique case (state_q)

                // ------------------------------------------------
                ST_IDLE: begin
                    if (vu_start) begin
                        iw_q    <= vu_instr;
                        vu_busy <= 1'b1;
                        state_q <= ST_EXEC;
                    end
                end

                // ------------------------------------------------
                ST_EXEC: begin : exec
                    logic [7:0]  op;
                    logic [3:0]  dst, s1, s0;
                    logic [31:0] d0, d1;
                    logic [12:0] sz0, sz1;
                    logic [9:0]  a0, a1, asp;
                    logic        cc_ok;

                    op  = iw_q[31:24];
                    dst = iw_q[IW_DST_HI:IW_DST_LO];
                    s1  = iw_q[IW_SRC1_HI:IW_SRC1_LO];
                    s0  = iw_q[IW_SRC0_HI:IW_SRC0_LO];
                    d0  = rs0_data; sz0 = rs0_size; a0 = rs0_addr;
                    d1  = rs1_data; sz1 = rs1_size; a1 = rs1_addr;
                    asp = sp_addr;
                    cc_ok = eval_cc(iw_q[IW_CC_HI:IW_CC_LO], status_q);

                    // Default: retire instruction
                    vu_busy <= 1'b0;
                    state_q <= ST_IDLE;

                    if (iw_q[IW_SETREG_OPC_HI:IW_SETREG_OPC_LO] == SETREG_OPC_PATTERN) begin
                        // SET_REG — always executes (no CC)
                        rf_write(iw_q[IW_SETREG_DST_HI:IW_SETREG_DST_LO],
                                 {19'h0, iw_q[IW_SETREG_DATA_HI:IW_SETREG_DATA_LO]},
                                 iw_q[IW_SETREG_SIZE_HI:IW_SETREG_SIZE_LO],
                                 a0);  // preserve existing addr
                    end else if (!cc_ok) begin
                        // Condition failed; skip
                    end else begin
                        unique casez (op)
                            OPC_MOV_REG:
                                rf_write(dst, d0, sz0, a0);

                            OPC_SWAP_REG: begin
                                rf_write(s0, d1, sz1, a1);  // move src1→src0 slot
                                rf_rd2_idx  <= s1;
                                rf_rd2_size <= sz0;
                                rf_rd2_addr <= a0;
                                rf_rd2_we   <= 1'b1;
                                // data of s1 not written (port B is addr/size only)
                            end

                            OPC_MOV_REG_TO_STATUS:
                                status_q <= d0[3:0];

                            OPC_MOV_STATUS_TO_REG:
                                rf_write(dst, {28'h0, status_q}, sz0, a0);

                            OPC_MOV_IMM_TO_STATUS:
                                status_q <= iw_q[3:0];

                            OPC_ADD_REG, OPC_SUB_REG, OPC_OR_REG, OPC_AND_REG,
                            OPC_XOR_REG, OPC_NOR_REG, OPC_NAND_REG,
                            OPC_MIN_REG, OPC_MAX_REG:
                                rf_write(dst, reg_alu(op, d0, d1), sz0, a0);

                            OPC_ALLOC_MEM: begin : alloc
                                logic [12:0] imm_a;
                                logic [9:0]  nw_a, new_sp_a;
                                imm_a    = iw_q[IW_ALLOC_IMM_HI:IW_ALLOC_IMM_LO];
                                nw_a     = sz2w(imm_a);
                                new_sp_a = asp - nw_a;
                                // Update SP (r15.data)
                                rf_write(VU_REG_SP[3:0],
                                         {22'h0, new_sp_a},
                                         rf_size_all[VU_REG_SP],
                                         new_sp_a);
                                // Set dst register's addr/size
                                rf_rd2_idx  <= iw_q[IW_ALLOC_DST_HI:IW_ALLOC_DST_LO];
                                rf_rd2_size <= imm_a;
                                rf_rd2_addr <= new_sp_a;
                                rf_rd2_we   <= 1'b1;
                            end : alloc

                            OPC_FREE_MEM: begin : free
                                logic [9:0] fw;
                                fw = free_words(iw_q[15:0], rf_size_all);
                                rf_write(VU_REG_SP[3:0],
                                         {22'h0, asp + fw},
                                         rf_size_all[VU_REG_SP],
                                         asp + fw);
                            end : free

                            OPC_LD_REG: begin
                                mb_b_addr <= asp + d0[9:0];
                                mb_b_we   <= 1'b0;
                                mb_b_own  <= 1'b1;
                                ld_dst_q  <= s1;
                                vu_busy   <= 1'b1;
                                state_q   <= ST_MEM_RD;
                            end

                            OPC_ST_REG: begin
                                mb_b_addr  <= asp + d0[9:0];
                                mb_b_wdata <= d1;
                                mb_b_we    <= 1'b1;
                                mb_b_own   <= 1'b1;
                            end

                            OPC_PUSH_REG: begin
                                // Allocate 15 words on stack
                                rf_write(VU_REG_SP[3:0],
                                         {22'h0, asp - 10'd15},
                                         rf_size_all[VU_REG_SP],
                                         asp - 10'd15);
                                sp_snap_q <= asp - 10'd15;
                                iter_q    <= 4'd0;
                                vu_busy   <= 1'b1;
                                state_q   <= ST_PUSH;
                            end

                            OPC_POP_REG: begin
                                sp_snap_q    <= asp;
                                iter_q       <= 4'd0;
                                pop_rd_valid_q <= 1'b0;
                                mb_b_addr    <= asp;
                                mb_b_we      <= 1'b0;
                                mb_b_own     <= 1'b1;
                                vu_busy      <= 1'b1;
                                state_q      <= ST_POP;
                            end

                            // Memory ALU ops
                            OPC_ADD, OPC_SUB,
                            OPC_VU_OR, OPC_VU_AND, OPC_VU_XOR,
                            OPC_VU_NOR, OPC_VU_NAND,
                            OPC_MOV, OPC_SET_TO_ZERO, OPC_SET_TO_ONE,
                            OPC_CMP_SUB, OPC_TST,
                            OPC_ADD_WITH_CARRY, OPC_SUB_WITH_CARRY: begin
                                alu_op        <= op;
                                alu_src0_addr <= a0;
                                alu_src0_size <= sz0;
                                alu_src1_addr <= a1;
                                alu_dst_addr  <= rf_data_all[dst][9:0];
                                alu_carry_in  <= status_q[VU_STATUS_CARRY];
                                alu_start     <= 1'b1;
                                sub_q         <= 2'd0;
                                vu_busy       <= 1'b1;
                                state_q       <= ST_WAIT;
                            end

                            // Shift ops
                            OPC_LSL, OPC_LSL1, OPC_LSL1_WITH_CARRY,
                            OPC_LSR, OPC_LSR1, OPC_LSR1_WITH_CARRY,
                            OPC_CLSAME, OPC_CTSAME,
                            OPC_SET_BIT_IMM, OPC_CLR_BIT_IMM, OPC_INV_BIT_IMM: begin
                                shf_op        <= op;
                                shf_src_addr  <= a0;
                                shf_src_size  <= sz0;
                                shf_dst_addr  <= rf_data_all[dst][9:0];
                                shf_shift_amt <= (op == OPC_LSL || op == OPC_LSR) ?
                                                  d1[12:0] : iw_q[12:0];
                                shf_carry_in  <= status_q[VU_STATUS_CARRY];
                                shf_start     <= 1'b1;
                                sub_q         <= 2'd1;
                                vu_busy       <= 1'b1;
                                state_q       <= ST_WAIT;
                            end

                            // Multiply ops
                            OPC_UMUL, OPC_XMUL, OPC_USQUARE, OPC_XSQUARE: begin
                                mul_op        <= op;
                                mul_src0_addr <= a0;
                                mul_src0_size <= sz0;
                                mul_src1_addr <= (op == OPC_USQUARE || op == OPC_XSQUARE) ?
                                                  a0 : a1;
                                mul_src1_size <= (op == OPC_USQUARE || op == OPC_XSQUARE) ?
                                                  sz0 : sz1;
                                mul_dst_addr  <= rf_data_all[dst][9:0];
                                mul_dst_size  <= sz0 + sz1 + 13'd1; // upper-bound size
                                mul_start     <= 1'b1;
                                sub_q         <= 2'd2;
                                vu_busy       <= 1'b1;
                                state_q       <= ST_WAIT;
                            end

                            default: ; // unknown: skip
                        endcase
                    end
                end : exec

                // ------------------------------------------------
                ST_MEM_RD: begin
                    // b_rdata now valid
                    rf_write(ld_dst_q, mb_b_rdata, 13'd31, mb_b_addr);
                    vu_busy <= 1'b0;
                    state_q <= ST_IDLE;
                end

                // ------------------------------------------------
                ST_PUSH: begin
                    // Write rf_data_all[iter_q] to stack
                    mb_b_addr  <= sp_snap_q + {6'h0, iter_q};
                    mb_b_wdata <= rf_data_all[iter_q];
                    mb_b_we    <= 1'b1;
                    mb_b_own   <= 1'b1;
                    if (iter_q == 4'd14) begin
                        vu_busy <= 1'b0;
                        state_q <= ST_IDLE;
                    end else
                        iter_q <= iter_q + 4'd1;
                end

                // ------------------------------------------------
                ST_POP: begin
                    mb_b_own <= 1'b1;
                    if (!pop_rd_valid_q) begin
                        // First read issued in ST_EXEC; wait one cycle
                        pop_rd_valid_q <= 1'b1;
                        mb_b_addr <= sp_snap_q + {6'h0, iter_q};
                    end else begin
                        // b_rdata valid for iter_q-1 (or first if iter_q==0)
                        rf_write(iter_q, mb_b_rdata, 13'd31,
                                 sp_snap_q + {6'h0, iter_q});
                        if (iter_q == 4'd14) begin
                            // Also update SP += 15
                            rf_rd2_idx  <= VU_REG_SP[3:0];
                            rf_rd2_size <= rf_size_all[VU_REG_SP];
                            rf_rd2_addr <= sp_snap_q + 10'd15;
                            rf_rd2_we   <= 1'b1;
                            vu_busy     <= 1'b0;
                            state_q     <= ST_IDLE;
                        end else begin
                            iter_q    <= iter_q + 4'd1;
                            mb_b_addr <= sp_snap_q + {6'h0, iter_q + 4'd1};
                        end
                    end
                end

                // ------------------------------------------------
                ST_WAIT: begin
                    unique case (sub_q)
                        2'd0: begin // ALU
                            if (alu_done) begin
                                status_q <= {alu_stat_one, alu_stat_zero,
                                             alu_stat_even, alu_stat_carry};
                                vu_busy  <= 1'b0;
                                state_q  <= ST_IDLE;
                            end
                        end
                        2'd1: begin // Shifter
                            if (shf_done) begin
                                status_q[VU_STATUS_CARRY] <= shf_stat_carry;
                                vu_busy  <= 1'b0;
                                state_q  <= ST_IDLE;
                            end
                        end
                        2'd2: begin // Multiplier
                            if (mul_done) begin
                                vu_busy  <= 1'b0;
                                state_q  <= ST_IDLE;
                            end
                        end
                        default: begin
                            vu_busy <= 1'b0;
                            state_q <= ST_IDLE;
                        end
                    endcase
                end

                default: state_q <= ST_IDLE;

            endcase
        end
    end

endmodule
