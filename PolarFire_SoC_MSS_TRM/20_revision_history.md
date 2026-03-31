# 12. Revision History

The revision history describes the changes that were implemented in the document. The changes are listed by revision, starting with the most current publication.

## Revision Q (05/2025)

The following list of changes are made in revision Q of the document.

- Added a reference to *PolarFire Family System Service User Guide* in References for information about how MSS communicates with the System Controller.
- Updated *Physical Memory Protection* by adding a note to reference the PMP example project in GitHub.
- Added information related to the arbitration scheme in *TileLink*.
- Removed all references to SoftConsole supporting the Trace functionality.
- Updated the width of the DQ_ECC signal to 4-bit when DQ width is x16, see the note in *Supported Configurations*.
- Updated the width of the DQ_ECC signal to 4-bit when DQ width is x16, see *Table 3-55*.
- Added DQS_ECC and DQS_ECC_N signals in *Table 3-55*.
- Updated the information related to the width of DQS and DQS_N signals when DQ width is x16 and x32, see *Table 3-55*.
- Updated *MAC Filter* to add more information on MAC filtering types.
- Added Broadcast Address, Hash Addressing.
- Added eMMC/SD Controller External Signals.
- Replaced the term "Sleep" with "WFI" in *Features* section.
- Added information related to MSS_INT_F2M[63:0] interrupts in *Functional Description*.

## Revision P (07/2024)

The following list of changes are made in revision P of the document.

- Added a note about the mandatory memory test to be run on all the supported memory devices.
- Provided reference to the datasheet for the MSS DDR performance, see *Performance*.
- Added GitHub links to driver examples for external Flash memories, see *MSS I/Os*.
- Added GitHub link to driver examples of MSS peripherals, see *Peripherals*.
- Updated the BASE address alignment requirement of mtvec interrupt CSR to 256-byte in vectored interrupt mode. See *Table 5-7* in *Machine Trap Vector Register (mtvec)*.

## Revision N (03/2024)

The following list of changes are made in revision N of the document.

- Added information about the L2 ECC operation in *L2 ECC*.
- Updated the Note in *Supported Configurations* as follows:

  > "MSS DDR controller performs write calibration on all DQ and ECC bits as follows:
  >
  > - For DQ = x16, write calibration is performed on data bits: DQ[15:0] and ECC bits: DQ_ECC[33:32]
  > - For DQ = x32, write calibration is performed on data bits: DQ[31:0] and ECC bits: DQ_ECC[35:32]"
  >
  > from
  >
  > "MSS DDR controller performs the write calibration on all bits in the ECC lane. The ECC bits must always be on DQ[35:32] as follows:
  >
  > - DQ = x32, data bits are DQ[31:0] and ECC bits are DQ[35:32]
  > - For DQ = x16, data bits are DQ[15:0] and ECC bits are DQ[33,32]"

## Revision M (01/2024)

The following list of changes are made in revision M of the document.

- Added footnotes under *Table 3-55*.
- Added a new signal "DQ_ECC" in *Table 3-55*.
- Added the "ACT_N" signal in *Table 3-55*.
- Updated the Note in *Supported Configurations* as follows:

  > "MSS DDR controller performs the write calibration on all bits in the ECC lane. The ECC bits must always be on DQ_ECC[35:32] as follows:
  >
  > - DQ = x32, data bits are DQ[31:0] and ECC bits are DQ[35:32]
  > - For DQ = x16, data bits are DQ[15:0] and ECC bits are DQ_ECC[33,32]"
  >
  > from
  >
  > "MSS DDR controller performs the write calibration on all used bits in the ECC lane. The ECC bits must always be on DQ[35:32] as follows:
  >
  > - DQ = x32, data bits are DQ[31:0] and ECC bits are DQ[35:32]
  > - For DQ = x16, data bits are DQ[15:0] and ECC bits are DQ[33,32]"

## Revision L (11/2023)

