`timescale 1ns/1ps

module cryptolite_tb;
    import uvm_pkg::*;
    import cryptolite_pkg::*;
    import cryptolite_test_pkg::*;

    logic clk;
    logic rst_n;
    logic interrupt_level;

    ahb_if            ahb_vif(.clk(clk), .rst_n(rst_n));
    irq_if            irq_vif(.clk(clk), .rst_n(rst_n));
    cryptolite_mem_if mem_vif(.clk(clk), .rst_n(rst_n));

    cryptolite_top dut (
        .clk             (clk),
        .rst_n           (rst_n),
        .s_hsel          (ahb_vif.hsel),
        .s_haddr         (ahb_vif.haddr),
        .s_htrans        (ahb_vif.htrans),
        .s_hwrite        (ahb_vif.hwrite),
        .s_hsize         (ahb_vif.hsize),
        .s_hwdata        (ahb_vif.hwdata),
        .s_hrdata        (ahb_vif.hrdata),
        .s_hreadyout     (ahb_vif.hreadyout),
        .s_hresp         (ahb_vif.hresp),
        .m_haddr         (mem_vif.haddr),
        .m_htrans        (mem_vif.htrans),
        .m_hwrite        (mem_vif.hwrite),
        .m_hsize         (mem_vif.hsize),
        .m_hwdata        (mem_vif.hwdata),
        .m_hrdata        (mem_vif.hrdata),
        .m_hready        (mem_vif.hready),
        .m_hresp         (mem_vif.hresp),
        .interrupt_level (interrupt_level)
    );

    assign irq_vif.irq = interrupt_level;

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        rst_n = 1'b0;
        ahb_vif.hsel   = 1'b0;
        ahb_vif.haddr  = '0;
        ahb_vif.htrans = HTRANS_IDLE;
        ahb_vif.hwrite = HWRITE_READ;
        ahb_vif.hsize  = HSIZE_WORD;
        ahb_vif.hwdata = '0;
        mem_vif.clear();
        repeat (4) @(posedge clk);
        rst_n = 1'b1;
    end

    initial begin
        uvm_config_db#(virtual ahb_if)::set(null, "*.ahb_agent*", "vif", ahb_vif);
        uvm_config_db#(virtual irq_if)::set(null, "*.irq_mon_agent*", "vif", irq_vif);
        uvm_config_db#(virtual cryptolite_mem_if)::set(null, "*", "mem_vif", mem_vif);
        uvm_config_db#(virtual irq_if)::set(null, "*", "irq_vif", irq_vif);
        uvm_config_db#(uvm_active_passive_enum)::set(null, "*.ahb_agent", "is_active", UVM_ACTIVE);
    end

    initial begin
        #5ms;
        `uvm_fatal("TIMEOUT", "Simulation timeout")
    end

    initial begin
        run_test();
    end

endmodule
