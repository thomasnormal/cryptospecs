// Synchronous FIFO
// Parameterized width and depth, pointer-based implementation

module sync_fifo #(
    parameter int WIDTH = 128,
    parameter int DEPTH = 4
) (
    input  logic             clk,
    input  logic             rst_n,

    // Write port
    input  logic [WIDTH-1:0] wr_data,
    input  logic             wr_en,
    output logic             full,

    // Read port
    output logic [WIDTH-1:0] rd_data,
    input  logic             rd_en,
    output logic             empty,

    // Status
    output logic [$clog2(DEPTH):0] count
);

    localparam int PTR_W = $clog2(DEPTH);

    logic [WIDTH-1:0] mem [0:DEPTH-1];
    logic [PTR_W:0]   wr_ptr_q, rd_ptr_q;

    assign full  = (count == DEPTH[$clog2(DEPTH):0]);
    assign empty = (count == '0);

    assign count = wr_ptr_q - rd_ptr_q;

    // Write
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_q <= '0;
        end else if (wr_en && !full) begin
            mem[wr_ptr_q[PTR_W-1:0]] <= wr_data;
            wr_ptr_q <= wr_ptr_q + 1;
        end
    end

    // Read
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_q <= '0;
        end else if (rd_en && !empty) begin
            rd_ptr_q <= rd_ptr_q + 1;
        end
    end

    assign rd_data = mem[rd_ptr_q[PTR_W-1:0]];

endmodule
