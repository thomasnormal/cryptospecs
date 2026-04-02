// AXI4 Interface
// Full AXI4 signal set for all 5 channels (AW, W, B, AR, R).
// 32-bit data bus, 4-bit ID. Used to connect the DUT's AXI master port
// to the reactive AXI slave agent in the testbench.

interface axi_if (
    input logic clk,
    input logic rst_n
);

    // ---------------------------------------------------------------
    // Write Address Channel (AW)
    // ---------------------------------------------------------------
    logic [3:0]  awid;
    logic [31:0] awaddr;
    logic [7:0]  awlen;
    logic [2:0]  awsize;
    logic [1:0]  awburst;
    logic        awvalid;
    logic        awready;

    // ---------------------------------------------------------------
    // Write Data Channel (W)
    // ---------------------------------------------------------------
    logic [31:0] wdata;
    logic [3:0]  wstrb;
    logic        wlast;
    logic        wvalid;
    logic        wready;

    // ---------------------------------------------------------------
    // Write Response Channel (B)
    // ---------------------------------------------------------------
    logic [3:0]  bid;
    logic [1:0]  bresp;
    logic        bvalid;
    logic        bready;

    // ---------------------------------------------------------------
    // Read Address Channel (AR)
    // ---------------------------------------------------------------
    logic [3:0]  arid;
    logic [31:0] araddr;
    logic [7:0]  arlen;
    logic [2:0]  arsize;
    logic [1:0]  arburst;
    logic        arvalid;
    logic        arready;

    // ---------------------------------------------------------------
    // Read Data Channel (R)
    // ---------------------------------------------------------------
    logic [3:0]  rid;
    logic [31:0] rdata;
    logic [1:0]  rresp;
    logic        rlast;
    logic        rvalid;
    logic        rready;

    // ---------------------------------------------------------------
    // Clocking Blocks
    // ---------------------------------------------------------------

    // Slave driver clocking block: drives slave-side outputs, samples master-side outputs
    clocking slave_drv_cb @(posedge clk);
        default input #1step output #1;

        // AW channel - master drives, slave samples and responds
        input  awid, awaddr, awlen, awsize, awburst, awvalid;
        output awready;

        // W channel - master drives, slave samples and responds
        input  wdata, wstrb, wlast, wvalid;
        output wready;

        // B channel - slave drives, master samples
        output bid, bresp, bvalid;
        input  bready;

        // AR channel - master drives, slave samples and responds
        input  arid, araddr, arlen, arsize, arburst, arvalid;
        output arready;

        // R channel - slave drives, master samples
        output rid, rdata, rresp, rlast, rvalid;
        input  rready;
    endclocking

    // Monitor clocking block: passive observation of all signals
    clocking mon_cb @(posedge clk);
        default input #1step;

        // AW channel
        input awid, awaddr, awlen, awsize, awburst, awvalid, awready;

        // W channel
        input wdata, wstrb, wlast, wvalid, wready;

        // B channel
        input bid, bresp, bvalid, bready;

        // AR channel
        input arid, araddr, arlen, arsize, arburst, arvalid, arready;

        // R channel
        input rid, rdata, rresp, rlast, rvalid, rready;
    endclocking

    // ---------------------------------------------------------------
    // Modports
    // ---------------------------------------------------------------
    modport SLAVE_DRV (clocking slave_drv_cb, input clk, input rst_n);
    modport MONITOR   (clocking mon_cb,       input clk, input rst_n);

endinterface : axi_if
