// GCM Mode Controller
// Implements GCM authenticated encryption/decryption.
// Two-phase operation:
//   Phase 1 (TRIGGER): Compute H = AES_K(0), process AAD, encrypt/decrypt data blocks
//   Phase 2 (CONTINUE_OP): Compute final tag T = GHASH(len_block) ^ AES_K(J0)

module gcm_unit
    import aes_accel_pkg::*;
(
    input  logic         clk,
    input  logic         rst_n,

    // Control
    input  logic         start,         // Begin GCM phase 1
    input  logic         continue_op,   // Begin GCM phase 2
    input  logic         decrypt,

    // Configuration
    input  logic [255:0] key,
    input  logic         aes256,
    input  logic [127:0] iv,            // IV from register
    input  logic [127:0] j0_in,         // J0 from register (written by SW between phases)
    input  logic [31:0]  aad_block_num,
    input  logic [31:0]  block_num,     // Data block count
    input  logic [6:0]   remainder_bit_num,

    // Data interface (from DMA engine)
    input  logic [127:0] data_in,
    input  logic         data_in_valid,
    output logic         data_in_ready,
    output logic [127:0] data_out,
    output logic         data_out_valid,

    // AES core interface (shared)
    output logic [127:0] core_data_in,
    output logic         core_start,
    output logic         core_decrypt,  // GCM always encrypts
    input  logic [127:0] core_data_out,
    input  logic         core_done,
    input  logic         core_busy,

    // Outputs
    output logic [127:0] h_out,         // H subkey for H_MEM
    output logic [127:0] t0_out,        // Authentication tag for T0_MEM
    output logic         phase1_done,   // Phase 1 complete
    output logic         phase2_done,   // Phase 2 complete (final done)
    output logic         busy
);

    typedef enum logic [3:0] {
        GCM_IDLE,
        GCM_COMPUTE_H,       // Encrypt zero block to get H
        GCM_WAIT_H,
        GCM_AAD,             // Process AAD blocks through GHASH
        GCM_WAIT_GHASH_AAD,
        GCM_DATA,            // Encrypt data + GHASH ciphertext
        GCM_WAIT_AES_DATA,
        GCM_WAIT_GHASH_DATA,
        GCM_PHASE1_DONE,     // Wait for continue_op
        GCM_TAG_LEN,         // GHASH the length block
        GCM_WAIT_GHASH_LEN,
        GCM_TAG_ENC,         // Encrypt J0 for tag masking
        GCM_WAIT_TAG_ENC,
        GCM_PHASE2_DONE
    } gcm_state_e;

    gcm_state_e state_q;

    logic [127:0] h_q;          // Hash subkey
    logic [127:0] ctr_q;        // Counter (J0+1, J0+2, ...)
    logic [31:0]  aad_cnt_q;    // AAD blocks remaining
    logic [31:0]  data_cnt_q;   // Data blocks remaining
    logic [127:0] saved_ct_q;   // Saved ciphertext for GHASH

    // GHASH interface
    logic         ghash_clear;
    logic [127:0] ghash_block;
    logic         ghash_valid;
    logic         ghash_ready;
    logic [127:0] ghash_out;
    logic         ghash_done;

    ghash u_ghash (
        .clk         (clk),
        .rst_n       (rst_n),
        .clear       (ghash_clear),
        .h           (h_q),
        .block_in    (ghash_block),
        .block_valid (ghash_valid),
        .block_ready (ghash_ready),
        .ghash_out   (ghash_out),
        .done        (ghash_done)
    );

    // GCM always uses AES in encrypt mode
    assign core_decrypt = 1'b0;

    assign busy = (state_q != GCM_IDLE) && (state_q != GCM_PHASE1_DONE);

    // Counter increment (INC32: increment lower 32 bits, big-endian)
    function automatic logic [127:0] inc32(input logic [127:0] c);
        inc32 = {c[127:32], c[31:0] + 32'd1};
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q       <= GCM_IDLE;
            h_q           <= '0;
            h_out         <= '0;
            t0_out        <= '0;
            ctr_q         <= '0;
            aad_cnt_q     <= '0;
            data_cnt_q    <= '0;
            saved_ct_q    <= '0;
            core_data_in  <= '0;
            core_start    <= 1'b0;
            data_in_ready <= 1'b0;
            data_out      <= '0;
            data_out_valid <= 1'b0;
            phase1_done   <= 1'b0;
            phase2_done   <= 1'b0;
            ghash_clear   <= 1'b0;
            ghash_block   <= '0;
            ghash_valid   <= 1'b0;
        end else begin
            core_start     <= 1'b0;
            data_in_ready  <= 1'b0;
            data_out_valid <= 1'b0;
            phase1_done    <= 1'b0;
            phase2_done    <= 1'b0;
            ghash_clear    <= 1'b0;
            ghash_valid    <= 1'b0;

            case (state_q)
                GCM_IDLE: begin
                    if (start) begin
                        // Start phase 1: compute H = AES_K(0^128)
                        core_data_in <= 128'h0;
                        core_start   <= 1'b1;
                        ghash_clear  <= 1'b1;
                        aad_cnt_q    <= aad_block_num;
                        data_cnt_q   <= block_num;
                        state_q      <= GCM_WAIT_H;
                    end
                end

                GCM_WAIT_H: begin
                    if (core_done) begin
                        h_q   <= core_data_out;
                        h_out <= core_data_out;
                        if (aad_cnt_q > 0)
                            state_q <= GCM_AAD;
                        else if (data_cnt_q > 0)
                            state_q <= GCM_DATA;
                        else
                            state_q <= GCM_PHASE1_DONE;
                    end
                end

                GCM_AAD: begin
                    // Feed AAD blocks through GHASH only (no encryption)
                    if (data_in_valid && ghash_ready) begin
                        data_in_ready <= 1'b1;
                        ghash_block   <= data_in;
                        ghash_valid   <= 1'b1;
                        state_q       <= GCM_WAIT_GHASH_AAD;
                    end
                end

                GCM_WAIT_GHASH_AAD: begin
                    if (ghash_done) begin
                        aad_cnt_q <= aad_cnt_q - 1;
                        if (aad_cnt_q == 1) begin
                            // AAD done, move to data
                            if (data_cnt_q > 0) begin
                                // Initialize counter from IV (J0 not yet known; use IV+1)
                                ctr_q   <= inc32(iv);
                                state_q <= GCM_DATA;
                            end else begin
                                state_q <= GCM_PHASE1_DONE;
                            end
                        end else begin
                            state_q <= GCM_AAD;
                        end
                    end
                end

                GCM_DATA: begin
                    // Encrypt counter, then XOR with plaintext and GHASH ciphertext
                    if (data_in_valid && !core_busy) begin
                        data_in_ready <= 1'b1;
                        saved_ct_q    <= data_in; // Save for XOR after encryption
                        core_data_in  <= ctr_q;
                        core_start    <= 1'b1;
                        state_q       <= GCM_WAIT_AES_DATA;
                    end
                end

                GCM_WAIT_AES_DATA: begin
                    if (core_done) begin
                        logic [127:0] ct_or_pt;
                        if (decrypt) begin
                            // Decrypt: GHASH the ciphertext input, output plaintext
                            ct_or_pt   = core_data_out ^ saved_ct_q;
                            ghash_block <= saved_ct_q;  // GHASH over ciphertext
                        end else begin
                            // Encrypt: output ciphertext, GHASH the ciphertext
                            ct_or_pt    = core_data_out ^ saved_ct_q;
                            ghash_block <= ct_or_pt;    // GHASH over ciphertext
                        end
                        data_out       <= ct_or_pt;
                        data_out_valid <= 1'b1;
                        ghash_valid    <= 1'b1;
                        ctr_q          <= inc32(ctr_q);
                        state_q        <= GCM_WAIT_GHASH_DATA;
                    end
                end

                GCM_WAIT_GHASH_DATA: begin
                    if (ghash_done) begin
                        data_cnt_q <= data_cnt_q - 1;
                        if (data_cnt_q == 1)
                            state_q <= GCM_PHASE1_DONE;
                        else
                            state_q <= GCM_DATA;
                    end
                end

                GCM_PHASE1_DONE: begin
                    phase1_done <= 1'b1;
                    if (continue_op) begin
                        // Phase 2: GHASH the length block, then encrypt J0
                        // Length block = [len(A) || len(C)] in bits, 64 bits each
                        ghash_block <= {aad_block_num, 25'b0, remainder_bit_num,   // len(A) in bits
                                        block_num[24:0], remainder_bit_num};        // len(C) in bits
                        // Simplified: actual GCM uses 64-bit bit lengths
                        // len(A) = aad_block_num * 128, len(C) = block_num * 128 - (128 - remainder)
                        ghash_block <= {32'b0, aad_block_num << 7,    // len(A) in bits (64-bit)
                                        32'b0, block_num << 7};       // len(C) in bits (64-bit)
                        ghash_valid <= 1'b1;
                        state_q     <= GCM_WAIT_GHASH_LEN;
                    end
                end

                GCM_WAIT_GHASH_LEN: begin
                    if (ghash_done) begin
                        // Encrypt J0 for tag masking
                        core_data_in <= j0_in;
                        core_start   <= 1'b1;
                        state_q      <= GCM_WAIT_TAG_ENC;
                    end
                end

                GCM_WAIT_TAG_ENC: begin
                    if (core_done) begin
                        // T = GHASH_out ^ AES_K(J0)
                        t0_out  <= ghash_out ^ core_data_out;
                        state_q <= GCM_PHASE2_DONE;
                    end
                end

                GCM_PHASE2_DONE: begin
                    phase2_done <= 1'b1;
                    state_q     <= GCM_IDLE;
                end

                default: state_q <= GCM_IDLE;
            endcase
        end
    end

endmodule
