class cryptolite_coverage extends uvm_component;
    `uvm_component_utils(cryptolite_coverage)

    uvm_analysis_imp #(ahb_seq_item, cryptolite_coverage) analysis_export;

    bit [11:0] cov_offset;
    bit        cov_write;

    covergroup ahb_cg;
        option.per_instance = 1;
        cp_offset: coverpoint cov_offset {
            bins ctl_regs[]  = {CTL, STATUS, AES_DESCR, VU_DESCR, SHA_DESCR};
            bins err_regs[]  = {INTR_ERROR, INTR_ERROR_SET, INTR_ERROR_MASK, INTR_ERROR_MASKED};
            bins trng_regs[] = {TRNG_CTL0, TRNG_CTL1, TRNG_STATUS, TRNG_RESULT,
                                TRNG_GARO_CTL, TRNG_FIRO_CTL,
                                TRNG_MON_CTL, TRNG_MON_RC_CTL,
                                TRNG_MON_AP_CTL, INTR_TRNG, INTR_TRNG_MASK};
        }
        cp_write: coverpoint cov_write;
        cx_rw_offset: cross cp_offset, cp_write;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ahb_cg = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_export = new("analysis_export", this);
    endfunction

    function void write(ahb_seq_item txn);
        if (txn.addr[31:12] == CRYPTOLITE_BASE[31:12]) begin
            cov_offset = txn.addr[11:0] & 12'hffc;
            cov_write  = (txn.op == AHB_WRITE);
            ahb_cg.sample();
        end
    endfunction
endclass
