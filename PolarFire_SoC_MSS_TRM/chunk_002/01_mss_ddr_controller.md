# 3.11 MSS DDR Controller

<!-- page 1: manual page 51 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 51
Table 3-50. DDR Memory Lane Support
Memory Configuration Total Data Width Lane 0 (Data) Lane 1 (Data) Lane 2 (Data) Lane 3 (Data) Lane 4 (ECC)
DDRx8 (2 die) no ECC 16 DDRx8 DDRx8
not used
DDRx16 (1 die) no ECC 16 DDRx16
DDRx8 (4 die) no ECC 32 DDRx8 DDRx8 DDRx8 DDRx8
not usedDDRx16 (2 die) no ECC 32 DDRx16 DDRx16
DDRx32 (1 die) no ECC 32 DDRx32
DDRx8 (3 die) with ECC 18 DDRx8 DDRx8
not used
DDRx8 (2 used)
DDRx16 (2 die) with ECC 18 DDRx16 DDRx16 (2 used)
DDRx8 (5 die) with ECC 36 DDRx8 DDRx8 DDRx8 DDRx8 DDRx8 (4 used)
DDRx16 (3 die) with ECC 36 DDRx16 DDRx16 DDRx16 (4 used)
Important:
• ECC is supported only for DDR3 and DDR4.
• Lane 4 is only 4-bits wide, the upper data bits on the DDR memory are not
connected.
• MSS DDR controller performs write calibration on all DQ and ECC bits as
follows:
– For DQ = x16, write calibration is performed on data bits: DQ[15:0] and
ECC bits: DQ_ECC[35:32]
– For DQ = x32, write calibration is performed on data bits: DQ[31:0] and
ECC bits: DQ_ECC[35:32]
Each data lane can be connected to a single DDR memory component or DIMM. A dual-die device is
supported for a component. The maximum supported number of memory address lines is 18 plus
two chip-enable signals (dual-rank) giving a maximum memory capacity (ignoring ECC) of 8 GB.
3.11.4.1. Supported DDR4 Memories  (Ask a Question)
The following table lists the supported DDR4 memories (not including ECC).
Table 3-51. Supported DDR4 Configurations
DDR4 Memory Max Devices Max Size
(x32 Data)
8 Gb: 512Mx16 2 2 GB
8 Gb: 1024Mx8 4 4 GB
16 Gb: 2 × 512Mx16 twin die 2 4 GB
16 Gb: 2 × 1024Mx8 twin die 4 8 GB
16 Gb: 2048Mx8 4 8 GB
Important: For DDR4, Dual Rank is supported to double the number of devices
and the maximum memory size for single die.
3.11.4.2. Supported DDR3 Memories  (Ask a Question)
The following table lists the DDR3 memories supported (not including ECC).

<!-- page 2: manual page 52 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 52
Table 3-52. Supported DDR3 Configurations
DDR3 Memory Max Devices Max Size
(x32 Data)
8 Gb: 1024Mx8 4 4 GB
8 Gb: 512Mx16 2 2 GB
Note: For DDR3, Dual Rank is supported to double the number of devices and the maximum memory size for single die.
3.11.4.3. Supported LPDDR4 Memories  (Ask a Question)
PolarFire SoC devices support LPDDR4 in single channel, single rank configurations. Single channel
devices are supported in configurations up to x32 DQ width. Dual channel devices are supported
up to x16 with DQ lanes connected in parallel (x32 DQ width) and CA buses shared across both
channels as shown in the following figure.
Figure 3-13. LPDDR4 Single Rank x32
MSS DDR
PHY
DRAM A
DRAM B
DQ[15:0]
DQ[31:16]
CA Bus/Clock
Important: LPDDR4 support is available for both 16-bit and 32-bit data widths.
PolarFire SoC devices with lesser pin count support only 16-bit data width.
3.11.4.4. Supported LPDDR3 Memories  (Ask a Question)
PolarFire SoC devices support LPDDR3 in single channel, single rank configurations. Single channel
devices are supported in configurations up to x32 DQ width. Dual channel devices can be supported
up to x16 with DQ lanes connected in parallel (x32 DQ width) and CA buses shared across both
channels as shown in the following figure.

