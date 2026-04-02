// AES S-box / Inverse S-box
// Combinational 256x8 lookup tables per FIPS-197

module aes_sbox (
    input  logic [7:0] data_in,
    input  logic       inverse,  // 0 = forward (SubBytes), 1 = inverse (InvSubBytes)
    output logic [7:0] data_out
);

    logic [7:0] fwd_out, inv_out;

    // Forward S-box (FIPS-197 Figure 7)
    always_comb begin
        case (data_in)
            8'h00: fwd_out = 8'h63; 8'h01: fwd_out = 8'h7C; 8'h02: fwd_out = 8'h77; 8'h03: fwd_out = 8'h7B;
            8'h04: fwd_out = 8'hF2; 8'h05: fwd_out = 8'h6B; 8'h06: fwd_out = 8'h6F; 8'h07: fwd_out = 8'hC5;
            8'h08: fwd_out = 8'h30; 8'h09: fwd_out = 8'h01; 8'h0A: fwd_out = 8'h67; 8'h0B: fwd_out = 8'h2B;
            8'h0C: fwd_out = 8'hFE; 8'h0D: fwd_out = 8'hD7; 8'h0E: fwd_out = 8'hAB; 8'h0F: fwd_out = 8'h76;
            8'h10: fwd_out = 8'hCA; 8'h11: fwd_out = 8'h82; 8'h12: fwd_out = 8'hC9; 8'h13: fwd_out = 8'h7D;
            8'h14: fwd_out = 8'hFA; 8'h15: fwd_out = 8'h59; 8'h16: fwd_out = 8'h47; 8'h17: fwd_out = 8'hF0;
            8'h18: fwd_out = 8'hAD; 8'h19: fwd_out = 8'hD4; 8'h1A: fwd_out = 8'hA2; 8'h1B: fwd_out = 8'hAF;
            8'h1C: fwd_out = 8'h9C; 8'h1D: fwd_out = 8'hA4; 8'h1E: fwd_out = 8'h72; 8'h1F: fwd_out = 8'hC0;
            8'h20: fwd_out = 8'hB7; 8'h21: fwd_out = 8'hFD; 8'h22: fwd_out = 8'h93; 8'h23: fwd_out = 8'h26;
            8'h24: fwd_out = 8'h36; 8'h25: fwd_out = 8'h3F; 8'h26: fwd_out = 8'hF7; 8'h27: fwd_out = 8'hCC;
            8'h28: fwd_out = 8'h34; 8'h29: fwd_out = 8'hA5; 8'h2A: fwd_out = 8'hE5; 8'h2B: fwd_out = 8'hF1;
            8'h2C: fwd_out = 8'h71; 8'h2D: fwd_out = 8'hD8; 8'h2E: fwd_out = 8'h31; 8'h2F: fwd_out = 8'h15;
            8'h30: fwd_out = 8'h04; 8'h31: fwd_out = 8'hC7; 8'h32: fwd_out = 8'h23; 8'h33: fwd_out = 8'hC3;
            8'h34: fwd_out = 8'h18; 8'h35: fwd_out = 8'h96; 8'h36: fwd_out = 8'h05; 8'h37: fwd_out = 8'h9A;
            8'h38: fwd_out = 8'h07; 8'h39: fwd_out = 8'h12; 8'h3A: fwd_out = 8'h80; 8'h3B: fwd_out = 8'hE2;
            8'h3C: fwd_out = 8'hEB; 8'h3D: fwd_out = 8'h27; 8'h3E: fwd_out = 8'hB2; 8'h3F: fwd_out = 8'h75;
            8'h40: fwd_out = 8'h09; 8'h41: fwd_out = 8'h83; 8'h42: fwd_out = 8'h2C; 8'h43: fwd_out = 8'h1A;
            8'h44: fwd_out = 8'h1B; 8'h45: fwd_out = 8'h6E; 8'h46: fwd_out = 8'h5A; 8'h47: fwd_out = 8'hA0;
            8'h48: fwd_out = 8'h52; 8'h49: fwd_out = 8'h3B; 8'h4A: fwd_out = 8'hD6; 8'h4B: fwd_out = 8'hB3;
            8'h4C: fwd_out = 8'h29; 8'h4D: fwd_out = 8'hE3; 8'h4E: fwd_out = 8'h2F; 8'h4F: fwd_out = 8'h84;
            8'h50: fwd_out = 8'h53; 8'h51: fwd_out = 8'hD1; 8'h52: fwd_out = 8'h00; 8'h53: fwd_out = 8'hED;
            8'h54: fwd_out = 8'h20; 8'h55: fwd_out = 8'hFC; 8'h56: fwd_out = 8'hB1; 8'h57: fwd_out = 8'h5B;
            8'h58: fwd_out = 8'h6A; 8'h59: fwd_out = 8'hCB; 8'h5A: fwd_out = 8'hBE; 8'h5B: fwd_out = 8'h39;
            8'h5C: fwd_out = 8'h4A; 8'h5D: fwd_out = 8'h4C; 8'h5E: fwd_out = 8'h58; 8'h5F: fwd_out = 8'hCF;
            8'h60: fwd_out = 8'hD0; 8'h61: fwd_out = 8'hEF; 8'h62: fwd_out = 8'hAA; 8'h63: fwd_out = 8'hFB;
            8'h64: fwd_out = 8'h43; 8'h65: fwd_out = 8'h4D; 8'h66: fwd_out = 8'h33; 8'h67: fwd_out = 8'h85;
            8'h68: fwd_out = 8'h45; 8'h69: fwd_out = 8'hF9; 8'h6A: fwd_out = 8'h02; 8'h6B: fwd_out = 8'h7F;
            8'h6C: fwd_out = 8'h50; 8'h6D: fwd_out = 8'h3C; 8'h6E: fwd_out = 8'h9F; 8'h6F: fwd_out = 8'hA8;
            8'h70: fwd_out = 8'h51; 8'h71: fwd_out = 8'hA3; 8'h72: fwd_out = 8'h40; 8'h73: fwd_out = 8'h8F;
            8'h74: fwd_out = 8'h92; 8'h75: fwd_out = 8'h9D; 8'h76: fwd_out = 8'h38; 8'h77: fwd_out = 8'hF5;
            8'h78: fwd_out = 8'hBC; 8'h79: fwd_out = 8'hB6; 8'h7A: fwd_out = 8'hDA; 8'h7B: fwd_out = 8'h21;
            8'h7C: fwd_out = 8'h10; 8'h7D: fwd_out = 8'hFF; 8'h7E: fwd_out = 8'hF3; 8'h7F: fwd_out = 8'hD2;
            8'h80: fwd_out = 8'hCD; 8'h81: fwd_out = 8'h0C; 8'h82: fwd_out = 8'h13; 8'h83: fwd_out = 8'hEC;
            8'h84: fwd_out = 8'h5F; 8'h85: fwd_out = 8'h97; 8'h86: fwd_out = 8'h44; 8'h87: fwd_out = 8'h17;
            8'h88: fwd_out = 8'hC4; 8'h89: fwd_out = 8'hA7; 8'h8A: fwd_out = 8'h7E; 8'h8B: fwd_out = 8'h3D;
            8'h8C: fwd_out = 8'h64; 8'h8D: fwd_out = 8'h5D; 8'h8E: fwd_out = 8'h19; 8'h8F: fwd_out = 8'h73;
            8'h90: fwd_out = 8'h60; 8'h91: fwd_out = 8'h81; 8'h92: fwd_out = 8'h4F; 8'h93: fwd_out = 8'hDC;
            8'h94: fwd_out = 8'h22; 8'h95: fwd_out = 8'h2A; 8'h96: fwd_out = 8'h90; 8'h97: fwd_out = 8'h88;
            8'h98: fwd_out = 8'h46; 8'h99: fwd_out = 8'hEE; 8'h9A: fwd_out = 8'hB8; 8'h9B: fwd_out = 8'h14;
            8'h9C: fwd_out = 8'hDE; 8'h9D: fwd_out = 8'h5E; 8'h9E: fwd_out = 8'h0B; 8'h9F: fwd_out = 8'hDB;
            8'hA0: fwd_out = 8'hE0; 8'hA1: fwd_out = 8'h32; 8'hA2: fwd_out = 8'h3A; 8'hA3: fwd_out = 8'h0A;
            8'hA4: fwd_out = 8'h49; 8'hA5: fwd_out = 8'h06; 8'hA6: fwd_out = 8'h24; 8'hA7: fwd_out = 8'h5C;
            8'hA8: fwd_out = 8'hC2; 8'hA9: fwd_out = 8'hD3; 8'hAA: fwd_out = 8'hAC; 8'hAB: fwd_out = 8'h62;
            8'hAC: fwd_out = 8'h91; 8'hAD: fwd_out = 8'h95; 8'hAE: fwd_out = 8'hE4; 8'hAF: fwd_out = 8'h79;
            8'hB0: fwd_out = 8'hE7; 8'hB1: fwd_out = 8'hC8; 8'hB2: fwd_out = 8'h37; 8'hB3: fwd_out = 8'h6D;
            8'hB4: fwd_out = 8'h8D; 8'hB5: fwd_out = 8'hD5; 8'hB6: fwd_out = 8'h4E; 8'hB7: fwd_out = 8'hA9;
            8'hB8: fwd_out = 8'h6C; 8'hB9: fwd_out = 8'h56; 8'hBA: fwd_out = 8'hF4; 8'hBB: fwd_out = 8'hEA;
            8'hBC: fwd_out = 8'h65; 8'hBD: fwd_out = 8'h7A; 8'hBE: fwd_out = 8'hAE; 8'hBF: fwd_out = 8'h08;
            8'hC0: fwd_out = 8'hBA; 8'hC1: fwd_out = 8'h78; 8'hC2: fwd_out = 8'h25; 8'hC3: fwd_out = 8'h2E;
            8'hC4: fwd_out = 8'h1C; 8'hC5: fwd_out = 8'hA6; 8'hC6: fwd_out = 8'hB4; 8'hC7: fwd_out = 8'hC6;
            8'hC8: fwd_out = 8'hE8; 8'hC9: fwd_out = 8'hDD; 8'hCA: fwd_out = 8'h74; 8'hCB: fwd_out = 8'h1F;
            8'hCC: fwd_out = 8'h4B; 8'hCD: fwd_out = 8'hBD; 8'hCE: fwd_out = 8'h8B; 8'hCF: fwd_out = 8'h8A;
            8'hD0: fwd_out = 8'h70; 8'hD1: fwd_out = 8'h3E; 8'hD2: fwd_out = 8'hB5; 8'hD3: fwd_out = 8'h66;
            8'hD4: fwd_out = 8'h48; 8'hD5: fwd_out = 8'h03; 8'hD6: fwd_out = 8'hF6; 8'hD7: fwd_out = 8'h0E;
            8'hD8: fwd_out = 8'h61; 8'hD9: fwd_out = 8'h35; 8'hDA: fwd_out = 8'h57; 8'hDB: fwd_out = 8'hB9;
            8'hDC: fwd_out = 8'h86; 8'hDD: fwd_out = 8'hC1; 8'hDE: fwd_out = 8'h1D; 8'hDF: fwd_out = 8'h9E;
            8'hE0: fwd_out = 8'hE1; 8'hE1: fwd_out = 8'hF8; 8'hE2: fwd_out = 8'h98; 8'hE3: fwd_out = 8'h11;
            8'hE4: fwd_out = 8'h69; 8'hE5: fwd_out = 8'hD9; 8'hE6: fwd_out = 8'h8E; 8'hE7: fwd_out = 8'h94;
            8'hE8: fwd_out = 8'h9B; 8'hE9: fwd_out = 8'h1E; 8'hEA: fwd_out = 8'h87; 8'hEB: fwd_out = 8'hE9;
            8'hEC: fwd_out = 8'hCE; 8'hED: fwd_out = 8'h55; 8'hEE: fwd_out = 8'h28; 8'hEF: fwd_out = 8'hDF;
            8'hF0: fwd_out = 8'h8C; 8'hF1: fwd_out = 8'hA1; 8'hF2: fwd_out = 8'h89; 8'hF3: fwd_out = 8'h0D;
            8'hF4: fwd_out = 8'hBF; 8'hF5: fwd_out = 8'hE6; 8'hF6: fwd_out = 8'h42; 8'hF7: fwd_out = 8'h68;
            8'hF8: fwd_out = 8'h41; 8'hF9: fwd_out = 8'h99; 8'hFA: fwd_out = 8'h2D; 8'hFB: fwd_out = 8'h0F;
            8'hFC: fwd_out = 8'hB0; 8'hFD: fwd_out = 8'h54; 8'hFE: fwd_out = 8'hBB; 8'hFF: fwd_out = 8'h16;
        endcase
    end

    // Inverse S-box (FIPS-197 Figure 14)
    always_comb begin
        case (data_in)
            8'h00: inv_out = 8'h52; 8'h01: inv_out = 8'h09; 8'h02: inv_out = 8'h6A; 8'h03: inv_out = 8'hD5;
            8'h04: inv_out = 8'h30; 8'h05: inv_out = 8'h36; 8'h06: inv_out = 8'hA5; 8'h07: inv_out = 8'h38;
            8'h08: inv_out = 8'hBF; 8'h09: inv_out = 8'h40; 8'h0A: inv_out = 8'hA3; 8'h0B: inv_out = 8'h9E;
            8'h0C: inv_out = 8'h81; 8'h0D: inv_out = 8'hF3; 8'h0E: inv_out = 8'hD7; 8'h0F: inv_out = 8'hFB;
            8'h10: inv_out = 8'h7C; 8'h11: inv_out = 8'hE3; 8'h12: inv_out = 8'h39; 8'h13: inv_out = 8'h82;
            8'h14: inv_out = 8'h9B; 8'h15: inv_out = 8'h2F; 8'h16: inv_out = 8'hFF; 8'h17: inv_out = 8'h87;
            8'h18: inv_out = 8'h34; 8'h19: inv_out = 8'h8E; 8'h1A: inv_out = 8'h43; 8'h1B: inv_out = 8'h44;
            8'h1C: inv_out = 8'hC4; 8'h1D: inv_out = 8'hDE; 8'h1E: inv_out = 8'hE9; 8'h1F: inv_out = 8'hCB;
            8'h20: inv_out = 8'h54; 8'h21: inv_out = 8'h7B; 8'h22: inv_out = 8'h94; 8'h23: inv_out = 8'h32;
            8'h24: inv_out = 8'hA6; 8'h25: inv_out = 8'hC2; 8'h26: inv_out = 8'h23; 8'h27: inv_out = 8'h3D;
            8'h28: inv_out = 8'hEE; 8'h29: inv_out = 8'h4C; 8'h2A: inv_out = 8'h95; 8'h2B: inv_out = 8'h0B;
            8'h2C: inv_out = 8'h42; 8'h2D: inv_out = 8'hFA; 8'h2E: inv_out = 8'hC3; 8'h2F: inv_out = 8'h4E;
            8'h30: inv_out = 8'h08; 8'h31: inv_out = 8'h2E; 8'h32: inv_out = 8'hA1; 8'h33: inv_out = 8'h66;
            8'h34: inv_out = 8'h28; 8'h35: inv_out = 8'hD9; 8'h36: inv_out = 8'h24; 8'h37: inv_out = 8'hB2;
            8'h38: inv_out = 8'h76; 8'h39: inv_out = 8'h5B; 8'h3A: inv_out = 8'hA2; 8'h3B: inv_out = 8'h49;
            8'h3C: inv_out = 8'h6D; 8'h3D: inv_out = 8'h8B; 8'h3E: inv_out = 8'hD1; 8'h3F: inv_out = 8'h25;
            8'h40: inv_out = 8'h72; 8'h41: inv_out = 8'hF8; 8'h42: inv_out = 8'hF6; 8'h43: inv_out = 8'h64;
            8'h44: inv_out = 8'h86; 8'h45: inv_out = 8'h68; 8'h46: inv_out = 8'h98; 8'h47: inv_out = 8'h16;
            8'h48: inv_out = 8'hD4; 8'h49: inv_out = 8'hA4; 8'h4A: inv_out = 8'h5C; 8'h4B: inv_out = 8'hCC;
            8'h4C: inv_out = 8'h5D; 8'h4D: inv_out = 8'h65; 8'h4E: inv_out = 8'hB6; 8'h4F: inv_out = 8'h92;
            8'h50: inv_out = 8'h6C; 8'h51: inv_out = 8'h70; 8'h52: inv_out = 8'h48; 8'h53: inv_out = 8'h50;
            8'h54: inv_out = 8'hFD; 8'h55: inv_out = 8'hED; 8'h56: inv_out = 8'hB9; 8'h57: inv_out = 8'hDA;
            8'h58: inv_out = 8'h5E; 8'h59: inv_out = 8'h15; 8'h5A: inv_out = 8'h46; 8'h5B: inv_out = 8'h57;
            8'h5C: inv_out = 8'hA7; 8'h5D: inv_out = 8'h8D; 8'h5E: inv_out = 8'h9D; 8'h5F: inv_out = 8'h84;
            8'h60: inv_out = 8'h90; 8'h61: inv_out = 8'hD8; 8'h62: inv_out = 8'hAB; 8'h63: inv_out = 8'h00;
            8'h64: inv_out = 8'h8C; 8'h65: inv_out = 8'hBC; 8'h66: inv_out = 8'hD3; 8'h67: inv_out = 8'h0A;
            8'h68: inv_out = 8'hF7; 8'h69: inv_out = 8'hE4; 8'h6A: inv_out = 8'h58; 8'h6B: inv_out = 8'h05;
            8'h6C: inv_out = 8'hB8; 8'h6D: inv_out = 8'hB3; 8'h6E: inv_out = 8'h45; 8'h6F: inv_out = 8'h06;
            8'h70: inv_out = 8'hD0; 8'h71: inv_out = 8'h2C; 8'h72: inv_out = 8'h1E; 8'h73: inv_out = 8'h8F;
            8'h74: inv_out = 8'hCA; 8'h75: inv_out = 8'h3F; 8'h76: inv_out = 8'h0F; 8'h77: inv_out = 8'h02;
            8'h78: inv_out = 8'hC1; 8'h79: inv_out = 8'hAF; 8'h7A: inv_out = 8'hBD; 8'h7B: inv_out = 8'h03;
            8'h7C: inv_out = 8'h01; 8'h7D: inv_out = 8'h13; 8'h7E: inv_out = 8'h8A; 8'h7F: inv_out = 8'h6B;
            8'h80: inv_out = 8'h3A; 8'h81: inv_out = 8'h91; 8'h82: inv_out = 8'h11; 8'h83: inv_out = 8'h41;
            8'h84: inv_out = 8'h4F; 8'h85: inv_out = 8'h67; 8'h86: inv_out = 8'hDC; 8'h87: inv_out = 8'hEA;
            8'h88: inv_out = 8'h97; 8'h89: inv_out = 8'hF2; 8'h8A: inv_out = 8'hCF; 8'h8B: inv_out = 8'hCE;
            8'h8C: inv_out = 8'hF0; 8'h8D: inv_out = 8'hB4; 8'h8E: inv_out = 8'hE6; 8'h8F: inv_out = 8'h73;
            8'h90: inv_out = 8'h96; 8'h91: inv_out = 8'hAC; 8'h92: inv_out = 8'h74; 8'h93: inv_out = 8'h22;
            8'h94: inv_out = 8'hE7; 8'h95: inv_out = 8'hAD; 8'h96: inv_out = 8'h35; 8'h97: inv_out = 8'h85;
            8'h98: inv_out = 8'hE2; 8'h99: inv_out = 8'hF9; 8'h9A: inv_out = 8'h37; 8'h9B: inv_out = 8'hE8;
            8'h9C: inv_out = 8'h1C; 8'h9D: inv_out = 8'h75; 8'h9E: inv_out = 8'hDF; 8'h9F: inv_out = 8'h6E;
            8'hA0: inv_out = 8'h47; 8'hA1: inv_out = 8'hF1; 8'hA2: inv_out = 8'h1A; 8'hA3: inv_out = 8'h71;
            8'hA4: inv_out = 8'h1D; 8'hA5: inv_out = 8'h29; 8'hA6: inv_out = 8'hC5; 8'hA7: inv_out = 8'h89;
            8'hA8: inv_out = 8'h6F; 8'hA9: inv_out = 8'hB7; 8'hAA: inv_out = 8'h62; 8'hAB: inv_out = 8'h0E;
            8'hAC: inv_out = 8'hAA; 8'hAD: inv_out = 8'h18; 8'hAE: inv_out = 8'hBE; 8'hAF: inv_out = 8'h1B;
            8'hB0: inv_out = 8'hFC; 8'hB1: inv_out = 8'h56; 8'hB2: inv_out = 8'h3E; 8'hB3: inv_out = 8'h4B;
            8'hB4: inv_out = 8'hC6; 8'hB5: inv_out = 8'hD2; 8'hB6: inv_out = 8'h79; 8'hB7: inv_out = 8'h20;
            8'hB8: inv_out = 8'h9A; 8'hB9: inv_out = 8'hDB; 8'hBA: inv_out = 8'hC0; 8'hBB: inv_out = 8'hFE;
            8'hBC: inv_out = 8'h78; 8'hBD: inv_out = 8'hCD; 8'hBE: inv_out = 8'h5A; 8'hBF: inv_out = 8'hF4;
            8'hC0: inv_out = 8'h1F; 8'hC1: inv_out = 8'hDD; 8'hC2: inv_out = 8'hA8; 8'hC3: inv_out = 8'h33;
            8'hC4: inv_out = 8'h88; 8'hC5: inv_out = 8'h07; 8'hC6: inv_out = 8'hC7; 8'hC7: inv_out = 8'h31;
            8'hC8: inv_out = 8'hB1; 8'hC9: inv_out = 8'h12; 8'hCA: inv_out = 8'h10; 8'hCB: inv_out = 8'h59;
            8'hCC: inv_out = 8'h27; 8'hCD: inv_out = 8'h80; 8'hCE: inv_out = 8'hEC; 8'hCF: inv_out = 8'h5F;
            8'hD0: inv_out = 8'h60; 8'hD1: inv_out = 8'h51; 8'hD2: inv_out = 8'h7F; 8'hD3: inv_out = 8'hA9;
            8'hD4: inv_out = 8'h19; 8'hD5: inv_out = 8'hB5; 8'hD6: inv_out = 8'h4A; 8'hD7: inv_out = 8'h0D;
            8'hD8: inv_out = 8'h2D; 8'hD9: inv_out = 8'hE5; 8'hDA: inv_out = 8'h7A; 8'hDB: inv_out = 8'h9F;
            8'hDC: inv_out = 8'h93; 8'hDD: inv_out = 8'hC9; 8'hDE: inv_out = 8'h9C; 8'hDF: inv_out = 8'hEF;
            8'hE0: inv_out = 8'hA0; 8'hE1: inv_out = 8'hE0; 8'hE2: inv_out = 8'h3B; 8'hE3: inv_out = 8'h4D;
            8'hE4: inv_out = 8'hAE; 8'hE5: inv_out = 8'h2A; 8'hE6: inv_out = 8'hF5; 8'hE7: inv_out = 8'hB0;
            8'hE8: inv_out = 8'hC8; 8'hE9: inv_out = 8'hEB; 8'hEA: inv_out = 8'hBB; 8'hEB: inv_out = 8'h3C;
            8'hEC: inv_out = 8'h83; 8'hED: inv_out = 8'h53; 8'hEE: inv_out = 8'h99; 8'hEF: inv_out = 8'h61;
            8'hF0: inv_out = 8'h17; 8'hF1: inv_out = 8'h2B; 8'hF2: inv_out = 8'h04; 8'hF3: inv_out = 8'h7E;
            8'hF4: inv_out = 8'hBA; 8'hF5: inv_out = 8'h77; 8'hF6: inv_out = 8'hD6; 8'hF7: inv_out = 8'h26;
            8'hF8: inv_out = 8'hE1; 8'hF9: inv_out = 8'h69; 8'hFA: inv_out = 8'h14; 8'hFB: inv_out = 8'h63;
            8'hFC: inv_out = 8'h55; 8'hFD: inv_out = 8'h21; 8'hFE: inv_out = 8'h0C; 8'hFF: inv_out = 8'h7D;
        endcase
    end

    assign data_out = inverse ? inv_out : fwd_out;

endmodule
