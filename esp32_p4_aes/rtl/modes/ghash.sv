// GHASH Accumulator for GCM
// Computes X_i = (X_{i-1} ^ block_i) * H in GF(2^128)
// Uses gf_mult_128 for the multiplication.

module ghash (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         clear,        // Reset accumulator to zero
    input  logic [127:0] h,            // Hash subkey
    input  logic [127:0] block_in,     // New block to accumulate
    input  logic         block_valid,
    output logic         block_ready,
    output logic [127:0] ghash_out,    // Current accumulated hash
    output logic         done          // Pulse when multiply complete
);

    logic [127:0] x_q;    // Accumulator
    logic         busy_q;

    // GF multiplier
    logic         gf_start;
    logic [127:0] gf_a;
    logic [127:0] gf_result;
    logic         gf_done;

    gf_mult_128 u_gf_mult (
        .clk    (clk),
        .rst_n  (rst_n),
        .start  (gf_start),
        .a      (gf_a),
        .b      (h),
        .result (gf_result),
        .done   (gf_done)
    );

    assign block_ready = !busy_q;
    assign ghash_out   = x_q;
    assign gf_a        = x_q ^ block_in;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_q      <= '0;
            busy_q   <= 1'b0;
            gf_start <= 1'b0;
            done     <= 1'b0;
        end else begin
            gf_start <= 1'b0;
            done     <= 1'b0;

            if (clear) begin
                x_q    <= '0;
                busy_q <= 1'b0;
            end else if (block_valid && !busy_q) begin
                // Start multiplication: (x_q ^ block_in) * h
                gf_start <= 1'b1;
                busy_q   <= 1'b1;
            end else if (gf_done) begin
                x_q    <= gf_result;
                busy_q <= 1'b0;
                done   <= 1'b1;
            end
        end
    end

endmodule
