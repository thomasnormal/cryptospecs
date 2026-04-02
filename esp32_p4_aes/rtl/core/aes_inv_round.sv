// AES Inverse Round (InvShiftRows -> InvSubBytes -> AddRoundKey -> InvMixColumns)
// Purely combinational. Uses the "direct" inverse cipher form from FIPS-197 Section 5.3.
// For the last inverse round (first actual round of encryption), InvMixColumns is skipped.

module aes_inv_round (
    input  logic [127:0] state_in,
    input  logic [127:0] round_key,
    input  logic         is_last_round, // Skip InvMixColumns on last inverse round
    output logic [127:0] state_out
);

    // ---------------------------------------------------------------
    // Step 1: InvShiftRows (right-shift rows)
    // ---------------------------------------------------------------
    logic [7:0] s_in [0:15];
    logic [7:0] isr  [0:15];

    genvar i;
    generate
        for (i = 0; i < 16; i++) begin : gen_extract
            assign s_in[i] = state_in[127 - i*8 -: 8];
        end
    endgenerate

    // Row 0: no shift
    assign isr[0]  = s_in[0];
    assign isr[4]  = s_in[4];
    assign isr[8]  = s_in[8];
    assign isr[12] = s_in[12];

    // Row 1: right shift by 1 -> s'(1,c) = s(1, (c-1) mod 4) = s(1, (c+3) mod 4)
    assign isr[1]  = s_in[13];  // s(1,0) <- s(1,3)
    assign isr[5]  = s_in[1];   // s(1,1) <- s(1,0)
    assign isr[9]  = s_in[5];   // s(1,2) <- s(1,1)
    assign isr[13] = s_in[9];   // s(1,3) <- s(1,2)

    // Row 2: right shift by 2 -> same as left shift by 2
    assign isr[2]  = s_in[10];
    assign isr[6]  = s_in[14];
    assign isr[10] = s_in[2];
    assign isr[14] = s_in[6];

    // Row 3: right shift by 3 -> s'(3,c) = s(3, (c+1) mod 4)
    assign isr[3]  = s_in[7];   // s(3,0) <- s(3,1)
    assign isr[7]  = s_in[11];  // s(3,1) <- s(3,2)
    assign isr[11] = s_in[15];  // s(3,2) <- s(3,3)
    assign isr[15] = s_in[3];   // s(3,3) <- s(3,0)

    // ---------------------------------------------------------------
    // Step 2: InvSubBytes (inverse S-box on each byte)
    // ---------------------------------------------------------------
    logic [7:0] isb_out [0:15];

    generate
        for (i = 0; i < 16; i++) begin : gen_inv_sbox
            aes_sbox u_sbox (
                .data_in  (isr[i]),
                .inverse  (1'b1),
                .data_out (isb_out[i])
            );
        end
    endgenerate

    // ---------------------------------------------------------------
    // Step 3: AddRoundKey (per FIPS-197 Section 5.3 standard inverse cipher)
    // ---------------------------------------------------------------
    logic [127:0] after_isb;
    assign after_isb = {isb_out[0],  isb_out[1],  isb_out[2],  isb_out[3],
                        isb_out[4],  isb_out[5],  isb_out[6],  isb_out[7],
                        isb_out[8],  isb_out[9],  isb_out[10], isb_out[11],
                        isb_out[12], isb_out[13], isb_out[14], isb_out[15]};

    logic [127:0] after_ark;
    assign after_ark = after_isb ^ round_key;

    // ---------------------------------------------------------------
    // Step 4: InvMixColumns (skipped on last inverse round)
    // ---------------------------------------------------------------
    logic [7:0]  ark_bytes [0:15];
    logic [31:0] imc_in  [0:3];
    logic [31:0] imc_out [0:3];

    generate
        for (i = 0; i < 16; i++) begin : gen_ark_bytes
            assign ark_bytes[i] = after_ark[127 - i*8 -: 8];
        end
        for (i = 0; i < 4; i++) begin : gen_inv_mix_col
            assign imc_in[i] = {ark_bytes[4*i], ark_bytes[4*i+1], ark_bytes[4*i+2], ark_bytes[4*i+3]};
            aes_mix_columns u_imc (
                .col_in  (imc_in[i]),
                .inverse (1'b1),
                .col_out (imc_out[i])
            );
        end
    endgenerate

    assign state_out = is_last_round ? after_ark
                                     : {imc_out[0], imc_out[1], imc_out[2], imc_out[3]};

endmodule
