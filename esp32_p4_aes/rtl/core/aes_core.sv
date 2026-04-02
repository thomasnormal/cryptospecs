// AES Core -- Encrypt/Decrypt Controller
// Iterative single-round architecture with pre-computed key expansion.
// Latency: key expansion (Nk..4*Nr cycles) + Nr+1 round cycles + 1 done cycle

module aes_core
    import aes_accel_pkg::*;
(
    input  logic         clk,
    input  logic         rst_n,

    // Control
    input  logic         start,      // Pulse to begin operation
    input  logic         decrypt,    // 1=decrypt, 0=encrypt
    input  logic         aes256,     // 1=AES-256, 0=AES-128
    input  logic [255:0] key,        // Full key (AES-128 uses upper 128 bits)

    // Data
    input  logic [127:0] data_in,    // Plaintext (encrypt) or ciphertext (decrypt)
    output logic [127:0] data_out,   // Result
    output logic         busy,       // High while processing
    output logic         done        // One-cycle pulse when finished
);

    // ---------------------------------------------------------------
    // Key expansion
    // ---------------------------------------------------------------
    logic         ke_start;
    logic         ke_done;
    logic [127:0] round_keys [0:MAX_NR];

    aes_key_expand u_key_expand (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (ke_start),
        .aes256     (aes256),
        .key        (key),
        .round_keys (round_keys),
        .done       (ke_done)
    );

    // ---------------------------------------------------------------
    // Round computation (combinational)
    // ---------------------------------------------------------------
    logic [127:0] fwd_state_out;
    logic [127:0] inv_state_out;
    logic [127:0] round_state;    // Current state register
    logic [127:0] round_key_sel;  // Selected round key for current round
    logic         is_last;        // Last round indicator

    aes_round u_fwd_round (
        .state_in      (round_state),
        .round_key     (round_key_sel),
        .is_last_round (is_last),
        .state_out     (fwd_state_out)
    );

    aes_inv_round u_inv_round (
        .state_in      (round_state),
        .round_key     (round_key_sel),
        .is_last_round (is_last),
        .state_out     (inv_state_out)
    );

    // ---------------------------------------------------------------
    // FSM
    // ---------------------------------------------------------------
    typedef enum logic [2:0] {
        CORE_IDLE,
        CORE_KEY_EXPAND,
        CORE_INIT_ARK,     // Initial AddRoundKey
        CORE_ROUNDS,       // Iterative rounds
        CORE_DONE
    } core_state_e;

    core_state_e state_q;
    logic [3:0]  round_cnt_q;    // Current round number (1..Nr)
    logic [3:0]  nr;             // Total rounds

    assign nr = aes256 ? AES256_NR[3:0] : AES128_NR[3:0];

    // Round key selection
    always_comb begin
        if (decrypt)
            round_key_sel = round_keys[nr - round_cnt_q]; // Reverse order for decrypt rounds
        else
            round_key_sel = round_keys[round_cnt_q];       // Forward order for encrypt rounds
    end

    // Last round detection
    assign is_last = (round_cnt_q == nr);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q     <= CORE_IDLE;
            round_cnt_q <= '0;
            round_state <= '0;
            data_out    <= '0;
            busy        <= 1'b0;
            done        <= 1'b0;
            ke_start    <= 1'b0;
        end else begin
            done     <= 1'b0;
            ke_start <= 1'b0;

            case (state_q)
                CORE_IDLE: begin
                    if (start) begin
                        ke_start <= 1'b1;
                        busy     <= 1'b1;
                        state_q  <= CORE_KEY_EXPAND;
                    end
                end

                CORE_KEY_EXPAND: begin
                    if (ke_done) begin
                        // Initial AddRoundKey: state = data_in ^ round_key[0] (encrypt) or round_key[Nr] (decrypt)
                        if (decrypt)
                            round_state <= data_in ^ round_keys[nr];
                        else
                            round_state <= data_in ^ round_keys[0];
                        round_cnt_q <= 4'd1;
                        state_q     <= CORE_ROUNDS;
                    end
                end

                CORE_ROUNDS: begin
                    // Apply one round
                    if (decrypt)
                        round_state <= inv_state_out;
                    else
                        round_state <= fwd_state_out;

                    if (round_cnt_q == nr) begin
                        // Final round complete
                        if (decrypt)
                            data_out <= inv_state_out;
                        else
                            data_out <= fwd_state_out;
                        state_q <= CORE_DONE;
                    end else begin
                        round_cnt_q <= round_cnt_q + 1;
                    end
                end

                CORE_DONE: begin
                    done    <= 1'b1;
                    busy    <= 1'b0;
                    state_q <= CORE_IDLE;
                end

                default: state_q <= CORE_IDLE;
            endcase
        end
    end

endmodule
