# 4. System Registers

The MSS contains the following system registers:

- CPU Core Complex Registers: These system registers are available within the CPU Core Complex to configure the CPU Core Complex. These registers are listed in Table 10-1.
- SYSREG: These system registers are connected to the APB bus and can be accessed by the CPU Core Complex or by other masters connected to the AXI switch. These system registers are used to configure the MSS clocks, interrupts, MSS I/Os, MSS reset, ECC events for peripherals, L2 cache low-power mode, MSS I/O MUXing, AHB-to-APB bridges, AXI-to-AHB bridges, eNVM controller, MSS boot events, other functionalities. For more information about the description and address map of these registers, see PolarFire SoC Device Register Map. To open PolarFire SoC Device Register Map, follow these steps:
  a. Download and unzip the register map folder.
  b. Using a browser, open the `pfsoc_regmap.htm` file from `<$download_directory>\PolarFireSoc_Register_Map\PF_SoC_RegMap`.
  c. Select `PFSOC_MSS_TOP_SYSREG` to view the subsequent register descriptions and details.
- SCBSYSREG: These system registers are connected to the device perimeter IO SCB bus. These registers are directly controlled and clocked by the SCB bus, the CPU Core Complex can access these registers. These system registers are used to configure the boot address, boot ROM, MPU, MSS soft reset, AXI Switch transactions, trace and debug connectivity, and other functionalities. For more information about the description and address map of these registers, see PolarFire SoC Device Register Map. To open PolarFire SoC Device Register Map, follow these steps:
  a. Using a browser, open the `pfsoc_regmap.htm` file from `<$download_directory>\PolarFireSoc_Register_Map\PF_SoC_RegMap`.
  b. Select `SYSREGSCB` to view the subsequent register descriptions and details.
