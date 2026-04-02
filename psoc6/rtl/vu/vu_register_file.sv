// VU Register File — 16 × {data[31:0], size[12:0], addr[9:0]}
// Synchronous write; combinational read.
// PORT A (write): rd_idx, rd_data, rd_size, rd_addr, rd_we
// PORT B (write): rd2_idx, rd2_data, rd2_size, rd2_addr, rd2_we  (for size-only updates)
// PORT C (read): rs0_idx → rs0_data/size/addr
// PORT D (read): rs1_idx → rs1_data/size/addr
// All 16 data words also output as rf_data_out[0:15][31:0] for AHB readback

`include "crypto_pkg.sv"
`include "crypto_isa_pkg.sv"

module vu_register_file
    import crypto_pkg::*;
    import crypto_isa_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    // Port A: primary write (data+size+addr)
    input  logic [3:0]  rd_idx,
    input  logic [31:0] rd_data,
    input  logic [12:0] rd_size,
    input  logic [9:0]  rd_addr,
    input  logic        rd_we,

    // Port B: secondary write (addr+size only, for ALLOC_MEM)
    input  logic [3:0]  rd2_idx,
    input  logic [12:0] rd2_size,
    input  logic [9:0]  rd2_addr,
    input  logic        rd2_we,

    // Read port C
    input  logic [3:0]  rs0_idx,
    output logic [31:0] rs0_data,
    output logic [12:0] rs0_size,
    output logic [9:0]  rs0_addr,

    // Read port D
    input  logic [3:0]  rs1_idx,
    output logic [31:0] rs1_data,
    output logic [12:0] rs1_size,
    output logic [9:0]  rs1_addr,

    // Stack pointer read (r15.data as 10-bit word address)
    output logic [9:0]  sp_addr,

    // AHB readback: all 16 data words
    output logic [31:0] rf_data_out [0:RF_NREGS-1]
);

    // Internal storage arrays
    logic [31:0] rf_data [0:15];
    logic [12:0] rf_size [0:15];
    logic [9:0]  rf_addr [0:15];

    // Synchronous write: Port A has priority over Port B on same index
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < 16; i++) begin
                rf_data[i] <= 32'd0;
                rf_size[i] <= 13'd0;
                rf_addr[i] <= 10'd0;
            end
            // Stack pointer initial value: top of 1024-word buffer
            rf_data[VU_REG_SP] <= 32'd1024;
        end else begin
            // Port B write (lower priority, applied first)
            if (rd2_we) begin
                rf_size[rd2_idx] <= rd2_size;
                rf_addr[rd2_idx] <= rd2_addr;
            end
            // Port A write (higher priority, applied second — overwrites Port B if same idx)
            if (rd_we) begin
                rf_data[rd_idx] <= rd_data;
                rf_size[rd_idx] <= rd_size;
                rf_addr[rd_idx] <= rd_addr;
            end
        end
    end

    // Read port C — combinational
    assign rs0_data = rf_data[rs0_idx];
    assign rs0_size = rf_size[rs0_idx];
    assign rs0_addr = rf_addr[rs0_idx];

    // Read port D — combinational
    assign rs1_data = rf_data[rs1_idx];
    assign rs1_size = rf_size[rs1_idx];
    assign rs1_addr = rf_addr[rs1_idx];

    // Stack pointer: r15.data[9:0]
    assign sp_addr = rf_data[VU_REG_SP][9:0];

    // AHB readback: expose all 16 data words
    generate
        genvar i;
        for (i = 0; i < RF_NREGS; i++) begin : gen_rf_data_out
            assign rf_data_out[i] = rf_data[i];
        end
    endgenerate

endmodule
