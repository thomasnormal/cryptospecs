interface cryptolite_mem_if #(
    parameter int MEM_WORDS = 8192
) (
    input logic clk,
    input logic rst_n
);
    import cryptolite_pkg::*;

    logic [31:0] haddr;
    logic [1:0]  htrans;
    logic        hwrite;
    logic [2:0]  hsize;
    logic [31:0] hwdata;
    logic [31:0] hrdata;
    logic        hready;
    logic        hresp;

    logic        fault_enable;
    logic [31:0] fault_base;
    logic [31:0] fault_limit;

    logic [31:0] mem [0:MEM_WORDS-1];

    assign hready = 1'b1;
    assign hresp =
        (fault_enable &&
         (htrans == HTRANS_NONSEQ) &&
         (haddr >= fault_base) &&
         (haddr < fault_limit)) ? HRESP_ERROR : HRESP_OKAY;
    assign hrdata = mem[haddr[31:2]];

    always_ff @(posedge clk) begin
        if ((htrans == HTRANS_NONSEQ) && hwrite && (hresp == HRESP_OKAY)) begin
            mem[haddr[31:2]] <= hwdata;
        end
    end

    task automatic clear();
        integer i;
        for (i = 0; i < MEM_WORDS; i = i + 1) begin
            mem[i] = '0;
        end
        fault_enable = 1'b0;
        fault_base   = '0;
        fault_limit  = '0;
    endtask

    task automatic write_word(input logic [31:0] addr, input logic [31:0] data);
        mem[addr[31:2]] = data;
    endtask

    function automatic logic [31:0] read_word(input logic [31:0] addr);
        return mem[addr[31:2]];
    endfunction

    task automatic set_error_range(input logic [31:0] base_addr, input logic [31:0] limit_addr);
        fault_enable = 1'b1;
        fault_base   = base_addr;
        fault_limit  = limit_addr;
    endtask

    task automatic clear_error_range();
        fault_enable = 1'b0;
        fault_base   = '0;
        fault_limit  = '0;
    endtask

endinterface
