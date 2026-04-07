class cryptolite_aes_ecb_test extends cryptolite_base_test;
    `uvm_component_utils(cryptolite_aes_ecb_test)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    virtual function uvm_object_wrapper get_seq_type(); return cryptolite_aes_ecb_seq::get_type(); endfunction
endclass

class cryptolite_sha256_sch_test extends cryptolite_base_test;
    `uvm_component_utils(cryptolite_sha256_sch_test)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    virtual function uvm_object_wrapper get_seq_type(); return cryptolite_sha256_sch_seq::get_type(); endfunction
endclass

class cryptolite_sha256_proc_test extends cryptolite_base_test;
    `uvm_component_utils(cryptolite_sha256_proc_test)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    virtual function uvm_object_wrapper get_seq_type(); return cryptolite_sha256_proc_seq::get_type(); endfunction
endclass

class cryptolite_sha256_full_test extends cryptolite_base_test;
    `uvm_component_utils(cryptolite_sha256_full_test)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    virtual function uvm_object_wrapper get_seq_type(); return cryptolite_sha256_full_seq::get_type(); endfunction
endclass

class cryptolite_trng_basic_test extends cryptolite_base_test;
    `uvm_component_utils(cryptolite_trng_basic_test)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    virtual function uvm_object_wrapper get_seq_type(); return cryptolite_trng_basic_seq::get_type(); endfunction
endclass

class cryptolite_trng_vn_test extends cryptolite_base_test;
    `uvm_component_utils(cryptolite_trng_vn_test)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    virtual function uvm_object_wrapper get_seq_type(); return cryptolite_trng_vn_seq::get_type(); endfunction
endclass

class cryptolite_trng_rc_test extends cryptolite_base_test;
    `uvm_component_utils(cryptolite_trng_rc_test)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    virtual function uvm_object_wrapper get_seq_type(); return cryptolite_trng_rc_seq::get_type(); endfunction
endclass

class cryptolite_trng_ap_test extends cryptolite_base_test;
    `uvm_component_utils(cryptolite_trng_ap_test)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    virtual function uvm_object_wrapper get_seq_type(); return cryptolite_trng_ap_seq::get_type(); endfunction
endclass

class cryptolite_vu_add_test extends cryptolite_base_test;
    `uvm_component_utils(cryptolite_vu_add_test)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    virtual function uvm_object_wrapper get_seq_type(); return cryptolite_vu_add_seq::get_type(); endfunction
endclass

class cryptolite_vu_mul_test extends cryptolite_base_test;
    `uvm_component_utils(cryptolite_vu_mul_test)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    virtual function uvm_object_wrapper get_seq_type(); return cryptolite_vu_mul_seq::get_type(); endfunction
endclass

class cryptolite_intr_test extends cryptolite_base_test;
    `uvm_component_utils(cryptolite_intr_test)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    virtual function uvm_object_wrapper get_seq_type(); return cryptolite_intr_seq::get_type(); endfunction
endclass

class cryptolite_busy_block_test extends cryptolite_base_test;
    `uvm_component_utils(cryptolite_busy_block_test)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    virtual function uvm_object_wrapper get_seq_type(); return cryptolite_busy_block_seq::get_type(); endfunction
endclass
