// AXI4 Master Interface
// Handles read and write bursts for DMA data movement.
// 32-bit data bus, INCR burst type.

module axi_master (
    input  logic        clk,
    input  logic        rst_n,

    // Internal read request interface (from DMA engine)
    input  logic [31:0] rd_addr,
    input  logic [7:0]  rd_len,       // AXI burst length (0=1 beat, 3=4 beats)
    input  logic        rd_req,
    output logic        rd_grant,
    output logic [31:0] rd_data,
    output logic        rd_valid,
    output logic        rd_last,

    // Internal write request interface (from DMA engine)
    input  logic [31:0] wr_addr,
    input  logic [7:0]  wr_len,
    input  logic        wr_req,
    output logic        wr_grant,
    input  logic [31:0] wr_data,
    input  logic        wr_valid_in,
    output logic        wr_ready_out,
    output logic        wr_resp_ok,

    // AXI4 Master - Write Address Channel
    output logic [3:0]  awid,
    output logic [31:0] awaddr,
    output logic [7:0]  awlen,
    output logic [2:0]  awsize,
    output logic [1:0]  awburst,
    output logic        awvalid,
    input  logic        awready,

    // AXI4 Master - Write Data Channel
    output logic [31:0] wdata,
    output logic [3:0]  wstrb,
    output logic        wlast,
    output logic        wvalid,
    input  logic        wready,

    // AXI4 Master - Write Response Channel
    input  logic [3:0]  bid,
    input  logic [1:0]  bresp,
    input  logic        bvalid,
    output logic        bready,

    // AXI4 Master - Read Address Channel
    output logic [3:0]  arid,
    output logic [31:0] araddr,
    output logic [7:0]  arlen,
    output logic [2:0]  arsize,
    output logic [1:0]  arburst,
    output logic        arvalid,
    input  logic        arready,

    // AXI4 Master - Read Data Channel
    input  logic [3:0]  rid,
    input  logic [31:0] rdata,
    input  logic [1:0]  rresp,
    input  logic        rlast,
    input  logic        rvalid,
    output logic        rready
);

    // Fixed AXI signals
    assign awid    = 4'd0;
    assign awsize  = 3'b010;  // 4 bytes per beat
    assign awburst = 2'b01;   // INCR
    assign arid    = 4'd0;
    assign arsize  = 3'b010;
    assign arburst = 2'b01;
    assign wstrb   = 4'hF;    // Full word write

    // ---------------------------------------------------------------
    // Read Channel FSM
    // ---------------------------------------------------------------
    typedef enum logic [1:0] {
        RD_IDLE,
        RD_ADDR,
        RD_DATA
    } rd_state_e;

    rd_state_e rd_state_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_state_q <= RD_IDLE;
            araddr     <= '0;
            arlen      <= '0;
            arvalid    <= 1'b0;
            rd_grant   <= 1'b0;
        end else begin
            rd_grant <= 1'b0;

            case (rd_state_q)
                RD_IDLE: begin
                    if (rd_req) begin
                        araddr     <= rd_addr;
                        arlen      <= rd_len;
                        arvalid    <= 1'b1;
                        rd_grant   <= 1'b1;
                        rd_state_q <= RD_ADDR;
                    end
                end

                RD_ADDR: begin
                    if (arready) begin
                        arvalid    <= 1'b0;
                        rd_state_q <= RD_DATA;
                    end
                end

                RD_DATA: begin
                    if (rvalid && rlast) begin
                        rd_state_q <= RD_IDLE;
                    end
                end

                default: rd_state_q <= RD_IDLE;
            endcase
        end
    end

    // Read data passthrough
    assign rready   = (rd_state_q == RD_DATA);
    assign rd_data  = rdata;
    assign rd_valid = rvalid && (rd_state_q == RD_DATA);
    assign rd_last  = rlast && rvalid && (rd_state_q == RD_DATA);

    // ---------------------------------------------------------------
    // Write Channel FSM
    // ---------------------------------------------------------------
    typedef enum logic [1:0] {
        WR_IDLE,
        WR_ADDR,
        WR_DATA,
        WR_RESP
    } wr_state_e;

    wr_state_e wr_state_q;
    logic [7:0] wr_beat_cnt_q;
    logic [7:0] wr_len_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_state_q    <= WR_IDLE;
            awaddr        <= '0;
            awlen         <= '0;
            awvalid       <= 1'b0;
            wr_grant      <= 1'b0;
            wr_beat_cnt_q <= '0;
            wr_len_q      <= '0;
            wr_resp_ok    <= 1'b0;
        end else begin
            wr_grant   <= 1'b0;
            wr_resp_ok <= 1'b0;

            case (wr_state_q)
                WR_IDLE: begin
                    if (wr_req) begin
                        awaddr        <= wr_addr;
                        awlen         <= wr_len;
                        awvalid       <= 1'b1;
                        wr_grant      <= 1'b1;
                        wr_len_q      <= wr_len;
                        wr_beat_cnt_q <= '0;
                        wr_state_q    <= WR_ADDR;
                    end
                end

                WR_ADDR: begin
                    if (awready) begin
                        awvalid    <= 1'b0;
                        wr_state_q <= WR_DATA;
                    end
                end

                WR_DATA: begin
                    if (wvalid && wready) begin
                        if (wr_beat_cnt_q == wr_len_q) begin
                            wr_state_q <= WR_RESP;
                        end else begin
                            wr_beat_cnt_q <= wr_beat_cnt_q + 1;
                        end
                    end
                end

                WR_RESP: begin
                    if (bvalid) begin
                        wr_resp_ok <= (bresp == 2'b00); // OKAY
                        wr_state_q <= WR_IDLE;
                    end
                end

                default: wr_state_q <= WR_IDLE;
            endcase
        end
    end

    // Write data passthrough
    assign wdata      = wr_data;
    assign wvalid     = wr_valid_in && (wr_state_q == WR_DATA);
    assign wlast      = (wr_beat_cnt_q == wr_len_q) && (wr_state_q == WR_DATA);
    assign wr_ready_out = wready && (wr_state_q == WR_DATA);
    assign bready     = (wr_state_q == WR_RESP);

endmodule
