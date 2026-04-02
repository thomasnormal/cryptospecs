// AHB-Lite Master Interface
// Defines signals for an AHB-Lite master driving a slave port.

interface ahb_if (
    input logic clk,
    input logic rst_n
);

    logic        hsel;
    logic [31:0] haddr;
    logic [1:0]  htrans;
    logic        hwrite;
    logic [2:0]  hsize;
    logic [31:0] hwdata;
    logic [31:0] hrdata;
    logic        hreadyout;
    logic        hresp;

    // Master drives: hsel, haddr, htrans, hwrite, hsize, hwdata
    // Slave  drives: hrdata, hreadyout, hresp

    clocking mst_cb @(posedge clk);
        default input #1step output #1;
        output hsel;
        output haddr;
        output htrans;
        output hwrite;
        output hsize;
        output hwdata;
        input  hrdata;
        input  hreadyout;
        input  hresp;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step;
        input hsel;
        input haddr;
        input htrans;
        input hwrite;
        input hsize;
        input hwdata;
        input hrdata;
        input hreadyout;
        input hresp;
    endclocking

    modport master (clocking mst_cb, input clk, input rst_n);
    modport monitor (clocking mon_cb, input clk, input rst_n);

endinterface
