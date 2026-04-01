# 1. PolarFire SoC MSS Features

<!-- page 6 -->
PolarFire SoC MSS Features



1.   PolarFire SoC MSS Features (Ask a Question)
     The following table lists the features of PolarFire SoC MSS.

     Table 1-1. MSS Features
     Feature                                       Description
     E51 RISC-V Monitor Core (1x)                  RV64IMAC, 625 MHz, 16 KB L1 iCache or 8 KB ITIM, and 8 KB DTIM. Machine (M)
                                                   and User (U) modes
     U54 RISC-V Application Cores (4x)             RV64GC1, 625 MHz, 32 KB L1 iCache or 28 KB ITIM. 32 KB dCache, Sv39 MMU, M,
                                                   Supervisor (S), and U modes
     L2 Cache                                      2 MB L2 cache or 1.875 MB LIM with ECC
     BootFlash                                     128 KB eNVM
     Physical Memory Protection                    PMP block per processor core with 16x regions with a granularity of 4 bytes
     Interrupts                                    48 local interrupts per processor core (M and S mode)
                                                   169 external interrupts (platform level) (M and S mode)
                                                   Software and Timer local interrupt per processor core (M mode)

     DMA Engine                                    4x independent DMA channels
     Bus Error Unit (BEU)                          BEU per processor core for L1 iCache/dCache ECC and TileLink bus errors
     Hardware Performance Monitor                  Performance monitoring CSRs per processor core
     TileLink                                      TileLink B64 and D128 switch for I/O and memory coherency
     Debug                                         JTAG based debug block for debugging all processor cores
     Trace                                         Trace block for instruction trace for all processor cores

     Memory Protection Unit                        MPU block for each external AXI Master
     Fabric Interface Controllers (FICs)           64-bit AXI4 FIC (3x), 32-bit APB FIC (1x)
     User Crypto Processor                         Athena F5200 TeraFire Crypto Processor (1x), 200 MHz
     Secure Boot                                   Support for all U54 cores and E51 core
     Anti-tamper Protection                        Anti-tamper mesh for the MSS to detect tamper events
     MSS DDR Memory Controller (1x) with           MSS DDR memory controller with support for DDR3, DDR3L, DDR4, LPDDR3, and
     ECC                                           LPDDR4 memory devices.
     Peripherals                                   Gigabit Ethernet MAC (GEM 2x), USB OTG 2.0 controller (1x), QSPI-XIP (1x), SPI (2x),
                                                   eMMC 5.1 (1x), SD (1x), and SDIO (1x), MMUART (5x), I2C (2x), CAN (2x), GPIO (3x),
                                                   RTC (1x), FRQMeter, Watchdogs (5x), and Timer (2x32 bit).
     MSS I/Os                                      38 MSS I/Os to support peripherals.

     Note:
     1. In RV64GC “G” = “IMAFD”




                                                       Technical Reference Manual                                         DS60001702Q - 6
                                           © 2025 Microchip Technology Inc. and its subsidiaries
