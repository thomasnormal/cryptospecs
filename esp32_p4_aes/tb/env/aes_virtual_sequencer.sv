// ---------------------------------------------------------------------------
// AES Virtual Sequencer
// Holds handles to sub-sequencers and the register block so that
// virtual sequences can coordinate AHB register accesses, AXI memory
// operations, and RAL-level stimulus.
// UVM 1.2 methodology.
// ---------------------------------------------------------------------------

class aes_virtual_sequencer extends uvm_sequencer;
    `uvm_component_utils(aes_virtual_sequencer)

    // Handle to the AHB master sequencer (register path)
    ahb_master_sequencer ahb_sqr;

    // Handle to the AXI slave agent (set by env)
    axi_slave_agent axi_agent;

    // Handle to the AXI memory model (convenience)
    axi_mem_model mem;

    // Handle to the register block (for RAL-based sequences)
    aes_reg_block  reg_block;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass
