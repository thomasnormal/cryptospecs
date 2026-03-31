# 2. Detailed Block Diagram

<!-- page 7 -->
Detailed Block Diagram



2.   Detailed Block Diagram (Ask a Question)
     The MSS includes the following blocks:
     •   CPU Core Complex
     •   AXI Switch
     •   Fabric Interface Controllers (FICs)
     •   Memory Protection Unit
     •   Segmentation Blocks
     •   AXI-to-AHB
     •   AHB-to-APB
     •   Asymmetric Multi-Processing (AMP) APB Bus
     •   MSS I/Os
     •   User Crypto Processor
     •   MSS DDR Memory Controller
     •   Peripherals
     The following figure shows the functional blocks of the MSS in detail, the data flow from the CPU
     Core Complex to peripherals and vice versa.




                                               Technical Reference Manual                          DS60001702Q - 7
                                  © 2025 Microchip Technology Inc. and its subsidiaries

<!-- page 8 -->
![Figure 2-1: MSS Detailed Block Diagram](figures/figure-002.png)

Notes:
- All AXI buses with red dot are fed into the Trace Block for monitoring.
- The direction of arrows indicates control (master to slave).
- The flow of data is bi-directional: AXI 32/64-bit, AXI 64-bit, AHB 32-bit, APB 32-bit.

Legend:
- Coherence Manager (CM) Link
- AXI Master
- AXI Slave
- AHB
- APB
