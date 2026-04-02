// ---------------------------------------------------------------------------
// AES Accelerator UVM Environment
// Instantiates agents, RAL infrastructure, scoreboard, coverage, and the
// virtual sequencer.  Wires everything in connect_phase.
// UVM 1.2 methodology.
// ---------------------------------------------------------------------------

class aes_env extends uvm_env;
    `uvm_component_utils(aes_env)

    // Agents
    ahb_master_agent               ahb_agent;
    axi_slave_agent                axi_agent;

    // RAL
    aes_reg_block                  reg_block;
    aes_reg_adapter                reg_adapter;
    uvm_reg_predictor #(ahb_seq_item) reg_predictor;

    // Scoreboard and coverage
    aes_scoreboard                 scoreboard;
    aes_coverage                   coverage;

    // Virtual sequencer
    aes_virtual_sequencer          v_sqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // ---------------------------------------------------------------
    // Build phase
    // ---------------------------------------------------------------
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Agents
        ahb_agent = ahb_master_agent::type_id::create("ahb_agent", this);
        axi_agent = axi_slave_agent::type_id::create("axi_agent", this);

        // RAL register block
        reg_block = aes_reg_block::type_id::create("reg_block");
        reg_block.build();

        // Adapter and predictor
        reg_adapter   = aes_reg_adapter::type_id::create("reg_adapter");
        reg_predictor = uvm_reg_predictor #(ahb_seq_item)::type_id::create("reg_predictor", this);

        // Scoreboard and coverage
        scoreboard = aes_scoreboard::type_id::create("scoreboard", this);
        coverage   = aes_coverage::type_id::create("coverage", this);

        // Virtual sequencer
        v_sqr = aes_virtual_sequencer::type_id::create("v_sqr", this);
    endfunction

    // ---------------------------------------------------------------
    // Connect phase
    // ---------------------------------------------------------------
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // ---- RAL to AHB agent ----
        // Set the sequencer and adapter on the register map so RAL
        // read/write calls are driven through the AHB agent.
        reg_block.default_map.set_sequencer(ahb_agent.sequencer, reg_adapter);
        reg_block.default_map.set_auto_predict(1);

        // Predictor: uses the adapter to translate observed AHB items
        // back into register updates.
        reg_predictor.map     = reg_block.default_map;
        reg_predictor.adapter = reg_adapter;
        ahb_agent.monitor.analysis_port.connect(reg_predictor.bus_in);

        // ---- Scoreboard connections ----
        ahb_agent.monitor.analysis_port.connect(scoreboard.ahb_export);
        axi_agent.monitor.wr_ap.connect(scoreboard.axi_export);
        axi_agent.monitor.rd_ap.connect(scoreboard.axi_rd_export);

        // ---- Coverage connections ----
        ahb_agent.monitor.analysis_port.connect(coverage.analysis_export);

        // ---- Virtual sequencer handles ----
        v_sqr.ahb_sqr   = ahb_agent.sequencer;
        v_sqr.axi_agent = axi_agent;
        v_sqr.mem       = axi_agent.mem;
        v_sqr.reg_block = reg_block;
    endfunction

endclass