<!-- page 3: manual page 53 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 53
Figure 3-14. LPDDR3 Single Rank x32
MSS DDR
PHY
DRAM A
DRAM B
DQ[15:0]
DQ[31:16]
CA Bus/Clock
3.11.5. Functional Description  (Ask a Question)
The MSS DDR Controller IP provides a high-performance interface to DDR3, DDR4, LPDDR3, and
LPDDR4 SDRAM devices. The MSS DDR Controller accepts read and write requests through the AXI
interfaces, and translates these requests to the command sequences required by DDR SDRAM
devices. The MSS DDR Controller performs automatic initialization, refresh, and ZQ-calibration
functions.
The following figure shows the functional blocks of the MSS DDR Controller.

<!-- page 4: manual page 54 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 54
Figure 3-15. MSS DDR Controller
Bank Management
Queue
 Control
Control
and
Timing
Data
Control
dfi_write_data_interface
dfi_read_data_interface
DDR
PHY
dfi_control_interface
dfi_status_interface
dfi_status_interfaceMulti-Burst
(Optional)
64/128-bit AXI4
Interface
3.11.5.1. Multi-Burst (Ask a Question)
The controller includes the multi-burst functionality to issue requests with a memory burst size. The
multi-burst functional block also handles requests with starting addresses not aligned to a burst
boundary, and breaks those addresses as necessary to avoid wrapped data access.
3.11.5.2. Queue Control (Ask a Question)
The Controller includes a Queue Control block that accepts new requests at every clock cycle until
the queue is full. This enables the controller to look ahead into the queue to perform activates and
precharges before the upcoming read/write requests. This queue-based user interface optimizes
throughput and efficiency.
3.11.5.3. Bank Management (Ask a Question)
The controller includes bank management module(s) to monitor the status of each DDR SDRAM
bank. Banks are opened/closed only when necessary, minimizing access delays. Up to 64 banks
can be managed at one time. Read/write requests are issued with minimal idle time between
commands, typically limited only by the DDR timing specifications. This results in minimal between
requests, enabling up to 100% memory throughput for sequential accesses (not including refresh
and ZQ-calibration commands).

<!-- page 5: manual page 55 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 55
3.11.5.4. Frequency Mode  (Ask a Question)
The MSS DDR Controller can be configured such that the user interface operates at half the rate at
which the SDRAM devices are clocked. In half-rate mode, the data interface (RDATA, WDATA) is four
times the width of the physical DQ pins.
3.11.5.5. ECC  (Ask a Question)
ECC is supported only for DDR3 and DDR4. When ECC is enabled, the DDR controller computes
a 4-bit ECC for every 32-bit data to support SECDED. A write operation computes and stores an
ECC along with the data, and a read operation reads and checks the data against the stored
ECC. Therefore, when ECC is enabled, single or double-bit errors may be received when reading
uninitialized memory locations. To prevent this, all memory locations must be written to before
being read. ECC can be enabled using the Standalone MSS Configurator -> DDR Memory -> DDR
Topology tab.
3.11.5.6. Address Mapping  (Ask a Question)
The AXI interface address is mapped based on the type of the Address Ordering selected during the
DDR Configuration. The address ordering can be selected using the Standalone MSS Configurator ->
DDR Memory -> Controller Options tab. For example, if Chip-Row-Bank-Col is selected, and if a row
address width and column address width is configured for 13 and 11, the AXI address is mapped as
shown in the following table.
Table 3-53. AXI Address Mapping
AXI Address 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 0
Column Address C10 C9 C8 C7 C6 C5 C4 C3 C2 C1 C0
Bank Address BA2 BA1 BA0
Row Address R12 R11 R10 R9 R8 R7 R6 R5 R4 R3 R2 R1 R0
3.11.5.7. DDR PHY  (Ask a Question)
The DDR PHY is included in the MSS DDR I/O Bank 6, which consists of I/O lanes and the training
logic. The integrated PHY provides a physical interface to DDR3, DDR4, LPDDR3, and LPDDR4 SDRAM
devices. It receives commands from the DDR controller and generates the DDR memory signals
required to access the external DDR memory. The training logic manages DFI 4.0 training requests
between the I/O lane and the DDR controller.
3.11.5.8. Clocking Structure  (Ask a Question)
The DDR PLL, external to the MSS, generates the required clocks for the MSS DDR Controller and
the DDR PHY. These clocks are distributed throughout the subsystem using HS_IO_CLK routes,
dedicated pads, and fabric clock routing. The DDR PLL sources the reference frequency from an
off-chip 100/125 MHz oscillator.
The PLL generates the following clocks:
• DDR PHY Clock (800 MHz maximum)— This clock is routed to the PHY for clocking the DDR
memory device.
• HS_IO_CLK— This clock routed to DDR I/O lanes and the training logic
• HS_IO_CLK_270— HS_IO_CLK phase shifted by 270. This clock is also routed to I/O lanes and the
training logic
• SYS_CLK— This clock is routed to the DDR controller, training logic, and user logic in the fabric.
The HS_IO_CLK and REF_CLK clocks are generated with the same frequency and phase. The
REF_CLK to SYS_CLK ratio is 4:1.
3.11.5.9. Initialization Sequence  (Ask a Question)
The following steps summarize the initialization sequence of the MSS DDR Controller:
The asynchronous SYS_RESET_N and PLL_LOCK signals are de-asserted.
The E51 monitor core initializes the MSS DDR Subsystem.

