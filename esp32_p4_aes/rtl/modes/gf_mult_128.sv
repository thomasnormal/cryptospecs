// GF(2^128) Multiplier (bit-serial)
// Computes a * b in GF(2^128) with reduction polynomial x^128 + x^7 + x^2 + x + 1
// GCM convention: R = 0xE1 << 120 (reflected)
// Latency: 128 clock cycles

module gf_mult_128 (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         start,
    input  logic [127:0] a,
    input  logic [127:0] b,
    output logic [127:0] result,
    output logic         done
);

    localparam logic [127:0] R_POLY = {8'hE1, 120'h0};

    logic [127:0] v_q;      // Shifted multiplicand
    logic [127:0] z_q;      // Accumulator
    logic [6:0]   cnt_q;    // Bit counter (0..127)
    logic         running_q;

    // Extract current bit of b (MSB first)
    wire cur_bit = b[7'd127 - cnt_q];

    // Compute the final z value combinationally (includes current iteration)
    logic [127:0] z_next;
    always_comb begin
        z_next = cur_bit ? (z_q ^ v_q) : z_q;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            v_q       <= '0;
            z_q       <= '0;
            cnt_q     <= '0;
            running_q <= 1'b0;
            result    <= '0;
            done      <= 1'b0;
        end else begin
            done <= 1'b0;

            if (start && !running_q) begin
                v_q       <= a;
                z_q       <= '0;
                cnt_q     <= '0;
                running_q <= 1'b1;
            end else if (running_q) begin
                // Accumulate: if current bit of b is 1, XOR V into Z
                z_q <= z_next;

                // Multiply V by x (right-shift in GCM convention)
                if (v_q[0])
                    v_q <= (v_q >> 1) ^ R_POLY;
                else
                    v_q <= v_q >> 1;

                if (cnt_q == 7'd127) begin
                    result    <= z_next;
                    done      <= 1'b1;
                    running_q <= 1'b0;
                end else begin
                    cnt_q <= cnt_q + 1;
                end
            end
        end
    end

endmodule
