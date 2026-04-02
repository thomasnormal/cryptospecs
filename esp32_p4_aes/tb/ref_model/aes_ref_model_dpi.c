// AES Reference Model DPI Implementation
// FIPS-197 AES-128/256 ECB, CBC, OFB, CTR.
// Matches the RTL's block_mode_ctrl.sv conventions exactly.

#include "aes_ref_model_dpi.h"
#include <string.h>

// ---------------------------------------------------------------------------
// AES constants
// ---------------------------------------------------------------------------

static const uint8_t SBOX[256] = {
    0x63,0x7c,0x77,0x7b,0xf2,0x6b,0x6f,0xc5,0x30,0x01,0x67,0x2b,0xfe,0xd7,0xab,0x76,
    0xca,0x82,0xc9,0x7d,0xfa,0x59,0x47,0xf0,0xad,0xd4,0xa2,0xaf,0x9c,0xa4,0x72,0xc0,
    0xb7,0xfd,0x93,0x26,0x36,0x3f,0xf7,0xcc,0x34,0xa5,0xe5,0xf1,0x71,0xd8,0x31,0x15,
    0x04,0xc7,0x23,0xc3,0x18,0x96,0x05,0x9a,0x07,0x12,0x80,0xe2,0xeb,0x27,0xb2,0x75,
    0x09,0x83,0x2c,0x1a,0x1b,0x6e,0x5a,0xa0,0x52,0x3b,0xd6,0xb3,0x29,0xe3,0x2f,0x84,
    0x53,0xd1,0x00,0xed,0x20,0xfc,0xb1,0x5b,0x6a,0xcb,0xbe,0x39,0x4a,0x4c,0x58,0xcf,
    0xd0,0xef,0xaa,0xfb,0x43,0x4d,0x33,0x85,0x45,0xf9,0x02,0x7f,0x50,0x3c,0x9f,0xa8,
    0x51,0xa3,0x40,0x8f,0x92,0x9d,0x38,0xf5,0xbc,0xb6,0xda,0x21,0x10,0xff,0xf3,0xd2,
    0xcd,0x0c,0x13,0xec,0x5f,0x97,0x44,0x17,0xc4,0xa7,0x7e,0x3d,0x64,0x5d,0x19,0x73,
    0x60,0x81,0x4f,0xdc,0x22,0x2a,0x90,0x88,0x46,0xee,0xb8,0x14,0xde,0x5e,0x0b,0xdb,
    0xe0,0x32,0x3a,0x0a,0x49,0x06,0x24,0x5c,0xc2,0xd3,0xac,0x62,0x91,0x95,0xe4,0x79,
    0xe7,0xc8,0x37,0x6d,0x8d,0xd5,0x4e,0xa9,0x6c,0x56,0xf4,0xea,0x65,0x7a,0xae,0x08,
    0xba,0x78,0x25,0x2e,0x1c,0xa6,0xb4,0xc6,0xe8,0xdd,0x74,0x1f,0x4b,0xbd,0x8b,0x8a,
    0x70,0x3e,0xb5,0x66,0x48,0x03,0xf6,0x0e,0x61,0x35,0x57,0xb9,0x86,0xc1,0x1d,0x9e,
    0xe1,0xf8,0x98,0x11,0x69,0xd9,0x8e,0x94,0x9b,0x1e,0x87,0xe9,0xce,0x55,0x28,0xdf,
    0x8c,0xa1,0x89,0x0d,0xbf,0xe6,0x42,0x68,0x41,0x99,0x2d,0x0f,0xb0,0x54,0xbb,0x16
};

