// AES Register Smoke Sequence
// Writes walking-1 pattern to all R/W registers, reads back, and verifies.
// Verifies RO registers are readable without error.
// Verifies write-trigger registers read back as 0.

class aes_reg_smoke_seq extends aes_base_seq;
    `uvm_object_utils(aes_reg_smoke_seq)

    int err_count;

    function new(string name = "aes_reg_smoke_seq");
        super.new(name);
        err_count = 0;
    endfunction

    // ---------------------------------------------------------------
    // Helper: write walking-1 to a single R/W register and verify
    // ---------------------------------------------------------------
    virtual task walk1_check_reg(uvm_reg r, int unsigned field_width);
        uvm_reg_data_t wr_val, rd_val, mask;

        mask = (field_width >= 32) ? 32'hFFFF_FFFF : ((1 << field_width) - 1);

        for (int i = 0; i < field_width; i++) begin
            wr_val = (32'h1 << i) & mask;
            write_reg(r, wr_val);
            read_reg(r, rd_val);
            if ((rd_val & mask) !== wr_val) begin
                `uvm_error("REG_SMOKE",
                    $sformatf("%s walking-1 bit %0d: wrote 0x%08h, read 0x%08h (mask 0x%08h)",
                              r.get_name(), i, wr_val, rd_val & mask, mask))
                err_count++;
            end else begin
                `uvm_info("REG_SMOKE",
                    $sformatf("%s walking-1 bit %0d OK: 0x%08h",
                              r.get_name(), i, rd_val & mask), UVM_HIGH)
            end
        end

        // Restore to 0
        write_reg(r, 32'h0);
    endtask

    // ---------------------------------------------------------------
    // Helper: verify RO register is readable without error
    // ---------------------------------------------------------------
    virtual task check_ro_reg(uvm_reg r);
        uvm_reg_data_t rd_val;
        `uvm_info("REG_SMOKE",
            $sformatf("Reading RO register %s", r.get_name()), UVM_MEDIUM)
        read_reg(r, rd_val);
        `uvm_info("REG_SMOKE",
            $sformatf("%s read value: 0x%08h", r.get_name(), rd_val), UVM_MEDIUM)
    endtask

    // ---------------------------------------------------------------
    // Helper: verify write-trigger register reads back as 0
    // ---------------------------------------------------------------
    virtual task check_wt_reg(uvm_reg r);
        uvm_reg_data_t rd_val;
        `uvm_info("REG_SMOKE",
            $sformatf("Checking WT register %s reads as 0", r.get_name()), UVM_MEDIUM)
        read_reg(r, rd_val);
        if (rd_val !== 32'h0) begin
            `uvm_error("REG_SMOKE",
                $sformatf("%s expected read-back 0x0, got 0x%08h", r.get_name(), rd_val))
            err_count++;
        end else begin
            `uvm_info("REG_SMOKE",
                $sformatf("%s read-back 0 OK", r.get_name()), UVM_MEDIUM)
        end
    endtask

    virtual task body();
        super.pre_body();

        `uvm_info("REG_SMOKE", "Starting register smoke test", UVM_LOW)
        err_count = 0;

        // ---- R/W array registers: key[8], text_in[4], iv[4], j0[4] ----
        `uvm_info("REG_SMOKE", "Testing KEY registers (R/W, 32-bit)", UVM_LOW)
        foreach (reg_model.key[i])
            walk1_check_reg(reg_model.key[i], 32);

        `uvm_info("REG_SMOKE", "Testing TEXT_IN registers (R/W, 32-bit)", UVM_LOW)
        foreach (reg_model.text_in[i])
            walk1_check_reg(reg_model.text_in[i], 32);

        `uvm_info("REG_SMOKE", "Testing IV registers (R/W, 32-bit)", UVM_LOW)
        foreach (reg_model.iv[i])
            walk1_check_reg(reg_model.iv[i], 32);

        `uvm_info("REG_SMOKE", "Testing J0 registers (R/W, 32-bit)", UVM_LOW)
        foreach (reg_model.j0[i])
            walk1_check_reg(reg_model.j0[i], 32);

        // ---- R/W scalar registers ----
        `uvm_info("REG_SMOKE", "Testing MODE register (R/W, 3-bit)", UVM_LOW)
        walk1_check_reg(reg_model.mode, 3);

        `uvm_info("REG_SMOKE", "Testing DMA_ENABLE register (R/W, 1-bit)", UVM_LOW)
        walk1_check_reg(reg_model.dma_enable, 1);

        `uvm_info("REG_SMOKE", "Testing BLOCK_MODE register (R/W, 3-bit)", UVM_LOW)
        walk1_check_reg(reg_model.block_mode, 3);

        `uvm_info("REG_SMOKE", "Testing BLOCK_NUM register (R/W, 32-bit)", UVM_LOW)
        walk1_check_reg(reg_model.block_num, 32);

        `uvm_info("REG_SMOKE", "Testing INC_SEL register (R/W, 1-bit)", UVM_LOW)
        walk1_check_reg(reg_model.inc_sel, 1);

        `uvm_info("REG_SMOKE", "Testing AAD_BLOCK_NUM register (R/W, 32-bit)", UVM_LOW)
        walk1_check_reg(reg_model.aad_block_num, 32);

        `uvm_info("REG_SMOKE", "Testing REMAINDER_BIT_NUM register (R/W, 7-bit)", UVM_LOW)
        walk1_check_reg(reg_model.remainder_bit_num, 7);

        `uvm_info("REG_SMOKE", "Testing INT_ENA register (R/W, 1-bit)", UVM_LOW)
        walk1_check_reg(reg_model.int_ena, 1);

        `uvm_info("REG_SMOKE", "Testing DMA_SRC_ADDR register (R/W, 32-bit)", UVM_LOW)
        walk1_check_reg(reg_model.dma_src_addr, 32);

        `uvm_info("REG_SMOKE", "Testing DMA_DST_ADDR register (R/W, 32-bit)", UVM_LOW)
        walk1_check_reg(reg_model.dma_dst_addr, 32);

        // ---- RO registers: text_out[4], state, h[4], t0[4] ----
        `uvm_info("REG_SMOKE", "Checking TEXT_OUT registers (RO)", UVM_LOW)
        foreach (reg_model.text_out[i])
            check_ro_reg(reg_model.text_out[i]);

        `uvm_info("REG_SMOKE", "Checking STATE register (RO)", UVM_LOW)
        check_ro_reg(reg_model.state);

        `uvm_info("REG_SMOKE", "Checking H registers (RO)", UVM_LOW)
        foreach (reg_model.h[i])
            check_ro_reg(reg_model.h[i]);

        `uvm_info("REG_SMOKE", "Checking T0 registers (RO)", UVM_LOW)
        foreach (reg_model.t0[i])
            check_ro_reg(reg_model.t0[i]);

        // ---- WT registers: trigger reads back as 0 (W1C) ----
        `uvm_info("REG_SMOKE", "Checking TRIGGER register (W1C, expect read 0)", UVM_LOW)
        check_wt_reg(reg_model.trigger);

        // ---- Summary ----
        if (err_count == 0)
            `uvm_info("REG_SMOKE", "Register smoke test PASSED - all checks OK", UVM_LOW)
        else
            `uvm_error("REG_SMOKE",
                $sformatf("Register smoke test FAILED - %0d error(s)", err_count))

    endtask

endclass
