// PSoC 6 Crypto Block Package
// Register offsets, bit-field positions, enumerations, and AHB constants
// All addresses are offsets from CRYPTO base 0x40110000
// Source: PSoC 6 Registers TRM 002-20777 Rev. *F, Chapter 3 (pp. 266-317)

package crypto_pkg;

    // ---------------------------------------------------------------
    // Absolute base addresses
    // ---------------------------------------------------------------
    localparam logic [31:0] CRYPTO_BASE     = 32'h4011_0000;
    localparam logic [31:0] MEM_BUFF_BASE   = 32'h4011_4000; // 1024 x 32-bit SRAM

    // ---------------------------------------------------------------
    // Register offsets (15-bit, word-aligned)
    // Regs 3.1.1 – 3.1.42 from the Registers TRM
    // ---------------------------------------------------------------

    // ---- Global control & status (§3.1.1 – 3.1.5) ----
    localparam logic [14:0] CRYPTO_CTL              = 15'h0000; // Control
    localparam logic [14:0] CRYPTO_STATUS           = 15'h0004; // Status (RO)
    localparam logic [14:0] CRYPTO_RAM_PWRUP_DELAY  = 15'h0008; // SRAM power-up delay
    localparam logic [14:0] CRYPTO_ERROR_STATUS0    = 15'h0020; // Error data word (RO)
    localparam logic [14:0] CRYPTO_ERROR_STATUS1    = 15'h0024; // Error meta (VALID/IDX) (RO)

    // ---- Instruction FIFO (§3.1.6 – 3.1.8) ----
    localparam logic [14:0] CRYPTO_INSTR_FF_CTL     = 15'h0040; // FIFO control (BLOCK/CLEAR/EVENT_LEVEL)
    localparam logic [14:0] CRYPTO_INSTR_FF_STATUS  = 15'h0044; // FIFO status  (BUSY/EVENT/USED)
    localparam logic [14:0] CRYPTO_INSTR_FF_WR      = 15'h0048; // FIFO write   (WO – pushes one word)

    // ---- Vector-unit register file, 16 entries (§3.1.9) ----
    // RF_DATAn = 0x080 + 4*n, n in 0..15
    localparam logic [14:0] CRYPTO_RF_DATA0         = 15'h0080;
    localparam logic [14:0] CRYPTO_RF_DATA15        = 15'h00BC;
    localparam int          RF_NREGS                = 16;
    // Layout of each RF_DATAn word:
    //   [29:16] data  (14-bit value)
    //   [11: 0] size  (bit-size minus 1; 12-bit field)

    // ---- AES engine (§3.1.10) ----
    localparam logic [14:0] CRYPTO_AES_CTL          = 15'h0100; // KEY_SIZE[1:0]

    // ---- String / memory-compare result (§3.1.11) ----
    localparam logic [14:0] CRYPTO_STR_RESULT       = 15'h0180; // MEMCMP[0] (RO)

    // ---- Pseudo-random (PRNG) (§3.1.12 – 3.1.15) ----
    localparam logic [14:0] CRYPTO_PR_LFSR_CTL0     = 15'h0200; // 32-bit LFSR state
    localparam logic [14:0] CRYPTO_PR_LFSR_CTL1     = 15'h0204; // 31-bit LFSR state [30:0]
    localparam logic [14:0] CRYPTO_PR_LFSR_CTL2     = 15'h0208; // 29-bit LFSR state [28:0]
    localparam logic [14:0] CRYPTO_PR_RESULT        = 15'h0210; // Result (RW – SW can clear)

    // ---- True-random (TRNG) core (§3.1.16 – 3.1.18) ----
    localparam logic [14:0] CRYPTO_TR_CTL0          = 15'h0280; // Sample/red clk divs, INIT_DELAY, Von-Neumann, stop-on-detect
    localparam logic [14:0] CRYPTO_TR_CTL1          = 15'h0284; // Oscillator enables (FIRO31/15, GARO31/15, RO15/11)
    localparam logic [14:0] CRYPTO_TR_RESULT        = 15'h0288; // 32-bit random result (RW – SW can clear)

    // ---- TRNG programmable ring oscillators (§3.1.19 – 3.1.20) ----
    localparam logic [14:0] CRYPTO_TR_GARO_CTL      = 15'h02A0; // GARO31 polynomial [30:0]
    localparam logic [14:0] CRYPTO_TR_FIRO_CTL      = 15'h02A4; // FIRO31 polynomial [30:0]

    // ---- TRNG health monitors (§3.1.21 – 3.1.28) ----
    localparam logic [14:0] CRYPTO_TR_MON_CTL       = 15'h02C0; // Bitstream selector [1:0]
    localparam logic [14:0] CRYPTO_TR_MON_CMD       = 15'h02C8; // START_RC[1], START_AP[0]
    localparam logic [14:0] CRYPTO_TR_MON_RC_CTL    = 15'h02D0; // RC cutoff count [7:0], default=255
    localparam logic [14:0] CRYPTO_TR_MON_RC_STS0   = 15'h02D8; // RC current bit value [0]
    localparam logic [14:0] CRYPTO_TR_MON_RC_STS1   = 15'h02DC; // RC repetition count [7:0]
    localparam logic [14:0] CRYPTO_TR_MON_AP_CTL    = 15'h02E0; // AP window size [31:16], cutoff [15:0]
    localparam logic [14:0] CRYPTO_TR_MON_AP_STS0   = 15'h02E8; // AP current bit value [0]
    localparam logic [14:0] CRYPTO_TR_MON_AP_STS1   = 15'h02EC; // AP window index [31:16], occ count [15:0]

    // ---- SHA engine (§3.1.29) ----
    localparam logic [14:0] CRYPTO_SHA_CTL          = 15'h0300; // MODE[2:0]

    // ---- CRC engine (§3.1.30 – 3.1.35) ----
    localparam logic [14:0] CRYPTO_CRC_CTL          = 15'h0400; // REM_REVERSE[8], DATA_REVERSE[0]
    localparam logic [14:0] CRYPTO_CRC_DATA_CTL     = 15'h0410; // DATA_XOR[7:0]
    localparam logic [14:0] CRYPTO_CRC_POL_CTL      = 15'h0420; // POLYNOMIAL[31:0] (without high-order bit)
    localparam logic [14:0] CRYPTO_CRC_LFSR_CTL     = 15'h0430; // LFSR32[31:0] – seed / state
    localparam logic [14:0] CRYPTO_CRC_REM_CTL      = 15'h0440; // REM_XOR[31:0]
    localparam logic [14:0] CRYPTO_CRC_REM_RESULT   = 15'h0448; // REM[31:0] (RO, combinatorially derived)

    // ---- Vector unit control (§3.1.36 – 3.1.38) ----
    localparam logic [14:0] CRYPTO_VU_CTL0          = 15'h0480; // ALWAYS_EXECUTE[0]
    localparam logic [14:0] CRYPTO_VU_CTL1          = 15'h0484; // ADDR[31:14] – 16 KB-aligned base for VU operands
    localparam logic [14:0] CRYPTO_VU_STATUS        = 15'h0490; // ONE[3] ZERO[2] EVEN[1] CARRY[0] (RO)

    // ---- Standard interrupt quad (§3.1.39 – 3.1.42) ----
    localparam logic [14:0] CRYPTO_INTR             = 15'h07C0; // RW1C – interrupt request
    localparam logic [14:0] CRYPTO_INTR_SET         = 15'h07C4; // RW1S – software-force
    localparam logic [14:0] CRYPTO_INTR_MASK        = 15'h07C8; // RW   – enable mask
    localparam logic [14:0] CRYPTO_INTR_MASKED      = 15'h07CC; // RO   – INTR & INTR_MASK

    // ---- Memory buffer (§3.1 table footnote) ----
    // 1024 words (4 KB), accessed as CRYPTO_MEM_BUFFn at 0x40114000 + 4*n.
    // Offset from CRYPTO_BASE = 0x4000.
    localparam logic [15:0] MEM_BUFF_OFFSET         = 16'h4000;
    localparam int          MEM_BUFF_WORDS          = 1024;

    // ---------------------------------------------------------------
    // Extension registers (offset 0x800 – 0x880, non-PSoC-6 additions)
    // 33 registers covering AEAD, key management, protection, feature
    // discovery, context switching, and cancellation.
    // ---------------------------------------------------------------

    // -- AEAD helpers --
    localparam logic [14:0] EXT_AAD_ADDR            = 15'h0800; // AAD buffer start address
    localparam logic [14:0] EXT_AAD_LEN             = 15'h0804; // AAD byte length
    localparam logic [14:0] EXT_MAC_ADDR            = 15'h0808; // MAC/tag destination address
    localparam logic [14:0] EXT_MAC_VERIF_RESULT    = 15'h080C; // Tag verify result [0] (RO, 1=match)
    localparam logic [14:0] EXT_XOF_LEN             = 15'h0810; // XOF (SHAKE) output byte length

    // -- Key management --
    localparam logic [14:0] EXT_KEY_ADDR            = 15'h0820; // Key material source address
    localparam logic [14:0] EXT_KEY_ID              = 15'h0824; // Key slot identifier [7:0]
    localparam logic [14:0] EXT_KEYTP1_PERM         = 15'h0828; // Key-type-1 permission bitmap
    localparam logic [14:0] EXT_KEYTP1_VALID        = 15'h082C; // Key-type-1 validity bitmap

    // -- Protection --
    localparam logic [14:0] EXT_QDENY_CFG           = 15'h0840; // Quick-deny configuration bitmap
    localparam logic [14:0] EXT_USER_PERM           = 15'h0844; // Unprivileged access permissions

    // -- Feature discovery --
    localparam logic [14:0] EXT_FEATURE_AVAIL       = 15'h0850; // Available engine bitmask (RO)
    localparam logic [14:0] EXT_FEATURE_CFG         = 15'h0854; // Feature enable/disable mask (RW)
    localparam logic [14:0] EXT_SYSTEM_STATE        = 15'h0858; // System state cookie (RW)

    // -- Context save/restore --
    localparam logic [14:0] EXT_CTX_ADDR            = 15'h0860; // Context save/restore buffer address

    // -- Operation cancellation --
    localparam logic [14:0] EXT_CANCEL              = 15'h0870; // Write 1 to cancel running operation (WO)

    // ---------------------------------------------------------------
    // AHB-Lite protocol constants
    // ---------------------------------------------------------------
    localparam logic [1:0] HTRANS_IDLE     = 2'b00;
    localparam logic [1:0] HTRANS_BUSY     = 2'b01;
    localparam logic [1:0] HTRANS_NONSEQ   = 2'b10;
    localparam logic [1:0] HTRANS_SEQ      = 2'b11;

    localparam logic [2:0] HSIZE_BYTE      = 3'b000; // 8-bit
    localparam logic [2:0] HSIZE_HALF      = 3'b001; // 16-bit
    localparam logic [2:0] HSIZE_WORD      = 3'b010; // 32-bit

    localparam logic [2:0] HBURST_SINGLE   = 3'b000;
    localparam logic [2:0] HBURST_INCR     = 3'b001;

    localparam logic HWRITE_READ           = 1'b0;
    localparam logic HWRITE_WRITE          = 1'b1;

    localparam logic HRESP_OKAY            = 1'b0;
    localparam logic HRESP_ERROR           = 1'b1;

    localparam logic HREADY_STALL          = 1'b0;
    localparam logic HREADY_READY          = 1'b1;

    // ---------------------------------------------------------------
    // CRYPTO_CTL bit positions
    // ---------------------------------------------------------------
    localparam int CTL_BIT_ENABLED         = 31;
    localparam int CTL_BIT_PWR_MODE_HI     = 1;
    localparam int CTL_BIT_PWR_MODE_LO     = 0;

    // ---------------------------------------------------------------
    // CRYPTO_STATUS bit positions (all RO)
    // ---------------------------------------------------------------
    localparam int STATUS_BIT_CMD_FF_BUSY  = 31;
    localparam int STATUS_BIT_VU_BUSY      = 7;
    localparam int STATUS_BIT_TR_BUSY      = 6;
    localparam int STATUS_BIT_PR_BUSY      = 5;
    localparam int STATUS_BIT_STR_BUSY     = 4;
    localparam int STATUS_BIT_CRC_BUSY     = 3;
    localparam int STATUS_BIT_SHA_BUSY     = 2;
    localparam int STATUS_BIT_DES_BUSY     = 1;
    localparam int STATUS_BIT_AES_BUSY     = 0;

    // ---------------------------------------------------------------
    // CRYPTO_INSTR_FF_CTL bit positions
    // ---------------------------------------------------------------
    localparam int INSTR_FF_CTL_BIT_BLOCK  = 17;
    localparam int INSTR_FF_CTL_BIT_CLEAR  = 16;
    localparam int INSTR_FF_CTL_EL_HI      = 2;
    localparam int INSTR_FF_CTL_EL_LO      = 0;

    // ---------------------------------------------------------------
    // CRYPTO_INSTR_FF_STATUS bit positions
    // ---------------------------------------------------------------
    localparam int INSTR_FF_STS_BIT_BUSY   = 31;
    localparam int INSTR_FF_STS_BIT_EVENT  = 16;
    localparam int INSTR_FF_STS_USED_HI    = 3;
    localparam int INSTR_FF_STS_USED_LO    = 0;
    localparam int INSTR_FF_DEPTH          = 8;  // 8-entry deep

    // ---------------------------------------------------------------
    // CRYPTO_ERROR_STATUS1 bit positions
    // ---------------------------------------------------------------
    localparam int ERR1_BIT_VALID          = 31;
    localparam int ERR1_IDX_HI            = 26;
    localparam int ERR1_IDX_LO            = 24;
    localparam int ERR1_DATA23_HI         = 23;
    localparam int ERR1_DATA23_LO         = 0;

    // ---------------------------------------------------------------
    // CRYPTO_INTR / INTR_SET / INTR_MASK / INTR_MASKED bit positions
    // ---------------------------------------------------------------
    localparam int INTR_BIT_TR_RC_DETECT_ERR = 20;
    localparam int INTR_BIT_TR_AP_DETECT_ERR = 19;
    localparam int INTR_BIT_BUS_ERROR        = 18;
    localparam int INTR_BIT_INSTR_CC_ERROR   = 17;
    localparam int INTR_BIT_INSTR_OPC_ERROR  = 16;
    localparam int INTR_BIT_PR_DATA_AVAIL    = 4;
    localparam int INTR_BIT_TR_DATA_AVAIL    = 3;
    localparam int INTR_BIT_TR_INITIALIZED   = 2;
    localparam int INTR_BIT_INSTR_FF_OFLOW   = 1;
    localparam int INTR_BIT_INSTR_FF_LEVEL   = 0;

    // Convenience mask for all error interrupts
    localparam logic [31:0] INTR_MASK_ERRORS =
        (32'h1 << INTR_BIT_TR_RC_DETECT_ERR) |
        (32'h1 << INTR_BIT_TR_AP_DETECT_ERR) |
        (32'h1 << INTR_BIT_BUS_ERROR)        |
        (32'h1 << INTR_BIT_INSTR_CC_ERROR)   |
        (32'h1 << INTR_BIT_INSTR_OPC_ERROR);

    // ---------------------------------------------------------------
    // VU_STATUS bit positions (RO)
    // ---------------------------------------------------------------
    localparam int VU_STS_BIT_ONE   = 3;
    localparam int VU_STS_BIT_ZERO  = 2;
    localparam int VU_STS_BIT_EVEN  = 1;
    localparam int VU_STS_BIT_CARRY = 0;

    // ---------------------------------------------------------------
    // PRNG default seed values (Registers TRM §3.1.12-14)
    // Irreducible polynomials: x^32+x^30+x^26+x^25+1,
    //                          x^31+x^28+1, x^29+x^27+1
    // ---------------------------------------------------------------
    localparam logic [31:0] PR_LFSR0_DEFAULT = 32'hD8959BC9; // 3633683401 decimal
    localparam logic [30:0] PR_LFSR1_DEFAULT = 31'h2BB911F8; // 733549048  decimal
    localparam logic [28:0] PR_LFSR2_DEFAULT = 29'h060C31B7; // 101462455  decimal

    // ---------------------------------------------------------------
    // TRNG health monitor defaults (Registers TRM §3.1.23, 3.1.26)
    // ---------------------------------------------------------------
    localparam logic [7:0]  TR_MON_RC_CUTOFF_DEFAULT  = 8'hFF; // 255
    localparam logic [15:0] TR_MON_AP_WINDOW_DEFAULT  = 16'hFFFF; // 65535
    localparam logic [15:0] TR_MON_AP_CUTOFF_DEFAULT  = 16'hFFFF; // 65535

    // ---------------------------------------------------------------
    // Enumeration types
    // ---------------------------------------------------------------

    // CTL.PWR_MODE (bits [1:0]) – memory buffer power mode
    typedef enum logic [1:0] {
        PWR_OFF      = 2'd0,
        PWR_RESERVED = 2'd1,
        PWR_RETAINED = 2'd2,
        PWR_ENABLED  = 2'd3  // reset default
    } pwr_mode_e;

    // AES_CTL.KEY_SIZE (bits [1:0])
    typedef enum logic [1:0] {
        AES_KEY128 = 2'd0,  // 16-byte key, 10 rounds
        AES_KEY192 = 2'd1,  // 24-byte key, 12 rounds
        AES_KEY256 = 2'd2   // 32-byte key, 14 rounds
    } aes_key_size_e;

    // SHA_CTL.MODE (bits [2:0])
    typedef enum logic [2:0] {
        SHA_MODE_SHA1   = 3'd0,  // 160-bit digest, 20 bytes
        SHA_MODE_SHA256 = 3'd1,  // 256 or 224-bit digest, 32 bytes
        SHA_MODE_SHA512 = 3'd2   // 512/384/256/224-bit digest, 64 bytes
    } sha_mode_e;

    // TR_MON_CTL.BITSTREAM_SEL (bits [1:0])
    typedef enum logic [1:0] {
        TRNG_BSTR_DAS = 2'd0,   // DAS bitstream (digital)
        TRNG_BSTR_RED = 2'd1,   // Reduced bitstream
        TRNG_BSTR_TR  = 2'd2,   // True-random bitstream (default)
        TRNG_BSTR_UNDEF = 2'd3  // Undefined
    } trng_bitstream_sel_e;

    // ERROR_STATUS1.IDX (bits [26:24]) – which error source fired
    typedef enum logic [2:0] {
        ERR_IDX_INSTR_OPC   = 3'd0,  // Illegal opcode
        ERR_IDX_INSTR_CC    = 3'd1,  // Undefined condition code
        ERR_IDX_BUS         = 3'd2,  // AHB-Lite master bus fault
        ERR_IDX_TR_AP       = 3'd3,  // TRNG adaptive-proportion detect
        ERR_IDX_TR_RC       = 3'd4   // TRNG repetition-count detect
    } error_idx_e;

    // EXT_FEATURE_AVAIL / EXT_FEATURE_CFG bit positions
    localparam int FEAT_BIT_AES   = 0;
    localparam int FEAT_BIT_DES   = 1;
    localparam int FEAT_BIT_SHA   = 2;
    localparam int FEAT_BIT_CRC   = 3;
    localparam int FEAT_BIT_PRNG  = 4;
    localparam int FEAT_BIT_TRNG  = 5;
    localparam int FEAT_BIT_VU    = 6;
    localparam int FEAT_BIT_AEAD  = 7;  // extension

    // ---------------------------------------------------------------
    // AES parameters (for RTL round-logic sizing)
    // ---------------------------------------------------------------
    localparam int AES128_NR = 10;
    localparam int AES192_NR = 12;
    localparam int AES256_NR = 14;
    localparam int AES_MAX_NR  = AES256_NR;
    localparam int AES_MAX_RK  = AES_MAX_NR + 1; // 15 round-key arrays

    // ---------------------------------------------------------------
    // DES parameters
    // ---------------------------------------------------------------
    localparam int DES_ROUNDS  = 16;
    localparam int TDES_KEYS   = 3;

    // ---------------------------------------------------------------
    // SHA-2 / SHA-3 parameters
    // ---------------------------------------------------------------
    localparam int SHA1_BLOCK_BYTES    = 64;
    localparam int SHA1_DIGEST_BYTES   = 20;
    localparam int SHA256_BLOCK_BYTES  = 64;
    localparam int SHA256_DIGEST_BYTES = 32;
    localparam int SHA512_BLOCK_BYTES  = 128;
    localparam int SHA512_DIGEST_BYTES = 64;
    localparam int SHA3_RATE_256_BYTES = 136; // SHAKE128 / SHA3-256
    localparam int SHA3_RATE_512_BYTES = 72;  // SHAKE256 / SHA3-512
    localparam int KECCAK_LANES        = 25;  // 5 x 5 state
    localparam int KECCAK_ROUNDS       = 24;

endpackage