<!-- page 6: manual page 56 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 56
The MSS_RESET_N_M2F signal is asserted to indicate that initialization is completed. This signal can
be monitored from the fabric.
3.11.6. MSS DDR Subsystem Ports (Ask a Question)
MSS DDR Controller ports (or signals) are available on the PFSOC_MSS SgCore IP. These ports are
exposed only when the DDR options are configured in the standalone MSS Configurator. The MSS
DDR subsystem ports are categorized into the following groups:
• Generic Signals—Required for MSS and DDR input clock sources, asserting MSS reset, CPU and
DDR PLL lock assertion.
• SDRAM Interface Signals—Required for connecting to the DDR SDRAM.
Figure 3-16. MSS DDR Subsystem Ports
MSS DDR
Subsystem
SDRAM
Interface
MSS_SYS_RESET_N_F2M
MSS/DDR REF_CLKs
PLL_CPU_LOCK
PLL_DDR_LOCK
MSS_SYS_
RESET_N_M2F
Note: The AXI interface is exposed when FICs are enabled in the standalone MSS Configurator.
3.11.6.1. Generic Signals  (Ask a Question)
The following table lists the generic signals of the MSS DDR Subsystem.
Table 3-54. Generic Signals
Signal Name Direction Description
REF_CLK REF_CLK_N Input Input PADs for reference clock source. The PADs can be connected to a
100/125 MHz off-chip oscillator.
MSS_SYS_RESET_N_F2M Input Active-low asynchronous MSS reset. MSS_SYS_RESET_N_F2M must be
connected to the DEVICE_INIT_DONE signal of the PFSOC_INIT_MONITOR
IP.
REFCLK_0_PLL_NW (optional) Input Reference clock to the MSS/ DDR PLL.
MSS_RESET_N_M2F Output Active-low MSS Reset signal for the fabric logic.
PLL_CPU_LOCK_M2F Output Lock signal to indicate that the MSS PLL is locked on to the reference
clock.
PLL_DDR_LOCK_M2F Output Lock signal to indicate that the DDR PLL is locked on to the reference
clock.
3.11.6.2. SDRAM Interface Signals (Ask a Question)
The following table lists the SDRAM interface signals.
Table 3-55. SDRAM Interface Signals1
Signal Name Direction Description
CK Output Positive signal of differential clock pair forwarded to SDRAM.

