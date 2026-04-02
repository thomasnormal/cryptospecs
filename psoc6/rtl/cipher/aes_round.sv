// AES Forward Round (SubBytes -> ShiftRows -> MixColumns -> AddRoundKey)
// Purely combinational. State is a 4x4 byte matrix stored column-major:
//   state[127:120] = s(0,0), state[119:112] = s(1,0), state[111:104] = s(2,0), state[103:96] = s(3,0)
//   state[95:88]   = s(0,1), state[87:80]   = s(1,1), state[79:72]   = s(2,1), state[71:64]  = s(3,1)
//   state[63:56]   = s(0,2), state[55:48]   = s(1,2), state[47:40]   = s(2,2), state[39:32]  = s(3,2)
//   state[31:24]   = s(0,3), state[23:16]   = s(1,3), state[15:8]    = s(2,3), state[7:0]    = s(3,3)

module aes_round (
    input  logic [127:0] state_in,
    input  logic [127:0] round_key,
    input  logic         is_last_round, // Skip MixColumns on last round
    output logic [127:0] state_out
);

    // Step 1: SubBytes
    logic [7:0] sb_in  [0:15];
    logic [7:0] sb_out [0:15];

    genvar i;
    generate
        for (i = 0; i < 16; i++) begin : gen_sbox
            assign sb_in[i] = state_in[127 - i*8 -: 8];
            aes_sbox u_sbox (
                .data_in  (sb_in[i]),
                .inverse  (1'b0),
                .data_out (sb_out[i])
            );
        end
    endgenerate

    // Step 2: ShiftRows
    // Row 0: no shift, Row 1: left 1, Row 2: left 2, Row 3: left 3
    logic [7:0] sr [0:15];

    assign sr[0]  = sb_out[0];   assign sr[4]  = sb_out[4];
    assign sr[8]  = sb_out[8];   assign sr[12] = sb_out[12];

    assign sr[1]  = sb_out[5];   assign sr[5]  = sb_out[9];
    assign sr[9]  = sb_out[13];  assign sr[13] = sb_out[1];

    assign sr[2]  = sb_out[10];  assign sr[6]  = sb_out[14];
    assign sr[10] = sb_out[2];   assign sr[14] = sb_out[6];

    assign sr[3]  = sb_out[15];  assign sr[7]  = sb_out[3];
    assign sr[11] = sb_out[7];   assign sr[15] = sb_out[11];

    // Step 3: MixColumns (skipped on last round)
    logic [31:0] mc_in  [0:3];
    logic [31:0] mc_out [0:3];

    generate
        for (i = 0; i < 4; i++) begin : gen_mix_col
            assign mc_in[i] = {sr[4*i], sr[4*i+1], sr[4*i+2], sr[4*i+3]};
            aes_mix_columns u_mc (
                .col_in  (mc_in[i]),
                .inverse (1'b0),
                .col_out (mc_out[i])
            );
        end
    endgenerate

    logic [127:0] after_mc;
    assign after_mc = is_last_round
        ? {sr[0], sr[1], sr[2], sr[3], sr[4], sr[5], sr[6], sr[7],
           sr[8], sr[9], sr[10], sr[11], sr[12], sr[13], sr[14], sr[15]}
        : {mc_out[0], mc_out[1], mc_out[2], mc_out[3]};

    // Step 4: AddRoundKey
    assign state_out = after_mc ^ round_key;

endmodule
