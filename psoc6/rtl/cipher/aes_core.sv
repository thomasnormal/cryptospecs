// PSoC 6 Crypto — AES Core
//
// Implements AES-128/192/256 encrypt and decrypt using the PSoC 6 V2
// register-buffer interface.  Fixed block assignments per crypto_isa_pkg:
//   BLOCK0 (id=0) — input  (plaintext for encrypt, ciphertext for decrypt)
//   BLOCK1 (id=1) — output (ciphertext for encrypt, plaintext for decrypt)
//   BLOCK4 (id=4) — key[127:0]    (first 16 key bytes; all key sizes)
//   BLOCK5 (id=5) — key[255:128]  (bytes 16-31; AES-192/256 only)
//
// Latency (AES-128 example):
//   3  cycles  : load BLOCK4, BLOCK5, BLOCK0
//   42 cycles  : key expansion (IDLE→EXPAND×40→DONE)
//   1  cycle   : initial AddRoundKey
//   10 cycles  : 10 cipher rounds
//   1  cycle   : store result to BLOCK1
//   ─────────────────────────────
//   57 cycles total (AES-128); ~73 for AES-256

`include "crypto_pkg.sv"
`include "crypto_isa_pkg.sv"

module aes_core
    import crypto_pkg::*;
    import crypto_isa_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    // From instr_decoder / AES_CTL register
    input  logic [1:0]  key_size,   // AES_KEY128 / AES_KEY192 / AES_KEY256
    input  logic        decrypt,    // 0 = encrypt, 1 = decrypt
    input  logic        start,      // One-cycle start pulse

    // To instr_decoder
    output logic        busy,       // High from start until result stored

    // Register buffer engine port (one read + one write, combinational read)
    output logic [3:0]  eng_rd_addr,
    input  logic [127:0] eng_rd_data,
    output logic [3:0]  eng_wr_addr,
    output logic [127:0] eng_wr_data,
    output logic        eng_wr_en
);

    // ---------------------------------------------------------------
    // State machine
    // ---------------------------------------------------------------
    typedef enum logic [2:0] {
        ST_IDLE,
        ST_LOAD0,    // drive eng_rd_addr=BLOCK4; latch key_lo at clock edge
        ST_LOAD1,    // drive eng_rd_addr=BLOCK5; latch key_hi at clock edge
        ST_LOAD2,    // drive eng_rd_addr=BLOCK0; latch plaintext; assert ke_start
        ST_KEY_EXP,  // wait for key expansion done
        ST_INIT,     // apply initial AddRoundKey, set round counter
        ST_ROUND,    // iterate Nr cipher rounds (one per cycle)
        ST_STORE     // write state to BLOCK1, deassert busy
    } aes_phase_e;

    aes_phase_e phase_q;
    logic [1:0]  key_size_q;
    logic        decrypt_q;
    logic [127:0] key_lo_q;    // BLOCK4 (key bytes 0-15)
    logic [127:0] key_hi_q;    // BLOCK5 (key bytes 16-31)
    logic [127:0] pt_q;        // input block (plaintext or ciphertext)
    logic [127:0] state_q;     // current AES state
    logic [3:0]  round_cnt_q; // current round index

    // Nr (number of rounds) from registered key size
    logic [3:0] Nr_q;
    assign Nr_q = (key_size_q == AES_KEY192) ? 4'd12 :
                  (key_size_q == AES_KEY256) ? 4'd14 : 4'd10;

    // ---------------------------------------------------------------
    // Key expansion submodule
    // ---------------------------------------------------------------
    logic        ke_start, ke_done;
    logic [255:0] ke_key;
    logic [127:0] round_keys [0:AES_MAX_NR];

    // ke_start: pulse while in ST_LOAD2 (key_expand is idle at that point)
    assign ke_start = (phase_q == ST_LOAD2);
    // BLOCK4 = key[255:128] in expand convention; BLOCK5 = key[127:0]
    assign ke_key = {key_lo_q, key_hi_q};

    aes_key_expand u_ke (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (ke_start),
        .key_size   (key_size_q),
        .key        (ke_key),
        .round_keys (round_keys),
        .done       (ke_done)
    );

    // ---------------------------------------------------------------
    // Combinational round functions
    // ---------------------------------------------------------------
    logic [127:0] fwd_out, inv_out;
    logic         is_last_fwd, is_last_inv;

    assign is_last_fwd = (round_cnt_q == Nr_q);
    assign is_last_inv = (round_cnt_q == 4'd0);

    aes_round u_fwd (
        .state_in     (state_q),
        .round_key    (round_keys[round_cnt_q]),
        .is_last_round(is_last_fwd),
        .state_out    (fwd_out)
    );

    aes_inv_round u_inv (
        .state_in     (state_q),
        .round_key    (round_keys[round_cnt_q]),
        .is_last_round(is_last_inv),
        .state_out    (inv_out)
    );

    // ---------------------------------------------------------------
    // Output assignments
    // ---------------------------------------------------------------
    assign busy = (phase_q != ST_IDLE);

    // eng_rd_addr: driven combinationally based on current load state
    always_comb begin
        case (phase_q)
            ST_LOAD0: eng_rd_addr = BLKID_BLOCK4; // key[127:0]
            ST_LOAD1: eng_rd_addr = BLKID_BLOCK5; // key[255:128]
            ST_LOAD2: eng_rd_addr = BLKID_BLOCK0; // plaintext
            default:  eng_rd_addr = 4'd0;
        endcase
    end

    // eng write: active only in ST_STORE
    assign eng_wr_addr = BLKID_BLOCK1;           // ciphertext/plaintext output
    assign eng_wr_data = state_q;
    assign eng_wr_en   = (phase_q == ST_STORE);

    // ---------------------------------------------------------------
    // FSM
    // ---------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_q     <= ST_IDLE;
            key_size_q  <= AES_KEY128;
            decrypt_q   <= 1'b0;
            key_lo_q    <= '0;
            key_hi_q    <= '0;
            pt_q        <= '0;
            state_q     <= '0;
            round_cnt_q <= 4'd0;
        end else begin
            case (phase_q)

                ST_IDLE: begin
                    if (start) begin
                        key_size_q <= key_size;
                        decrypt_q  <= decrypt;
                        phase_q    <= ST_LOAD0;
                    end
                end

                ST_LOAD0: begin
                    // eng_rd_addr = BLOCK4 this cycle (comb) → latch at edge
                    key_lo_q <= eng_rd_data;
                    phase_q  <= ST_LOAD1;
                end

                ST_LOAD1: begin
                    // eng_rd_addr = BLOCK5 this cycle → latch at edge
                    key_hi_q <= eng_rd_data;
                    phase_q  <= ST_LOAD2;
                end

                ST_LOAD2: begin
                    // eng_rd_addr = BLOCK0; ke_start=1 triggers key expansion
                    pt_q    <= eng_rd_data;
                    phase_q <= ST_KEY_EXP;
                end

                ST_KEY_EXP: begin
                    if (ke_done) phase_q <= ST_INIT;
                end

                ST_INIT: begin
                    if (!decrypt_q) begin
                        state_q     <= pt_q ^ round_keys[0];
                        round_cnt_q <= 4'd1;
                    end else begin
                        state_q     <= pt_q ^ round_keys[Nr_q];
                        round_cnt_q <= Nr_q - 4'd1;
                    end
                    phase_q <= ST_ROUND;
                end

                ST_ROUND: begin
                    state_q <= decrypt_q ? inv_out : fwd_out;
                    if ((!decrypt_q && round_cnt_q == Nr_q) ||
                        ( decrypt_q && round_cnt_q == 4'd0)) begin
                        phase_q <= ST_STORE;
                    end else begin
                        round_cnt_q <= decrypt_q ?
                                       round_cnt_q - 4'd1 :
                                       round_cnt_q + 4'd1;
                    end
                end

                ST_STORE: begin
                    // eng_wr_en=1 this cycle (comb assign above)
                    // reg_buffer latches state_q → BLOCK1 at this clock edge
                    phase_q <= ST_IDLE;
                end

                default: phase_q <= ST_IDLE;
            endcase
        end
    end

endmodule
