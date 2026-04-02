// PSoC 6 Crypto — Internal Memory Buffer (MEM_BUFF)
//
// 1024 × 32-bit synchronous SRAM at offset 0x4000 from CRYPTO_BASE.
// Accessible via AHB slave (CPU reads/writes) and engine port (VU / LOAD-STORE DMA).

`include "crypto_pkg.sv"

module mem_buffer
    import crypto_pkg::*;
(
    input  logic        clk,

    // Port A — AHB slave (word address = haddr[11:2])
    input  logic [9:0]  a_addr,
    input  logic [31:0] a_wdata,
    input  logic        a_we,
    output logic [31:0] a_rdata,

    // Port B — engine / DMA access
    input  logic [9:0]  b_addr,
    input  logic [31:0] b_wdata,
    input  logic        b_we,
    output logic [31:0] b_rdata
);
    logic [31:0] ram [0:MEM_BUFF_WORDS-1];

    always_ff @(posedge clk) begin
        if (a_we) ram[a_addr] <= a_wdata;
        a_rdata <= ram[a_addr];
    end

    always_ff @(posedge clk) begin
        if (b_we) ram[b_addr] <= b_wdata;
        b_rdata <= ram[b_addr];
    end

endmodule
