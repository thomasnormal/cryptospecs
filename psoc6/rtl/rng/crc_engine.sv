// PSoC 6 Crypto — CRC Engine
//
// Implements a 32-bit serial LFSR CRC over data streamed from LOAD_FIFO0.
// Triggered by OPC_CRC (crc_start pulse); stays busy until DMA completion
// (ff_done), then deasserts crc_busy.
//
// Configuration registers (from ahb_slave):
//   reg_crc_polynomial[31:0]  — CRC polynomial without the implicit MSB
//   reg_crc_lfsr[31:0]        — Initial LFSR value (seed)
//   reg_crc_rem_xor[31:0]     — Final XOR mask for the remainder
//   reg_crc_data_reverse[0]   — Bit-reverse each input byte before processing
//   reg_crc_rem_reverse[0]    — Bit-reverse the final CRC remainder
//   reg_crc_data_xor[7:0]     — XOR mask applied to each input byte
//
// Data interface:
//   ld0_staging[127:0]        — 128-bit beat from load_store_fifo
//   ld0_valid                 — Beat valid (from ld0_valid_raw in crypto_top)
//   ff_done                   — DMA complete pulse from load_store_fifo
//
// Each 128-bit beat is processed as 16 bytes in a fully unrolled loop (one
// beat per clock cycle).  The output crc_rem_result is valid when !crc_busy.

`include "crypto_pkg.sv"
`include "crypto_isa_pkg.sv"

module crc_engine
    import crypto_pkg::*;
    import crypto_isa_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    // OPC_CRC trigger
    input  logic        crc_start,
    output logic        crc_busy,

    // Streaming data from load_store_fifo
    input  logic [127:0] ld0_staging,
    input  logic         ld0_valid,
    input  logic         ff_done,

    // Configuration from AHB slave registers
    input  logic [31:0]  reg_crc_polynomial,
    input  logic [31:0]  reg_crc_lfsr,         // seed / initial value
    input  logic [31:0]  reg_crc_rem_xor,
    input  logic         reg_crc_rem_reverse,
    input  logic         reg_crc_data_reverse,
    input  logic [7:0]   reg_crc_data_xor,

    // Result register (combinational, updated every beat)
    output logic [31:0]  crc_rem_result
);

    // Bit-reverse a 32-bit value
    function automatic logic [31:0] bitrev32(input logic [31:0] x);
        logic [31:0] r;
        for (int i = 0; i < 32; i++) r[i] = x[31-i];
        return r;
    endfunction

    // Process one byte through the CRC LFSR (MSB-first Galois form)
    // The polynomial includes only coefficients x^0..x^31 (without the implicit x^32).
    function automatic logic [31:0] crc_byte(
        input logic [31:0] lfsr,
        input logic [7:0]  data,
        input logic [31:0] poly
    );
        logic [31:0] l;
        logic feedback;
        l = lfsr;
        for (int i = 7; i >= 0; i--) begin  // MSB-first
            feedback = l[31] ^ data[i];
            l = {l[30:0], 1'b0};
            if (feedback) l ^= poly;
        end
        return l;
    endfunction

    // Process a 128-bit (16-byte) beat through the CRC LFSR
    function automatic logic [31:0] crc_beat(
        input logic [31:0]  lfsr,
        input logic [127:0] beat,
        input logic [31:0]  poly,
        input logic         data_rev,
        input logic [7:0]   data_xor
    );
        logic [31:0] l;
        logic [7:0]  byt;
        l = lfsr;
        for (int b = 0; b < 16; b++) begin
            byt = beat[b*8 +: 8] ^ data_xor;
            if (data_rev) begin
                // bit-reverse the byte
                byt = {byt[0],byt[1],byt[2],byt[3],byt[4],byt[5],byt[6],byt[7]};
            end
            l = crc_byte(l, byt, poly);
        end
        return l;
    endfunction

    logic [31:0] lfsr_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_q   <= '0;
            crc_busy <= 1'b0;
        end else if (crc_start) begin
            lfsr_q   <= reg_crc_lfsr;
            crc_busy <= 1'b1;
        end else if (crc_busy) begin
            if (ld0_valid)
                lfsr_q <= crc_beat(lfsr_q, ld0_staging, reg_crc_polynomial,
                                   reg_crc_data_reverse, reg_crc_data_xor);
            if (ff_done)
                crc_busy <= 1'b0;
        end
    end

    // Combinational result: LFSR XOR mask, optionally bit-reversed
    logic [31:0] rem_raw;
    assign rem_raw = lfsr_q ^ reg_crc_rem_xor;
    assign crc_rem_result = reg_crc_rem_reverse ? bitrev32(rem_raw) : rem_raw;

endmodule
