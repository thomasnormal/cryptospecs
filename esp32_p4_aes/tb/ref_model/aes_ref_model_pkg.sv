// AES Reference Model Package
// DPI-C imports for the stateful per-block reference model.
// Import this package before aes_env_pkg.

package aes_ref_model_pkg;

    // ------------------------------------------------------------------
    // DPI-C imports  (implemented in aes_ref_model_dpi.c)
    // ------------------------------------------------------------------

    // Load key and build round-key schedule.
    // key:      bit[255:0] — only lower key_bits are meaningful for AES-128
    // key_bits: 128 or 256
    import "DPI-C" function void aes_ref_init(
        input  bit [255:0] key,
        input  int         key_bits
    );

    // Set the chaining IV used by CBC / OFB / CTR.
    import "DPI-C" function void aes_ref_set_iv(
        input  bit [127:0] iv
    );

    // ECB single block — decrypt==0 → encrypt, decrypt==1 → decrypt.
    import "DPI-C" function void aes_ref_ecb_block(
        input  int         decrypt,
        input  bit [127:0] data_in,
        output bit [127:0] data_out
    );

    // CBC single block — internal IV updated automatically after each call.
    import "DPI-C" function void aes_ref_cbc_block(
        input  int         decrypt,
        input  bit [127:0] data_in,
        output bit [127:0] data_out
    );

    // OFB single block — encrypt and decrypt are identical.
    import "DPI-C" function void aes_ref_ofb_block(
        input  bit [127:0] data_in,
        output bit [127:0] data_out
    );

    // CTR single block — counter incremented after each call.
    // inc_sel: 0 = INC32 (lower 32 bits), 1 = INC128.
    import "DPI-C" function void aes_ref_ctr_block(
        input  int         inc_sel,
        input  bit [127:0] data_in,
        output bit [127:0] data_out
    );

    // CFB-128 single block — decrypt==0 → encrypt, decrypt==1 → decrypt.
    // AES core always encrypts the IV/feedback; only the feedback source differs.
    import "DPI-C" function void aes_ref_cfb128_block(
        input  int         decrypt,
        input  bit [127:0] data_in,
        output bit [127:0] data_out
    );

endpackage : aes_ref_model_pkg
