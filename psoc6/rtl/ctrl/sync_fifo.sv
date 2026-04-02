// Synchronous FIFO — parameterized width and depth

module sync_fifo #(
    parameter int WIDTH = 32,
    parameter int DEPTH = 8
) (
    input  logic             clk,
    input  logic             rst_n,

    input  logic [WIDTH-1:0] wr_data,
    input  logic             wr_en,
    output logic             full,

    output logic [WIDTH-1:0] rd_data,
    input  logic             rd_en,
    output logic             empty,

    output logic [$clog2(DEPTH):0] count
);
    localparam int PTR_W = $clog2(DEPTH);

    logic [WIDTH-1:0] mem [0:DEPTH-1];
    logic [PTR_W:0]   wr_ptr_q, rd_ptr_q;

    assign count = wr_ptr_q - rd_ptr_q;
    assign full  = (count == DEPTH[$clog2(DEPTH):0]);
    assign empty = (count == '0);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) wr_ptr_q <= '0;
        else if (wr_en && !full) begin
            mem[wr_ptr_q[PTR_W-1:0]] <= wr_data;
            wr_ptr_q <= wr_ptr_q + 1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) rd_ptr_q <= '0;
        else if (rd_en && !empty) rd_ptr_q <= rd_ptr_q + 1;
    end

    assign rd_data = mem[rd_ptr_q[PTR_W-1:0]];

endmodule
