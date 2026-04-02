// AES Accelerator Package
// Types, parameters, and register offset constants

package aes_accel_pkg;

    // ---------------------------------------------------------------
    // Register address offsets (12-bit, word-aligned)
    // ---------------------------------------------------------------
    localparam logic [11:0] ADDR_KEY0          = 12'h000; // KEY_0 through KEY_7 at 0x000-0x01C
    localparam logic [11:0] ADDR_KEY7          = 12'h01C;
    localparam logic [11:0] ADDR_TEXT_IN0      = 12'h020; // TEXT_IN_0 through TEXT_IN_3
    localparam logic [11:0] ADDR_TEXT_IN3      = 12'h02C;
    localparam logic [11:0] ADDR_TEXT_OUT0     = 12'h030; // TEXT_OUT_0 through TEXT_OUT_3 (RO)
    localparam logic [11:0] ADDR_TEXT_OUT3     = 12'h03C;
    localparam logic [11:0] ADDR_MODE          = 12'h040;
    localparam logic [11:0] ADDR_TRIGGER       = 12'h048;
    localparam logic [11:0] ADDR_STATE         = 12'h04C;
    localparam logic [11:0] ADDR_IV0           = 12'h050; // IV_MEM 0x050-0x05F
    localparam logic [11:0] ADDR_IV3           = 12'h05C;
    localparam logic [11:0] ADDR_H0            = 12'h060; // H_MEM 0x060-0x06F (RO)
    localparam logic [11:0] ADDR_H3            = 12'h06C;
    localparam logic [11:0] ADDR_J0_0          = 12'h070; // J0_MEM 0x070-0x07F
    localparam logic [11:0] ADDR_J0_3          = 12'h07C;
    localparam logic [11:0] ADDR_T0_0          = 12'h080; // T0_MEM 0x080-0x08F (RO)
    localparam logic [11:0] ADDR_T0_3          = 12'h08C;
    localparam logic [11:0] ADDR_DMA_ENA       = 12'h090;
    localparam logic [11:0] ADDR_BLK_MODE      = 12'h094;
    localparam logic [11:0] ADDR_BLK_NUM       = 12'h098;
    localparam logic [11:0] ADDR_INC_SEL       = 12'h09C;
    localparam logic [11:0] ADDR_AAD_BLK_NUM   = 12'h0A0;
    localparam logic [11:0] ADDR_REM_BIT       = 12'h0A4;
    localparam logic [11:0] ADDR_CONT_OP       = 12'h0A8; // WO
    localparam logic [11:0] ADDR_INT_CLR       = 12'h0AC; // WT
    localparam logic [11:0] ADDR_INT_ENA       = 12'h0B0;
    localparam logic [11:0] ADDR_DMA_EXIT      = 12'h0B8; // WO
    localparam logic [11:0] ADDR_DMA_SRC_ADDR  = 12'h0BC;
    localparam logic [11:0] ADDR_DMA_DST_ADDR  = 12'h0C0;

    // ---------------------------------------------------------------
    // Block cipher mode encoding (BLOCK_MODE_REG[2:0])
    // ---------------------------------------------------------------
    typedef enum logic [2:0] {
        BLK_ECB    = 3'd0,
        BLK_CBC    = 3'd1,
        BLK_OFB    = 3'd2,
        BLK_CTR    = 3'd3,
        BLK_CFB8   = 3'd4,
        BLK_CFB128 = 3'd5,
        BLK_GCM    = 3'd6
    } blk_mode_e;

    // ---------------------------------------------------------------
    // Accelerator state (STATE_REG[1:0])
    // ---------------------------------------------------------------
    typedef enum logic [1:0] {
        ST_IDLE = 2'd0,
        ST_WORK = 2'd1,
        ST_DONE = 2'd2
    } accel_state_e;

    // ---------------------------------------------------------------
    // AES parameters
    // ---------------------------------------------------------------
    localparam int AES128_NR = 10; // Number of rounds for AES-128
    localparam int AES256_NR = 14; // Number of rounds for AES-256
    localparam int MAX_NR    = 14; // Maximum rounds (AES-256)
    localparam int MAX_RK    = 15; // Maximum round keys (Nr+1)

    // ---------------------------------------------------------------
    // AHB-Lite transfer types
    // ---------------------------------------------------------------
    localparam logic [1:0] HTRANS_IDLE   = 2'b00;
    localparam logic [1:0] HTRANS_NONSEQ = 2'b10;

    // AHB response
    localparam logic HRESP_OKAY  = 1'b0;
    localparam logic HRESP_ERROR = 1'b1;

endpackage
