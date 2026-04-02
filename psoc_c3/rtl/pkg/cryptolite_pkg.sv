// PSoC Control C3 CryptoLite Block Package
// Register offsets, bit-field positions, descriptor layout, and AHB constants
// Source: PSoC Control C3 Architecture TRM + Registers Reference Manual
//         (Infineon / Cypress)
//
// Programming model: descriptor-pointer
//   CPU writes a 4-byte-aligned pointer to AES_DESCR, SHA_DESCR, or VU_DESCR.
//   Hardware fetches the 3-word descriptor from memory via AHB master, executes,
//   then clears STATUS.BUSY and optionally fires an interrupt.
//   Only ONE function (AES / SHA / VU) may be active at a time; write transfers
//   to MMIO are blocked while BUSY='1'. TRNG runs independently.

package cryptolite_pkg;

    // ---------------------------------------------------------------
    // Base address
    // ---------------------------------------------------------------
    localparam logic [31:0] CRYPTOLITE_BASE = 32'h4223_0000;

    // ---------------------------------------------------------------
    // Register offsets (from CRYPTOLITE_BASE)
    // ---------------------------------------------------------------

    // Global control / status
    localparam logic [11:0] CTL            = 12'h000;
    localparam logic [11:0] STATUS         = 12'h004;

    // Descriptor pointers (write to start an operation)
    localparam logic [11:0] AES_DESCR      = 12'h040;
    localparam logic [11:0] VU_DESCR       = 12'h080;
    localparam logic [11:0] SHA_DESCR      = 12'h0C0;

    // Error interrupt quad (RW1C / RW1S / RW / RO)
    localparam logic [11:0] INTR_ERROR        = 12'h0F0;  // RW1C
    localparam logic [11:0] INTR_ERROR_SET    = 12'h0F4;  // RW1S
    localparam logic [11:0] INTR_ERROR_MASK   = 12'h0F8;  // RW
    localparam logic [11:0] INTR_ERROR_MASKED = 12'h0FC;  // RO

    // TRNG control and output
    localparam logic [11:0] TRNG_CTL0      = 12'h100;
    localparam logic [11:0] TRNG_CTL1      = 12'h104;
    localparam logic [11:0] TRNG_STATUS    = 12'h10C;
    localparam logic [11:0] TRNG_RESULT    = 12'h110;

    // TRNG programmable ring oscillator polynomials
    localparam logic [11:0] TRNG_GARO_CTL  = 12'h120;
    localparam logic [11:0] TRNG_FIRO_CTL  = 12'h124;

    // TRNG health monitor control
    localparam logic [11:0] TRNG_MON_CTL        = 12'h140;
    localparam logic [11:0] TRNG_MON_RC_CTL     = 12'h150;
    localparam logic [11:0] TRNG_MON_RC_STATUS0 = 12'h158;
    localparam logic [11:0] TRNG_MON_RC_STATUS1 = 12'h15C;
    localparam logic [11:0] TRNG_MON_AP_CTL     = 12'h160;
    localparam logic [11:0] TRNG_MON_AP_STATUS0 = 12'h168;
    localparam logic [11:0] TRNG_MON_AP_STATUS1 = 12'h16C;

    // TRNG interrupt quad
    localparam logic [11:0] INTR_TRNG        = 12'h1F0;  // RW1C
    localparam logic [11:0] INTR_TRNG_SET    = 12'h1F4;  // RW1S
    localparam logic [11:0] INTR_TRNG_MASK   = 12'h1F8;  // RW
    localparam logic [11:0] INTR_TRNG_MASKED = 12'h1FC;  // RO

    // ---------------------------------------------------------------
    // CTL register bit positions (0x000)
    // ---------------------------------------------------------------
    localparam int CTL_BIT_P          = 0;   // 0=user, 1=privileged
    localparam int CTL_BIT_NS         = 1;   // 0=secure, 1=non-secure
    localparam int CTL_PC_LO          = 4;   // protection context [7:4]
    localparam int CTL_PC_HI          = 7;
    localparam int CTL_MS_LO          = 8;   // master identifier [11:8]
    localparam int CTL_MS_HI          = 11;

    // ---------------------------------------------------------------
    // STATUS register bit positions (0x004)
    // ---------------------------------------------------------------
    localparam int STATUS_BIT_BUSY    = 0;   // 1 = AES/SHA/VU active (not TRNG)

    // ---------------------------------------------------------------
    // Descriptor pointer registers — bit positions (0x040, 0x080, 0x0C0)
    // PTR[31:2] is the 4-byte-aligned address of the 3-word descriptor.
    // ---------------------------------------------------------------
    localparam int DESCR_PTR_HI = 31;
    localparam int DESCR_PTR_LO = 2;

    // ---------------------------------------------------------------
    // INTR_ERROR bit positions (0x0F0)
    // ---------------------------------------------------------------
    localparam int INTR_ERR_BIT_BUS_ERROR = 0;  // AHB master bus error or ECC error

    // ---------------------------------------------------------------
    // TRNG_CTL0 bit positions (0x100)
    // ---------------------------------------------------------------
    localparam int TRNG_CTL0_SAMPLE_CLK_DIV_LO = 0;   // [7:0]
    localparam int TRNG_CTL0_SAMPLE_CLK_DIV_HI = 7;
    localparam int TRNG_CTL0_RED_CLK_DIV_LO    = 8;   // [15:8]
    localparam int TRNG_CTL0_RED_CLK_DIV_HI    = 15;
    localparam int TRNG_CTL0_INIT_DELAY_LO      = 16;  // [23:16]  default: 3
    localparam int TRNG_CTL0_INIT_DELAY_HI      = 23;
    localparam int TRNG_CTL0_BIT_VON_NEUMANN    = 24;
    localparam int TRNG_CTL0_BIT_FEEDBACK_EN    = 25;
    localparam int TRNG_CTL0_BIT_STOP_ON_AP     = 28;
    localparam int TRNG_CTL0_BIT_STOP_ON_RC     = 29;

    // ---------------------------------------------------------------
    // TRNG_CTL1 ring oscillator enable bits (0x104)
    // ---------------------------------------------------------------
    localparam int TRNG_CTL1_BIT_RO11_EN   = 0;
    localparam int TRNG_CTL1_BIT_RO15_EN   = 1;
    localparam int TRNG_CTL1_BIT_GARO15_EN = 2;
    localparam int TRNG_CTL1_BIT_GARO31_EN = 3;
    localparam int TRNG_CTL1_BIT_FIRO15_EN = 4;
    localparam int TRNG_CTL1_BIT_FIRO31_EN = 5;

    // ---------------------------------------------------------------
    // TRNG_STATUS bit positions (0x10C)
    // ---------------------------------------------------------------
    localparam int TRNG_STATUS_BIT_INITIALIZED = 0;

    // ---------------------------------------------------------------
    // TRNG_MON_CTL bit positions (0x140)
    // ---------------------------------------------------------------
    localparam int TRNG_MON_CTL_BSEL_LO = 0;   // bitstream select [1:0]
    localparam int TRNG_MON_CTL_BSEL_HI = 1;
    localparam int TRNG_MON_CTL_BIT_AP  = 8;   // adaptive proportion test enable
    localparam int TRNG_MON_CTL_BIT_RC  = 9;   // repetition count test enable

    // TRNG bitstream select encoding
    typedef enum logic [1:0] {
        BSEL_DAS  = 2'd0,  // digitised analog samples
        BSEL_RED  = 2'd1,  // reduction bits
        BSEL_TR   = 2'd2,  // true random bits (default)
        BSEL_UNDEF= 2'd3
    } trng_bsel_e;

    // ---------------------------------------------------------------
    // TRNG default polynomial values (from spec)
    // ---------------------------------------------------------------
    localparam logic [30:0] TRNG_GARO_DEFAULT = 31'h21F8_1910;
    localparam logic [30:0] TRNG_FIRO_DEFAULT = 31'h696F_0221;

    // ---------------------------------------------------------------
    // INTR_TRNG bit positions (0x1F0)
    // ---------------------------------------------------------------
    localparam int INTR_TRNG_BIT_INITIALIZED   = 0;
    localparam int INTR_TRNG_BIT_DATA_AVAILABLE= 1;
    localparam int INTR_TRNG_BIT_AP_DETECT     = 2;
    localparam int INTR_TRNG_BIT_RC_DETECT     = 3;

    // ---------------------------------------------------------------
    // AES descriptor layout (in system memory, 3 × 32-bit words)
    // Word 0: {24'h0, 8'h01} — function selector (0x01 = encrypt)
    // Word 1: 32-bit pointer to {key[127:0], src[127:0]} — key first
    // Word 2: 32-bit pointer to dst[127:0] (128-bit ciphertext)
    // All pointers must be 4-byte aligned.
    // ---------------------------------------------------------------
    localparam int AES_DESCR_FUNC_WORD  = 0;
    localparam int AES_DESCR_SRC_WORD   = 1;  // points to {key, plaintext}
    localparam int AES_DESCR_DST_WORD   = 2;  // points to ciphertext output

    // ---------------------------------------------------------------
    // SHA-256 descriptor layout (in system memory, 3 × 32-bit words)
    // Schedule function (MSG_SCH):
    //   Word 0: function = MSG_SCH
    //   Word 1: pointer to 512-bit (64-byte) message chunk (input)
    //   Word 2: pointer to 64×32-bit (256-byte) message schedule array (output)
    // Process function (PROCESS):
    //   Word 0: function = PROCESS
    //   Word 1: pointer to 8×32-bit (32-byte) hash state (input/output)
    //   Word 2: pointer to 64×32-bit (256-byte) message schedule array (input)
    // ---------------------------------------------------------------
    localparam logic [7:0] SHA_FUNC_MSG_SCH = 8'h01;  // message schedule
    localparam logic [7:0] SHA_FUNC_PROCESS = 8'h02;  // hash round

    localparam int SHA_DESCR_FUNC_WORD  = 0;
    localparam int SHA_DESCR_OP1_WORD   = 1;  // msg chunk (sch) or hash state (proc)
    localparam int SHA_DESCR_OP2_WORD   = 2;  // schedule array (both functions)

    // SHA-256 state and schedule sizes
    localparam int SHA256_HASH_WORDS    = 8;    //  8 × 32-bit = 256-bit hash state
    localparam int SHA256_SCHED_WORDS   = 64;   // 64 × 32-bit message schedule
    localparam int SHA256_BLOCK_WORDS   = 16;   // 16 × 32-bit = 512-bit message block

    // ---------------------------------------------------------------
    // AHB-Lite constants (shared with AHB slave and master interfaces)
    // ---------------------------------------------------------------
    localparam logic [1:0] HTRANS_IDLE   = 2'b00;
    localparam logic [1:0] HTRANS_BUSY   = 2'b01;
    localparam logic [1:0] HTRANS_NONSEQ = 2'b10;
    localparam logic [1:0] HTRANS_SEQ    = 2'b11;
    localparam logic [2:0] HSIZE_BYTE    = 3'b000;
    localparam logic [2:0] HSIZE_HALF    = 3'b001;
    localparam logic [2:0] HSIZE_WORD    = 3'b010;
    localparam logic       HWRITE_READ   = 1'b0;
    localparam logic       HWRITE_WRITE  = 1'b1;
    localparam logic       HRESP_OKAY    = 1'b0;
    localparam logic       HRESP_ERROR   = 1'b1;
    localparam logic       HREADY_STALL  = 1'b0;
    localparam logic       HREADY_READY  = 1'b1;

endpackage