The following list of changes are made in revision L of the document.

- Updated the note in *PolarFire SoC Gigabit Ethernet MAC* by providing a link to *PolarFire SoC Datasheet* for information on the ppm accuracy.
- Updated *RTC Counter* as follows:
  - Changed the number of seconds lost per 24 hours to 8 seconds.
  - Added equations for calculating the number of seconds lost in 24 hours due to a deviation of the external reference frequency.
- Updated *Table 3-51* as follows:
  - Changed the order of entries.
  - Updated the maximum size of DDR4 memory configuration of 2048Mx8 to 8 GB.

## Revision K (09/2023)

The following list of changes are made in revision K of the document.

- In *Supported Configurations*, updated the third point in the Note to “MSS DDR controller performs the write calibration on all used bits in the ECC lane. The ECC bits must always be on DQ[35:32] as follows:
  - DQ = x32, data bits are DQ[31:0] and ECC bits are DQ[35:32]
  - For DQ = x16, data bits are DQ[15:0] and ECC bits are DQ[33,32]”
  from
  “In PolarFire SoC MSS Configurator, when the DQ width is set to 16 with ECC enabled, four extra pins DQ[16], DQ[17], DQ[18], and DQ[19] are available. In this case, DQ[16] and DQ[17] are used for ECC, while DQ[18] and DQ[19] are used for write calibration in training.”
- Added *Transmit DMA Buffers* and *Receive DMA Buffers* to describe the Tx and Rx buffer descriptors of the GEM block.

## Revision J (08/2023)

The following list of changes are made in revision J of the document.

- Updated *Figure 2-1* by making the arrows, from each Hart to TileLink, bidirectional.
- Added the following information in *DMA Memory Map*:
  - Added a link to CPU Core Complex address space
  - Updated “DMA Base Address” to “DMA Controller Base Address” in *Table 3-15*.
- Updated *Table 3-50*.
- Added the following information in *Features*:
  - Added Default Speed, Low Speed, and Full Speed in SD/SDIO supported standards.
  - Removed “DDR52” from the supported eMMC standards.
  - Added a note to mention the supported data rates for eMMC speed modes.
  - Added a note to mention the supported data rates for SD/SDIO speed modes.
- Added *Measurable Clocks* in *FRQ Meter*.
- Updated *Figure 5-1* to show that two External interrupt signals—M mode External interrupt and S mode External interrupt—from the PLIC are sent to each Hart.
- Added information about the secure boot support in *Boot Process*.

## Revision H (03/2023)

The following list of changes are made in revision H of the document.

- Updated the description of FIC2 in *Table 6-1*.
- Added *Boot Modes Fundamentals*.
- Added information about clock generation in *Serial Clock Generator*.

## Revision G (02/2023)

The following list of changes are made in revision G of the document.

- Added *Table 10-2*.
- Added a note about TileLink under *Figure 1*.
- Added *eNVM Address and Segments* and *eNVM Access Capabilities*.
- Removed a statement, from *Features*, that mentions that the Reset state of the GPIOs is configurable.

## Revision F (11/2022)

The following list of changes are made in revision F of the document.

- Removed the note regarding system controller from *Appendix A: Acronyms*.
- Updated the cross-reference in *L2 ECC* to correctly point to the L2-cache interrupts going to PLIC.
- Added a table footnote about ECC support in *Table 3-49*.
- Added a note that mentions the clock frequency offset supported by the GEM blocks, see *PolarFire SoC Gigabit Ethernet MAC*.
- Added DDR3L as one of the supported devices by MSS DDR Memory Controller across the document.
- Added information about SYSREG and SCBSYSREG system registers, see *System Registers*.
- Renamed ecc_error and ecc_correct interrupts to peripheral_ecc_error and peripheral_ecc_correct in *Table 5-1*. Also, added a table footnote describing how to implement ECC for peripherals.
- Updated the description of the exception code 7 from machine software interrupt to machine timer interrupt. See *Table 5-6*.
- Updated the number of interrupts from L2 cache to 4 in *Figure 5-1*.
- Updated the total global interrupts to 186 in *Platform Level Interrupt Controller*, *PLIC Memory Map*, *Interrupt Sources*, *Interrupt Enables*, and *Interrupt Pending Bits*.
- Updated section *Timer Registers (mtime)*.
- Added *Figure 6-2* to show the simulation write and read transactions to non-cached DDR region.
- Updated *FIC Reset*.
- Added *Boot Modes Fundamentals* in *Boot Process*.

