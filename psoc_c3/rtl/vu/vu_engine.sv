// PSoC Control C3 CryptoLite - Vector Unit Engine
//
// Behavioral large-integer engine behind the CryptoLite descriptor interface.
// The AHB master protocol is preserved: the engine fetches the descriptor and
// operand buffers from memory, computes the result locally, then writes the
// destination words back through the same master port.

module vu_engine
    import cryptolite_pkg::*;
#(
    parameter int VU_MAX_WORDS = 128
)
(
    input  logic        clk,
    input  logic        rst_n,

    input  logic        start,
    input  logic [31:0] descr_ptr,

    // AHB master
    output logic [31:0] haddr,
    output logic [1:0]  htrans,
    output logic        hwrite,
    output logic [2:0]  hsize,
    output logic [31:0] hwdata,
    input  logic [31:0] hrdata,
    input  logic        hready,
    input  logic        hresp,

    output logic        busy,
    output logic        done,
    output logic        bus_error
);

    localparam int VU_MAX_DST_WORDS = 2 * VU_MAX_WORDS;

    typedef enum logic [2:0] {
        VU_IDLE,
        VU_XFER_ADDR,
        VU_XFER_DATA,
        VU_COMPUTE
    } vu_state_e;

    typedef enum logic [1:0] {
        VPH_DESCR,
        VPH_LOAD_SRC0,
        VPH_LOAD_SRC1,
        VPH_WRITE_DST
    } vu_phase_e;

    vu_state_e state_q;
    vu_phase_e phase_q;

    logic [31:0] ctl_word_q;
    logic [3:0]  opcode_q;
    logic [8:0]  dst_len_q;
    logic [7:0]  src0_len_q;
    logic [7:0]  src1_len_q;
    logic [31:0] src0_ptr_q;
    logic [31:0] src1_ptr_q;
    logic [31:0] dst_ptr_q;

    logic [8:0]  word_idx_q;

    logic [31:0] src0_buf [0:VU_MAX_WORDS-1];
    logic [31:0] src1_buf [0:VU_MAX_WORDS-1];
    logic [31:0] result_buf [0:VU_MAX_DST_WORDS-1];

    function automatic logic use_src1_buffer(input logic [3:0] opcode);
        case (opcode)
            VU_ADD,
            VU_SUB,
            VU_XOR,
            VU_XMUL,
            VU_MUL,
            VU_COND_SUB: use_src1_buffer = 1'b1;
            default:     use_src1_buffer = 1'b0;
        endcase
    endfunction

    function automatic logic [8:0] clamp_dst_len(input logic [8:0] len);
        if (len > VU_MAX_DST_WORDS)
            clamp_dst_len = VU_MAX_DST_WORDS[8:0];
        else
            clamp_dst_len = len;
    endfunction

    function automatic logic [7:0] clamp_src_len(input logic [7:0] len);
        if (len > VU_MAX_WORDS)
            clamp_src_len = VU_MAX_WORDS[7:0];
        else
            clamp_src_len = len;
    endfunction

    function automatic logic [31:0] src0_word(input int idx);
        if ((idx >= 0) && (idx < src0_len_q) && (idx < VU_MAX_WORDS))
            src0_word = src0_buf[idx];
        else
            src0_word = '0;
    endfunction

    function automatic logic [31:0] src1_word(input int idx);
        if ((idx >= 0) && (idx < src1_len_q) && (idx < VU_MAX_WORDS))
            src1_word = src1_buf[idx];
        else
            src1_word = '0;
    endfunction

    function automatic logic [63:0] clmul32(
        input logic [31:0] a,
        input logic [31:0] b
    );
        logic [63:0] accum;
        integer bit_idx;
        accum = '0;
        for (bit_idx = 0; bit_idx < 32; bit_idx = bit_idx + 1) begin
            if (b[bit_idx])
                accum ^= ({32'b0, a} << bit_idx);
        end
        clmul32 = accum;
    endfunction

    function automatic logic src0_ge_src1;
        logic gt;
        logic eq;
        logic [31:0] a_word;
        logic [31:0] b_word;
        integer idx;
        gt = 1'b0;
        eq = 1'b1;
        for (idx = VU_MAX_WORDS - 1; idx >= 0; idx = idx - 1) begin
            a_word = src0_word(idx);
            b_word = src1_word(idx);
            if (eq && (a_word > b_word)) begin
                gt = 1'b1;
                eq = 1'b0;
            end else if (eq && (a_word < b_word)) begin
                gt = 1'b0;
                eq = 1'b0;
            end
        end
        src0_ge_src1 = gt | eq;
    endfunction

    logic [31:0] xfer_addr;
    always_comb begin
        unique case (phase_q)
            VPH_DESCR:    xfer_addr = descr_ptr   + {21'b0, word_idx_q, 2'b00};
            VPH_LOAD_SRC0:xfer_addr = src0_ptr_q  + {21'b0, word_idx_q, 2'b00};
            VPH_LOAD_SRC1:xfer_addr = src1_ptr_q  + {21'b0, word_idx_q, 2'b00};
            VPH_WRITE_DST:xfer_addr = dst_ptr_q   + {21'b0, word_idx_q, 2'b00};
            default:      xfer_addr = '0;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        int i;
        int j;
        int k;
        int word_shift;
        int bit_shift;
        logic [31:0] low_word;
        logic [31:0] high_word;
        logic [31:0] prev_word;
        logic [31:0] a_word;
        logic [31:0] b_word;
        logic        cond_sub_en;
        logic [32:0] sum33;
        logic [32:0] diff33;
        logic [63:0] mul_accum;
        logic [63:0] xmul_part;
        logic [31:0] carry32;

        if (!rst_n) begin
            state_q    <= VU_IDLE;
            phase_q    <= VPH_DESCR;
            ctl_word_q <= '0;
            opcode_q   <= '0;
            dst_len_q  <= '0;
            src0_len_q <= '0;
            src1_len_q <= '0;
            src0_ptr_q <= '0;
            src1_ptr_q <= '0;
            dst_ptr_q  <= '0;
            word_idx_q <= '0;
            haddr      <= '0;
            htrans     <= HTRANS_IDLE;
            hwrite     <= HWRITE_READ;
            hsize      <= HSIZE_WORD;
            hwdata     <= '0;
            busy       <= 1'b0;
            done       <= 1'b0;
            bus_error  <= 1'b0;
            for (i = 0; i < VU_MAX_WORDS; i++) begin
                src0_buf[i] <= '0;
                src1_buf[i] <= '0;
            end
            for (i = 0; i < VU_MAX_DST_WORDS; i++) begin
                result_buf[i] <= '0;
            end
        end else begin
            done <= 1'b0;
            bus_error <= 1'b0;

            case (state_q)
                VU_IDLE: begin
                    htrans <= HTRANS_IDLE;
                    hwrite <= HWRITE_READ;
                    if (start) begin
                        busy       <= 1'b1;
                        phase_q    <= VPH_DESCR;
                        word_idx_q <= '0;
                        state_q    <= VU_XFER_ADDR;
                        for (i = 0; i < VU_MAX_DST_WORDS; i++) begin
                            result_buf[i] <= '0;
                        end
                    end
                end

                VU_XFER_ADDR: begin
                    haddr  <= xfer_addr;
                    htrans <= HTRANS_NONSEQ;
                    hwrite <= (phase_q == VPH_WRITE_DST);
                    hsize  <= HSIZE_WORD;
                    hwdata <= result_buf[word_idx_q];
                    state_q <= VU_XFER_DATA;
                end

                VU_XFER_DATA: begin
                    htrans <= HTRANS_IDLE;
                    if (hready) begin
                        if (hresp == HRESP_ERROR) begin
                            busy      <= 1'b0;
                            done      <= 1'b1;
                            bus_error <= 1'b1;
                            state_q   <= VU_IDLE;
                        end else begin
                            unique case (phase_q)
                                VPH_DESCR: begin
                                    unique case (word_idx_q[1:0])
                                        2'd0: begin
                                            ctl_word_q <= hrdata;
                                            opcode_q   <= hrdata[VU_CTL_OPC_HI:VU_CTL_OPC_LO];
                                            dst_len_q  <= clamp_dst_len(hrdata[VU_CTL_DST_LEN_HI:VU_CTL_DST_LEN_LO] + 9'd1);
                                            src1_len_q <= clamp_src_len(hrdata[VU_CTL_SRC1_LEN_HI:VU_CTL_SRC1_LEN_LO] + 8'd1);
                                            src0_len_q <= clamp_src_len(hrdata[VU_CTL_SRC0_LEN_HI:VU_CTL_SRC0_LEN_LO] + 8'd1);
                                        end
                                        2'd1: src0_ptr_q <= hrdata;
                                        2'd2: src1_ptr_q <= hrdata;
                                        2'd3: dst_ptr_q  <= hrdata;
                                        default: ;
                                    endcase

                                    if (word_idx_q == 9'd3) begin
                                        word_idx_q <= '0;
                                        phase_q    <= VPH_LOAD_SRC0;
                                        state_q    <= VU_XFER_ADDR;
                                    end else begin
                                        word_idx_q <= word_idx_q + 9'd1;
                                        state_q    <= VU_XFER_ADDR;
                                    end
                                end

                                VPH_LOAD_SRC0: begin
                                    if (word_idx_q < VU_MAX_WORDS)
                                        src0_buf[word_idx_q] <= hrdata;

                                    if (word_idx_q + 9'd1 >= {1'b0, src0_len_q}) begin
                                        word_idx_q <= '0;
                                        if (use_src1_buffer(opcode_q)) begin
                                            phase_q <= VPH_LOAD_SRC1;
                                            state_q <= VU_XFER_ADDR;
                                        end else begin
                                            state_q <= VU_COMPUTE;
                                        end
                                    end else begin
                                        word_idx_q <= word_idx_q + 9'd1;
                                        state_q    <= VU_XFER_ADDR;
                                    end
                                end

                                VPH_LOAD_SRC1: begin
                                    if (word_idx_q < VU_MAX_WORDS)
                                        src1_buf[word_idx_q] <= hrdata;

                                    if (word_idx_q + 9'd1 >= {1'b0, src1_len_q}) begin
                                        word_idx_q <= '0;
                                        state_q    <= VU_COMPUTE;
                                    end else begin
                                        word_idx_q <= word_idx_q + 9'd1;
                                        state_q    <= VU_XFER_ADDR;
                                    end
                                end

                                VPH_WRITE_DST: begin
                                    if (word_idx_q + 9'd1 >= dst_len_q) begin
                                        busy    <= 1'b0;
                                        done    <= 1'b1;
                                        state_q <= VU_IDLE;
                                    end else begin
                                        word_idx_q <= word_idx_q + 9'd1;
                                        state_q    <= VU_XFER_ADDR;
                                    end
                                end

                                default: state_q <= VU_IDLE;
                            endcase
                        end
                    end
                end

                VU_COMPUTE: begin
                    for (i = 0; i < VU_MAX_DST_WORDS; i++) begin
                        result_buf[i] = '0;
                    end

                    unique case (opcode_q)
                        VU_MOV: begin
                            for (i = 0; i < dst_len_q; i++) begin
                                result_buf[i] = src0_word(i);
                            end
                        end

                        VU_ADD: begin
                            carry32 = '0;
                            for (i = 0; i < dst_len_q; i++) begin
                                sum33 = {1'b0, src0_word(i)} + {1'b0, src1_word(i)} + {32'b0, carry32[0]};
                                result_buf[i] = sum33[31:0];
                                carry32 = {31'b0, sum33[32]};
                            end
                        end

                        VU_SUB: begin
                            carry32 = '0;
                            for (i = 0; i < dst_len_q; i++) begin
                                diff33 = {1'b0, src0_word(i)} - {1'b0, src1_word(i)} - {32'b0, carry32[0]};
                                result_buf[i] = diff33[31:0];
                                carry32 = {31'b0, diff33[32]};
                            end
                        end

                        VU_XOR: begin
                            for (i = 0; i < dst_len_q; i++) begin
                                result_buf[i] = src0_word(i) ^ src1_word(i);
                            end
                        end

                        VU_XMUL: begin
                            for (i = 0; i < src1_len_q; i++) begin
                                for (j = 0; j < src0_len_q; j++) begin
                                    xmul_part = clmul32(src0_word(j), src1_word(i));
                                    if ((i + j) < VU_MAX_DST_WORDS && (i + j) < dst_len_q)
                                        result_buf[i + j] = result_buf[i + j] ^ xmul_part[31:0];
                                    if ((i + j + 1) < VU_MAX_DST_WORDS && (i + j + 1) < dst_len_q)
                                        result_buf[i + j + 1] = result_buf[i + j + 1] ^ xmul_part[63:32];
                                end
                            end
                        end

                        VU_LSR1: begin
                            for (i = 0; i < dst_len_q; i++) begin
                                low_word = src0_word(i);
                                high_word = src0_word(i + 1);
                                result_buf[i] = {high_word[0], low_word[31:1]};
                            end
                        end

                        VU_LSL1: begin
                            for (i = 0; i < dst_len_q; i++) begin
                                a_word = src0_word(i);
                                prev_word = (i == 0) ? 32'h0 : src0_word(i - 1);
                                result_buf[i] = {a_word[30:0], prev_word[31]};
                            end
                        end

                        VU_LSR: begin
                            word_shift = src1_ptr_q[12:5];
                            bit_shift  = src1_ptr_q[4:0];
                            for (i = 0; i < dst_len_q; i++) begin
                                low_word = src0_word(i + word_shift);
                                high_word = src0_word(i + word_shift + 1);
                                if (bit_shift == 0)
                                    result_buf[i] = low_word;
                                else
                                    result_buf[i] = (low_word >> bit_shift) | (high_word << (32 - bit_shift));
                            end
                        end

                        VU_COND_SUB: begin
                            cond_sub_en = src0_ge_src1();
                            carry32 = '0;
                            for (i = 0; i < dst_len_q; i++) begin
                                if (cond_sub_en) begin
                                    diff33 = {1'b0, src0_word(i)} - {1'b0, src1_word(i)} - {32'b0, carry32[0]};
                                    result_buf[i] = diff33[31:0];
                                    carry32 = {31'b0, diff33[32]};
                                end else begin
                                    result_buf[i] = src0_word(i);
                                end
                            end
                        end

                        VU_MUL: begin
                            for (i = 0; i < src1_len_q; i++) begin
                                carry32 = '0;
                                for (j = 0; j < src0_len_q; j++) begin
                                    if ((i + j) < VU_MAX_DST_WORDS && (i + j) < dst_len_q) begin
                                        mul_accum = ({32'b0, src0_word(j)} * {32'b0, src1_word(i)}) +
                                                    {32'b0, result_buf[i + j]} +
                                                    {32'b0, carry32};
                                        result_buf[i + j] = mul_accum[31:0];
                                        carry32 = mul_accum[63:32];
                                    end
                                end
                                k = i + src0_len_q;
                                while ((carry32 != 0) && (k < dst_len_q) && (k < VU_MAX_DST_WORDS)) begin
                                    mul_accum = {32'b0, result_buf[k]} + {32'b0, carry32};
                                    result_buf[k] = mul_accum[31:0];
                                    carry32 = mul_accum[63:32];
                                    k = k + 1;
                                end
                            end
                        end

                        default: begin
                            for (i = 0; i < dst_len_q; i++) begin
                                result_buf[i] = '0;
                            end
                        end
                    endcase

                    phase_q    <= VPH_WRITE_DST;
                    word_idx_q <= '0;
                    state_q    <= VU_XFER_ADDR;
                end

                default: state_q <= VU_IDLE;
            endcase
        end
    end

endmodule
