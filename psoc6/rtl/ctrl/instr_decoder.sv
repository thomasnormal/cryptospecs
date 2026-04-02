// PSoC 6 Crypto — Instruction Decoder / Dispatcher
//
// Fetches 32-bit instruction words from instr_fifo and dispatches to
// engines.  Implements the IDLE→FETCH1→[FETCH2→FETCH3]→DISPATCH→WAIT→IDLE
// pipeline described in the plan.
//
// Multi-word instructions (FF_START, FF_CONTINUE = 3 words) are buffered
// before dispatch.  All other instructions are single-word.
//
// AES, SHA, DES, CRC, block-ops, and FIFO commands are dispatched via
// dedicated start pulses.  VU instructions are forwarded as a 32-bit word.

`include "crypto_pkg.sv"
`include "crypto_isa_pkg.sv"

module instr_decoder
    import crypto_pkg::*;
    import crypto_isa_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    // From instruction FIFO
    input  logic [31:0] instr_data,
    output logic        instr_pop,
    input  logic        instr_empty,

    // Register & block operation interface (→ reg_buffer)
    output logic [7:0]  bop_opcode,
    output logic [3:0]  bop_src0,
    output logic [3:0]  bop_src1,
    output logic [3:0]  bop_dst,
    output logic [3:0]  bop_size,
    output logic [7:0]  bop_byte,
    output logic        bop_reflect,
    output logic        bop_start,
    input  logic        bop_done,
    output logic        rbuf_clear,
    output logic        rbuf_swap,

    // Load/store FIFO (→ load_store_fifo)
    output logic [3:0]  ff_id,
    output logic [31:0] ff_addr,
    output logic [31:0] ff_size,
    output logic        ff_start,
    output logic        ff_continue,
    output logic        ff_stop,
    input  logic        ff_done,

    // STORE staging arm: instructs load_store_fifo to latch st_staging
    output logic [3:0]  st_arm_src,   // block ID to latch as store source
    output logic        st_arm_valid,

    // AES (→ aes_core)
    output logic        aes_start,
    output logic        aes_decrypt,  // 0=encrypt, 1=decrypt
    input  logic        aes_busy,

    // SHA (→ sha_*_core via arbiter in crypto_top)
    output logic [2:0]  sha_mode,     // SHA_CTL.MODE
    output logic        sha_start,
    input  logic        sha_busy,

    // DES (→ des_core)
    output logic [3:0]  des_mode,     // {tdes, inv}
    output logic        des_start,
    input  logic        des_busy,

    // CRC (→ crc_engine; register-triggered, but decoder pulses start)
    output logic        crc_start,
    input  logic        crc_busy,

    // VU (→ vu_top)
    output logic [31:0] vu_instr,
    output logic        vu_start,
    input  logic        vu_busy,

    // AES configuration from AES_CTL register
    input  logic [1:0]  aes_key_size, // AES_KEY128/192/256

    // SHA configuration from SHA_CTL register
    input  logic [2:0]  sha_ctl_mode,

    // Error outputs (→ INTR register)
    output logic        opc_error,    // unknown opcode
    output logic        cc_error,     // undefined condition code

    // Decoder busy (→ STATUS.CMD_FF_BUSY)
    output logic        decoder_busy
);

    // ------------------------------------------------------------------
    // State machine
    // ------------------------------------------------------------------
    typedef enum logic [2:0] {
        ST_IDLE     = 3'd0,
        ST_FETCH1   = 3'd1,  // read IW0
        ST_FETCH2   = 3'd2,  // read IW1 (3-word instructions)
        ST_FETCH3   = 3'd3,  // read IW2 (3-word instructions)
        ST_DISPATCH = 3'd4,  // issue engine start
        ST_WAIT     = 3'd5   // wait for engine done
    } dec_state_e;

    dec_state_e state_q;

    logic [31:0] iw0_q, iw1_q, iw2_q; // buffered instruction words
    logic [7:0]  opc_q;
    logic        three_word_q;          // current instruction is 3 words

    // ------------------------------------------------------------------
    // Opcode extraction helpers
    // ------------------------------------------------------------------
    wire [7:0]  opc     = instr_data[IW_OPC_HI:IW_OPC_LO];
    wire [1:0]  opc2    = instr_data[IW_SETREG_OPC_HI:IW_SETREG_OPC_LO];
    wire        is_3w   = (opc == OPC_FF_START) || (opc == OPC_FF_CONTINUE);

    // ------------------------------------------------------------------
    // Default outputs
    // ------------------------------------------------------------------
    always_comb begin
        instr_pop    = 1'b0;
        bop_opcode   = '0; bop_src0 = '0; bop_src1 = '0; bop_dst = '0;
        bop_size     = '0; bop_byte = '0; bop_reflect = 1'b0;
        bop_start    = 1'b0; rbuf_clear = 1'b0; rbuf_swap = 1'b0;
        ff_id = '0; ff_addr = '0; ff_size = '0;
        ff_start = 1'b0; ff_continue = 1'b0; ff_stop = 1'b0;
        st_arm_src = '0; st_arm_valid = 1'b0;
        aes_start = 1'b0; aes_decrypt = 1'b0;
        sha_mode = '0; sha_start = 1'b0;
        des_mode = '0; des_start = 1'b0;
        crc_start = 1'b0;
        vu_instr = '0; vu_start = 1'b0;
        opc_error = 1'b0; cc_error = 1'b0;
        decoder_busy = (state_q != ST_IDLE);
    end

    // ------------------------------------------------------------------
    // FSM
    // ------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q      <= ST_IDLE;
            iw0_q <= '0; iw1_q <= '0; iw2_q <= '0;
            opc_q <= '0; three_word_q <= 1'b0;
        end else begin
            unique case (state_q)

                ST_IDLE: begin
                    if (!instr_empty) begin
                        state_q <= ST_FETCH1;
                    end
                end

                ST_FETCH1: begin
                    if (!instr_empty) begin
                        instr_pop    <= 1'b1;
                        iw0_q        <= instr_data;
                        opc_q        <= opc;
                        three_word_q <= is_3w;
                        state_q      <= is_3w ? ST_FETCH2 : ST_DISPATCH;
                    end
                end

                ST_FETCH2: begin
                    instr_pop <= 1'b0;
                    if (!instr_empty) begin
                        instr_pop <= 1'b1;
                        iw1_q     <= instr_data;
                        state_q   <= ST_FETCH3;
                    end
                end

                ST_FETCH3: begin
                    instr_pop <= 1'b0;
                    if (!instr_empty) begin
                        instr_pop <= 1'b1;
                        iw2_q     <= instr_data;
                        state_q   <= ST_DISPATCH;
                    end
                end

                ST_DISPATCH: begin
                    instr_pop <= 1'b0;
                    dispatch_instr();
                    state_q <= ST_WAIT;
                end

                ST_WAIT: begin
                    if (wait_done()) state_q <= ST_IDLE;
                end

                default: state_q <= ST_IDLE;
            endcase
        end
    end

    // ------------------------------------------------------------------
    // Dispatch task
    // ------------------------------------------------------------------
    task automatic dispatch_instr();
        logic [7:0] op;
        op = opc_q;

        // SET_REG: detect by [31:30] = 2'b10 (overrides byte 3 opcode)
        if (iw0_q[IW_SETREG_OPC_HI:IW_SETREG_OPC_LO] == SETREG_OPC_PATTERN) begin
            vu_instr  = iw0_q;
            vu_start  = 1'b1;
            return;
        end

        unique casez (op)
            // ---- Block operations ----
            OPC_BLOCK_MOV: begin
                bop_opcode  = OPC_BLOCK_MOV;
                bop_reflect = iw0_q[IW_BMOV_REFLECT];
                bop_size    = iw0_q[IW_BMOV_SIZE_HI:IW_BMOV_SIZE_LO];
                bop_dst     = iw0_q[IW_BMOV_DST_HI:IW_BMOV_DST_LO];
                bop_src0    = iw0_q[IW_BMOV_SRC0_HI:IW_BMOV_SRC0_LO];
                // If dst is STORE_FIFO (12), arm the store staging
                if (bop_dst == BLKID_STORE_FIFO) begin
                    st_arm_src   = bop_src0;
                    st_arm_valid = 1'b1;
                end else begin
                    bop_start = 1'b1;
                end
            end
            OPC_BLOCK_XOR: begin
                bop_opcode = OPC_BLOCK_XOR;
                bop_size   = iw0_q[IW_BXOR_SIZE_HI:IW_BXOR_SIZE_LO];
                bop_dst    = iw0_q[IW_BXOR_DST_HI:IW_BXOR_DST_LO];
                bop_src1   = iw0_q[IW_BXOR_SRC1_HI:IW_BXOR_SRC1_LO];
                bop_src0   = iw0_q[IW_BXOR_SRC0_HI:IW_BXOR_SRC0_LO];
                bop_start  = 1'b1;
            end
            OPC_BLOCK_SET: begin
                bop_opcode = OPC_BLOCK_SET;
                bop_size   = iw0_q[IW_BSET_SIZE_HI:IW_BSET_SIZE_LO];
                bop_dst    = iw0_q[IW_BSET_DST_HI:IW_BSET_DST_LO];
                bop_byte   = iw0_q[IW_BSET_BYTE_HI:IW_BSET_BYTE_LO];
                bop_start  = 1'b1;
            end
            OPC_BLOCK_CMP_GCM: begin
                bop_opcode = OPC_BLOCK_CMP_GCM;
                bop_size   = iw0_q[IW_BCMP_SIZE_HI:IW_BCMP_SIZE_LO];
                bop_src1   = iw0_q[IW_BCMP_SRC1_HI:IW_BCMP_SRC1_LO];
                bop_src0   = iw0_q[IW_BCMP_SRC0_HI:IW_BCMP_SRC0_LO];
                bop_start  = 1'b1;
            end

            // ---- Register buffer ops ----
            OPC_CLEAR:    rbuf_clear = 1'b1;
            OPC_SWAP:     rbuf_swap  = 1'b1;
            OPC_REGB_XOR, OPC_STORE, OPC_BYTE_SET: begin
                // Phase 1 stub: treated as NOP (full impl in SHA phase)
                ;
            end

            // ---- FIFO stream instructions ----
            OPC_FF_START: begin
                ff_id       = iw0_q[IW_FF_ID_HI:IW_FF_ID_LO];
                ff_addr     = iw1_q;
                ff_size     = iw2_q;
                ff_start    = 1'b1;
            end
            OPC_FF_CONTINUE: begin
                ff_id       = iw0_q[IW_FF_ID_HI:IW_FF_ID_LO];
                ff_addr     = iw1_q;
                ff_size     = iw2_q;
                ff_continue = 1'b1;
            end
            OPC_FF_STOP: begin
                ff_id  = iw0_q[IW_FF_ID_HI:IW_FF_ID_LO];
                ff_stop = 1'b1;
            end

            // ---- AES ----
            OPC_AES: begin
                aes_start   = 1'b1;
                aes_decrypt = 1'b0;
            end
            OPC_AES_INV: begin
                aes_start   = 1'b1;
                aes_decrypt = 1'b1;
            end

            // ---- SHA ----
            OPC_SHA1, OPC_SHA2_256, OPC_SHA2_512, OPC_SHA3: begin
                sha_mode  = sha_ctl_mode;
                sha_start = 1'b1;
            end

            // ---- DES ----
            OPC_DES:      begin des_mode = 4'b0000; des_start = 1'b1; end
            OPC_DES_INV:  begin des_mode = 4'b0001; des_start = 1'b1; end
            OPC_TDES:     begin des_mode = 4'b0010; des_start = 1'b1; end
            OPC_TDES_INV: begin des_mode = 4'b0011; des_start = 1'b1; end

            // ---- CRC ----
            OPC_CRC: begin
                crc_start = 1'b1;
            end

            // ---- VU (all opcodes 0x00–0x3F and 0x0F, etc.) ----
            8'h00, 8'h01, 8'h02, 8'h03, 8'h04, 8'h05,
            8'h06, 8'h07, 8'h08, 8'h09, 8'h0A, 8'h0B,
            8'h0C, 8'h0D, 8'h0E, 8'h0F, 8'h10, 8'h11,
            8'h12, 8'h13, 8'h14, 8'h15, 8'h20, 8'h21,
            8'h22, 8'h23, 8'h24, 8'h25, 8'h26, 8'h27,
            8'h28, 8'h29, 8'h2A, 8'h2B, 8'h2C, 8'h2D,
            8'h2E, 8'h2F, 8'h30, 8'h31, 8'h32, 8'h33,
            8'h34, 8'h35, 8'h36, 8'h37, 8'h38, 8'h39,
            8'h3A, 8'h3B, 8'h3C, 8'h3D, 8'h3E, 8'h3F: begin
                vu_instr = iw0_q;
                vu_start = 1'b1;
            end

            default: begin
                opc_error = 1'b1;
            end
        endcase
    endtask

    // ------------------------------------------------------------------
    // Wait-done function: returns 1 when the active engine has finished
    // ------------------------------------------------------------------
    function automatic logic wait_done();
        if (iw0_q[IW_SETREG_OPC_HI:IW_SETREG_OPC_LO] == SETREG_OPC_PATTERN)
            return !vu_busy;
        unique case (opc_q)
            OPC_BLOCK_MOV, OPC_BLOCK_XOR, OPC_BLOCK_SET,
            OPC_BLOCK_CMP_GCM:    return bop_done;
            OPC_CLEAR, OPC_SWAP:  return 1'b1; // immediate
            OPC_REGB_XOR, OPC_STORE, OPC_BYTE_SET: return 1'b1;
            OPC_FF_START, OPC_FF_CONTINUE: return ff_done;
            OPC_FF_STOP:          return 1'b1;
            OPC_AES, OPC_AES_INV: return !aes_busy;
            OPC_SHA1, OPC_SHA2_256, OPC_SHA2_512, OPC_SHA3: return !sha_busy;
            OPC_DES, OPC_DES_INV, OPC_TDES, OPC_TDES_INV: return !des_busy;
            OPC_CRC:              return !crc_busy;
            default:              return !vu_busy;
        endcase
    endfunction

endmodule
