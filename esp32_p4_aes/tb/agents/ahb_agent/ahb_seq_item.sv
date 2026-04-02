// AHB-Lite Sequence Item
// Represents a single AHB read or write transfer.

typedef enum bit {
    AHB_READ  = 1'b0,
    AHB_WRITE = 1'b1
} ahb_op_e;

class ahb_seq_item extends uvm_sequence_item;

    rand bit [31:0] addr;
    rand bit [31:0] wdata;
         bit [31:0] rdata;
    rand ahb_op_e   op;
    rand bit [2:0]  hsize;

    constraint c_hsize_default {
        soft hsize == 3'b010; // WORD
    }

    constraint c_addr_word_aligned {
        addr[1:0] == 2'b00;
    }

    `uvm_object_utils_begin(ahb_seq_item)
        `uvm_field_int(addr,  UVM_ALL_ON)
        `uvm_field_int(wdata, UVM_ALL_ON)
        `uvm_field_int(rdata, UVM_ALL_ON)
        `uvm_field_enum(ahb_op_e, op, UVM_ALL_ON)
        `uvm_field_int(hsize, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "ahb_seq_item");
        super.new(name);
    endfunction

    // ----------------------------------------------------------------
    // do_compare
    // ----------------------------------------------------------------
    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        ahb_seq_item rhs_;
        if (!$cast(rhs_, rhs)) begin
            `uvm_error("do_compare", "cast failed")
            return 0;
        end
        return (super.do_compare(rhs, comparer) &&
                (addr  == rhs_.addr)             &&
                (wdata == rhs_.wdata)            &&
                (rdata == rhs_.rdata)            &&
                (op    == rhs_.op)               &&
                (hsize == rhs_.hsize));
    endfunction

    // ----------------------------------------------------------------
    // do_copy
    // ----------------------------------------------------------------
    function void do_copy(uvm_object rhs);
        ahb_seq_item rhs_;
        if (!$cast(rhs_, rhs))
            `uvm_fatal("do_copy", "cast failed")
        super.do_copy(rhs);
        addr  = rhs_.addr;
        wdata = rhs_.wdata;
        rdata = rhs_.rdata;
        op    = rhs_.op;
        hsize = rhs_.hsize;
    endfunction

    // ----------------------------------------------------------------
    // convert2string
    // ----------------------------------------------------------------
    function string convert2string();
        return $sformatf("op=%s addr=0x%08h wdata=0x%08h rdata=0x%08h hsize=%0d",
                         op.name(), addr, wdata, rdata, hsize);
    endfunction

endclass
