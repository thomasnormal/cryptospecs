// PSoC Control C3 CryptoLite — AHB-Lite Slave / MMIO Register File
// Implements the 26-register CryptoLite register map.
// Writing AES_DESCR / SHA_DESCR / VU_DESCR while !busy triggers a one-cycle start pulse.
// TRNG_RESULT reads stall HREADY until a fresh 32-bit sample is available.
// Source: PSoC Control C3 TRM + Register Reference Manual (Infineon)

module cryptolite_regfile
    import cryptolite_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    // AHB-Lite slave
    input  logic        hsel,
    input  logic [31:0] haddr,
    input  logic [1:0]  htrans,
    input  logic        hwrite,
    input  logic [2:0]  hsize,
    input  logic [31:0] hwdata,
    output logic [31:0] hrdata,
    output logic        hreadyout,
    output logic        hresp,

    // Engine busy / start
    input  logic        busy,
    output logic [31:0] aes_descr_ptr,
    output logic [31:0] sha_descr_ptr,
    output logic [31:0] vu_descr_ptr,
    output logic        aes_start,      // one-cycle pulse
    output logic        sha_start,
    output logic        vu_start,

    // CTL register (passed to AHB master for protection attributes)
    output logic [31:0] ctl_reg,

    // Error interrupt input (AHB master bus error during operation)
    input  logic        bus_error,

    // TRNG config registers (to trng.sv)
    output logic [31:0] trng_ctl0,
    output logic [31:0] trng_ctl1,
    output logic [30:0] trng_garo_ctl,
    output logic [30:0] trng_firo_ctl,
    output logic [31:0] trng_mon_ctl,
    output logic [31:0] trng_mon_rc_ctl,
    output logic [31:0] trng_mon_ap_ctl,

    // TRNG status / result (from trng.sv)
    input  logic [31:0] trng_status,
    input  logic [31:0] trng_result,
    input  logic        trng_data_valid,   // 1 = trng_result holds fresh 32-bit sample
    output logic        trng_result_read,  // one-cycle pulse: TRNG may discard sample

    input  logic [31:0] trng_mon_rc_status0,
    input  logic [31:0] trng_mon_rc_status1,
    input  logic [31:0] trng_mon_ap_status0,
    input  logic [31:0] trng_mon_ap_status1,

    // TRNG interrupt inputs (level, set INTR_TRNG bits)
    input  logic        trng_initialized,
    input  logic        trng_ap_detect,
    input  logic        trng_rc_detect,

    // Combined masked interrupt output
    output logic        interrupt_level
);

    // ---------------------------------------------------------------
    // AHB-Lite address-phase pipeline registers
    // Only advance when hreadyout is asserted (current transfer done).
    // ---------------------------------------------------------------
    logic        hsel_q, hwrite_q;
    logic [11:0] haddr_q;
    logic [1:0]  htrans_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hsel_q   <= 1'b0;
            haddr_q  <= '0;
            hwrite_q <= 1'b0;
            htrans_q <= HTRANS_IDLE;
        end else if (hreadyout) begin
            hsel_q   <= hsel;
            haddr_q  <= haddr[11:0] & 12'hFFC;  // word-align
            hwrite_q <= hwrite;
            htrans_q <= htrans;
        end
    end

    // Data-phase qualifiers
    wire active = hsel_q && (htrans_q == HTRANS_NONSEQ);
    wire wr_en  = active &&  hwrite_q && !busy;  // all MMIO writes ignored while busy
    wire rd_en  = active && !hwrite_q;

    // TRNG_RESULT blocking read: hold hreadyout low until data is available.
    wire is_trng_rd       = rd_en && (haddr_q == TRNG_RESULT[11:0]);
    assign hreadyout       = !(is_trng_rd && !trng_data_valid);
    assign trng_result_read =   is_trng_rd &&  trng_data_valid;   // combinational pulse
    assign hresp           = HRESP_OKAY;

    // ---------------------------------------------------------------
    // CTL register (0x000) — valid bits: [11:8]=MS, [7:4]=PC, [1]=NS, [0]=P
    // ---------------------------------------------------------------
    logic [31:0] ctl_q;
    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n)
            ctl_q <= '0;
        else if (wr_en && (haddr_q == CTL[11:0]))
            ctl_q <= hwdata & 32'h00000FF3;
    assign ctl_reg = ctl_q;

    // ---------------------------------------------------------------
    // Descriptor pointer registers + one-cycle start pulses
    // ---------------------------------------------------------------
    logic [31:0] aes_descr_q, sha_descr_q, vu_descr_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            aes_descr_q <= '0; sha_descr_q <= '0; vu_descr_q <= '0;
            aes_start   <= 0;  sha_start   <= 0;  vu_start   <= 0;
        end else begin
            aes_start <= 0; sha_start <= 0; vu_start <= 0;
            if (wr_en) begin
                if (haddr_q == AES_DESCR[11:0]) begin
                    aes_descr_q <= {hwdata[31:2], 2'b00};
                    aes_start   <= 1'b1;
                end
                if (haddr_q == SHA_DESCR[11:0]) begin
                    sha_descr_q <= {hwdata[31:2], 2'b00};
                    sha_start   <= 1'b1;
                end
                if (haddr_q == VU_DESCR[11:0]) begin
                    vu_descr_q  <= {hwdata[31:2], 2'b00};
                    vu_start    <= 1'b1;
                end
            end
        end
    end
    assign aes_descr_ptr = aes_descr_q;
    assign sha_descr_ptr = sha_descr_q;
    assign vu_descr_ptr  = vu_descr_q;

    // ---------------------------------------------------------------
    // INTR_ERROR quad (RW1C / RW1S / RW / RO masked)
    // Only bit[0] = BUS_ERROR is implemented.
    // ---------------------------------------------------------------
    logic intr_err_q, intr_err_mask_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            intr_err_q      <= 1'b0;
            intr_err_mask_q <= 1'b0;
        end else begin
            if (bus_error)
                intr_err_q <= 1'b1;
            if (wr_en && (haddr_q == INTR_ERROR[11:0])      && hwdata[0])
                intr_err_q <= 1'b0;              // RW1C clear
            if (wr_en && (haddr_q == INTR_ERROR_SET[11:0])  && hwdata[0])
                intr_err_q <= 1'b1;              // RW1S force-set
            if (wr_en && (haddr_q == INTR_ERROR_MASK[11:0]))
                intr_err_mask_q <= hwdata[0];
        end
    end
    wire intr_err_masked = intr_err_q & intr_err_mask_q;

    // ---------------------------------------------------------------
    // TRNG config registers (all RW)
    // Reset values: TRNG_CTL0.INIT_DELAY defaults to 3 (bits [23:16])
    // ---------------------------------------------------------------
    logic [31:0] trng_ctl0_q, trng_ctl1_q;
    logic [31:0] trng_mon_ctl_q, trng_mon_rc_ctl_q, trng_mon_ap_ctl_q;
    logic [30:0] trng_garo_q, trng_firo_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            trng_ctl0_q       <= 32'h0003_0000;  // INIT_DELAY = 3
            trng_ctl1_q       <= '0;
            trng_mon_ctl_q    <= '0;
            trng_mon_rc_ctl_q <= '0;
            trng_mon_ap_ctl_q <= '0;
            trng_garo_q       <= TRNG_GARO_DEFAULT;
            trng_firo_q       <= TRNG_FIRO_DEFAULT;
        end else if (wr_en) begin
            case (haddr_q)
                TRNG_CTL0[11:0]:       trng_ctl0_q       <= hwdata;
                TRNG_CTL1[11:0]:       trng_ctl1_q       <= hwdata;
                TRNG_GARO_CTL[11:0]:   trng_garo_q       <= hwdata[30:0];
                TRNG_FIRO_CTL[11:0]:   trng_firo_q       <= hwdata[30:0];
                TRNG_MON_CTL[11:0]:    trng_mon_ctl_q    <= hwdata;
                TRNG_MON_RC_CTL[11:0]: trng_mon_rc_ctl_q <= hwdata;
                TRNG_MON_AP_CTL[11:0]: trng_mon_ap_ctl_q <= hwdata;
                default: ;
            endcase
        end
    end

    assign trng_ctl0       = trng_ctl0_q;
    assign trng_ctl1       = trng_ctl1_q;
    assign trng_garo_ctl   = trng_garo_q;
    assign trng_firo_ctl   = trng_firo_q;
    assign trng_mon_ctl    = trng_mon_ctl_q;
    assign trng_mon_rc_ctl = trng_mon_rc_ctl_q;
    assign trng_mon_ap_ctl = trng_mon_ap_ctl_q;

    // ---------------------------------------------------------------
    // INTR_TRNG quad (RW1C / RW1S / RW / RO masked)
    // Bits: [0]=initialized, [1]=data_available, [2]=ap_detect, [3]=rc_detect
    // ---------------------------------------------------------------
    logic [3:0] intr_trng_q, intr_trng_mask_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            intr_trng_q      <= '0;
            intr_trng_mask_q <= '0;
        end else begin
            // Hardware sets (level-sensitive: set while input is high)
            if (trng_initialized) intr_trng_q[INTR_TRNG_BIT_INITIALIZED]    <= 1'b1;
            if (trng_data_valid)  intr_trng_q[INTR_TRNG_BIT_DATA_AVAILABLE] <= 1'b1;
            if (trng_ap_detect)   intr_trng_q[INTR_TRNG_BIT_AP_DETECT]      <= 1'b1;
            if (trng_rc_detect)   intr_trng_q[INTR_TRNG_BIT_RC_DETECT]      <= 1'b1;
            // Register writes
            if (wr_en) begin
                if (haddr_q == INTR_TRNG[11:0])
                    intr_trng_q <= intr_trng_q & ~hwdata[3:0]; // RW1C
                if (haddr_q == INTR_TRNG_SET[11:0])
                    intr_trng_q <= intr_trng_q |  hwdata[3:0]; // RW1S
                if (haddr_q == INTR_TRNG_MASK[11:0])
                    intr_trng_mask_q <= hwdata[3:0];
            end
        end
    end
    wire [3:0] intr_trng_masked = intr_trng_q & intr_trng_mask_q;

    assign interrupt_level = |intr_trng_masked | intr_err_masked;

    // ---------------------------------------------------------------
    // Read mux (combinational, data phase)
    // ---------------------------------------------------------------
    always_comb begin
        hrdata = 32'h0;
        if (rd_en) begin
            case (haddr_q)
                CTL[11:0]:                 hrdata = ctl_q;
                STATUS[11:0]:              hrdata = {31'b0, busy};
                AES_DESCR[11:0]:           hrdata = aes_descr_q;
                SHA_DESCR[11:0]:           hrdata = sha_descr_q;
                VU_DESCR[11:0]:            hrdata = vu_descr_q;
                INTR_ERROR[11:0]:          hrdata = {31'b0, intr_err_q};
                INTR_ERROR_SET[11:0]:      hrdata = {31'b0, intr_err_q};
                INTR_ERROR_MASK[11:0]:     hrdata = {31'b0, intr_err_mask_q};
                INTR_ERROR_MASKED[11:0]:   hrdata = {31'b0, intr_err_masked};
                TRNG_CTL0[11:0]:           hrdata = trng_ctl0_q;
                TRNG_CTL1[11:0]:           hrdata = trng_ctl1_q;
                TRNG_STATUS[11:0]:         hrdata = trng_status;
                TRNG_RESULT[11:0]:         hrdata = trng_data_valid ? trng_result : 32'h0;
                TRNG_GARO_CTL[11:0]:       hrdata = {1'b0, trng_garo_q};
                TRNG_FIRO_CTL[11:0]:       hrdata = {1'b0, trng_firo_q};
                TRNG_MON_CTL[11:0]:        hrdata = trng_mon_ctl_q;
                TRNG_MON_RC_CTL[11:0]:     hrdata = trng_mon_rc_ctl_q;
                TRNG_MON_RC_STATUS0[11:0]: hrdata = trng_mon_rc_status0;
                TRNG_MON_RC_STATUS1[11:0]: hrdata = trng_mon_rc_status1;
                TRNG_MON_AP_CTL[11:0]:     hrdata = trng_mon_ap_ctl_q;
                TRNG_MON_AP_STATUS0[11:0]: hrdata = trng_mon_ap_status0;
                TRNG_MON_AP_STATUS1[11:0]: hrdata = trng_mon_ap_status1;
                INTR_TRNG[11:0]:           hrdata = {28'b0, intr_trng_q};
                INTR_TRNG_SET[11:0]:       hrdata = {28'b0, intr_trng_q};
                INTR_TRNG_MASK[11:0]:      hrdata = {28'b0, intr_trng_mask_q};
                INTR_TRNG_MASKED[11:0]:    hrdata = {28'b0, intr_trng_masked};
                default:                   hrdata = 32'h0;
            endcase
        end
    end

endmodule
