// AES Internal State Machine SVA Checker
// Bound into aes_accel_top. All DUT signals passed as ports.

module aes_internal_sva (
    input logic        clk,
    input logic        rst_n,
    input logic [1:0]  typ_state,
    input logic        trigger_start,
    input logic        dma_enable,
    input logic        core_done,
    input logic        core_busy,
    input logic        irq,
    input logic        int_ena,
    input logic        irq_pending,
    input logic [255:0] reg_key,
    input logic [2:0]  reg_mode
);

    default clocking cb @(posedge clk);
    endclocking

    default disable iff (!rst_n);

    localparam logic [1:0] TYP_IDLE = 2'b00;
    localparam logic [1:0] TYP_WORK = 2'b01;

    // C1: IDLE -> WORK on trigger in typical mode
    C1_idle_to_work: assert property (
        (typ_state == TYP_IDLE && trigger_start && !dma_enable)
        |=> (typ_state == TYP_WORK)
    ) else $error("C1: State did not transition from IDLE to WORK on trigger");

    // C2: WORK -> IDLE after core_done in typical mode
    C2_work_to_idle: assert property (
        (typ_state == TYP_WORK && core_done)
        |=> (typ_state == TYP_IDLE)
    ) else $error("C2: State did not return to IDLE after core_done");

    // C3: IRQ only when int_ena AND irq_pending
    C3_irq_gated: assert property (
        irq |-> (int_ena && irq_pending)
    ) else $error("C3: IRQ asserted without int_ena or irq_pending");

    // C4: After reset, typ_state must be IDLE
    C4_reset_idle: assert property (
        @(posedge clk) disable iff (0)
        ($rose(rst_n)) |-> (typ_state == TYP_IDLE)
    ) else $error("C4: typ_state is not IDLE after reset deasserts");

    // C5: KEY and MODE stable while core busy
    C5_key_stable: assert property (
        (typ_state == TYP_WORK) |=> (reg_key == $past(reg_key))
    ) else $error("C5: KEY register modified while core is busy");

    C5_mode_stable: assert property (
        (typ_state == TYP_WORK) |=> (reg_mode == $past(reg_mode))
    ) else $error("C5: MODE register modified while core is busy");

endmodule
