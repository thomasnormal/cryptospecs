class cryptolite_scoreboard extends uvm_component;
    `uvm_component_utils(cryptolite_scoreboard)

    uvm_analysis_imp #(ahb_seq_item, cryptolite_scoreboard) ahb_export;

    int unsigned read_count;
    int unsigned write_count;
    int unsigned reg_access_count[int unsigned];

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ahb_export = new("ahb_export", this);
    endfunction

    function void write(ahb_seq_item txn);
        int unsigned offset;
        if (txn.op == AHB_WRITE)
            write_count++;
        else
            read_count++;

        if (txn.addr[31:12] == CRYPTOLITE_BASE[31:12]) begin
            offset = txn.addr[11:0] & 12'hffc;
            reg_access_count[offset]++;
        end
    endfunction
endclass
