// Block Cipher Mode Controller
// Implements pre/post processing for ECB, CBC, OFB, CTR, CFB128.
// Sits between data source (register file or DMA) and AES core.

module block_mode_ctrl
    import aes_accel_pkg::*;
(
    input  logic         clk,
    input  logic         rst_n,

    // Configuration
    input  blk_mode_e   block_mode,
    input  logic         decrypt,
    input  logic [127:0] iv_in,       // Initial IV from register file
    input  logic         inc_sel,     // 0=INC32 (big-endian lower 32), 1=INC128

    // Data interface (from DMA or register file)
    input  logic [127:0] data_in,
    input  logic         data_in_valid,
    output logic         data_in_ready,

    // AES core interface
    output logic [127:0] core_data_in,
    output logic         core_start,
    input  logic [127:0] core_data_out,
    input  logic         core_done,

    // Output
    output logic [127:0] data_out,
    output logic         data_out_valid,

    // Control
    input  logic         flush,       // Reset internal state (new operation)
    output logic         busy
);

    // Internal IV register (updated across blocks)
    logic [127:0] iv_q;
    logic         first_block_q;
    logic         waiting_core_q;
    logic [127:0] saved_data_q;

    // Counter increment functions
    function automatic logic [127:0] inc32(input logic [127:0] ctr);
        // Increment the lower 32 bits (big-endian)
        inc32 = {ctr[127:32], ctr[31:0] + 32'd1};
    endfunction

    function automatic logic [127:0] inc128(input logic [127:0] ctr);
        inc128 = ctr + 128'd1;
    endfunction

    // FSM
    typedef enum logic [1:0] {
        BM_IDLE,
        BM_WAIT_CORE,
        BM_OUTPUT
    } bm_state_e;

    bm_state_e state_q;

    assign busy = (state_q != BM_IDLE);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q        <= BM_IDLE;
            iv_q           <= '0;
            first_block_q  <= 1'b1;
            waiting_core_q <= 1'b0;
            saved_data_q   <= '0;
            core_start     <= 1'b0;
            core_data_in   <= '0;
            data_out       <= '0;
            data_out_valid <= 1'b0;
            data_in_ready  <= 1'b0;
        end else begin
            core_start     <= 1'b0;
            data_out_valid <= 1'b0;
            data_in_ready  <= 1'b0;

            if (flush) begin
                state_q       <= BM_IDLE;
                iv_q          <= iv_in;
                first_block_q <= 1'b1;
            end else begin
                case (state_q)
                    BM_IDLE: begin
                        if (data_in_valid) begin
                            data_in_ready <= 1'b1;
                            saved_data_q  <= data_in;

                            // Load IV on first block
                            if (first_block_q)
                                iv_q <= iv_in;

                            case (block_mode)
                                BLK_ECB: begin
                                    // ECB: pass-through
                                    core_data_in <= data_in;
                                    core_start   <= 1'b1;
                                end

                                BLK_CBC: begin
                                    if (decrypt) begin
                                        // CBC decrypt: encrypt the ciphertext block
                                        core_data_in <= data_in;
                                    end else begin
                                        // CBC encrypt: plaintext XOR IV
                                        core_data_in <= data_in ^ (first_block_q ? iv_in : iv_q);
                                    end
                                    core_start <= 1'b1;
                                end

                                BLK_OFB: begin
                                    // OFB: encrypt IV (always encrypt, regardless of direction)
                                    core_data_in <= first_block_q ? iv_in : iv_q;
                                    core_start   <= 1'b1;
                                end

                                BLK_CTR: begin
                                    // CTR: encrypt counter (always encrypt)
                                    core_data_in <= first_block_q ? iv_in : iv_q;
                                    core_start   <= 1'b1;
                                end

                                BLK_CFB128: begin
                                    // CFB128: encrypt IV/feedback
                                    core_data_in <= first_block_q ? iv_in : iv_q;
                                    core_start   <= 1'b1;
                                end

                                default: begin
                                    core_data_in <= data_in;
                                    core_start   <= 1'b1;
                                end
                            endcase

                            state_q       <= BM_WAIT_CORE;
                            first_block_q <= 1'b0;
                        end
                    end

                    BM_WAIT_CORE: begin
                        if (core_done) begin
                            case (block_mode)
                                BLK_ECB: begin
                                    data_out <= core_data_out;
                                end

                                BLK_CBC: begin
                                    if (decrypt) begin
                                        data_out <= core_data_out ^ iv_q;
                                        iv_q     <= saved_data_q; // IV = ciphertext
                                    end else begin
                                        data_out <= core_data_out;
                                        iv_q     <= core_data_out; // IV = output ciphertext
                                    end
                                end

                                BLK_OFB: begin
                                    data_out <= core_data_out ^ saved_data_q;
                                    iv_q     <= core_data_out; // IV = cipher output
                                end

                                BLK_CTR: begin
                                    data_out <= core_data_out ^ saved_data_q;
                                    if (inc_sel)
                                        iv_q <= inc128(iv_q);
                                    else
                                        iv_q <= inc32(iv_q);
                                end

                                BLK_CFB128: begin
                                    if (decrypt) begin
                                        data_out <= core_data_out ^ saved_data_q;
                                        iv_q     <= saved_data_q; // IV = ciphertext input
                                    end else begin
                                        data_out <= core_data_out ^ saved_data_q;
                                        iv_q     <= core_data_out ^ saved_data_q; // IV = output ciphertext
                                    end
                                end

                                default: begin
                                    data_out <= core_data_out;
                                end
                            endcase

                            data_out_valid <= 1'b1;
                            state_q        <= BM_IDLE;
                        end
                    end

                    default: state_q <= BM_IDLE;
                endcase
            end
        end
    end

endmodule