static const uint8_t INV_SBOX[256] = {
    0x52,0x09,0x6a,0xd5,0x30,0x36,0xa5,0x38,0xbf,0x40,0xa3,0x9e,0x81,0xf3,0xd7,0xfb,
    0x7c,0xe3,0x39,0x82,0x9b,0x2f,0xff,0x87,0x34,0x8e,0x43,0x44,0xc4,0xde,0xe9,0xcb,
    0x54,0x7b,0x94,0x32,0xa6,0xc2,0x23,0x3d,0xee,0x4c,0x95,0x0b,0x42,0xfa,0xc3,0x4e,
    0x08,0x2e,0xa1,0x66,0x28,0xd9,0x24,0xb2,0x76,0x5b,0xa2,0x49,0x6d,0x8b,0xd1,0x25,
    0x72,0xf8,0xf6,0x64,0x86,0x68,0x98,0x16,0xd4,0xa4,0x5c,0xcc,0x5d,0x65,0xb6,0x92,
    0x6c,0x70,0x48,0x50,0xfd,0xed,0xb9,0xda,0x5e,0x15,0x46,0x57,0xa7,0x8d,0x9d,0x84,
    0x90,0xd8,0xab,0x00,0x8c,0xbc,0xd3,0x0a,0xf7,0xe4,0x58,0x05,0xb8,0xb3,0x45,0x06,
    0xd0,0x2c,0x1e,0x8f,0xca,0x3f,0x0f,0x02,0xc1,0xaf,0xbd,0x03,0x01,0x13,0x8a,0x6b,
    0x3a,0x91,0x11,0x41,0x4f,0x67,0xdc,0xea,0x97,0xf2,0xcf,0xce,0xf0,0xb4,0xe6,0x73,
    0x96,0xac,0x74,0x22,0xe7,0xad,0x35,0x85,0xe2,0xf9,0x37,0xe8,0x1c,0x75,0xdf,0x6e,
    0x47,0xf1,0x1a,0x71,0x1d,0x29,0xc5,0x89,0x6f,0xb7,0x62,0x0e,0xaa,0x18,0xbe,0x1b,
    0xfc,0x56,0x3e,0x4b,0xc6,0xd2,0x79,0x20,0x9a,0xdb,0xc0,0xfe,0x78,0xcd,0x5a,0xf4,
    0x1f,0xdd,0xa8,0x33,0x88,0x07,0xc7,0x31,0xb1,0x12,0x10,0x59,0x27,0x80,0xec,0x5f,
    0x60,0x51,0x7f,0xa9,0x19,0xb5,0x4a,0x0d,0x2d,0xe5,0x7a,0x9f,0x93,0xc9,0x9c,0xef,
    0xa0,0xe0,0x3b,0x4d,0xae,0x2a,0xf5,0xb0,0xc8,0xeb,0xbb,0x3c,0x83,0x53,0x99,0x61,
    0x17,0x2b,0x04,0x7e,0xba,0x77,0xd6,0x26,0xe1,0x69,0x14,0x63,0x55,0x21,0x0c,0x7d
};

static const uint8_t RCON[11] = {
    0x00,0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80,0x1b,0x36
};

// ---------------------------------------------------------------------------
// Global state
// ---------------------------------------------------------------------------
#define MAX_RK_WORDS 60  /* 4*(Nr+1): AES-256 Nr=14 -> 60 words */

static uint32_t g_rk[MAX_RK_WORDS];   /* expanded round keys */
static int      g_nr;                  /* number of rounds */
static uint8_t  g_iv[16];             /* chaining IV */

// ---------------------------------------------------------------------------
// GF(2^8) helpers
// ---------------------------------------------------------------------------
static uint8_t xtime(uint8_t a) {
    return (uint8_t)((a & 0x80) ? ((a << 1) ^ 0x1b) : (a << 1));
}

static uint8_t gmul(uint8_t a, uint8_t b) {
    uint8_t p = 0;
    for (int i = 0; i < 8; i++) {
        if (b & 1) p ^= a;
        uint8_t hi = a & 0x80;
        a = (uint8_t)(a << 1);
        if (hi) a ^= 0x1b;
        b >>= 1;
    }
    return p;
}

// ---------------------------------------------------------------------------
// Bit-vector conversion helpers
// ---------------------------------------------------------------------------

// SV bit[127:0]: sv[3]=bits[127:96], sv[0]=bits[31:0]
// AES bytes: b[0] = most-significant byte = bits[127:120]
static void sv128_to_bytes(const svBitVecVal *sv, uint8_t *b) {
    for (int w = 0; w < 4; w++) {
        uint32_t word = (uint32_t)sv[3 - w];
        b[w*4+0] = (uint8_t)(word >> 24);
        b[w*4+1] = (uint8_t)(word >> 16);
        b[w*4+2] = (uint8_t)(word >>  8);
        b[w*4+3] = (uint8_t)(word >>  0);
    }
}

static void bytes_to_sv128(const uint8_t *b, svBitVecVal *sv) {
    for (int w = 0; w < 4; w++) {
        sv[3 - w] = ((uint32_t)b[w*4+0] << 24) | ((uint32_t)b[w*4+1] << 16) |
                    ((uint32_t)b[w*4+2] <<  8) | ((uint32_t)b[w*4+3]);
    }
}

