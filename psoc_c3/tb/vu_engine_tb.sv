`timescale 1ns/1ps

module vu_engine_tb;
    import cryptolite_pkg::*;

    localparam int MEM_WORDS = 1024;
    localparam int CLK_PERIOD = 10;

    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic start;
    logic [31:0] descr_ptr;

    logic [31:0] haddr;
    logic [1:0]  htrans;
    logic        hwrite;
    logic [2:0]  hsize;
    logic [31:0] hwdata;
    logic [31:0] hrdata;
    logic        hready;
    logic        hresp;

    logic busy;
    logic done;
    logic bus_error;

    logic [31:0] mem [0:MEM_WORDS-1];

    always #(CLK_PERIOD/2) clk = ~clk;

    vu_engine #(
        .VU_MAX_WORDS(8)
    ) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .start     (start),
        .descr_ptr (descr_ptr),
        .haddr     (haddr),
        .htrans    (htrans),
        .hwrite    (hwrite),
        .hsize     (hsize),
        .hwdata    (hwdata),
        .hrdata    (hrdata),
        .hready    (hready),
        .hresp     (hresp),
        .busy      (busy),
        .done      (done),
        .bus_error (bus_error)
    );

    assign hready = 1'b1;
    assign hresp = HRESP_OKAY;
    assign hrdata = mem[haddr[31:2]];

    always_ff @(posedge clk) begin
        if (htrans == HTRANS_NONSEQ && hwrite) begin
            mem[haddr[31:2]] <= hwdata;
        end
    end

    task automatic clear_mem;
        for (int i = 0; i < MEM_WORDS; i++) begin
            mem[i] = '0;
        end
    endtask

    task automatic wait_done(string name);
        int cycles;
        cycles = 0;
        while (!done) begin
            @(posedge clk);
            cycles++;
            if (cycles > 500) begin
                $fatal(1, "%s timed out", name);
            end
            if (bus_error) begin
                $fatal(1, "%s raised bus_error", name);
            end
        end
        @(posedge clk);
    endtask

    task automatic start_descr(input logic [31:0] ptr);
        @(posedge clk);
        descr_ptr <= ptr;
        start <= 1'b1;
        @(posedge clk);
        start <= 1'b0;
    endtask

    task automatic expect_word(input logic [31:0] addr, input logic [31:0] expected, input string label);
        logic [31:0] actual;
        actual = mem[addr[31:2]];
        if (actual !== expected) begin
            $fatal(1, "%s mismatch at 0x%08h: got 0x%08h expected 0x%08h",
                   label, addr, actual, expected);
        end
    endtask

    task automatic run_mov_test;
        localparam logic [31:0] DESCR = 32'h0000_0000;
        localparam logic [31:0] SRC0  = 32'h0000_0040;
        localparam logic [31:0] DST   = 32'h0000_0080;
        begin
            clear_mem();
            mem[DESCR[31:2] + 0] = (VU_MOV << 28) | ((2 - 1) << 16) | (2 - 1);
            mem[DESCR[31:2] + 1] = SRC0;
            mem[DESCR[31:2] + 2] = 32'h0;
            mem[DESCR[31:2] + 3] = DST;
            mem[SRC0[31:2] + 0] = 32'h89ab_cdef;
            mem[SRC0[31:2] + 1] = 32'h0123_4567;

            start_descr(DESCR);
            wait_done("mov");

            expect_word(DST + 32'd0, 32'h89ab_cdef, "mov");
            expect_word(DST + 32'd4, 32'h0123_4567, "mov");
        end
    endtask

    task automatic run_add_test;
        localparam logic [31:0] DESCR = 32'h0000_0100;
        localparam logic [31:0] SRC0  = 32'h0000_0140;
        localparam logic [31:0] SRC1  = 32'h0000_0180;
        localparam logic [31:0] DST   = 32'h0000_01c0;
        begin
            clear_mem();
            mem[DESCR[31:2] + 0] = (VU_ADD << 28) | ((2 - 1) << 16) | ((2 - 1) << 8) | (2 - 1);
            mem[DESCR[31:2] + 1] = SRC0;
            mem[DESCR[31:2] + 2] = SRC1;
            mem[DESCR[31:2] + 3] = DST;
            mem[SRC0[31:2] + 0] = 32'hffff_ffff;
            mem[SRC0[31:2] + 1] = 32'h0000_0000;
            mem[SRC1[31:2] + 0] = 32'h0000_0001;
            mem[SRC1[31:2] + 1] = 32'h0000_0000;

            start_descr(DESCR);
            wait_done("add");

            expect_word(DST + 32'd0, 32'h0000_0000, "add");
            expect_word(DST + 32'd4, 32'h0000_0001, "add");
        end
    endtask

    task automatic run_lsr_test;
        localparam logic [31:0] DESCR = 32'h0000_0200;
        localparam logic [31:0] SRC0  = 32'h0000_0240;
        localparam logic [31:0] DST   = 32'h0000_0280;
        begin
            clear_mem();
            mem[DESCR[31:2] + 0] = (VU_LSR << 28) | ((2 - 1) << 16) | (2 - 1);
            mem[DESCR[31:2] + 1] = SRC0;
            mem[DESCR[31:2] + 2] = 32'd4;
            mem[DESCR[31:2] + 3] = DST;
            mem[SRC0[31:2] + 0] = 32'h0123_4567;
            mem[SRC0[31:2] + 1] = 32'h89ab_cdef;

            start_descr(DESCR);
            wait_done("lsr");

            expect_word(DST + 32'd0, 32'hf012_3456, "lsr");
            expect_word(DST + 32'd4, 32'h089a_bcde, "lsr");
        end
    endtask

    task automatic run_mul_test;
        localparam logic [31:0] DESCR = 32'h0000_0300;
        localparam logic [31:0] SRC0  = 32'h0000_0340;
        localparam logic [31:0] SRC1  = 32'h0000_0380;
        localparam logic [31:0] DST   = 32'h0000_03c0;
        begin
            clear_mem();
            mem[DESCR[31:2] + 0] = (VU_MUL << 28) | ((2 - 1) << 16) | ((1 - 1) << 8) | (1 - 1);
            mem[DESCR[31:2] + 1] = SRC0;
            mem[DESCR[31:2] + 2] = SRC1;
            mem[DESCR[31:2] + 3] = DST;
            mem[SRC0[31:2] + 0] = 32'd3;
            mem[SRC1[31:2] + 0] = 32'd5;
            mem[DST[31:2] + 0] = 32'hdead_beef;
            mem[DST[31:2] + 1] = 32'hcafe_babe;

            start_descr(DESCR);
            wait_done("mul");

            expect_word(DST + 32'd0, 32'd15, "mul");
            expect_word(DST + 32'd4, 32'd0, "mul");
        end
    endtask

    initial begin
        start = 1'b0;
        descr_ptr = '0;
        clear_mem();

        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        run_mov_test();
        run_add_test();
        run_lsr_test();
        run_mul_test();

        $display("vu_engine_tb PASS");
        $finish;
    end

endmodule
