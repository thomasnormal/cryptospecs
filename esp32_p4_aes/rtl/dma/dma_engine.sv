// DMA Engine
// Reads source data from memory via AXI, feeds blocks through the cipher pipeline,
// and writes results back to memory via AXI.
// Each AES block (128 bits) is transferred as 4 x 32-bit AXI beats.

module dma_engine
    import aes_accel_pkg::*;
(
    input  logic         clk,
    input  logic         rst_n,

    // Configuration (from register file)
    input  logic         start,          // Trigger pulse
    input  logic         dma_enable,
    input  logic [31:0]  block_num,      // Number of 128-bit blocks
    input  logic [31:0]  src_addr,
    input  logic [31:0]  dst_addr,
    input  logic         dma_exit_cmd,   // DMA exit command

    // AXI master read interface
    output logic [31:0]  axi_rd_addr,
    output logic [7:0]   axi_rd_len,
    output logic         axi_rd_req,
    input  logic         axi_rd_grant,
    input  logic [31:0]  axi_rd_data,
    input  logic         axi_rd_valid,
    input  logic         axi_rd_last,

    // AXI master write interface
    output logic [31:0]  axi_wr_addr,
    output logic [7:0]   axi_wr_len,
    output logic         axi_wr_req,
    input  logic         axi_wr_grant,
    output logic [31:0]  axi_wr_data,
    output logic         axi_wr_valid,
    input  logic         axi_wr_ready,
    input  logic         axi_wr_resp_ok,

    // Cipher interface
    output logic [127:0] cipher_data_in,
    output logic         cipher_data_valid,
    input  logic         cipher_data_ready,
    input  logic [127:0] cipher_data_out,
    input  logic         cipher_data_out_valid,

    // Status
    output logic         dma_done,       // Pulse when all blocks processed
    output accel_state_e dma_state
);

    typedef enum logic [2:0] {
        DMA_IDLE,
        DMA_READ_REQ,
        DMA_READ_DATA,
        DMA_CIPHER,
        DMA_WRITE_REQ,
        DMA_WRITE_DATA,
        DMA_DONE_ST
    } dma_fsm_e;

    dma_fsm_e fsm_q;
    logic [31:0] blk_cnt_q;        // Blocks remaining
    logic [31:0] cur_src_q;        // Current source address
    logic [31:0] cur_dst_q;        // Current destination address
    logic [127:0] rd_buffer_q;     // Accumulate 4 beats into 128-bit block
    logic [1:0]  beat_cnt_q;       // Beat counter within a block (0-3)
    logic [127:0] wr_buffer_q;     // Cipher output to write
    logic [1:0]  wr_beat_cnt_q;
    logic         cipher_accepted_q; // Set when BMC accepts block; prevents re-asserting valid

    // State output
    always_comb begin
        case (fsm_q)
            DMA_IDLE:    dma_state = ST_IDLE;
            DMA_DONE_ST: dma_state = ST_DONE;
            default:     dma_state = ST_WORK;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fsm_q            <= DMA_IDLE;
            blk_cnt_q        <= '0;
            cur_src_q        <= '0;
            cur_dst_q        <= '0;
            rd_buffer_q      <= '0;
            beat_cnt_q       <= '0;
            wr_buffer_q      <= '0;
            wr_beat_cnt_q    <= '0;
            axi_rd_req       <= 1'b0;
            axi_rd_addr      <= '0;
            axi_rd_len       <= '0;
            axi_wr_req       <= 1'b0;
            axi_wr_addr      <= '0;
            axi_wr_len       <= '0;
            axi_wr_valid     <= 1'b0;
            cipher_data_in    <= '0;
            cipher_data_valid <= 1'b0;
            cipher_accepted_q <= 1'b0;
            dma_done          <= 1'b0;
        end else begin
            dma_done          <= 1'b0;
            axi_rd_req        <= 1'b0;
            axi_wr_req        <= 1'b0;
            cipher_data_valid <= 1'b0;
            axi_wr_valid      <= 1'b0;

            case (fsm_q)
                DMA_IDLE: begin
                    if (start && dma_enable) begin
                        blk_cnt_q <= block_num;
                        cur_src_q <= src_addr;
                        cur_dst_q <= dst_addr;
                        beat_cnt_q <= '0;
                        fsm_q     <= DMA_READ_REQ;
                    end
                end

                DMA_READ_REQ: begin
                    if (blk_cnt_q == 0) begin
                        dma_done <= 1'b1;
                        fsm_q    <= DMA_DONE_ST;
                    end else begin
                        axi_rd_addr       <= cur_src_q;
                        axi_rd_len        <= 8'd3;  // 4 beats
                        axi_rd_req        <= 1'b1;
                        beat_cnt_q        <= '0;
                        cipher_accepted_q <= 1'b0;  // Reset for each new block
                        fsm_q             <= DMA_READ_DATA;
                    end
                end

                DMA_READ_DATA: begin
                    if (axi_rd_valid) begin
                        // Accumulate beats into 128-bit block (MSB first)
                        case (beat_cnt_q)
                            2'd0: rd_buffer_q[127:96] <= axi_rd_data;
                            2'd1: rd_buffer_q[95:64]  <= axi_rd_data;
                            2'd2: rd_buffer_q[63:32]  <= axi_rd_data;
                            2'd3: rd_buffer_q[31:0]   <= axi_rd_data;
                        endcase
                        beat_cnt_q <= beat_cnt_q + 1;

                        if (axi_rd_last) begin
                            fsm_q <= DMA_CIPHER;
                        end
                    end
                end

                DMA_CIPHER: begin
                    // Present block to cipher and wait for result.
                    // Only assert valid until BMC accepts (cipher_data_ready).
                    // Without this guard, cipher_data_valid would be re-asserted every
                    // cycle and the BMC would start a spurious second operation as soon
                    // as it returns to BM_IDLE after the real one completes.
                    cipher_data_in <= rd_buffer_q;

                    if (!cipher_accepted_q) begin
                        cipher_data_valid <= 1'b1;
                    end

                    if (cipher_data_ready) begin
                        cipher_accepted_q <= 1'b1;
                    end

                    if (cipher_data_out_valid) begin
                        wr_buffer_q   <= cipher_data_out;
                        wr_beat_cnt_q <= '0;
                        fsm_q         <= DMA_WRITE_REQ;
                    end
                end

                DMA_WRITE_REQ: begin
                    axi_wr_addr <= cur_dst_q;
                    axi_wr_len  <= 8'd3;  // 4 beats
                    axi_wr_req  <= 1'b1;
                    fsm_q       <= DMA_WRITE_DATA;
                end

                DMA_WRITE_DATA: begin
                    axi_wr_valid <= 1'b1;

                    if (axi_wr_ready) begin
                        if (wr_beat_cnt_q == 2'd3) begin
                            // Block write complete
                            cur_src_q <= cur_src_q + 32'd16;
                            cur_dst_q <= cur_dst_q + 32'd16;
                            blk_cnt_q <= blk_cnt_q - 1;
                            fsm_q     <= DMA_READ_REQ;
                        end else begin
                            wr_beat_cnt_q <= wr_beat_cnt_q + 1;
                        end
                    end
                end

                DMA_DONE_ST: begin
                    // Stay here until software writes DMA_EXIT
                    if (dma_exit_cmd) begin
                        fsm_q <= DMA_IDLE;
                    end
                end

                default: fsm_q <= DMA_IDLE;
            endcase
        end
    end

    // Drive write data combinationally so each beat's data is immediately
    // valid when wr_beat_cnt_q updates (avoids one-cycle lag with registered outputs)
    always_comb begin
        case (wr_beat_cnt_q)
            2'd0: axi_wr_data = wr_buffer_q[127:96];
            2'd1: axi_wr_data = wr_buffer_q[95:64];
            2'd2: axi_wr_data = wr_buffer_q[63:32];
            2'd3: axi_wr_data = wr_buffer_q[31:0];
            default: axi_wr_data = '0;
        endcase
    end

endmodule
