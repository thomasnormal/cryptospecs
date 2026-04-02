// ---------------------------------------------------------------------------
// AES Functional Coverage Collector
// Monitors AHB write stream to latch register values, then samples
// covergroups when relevant trigger events occur.
// UVM 1.2 methodology.
// ---------------------------------------------------------------------------

class aes_coverage extends uvm_subscriber #(ahb_seq_item);
    `uvm_component_utils(aes_coverage)

    // -----------------------------------------------------------------
    // Register address map (offsets used on the AHB bus)
    // -----------------------------------------------------------------
    localparam bit [31:0] ADDR_MODE          = 32'h040;
    localparam bit [31:0] ADDR_TRIGGER       = 32'h048;
    localparam bit [31:0] ADDR_IV0           = 32'h050;
    localparam bit [31:0] ADDR_DMA_ENABLE    = 32'h090;
    localparam bit [31:0] ADDR_BLOCK_MODE    = 32'h094;
    localparam bit [31:0] ADDR_BLOCK_NUM     = 32'h098;
    localparam bit [31:0] ADDR_INT_ENA       = 32'h0B0;

    // -----------------------------------------------------------------
    // Latched register values (updated on every matching AHB write)
    // -----------------------------------------------------------------
    bit [31:0] last_mode;
    bit [31:0] last_dma_enable;
    bit [31:0] last_block_mode;
    bit [31:0] last_block_num;
    bit [31:0] last_int_ena;

    // -----------------------------------------------------------------
    // Convenience signals derived from latched registers
    // -----------------------------------------------------------------
    bit        key_len;       // MODE[1]:   0 = AES-128, 1 = AES-256
    bit        direction;     // MODE[2]:   0 = encrypt, 1 = decrypt
    bit        work_mode;     // DMA_ENABLE[0]: 0 = typical, 1 = DMA
    bit [2:0]  block_mode;    // BLOCK_MODE[2:0]
    bit [31:0] block_num;     // BLOCK_NUM full value
    bit        int_ena;       // INT_ENA last written value (bit 0)

    // Fields for cg_ahb_access sampling
    bit [31:0] cov_addr;
    bit        cov_write;

    // =================================================================
    // Covergroup 1: AES operation -- sampled on TRIGGER write
    // =================================================================
    covergroup cg_aes_operation;
        option.per_instance = 1;
        option.name         = "cg_aes_operation";

        cp_key_len : coverpoint key_len {
            bins aes128 = {0};
            bins aes256 = {1};
        }

        cp_direction : coverpoint direction {
            bins encrypt = {0};
            bins decrypt = {1};
        }

        cp_work_mode : coverpoint work_mode {
            bins typical = {0};
            bins dma     = {1};
        }

        cp_block_mode : coverpoint block_mode {
            bins ecb    = {3'd0};
            bins cbc    = {3'd1};
            bins ofb    = {3'd2};
            bins ctr    = {3'd3};
            bins cfb8   = {3'd4};
            bins cfb128 = {3'd5};
            bins gcm    = {3'd6};
        }

        cx_mode_cross : cross cp_key_len, cp_direction, cp_block_mode, cp_work_mode {
            // In typical (non-DMA) mode only ECB is valid; ignore all
            // other block modes when work_mode is typical.
            ignore_bins typical_non_ecb =
                binsof(cp_work_mode.typical) && !binsof(cp_block_mode.ecb);
        }
    endgroup

    // =================================================================
    // Covergroup 2: Block count -- sampled on BLOCK_NUM write
    // =================================================================
    covergroup cg_block_count;
        option.per_instance = 1;
        option.name         = "cg_block_count";

        cp_block_num : coverpoint block_num {
            bins cnt_one        = {1};
            bins cnt_small      = {[2:4]};
            bins cnt_medium     = {[5:16]};
            bins cnt_large      = {[17:64]};
            bins cnt_very_large = {[65:1024]};
        }
    endgroup

    // =================================================================
    // Covergroup 3: Interrupt enable -- sampled on TRIGGER write
    // =================================================================
    covergroup cg_interrupt;
        option.per_instance = 1;
        option.name         = "cg_interrupt";

        cp_int_ena : coverpoint int_ena {
            bins disabled = {0};
            bins enabled  = {1};
        }
    endgroup

    // =================================================================
    // Covergroup 4: AHB access -- sampled on every transaction
    // =================================================================
    covergroup cg_ahb_access;
        option.per_instance = 1;
        option.name         = "cg_ahb_access";

        cp_addr : coverpoint cov_addr {
            bins key_regs[]      = {[32'h000:32'h01C]};
            bins text_in_regs[]  = {[32'h020:32'h02C]};
            bins text_out_regs[] = {[32'h030:32'h03C]};
            bins mode_reg        = {32'h040};
            bins trigger_reg     = {32'h048};
            bins state_reg       = {32'h04C};
            bins iv_regs[]       = {[32'h050:32'h05C]};
            bins h_regs[]        = {[32'h060:32'h06C]};
            bins j0_regs[]       = {[32'h070:32'h07C]};
            bins t0_regs[]       = {[32'h080:32'h08C]};
            bins dma_enable      = {32'h090};
            bins block_mode      = {32'h094};
            bins block_num       = {32'h098};
            bins inc_sel         = {32'h09C};
            bins aad_block_num   = {32'h0A0};
            bins rem_bit_num     = {32'h0A4};
            bins continue_op     = {32'h0A8};
            bins int_clr         = {32'h0AC};
            bins int_ena         = {32'h0B0};
            bins dma_exit        = {32'h0B8};
            bins dma_src_addr    = {32'h0BC};
            bins dma_dst_addr    = {32'h0C0};
        }

        cp_direction : coverpoint cov_write {
            bins read  = {1'b0};
            bins write = {1'b1};
        }

        cx_addr_x_dir : cross cp_addr, cp_direction;
    endgroup

    // =================================================================
    // Constructor
    // =================================================================
    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_aes_operation = new();
        cg_block_count   = new();
        cg_interrupt     = new();
        cg_ahb_access    = new();
    endfunction

    // =================================================================
    // write() -- called by the analysis port on each AHB transaction
    // =================================================================
    virtual function void write(ahb_seq_item t);

        // -- Always sample AHB access coverage --------------------------
        cov_addr  = t.addr;
        cov_write = (t.op == AHB_WRITE);
        cg_ahb_access.sample();

        // -- Latch register values on writes ----------------------------
        if (t.op == AHB_WRITE) begin
            case (t.addr)
                ADDR_MODE:       last_mode       = t.wdata;
                ADDR_DMA_ENABLE: last_dma_enable = t.wdata;
                ADDR_BLOCK_MODE: last_block_mode = t.wdata;
                ADDR_BLOCK_NUM: begin
                    last_block_num = t.wdata;
                    // Update convenience signal and sample block count
                    block_num = t.wdata;
                    cg_block_count.sample();
                end
                ADDR_INT_ENA:    last_int_ena    = t.wdata;
                default: ;
            endcase
        end

        // -- Sample operation covergroups on TRIGGER write ---------------
        if (t.op == AHB_WRITE && t.addr == ADDR_TRIGGER) begin
            // Refresh convenience signals from latched register values
            key_len    = last_mode[1];
            direction  = last_mode[2];
            work_mode  = last_dma_enable[0];
            block_mode = last_block_mode[2:0];
            int_ena    = last_int_ena[0];

            cg_aes_operation.sample();
            cg_interrupt.sample();
        end

    endfunction

endclass
