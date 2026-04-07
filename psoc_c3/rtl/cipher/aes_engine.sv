// PSoC Control C3 CryptoLite — AES-128 ECB Engine
// Fetches a 3-word descriptor from memory, reads 128-bit key + plaintext via
// AHB master, runs AES-128 ECB encryption, writes 128-bit ciphertext back.
//
// Descriptor (at descr_ptr, 3 words):
//   Word 0: 32-bit pointer to 128-bit key    (4 × 32-bit words, MSW first)
//   Word 1: 32-bit pointer to 128-bit plaintext
//   Word 2: 32-bit pointer to 128-bit ciphertext output
//
// Reuses aes_core.sv from esp32_p4_aes with decrypt=0, aes256=0.

module aes_engine
    import cryptolite_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    // Trigger (one-cycle pulse from regfile when AES_DESCR is written)
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
    output logic        done,       // one-cycle pulse
    output logic        bus_error   // one-cycle pulse
);

    // ---------------------------------------------------------------
    // AES core instance (from esp32_p4_aes)
    // ---------------------------------------------------------------
    logic         core_start;
    logic [127:0] core_key, core_pt;
    logic [127:0] core_ct;
    logic         core_busy, core_done;

    aes_core u_core (
        .clk      (clk),
        .rst_n    (rst_n),
        .start    (core_start),
        .decrypt  (1'b0),            // encrypt only
        .aes256   (1'b0),            // AES-128 only
        .key      ({core_key, 128'h0}), // upper 128 bits used for AES-128
        .data_in  (core_pt),
        .data_out (core_ct),
        .busy     (core_busy),
        .done     (core_done)
    );

    // ---------------------------------------------------------------
    // FSM
    // ---------------------------------------------------------------
    typedef enum logic [2:0] {
        AES_IDLE,
        AES_XFER_ADDR,   // address phase of a single AHB transfer
        AES_XFER_DATA,   // data  phase of a single AHB transfer
        AES_RUN,         // waiting for aes_core to finish
        AES_DONE
    } aes_state_e;

    typedef enum logic [1:0] {
        PH_DESCR,   // fetch 3-word descriptor
        PH_KEY,     // fetch 4-word key (MSW first)
        PH_PT,      // fetch 4-word plaintext
        PH_CT       // write 4-word ciphertext
    } phase_e;

    aes_state_e  state_q;
    phase_e      phase_q;
    logic [1:0]  word_cnt_q;   // 0-based index within current phase

    logic [31:0] key_ptr_q, pt_ptr_q, ct_ptr_q;
    logic [127:0] key_q, pt_q;

    // Combinatorial: current transfer address
    logic [31:0] xfer_addr;
    always_comb begin
        case (phase_q)
            PH_DESCR: xfer_addr = descr_ptr    + {28'h0, word_cnt_q, 2'b00};
            PH_KEY:   xfer_addr = key_ptr_q    + {28'h0, word_cnt_q, 2'b00};
            PH_PT:    xfer_addr = pt_ptr_q     + {28'h0, word_cnt_q, 2'b00};
            PH_CT:    xfer_addr = ct_ptr_q     + {28'h0, word_cnt_q, 2'b00};
            default:  xfer_addr = '0;
        endcase
    end

    // Combinatorial: write data for CT phase (big-endian: word 0 = MSW)
    logic [31:0] ct_wdata;
    always_comb begin
        case (word_cnt_q)
            2'd0: ct_wdata = core_ct[127:96];
            2'd1: ct_wdata = core_ct[95:64];
            2'd2: ct_wdata = core_ct[63:32];
            2'd3: ct_wdata = core_ct[31:0];
            default: ct_wdata = '0;
        endcase
    end

    // Phase done when word_cnt reaches the last word for that phase
    wire phase_done = (phase_q == PH_DESCR) ? (word_cnt_q == 2'd2) : (word_cnt_q == 2'd3);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q    <= AES_IDLE;
            phase_q    <= PH_DESCR;
            word_cnt_q <= '0;
            htrans     <= HTRANS_IDLE;
            hwrite     <= HWRITE_READ;
            haddr      <= '0;
            hwdata     <= '0;
            hsize      <= HSIZE_WORD;
            busy       <= 1'b0;
            done       <= 1'b0;
            bus_error  <= 1'b0;
            core_start <= 1'b0;
            key_ptr_q  <= '0; pt_ptr_q <= '0; ct_ptr_q <= '0;
            key_q      <= '0; pt_q     <= '0;
        end else begin
            done       <= 1'b0;
            bus_error  <= 1'b0;
            core_start <= 1'b0;

            case (state_q)

                AES_IDLE: begin
                    htrans <= HTRANS_IDLE;
                    if (start) begin
                        busy       <= 1'b1;
                        phase_q    <= PH_DESCR;
                        word_cnt_q <= '0;
                        state_q    <= AES_XFER_ADDR;
                    end
                end

                // Address phase: present HADDR, HTRANS=NONSEQ, HWRITE, HWDATA (writes)
                AES_XFER_ADDR: begin
                    haddr  <= xfer_addr;
                    htrans <= HTRANS_NONSEQ;
                    hwrite <= (phase_q == PH_CT);
                    hsize  <= HSIZE_WORD;
                    hwdata <= ct_wdata;   // valid only for PH_CT; harmless for reads
                    state_q <= AES_XFER_DATA;
                end

                // Data phase: HTRANS=IDLE, wait for hready
                AES_XFER_DATA: begin
                    htrans <= HTRANS_IDLE;
                    if (hready) begin
                        if (hresp == HRESP_ERROR) begin
                            bus_error <= 1'b1;
                            busy      <= 1'b0;
                            done      <= 1'b1;
                            state_q   <= AES_IDLE;
                        end else begin
                            // Capture read data
                            if (phase_q != PH_CT) begin
                                case (phase_q)
                                    PH_DESCR: begin
                                        case (word_cnt_q)
                                            2'd0: key_ptr_q <= hrdata;
                                            2'd1: pt_ptr_q  <= hrdata;
                                            2'd2: ct_ptr_q  <= hrdata;
                                            default: ;
                                        endcase
                                    end
                                    PH_KEY: begin
                                        case (word_cnt_q)
                                            2'd0: key_q[127:96] <= hrdata;
                                            2'd1: key_q[95:64]  <= hrdata;
                                            2'd2: key_q[63:32]  <= hrdata;
                                            2'd3: key_q[31:0]   <= hrdata;
                                            default: ;
                                        endcase
                                    end
                                    PH_PT: begin
                                        case (word_cnt_q)
                                            2'd0: pt_q[127:96] <= hrdata;
                                            2'd1: pt_q[95:64]  <= hrdata;
                                            2'd2: pt_q[63:32]  <= hrdata;
                                            2'd3: pt_q[31:0]   <= hrdata;
                                            default: ;
                                        endcase
                                    end
                                    default: ;
                                endcase
                            end

                            if (phase_done) begin
                                word_cnt_q <= '0;
                                case (phase_q)
                                    PH_DESCR: begin phase_q <= PH_KEY; state_q <= AES_XFER_ADDR; end
                                    PH_KEY:   begin phase_q <= PH_PT;  state_q <= AES_XFER_ADDR; end
                                    PH_PT: begin
                                        // key_q and pt_q are now fully assembled — kick off core
                                        core_start <= 1'b1;
                                        state_q    <= AES_RUN;
                                    end
                                    PH_CT: begin
                                        busy    <= 1'b0;
                                        done    <= 1'b1;
                                        state_q <= AES_IDLE;
                                    end
                                    default: state_q <= AES_IDLE;
                                endcase
                            end else begin
                                word_cnt_q <= word_cnt_q + 2'd1;
                                state_q    <= AES_XFER_ADDR;
                            end
                        end
                    end
                end

                AES_RUN: begin
                    if (core_done) begin
                        // core_ct is now valid; write ciphertext to memory
                        phase_q    <= PH_CT;
                        word_cnt_q <= '0;
                        state_q    <= AES_XFER_ADDR;
                    end
                end

                default: state_q <= AES_IDLE;
            endcase
        end
    end

    // Pass through assembled operands to core (wire, not registered)
    assign core_key = key_q;
    assign core_pt  = pt_q;

endmodule