<!-- page 7: manual page 57 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 57
Table 3-55. SDRAM Interface Signals1 (continued)
Signal Name Direction Description
CK_N Output Negative signal of differential clock pair forwarded to SDRAM.
RESET_N Output SDRAM reset. Supported only for DDR3 and DDR4.
A[15:0] Output Address bus2. Sampled during the active, precharge, read, and write commands. Also
provides the mode register value during MRS commands.
BA[2:0] Output Bank address. Sampled during active, precharge, read, and write commands to
determine which bank the command is to be applied to. Supported only for DDR3
and DDR4.
For DDR4, bus width is 2 bits.
For DDR3, bus width is 3 bits.
BG[1:0] Output DDR bank group address for DDR4 only.
CS_N Output SDRAM Chip Select (CS).
CKE Output SDRAM clock enable. Held low during initialization to ensure SDRAM DQ and DQS
outputs are in the hi-Z state.
RAS_N3 Output SDRAM row address strobe command. Supported only for DDR3 and DDR4.
CAS_N3 Output SDRAM column access strobe command. Supported only for DDR3 and DDR4.
WE_N3 Output SDRAM write enable command. Supported only for DDR3 and DDR4.
ACT_N3 Output Activation signal for the following commands along with CS_N:
• SDRAM row address strobe command (RAS_N)
• SDRAM column address strobe command (CAS_N)
• SDRAM write enable command (WE_N)
This signal is only for DDR4 as per the JEDEC_DDR4_JESD79-4 standard.
ODT Output On-die termination control. ODT is asserted during reads and writes according to the
ODT activation settings in the standalone MSS Configurator.
PAR Output Command and address parity output. Supported only for DDR4.
ALERT_N Input Alert signaling command/address parity or write CRC error. Supported only for DDR4.
DQ Bidirectional SDRAM data bus. Supports 16-bit and 32-bit DDR SDRAM data buses.
DQ_ECC4 Bidirectional SDRAM ECC data bus.
• When the DQ width is x16 with ECC enable, ECC is 4-bit wide (DQ_ECC[35:32]).
• When the DQ width is x32 with ECC enable, ECC is 4-bit wide (DQ_ECC[35:32]).
DM/DM_N Output Write data mask. DM for DDR3/LPDDR3 and DM_N for DDR4.
DQS Bidirectional Strobes data into the SDRAM devices during writes and into the DDR subsystem
during reads.
• When the DQ width is x16, DQS is 2-bit wide (DQS[1:0])
• When the DQ width is x32, DQS is 4-bit wide (DQS[3:0])
DQS_ECC Bidirectional DQS ECC signals. For both x16 and x32 DQ widths, DQS_ECC is one 4-bit DQ lane for
ECC.
DQS_ECC_N Bidirectional Complimentary DQS ECC signals. For both x16 and x32 DQ widths, DQS_ECC_N is one
4-bit DQ lane for ECC.
DQS_N Bidirectional Complimentary DQS.
• When the DQ width is x16, DQS_N consists of two 8-bit DQ lanes, not including
ECC lane (DQS_N[1:0]).
• When the DQ width is x32, DQS_N consists of four 8-bit DQ lanes, not including
ECC lane (DQS_N[3:0]).