// SV bit[255:0]: sv[7]=bits[255:224], sv[0]=bits[31:0]
// key_bits=128: sv[7..4] hold the 16 key bytes; sv[3..0] are unused
static void sv256_to_key_bytes(const svBitVecVal *sv, uint8_t *b, int key_bits) {
    int nwords = key_bits / 32;  /* 4 or 8 */
    for (int w = 0; w < nwords; w++) {
        uint32_t word = (uint32_t)sv[7 - w];
        b[w*4+0] = (uint8_t)(word >> 24);
        b[w*4+1] = (uint8_t)(word >> 16);
        b[w*4+2] = (uint8_t)(word >>  8);
        b[w*4+3] = (uint8_t)(word >>  0);
    }
}

// ---------------------------------------------------------------------------
// Key expansion (FIPS-197 §5.2)
// ---------------------------------------------------------------------------
static void key_expansion(const uint8_t *key, int key_bits) {
    int nk = key_bits / 32;   /* 4 or 8 */
    g_nr = nk + 6;            /* 10 or 14 */
    int total = 4 * (g_nr + 1);

    /* Load initial key words */
    for (int i = 0; i < nk; i++) {
        g_rk[i] = ((uint32_t)key[i*4+0] << 24) | ((uint32_t)key[i*4+1] << 16) |
                  ((uint32_t)key[i*4+2] <<  8) | ((uint32_t)key[i*4+3]);
    }

    for (int i = nk; i < total; i++) {
        uint32_t temp = g_rk[i - 1];
        if (i % nk == 0) {
            /* RotWord + SubWord + Rcon */
            temp = ((uint32_t)SBOX[(temp >> 16) & 0xFF] << 24) |
                   ((uint32_t)SBOX[(temp >>  8) & 0xFF] << 16) |
                   ((uint32_t)SBOX[(temp >>  0) & 0xFF] <<  8) |
                   ((uint32_t)SBOX[(temp >> 24) & 0xFF] <<  0);
            temp ^= (uint32_t)RCON[i / nk] << 24;
        } else if (nk > 6 && i % nk == 4) {
            /* AES-256 extra SubWord */
            temp = ((uint32_t)SBOX[(temp >> 24) & 0xFF] << 24) |
                   ((uint32_t)SBOX[(temp >> 16) & 0xFF] << 16) |
                   ((uint32_t)SBOX[(temp >>  8) & 0xFF] <<  8) |
                   ((uint32_t)SBOX[(temp >>  0) & 0xFF] <<  0);
        }
        g_rk[i] = g_rk[i - nk] ^ temp;
    }
}

// ---------------------------------------------------------------------------
// AES cipher state helpers
// State[col][row], column-major per FIPS-197
// We use a flat 16-byte array: state[r + 4*c]
// ---------------------------------------------------------------------------
#define S(r,c) state[(r) + 4*(c)]

static void add_round_key(uint8_t *state, int round) {
    for (int c = 0; c < 4; c++) {
        uint32_t rk = g_rk[round*4 + c];
        S(0,c) ^= (uint8_t)(rk >> 24);
        S(1,c) ^= (uint8_t)(rk >> 16);
        S(2,c) ^= (uint8_t)(rk >>  8);
        S(3,c) ^= (uint8_t)(rk >>  0);
    }
}

static void sub_bytes(uint8_t *state) {
    for (int i = 0; i < 16; i++) state[i] = SBOX[state[i]];
}

static void inv_sub_bytes(uint8_t *state) {
    for (int i = 0; i < 16; i++) state[i] = INV_SBOX[state[i]];
}

static void shift_rows(uint8_t *state) {
    uint8_t tmp;
    /* Row 1: left rotate by 1 */
    tmp=S(1,0); S(1,0)=S(1,1); S(1,1)=S(1,2); S(1,2)=S(1,3); S(1,3)=tmp;
    /* Row 2: left rotate by 2 */
    tmp=S(2,0); S(2,0)=S(2,2); S(2,2)=tmp;
    tmp=S(2,1); S(2,1)=S(2,3); S(2,3)=tmp;
    /* Row 3: left rotate by 3 (= right rotate by 1) */
    tmp=S(3,3); S(3,3)=S(3,2); S(3,2)=S(3,1); S(3,1)=S(3,0); S(3,0)=tmp;
}

