// PSoC Control C3 CryptoLite — Top-Level Integration
//
// Instantiates:
//   cryptolite_regfile  — AHB-Lite slave, all 26 MMIO registers
//   aes_engine          — AES-128 ECB encrypt
//   sha_engine          — SHA-256 (schedule + process passes)
//   vu_engine           — Vector Unit large-integer arithmetic
//   trng                — TRNG behavioral model
//
// AHB master port is multiplexed across engines; only one operation
// runs at a time (enforced by MMIO write-block while BUSY=1).

module cryptolite_top
    import cryptolite_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,

    // ---- AHB-Lite slave (CPU config / status access) ----------------
    input  logic        s_hsel,
    input  logic [31:0] s_haddr,
    input  logic [1:0]  s_htrans,
    input  logic        s_hwrite,
    input  logic [2:0]  s_hsize,
    input  logic [31:0] s_hwdata,
    output logic [31:0] s_hrdata,
    output logic        s_hreadyout,
    output logic        s_hresp,

    // ---- AHB master (operand memory access) -------------------------
    output logic [31:0] m_haddr,
    output logic [1:0]  m_htrans,
    output logic        m_hwrite,
    output logic [2:0]  m_hsize,
    output logic [31:0] m_hwdata,
    input  logic [31:0] m_hrdata,
    input  logic        m_hready,
    input  logic        m_hresp,

    // ---- Interrupt output -------------------------------------------
    output logic        interrupt_level
);

    // ---------------------------------------------------------------
    // Busy / done
    // ---------------------------------------------------------------
    logic aes_busy, aes_done, aes_bus_err;
    logic sha_busy, sha_done, sha_bus_err;
    logic vu_busy,  vu_done,  vu_bus_err;

    wire  busy      = aes_busy | sha_busy | vu_busy;
    wire  bus_error = aes_bus_err | sha_bus_err | vu_bus_err;

    // ---------------------------------------------------------------
    // Register file signals
    // ---------------------------------------------------------------
    logic [31:0] aes_descr_ptr, sha_descr_ptr, vu_descr_ptr;
    logic        aes_start, sha_start, vu_start;
    logic [31:0] ctl_reg;

    // TRNG wires
    logic [31:0] trng_ctl0, trng_ctl1;
    logic [30:0] trng_garo_ctl, trng_firo_ctl;
    logic [31:0] trng_mon_ctl, trng_mon_rc_ctl, trng_mon_ap_ctl;
    logic [31:0] trng_status, trng_result;
    logic        trng_data_valid, trng_result_read;
    logic [31:0] trng_mon_rc_status0, trng_mon_rc_status1;
    logic [31:0] trng_mon_ap_status0, trng_mon_ap_status1;
    logic        trng_initialized, trng_ap_detect, trng_rc_detect;

    // ---------------------------------------------------------------
    // Register file
    // ---------------------------------------------------------------
    cryptolite_regfile u_regfile (
        .clk              (clk),
        .rst_n            (rst_n),
        .hsel             (s_hsel),
        .haddr            (s_haddr),
        .htrans           (s_htrans),
        .hwrite           (s_hwrite),
        .hsize            (s_hsize),
        .hwdata           (s_hwdata),
        .hrdata           (s_hrdata),
        .hreadyout        (s_hreadyout),
        .hresp            (s_hresp),
        .busy             (busy),
        .aes_descr_ptr    (aes_descr_ptr),
        .sha_descr_ptr    (sha_descr_ptr),
        .vu_descr_ptr     (vu_descr_ptr),
        .aes_start        (aes_start),
        .sha_start        (sha_start),
        .vu_start         (vu_start),
        .ctl_reg          (ctl_reg),
        .bus_error        (bus_error),
        .trng_ctl0        (trng_ctl0),
        .trng_ctl1        (trng_ctl1),
        .trng_garo_ctl    (trng_garo_ctl),
        .trng_firo_ctl    (trng_firo_ctl),
        .trng_mon_ctl     (trng_mon_ctl),
        .trng_mon_rc_ctl  (trng_mon_rc_ctl),
        .trng_mon_ap_ctl  (trng_mon_ap_ctl),
        .trng_status      (trng_status),
        .trng_result      (trng_result),
        .trng_data_valid  (trng_data_valid),
        .trng_result_read (trng_result_read),
        .trng_mon_rc_status0(trng_mon_rc_status0),
        .trng_mon_rc_status1(trng_mon_rc_status1),
        .trng_mon_ap_status0(trng_mon_ap_status0),
        .trng_mon_ap_status1(trng_mon_ap_status1),
        .trng_initialized (trng_initialized),
        .trng_ap_detect   (trng_ap_detect),
        .trng_rc_detect   (trng_rc_detect),
        .interrupt_level  (interrupt_level)
    );

    // ---------------------------------------------------------------
    // AES engine
    // ---------------------------------------------------------------
    logic [31:0] aes_haddr;  logic [1:0] aes_htrans;
    logic        aes_hwrite; logic [2:0] aes_hsize;
    logic [31:0] aes_hwdata;

    aes_engine u_aes (
        .clk       (clk),
        .rst_n     (rst_n),
        .start     (aes_start),
        .descr_ptr (aes_descr_ptr),
        .haddr     (aes_haddr),
        .htrans    (aes_htrans),
        .hwrite    (aes_hwrite),
        .hsize     (aes_hsize),
        .hwdata    (aes_hwdata),
        .hrdata    (m_hrdata),
        .hready    (m_hready),
        .hresp     (m_hresp),
        .busy      (aes_busy),
        .done      (aes_done),
        .bus_error (aes_bus_err)
    );

    // ---------------------------------------------------------------
    // SHA engine
    // ---------------------------------------------------------------
    logic [31:0] sha_haddr;  logic [1:0] sha_htrans;
    logic        sha_hwrite; logic [2:0] sha_hsize;
    logic [31:0] sha_hwdata;

    sha_engine u_sha (
        .clk       (clk),
        .rst_n     (rst_n),
        .start     (sha_start),
        .descr_ptr (sha_descr_ptr),
        .haddr     (sha_haddr),
        .htrans    (sha_htrans),
        .hwrite    (sha_hwrite),
        .hsize     (sha_hsize),
        .hwdata    (sha_hwdata),
        .hrdata    (m_hrdata),
        .hready    (m_hready),
        .hresp     (m_hresp),
        .busy      (sha_busy),
        .done      (sha_done),
        .bus_error (sha_bus_err)
    );

    // ---------------------------------------------------------------
    // VU engine
    // ---------------------------------------------------------------
    logic [31:0] vu_haddr;  logic [1:0] vu_htrans;
    logic        vu_hwrite; logic [2:0] vu_hsize;
    logic [31:0] vu_hwdata;

    vu_engine u_vu (
        .clk       (clk),
        .rst_n     (rst_n),
        .start     (vu_start),
        .descr_ptr (vu_descr_ptr),
        .haddr     (vu_haddr),
        .htrans    (vu_htrans),
        .hwrite    (vu_hwrite),
        .hsize     (vu_hsize),
        .hwdata    (vu_hwdata),
        .hrdata    (m_hrdata),
        .hready    (m_hready),
        .hresp     (m_hresp),
        .busy      (vu_busy),
        .done      (vu_done),
        .bus_error (vu_bus_err)
    );

    // ---------------------------------------------------------------
    // TRNG
    // ---------------------------------------------------------------
    trng u_trng (
        .clk              (clk),
        .rst_n            (rst_n),
        .ctl0             (trng_ctl0),
        .ctl1             (trng_ctl1),
        .garo_ctl         (trng_garo_ctl),
        .firo_ctl         (trng_firo_ctl),
        .mon_ctl          (trng_mon_ctl),
        .mon_rc_ctl       (trng_mon_rc_ctl),
        .mon_ap_ctl       (trng_mon_ap_ctl),
        .status           (trng_status),
        .result           (trng_result),
        .data_valid       (trng_data_valid),
        .result_read      (trng_result_read),
        .mon_rc_status0   (trng_mon_rc_status0),
        .mon_rc_status1   (trng_mon_rc_status1),
        .mon_ap_status0   (trng_mon_ap_status0),
        .mon_ap_status1   (trng_mon_ap_status1),
        .initialized      (trng_initialized),
        .ap_detect        (trng_ap_detect),
        .rc_detect        (trng_rc_detect)
    );

    // ---------------------------------------------------------------
    // AHB master mux — only one engine active at a time
    // ---------------------------------------------------------------
    always_comb begin
        if (sha_busy) begin
            m_haddr  = sha_haddr;  m_htrans = sha_htrans;
            m_hwrite = sha_hwrite; m_hsize  = sha_hsize;
            m_hwdata = sha_hwdata;
        end else if (vu_busy) begin
            m_haddr  = vu_haddr;  m_htrans = vu_htrans;
            m_hwrite = vu_hwrite; m_hsize  = vu_hsize;
            m_hwdata = vu_hwdata;
        end else begin
            // Default: AES (also covers idle — HTRANS=IDLE when AES is idle)
            m_haddr  = aes_haddr;  m_htrans = aes_htrans;
            m_hwrite = aes_hwrite; m_hsize  = aes_hsize;
            m_hwdata = aes_hwdata;
        end
    end

endmodule
