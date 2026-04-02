// AES Accelerator Testbench Top
// Instantiates DUT, interfaces, clock/reset, and connects everything

`timescale 1ns/1ps

module tb_top;

    import uvm_pkg::*;
    import aes_env_pkg::*;
    import aes_test_pkg::*;

    // Clock and reset
    logic clk;
    logic rst_n;

    // Clock generation: 100 MHz
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        rst_n = 1'b0;
        #100;
        rst_n = 1'b1;
    end

    // AHB-Lite interface
    ahb_if ahb_if_inst (.clk(clk), .rst_n(rst_n));

    // AXI4 interface
    axi_if axi_if_inst (.clk(clk), .rst_n(rst_n));

    // Interrupt wire
    logic irq;

    // DUT instantiation
    aes_accel_top u_dut (
        .clk        (clk),
        .rst_n      (rst_n),

        // AHB-Lite Slave
        .hsel       (ahb_if_inst.hsel),
        .haddr      ({20'h0, ahb_if_inst.haddr[11:0]}),
        .htrans     (ahb_if_inst.htrans),
        .hwrite     (ahb_if_inst.hwrite),
        .hsize      (ahb_if_inst.hsize),
        .hwdata     (ahb_if_inst.hwdata),
        .hrdata     (ahb_if_inst.hrdata),
        .hreadyout  (ahb_if_inst.hreadyout),
        .hresp      (ahb_if_inst.hresp),

        // AXI4 Master
        .awid       (axi_if_inst.awid),
        .awaddr     (axi_if_inst.awaddr),
        .awlen      (axi_if_inst.awlen),
        .awsize     (axi_if_inst.awsize),
        .awburst    (axi_if_inst.awburst),
        .awvalid    (axi_if_inst.awvalid),
        .awready    (axi_if_inst.awready),
        .wdata      (axi_if_inst.wdata),
        .wstrb      (axi_if_inst.wstrb),
        .wlast      (axi_if_inst.wlast),
        .wvalid     (axi_if_inst.wvalid),
        .wready     (axi_if_inst.wready),
        .bid        (axi_if_inst.bid),
        .bresp      (axi_if_inst.bresp),
        .bvalid     (axi_if_inst.bvalid),
        .bready     (axi_if_inst.bready),
        .arid       (axi_if_inst.arid),
        .araddr     (axi_if_inst.araddr),
        .arlen      (axi_if_inst.arlen),
        .arsize     (axi_if_inst.arsize),
        .arburst    (axi_if_inst.arburst),
        .arvalid    (axi_if_inst.arvalid),
        .arready    (axi_if_inst.arready),
        .rid        (axi_if_inst.rid),
        .rdata      (axi_if_inst.rdata),
        .rresp      (axi_if_inst.rresp),
        .rlast      (axi_if_inst.rlast),
        .rvalid     (axi_if_inst.rvalid),
        .rready     (axi_if_inst.rready),

        .irq        (irq)
    );

    // Pass interfaces to UVM config DB
    initial begin
        uvm_config_db#(virtual ahb_if)::set(null, "*.ahb_agent*", "vif", ahb_if_inst);
        uvm_config_db#(virtual axi_if.SLAVE_DRV)::set(null, "*.axi_agent*.driver*", "vif", axi_if_inst.SLAVE_DRV);
        uvm_config_db#(virtual axi_if.MONITOR)::set(null, "*.axi_agent*.monitor*", "vif", axi_if_inst.MONITOR);
    end

    // Timeout
    initial begin
        #10_000_000;  // 10ms timeout
        `uvm_fatal("TIMEOUT", "Simulation timed out")
    end

    // SVA: AHB protocol checker (direct instantiation)
    ahb_protocol_checker u_ahb_proto_check (
        .clk       (clk),
        .rst_n     (rst_n),
        .hsel      (ahb_if_inst.hsel),
        .haddr     (ahb_if_inst.haddr),
        .htrans    (ahb_if_inst.htrans),
        .hwrite    (ahb_if_inst.hwrite),
        .hsize     (ahb_if_inst.hsize),
        .hwdata    (ahb_if_inst.hwdata),
        .hrdata    (ahb_if_inst.hrdata),
        .hreadyout (ahb_if_inst.hreadyout),
        .hresp     (ahb_if_inst.hresp)
    );

    // SVA bind: AES internal state machine checker on the DUT
    bind aes_accel_top aes_internal_sva u_aes_int_sva (
        .clk           (clk),
        .rst_n         (rst_n),
        .typ_state     (typ_state_q),
        .trigger_start (trigger_start),
        .dma_enable    (reg_dma_enable),
        .core_done     (core_done),
        .core_busy     (core_busy),
        .irq           (irq),
        .int_ena       (u_ahb_slave.int_ena),
        .irq_pending   (u_ahb_slave.irq_pending_q),
        .reg_key       (reg_key),
        .reg_mode      (reg_mode)
    );

    // Start UVM
    initial begin
        run_test();
    end

    // Waveform dump
    initial begin
        if ($test$plusargs("DUMP_WAVES")) begin
            $dumpfile("waves.vcd");
            $dumpvars(0, tb_top);
        end
    end

endmodule
