// PSoC Control C3 CryptoLite — SHA-256 Engine
// Implements the two-pass SHA-256 model used by C3 CryptoLite.
//
// Descriptor (at descr_ptr, 3 words):
//   Word 0: control word  — bit[28]=0 → schedule pass, bit[28]=1 → process pass
//   Word 1 (schedule pass): pointer to 512-bit message block   (16×32b, input)
//   Word 1 (process  pass): pointer to 256-bit hash state      (8×32b,  in/out)
//   Word 2 (both passes):   pointer to 256-byte schedule array (64×32b, out/in)
//
// Schedule pass  (WORD0[28]=0):
//   Reads  16 words from op1_ptr (message block)
//   Writes 64 words to   op2_ptr (full message schedule W[0..63])
//
// Process pass   (WORD0[28]=1):
//   Reads  8 words  from op1_ptr (hash state H[0..7])
//   Reads  64 words from op2_ptr (message schedule W[0..63])
//   Runs   64-round SHA-256 compression
//   Writes 8 words  back to op1_ptr (updated hash state)

module sha_engine
    import cryptolite_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    // Trigger (one-cycle pulse from regfile when SHA_DESCR is written)
    input  logic        start,
    input  logic [31:0] descr_ptr,

    // AHB master port
    output logic [31:0] haddr,
    output logic [1:0]  htrans,
    output logic        hwrite,
    output logic [2:0]  hsize,
    output logic [31:0] hwdata,
    input  logic [31:0] hrdata,
    input  logic        hready,
    input  logic        hresp,

    // Status
    output logic        busy,
    output logic        done,
    output logic        bus_error
);

    // ---------------------------------------------------------------
    // SHA-256 round constants
    // ---------------------------------------------------------------
    logic [31:0] K [0:63];
    assign K[ 0] = 32'h428a2f98; assign K[ 1] = 32'h71374491;
    assign K[ 2] = 32'hb5c0fbcf; assign K[ 3] = 32'he9b5dba5;
    assign K[ 4] = 32'h3956c25b; assign K[ 5] = 32'h59f111f1;
    assign K[ 6] = 32'h923f82a4; assign K[ 7] = 32'hab1c5ed5;
    assign K[ 8] = 32'hd807aa98; assign K[ 9] = 32'h12835b01;
    assign K[10] = 32'h243185be; assign K[11] = 32'h550c7dc3;
    assign K[12] = 32'h72be5d74; assign K[13] = 32'h80deb1fe;
    assign K[14] = 32'h9bdc06a7; assign K[15] = 32'hc19bf174;
    assign K[16] = 32'he49b69c1; assign K[17] = 32'hefbe4786;
    assign K[18] = 32'h0fc19dc6; assign K[19] = 32'h240ca1cc;
    assign K[20] = 32'h2de92c6f; assign K[21] = 32'h4a7484aa;
    assign K[22] = 32'h5cb0a9dc; assign K[23] = 32'h76f988da;
    assign K[24] = 32'h983e5152; assign K[25] = 32'ha831c66d;
    assign K[26] = 32'hb00327c8; assign K[27] = 32'hbf597fc7;
    assign K[28] = 32'hc6e00bf3; assign K[29] = 32'hd5a79147;
    assign K[30] = 32'h06ca6351; assign K[31] = 32'h14292967;
    assign K[32] = 32'h27b70a85; assign K[33] = 32'h2e1b2138;
    assign K[34] = 32'h4d2c6dfc; assign K[35] = 32'h53380d13;
    assign K[36] = 32'h650a7354; assign K[37] = 32'h766a0abb;
    assign K[38] = 32'h81c2c92e; assign K[39] = 32'h92722c85;
    assign K[40] = 32'ha2bfe8a1; assign K[41] = 32'ha81a664b;
    assign K[42] = 32'hc24b8b70; assign K[43] = 32'hc76c51a3;
    assign K[44] = 32'hd192e819; assign K[45] = 32'hd6990624;
    assign K[46] = 32'hf40e3585; assign K[47] = 32'h106aa070;
    assign K[48] = 32'h19a4c116; assign K[49] = 32'h1e376c08;
    assign K[50] = 32'h2748774c; assign K[51] = 32'h34b0bcb5;
    assign K[52] = 32'h391c0cb3; assign K[53] = 32'h4ed8aa4a;
    assign K[54] = 32'h5b9cca4f; assign K[55] = 32'h682e6ff3;
    assign K[56] = 32'h748f82ee; assign K[57] = 32'h78a5636f;
    assign K[58] = 32'h84c87814; assign K[59] = 32'h8cc70208;
    assign K[60] = 32'h90befffa; assign K[61] = 32'ha4506ceb;
    assign K[62] = 32'hbef9a3f7; assign K[63] = 32'hc67178f2;

    // ---------------------------------------------------------------
    // SHA-256 functions
    // ---------------------------------------------------------------
    function automatic logic [31:0] rotr;
        input logic [31:0] x;
        input integer n;
        return (x >> n) | (x << (32 - n));
    endfunction

    function automatic logic [31:0] sigma0;  // small σ0
        input logic [31:0] x;
        return rotr(x,7) ^ rotr(x,18) ^ (x >> 3);
    endfunction

    function automatic logic [31:0] sigma1;  // small σ1
        input logic [31:0] x;
        return rotr(x,17) ^ rotr(x,19) ^ (x >> 10);
    endfunction

    function automatic logic [31:0] Sigma0;  // big Σ0
        input logic [31:0] x;
        return rotr(x,2) ^ rotr(x,13) ^ rotr(x,22);
    endfunction

    function automatic logic [31:0] Sigma1;  // big Σ1
        input logic [31:0] x;
        return rotr(x,6) ^ rotr(x,11) ^ rotr(x,25);
    endfunction

    function automatic logic [31:0] Ch;
        input logic [31:0] e, f, g;
        return (e & f) ^ (~e & g);
    endfunction

    function automatic logic [31:0] Maj;
        input logic [31:0] a, b, c;
        return (a & b) ^ (a & c) ^ (b & c);
    endfunction

    // ---------------------------------------------------------------
    // FSM states
    // ---------------------------------------------------------------
    typedef enum logic [3:0] {
        SHA_IDLE,
        SHA_XFER_ADDR,
        SHA_XFER_DATA,
        // Schedule pass sub-states
        SHA_SCH_COMPUTE,   // compute W[i] from circular buffer
        // Process pass sub-states
        SHA_PROC_ROUND,    // one SHA-256 compression round (after W[i] read)
        SHA_PROC_ADDBACK,  // add a..h back to H[0..7]
        // Shared
        SHA_DONE
    } sha_state_e;

    // Phase within the operation
    typedef enum logic [2:0] {
        PH_DESCR,       // fetch 3-word descriptor
        PH_SCH_READ,    // schedule pass: read 16 message words into W_buf
        PH_SCH_WRITE,   // schedule pass: write W[0..63] to sched_ptr
        PH_PROC_STATE,  // process pass: read 8 hash state words
        PH_PROC_W,      // process pass: read W[i] for round i
        PH_PROC_WRITE   // process pass: write 8 hash state words back
    } sha_phase_e;

    sha_state_e  state_q;
    sha_phase_e  phase_q;
    logic [6:0]  cnt_q;        // multi-purpose loop counter (0..63)

    logic [31:0] op1_ptr_q;    // message block ptr (sch) or hash state ptr (proc)
    logic [31:0] op2_ptr_q;    // schedule array ptr (both)
    logic        is_process_q; // 0=schedule pass, 1=process pass

    // 16-element circular buffer for schedule window W[i mod 16]
    logic [31:0] W_buf [0:15];

    // Hash state working variables
    logic [31:0] H [0:7];      // initial/final hash state
    logic [31:0] a_q, b_q, c_q, d_q, e_q, f_q, g_q, h_q;

    // Latched W[i] fetched from memory for current process round
    logic [31:0] W_round_q;

    // ---------------------------------------------------------------
    // Combinatorial: current transfer address
    // ---------------------------------------------------------------
    logic [31:0] xfer_addr;
    always_comb begin
        case (phase_q)
            PH_DESCR:      xfer_addr = descr_ptr       + {25'b0, cnt_q[1:0], 2'b00};
            PH_SCH_READ:   xfer_addr = op1_ptr_q       + {23'b0, cnt_q[3:0], 2'b00};
            PH_SCH_WRITE:  xfer_addr = op2_ptr_q       + {23'b0, cnt_q[5:0], 2'b00};
            PH_PROC_STATE: xfer_addr = op1_ptr_q       + {23'b0, cnt_q[3:0], 2'b00};
            PH_PROC_W:     xfer_addr = op2_ptr_q       + {23'b0, cnt_q[5:0], 2'b00};
            PH_PROC_WRITE: xfer_addr = op1_ptr_q       + {23'b0, cnt_q[3:0], 2'b00};
            default:       xfer_addr = '0;
        endcase
    end

    // Write data for PH_SCH_WRITE: W[cnt] from circular buffer or computed
    logic [31:0] sch_wdata;
    assign sch_wdata = W_buf[cnt_q[3:0]];  // W_buf[(cnt) mod 16]

    logic [3:0]  sch_i, sch_im2, sch_im7, sch_im15;
    logic [31:0] sch_w_new;
    assign sch_i    = cnt_q[3:0];
    assign sch_im2  = sch_i - 4'd2;
    assign sch_im7  = sch_i - 4'd7;
    assign sch_im15 = sch_i - 4'd15;
    assign sch_w_new = sigma1(W_buf[sch_im2]) + W_buf[sch_im7] +
                       sigma0(W_buf[sch_im15]) + W_buf[sch_i];

    // Write data for PH_PROC_WRITE: updated hash state
    logic [31:0] state_wdata;
    always_comb begin
        case (cnt_q[2:0])
            3'd0: state_wdata = H[0];
            3'd1: state_wdata = H[1];
            3'd2: state_wdata = H[2];
            3'd3: state_wdata = H[3];
            3'd4: state_wdata = H[4];
            3'd5: state_wdata = H[5];
            3'd6: state_wdata = H[6];
            3'd7: state_wdata = H[7];
            default: state_wdata = '0;
        endcase
    end

    logic [31:0] proc_t1, proc_t2;
    assign proc_t1 = h_q + Sigma1(e_q) + Ch(e_q, f_q, g_q) + K[cnt_q[5:0]] + W_round_q;
    assign proc_t2 = Sigma0(a_q) + Maj(a_q, b_q, c_q);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q      <= SHA_IDLE;
            phase_q      <= PH_DESCR;
            cnt_q        <= '0;
            htrans       <= HTRANS_IDLE;
            hwrite       <= HWRITE_READ;
            haddr        <= '0;
            hwdata       <= '0;
            hsize        <= HSIZE_WORD;
            busy         <= 1'b0;
            done         <= 1'b0;
            bus_error    <= 1'b0;
            op1_ptr_q    <= '0;
            op2_ptr_q    <= '0;
            is_process_q <= 1'b0;
            W_round_q    <= '0;
            for (int i = 0; i < 16; i++) W_buf[i] <= '0;
            for (int i = 0; i < 8;  i++) H[i]     <= '0;
            {a_q,b_q,c_q,d_q,e_q,f_q,g_q,h_q} <= '0;
        end else begin
            done      <= 1'b0;
            bus_error <= 1'b0;

            case (state_q)

                SHA_IDLE: begin
                    htrans <= HTRANS_IDLE;
                    if (start) begin
                        busy    <= 1'b1;
                        phase_q <= PH_DESCR;
                        cnt_q   <= '0;
                        state_q <= SHA_XFER_ADDR;
                    end
                end

                SHA_XFER_ADDR: begin
                    haddr  <= xfer_addr;
                    htrans <= HTRANS_NONSEQ;
                    hwrite <= (phase_q == PH_SCH_WRITE || phase_q == PH_PROC_WRITE);
                    hsize  <= HSIZE_WORD;
                    hwdata <= (phase_q == PH_PROC_WRITE) ? state_wdata : sch_wdata;
                    state_q <= SHA_XFER_DATA;
                end

                SHA_XFER_DATA: begin
                    htrans <= HTRANS_IDLE;
                    if (hready) begin
                        if (hresp == HRESP_ERROR) begin
                            bus_error <= 1'b1;
                            busy      <= 1'b0;
                            done      <= 1'b1;
                            state_q   <= SHA_IDLE;
                        end else begin
                            // Capture / dispatch read data
                            case (phase_q)
                                PH_DESCR: begin
                                    case (cnt_q[1:0])
                                        2'd0: begin
                                            is_process_q <= hrdata[SHA_DESCR_CTL_PROC_BIT];
                                        end
                                        2'd1: op1_ptr_q <= hrdata;
                                        2'd2: op2_ptr_q <= hrdata;
                                        default: ;
                                    endcase
                                    if (cnt_q[1:0] == 2'd2) begin
                                        cnt_q   <= '0;
                                        if (is_process_q)
                                            phase_q <= PH_PROC_STATE;
                                        else
                                            phase_q <= PH_SCH_READ;
                                        state_q <= SHA_XFER_ADDR;
                                    end else begin
                                        cnt_q   <= cnt_q + 1;
                                        state_q <= SHA_XFER_ADDR;
                                    end
                                end

                                PH_SCH_READ: begin
                                    W_buf[cnt_q[3:0]] <= hrdata;
                                    if (cnt_q[3:0] == 4'd15) begin
                                        // All 16 message words read; compute & write W[0..63]
                                        cnt_q   <= '0;
                                        phase_q <= PH_SCH_WRITE;
                                        // Compute W[16] before writing W[0]?
                                        // W[0..15] are written first, so jump straight to write.
                                        state_q <= SHA_XFER_ADDR;
                                    end else begin
                                        cnt_q   <= cnt_q + 1;
                                        state_q <= SHA_XFER_ADDR;
                                    end
                                end

                                PH_SCH_WRITE: begin
                                    // After writing W[cnt], compute next entry for W[cnt+1]
                                    // if cnt+1 >= 16, compute from schedule formula.
                                    if (cnt_q == 7'd63) begin
                                        busy    <= 1'b0;
                                        done    <= 1'b1;
                                        state_q <= SHA_IDLE;
                                    end else begin
                                        cnt_q <= cnt_q + 1;
                                        // If we've finished writing W[15], start computing W[16..63]
                                        // W[cnt+1] for cnt>=15 is computed; already done in SHA_SCH_COMPUTE.
                                        // For cnt < 15: W_buf already has the values from PH_SCH_READ.
                                        if (cnt_q >= 7'd15) begin
                                            state_q <= SHA_SCH_COMPUTE;
                                        end else begin
                                            state_q <= SHA_XFER_ADDR;
                                        end
                                    end
                                end

                                PH_PROC_STATE: begin
                                    H[cnt_q[2:0]] <= hrdata;
                                    if (cnt_q[2:0] == 3'd7) begin
                                        // All 8 hash state words read; init working vars
                                        a_q <= H[0]; b_q <= H[1]; c_q <= H[2]; d_q <= H[3];
                                        e_q <= H[4]; f_q <= H[5]; g_q <= H[6]; h_q <= hrdata;  // H[7] not yet committed
                                        cnt_q   <= '0;
                                        phase_q <= PH_PROC_W;
                                        state_q <= SHA_XFER_ADDR;
                                    end else begin
                                        cnt_q   <= cnt_q + 1;
                                        state_q <= SHA_XFER_ADDR;
                                    end
                                end

                                PH_PROC_W: begin
                                    // W[cnt] just fetched; run one compression round
                                    W_round_q <= hrdata;
                                    state_q   <= SHA_PROC_ROUND;
                                end

                                PH_PROC_WRITE: begin
                                    if (cnt_q[2:0] == 3'd7) begin
                                        busy    <= 1'b0;
                                        done    <= 1'b1;
                                        state_q <= SHA_IDLE;
                                    end else begin
                                        cnt_q   <= cnt_q + 1;
                                        state_q <= SHA_XFER_ADDR;
                                    end
                                end

                                default: state_q <= SHA_IDLE;
                            endcase
                        end
                    end
                end

                // Compute W[cnt] = σ1(W[cnt-2]) + W[cnt-7] + σ0(W[cnt-15]) + W[cnt-16]
                // using the 16-element circular buffer (entry = W[i mod 16])
                SHA_SCH_COMPUTE: begin
                    W_buf[sch_i] <= sch_w_new;
                    state_q      <= SHA_XFER_ADDR;  // write W[cnt_q] to memory
                end

                // One SHA-256 compression round using W_round_q
                SHA_PROC_ROUND: begin
                    h_q <= g_q;
                    g_q <= f_q;
                    f_q <= e_q;
                    e_q <= d_q + proc_t1;
                    d_q <= c_q;
                    c_q <= b_q;
                    b_q <= a_q;
                    a_q <= proc_t1 + proc_t2;
                    if (cnt_q[5:0] == 6'd63) begin
                        state_q <= SHA_PROC_ADDBACK;
                    end else begin
                        cnt_q   <= cnt_q + 1;
                        phase_q <= PH_PROC_W;
                        state_q <= SHA_XFER_ADDR;
                    end
                end

                // Add working variables back to initial hash state
                SHA_PROC_ADDBACK: begin
                    H[0] <= H[0] + a_q;
                    H[1] <= H[1] + b_q;
                    H[2] <= H[2] + c_q;
                    H[3] <= H[3] + d_q;
                    H[4] <= H[4] + e_q;
                    H[5] <= H[5] + f_q;
                    H[6] <= H[6] + g_q;
                    H[7] <= H[7] + h_q;
                    cnt_q   <= '0;
                    phase_q <= PH_PROC_WRITE;
                    state_q <= SHA_XFER_ADDR;
                end

                default: state_q <= SHA_IDLE;
            endcase
        end
    end

    // Latch H[0] after addback for timing closure
    // (H[] update happens one cycle before the first write, which is correct)

endmodule
