// AES MixColumns / InvMixColumns Transform
// Operates on one 32-bit column (4 bytes) in GF(2^8)
// Reduction polynomial: x^8 + x^4 + x^3 + x + 1 (0x1B)

module aes_mix_columns (
    input  logic [31:0] col_in,   // 4 bytes {b0, b1, b2, b3} of one column
    input  logic        inverse,  // 0 = MixColumns, 1 = InvMixColumns
    output logic [31:0] col_out
);

    // Extract individual bytes
    logic [7:0] b0, b1, b2, b3;
    assign b0 = col_in[31:24];
    assign b1 = col_in[23:16];
    assign b2 = col_in[15:8];
    assign b3 = col_in[7:0];

    // xtime: multiply by {02} in GF(2^8)
    function automatic logic [7:0] xtime(input logic [7:0] b);
        xtime = {b[6:0], 1'b0} ^ (b[7] ? 8'h1B : 8'h00);
    endfunction

    // Multiply by arbitrary constant in GF(2^8) using repeated xtime
    function automatic logic [7:0] gf_mult(input logic [7:0] b, input logic [7:0] k);
        logic [7:0] result;
        logic [7:0] temp;
        result = 8'h00;
        temp = b;
        for (int i = 0; i < 8; i++) begin
            if (k[i])
                result = result ^ temp;
            temp = xtime(temp);
        end
        gf_mult = result;
    endfunction

    // Forward MixColumns: multiply by matrix {{02,03,01,01},{01,02,03,01},{01,01,02,03},{03,01,01,02}}
    logic [7:0] fwd_r0, fwd_r1, fwd_r2, fwd_r3;
    assign fwd_r0 = xtime(b0) ^ (xtime(b1) ^ b1) ^ b2 ^ b3;             // 02*b0 + 03*b1 + 01*b2 + 01*b3
    assign fwd_r1 = b0 ^ xtime(b1) ^ (xtime(b2) ^ b2) ^ b3;             // 01*b0 + 02*b1 + 03*b2 + 01*b3
    assign fwd_r2 = b0 ^ b1 ^ xtime(b2) ^ (xtime(b3) ^ b3);             // 01*b0 + 01*b1 + 02*b2 + 03*b3
    assign fwd_r3 = (xtime(b0) ^ b0) ^ b1 ^ b2 ^ xtime(b3);             // 03*b0 + 01*b1 + 01*b2 + 02*b3

    // Inverse MixColumns: multiply by matrix {{0E,0B,0D,09},{09,0E,0B,0D},{0D,09,0E,0B},{0B,0D,09,0E}}
    logic [7:0] inv_r0, inv_r1, inv_r2, inv_r3;
    assign inv_r0 = gf_mult(b0, 8'h0E) ^ gf_mult(b1, 8'h0B) ^ gf_mult(b2, 8'h0D) ^ gf_mult(b3, 8'h09);
    assign inv_r1 = gf_mult(b0, 8'h09) ^ gf_mult(b1, 8'h0E) ^ gf_mult(b2, 8'h0B) ^ gf_mult(b3, 8'h0D);
    assign inv_r2 = gf_mult(b0, 8'h0D) ^ gf_mult(b1, 8'h09) ^ gf_mult(b2, 8'h0E) ^ gf_mult(b3, 8'h0B);
    assign inv_r3 = gf_mult(b0, 8'h0B) ^ gf_mult(b1, 8'h0D) ^ gf_mult(b2, 8'h09) ^ gf_mult(b3, 8'h0E);

    assign col_out = inverse ? {inv_r0, inv_r1, inv_r2, inv_r3}
                             : {fwd_r0, fwd_r1, fwd_r2, fwd_r3};

endmodule