static void inv_shift_rows(uint8_t *state) {
    uint8_t tmp;
    /* Row 1: right rotate by 1 */
    tmp=S(1,3); S(1,3)=S(1,2); S(1,2)=S(1,1); S(1,1)=S(1,0); S(1,0)=tmp;
    /* Row 2: right rotate by 2 */
    tmp=S(2,0); S(2,0)=S(2,2); S(2,2)=tmp;
    tmp=S(2,1); S(2,1)=S(2,3); S(2,3)=tmp;
    /* Row 3: right rotate by 3 (= left rotate by 1) */
    tmp=S(3,0); S(3,0)=S(3,1); S(3,1)=S(3,2); S(3,2)=S(3,3); S(3,3)=tmp;
}

static void mix_columns(uint8_t *state) {
    for (int c = 0; c < 4; c++) {
        uint8_t s0=S(0,c), s1=S(1,c), s2=S(2,c), s3=S(3,c);
        S(0,c) = gmul(0x02,s0) ^ gmul(0x03,s1) ^ s2 ^ s3;
        S(1,c) = s0 ^ gmul(0x02,s1) ^ gmul(0x03,s2) ^ s3;
        S(2,c) = s0 ^ s1 ^ gmul(0x02,s2) ^ gmul(0x03,s3);
        S(3,c) = gmul(0x03,s0) ^ s1 ^ s2 ^ gmul(0x02,s3);
    }
}

static void inv_mix_columns(uint8_t *state) {
    for (int c = 0; c < 4; c++) {
        uint8_t s0=S(0,c), s1=S(1,c), s2=S(2,c), s3=S(3,c);
        S(0,c) = gmul(0x0e,s0) ^ gmul(0x0b,s1) ^ gmul(0x0d,s2) ^ gmul(0x09,s3);
        S(1,c) = gmul(0x09,s0) ^ gmul(0x0e,s1) ^ gmul(0x0b,s2) ^ gmul(0x0d,s3);
        S(2,c) = gmul(0x0d,s0) ^ gmul(0x09,s1) ^ gmul(0x0e,s2) ^ gmul(0x0b,s3);
        S(3,c) = gmul(0x0b,s0) ^ gmul(0x0d,s1) ^ gmul(0x09,s2) ^ gmul(0x0e,s3);
    }
}

// Load 16 bytes (big-endian block) into column-major state
static void bytes_to_state(const uint8_t *b, uint8_t *state) {
    for (int c = 0; c < 4; c++)
        for (int r = 0; r < 4; r++)
            S(r,c) = b[r + 4*c];
}

static void state_to_bytes(const uint8_t *state, uint8_t *b) {
    for (int c = 0; c < 4; c++)
        for (int r = 0; r < 4; r++)
            b[r + 4*c] = S(r,c);
}

// ---------------------------------------------------------------------------
// Core AES block encrypt / decrypt
// ---------------------------------------------------------------------------
static void aes_encrypt_block(const uint8_t *in, uint8_t *out) {
    uint8_t state[16];
    bytes_to_state(in, state);
    add_round_key(state, 0);
    for (int round = 1; round < g_nr; round++) {
        sub_bytes(state);
        shift_rows(state);
        mix_columns(state);
        add_round_key(state, round);
    }
    sub_bytes(state);
    shift_rows(state);
    add_round_key(state, g_nr);
    state_to_bytes(state, out);
}

static void aes_decrypt_block(const uint8_t *in, uint8_t *out) {
    uint8_t state[16];
    bytes_to_state(in, state);
    add_round_key(state, g_nr);
    for (int round = g_nr - 1; round >= 1; round--) {
        inv_shift_rows(state);
        inv_sub_bytes(state);
        add_round_key(state, round);
        inv_mix_columns(state);
    }
    inv_shift_rows(state);
    inv_sub_bytes(state);
    add_round_key(state, 0);
    state_to_bytes(state, out);
}

// ---------------------------------------------------------------------------
// Counter increment helpers (matching block_mode_ctrl.sv exactly)
// INC32:  increment lower 32 bits (bits 31:0 in SV = bytes 12..15)
// INC128: increment full 128-bit counter
// ---------------------------------------------------------------------------
static void inc32(uint8_t *ctr) {
    /* bytes[12..15] are the lower 32 bits (big-endian) */
    uint32_t lo = ((uint32_t)ctr[12] << 24) | ((uint32_t)ctr[13] << 16) |
                  ((uint32_t)ctr[14] <<  8) | ((uint32_t)ctr[15]);
    lo++;
    ctr[12] = (uint8_t)(lo >> 24);
    ctr[13] = (uint8_t)(lo >> 16);
    ctr[14] = (uint8_t)(lo >>  8);
    ctr[15] = (uint8_t)(lo >>  0);
}

