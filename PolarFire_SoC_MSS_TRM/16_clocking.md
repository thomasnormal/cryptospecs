# 9. Clocking

<!-- page 45 -->
Clocking
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 145
9. Clocking  (Ask a Question)
An off-chip 100 MHz or 125 MHz reference clock can be fed into the following PLLs:
• MSS PLL: Generates up to 625 MHz CPU clock, 80 MHz Standby
• DDR PLL: Generates 400 MHz, actual frequency depends on the DDR type
• SGMII PLL: Generates clocks for SGMII PHY and GEMs
Important: These PLLs are located at NW corner of the device close to MSS.
On “-1” devices, the MSS PLL supports up to 667 MHz. On “STD” devices, MSS
PLL supports up to 625 MHz.
These PLLs are used to generate the main clocks for the various blocks in the MSS. The majority
of the MSS is clocked from a 600 MHz or less (CPU)/300 MHz or less (AMBA subsystem) clock
derived from the MSS PLL through a clock divider.
The CPU cores, L2 Cache, and AMBA infrastructure are clocked from the MSS PLL through a set
off dividers. During normal operation, the PLL clock is divided by 1 for the CPU cores, by 2 for the
L2 Cache and AXI bus, and by 4 for the AHB/APB bus.
At power-up and after MSS Reset, the MSS is clocked from the on-chip 80 MHz RC oscillator.
This clock source can be switched to the MSS clock source dynamically during boot-up using
the embedded firmware running on E51. There is no switching of clock sources at device power-
up;the MSS PLL remains operational.
The SGMII PLL generates the necessary clocks required for the SGMII PHY block.
The DDR PLL generates the necessary clocks required for the DDR PHY and for the DFI interface
to the DDR controller in the MSS.
Five clocks are sourced from the FPGA fabric into the MSS. These five clocks are fed into the
DLLs of FICs to enable direct clocking of signals at each fabric interface with sufficient setup and
hold times (only when the clock frequency is greater than 125 MHz). DLLs are not used if the
clock frequency is below 125 MHz. For clock frequency below 125 MHz, the clocks from the fabric
are used directly with positive to negative edge clocking to ensure setup and hold times in both
directions. These five clocks may be sourced from global clock lines in the fabric.
For more information about MSS Clocking, see PolarFire Family Clocking Resources User Guide.
