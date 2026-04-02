// AXI4 Reactive Slave Driver
// Responds to AXI master requests from the DUT without a sequencer.
// Monitors the virtual interface for AR/AW/W channel activity and
// produces R/B channel responses using the shared memory model.

class axi_slave_driver extends uvm_driver;

    `uvm_component_utils(axi_slave_driver)

    // ---------------------------------------------------------------
    // Virtual interface and memory model handles
    // ---------------------------------------------------------------
    virtual axi_if.SLAVE_DRV vif;
    axi_mem_model             mem;

    // ---------------------------------------------------------------
    // Configuration
    // ---------------------------------------------------------------
    int unsigned max_resp_delay = 3;  // Max random response delay in cycles

    // ---------------------------------------------------------------
    // Constructor
    // ---------------------------------------------------------------
    function new(string name = "axi_slave_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    // ---------------------------------------------------------------
    // Build Phase
    // ---------------------------------------------------------------
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_if.SLAVE_DRV)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "Virtual interface not found in config_db for axi_slave_driver")
    endfunction : build_phase

    // ---------------------------------------------------------------
    // Run Phase - Launch read and write responders in parallel
    // ---------------------------------------------------------------
    virtual task run_phase(uvm_phase phase);
        // Initialize all slave-driven outputs to idle
        init_signals();

        // Wait for reset de-assertion
        @(posedge vif.clk);
        wait (vif.rst_n === 1'b1);
        @(posedge vif.clk);

        fork
            read_responder();
            write_responder();
        join
    endtask : run_phase

    // ---------------------------------------------------------------
    // Initialize all slave-driven signals
    // ---------------------------------------------------------------
    virtual task init_signals();
        vif.slave_drv_cb.awready <= 1'b0;
        vif.slave_drv_cb.wready  <= 1'b0;
        vif.slave_drv_cb.bvalid  <= 1'b0;
        vif.slave_drv_cb.bid     <= 4'h0;
        vif.slave_drv_cb.bresp   <= 2'b00;
        vif.slave_drv_cb.arready <= 1'b0;
        vif.slave_drv_cb.rvalid  <= 1'b0;
        vif.slave_drv_cb.rid     <= 4'h0;
        vif.slave_drv_cb.rdata   <= 32'h0;
        vif.slave_drv_cb.rresp   <= 2'b00;
        vif.slave_drv_cb.rlast   <= 1'b0;
    endtask : init_signals

    // ---------------------------------------------------------------
    // Read Responder
    // Waits for AR channel handshake, then returns data on R channel
    // ---------------------------------------------------------------
    virtual task read_responder();
        bit [3:0]  ar_id;
        bit [31:0] ar_addr;
        bit [7:0]  ar_len;
        bit [2:0]  ar_size;
        bit [1:0]  ar_burst;
        int        delay;

        forever begin
            // Wait for arvalid
            while (vif.slave_drv_cb.arvalid !== 1'b1)
                @(vif.slave_drv_cb);

            // Optional delay before accepting address
            delay = $urandom_range(0, max_resp_delay);
            repeat (delay) @(vif.slave_drv_cb);

            // Accept address
            vif.slave_drv_cb.arready <= 1'b1;
            @(vif.slave_drv_cb);

            // Capture address phase info (sampled at the posedge where handshake occurs)
            ar_id    = vif.slave_drv_cb.arid;
            ar_addr  = vif.slave_drv_cb.araddr;
            ar_len   = vif.slave_drv_cb.arlen;
            ar_size  = vif.slave_drv_cb.arsize;
            ar_burst = vif.slave_drv_cb.arburst;

            vif.slave_drv_cb.arready <= 1'b0;

            `uvm_info("AXI_SLV_DRV", $sformatf(
                "Read request: addr=0x%08h len=%0d size=%0d burst=%0d id=%0d",
                ar_addr, ar_len, ar_size, ar_burst, ar_id), UVM_HIGH)

            // Send read data beats
            send_read_data(ar_id, ar_addr, ar_len, ar_size, ar_burst);
        end
    endtask : read_responder

    // ---------------------------------------------------------------
    // Send Read Data - Drive R channel for each beat of the burst
    // ---------------------------------------------------------------
    virtual task send_read_data(
        bit [3:0]  id,
        bit [31:0] start_addr,
        bit [7:0]  len,
        bit [2:0]  size,
        bit [1:0]  burst
    );
        bit [31:0] addr;
        bit [31:0] data;
        int        num_beats;
        int        delay;
        int        byte_size;

        num_beats = len + 1;
        byte_size = 2 ** size;
        addr      = start_addr;

        for (int beat = 0; beat < num_beats; beat++) begin
            // De-assert rvalid before delay to prevent premature acceptance
            // (if delay=0 and rvalid was already 1, the subsequent rvalid<=1
            //  at the same time step will win, so no glitch occurs)
            vif.slave_drv_cb.rvalid <= 1'b0;

            // Optional delay before each data beat
            delay = $urandom_range(0, max_resp_delay);
            repeat (delay) @(vif.slave_drv_cb);

            // Read data from memory model
            data = mem.read_word(addr);

            // Drive R channel
            vif.slave_drv_cb.rid   <= id;
            vif.slave_drv_cb.rdata <= data;
            vif.slave_drv_cb.rresp <= 2'b00;  // OKAY
            vif.slave_drv_cb.rlast <= (beat == num_beats - 1) ? 1'b1 : 1'b0;
            vif.slave_drv_cb.rvalid <= 1'b1;

            // Wait for rready handshake
            @(vif.slave_drv_cb);
            while (vif.slave_drv_cb.rready !== 1'b1)
                @(vif.slave_drv_cb);

            `uvm_info("AXI_SLV_DRV", $sformatf(
                "Read data beat[%0d]: addr=0x%08h data=0x%08h%s",
                beat, addr, data, (beat == num_beats - 1) ? " LAST" : ""), UVM_HIGH)

            // Compute next address based on burst type
            addr = compute_next_addr(addr, start_addr, byte_size, burst, len);
        end

        // De-assert R channel
        vif.slave_drv_cb.rvalid <= 1'b0;
        vif.slave_drv_cb.rlast  <= 1'b0;
    endtask : send_read_data

    // ---------------------------------------------------------------
    // Write Responder
    // Accepts AW + W channels, writes to memory, returns B response
    // ---------------------------------------------------------------
    virtual task write_responder();
        bit [3:0]  aw_id;
        bit [31:0] aw_addr;
        bit [7:0]  aw_len;
        bit [2:0]  aw_size;
        bit [1:0]  aw_burst;
        int        delay;

        forever begin
            // Wait for awvalid
            while (vif.slave_drv_cb.awvalid !== 1'b1)
                @(vif.slave_drv_cb);

            // Optional delay before accepting address
            delay = $urandom_range(0, max_resp_delay);
            repeat (delay) @(vif.slave_drv_cb);

            // Accept write address
            vif.slave_drv_cb.awready <= 1'b1;
            @(vif.slave_drv_cb);

            // Capture address phase info
            aw_id    = vif.slave_drv_cb.awid;
            aw_addr  = vif.slave_drv_cb.awaddr;
            aw_len   = vif.slave_drv_cb.awlen;
            aw_size  = vif.slave_drv_cb.awsize;
            aw_burst = vif.slave_drv_cb.awburst;

            vif.slave_drv_cb.awready <= 1'b0;

            `uvm_info("AXI_SLV_DRV", $sformatf(
                "Write request: addr=0x%08h len=%0d size=%0d burst=%0d id=%0d",
                aw_addr, aw_len, aw_size, aw_burst, aw_id), UVM_HIGH)

            // Accept write data beats
            accept_write_data(aw_id, aw_addr, aw_len, aw_size, aw_burst);

            // Send write response
            send_write_response(aw_id);
        end
    endtask : write_responder

    // ---------------------------------------------------------------
    // Accept Write Data - Accept W channel beats and write to memory
    // ---------------------------------------------------------------
    virtual task accept_write_data(
        bit [3:0]  id,
        bit [31:0] start_addr,
        bit [7:0]  len,
        bit [2:0]  size,
        bit [1:0]  burst
    );
        bit [31:0] addr;
        bit [31:0] data;
        bit [3:0]  strb;
        int        num_beats;
        int        delay;
        int        byte_size;
        bit        last;

        num_beats = len + 1;
        byte_size = 2 ** size;
        addr      = start_addr;

        for (int beat = 0; beat < num_beats; beat++) begin
            // De-assert wready before delay to prevent accepting extra beats
            vif.slave_drv_cb.wready <= 1'b0;

            // Optional delay before accepting each data beat
            delay = $urandom_range(0, max_resp_delay);
            repeat (delay) @(vif.slave_drv_cb);

            // Assert wready
            vif.slave_drv_cb.wready <= 1'b1;

            // Wait for wvalid handshake
            @(vif.slave_drv_cb);
            while (vif.slave_drv_cb.wvalid !== 1'b1)
                @(vif.slave_drv_cb);

            // Capture write data
            data = vif.slave_drv_cb.wdata;
            strb = vif.slave_drv_cb.wstrb;
            last = vif.slave_drv_cb.wlast;

            // Write to memory model with byte strobes
            mem.write_word_strobed(addr, data, strb);

            `uvm_info("AXI_SLV_DRV", $sformatf(
                "Write data beat[%0d]: addr=0x%08h data=0x%08h strb=0x%h%s",
                beat, addr, data, strb, last ? " LAST" : ""), UVM_HIGH)

            // Compute next address based on burst type
            addr = compute_next_addr(addr, start_addr, byte_size, burst, len);
        end

        // De-assert wready
        vif.slave_drv_cb.wready <= 1'b0;
    endtask : accept_write_data

    // ---------------------------------------------------------------
    // Send Write Response on B channel
    // ---------------------------------------------------------------
    virtual task send_write_response(bit [3:0] id);
        int delay;

        // Optional delay before response
        delay = $urandom_range(0, max_resp_delay);
        repeat (delay) @(vif.slave_drv_cb);

        // Drive B channel
        vif.slave_drv_cb.bid    <= id;
        vif.slave_drv_cb.bresp  <= 2'b00;  // OKAY
        vif.slave_drv_cb.bvalid <= 1'b1;

        // Wait for bready handshake
        @(vif.slave_drv_cb);
        while (vif.slave_drv_cb.bready !== 1'b1)
            @(vif.slave_drv_cb);

        `uvm_info("AXI_SLV_DRV", $sformatf(
            "Write response: id=%0d resp=OKAY", id), UVM_HIGH)

        // De-assert B channel
        vif.slave_drv_cb.bvalid <= 1'b0;
    endtask : send_write_response

    // ---------------------------------------------------------------
    // Compute next address based on AXI burst type
    //   FIXED (00) : address stays the same
    //   INCR  (01) : address increments by byte_size each beat
    //   WRAP  (10) : address wraps at aligned boundary
    // ---------------------------------------------------------------
    function bit [31:0] compute_next_addr(
        bit [31:0] current_addr,
        bit [31:0] start_addr,
        int        byte_size,
        bit [1:0]  burst_type,
        bit [7:0]  len
    );
        bit [31:0] next_addr;
        int        wrap_boundary;

        case (burst_type)
            2'b00: begin  // FIXED
                next_addr = current_addr;
            end
            2'b01: begin  // INCR
                next_addr = current_addr + byte_size;
            end
            2'b10: begin  // WRAP
                wrap_boundary = byte_size * (len + 1);
                next_addr = current_addr + byte_size;
                if ((next_addr - (start_addr & ~(wrap_boundary - 1))) >= wrap_boundary)
                    next_addr = start_addr & ~(wrap_boundary - 1);
            end
            default: begin
                next_addr = current_addr + byte_size;
            end
        endcase

        return next_addr;
    endfunction : compute_next_addr

endclass : axi_slave_driver
