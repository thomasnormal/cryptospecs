// PSoC 6 Crypto — Load/Store FIFO DMA Engine
//
// Implements the FF_START / FF_CONTINUE / FF_STOP instruction effects:
//   - LOAD (ff_id 8 or 9): AHB master reads up to 16 bytes from external
//     memory into a 128-bit staging register, then asserts ld_valid so the
//     instruction decoder can issue a BLOCK_MOV to copy it to reg_buffer.
//   - STORE (ff_id 12): reads 128 bits from the store staging register and
//     writes them to external memory via AHB master.
//
// For Phase 1 a single 16-byte (128-bit) burst is supported per FF_START.
// FF_CONTINUE (address chaining) is accepted and starts the next burst.
// FF_STOP terminates an active transaction.
//
// AHB burst: INCR4 × 32-bit words (16 bytes per burst).

`include "crypto_pkg.sv"

module load_store_fifo
    import crypto_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    // ------------------------------------------------------------------
    // Command interface (from instruction decoder)
    // ------------------------------------------------------------------
    input  logic [3:0]   cmd_ff_id,    // BLKID_LOAD_FIFO0=8, BLKID_LOAD_FIFO1=9, BLKID_STORE_FIFO=12
    input  logic [31:0]  cmd_addr,     // start address
    input  logic [31:0]  cmd_size,     // byte count (≤ 16 for Phase 1)
    input  logic         cmd_start,    // FF_START pulse
    input  logic         cmd_continue, // FF_CONTINUE pulse
    input  logic         cmd_stop,     // FF_STOP pulse
    output logic         cmd_done,     // transfer complete pulse

    // ------------------------------------------------------------------
    // Staging register outputs (to reg_buffer / instruction decoder)
    // ------------------------------------------------------------------
    output logic [127:0] ld0_staging,  // LOAD_FIFO0 buffer
    output logic         ld0_valid,    // new 128-bit word available in ld0_staging
    output logic [127:0] ld1_staging,  // LOAD_FIFO1 buffer
    output logic         ld1_valid,

    // STORE staging is written by BLOCK_MOV from reg_buffer side
    input  logic [127:0] st_staging,   // content set by decoder / reg_buffer
    input  logic         st_arm,       // decoder arms the store staging before FF_START

    // ------------------------------------------------------------------
    // AHB Master port
    // ------------------------------------------------------------------
    output logic [31:0]  m_haddr,
    output logic [1:0]   m_htrans,
    output logic         m_hwrite,
    output logic [2:0]   m_hsize,
    output logic [2:0]   m_hburst,
    output logic [31:0]  m_hwdata,
    input  logic [31:0]  m_hrdata,
    input  logic         m_hready,
    input  logic         m_hresp,

    // Bus error interrupt
    output logic         bus_error_irq
);
    import crypto_pkg::BLKID_LOAD_FIFO0, BLKID_LOAD_FIFO1, BLKID_STORE_FIFO;

    // ------------------------------------------------------------------
    // State machine
    // ------------------------------------------------------------------
    typedef enum logic [2:0] {
        ST_IDLE       = 3'd0,
        ST_ADDR       = 3'd1,  // AHB address phase
        ST_DATA_LOAD  = 3'd2,  // receiving read data
        ST_DATA_STORE = 3'd3,  // driving write data
        ST_DONE       = 3'd4
    } lsf_state_e;

    lsf_state_e state_q;

    logic [31:0]  base_addr_q;
    logic [31:0]  size_q;
    logic [3:0]   ff_id_q;
    logic         is_store_q;

    logic [1:0]   beat_q;        // 4-beat INCR4 counter (0–3)
    logic [127:0] load_buf_q;    // accumulate 4 × 32-bit words
    logic [127:0] store_buf_q;   // registered copy of st_staging

    // AHB address calculation
    logic [31:0] beat_addr;
    assign beat_addr = base_addr_q + {beat_q, 2'b00};

    // ------------------------------------------------------------------
    // AHB output assignments
    // ------------------------------------------------------------------
    always_comb begin
        m_htrans = HTRANS_IDLE;
        m_haddr  = beat_addr;
        m_hwrite = is_store_q;
        m_hsize  = HSIZE_WORD;
        m_hburst = 3'b011; // INCR4
        m_hwdata = store_buf_q[beat_q * 32 +: 32];

        unique case (state_q)
            ST_ADDR: begin
                m_htrans = HTRANS_NONSEQ;
            end
            ST_DATA_LOAD, ST_DATA_STORE: begin
                m_htrans = (beat_q == 2'd3) ? HTRANS_IDLE : HTRANS_SEQ;
            end
            default: m_htrans = HTRANS_IDLE;
        endcase
    end

    // ------------------------------------------------------------------
    // Main FSM
    // ------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q      <= ST_IDLE;
            beat_q       <= '0;
            cmd_done     <= 1'b0;
            ld0_valid    <= 1'b0;
            ld1_valid    <= 1'b0;
            bus_error_irq<= 1'b0;
            load_buf_q   <= '0;
            store_buf_q  <= '0;
        end else begin
            cmd_done    <= 1'b0;
            ld0_valid   <= 1'b0;
            ld1_valid   <= 1'b0;
            bus_error_irq <= 1'b0;

            unique case (state_q)
                ST_IDLE: begin
                    if (cmd_start || cmd_continue) begin
                        base_addr_q <= cmd_addr;
                        size_q      <= cmd_size;
                        ff_id_q     <= cmd_ff_id;
                        is_store_q  <= (cmd_ff_id == BLKID_STORE_FIFO);
                        beat_q      <= 2'd0;
                        if (cmd_ff_id == BLKID_STORE_FIFO)
                            store_buf_q <= st_staging; // latch at command time
                        state_q <= ST_ADDR;
                    end
                end

                ST_ADDR: begin
                    if (m_hready) begin
                        state_q <= is_store_q ? ST_DATA_STORE : ST_DATA_LOAD;
                    end
                end

                ST_DATA_LOAD: begin
                    if (m_hready) begin
                        if (m_hresp == HRESP_ERROR) begin
                            bus_error_irq <= 1'b1;
                            state_q <= ST_IDLE;
                        end else begin
                            load_buf_q[beat_q * 32 +: 32] <= m_hrdata;
                            if (beat_q == 2'd3) begin
                                // All 4 words received
                                state_q <= ST_DONE;
                            end else begin
                                beat_q <= beat_q + 1;
                            end
                        end
                    end
                end

                ST_DATA_STORE: begin
                    if (m_hready) begin
                        if (m_hresp == HRESP_ERROR) begin
                            bus_error_irq <= 1'b1;
                            state_q <= ST_IDLE;
                        end else if (beat_q == 2'd3) begin
                            state_q <= ST_DONE;
                        end else begin
                            beat_q <= beat_q + 1;
                        end
                    end
                end

                ST_DONE: begin
                    // Update staging register and assert valid
                    if (ff_id_q == BLKID_LOAD_FIFO0) begin
                        ld0_staging <= load_buf_q;
                        ld0_valid   <= 1'b1;
                    end else if (ff_id_q == BLKID_LOAD_FIFO1) begin
                        ld1_staging <= load_buf_q;
                        ld1_valid   <= 1'b1;
                    end
                    cmd_done <= 1'b1;
                    state_q  <= ST_IDLE;
                end

                default: state_q <= ST_IDLE;
            endcase

            // FF_STOP: abort immediately
            if (cmd_stop) state_q <= ST_IDLE;
        end
    end

endmodule
