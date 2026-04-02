// ---------------------------------------------------------------------------
// AES Register Adapter
// Converts between uvm_reg_bus_op and ahb_seq_item for the RAL to
// drive/sample AHB-Lite transactions.
// UVM 1.2 methodology.
// ---------------------------------------------------------------------------

class aes_reg_adapter extends uvm_reg_adapter;
    `uvm_object_utils(aes_reg_adapter)

    function new(string name = "aes_reg_adapter");
        super.new(name);

        // AHB is a pipelined bus: address and data travel in the same item,
        // but the item is not returned until the data phase completes.
        supports_byte_enable = 0;
        provides_responses   = 0;
    endfunction

    // ---------------------------------------------------------------
    // reg2bus: convert a RAL operation into an AHB sequence item
    // ---------------------------------------------------------------
    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        ahb_seq_item item = ahb_seq_item::type_id::create("item");

        item.addr  = rw.addr;
        item.wdata = rw.data[31:0];
        item.op    = (rw.kind == UVM_WRITE) ? AHB_WRITE : AHB_READ;
        return item;
    endfunction

    // ---------------------------------------------------------------
    // bus2reg: convert a completed AHB sequence item back to a RAL op
    // ---------------------------------------------------------------
    virtual function void bus2reg(uvm_sequence_item bus_item,
                                  ref uvm_reg_bus_op rw);
        ahb_seq_item item;

        if (!$cast(item, bus_item)) begin
            `uvm_fatal("REG_ADAPTER", "bus2reg cast failed - item is not ahb_seq_item")
            return;
        end

        rw.addr   = item.addr;
        rw.data   = (item.op == AHB_READ) ? item.rdata : item.wdata;
        rw.kind   = (item.op == AHB_WRITE) ? UVM_WRITE : UVM_READ;
        rw.status = UVM_IS_OK;
    endfunction

endclass
