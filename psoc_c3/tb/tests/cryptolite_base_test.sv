class cryptolite_base_test extends uvm_test;
    `uvm_component_utils(cryptolite_base_test)

    cryptolite_env env;

    function new(string name = "cryptolite_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = cryptolite_env::type_id::create("env", this);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

    virtual function uvm_object_wrapper get_seq_type();
        return null;
    endfunction

    virtual task run_phase(uvm_phase phase);
        uvm_sequence_base seq;
        uvm_object obj;
        uvm_object_wrapper seq_type;

        phase.raise_objection(this);
        seq_type = get_seq_type();
        if (seq_type == null)
            `uvm_fatal("NOSEQ", "No sequence type provided by test")
        obj = seq_type.create_object("seq");
        if (!$cast(seq, obj))
            `uvm_fatal("BADSEQ", "Failed to cast created object to uvm_sequence_base")
        seq.start(env.v_sqr);
        phase.drop_objection(this);
    endtask

    virtual function void report_phase(uvm_phase phase);
        uvm_report_server srv;
        srv = uvm_report_server::get_server();
        if ((srv.get_severity_count(UVM_ERROR) > 0) || (srv.get_severity_count(UVM_FATAL) > 0))
            `uvm_info("TEST", "*** TEST FAILED ***", UVM_NONE)
        else
            `uvm_info("TEST", "*** TEST PASSED ***", UVM_NONE)
    endfunction
endclass
