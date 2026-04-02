// AES Reference Model DPI Header
// Stateful per-block interface: call aes_ref_init() + aes_ref_set_iv() once,
// then call one of the block functions per 128-bit AES block.

#ifndef AES_REF_MODEL_DPI_H
#define AES_REF_MODEL_DPI_H

#include "svdpi.h"
#include <stdint.h>

// Load key and expand key schedule.
// key:      SV bit[255:0] — for AES-128 only bits[255:128] are used
// key_bits: 128 or 256
void aes_ref_init(const svBitVecVal *key, int key_bits);

// Set chaining IV (CBC / OFB / CTR / CFB).
// iv: SV bit[127:0]
void aes_ref_set_iv(const svBitVecVal *iv);

// ECB single-block encrypt (decrypt==0) or decrypt (decrypt==1).
void aes_ref_ecb_block(int decrypt,
                       const svBitVecVal *data_in,
                       svBitVecVal       *data_out);

// CBC single-block — internal IV updated automatically.
void aes_ref_cbc_block(int decrypt,
                       const svBitVecVal *data_in,
                       svBitVecVal       *data_out);

// OFB single-block (encrypt and decrypt are identical).
void aes_ref_ofb_block(const svBitVecVal *data_in,
                       svBitVecVal       *data_out);

// CTR single-block.  inc_sel: 0 = INC32 (lower 32 bits), 1 = INC128.
void aes_ref_ctr_block(int inc_sel,
                       const svBitVecVal *data_in,
                       svBitVecVal       *data_out);

// CFB-128 single-block encrypt (decrypt==0) or decrypt (decrypt==1).
// AES core always runs encrypt; IV feedback is ciphertext for encrypt,
// and the ciphertext input (data_in) for decrypt.
void aes_ref_cfb128_block(int decrypt,
                          const svBitVecVal *data_in,
                          svBitVecVal       *data_out);

#endif /* AES_REF_MODEL_DPI_H */
