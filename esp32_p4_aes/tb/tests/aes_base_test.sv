// AES Base Test
// Builds the UVM environment and provides common configuration.

class aes_base_test extends uvm_test;
    `uvm_component_utils(aes_base_test)

    aes_env env;

    function new(string name = "aes_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = aes_env::type_id::create("env", this);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        // Wait for reset
        #200;
        phase.drop_objection(this);
    endtask

    virtual function void report_phase(uvm_phase phase);
        uvm_report_server srv = uvm_report_server::get_server();
        if (srv.get_severity_count(UVM_ERROR) > 0 || srv.get_severity_count(UVM_FATAL) > 0)
            `uvm_info("TEST", "*** TEST FAILED ***", UVM_NONE)
        else
            `uvm_info("TEST", "*** TEST PASSED ***", UVM_NONE)
    endfunction

endclass
