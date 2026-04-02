// VU ALU — Large-integer arithmetic over mem_buffer words
// Handles: ADD, SUB, AND, OR, XOR, NOR, NAND, MOV, SET_TO_ZERO, SET_TO_ONE,
//          CMP_SUB, TST, ADD_WITH_CARRY, SUB_WITH_CARRY
//
// Uses mem_buffer port B (single R/W, 1-cycle read latency).
// Binary ops: 3 sub-cycles per word (READ0 → READ1 → WRITE).
// Unary ops:  2 sub-cycles per word (READ0 → WRITE), or just WRITE for SET_*.
// CMP_SUB / TST: same timing but suppress writes.

`include "crypto_pkg.sv"
`include "crypto_isa_pkg.sv"

module vu_alu
    import crypto_pkg::*;
    import crypto_isa_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    // Control
    input  logic [7:0]  alu_op,       // opcode
    input  logic [9:0]  src0_addr,    // mem_buffer word address for src0
    input  logic [12:0] src0_size,    // size in bits minus 1
    input  logic [9:0]  src1_addr,    // for binary ops
    input  logic [9:0]  dst_addr,     // destination word address
    input  logic        alu_start,
    output logic        alu_done,
    output logic        alu_busy,

    // Carry-in for ADD_WITH_CARRY / SUB_WITH_CARRY
    input  logic        alu_carry_in,

    // Status outputs (valid when alu_done pulses)
    output logic        stat_carry,
    output logic        stat_zero,
    output logic        stat_even,
    output logic        stat_one,

    // mem_buffer port B (shared with VU engine)
    output logic [9:0]  b_addr,
    output logic [31:0] b_wdata,
    output logic        b_we,
    input  logic [31:0] b_rdata
);

    // -----------------------------------------------------------------------
    // State encoding
    // -----------------------------------------------------------------------
    typedef enum logic [2:0] {
        ST_IDLE  = 3'd0,
        ST_READ0 = 3'd1,   // issue read for src0[word_q]  (or setup for SET_*)
        ST_READ1 = 3'd2,   // src0 latched; issue read for src1[word_q]
        ST_WRITE = 3'd3,   // compute & write result; advance word
        ST_DONE  = 3'd4
    } state_t;

    state_t state_q, state_d;

    // -----------------------------------------------------------------------
    // Opcode classification helpers
    // -----------------------------------------------------------------------
    // Binary ops: need two source reads
    function automatic logic is_binary(input logic [7:0] op);
        return (op == 8'h36 || op == 8'h37 ||   // OPC_ADD, OPC_SUB
                op == 8'h38 || op == 8'h39 ||   // OPC_VU_OR, OPC_VU_AND
                op == 8'h3A || op == 8'h3B ||   // OPC_VU_XOR, OPC_VU_NOR
                op == 8'h3C ||                   // OPC_VU_NAND
                op == 8'h3D ||                   // OPC_CMP_SUB
                op == 8'h14 || op == 8'h15);    // ADD_WITH_CARRY, SUB_WITH_CARRY
    endfunction

    // Ops that write nothing (status-only)
    function automatic logic is_no_write(input logic [7:0] op);
        return (op == 8'h3D || op == 8'h3F);    // OPC_CMP_SUB, OPC_TST
    endfunction

    // Ops where no source read is needed (generate constant)
    function automatic logic is_const_gen(input logic [7:0] op);
        return (op == 8'h34 || op == 8'h35);    // SET_TO_ZERO, SET_TO_ONE
    endfunction

    // Ops that are unary (one source read: MOV, TST)
    function automatic logic is_unary(input logic [7:0] op);
        return (op == 8'h30 || op == 8'h3F);    // OPC_MOV, OPC_TST
    endfunction

    // -----------------------------------------------------------------------
    // Registered state
    // -----------------------------------------------------------------------
    logic [9:0]  nwords_q;      // number of 32-bit words to process
    logic [9:0]  word_q;        // current word index
    logic [32:0] carry_q;       // carry/borrow (33-bit for overflow detection)
    logic [31:0] src0_lat_q;    // latched src0 word (available after READ0)

    // Status accumulators
    logic        zero_acc_q;    // running: all words zero so far
    logic        one_acc_q;     // running: all words all-ones so far
    logic        even_q;        // bit 0 of first result word (stored once)
    logic        even_set_q;    // flag: even_q has been set
    logic        carry_out_q;   // final carry/borrow out

    // Latched inputs (captured on alu_start)
    logic [7:0]  op_q;
    logic [9:0]  src0_base_q;
    logic [9:0]  src1_base_q;
    logic [9:0]  dst_base_q;
    logic [12:0] size_q;        // src0_size

    // -----------------------------------------------------------------------
    // Derived: last-word bit mask
    // -----------------------------------------------------------------------
    logic [4:0]  last_valid_bits;   // number of valid bits in last word (1–32)
    logic [31:0] last_mask;

    assign last_valid_bits = size_q[4:0] + 5'd1;  // (size % 32) + 1; 0 means 32
    assign last_mask = (last_valid_bits == 5'd0) ? 32'hFFFF_FFFF
                                                  : ((32'd1 << last_valid_bits) - 32'd1);

    // -----------------------------------------------------------------------
    // Compute result word (combinational, uses src0_lat_q and b_rdata)
    // -----------------------------------------------------------------------
    logic [31:0] src0_w, src1_w;
    logic [31:0] raw_result;
    logic [31:0] result_w;
    logic        is_last_word;
    logic [32:0] add_result;    // extra bit for carry

    assign src0_w     = src0_lat_q;
    assign src1_w     = b_rdata;
    assign is_last_word = (word_q == nwords_q - 10'd1);

    always_comb begin
        add_result = 33'd0;
        raw_result = 32'd0;
        case (op_q)
            8'h36, 8'h14: begin  // OPC_ADD, ADD_WITH_CARRY
                add_result = {1'b0, src0_w} + {1'b0, src1_w} + {32'd0, carry_q[0]};
                raw_result = add_result[31:0];
            end
            8'h37, 8'h15: begin  // OPC_SUB, SUB_WITH_CARRY
                add_result = {1'b0, src0_w} - {1'b0, src1_w} - {32'd0, carry_q[0]};
                raw_result = add_result[31:0];
            end
            8'h3D: begin  // OPC_CMP_SUB (subtract, status only)
                add_result = {1'b0, src0_w} - {1'b0, src1_w} - {32'd0, carry_q[0]};
                raw_result = add_result[31:0];
            end
            8'h38: raw_result = src0_w | src1_w;   // OPC_VU_OR
            8'h39: raw_result = src0_w & src1_w;   // OPC_VU_AND
            8'h3A: raw_result = src0_w ^ src1_w;   // OPC_VU_XOR
            8'h3B: raw_result = ~(src0_w | src1_w); // OPC_VU_NOR
            8'h3C: raw_result = ~(src0_w & src1_w); // OPC_VU_NAND
            8'h30: raw_result = src0_w;             // OPC_MOV
            8'h3F: raw_result = src0_w;             // OPC_TST (status only)
            8'h34: raw_result = 32'h0000_0000;     // SET_TO_ZERO
            8'h35: raw_result = 32'hFFFF_FFFF;     // SET_TO_ONE
            default: raw_result = 32'd0;
        endcase
        // Mask last word to valid bits
        result_w = is_last_word ? (raw_result & last_mask) : raw_result;
    end

    // Next carry/borrow for ADD/SUB
    logic next_carry;
    assign next_carry = (op_q == 8'h36 || op_q == 8'h14 ||
                         op_q == 8'h37 || op_q == 8'h15 ||
                         op_q == 8'h3D) ? add_result[32] : 1'b0;

    // -----------------------------------------------------------------------
    // FSM next-state and output logic
    // -----------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q      <= ST_IDLE;
            op_q         <= 8'd0;
            src0_base_q  <= 10'd0;
            src1_base_q  <= 10'd0;
            dst_base_q   <= 10'd0;
            size_q       <= 13'd0;
            nwords_q     <= 10'd0;
            word_q       <= 10'd0;
            carry_q      <= 33'd0;
            src0_lat_q   <= 32'd0;
            zero_acc_q   <= 1'b1;
            one_acc_q    <= 1'b1;
            even_q       <= 1'b0;
            even_set_q   <= 1'b0;
            carry_out_q  <= 1'b0;
            alu_done     <= 1'b0;
            stat_carry   <= 1'b0;
            stat_zero    <= 1'b0;
            stat_even    <= 1'b0;
            stat_one     <= 1'b0;
            b_addr       <= 10'd0;
            b_wdata      <= 32'd0;
            b_we         <= 1'b0;
        end else begin
            alu_done <= 1'b0;
            b_we     <= 1'b0;

            case (state_q)
                // ---------------------------------------------------------
                ST_IDLE: begin
                    if (alu_start) begin
                        op_q        <= alu_op;
                        src0_base_q <= src0_addr;
                        src1_base_q <= src1_addr;
                        dst_base_q  <= dst_addr;
                        size_q      <= src0_size;
                        nwords_q    <= (src0_size[12:5] + 10'd1); // ceil((size+1)/32)
                        word_q      <= 10'd0;
                        zero_acc_q  <= 1'b1;
                        one_acc_q   <= 1'b1;
                        even_q      <= 1'b0;
                        even_set_q  <= 1'b0;
                        // Carry init: ADD_WITH_CARRY/SUB_WITH_CARRY use alu_carry_in
                        if (alu_op == 8'h14 || alu_op == 8'h15)
                            carry_q <= {32'd0, alu_carry_in};
                        else
                            carry_q <= 33'd0;
                        state_q <= ST_READ0;
                    end
                end

                // ---------------------------------------------------------
                // READ0: Issue read for src0[word_q]
                //   For SET_TO_ZERO/SET_TO_ONE: skip reads, go directly to WRITE
                //   For all others: issue src0 read
                ST_READ0: begin
                    if (is_const_gen(op_q)) begin
                        // No reads needed — jump straight to write
                        state_q <= ST_WRITE;
                    end else begin
                        // Issue read for src0
                        b_addr  <= src0_base_q + word_q;
                        b_we    <= 1'b0;
                        state_q <= ST_READ1;
                    end
                end

                // ---------------------------------------------------------
                // READ1: src0 data arrives on b_rdata; latch it.
                //   For unary ops: no src1 read needed, go to WRITE
                //   For binary ops: issue src1 read
                ST_READ1: begin
                    src0_lat_q <= b_rdata;   // latch src0
                    if (is_binary(op_q)) begin
                        // Issue read for src1
                        b_addr  <= src1_base_q + word_q;
                        b_we    <= 1'b0;
                        state_q <= ST_WRITE;
                    end else begin
                        // Unary: src0 latched, go compute/write
                        state_q <= ST_WRITE;
                    end
                end

                // ---------------------------------------------------------
                // WRITE: src1 (binary) or nothing (unary) arrives.
                //   Compute result, accumulate status, optionally write.
                ST_WRITE: begin
                    // For binary ops b_rdata = src1; for unary it is unused.
                    // result_w computed combinationally above.

                    // Accumulate status
                    zero_acc_q <= zero_acc_q & (result_w == 32'd0);
                    one_acc_q  <= one_acc_q  & (result_w == 32'hFFFF_FFFF);
                    carry_q    <= {32'd0, next_carry};

                    if (!even_set_q) begin
                        even_q     <= ~result_w[0];  // even = bit0 is 0
                        even_set_q <= 1'b1;
                    end

                    // Write to dst unless this is a status-only op
                    if (!is_no_write(op_q)) begin
                        b_addr  <= dst_base_q + word_q;
                        b_wdata <= result_w;
                        b_we    <= 1'b1;
                    end

                    // Advance word or finish
                    if (word_q == nwords_q - 10'd1) begin
                        carry_out_q <= next_carry;
                        state_q     <= ST_DONE;
                    end else begin
                        word_q  <= word_q + 10'd1;
                        state_q <= ST_READ0;
                    end
                end

                // ---------------------------------------------------------
                ST_DONE: begin
                    stat_carry <= carry_out_q;
                    stat_zero  <= zero_acc_q;
                    stat_one   <= one_acc_q;
                    stat_even  <= even_q;
                    alu_done   <= 1'b1;
                    state_q    <= ST_IDLE;
                end

                default: state_q <= ST_IDLE;
            endcase
        end
    end

    // alu_busy: asserted whenever not idle (and not the done pulse cycle)
    assign alu_busy = (state_q != ST_IDLE);

endmodule
