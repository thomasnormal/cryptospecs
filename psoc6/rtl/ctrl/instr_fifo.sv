// PSoC 6 Crypto — Instruction FIFO
//
// 8-entry, 32-bit write-only FIFO (INSTR_FF_WR).  The CPU pushes 32-bit
// instruction words; the decoder pops them.  Implements INSTR_FF_STATUS
// fields (BUSY/EVENT/USED) and the overflow interrupt.

`include "crypto_pkg.sv"

module instr_fifo
    import crypto_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    // Write port (from AHB slave, INSTR_FF_WR write)
    input  logic [31:0] push_data,
    input  logic        push_en,

    // Read port (instruction decoder)
    output logic [31:0] pop_data,
    input  logic        pop_en,

    // Control (INSTR_FF_CTL)
    input  logic        fifo_clear,   // clear all entries on any write to CLEAR bit
    input  logic [2:0]  event_level,  // EVENT_LEVEL field [2:0]

    // Status (drives INSTR_FF_STATUS)
    output logic [3:0]  used,         // USED field: 0–8
    output logic        fifo_full,
    output logic        fifo_empty,
    output logic        event_flag,   // used <= event_level
    output logic        busy,         // !empty

    // Interrupt: push attempted while full
    output logic        overflow_irq
);
    logic [3:0] cnt;
    logic       full_w, empty_w;
    logic       rst_combined;

    assign rst_combined = rst_n && !fifo_clear;

    sync_fifo #(.WIDTH(32), .DEPTH(INSTR_FF_DEPTH)) u_fifo (
        .clk    (clk),
        .rst_n  (rst_combined),
        .wr_data(push_data),
        .wr_en  (push_en && !full_w),
        .full   (full_w),
        .rd_data(pop_data),
        .rd_en  (pop_en),
        .empty  (empty_w),
        .count  (cnt)
    );

    assign used       = cnt;
    assign fifo_full  = full_w;
    assign fifo_empty = empty_w;
    assign busy       = !empty_w;
    assign event_flag = (cnt <= {1'b0, event_level});

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || fifo_clear) overflow_irq <= 1'b0;
        else                      overflow_irq <= push_en && full_w;
    end

endmodule
