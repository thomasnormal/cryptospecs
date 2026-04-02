// AES Key Expansion
// Pre-computes all round keys and stores them in an array.
// Iterative: produces one round key per clock cycle.
// AES-128: 11 round keys (Nk=4, Nr=10), AES-256: 15 round keys (Nk=8, Nr=14)

module aes_key_expand
    import aes_accel_pkg::*;
(
    input  logic         clk,
    input  logic         rst_n,
    input  logic         start,    // Pulse to begin key expansion
    input  logic         aes256,   // 0=AES-128, 1=AES-256
    input  logic [255:0] key,      // Cipher key (AES-128 uses [255:128])
    output logic [127:0] round_keys [0:MAX_NR], // All round keys
    output logic         done       // Pulse when all keys ready
);

    // AES round constants (Rcon)
    logic [7:0] rcon [0:9];
    assign rcon[0] = 8'h01;
    assign rcon[1] = 8'h02;
    assign rcon[2] = 8'h04;
    assign rcon[3] = 8'h08;
    assign rcon[4] = 8'h10;
    assign rcon[5] = 8'h20;
    assign rcon[6] = 8'h40;
    assign rcon[7] = 8'h80;
    assign rcon[8] = 8'h1B;
    assign rcon[9] = 8'h36;

    // S-box instances for SubWord (4 bytes)
    logic [7:0] sw_in  [0:3];
    logic [7:0] sw_out [0:3];

    genvar gi;
    generate
        for (gi = 0; gi < 4; gi++) begin : gen_sbox
            aes_sbox u_sbox (
                .data_in  (sw_in[gi]),
                .inverse  (1'b0),
                .data_out (sw_out[gi])
            );
        end
    endgenerate

    // Internal state
    typedef enum logic [1:0] {
        KE_IDLE,
        KE_EXPAND,
        KE_DONE
    } ke_state_e;

    ke_state_e state_q, state_d;
    logic [5:0] word_idx_q; // Current word index being generated (4..43 for AES-128, 8..59 for AES-256)
    logic [3:0] rcon_idx_q;
    logic [3:0] nk;         // 4 for AES-128, 8 for AES-256
    logic [3:0] nr_plus1;   // Number of round keys to generate

    assign nk       = aes256 ? 4'd8 : 4'd4;
    assign nr_plus1 = aes256 ? 4'd15 : 4'd11;

    // Word storage: up to 60 words for AES-256
    logic [31:0] w [0:59];

    // Combinational: RotWord input to S-box
    logic [31:0] prev_word;   // w[i-1]
    logic [31:0] nk_back;     // w[i-Nk]
    logic        need_rot;
    logic        need_sub_only; // AES-256 SubWord without RotWord at i mod 8 == 4
    logic [31:0] after_sub;
    logic [31:0] new_word;

    always_comb begin
        prev_word = w[word_idx_q - 1];
        nk_back   = w[word_idx_q - nk];

        need_rot      = (word_idx_q % nk) == 0;
        need_sub_only = aes256 && ((word_idx_q % nk) == 4);

        // RotWord: rotate left by one byte
        if (need_rot) begin
            sw_in[0] = prev_word[23:16]; // byte 1 -> position 0
            sw_in[1] = prev_word[15:8];  // byte 2 -> position 1
            sw_in[2] = prev_word[7:0];   // byte 3 -> position 2
            sw_in[3] = prev_word[31:24]; // byte 0 -> position 3
        end else begin
            sw_in[0] = prev_word[31:24];
            sw_in[1] = prev_word[23:16];
            sw_in[2] = prev_word[15:8];
            sw_in[3] = prev_word[7:0];
        end

        after_sub = {sw_out[0], sw_out[1], sw_out[2], sw_out[3]};

        if (need_rot)
            new_word = nk_back ^ after_sub ^ {rcon[rcon_idx_q], 24'h0};
        else if (need_sub_only)
            new_word = nk_back ^ after_sub;
        else
            new_word = nk_back ^ prev_word;
    end

    // FSM
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q    <= KE_IDLE;
            word_idx_q <= '0;
            rcon_idx_q <= '0;
            done       <= 1'b0;
            for (int j = 0; j < 60; j++)
                w[j] <= '0;
            for (int j = 0; j <= MAX_NR; j++)
                round_keys[j] <= '0;
        end else begin
            done <= 1'b0;

            case (state_q)
                KE_IDLE: begin
                    if (start) begin
                        // Load initial key words
                        if (aes256) begin
                            w[0] <= key[255:224];
                            w[1] <= key[223:192];
                            w[2] <= key[191:160];
                            w[3] <= key[159:128];
                            w[4] <= key[127:96];
                            w[5] <= key[95:64];
                            w[6] <= key[63:32];
                            w[7] <= key[31:0];
                            word_idx_q <= 6'd8;
                        end else begin
                            w[0] <= key[255:224];
                            w[1] <= key[223:192];
                            w[2] <= key[191:160];
                            w[3] <= key[159:128];
                            word_idx_q <= 6'd4;
                        end
                        rcon_idx_q <= '0;
                        state_q    <= KE_EXPAND;
                    end
                end

                KE_EXPAND: begin
                    w[word_idx_q] <= new_word;

                    if (need_rot)
                        rcon_idx_q <= rcon_idx_q + 1;

                    // Check if we've generated enough words
                    // AES-128 needs words 0..43 (11 round keys), AES-256 needs 0..59 (15 round keys)
                    if (word_idx_q == (aes256 ? 6'd59 : 6'd43)) begin
                        state_q <= KE_DONE;
                    end else begin
                        word_idx_q <= word_idx_q + 1;
                    end
                end

                KE_DONE: begin
                    // Pack words into round keys
                    for (int rk = 0; rk < MAX_RK; rk++) begin
                        if (rk < nr_plus1)
                            round_keys[rk] <= {w[4*rk], w[4*rk+1], w[4*rk+2], w[4*rk+3]};
                    end
                    done    <= 1'b1;
                    state_q <= KE_IDLE;
                end

                default: state_q <= KE_IDLE;
            endcase
        end
    end

endmodule