static void inc128(uint8_t *ctr) {
    for (int i = 15; i >= 0; i--) {
        ctr[i]++;
        if (ctr[i] != 0) break;
    }
}

// ---------------------------------------------------------------------------
// DPI-exported functions
// ---------------------------------------------------------------------------

void aes_ref_init(const svBitVecVal *key, int key_bits) {
    uint8_t key_bytes[32];
    memset(key_bytes, 0, sizeof(key_bytes));
    sv256_to_key_bytes(key, key_bytes, key_bits);
    key_expansion(key_bytes, key_bits);
}

void aes_ref_set_iv(const svBitVecVal *iv) {
    sv128_to_bytes(iv, g_iv);
}

void aes_ref_ecb_block(int decrypt,
                       const svBitVecVal *data_in,
                       svBitVecVal       *data_out) {
    uint8_t in[16], out[16];
    sv128_to_bytes(data_in, in);
    if (decrypt)
        aes_decrypt_block(in, out);
    else
        aes_encrypt_block(in, out);
    bytes_to_sv128(out, data_out);
}

void aes_ref_cbc_block(int decrypt,
                       const svBitVecVal *data_in,
                       svBitVecVal       *data_out) {
    uint8_t in[16], out[16];
    sv128_to_bytes(data_in, in);

    if (decrypt) {
        /* CBC decrypt: out = AES_dec(in) XOR iv; iv_next = in */
        uint8_t dec[16];
        aes_decrypt_block(in, dec);
        for (int i = 0; i < 16; i++) out[i] = dec[i] ^ g_iv[i];
        memcpy(g_iv, in, 16);            /* iv_next = ciphertext */
    } else {
        /* CBC encrypt: out = AES_enc(in XOR iv); iv_next = out */
        uint8_t xored[16];
        for (int i = 0; i < 16; i++) xored[i] = in[i] ^ g_iv[i];
        aes_encrypt_block(xored, out);
        memcpy(g_iv, out, 16);           /* iv_next = ciphertext */
    }
    bytes_to_sv128(out, data_out);
}

void aes_ref_ofb_block(const svBitVecVal *data_in,
                       svBitVecVal       *data_out) {
    /* OFB: keystream = AES_enc(iv); out = in XOR keystream; iv_next = keystream */
    uint8_t in[16], keystream[16], out[16];
    sv128_to_bytes(data_in, in);
    aes_encrypt_block(g_iv, keystream);
    for (int i = 0; i < 16; i++) out[i] = in[i] ^ keystream[i];
    memcpy(g_iv, keystream, 16);
    bytes_to_sv128(out, data_out);
}

void aes_ref_ctr_block(int inc_sel,
                       const svBitVecVal *data_in,
                       svBitVecVal       *data_out) {
    /* CTR: keystream = AES_enc(ctr); out = in XOR keystream; ctr_next = INC(ctr) */
    uint8_t in[16], keystream[16], out[16];
    sv128_to_bytes(data_in, in);
    aes_encrypt_block(g_iv, keystream);
    for (int i = 0; i < 16; i++) out[i] = in[i] ^ keystream[i];
    if (inc_sel)
        inc128(g_iv);
    else
        inc32(g_iv);
    bytes_to_sv128(out, data_out);
}

void aes_ref_cfb128_block(int decrypt,
                          const svBitVecVal *data_in,
                          svBitVecVal       *data_out) {
    /* CFB-128: keystream = AES_enc(iv); out = in XOR keystream
     * encrypt: iv_next = out (ciphertext output)
     * decrypt: iv_next = in (ciphertext input)
     */
    uint8_t in[16], keystream[16], out[16];
    sv128_to_bytes(data_in, in);
    aes_encrypt_block(g_iv, keystream);
    for (int i = 0; i < 16; i++) out[i] = in[i] ^ keystream[i];
    if (decrypt)
        memcpy(g_iv, in, 16);   /* feedback = ciphertext input */
    else
        memcpy(g_iv, out, 16);  /* feedback = ciphertext output */
    bytes_to_sv128(out, data_out);
}
