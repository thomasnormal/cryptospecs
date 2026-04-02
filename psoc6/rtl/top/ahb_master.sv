// PSoC 6 Crypto — AHB-Lite Master
//
// Issues AHB INCR4 bursts (4 × 32-bit = 16 bytes) on behalf of the
// Load/Store FIFO DMA engine.  Supports both read (LOAD) and write (STORE).
//
// Interface to load_store_fifo:
//   - cmd_start: begin a transaction (address + read/write + byte count)
//   - rd_data / wr_data: 32-bit word per beat
//   - done: all beats complete
//
// One INCR4 burst = 4 beats.  For transfers > 16 bytes the load_store_fifo
// issues multiple FF_CONTINUE commands, each triggering a new burst here.

`include "crypto_pkg.sv"

module ahb_master
    import crypto_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    // DMA command interface (from load_store_fifo)
    input  logic [31:0] cmd_addr,     // start address (must be 4-byte aligned)
    input  logic        cmd_read,     // 1=read, 0=write
    input  logic        cmd_start,    // start pulse
    output logic        cmd_done,     // completion pulse
    output logic        cmd_error,    // AHB HRESP ERROR

    // Data interface
    output logic [31:0] rd_data [0:3], // captured read data
    input  logic [31:0] wr_data [0:3], // data to write

    // AHB Master port
    output logic [31:0] haddr,
    output logic [1:0]  htrans,
    output logic        hwrite,
    output logic [2:0]  hsize,
    output logic [2:0]  hburst,
    output logic [31:0] hwdata,
    input  logic [31:0] hrdata,
    input  logic        hready,
    input  logic        hresp
);
    typedef enum logic [1:0] {
        ST_IDLE = 2'd0,
        ST_ADDR = 2'd1,
        ST_DATA = 2'd2,
        ST_LAST = 2'd3
    } mst_state_e;

    mst_state_e state_q;

    logic [31:0] base_q;
    logic        read_q;
    logic [1:0]  beat_q;     // 0–3

    // Current address
    logic [31:0] cur_addr;
    assign cur_addr = base_q + {beat_q, 2'b00};

    // AHB outputs
    always_comb begin
        htrans = HTRANS_IDLE;
        haddr  = cur_addr;
        hwrite = !read_q;
        hsize  = HSIZE_WORD;
        hburst = 3'b011; // INCR4
        hwdata = wr_data[beat_q > 0 ? beat_q - 1 : 0]; // write data lags one cycle

        unique case (state_q)
            ST_ADDR: htrans = HTRANS_NONSEQ;
            ST_DATA: htrans = (beat_q == 2'd3) ? HTRANS_IDLE : HTRANS_SEQ;
            ST_LAST: htrans = HTRANS_IDLE;
            default: htrans = HTRANS_IDLE;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q   <= ST_IDLE;
            beat_q    <= '0;
            cmd_done  <= 1'b0;
            cmd_error <= 1'b0;
            for (int i = 0; i < 4; i++) rd_data[i] <= '0;
        end else begin
            cmd_done  <= 1'b0;
            cmd_error <= 1'b0;

            unique case (state_q)
                ST_IDLE: begin
                    if (cmd_start) begin
                        base_q  <= cmd_addr;
                        read_q  <= cmd_read;
                        beat_q  <= 2'd0;
                        state_q <= ST_ADDR;
                    end
                end

                ST_ADDR: begin
                    if (hready) begin
                        beat_q  <= 2'd1;
                        state_q <= ST_DATA;
                    end
                end

                ST_DATA: begin
                    if (hready) begin
                        if (hresp == HRESP_ERROR) begin
                            cmd_error <= 1'b1;
                            state_q   <= ST_IDLE;
                        end else begin
                            if (read_q)
                                rd_data[beat_q - 1] <= hrdata;
                            if (beat_q == 2'd3) begin
                                state_q <= ST_LAST;
                            end else begin
                                beat_q <= beat_q + 1;
                            end
                        end
                    end
                end

                ST_LAST: begin
                    // Capture final read data word
                    if (read_q) rd_data[3] <= hrdata;
                    cmd_done <= 1'b1;
                    state_q  <= ST_IDLE;
                end

                default: state_q <= ST_IDLE;
            endcase
        end
    end

endmodule
