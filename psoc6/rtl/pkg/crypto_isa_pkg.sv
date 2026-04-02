// PSoC 6 Crypto Block ISA Package
// All instruction opcodes, encodings, field positions, and condition codes
// Source: PSoC 6 MCU Architecture TRM 002-20730 Rev. *K, Chapter 11 (pp. 98-135)
//
// Instruction word layout (general form):
//   IW[31:24] = 8-bit operation code
//   IW[23:20] = 4-bit condition code (cc) — VU instructions only
//   Remaining fields depend on instruction category (see per-opcode comments)
//
// Special case: SET_REG uses only IW[31:30] = 2'b10 as its operation code,
//   freeing the remaining 30 bits for two 13-bit immediates + 4-bit destination.
//
// Cipher, hash, CRC, FIFO, and block instructions carry no condition code
//   and always execute (effectively ALWAYS condition).

package crypto_isa_pkg;

    // ---------------------------------------------------------------
    // Instruction word field positions (shared across categories)
    // ---------------------------------------------------------------
    localparam int IW_OPC_HI     = 31;  // opcode MSB
    localparam int IW_OPC_LO     = 24;  // opcode LSB
    localparam int IW_CC_HI      = 23;  // condition code MSB (VU only)
    localparam int IW_CC_LO      = 20;  // condition code LSB (VU only)

    // SET_REG special 2-bit opcode window
    localparam int IW_SETREG_OPC_HI  = 31;
    localparam int IW_SETREG_OPC_LO  = 30;
    localparam logic [1:0] SETREG_OPC_PATTERN = 2'b10;

    // SET_REG operand fields (within the 30 non-opcode bits)
    localparam int IW_SETREG_DST_HI   = 29;
    localparam int IW_SETREG_DST_LO   = 26;
    localparam int IW_SETREG_SIZE_HI  = 25;  // imm13_1 = size field (bits minus 1)
    localparam int IW_SETREG_SIZE_LO  = 13;
    localparam int IW_SETREG_DATA_HI  = 12;  // imm13_0 = data field
    localparam int IW_SETREG_DATA_LO  = 0;

    // ---------------------------------------------------------------
    // AES cipher instructions  (Tables 11-24, 11-25; §11.6)
    // Encoding: IW[31:24]=opcode only; no cc, no operand fields.
    // Operands fixed: block0=plaintext, block1=ciphertext,
    //   block4/5=key-in, block6/7=key-out.
    // ---------------------------------------------------------------
    localparam logic [7:0] OPC_AES     = 8'h50;  // AES block cipher
    localparam logic [7:0] OPC_AES_INV = 8'h51;  // AES inverse (decrypt)

    // ---------------------------------------------------------------
    // DES / TDES cipher instructions  (Tables 11-19 – 11-22; §11.5)
    // Encoding: IW[31:24]=opcode only.
    // Operands fixed: block0=plaintext, block1=ciphertext,
    //   block4=key-in(DES), block4/5=key-in(TDES), block5/7=key-out.
    // ---------------------------------------------------------------
    localparam logic [7:0] OPC_DES      = 8'h52;  // DES block cipher
    localparam logic [7:0] OPC_DES_INV  = 8'h53;  // DES inverse
    localparam logic [7:0] OPC_TDES     = 8'h54;  // Triple-DES
    localparam logic [7:0] OPC_TDES_INV = 8'h55;  // Triple-DES inverse

    // ---------------------------------------------------------------
    // CRC instruction  (Table 11-26; §11.7)
    // Encoding: IW[31:24]=opcode only.  Data comes from load FIFO 0.
    // ---------------------------------------------------------------
    localparam logic [7:0] OPC_CRC = 8'h58;

    // ---------------------------------------------------------------
    // Hash instructions  (Tables 11-14 – 11-18; §11.4)
    // Encoding: IW[31:24]=opcode only.
    // reg_buff[1023:0] = round weights (message block written before call).
    // reg_buff[1535:1024] = hash value in/out.
    // reg_buff[2047:1536] = working copy (SHA2_512 uses reg_buff[1023:0] too).
    // ---------------------------------------------------------------
    localparam logic [7:0] OPC_SHA1     = 8'h69;  // SHA-1   (512-bit block)
    localparam logic [7:0] OPC_SHA2_256 = 8'h6A;  // SHA2/224/256 (512-bit block)
    localparam logic [7:0] OPC_SHA2_512 = 8'h6B;  // SHA2/384/512 (1024-bit block)
    localparam logic [7:0] OPC_SHA3     = 8'h6C;  // SHA3/SHAKE Keccak perm
                                                    // on 1600-bit state in reg_buff[1599:0]

    // SHA round counts
    localparam int SHA1_ROUNDS     = 80;
    localparam int SHA2_256_ROUNDS = 64;
    localparam int SHA2_512_ROUNDS = 80;
    localparam int SHA3_ROUNDS     = 24;  // Keccak-p[1600,24]

    // ---------------------------------------------------------------
    // Register buffer instructions  (Tables 11-4 – 11-8; §11.3.4)
    // Encoding: IW[31:24]=opcode; lower bits carry immediate operands.
    // All operate on the 2048-bit register buffer (two 1024-bit halves).
    // ---------------------------------------------------------------

    // CLEAR — zero the entire register buffer (Table 11-4)
    // IW: opcode only
    localparam logic [7:0] OPC_CLEAR    = 8'h64;

    // SWAP — exchange the two 1024-bit register buffer halves (Table 11-5)
    // IW: opcode only
    localparam logic [7:0] OPC_SWAP     = 8'h65;

    // XOR (register buffer) — XOR load-FIFO-0 data into lower half (Table 11-6)
    // IW[14:8]=offset (byte offset within reg_buff[1023:0])
    // IW[7:0] =size   (bytes, range [0,128])
    localparam logic [7:0] OPC_REGB_XOR = 8'h66;
    localparam int IW_REGB_OFFSET_HI = 14;
    localparam int IW_REGB_OFFSET_LO = 8;
    localparam int IW_REGB_SIZE_HI   = 7;
    localparam int IW_REGB_SIZE_LO   = 0;

    // STORE — write lower reg_buff slice to store FIFO (Table 11-7)
    // IW[14:8]=offset, IW[7:0]=size  (same fields as REGB_XOR)
    localparam logic [7:0] OPC_STORE    = 8'h67;

    // BYTE_SET — set a single byte in reg_buff[1023:0] (Table 11-8)
    // IW[14:8]=offset (byte address), IW[7:0]=byte value
    localparam logic [7:0] OPC_BYTE_SET = 8'h68;

    // ---------------------------------------------------------------
    // Block operand identifiers (used in BLOCK_* and FIFO instructions)
    // Values 0-7 → reg_buff 128-bit subpartitions block0..block7
    // Value  8   → load FIFO 0
    // Value  9   → load FIFO 1
    // Value 12   → store FIFO
    // ---------------------------------------------------------------
    localparam logic [3:0] BLKID_BLOCK0     = 4'd0;
    localparam logic [3:0] BLKID_BLOCK1     = 4'd1;
    localparam logic [3:0] BLKID_BLOCK2     = 4'd2;
    localparam logic [3:0] BLKID_BLOCK3     = 4'd3;
    localparam logic [3:0] BLKID_BLOCK4     = 4'd4;
    localparam logic [3:0] BLKID_BLOCK5     = 4'd5;
    localparam logic [3:0] BLKID_BLOCK6     = 4'd6;
    localparam logic [3:0] BLKID_BLOCK7     = 4'd7;
    localparam logic [3:0] BLKID_LOAD_FIFO0 = 4'd8;
    localparam logic [3:0] BLKID_LOAD_FIFO1 = 4'd9;
    localparam logic [3:0] BLKID_STORE_FIFO = 4'd12;

    // ---------------------------------------------------------------
    // Block operation instructions  (Tables 11-9 – 11-13; §11.3.4)
    // Encoding: IW[31:24]=opcode, operand fields below.
    // Block size field: value 0 means 16 (full 128-bit block).
    // ---------------------------------------------------------------

    // BLOCK_MOV — copy/reflect a block (Table 11-9)
    // IW[23]=reflect, IW[19:16]=size(0→16), IW[15:12]=dst, IW[3:0]=src0
    localparam logic [7:0] OPC_BLOCK_MOV = 8'h40;
    localparam int IW_BMOV_REFLECT  = 23;
    localparam int IW_BMOV_SIZE_HI  = 19;
    localparam int IW_BMOV_SIZE_LO  = 16;
    localparam int IW_BMOV_DST_HI   = 15;
    localparam int IW_BMOV_DST_LO   = 12;
    localparam int IW_BMOV_SRC0_HI  = 3;
    localparam int IW_BMOV_SRC0_LO  = 0;

    // BLOCK_XOR — XOR two blocks into dst (Table 11-10)
    // IW[19:16]=size, IW[15:12]=dst, IW[7:4]=src1, IW[3:0]=src0
    localparam logic [7:0] OPC_BLOCK_XOR = 8'h41;
    localparam int IW_BXOR_SIZE_HI  = 19;
    localparam int IW_BXOR_SIZE_LO  = 16;
    localparam int IW_BXOR_DST_HI   = 15;
    localparam int IW_BXOR_DST_LO   = 12;
    localparam int IW_BXOR_SRC1_HI  = 7;
    localparam int IW_BXOR_SRC1_LO  = 4;
    localparam int IW_BXOR_SRC0_HI  = 3;
    localparam int IW_BXOR_SRC0_LO  = 0;

    // BLOCK_SET — fill a block with a repeated byte (Table 11-11)
    // IW[19:16]=size, IW[15:12]=dst, IW[7:0]=byte
    localparam logic [7:0] OPC_BLOCK_SET = 8'h42;
    localparam int IW_BSET_SIZE_HI  = 19;
    localparam int IW_BSET_SIZE_LO  = 16;
    localparam int IW_BSET_DST_HI   = 15;
    localparam int IW_BSET_DST_LO   = 12;
    localparam int IW_BSET_BYTE_HI  = 7;
    localparam int IW_BSET_BYTE_LO  = 0;

    // BLOCK_CMP — compare two blocks, result in STR_RESULT (Table 11-12)
    // BLOCK_GCM — GCM multiply (Table 11-13) — same opcode, hw selects by AES_CTL.GCM
    // IW[19:16]=size, IW[7:4]=src1, IW[3:0]=src0
    localparam logic [7:0] OPC_BLOCK_CMP_GCM = 8'h43;  // BLOCK_CMP and BLOCK_GCM share opcode
    localparam int IW_BCMP_SIZE_HI  = 19;
    localparam int IW_BCMP_SIZE_LO  = 16;
    localparam int IW_BCMP_SRC1_HI  = 7;
    localparam int IW_BCMP_SRC1_LO  = 4;
    localparam int IW_BCMP_SRC0_HI  = 3;
    localparam int IW_BCMP_SRC0_LO  = 0;

    // ---------------------------------------------------------------
    // Load/store FIFO stream instructions  (Tables 11-1 – 11-3; §11.3.3)
    // FF_START and FF_CONTINUE are 3-word instructions.
    // FF_STOP is a 1-word instruction.
    // ---------------------------------------------------------------
    localparam logic [7:0] OPC_FF_START    = 8'h70;  // 3 words: addr, size
    localparam logic [7:0] OPC_FF_CONTINUE = 8'h71;  // 3 words: addr, size (load FIFOs only)
    localparam logic [7:0] OPC_FF_STOP     = 8'h72;  // 1 word

    // IW0[3:0] = ff_identifier for all three FIFO instructions
    localparam int IW_FF_ID_HI = 3;
    localparam int IW_FF_ID_LO = 0;

    // Word counts
    localparam int WC_FF_START    = 3;
    localparam int WC_FF_CONTINUE = 3;
    localparam int WC_FF_STOP     = 1;

    // ---------------------------------------------------------------
    // VU condition codes  (Table 11-28; IW[23:20])
    // ---------------------------------------------------------------
    typedef enum logic [3:0] {
        CC_ALWAYS   = 4'h0,  // '1' (unconditional)
        CC_EQ       = 4'h1,  // ZERO
        CC_NE       = 4'h2,  // !ZERO
        CC_CS       = 4'h3,  // CARRY (higher or same)
        CC_CC       = 4'h4,  // !CARRY (lower)
        CC_HI       = 4'h5,  // CARRY & !ZERO (higher)
        CC_LS       = 4'h6,  // !CARRY | ZERO  (lower or same)
        CC_EVEN     = 4'h7,  // EVEN
        CC_ODD      = 4'h8,  // !EVEN
        CC_ONE      = 4'h9,  // ONE
        CC_NOT_ONE  = 4'hA   // !ONE
    } vu_cc_e;

    // ---------------------------------------------------------------
    // VU instructions — register-file operands only
    // Standard encoding: IW[31:24]=opcode, IW[23:20]=cc
    // ---------------------------------------------------------------

    // Category: load/store register file to/from memory stack
    // LD_REG (rsrc1, rsrc0): loads a 32-bit word from mem[r15+rsrc0]
    //   into rsrc1. IW[15:12]=rsrc1, IW[3:0]=rsrc0. (Table 11-33)
    localparam logic [7:0] OPC_LD_REG = 8'h00;

    // ST_REG (rsrc1, rsrc0): stores rsrc1 to mem[r15+rsrc0]. (Table 11-34)
    // IW[7:4]=rsrc1, IW[3:0]=rsrc0.
    //
    // MOV_IMM_TO_STATUS (imm4): sets STATUS flags from 4-bit immediate. (Table 11-40)
    // IW[3:0]=imm4; IW[7:4] is absent (assembler writes 0).
    //
    // Both share opcode 0x01 — confirmed by the spec (Tables 11-34 and 11-40).
    // Decoder distinguishes them by IW[7:4]: nonzero → ST_REG, zero → MOV_IMM_TO_STATUS.
    // (r0 as rsrc1 in ST_REG is valid but produces IW[7:4]=0, which is ambiguous;
    //  software convention should avoid using r0 as rsrc1 in ST_REG.)
    localparam logic [7:0] OPC_ST_REG            = 8'h01;
    localparam logic [7:0] OPC_MOV_IMM_TO_STATUS = 8'h01;

    // SET_REG (rdst, imm13_0, imm13_1): set register data and size fields. (Table 11-31)
    // Special encoding: IW[31:30]=2'b10, IW[29:26]=rdst,
    //   IW[25:13]=imm13_1(size-minus-1), IW[12:0]=imm13_0(data).
    // No condition code field. Always executes.
    localparam logic [1:0] OPC_SET_REG_2BIT = 2'b10;  // IW[31:30]

    // MOV_REG (rdst, rsrc): copy data+size from rsrc to rdst. (Table 11-32)
    // IW[15:12]=rdst, IW[3:0]=rsrc.
    localparam logic [7:0] OPC_MOV_REG = 8'h02;

    // SWAP_REG (rsrc1, rsrc0): exchange two registers. (Table 11-35)
    // IW[7:4]=rsrc1, IW[3:0]=rsrc0.
    localparam logic [7:0] OPC_SWAP_REG = 8'h03;

    // MOV_REG_TO_STATUS (rsrc): load STATUS from register data[3:0]. (Table 11-38)
    // IW[3:0]=rsrc.
    localparam logic [7:0] OPC_MOV_REG_TO_STATUS = 8'h04;

    // MOV_STATUS_TO_REG (rdst): save STATUS into register data[3:0]. (Table 11-39)
    // IW[15:12]=rdst.
    localparam logic [7:0] OPC_MOV_STATUS_TO_REG = 8'h05;

    // Arithmetic/logical on register data fields (Table 11-37)
    // IW[15:12]=rdst, IW[7:4]=rsrc1, IW[3:0]=rsrc0 (where applicable).
    localparam logic [7:0] OPC_ADD_REG  = 8'h06;  // rdst.data = rsrc1.data + rsrc0.data
    localparam logic [7:0] OPC_SUB_REG  = 8'h07;  // rdst.data = rsrc1.data - rsrc0.data
    localparam logic [7:0] OPC_OR_REG   = 8'h08;
    localparam logic [7:0] OPC_AND_REG  = 8'h09;
    localparam logic [7:0] OPC_XOR_REG  = 8'h0A;
    localparam logic [7:0] OPC_NOR_REG  = 8'h0B;
    localparam logic [7:0] OPC_NAND_REG = 8'h0C;
    localparam logic [7:0] OPC_MIN_REG  = 8'h0D;
    localparam logic [7:0] OPC_MAX_REG  = 8'h0E;

    // Stack management (Table 11-36; no register operand fields in IW)
    // PUSH_REG: r0–r14 → stack; r15 decremented by 15. IW[23:20]=cc only.
    localparam logic [7:0] OPC_PUSH_REG = 8'h10;
    // POP_REG: stack → r0–r14; r15 incremented by 15.
    localparam logic [7:0] OPC_POP_REG  = 8'h11;

    // Memory allocation (Tables 11-29, 11-30)
    // ALLOC_MEM (rdst, size-1): allocate stack frame. (Table 11-29)
    //   IW[19:16]=rdst, IW[12:0]=imm13 (size in bits, minus 1).
    localparam logic [7:0] OPC_ALLOC_MEM = 8'h12;
    localparam int IW_ALLOC_DST_HI  = 19;
    localparam int IW_ALLOC_DST_LO  = 16;
    localparam int IW_ALLOC_IMM_HI  = 12;
    localparam int IW_ALLOC_IMM_LO  = 0;

    // FREE_MEM (imm16): free stack elements matching bit pattern. (Table 11-30)
    //   IW[15:0]=imm16 (bit 0 = r0, bit 15 = r15).
    localparam logic [7:0] OPC_FREE_MEM  = 8'h13;
    localparam int IW_FREE_IMM_HI   = 15;
    localparam int IW_FREE_IMM_LO   = 0;

    // Carry-aware arithmetic on memory operands (Table 11-50)
    // IW[15:12]=rdst, IW[7:4]=rsrc1, IW[3:0]=rsrc0.
    localparam logic [7:0] OPC_ADD_WITH_CARRY = 8'h14;
    localparam logic [7:0] OPC_SUB_WITH_CARRY = 8'h15;

    // ---------------------------------------------------------------
    // VU instructions — mixed operands (memory buffer + register)
    // ---------------------------------------------------------------

    // Shift instructions — rdst/rsrc1 are memory operands, rsrc0 is register (Table 11-41)
    // IW[15:12]=rdst(mem), IW[7:4]=rsrc1(mem), IW[3:0]=rsrc0(reg).
    localparam logic [7:0] OPC_LSL            = 8'h20;  // logical shift left by rsrc0.data
    localparam logic [7:0] OPC_LSR            = 8'h23;  // logical shift right by rsrc0.data

    // Shift-by-1 — rdst/rsrc are memory operands (Table 11-42)
    // IW[15:12]=rdst(mem), IW[3:0]=rsrc(mem).
    localparam logic [7:0] OPC_LSL1           = 8'h21;  // shift left 1
    localparam logic [7:0] OPC_LSL1_WITH_CARRY= 8'h22;  // shift left 1, insert STATUS.CARRY
    localparam logic [7:0] OPC_LSR1           = 8'h24;  // shift right 1
    localparam logic [7:0] OPC_LSR1_WITH_CARRY= 8'h25;  // shift right 1, insert STATUS.CARRY

    // Leading/trailing same-bit count (Table 11-45)
    // IW[15:12]=rdst(reg, result), IW[7:4]=rsrc1(mem), IW[3:0]=rsrc0(mem).
    localparam logic [7:0] OPC_CLSAME = 8'h26;  // count leading same bits
    localparam logic [7:0] OPC_CTSAME = 8'h27;  // count trailing same bits

    // Single-bit manipulation on memory operand (Table 11-43)
    // IW[15:12]=rdst(mem), IW[3:0]=rsrc(reg, bit index = rsrc.data[12:0]).
    localparam logic [7:0] OPC_SET_BIT = 8'h28;
    localparam logic [7:0] OPC_CLR_BIT = 8'h29;
    localparam logic [7:0] OPC_INV_BIT = 8'h2A;

    // GET_BIT — extract one bit from memory into register (Table 11-44)
    // IW[15:12]=rdst(reg), IW[7:4]=rsrc1(mem), IW[3:0]=rsrc0(reg, bit index).
    localparam logic [7:0] OPC_GET_BIT = 8'h2B;

    // Single-bit manipulation with immediate bit index (Table 11-51)
    // IW[19:16]=rdst(mem), IW[12:0]=imm13 (bit index).
    localparam logic [7:0] OPC_SET_BIT_IMM = 8'h2C;
    localparam logic [7:0] OPC_CLR_BIT_IMM = 8'h2D;
    localparam logic [7:0] OPC_INV_BIT_IMM = 8'h2E;
    localparam int IW_BITIMM_DST_HI = 19;
    localparam int IW_BITIMM_DST_LO = 16;
    localparam int IW_BITIMM_IDX_HI = 12;
    localparam int IW_BITIMM_IDX_LO = 0;

    // Integer squaring (Table 11-47)
    // IW[15:12]=rdst(mem), IW[3:0]=rsrc(mem). dst must not overlap src.
    localparam logic [7:0] OPC_USQUARE = 8'h2F;  // unsigned integer square: dst = src * src
    localparam logic [7:0] OPC_XSQUARE = 8'h31;  // GF(2^m) polynomial square

    // ---------------------------------------------------------------
    // VU instructions — memory buffer operands only  (Table 11-47 onwards)
    // Encoding: IW[31:24]=opcode, IW[23:20]=cc,
    //           IW[15:12]=rdst(mem), IW[7:4]=rsrc1(mem), IW[3:0]=rsrc0(mem)
    //   (or IW[15:12]=rdst/IW[3:0]=rsrc for unary; no dst for compare/test)
    // ---------------------------------------------------------------

    // Data movement
    localparam logic [7:0] OPC_MOV       = 8'h30;  // dst ← src (Table 11-47)

    // Polynomial (GF(2^m)) multiply — dst must not overlap src (Table 11-50)
    localparam logic [7:0] OPC_XMUL      = 8'h32;  // GF(2^m) poly multiply
    localparam logic [7:0] OPC_UMUL      = 8'h33;  // unsigned integer multiply

    // Set/clear to all-ones or all-zeros (Table 11-46)
    localparam logic [7:0] OPC_SET_TO_ZERO = 8'h34;  // dst ← 0
    localparam logic [7:0] OPC_SET_TO_ONE  = 8'h35;  // dst ← 1

    // Arithmetic on large integers (Table 11-50)
    localparam logic [7:0] OPC_ADD  = 8'h36;  // dst ← src1 + src0  (with STATUS.CARRY)
    localparam logic [7:0] OPC_SUB  = 8'h37;  // dst ← src1 - src0  (with STATUS.CARRY)

    // Bitwise logical on large integers (Table 11-50)
    localparam logic [7:0] OPC_VU_OR   = 8'h38;
    localparam logic [7:0] OPC_VU_AND  = 8'h39;
    localparam logic [7:0] OPC_VU_XOR  = 8'h3A;
    localparam logic [7:0] OPC_VU_NOR  = 8'h3B;
    localparam logic [7:0] OPC_VU_NAND = 8'h3C;

    // Compare/test — update STATUS only, no destination write (Table 11-48)
    // IW[7:4]=rsrc1, IW[3:0]=rsrc0.
    localparam logic [7:0] OPC_CMP_SUB    = 8'h3D;  // STATUS ← subtraction flags
    localparam logic [7:0] OPC_CMP_DEGREE = 8'h3E;  // STATUS ← polynomial degree compare

    // TST — inspect memory operand, update STATUS, no destination (Table 11-49)
    // IW[3:0]=rsrc.  STATUS.CARRY always cleared.
    localparam logic [7:0] OPC_TST = 8'h3F;

    // ---------------------------------------------------------------
    // Common IW field positions for VU register-pair categories
    // (Categories IV, V, and mixed memory instructions)
    // ---------------------------------------------------------------
    localparam int IW_DST_HI   = 15;
    localparam int IW_DST_LO   = 12;
    localparam int IW_SRC1_HI  = 7;
    localparam int IW_SRC1_LO  = 4;
    localparam int IW_SRC0_HI  = 3;
    localparam int IW_SRC0_LO  = 0;

    // ---------------------------------------------------------------
    // Instruction word count by opcode group
    // (number of 32-bit words the CPU must write to INSTR_FF_WR)
    // ---------------------------------------------------------------
    localparam int WC_1WORD = 1;  // all instructions except FF_START / FF_CONTINUE
    localparam int WC_3WORD = 3;  // FF_START and FF_CONTINUE only

    // ---------------------------------------------------------------
    // FIFO instruction word offsets (for 3-word FIFO instructions)
    // IW0: opcode + ff_identifier
    // IW1: start address [31:0]
    // IW2: byte count / size [31:0]
    // ---------------------------------------------------------------
    localparam int FIFO_IW_ADDR_WORD = 1;
    localparam int FIFO_IW_SIZE_WORD = 2;

    // ---------------------------------------------------------------
    // VU STATUS register bit positions  (§11.10.5)
    // ---------------------------------------------------------------
    localparam int VU_STATUS_CARRY = 0;
    localparam int VU_STATUS_EVEN  = 1;
    localparam int VU_STATUS_ZERO  = 2;
    localparam int VU_STATUS_ONE   = 3;

    // ---------------------------------------------------------------
    // VU register file conventions  (§11.10.1)
    // r15 is reserved as the stack pointer.
    // r0–r3: leaf-function operands / volatile.
    // r4–r14: non-leaf-function operands / caller-saved.
    // ---------------------------------------------------------------
    localparam int VU_REG_SP  = 15;  // stack pointer
    localparam int VU_NREGS   = 16;  // total register count

    // Maximum memory operand size (13-bit size field → range [1, 8192] bits)
    localparam int VU_MAX_OP_BITS  = 8192;
    localparam int VU_SIZE_FIELD_W = 13;

endpackage