<!-- page 8: manual page 58 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 58
Notes:
1. SHIELD signals are not available in the MSS DDR controller because it has dedicated I/O Banks to
interface with the DDR memory.
2. In general, the number of address bits for different memory types are as follows:
– For LPDDR3, it is 10 bits
– For DDR3, it is 16 bits
– For DDR4, it is 14 bits
The number of address bits varies based on different memory configurations. For example,
when DDR4 is used in 32Gbx16 configuration, 17 row address bits are used (not 14 address bits).
3. RAS_N, CAS_N, and WE_N signals, along with CS_N, are multifunction pins. When ACT_N is Low,
they function as address pins A16, A15, and A14 respectively. When ACT_N is High, they function
as command pins for Read, Write, and other commands defined in the command truth table.
This multifunction only applies to DDR4.
4. The DQ_ECC signal is exposed only when the Enable ECC option is selected in the PolarFire SoC
Standalone MSS Configurator > DDR Memory > DDR Topology.
3.11.7. Functional Timing Diagrams (Ask a Question)
To be updated.
3.11.8. Implementation (Ask a Question)
For more information about MSS DDR implementation in the PolarFire SoC FPGA design, see
Standalone MSS Configurator User Guide for PolarFire SoC.
3.11.9. Functional Examples  (Ask a Question)
Masters from the MSS and fabric can access the DDR memory using the MSS DDR Subsystem. The
following functional examples describe these scenarios.
• Accessing DDR Memory from the MSS
• Accessing DDR Memory from Fabric
3.11.9.1. Accessing DDR Memory from the MSS  (Ask a Question)
Processor cores access DDR memory using the MSS DDR Subsystem through Seg0 (Segmentation
block) as shown in the following figure.
Figure 3-17. Functional Example - 1
DDRx
SDRAM
CPU Core Complex
PolarFire ®  SoC MSS
Seg0
MSS DDR
Controller
1x E51
4x U54
L2
Cache
AXI4
(128-bit)

<!-- page 9: manual page 59 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 59
For the overall PolarFire SoC MSS memory map which covers the memory map of the
CPU Core Complex, L2 Cache, Seg0 Segmentation block, and the MSS DDR Controller, see
MSS Memory Map.
3.11.9.2. Accessing DDR Memory from Fabric (Ask a Question)
AXI4 masters implemented in the fabric access the DDR memory through FIC0 (Fabric Interface
Controller), the AXI Switch, and the MSS DDR Subsystem, as shown in the following figure.
Figure 3-18. Functional Example - 2
DDRx
SDRAM
FIC0
FPGA Fabric PolarFire ®  SoC MSS
AXI
Switch
MSS DDR
Controller
S7M1M
AXI
Master
M Seg1
S8 L2
Cache (Cached)
(UnCached)
For the overall PolarFire SoC MSS memory map which covers the memory map of FIC0, CPU Core
Complex, AXI Switch, and Seg1 segmentation block, and the MSS DDR Controller (cached and
uncached), see MSS Memory Map.
3.12. Peripherals (Ask a Question)
The MSS includes the following peripherals:
• CAN Controller (x2)
• eNVM Controller
• eMMC SD/SDIO
• Quad SPI with XIP
• MMUART (x5)
• SPI Controller (x2)
• I2C (x2)
• GPIO (x3)
• Real-time Counter (RTC)
• Timer
• Watchdog (x5)
• Universal Serial Bus OTG Controller (USB)
• FRQ Meter
• M2F Interrupt Controller
• Gigabit Ethernet MAC (GEM x2)

<!-- page 10: manual page 60 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 60
Important:
• MSS peripherals are Reset using the SOFT_RESET_CR system register.
The register description of SOFT_RESET_CR is available under
PFSOC_MSS_TOP_SYSREG in the PolarFire SoC Device Register Map.
• Driver example projects of MSS peripherals are available in GitHub.
This section describes features and functional description of the preceding peripherals. For more
information about configuring the preceding peripherals, see Standalone MSS Configurator User
Guide for PolarFire SoC.
The following figure shows the MSS peripherals.
Figure 3-19. Peripherals Block Diagram
MSS Core Complex
AXI Switch
AXI to AHB
AHB to APB
MMUART ×5 SPI ×2 I2C ×2 GPIO ×3 CAN ×2
TIMERFRQ Meter WatchDog
×5
M2F
Interrupt
Controller RTC eMMC
SD/SDIO
GEM x2
DDR
Controller
IO MUX
FPGA Fabric
UserCrypto USB 2.0eNVM QSPI-XIP
DDR PHY
MSSIOs
MPU
AHB to AXI
3.12.1. Memory Map  (Ask a Question)
The PolarFire SoC MSS peripheral memory map is described in PolarFire SoC Device Register Map.
Follow these steps:
1. Download and unzip the register map folder.
