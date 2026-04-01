# 8. Resets

<!-- page 44 -->
Resets
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 144
8. Resets (Ask a Question)
The MSS can be reset by any of the following sources:
• Power cycle
• System Controller
• FPGA fabric
• CPU Debugger
• E51 Watchdog
The following table lists all the Reset signals of the MSS.
Table 8-1. Reset Signals
Reason Reset
Reason Bit
Asserted By Description
SCB_PERIPH_RESET 0 SCB This is the POR signal. This signal fully resets the MSS. Additional
bits in the SOFT-RESET register also allow the SCB registers to be
reset.
SCB_MSS_RESET 1 SCB, CPU,
MSS
This signal resets the full MSS including the CPU Core Complex,
peripherals, and the entire AXI system. This signal does not reset
SCB registers.
SCB_CPU_RESET 2 SCB, CPU,
MSS
This signal resets only the CPU Core Complex. This Reset signal
must be used carefully because in most cases the MSS requires
resetting at the same time to clear outstanding AXI transactions.
DEBUGER_RESET 3 Debugger This signal is asserted by the CPU Core Complex debugger and
has the same effect as the SCB_MSS_RESET.
FABRIC_RESET 4 Fabric This is asserted by the fabric (MSS_RESET_N_F2M) and has the
same effect as the SCB_MSS_RESET. This signal can be asserted at
Power-Up to hold the MSS in reset. If not asserted at Power-Up,
this signal can be used subsequently at any stage during normal
operation to reset the MSS.
WDOG_RESET 5 Watchdog This signal indicates that the watchdog (WDOG0) Reset has
activated.
GPIO_RESET 6 Fabric This indicates that the fabric GPIO Reset was asserted, it will reset
the GPIO blocks if the GPIOs are configured to be reset by this
signal, it does not reset the MSS.
SCB_BUS_RESET 7 Fabric Indicates that SCB bus Reset occurred.
CPU_SOFT_RESET 8 MSS Indicates CPU Core Complex Reset was asserted using the soft
reset register.
For more information, see PolarFire Family Power-Up and Resets User Guide.
There is an additional register SOFT_RESET_CR, which is used to Reset all MSS peripherals after the
MSS Reset. The SOFT_RESET_CR register is described in PolarFire SoC Device Register Map. To view
the register description of SOFT_RESET_CR, follow these steps:
1. Download and unzip the register map folder.
2. Using a browser, open the pfsoc_regmap.htm file from <$download_folder>\Register
Map\PF_SoC_RegMap_Vx_x.
3. Select PFSOC_MSS_TOP_SYSREG and find the SOFT_RESET_CR register to view its description.
