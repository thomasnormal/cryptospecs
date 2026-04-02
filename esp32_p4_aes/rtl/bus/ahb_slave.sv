// AHB-Lite Slave + MMIO Register File
// Zero wait-state slave: hreadyout always asserted.
// Implements the full AES accelerator register map.

module ahb_slave
    import aes_accel_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    // AHB-Lite slave signals
    input  logic        hsel,
    input  logic [11:0] haddr,
    input  logic [1:0]  htrans,
    input  logic        hwrite,
    input  logic [2:0]  hsize,
    input  logic [31:0] hwdata,
    output logic [31:0] hrdata,
    output logic        hreadyout,
    output logic        hresp,

    // Register outputs
    output logic [255:0] key,
    output logic [127:0] text_in,
    output logic [2:0]   mode_reg,     // {decrypt, aes256, 0}
    output logic [127:0] iv,
    output logic [127:0] j0,
    output logic         dma_enable,
    output logic [2:0]   block_mode,
    output logic [31:0]  block_num,
    output logic         inc_sel,
    output logic [31:0]  aad_block_num,
    output logic [6:0]   remainder_bit_num,
    output logic         int_ena,
    output logic [31:0]  dma_src_addr,
    output logic [31:0]  dma_dst_addr,

    // Register inputs (from datapath)
    input  logic [127:0] text_out,
    input  logic [127:0] h_mem,
    input  logic [127:0] t0_mem,
    input  logic [1:0]   state,

    // Trigger/control pulses (active for one cycle)
    output logic         trigger_start,
    output logic         continue_op,
    output logic         dma_exit,
    output logic         int_clr,

    // Interrupt
    input  logic         irq_raw,
    output logic         irq
);

    // AHB pipeline registers (address phase -> data phase)
    logic        hsel_q;
    logic [11:0] haddr_q;
    logic        hwrite_q;
    logic [1:0]  htrans_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hsel_q   <= 1'b0;
            haddr_q  <= '0;
            hwrite_q <= 1'b0;
            htrans_q <= HTRANS_IDLE;
        end else begin
            hsel_q   <= hsel;
            haddr_q  <= haddr;
            hwrite_q <= hwrite;
            htrans_q <= htrans;
        end
    end

    // Zero wait-state
    assign hreadyout = 1'b1;
    assign hresp     = HRESP_OKAY;

    // Active transfer in data phase
    wire data_phase_valid = hsel_q && (htrans_q == HTRANS_NONSEQ);
    wire wr_en = data_phase_valid && hwrite_q;
    wire rd_en = data_phase_valid && !hwrite_q;

    // Word-aligned address for indexing
    wire [11:0] addr = haddr_q & 12'hFFC;

    // ---------------------------------------------------------------
    // Register file: Write logic
    // ---------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key               <= '0;
            text_in           <= '0;
            mode_reg          <= '0;
            iv                <= '0;
            j0                <= '0;
            dma_enable        <= 1'b0;
            block_mode        <= '0;
            block_num         <= '0;
            inc_sel           <= 1'b0;
            aad_block_num     <= '0;
            remainder_bit_num <= '0;
            int_ena           <= 1'b0;
            dma_src_addr      <= '0;
            dma_dst_addr      <= '0;
        end else if (wr_en) begin
            case (addr)
                // KEY registers (0x000-0x01C)
                ADDR_KEY0:          key[255:224] <= hwdata;
                ADDR_KEY0 + 12'h4:  key[223:192] <= hwdata;
                ADDR_KEY0 + 12'h8:  key[191:160] <= hwdata;
                ADDR_KEY0 + 12'hC:  key[159:128] <= hwdata;
                ADDR_KEY0 + 12'h10: key[127:96]  <= hwdata;
                ADDR_KEY0 + 12'h14: key[95:64]   <= hwdata;
                ADDR_KEY0 + 12'h18: key[63:32]   <= hwdata;
                ADDR_KEY7:          key[31:0]    <= hwdata;

                // TEXT_IN registers (0x020-0x02C)
                ADDR_TEXT_IN0:          text_in[127:96] <= hwdata;
                ADDR_TEXT_IN0 + 12'h4:  text_in[95:64]  <= hwdata;
                ADDR_TEXT_IN0 + 12'h8:  text_in[63:32]  <= hwdata;
                ADDR_TEXT_IN3:          text_in[31:0]   <= hwdata;

                // MODE (0x040)
                ADDR_MODE: mode_reg <= hwdata[2:0];

                // IV_MEM (0x050-0x05C)
                ADDR_IV0:          iv[127:96] <= hwdata;
                ADDR_IV0 + 12'h4:  iv[95:64]  <= hwdata;
                ADDR_IV0 + 12'h8:  iv[63:32]  <= hwdata;
                ADDR_IV3:          iv[31:0]   <= hwdata;

                // J0_MEM (0x070-0x07C)
                ADDR_J0_0:          j0[127:96] <= hwdata;
                ADDR_J0_0 + 12'h4:  j0[95:64]  <= hwdata;
                ADDR_J0_0 + 12'h8:  j0[63:32]  <= hwdata;
                ADDR_J0_3:          j0[31:0]   <= hwdata;

                // DMA config
                ADDR_DMA_ENA:     dma_enable        <= hwdata[0];
                ADDR_BLK_MODE:    block_mode        <= hwdata[2:0];
                ADDR_BLK_NUM:     block_num         <= hwdata;
                ADDR_INC_SEL:     inc_sel           <= hwdata[0];
                ADDR_AAD_BLK_NUM: aad_block_num     <= hwdata;
                ADDR_REM_BIT:     remainder_bit_num <= hwdata[6:0];
                ADDR_INT_ENA:     int_ena           <= hwdata[0];
                ADDR_DMA_SRC_ADDR: dma_src_addr     <= hwdata;
                ADDR_DMA_DST_ADDR: dma_dst_addr     <= hwdata;

                default: ; // Ignore writes to unknown/read-only addresses
            endcase
        end
    end

    // ---------------------------------------------------------------
    // Write-trigger pulses (active for one cycle on write)
    // ---------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            trigger_start <= 1'b0;
            continue_op   <= 1'b0;
            dma_exit      <= 1'b0;
            int_clr       <= 1'b0;
        end else begin
            trigger_start <= wr_en && (addr == ADDR_TRIGGER)  && hwdata[0];
            continue_op   <= wr_en && (addr == ADDR_CONT_OP)  && hwdata[0];
            dma_exit      <= wr_en && (addr == ADDR_DMA_EXIT) && hwdata[0];
            int_clr       <= wr_en && (addr == ADDR_INT_CLR)  && hwdata[0];
        end
    end

    // ---------------------------------------------------------------
    // Register file: Read logic (combinational, data-phase)
    // ---------------------------------------------------------------
    always_comb begin
        hrdata = 32'h0;
        if (rd_en) begin
            case (addr)
                ADDR_KEY0:          hrdata = key[255:224];
                ADDR_KEY0 + 12'h4:  hrdata = key[223:192];
                ADDR_KEY0 + 12'h8:  hrdata = key[191:160];
                ADDR_KEY0 + 12'hC:  hrdata = key[159:128];
                ADDR_KEY0 + 12'h10: hrdata = key[127:96];
                ADDR_KEY0 + 12'h14: hrdata = key[95:64];
                ADDR_KEY0 + 12'h18: hrdata = key[63:32];
                ADDR_KEY7:          hrdata = key[31:0];

                ADDR_TEXT_IN0:          hrdata = text_in[127:96];
                ADDR_TEXT_IN0 + 12'h4:  hrdata = text_in[95:64];
                ADDR_TEXT_IN0 + 12'h8:  hrdata = text_in[63:32];
                ADDR_TEXT_IN3:          hrdata = text_in[31:0];

                ADDR_TEXT_OUT0:          hrdata = text_out[127:96];
                ADDR_TEXT_OUT0 + 12'h4:  hrdata = text_out[95:64];
                ADDR_TEXT_OUT0 + 12'h8:  hrdata = text_out[63:32];
                ADDR_TEXT_OUT3:          hrdata = text_out[31:0];

                ADDR_MODE:    hrdata = {29'b0, mode_reg};
                ADDR_STATE:   hrdata = {30'b0, state};

                ADDR_IV0:          hrdata = iv[127:96];
                ADDR_IV0 + 12'h4:  hrdata = iv[95:64];
                ADDR_IV0 + 12'h8:  hrdata = iv[63:32];
                ADDR_IV3:          hrdata = iv[31:0];

                ADDR_H0:          hrdata = h_mem[127:96];
                ADDR_H0 + 12'h4:  hrdata = h_mem[95:64];
                ADDR_H0 + 12'h8:  hrdata = h_mem[63:32];
                ADDR_H3:          hrdata = h_mem[31:0];

                ADDR_J0_0:          hrdata = j0[127:96];
                ADDR_J0_0 + 12'h4:  hrdata = j0[95:64];
                ADDR_J0_0 + 12'h8:  hrdata = j0[63:32];
                ADDR_J0_3:          hrdata = j0[31:0];

                ADDR_T0_0:          hrdata = t0_mem[127:96];
                ADDR_T0_0 + 12'h4:  hrdata = t0_mem[95:64];
                ADDR_T0_0 + 12'h8:  hrdata = t0_mem[63:32];
                ADDR_T0_3:          hrdata = t0_mem[31:0];

                ADDR_DMA_ENA:       hrdata = {31'b0, dma_enable};
                ADDR_BLK_MODE:      hrdata = {29'b0, block_mode};
                ADDR_BLK_NUM:       hrdata = block_num;
                ADDR_INC_SEL:       hrdata = {31'b0, inc_sel};
                ADDR_AAD_BLK_NUM:   hrdata = aad_block_num;
                ADDR_REM_BIT:       hrdata = {25'b0, remainder_bit_num};
                ADDR_INT_ENA:       hrdata = {31'b0, int_ena};
                ADDR_DMA_SRC_ADDR:  hrdata = dma_src_addr;
                ADDR_DMA_DST_ADDR:  hrdata = dma_dst_addr;

                default: hrdata = 32'h0;
            endcase
        end
    end

    // ---------------------------------------------------------------
    // Interrupt logic
    // ---------------------------------------------------------------
    logic irq_pending_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            irq_pending_q <= 1'b0;
        else if (int_clr)
            irq_pending_q <= 1'b0;
        else if (irq_raw)
            irq_pending_q <= 1'b1;
    end

    assign irq = irq_pending_q & int_ena;

endmodule