## Revision E (06/2022)

The following list of changes are made in revision E of the document.

- Added *Branch Prediction*.
- Added the following information in *AXI Switch*:
  - Added *Table 3-34* that describes Master and Slave connectivity.
  - Added *Table 3-35* that lists the address ranges of each slave port on the AXI switch.
- Added a note regarding the rules which apply during the selection I/Os of MSS peripherals, see *MSS I/Os*.
- Added a note that describes the DDR I/O setting when DQ width is set to 16 with ECC enabled, see *Supported Configurations*.
- Added a note regarding SHIELD signals under *Table 3-55*.

## Revision D (05/2022)

The following list of changes are made in revision D of the document.

- Enabled ‘Ask A Question’ hyperlink for each section in the document.
- Updated the description of the FABRIC_RESET signal, see *Table 8-1*.
- Added a note on routing MSS I2C I/O to Fabric, see *Functional Description*.

## Revision C (12/2021)

The following list of changes are made in revision C of the document.

- Updated the fabric to MSS interrupt name from “fabric_f2h” to “MSS_INT_F2M” in *Table 5-1*.
- Added the minimum AHB or APB clock frequency requirement for driving eNVM. See *AXI-to-AHB*.
- Updated DDR3 and LPDDR3 speed in *Performance*.
- Removed MSS-specific power management information from *Clocking*.
- Added information about SOFT_RESET_CR system register, which is used to Reset all MSS peripherals in *Resets* and *Peripherals*.
- Updated the *Boot Process* section to include information about MSS boot modes.
- Updated the *Bus Error Unit (BEU)* section to mention that BEUs are used for reporting errors only in L1 instruction and data caches.
- Updated the information about how to reset FICs, see *FIC Reset*.

## Revision B (08/2021)

The following list of changes are made in revision B of the document.

- Updated table *Table 3-51*.
- Added *System Registers*.
- Removed memory and peripherals addresses from *Table 10-1* and renamed the table title to “CPU Core Complex Address Space”.
- Added *Table 10-3*.
- In *MSS Memory Map*, added steps to describe how to use *PolarFire SoC Device Register Map*.
- Throughout the document, removed peripherals memory map and pointed to *PolarFire SoC Device Register Map*.

## Revision A (04/2021)

The following list of changes are made in revision A of the document.

- Converted the document type to MSS Technical Reference Manual from MSS User Guide.
- Document converted to Microchip format and document number changed from UG0880 to DS60001702A.

## Revision 3.0 (09/2020)

The following list of changes are made in revision 3.0 of the document.

- Updated for Libero SoC v12.5.
- Updated *Clocking*.
- Added *AXI Switch Arbitration*.
- Updated *Write Combining Buffer (WCB)*.
- Added PMP register usage information, see *Physical Memory Protection*.

## Revision 2.0 (04/2020)

The following list of changes are made in revision 2.0 of the document.

- Updated the detailed MSS Block diagram, see *Figure 2-1*.
- Added *Debug CSRs*, *Breakpoints*, and *Debug Memory Map*.
- Added *Write Combining Buffer (WCB)*.
- Added the CPU memory map to the MSS memory map, see *Table 10-1*.
- Updated FIC1 information, see *Fabric Interface Controllers (FICs)* and *Table 6-1*.

## Revision 1.0 (10/2019)

This the first publication of this document.
