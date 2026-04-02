// AHB-Lite Protocol Checker (SVA)
// Binds to an AHB-Lite interface and checks protocol compliance.
// Intended to be bound to ahb_if_inst in tb_top via a bind statement.

module ahb_protocol_checker (
    input logic        clk,
    input logic        rst_n,
    input logic        hsel,
    input logic [31:0] haddr,
    input logic [1:0]  htrans,
    input logic        hwrite,
    input logic [2:0]  hsize,
    input logic [31:0] hwdata,
    input logic [31:0] hrdata,
    input logic        hreadyout,
    input logic        hresp
);

    default clocking cb @(posedge clk);
    endclocking

    default disable iff (!rst_n);

    // ---------------------------------------------------------------
    // A1: After reset deassert, all outputs must be defined (not X/Z)
    // ---------------------------------------------------------------
    // Slave outputs: hrdata, hreadyout, hresp
    A1_hrdata_no_x: assert property (
        !$isunknown(hrdata)
    ) else $error("A1: hrdata contains X/Z after reset");

    A1_hreadyout_no_x: assert property (
        !$isunknown(hreadyout)
    ) else $error("A1: hreadyout contains X/Z after reset");

    A1_hresp_no_x: assert property (
        !$isunknown(hresp)
    ) else $error("A1: hresp contains X/Z after reset");

    // ---------------------------------------------------------------
    // A2: HADDR must be aligned to HSIZE
    //     HSIZE=000 (byte):     no alignment required
    //     HSIZE=001 (halfword): haddr[0] must be 0
    //     HSIZE=010 (word):     haddr[1:0] must be 00
    // ---------------------------------------------------------------
    A2_addr_align: assert property (
        (hsel && htrans != 2'b00) |->
            ((hsize == 3'b000) ||
             (hsize == 3'b001 && haddr[0] == 1'b0) ||
             (hsize == 3'b010 && haddr[1:0] == 2'b00))
    ) else $error("A2: HADDR 0x%08h not aligned for HSIZE=%0d", haddr, hsize);

    // ---------------------------------------------------------------
    // A3: When HREADYOUT is low, HADDR/HTRANS/HWRITE must remain stable
    //     (Not applicable for our zero-wait-state slave, but included
    //     for protocol completeness.)
    // ---------------------------------------------------------------
    A3_addr_stable: assert property (
        (!hreadyout) |=> (haddr == $past(haddr))
    ) else $error("A3: HADDR changed while HREADYOUT was low");

    A3_htrans_stable: assert property (
        (!hreadyout) |=> (htrans == $past(htrans))
    ) else $error("A3: HTRANS changed while HREADYOUT was low");

    A3_hwrite_stable: assert property (
        (!hreadyout) |=> (hwrite == $past(hwrite))
    ) else $error("A3: HWRITE changed while HREADYOUT was low");

    // ---------------------------------------------------------------
    // A4: HRESP OKAY must be single-cycle
    //     For our slave hresp is always OKAY (0). An ERROR response
    //     on AHB-Lite requires a two-cycle protocol; OKAY is always
    //     single-cycle. We assert hresp is always OKAY here.
    // ---------------------------------------------------------------
    A4_hresp_okay: assert property (
        hresp == 1'b0
    ) else $error("A4: HRESP is not OKAY (single-cycle response expected)");

    // ---------------------------------------------------------------
    // A5: HSIZE must not exceed data bus width
    //     For a 32-bit bus, HSIZE must be <= 3'b010 (word)
    // ---------------------------------------------------------------
    A5_hsize_max: assert property (
        (hsel && htrans != 2'b00) |-> (hsize <= 3'b010)
    ) else $error("A5: HSIZE=%0d exceeds 32-bit bus width", hsize);

endmodule
