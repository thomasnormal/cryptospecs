class cryptolite_env extends uvm_env;
    `uvm_component_utils(cryptolite_env)

    ahb_master_agent            ahb_agent;
    irq_agent                   irq_mon_agent;
    cryptolite_scoreboard       scoreboard;
    cryptolite_coverage         coverage;
    cryptolite_virtual_sequencer v_sqr;

    virtual cryptolite_mem_if mem_vif;
    virtual irq_if            irq_vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        ahb_agent     = ahb_master_agent::type_id::create("ahb_agent", this);
        irq_mon_agent = irq_agent::type_id::create("irq_mon_agent", this);
        scoreboard    = cryptolite_scoreboard::type_id::create("scoreboard", this);
        coverage      = cryptolite_coverage::type_id::create("coverage", this);
        v_sqr         = cryptolite_virtual_sequencer::type_id::create("v_sqr", this);

        if (!uvm_config_db#(virtual cryptolite_mem_if)::get(this, "", "mem_vif", mem_vif))
            `uvm_fatal("NOMEMVIF", "cryptolite_mem_if not found in config_db")
        if (!uvm_config_db#(virtual irq_if)::get(this, "", "irq_vif", irq_vif))
            `uvm_fatal("NOIRQVIF", "irq_if not found in config_db")
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        ahb_agent.monitor.analysis_port.connect(scoreboard.ahb_export);
        ahb_agent.monitor.analysis_port.connect(coverage.analysis_export);

        v_sqr.ahb_sqr = ahb_agent.sequencer;
        v_sqr.mem_vif = mem_vif;
        v_sqr.irq_vif = irq_vif;
    endfunction
endclass
