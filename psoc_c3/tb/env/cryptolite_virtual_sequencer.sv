class cryptolite_virtual_sequencer extends uvm_sequencer;
    `uvm_component_utils(cryptolite_virtual_sequencer)

    ahb_master_sequencer      ahb_sqr;
    virtual cryptolite_mem_if mem_vif;
    virtual irq_if            irq_vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass
