# 10. MSS Memory Map

The overall PolarFire SoC memory map consists of the following:

- CPU Core Complex address space, see Table 10-1.
- Peripherals address space, see PolarFire SoC Device Register Map.
- Memory address space, see Table 10-3.

**Table 10-1. CPU Core Complex Address Space**

| Start Address | End Address | Attributes | Description |
| --- | --- | --- | --- |
| 0x0000_0000 | 0x0000_00FF | — | Reserved |
| 0x0000_0100 | 0x0000_0FFF | RWX | Debug |
| 0x0000_1000 | 0x00FF_FFFF | — | Reserved |
| 0x0100_0000 | 0x0100_1FFF | RWXA | E51 DTIM |
| 0x0100_2000 | 0x016F_FFFF | — | Reserved |
| 0x0170_0000 | 0x0170_0FFF | RW | Bus Error Unit 0 |
| 0x0170_1000 | 0x0170_1FFF | RW | Bus Error Unit 1 |
| 0x0170_2000 | 0x0170_2FFF | RW | Bus Error Unit 2 |
| 0x0170_3000 | 0x0170_3FFF | RW | Bus Error Unit 3 |
| 0x0170_4000 | 0x0170_4FFF | RW | Bus Error Unit 4 |
| 0x0170_5000 | 0x017F_FFFF | — | Reserved |
| 0x0180_0000 | 0x0180_1FFF | RWXA | E51 Hart 0 ITIM |
| 0x0180_2000 | 0x0180_7FFF | — | Reserved |
| 0x0180_8000 | 0x0180_EFFF | RWXA | U54 Hart 1 ITIM |
| 0x0180_F000 | 0x0180_FFFF | — | Reserved |
| 0x0181_0000 | 0x0181_6FFF | RWXA | U54 Hart 2 ITIM |
| 0x0181_7000 | 0x0181_7FFF | — | Reserved |
| 0x0181_8000 | 0x0181_EFFF | RWXA | U54 Hart 3 ITIM |
| 0x0181_F000 | 0x0181_FFFF | — | Reserved |
| 0x0182_0000 | 0x0182_6FFF | RWXA | U54 Hart 4 ITIM |
| 0x0182_7000 | 0x01FF_FFFF | — | Reserved |
| 0x0200_0000 | 0x0200_FFFF | RW | CLINT |
| 0x0201_0000 | 0x0201_0FFF | RW | Cache Controller |
| 0x0201_1000 | 0x0201_FFFF | — | Reserved |
| 0x0202_0000 | 0x0202_0FFF | RW | WCB |
| 0x0202_1000 | 0x02FF_FFFF | — | Reserved |
| 0x0300_0000 | 0x030F_FFFF | RW | DMA Controller |
| 0x0310_0000 | 0x07FF_FFFF | — | Reserved |
| 0x0800_0000 | 0x081F_FFFF | RWX | L2-LIM |
| 0x0820_0000 | 0x09FF_FFFF | — | Reserved |
| 0x0A00_0000 | 0x0BFF_FFFF | RWXC | L2 Zero Device |
| 0x0C00_0000 | 0x0FFF_FFFF | RW | PLIC |
| 0x1000_0000 | 0x1FFF_FFFF | — | Reserved |

The address range 0x2000_0000 - 0x27FF_FFFF includes the default base addresses (LOW) of low-speed peripherals and base addresses of high-speed peripherals. The address range 0x2800_0000 - 0x2812_6FFF, includes the alternate base addresses (HIGH) of low-speed peripherals. The address space of peripherals is listed in Table 10-2, for a full register view of each peripheral, see PolarFire SoC Device Register Map.

**Table 10-2. Peripherals Address Space**

| Peripheral | Low Address | High Address |
| --- | --- | --- |
| MMUART0 | 0x2000_0000 | 0x2800_0000 |
| Watchdog0 | 0x2000_1000 | 0x2800_1000 |
| MMUART1 | 0x2010_0000 | 0x2810_0000 |
| Watchdog1 | 0x2010_1000 | 0x2810_1000 |
| MMUART2 | 0x2010_2000 | 0x2810_2000 |
| Watchdog2 | 0x2010_3000 | 0x2810_3000 |
| MMUART3 | 0x2010_4000 | 0x2810_4000 |
| Watchdog3 | 0x2010_5000 | 0x2810_5000 |
| MMUART4 | 0x2010_6000 | 0x2810_6000 |
| Watchdog4 | 0x2010_7000 | 0x2810_7000 |
| SPI0 | 0x2010_8000 | 0x2810_8000 |
| SPI1 | 0x2010_9000 | 0x2810_9000 |
| I2C0 | 0x2010_A000 | 0x2810_A000 |
| I2C1 | 0x2010_B000 | 0x2810_B000 |
| CAN0 | 0x2010_C000 | 0x2810_C000 |
| CAN1 | 0x2010_D000 | 0x2810_D000 |
| MAC0 | 0x2011_0000 | 0x2811_0000 |
| MAC1 | 0x2011_2000 | 0x2811_2000 |
| GPIO0 | 0x2012_0000 | 0x2812_0000 |
| GPIO1 | 0x2012_1000 | 0x2812_1000 |
| GPIO2 | 0x2012_2000 | 0x2812_2000 |
| RTC | 0x2012_4000 | 0x2012_4FFF |
| Timer | 0x2012_5000 | 0x2012_5FFF |
| H2F Interrupts | 0x2012_6000 | 0x2812_6000 |

**Table 10-3. Memory Address Space**

| Start Address | End Address | Attributes | Description |
| --- | --- | --- | --- |
| 0x3000_0000 | 0x3FFF_FFFF | RWX | IOSCB-DATA<br>CPU Core Complex - D0 (AXI Switch Master Port M10) |
| 0x3708_0000 | 0x3708_0FFF | RWX | IOSCB-CONFIGURATION |
| 0x4000_0000 | 0x5FFF_FFFF | RWX | FIC3 - 512 MB<br>CPU Core Complex - D0 (AXI Switch Master Port M10) |
| 0x6000_0000 | 0x7FFF_FFFF | RWX | FIC0 - 512 MB<br>CPU Core Complex - F0 (AXI Switch Master Port M12) |
| 0x8000_0000 | 0xBFFF_FFFF | RWXC | DDR Cached Access - 1 GB |

### Table 10-3. Memory Address Space (continued)

| Start Address | End Address | Attributes | Description |
| --- | --- | --- | --- |
| 0xC000_0000 | 0xCFFF_FFFF | RWX | DDR Non-Cached Access - 256 MB |
| 0xD000_0000 | 0xDFFF_FFFF | RWX | DDR Non-Cached WCB Access - 256 MB<br>CPU Core Complex - NC (AXI Switch Master Port M14) |
| 0xE000_0000 | 0xFFFF_FFFF | RWX | FIC1 - 512 MB<br>CPU Core Complex - F1 (AXI Switch Master Port M13) |
| 0x01_0000_0000 | 0x0F_FFFF_FFFF | — | Reserved |
| 0x1C_0000_0000 | 0x1F_FFFF_FFFF | — | Reserved |
| 0x10_0000_0000 | 0x13_FFFF_FFFF | RWXC | DDR Cached Access - 16 GB |
| 0x14_0000_0000 | 0x17_FFFF_FFFF | RWX | DDR Non-Cached Access - 16 GB |
| 0x18_0000_0000 | 0x1B_FFFF_FFFF | RWX | DDR Non-Cached WCB Access - 16 GB |
| 0x20_0000_0000 | 0x2F_FFFF_FFFF | RWX | FICO - 64 GB |
| 0x30_0000_0000 | 0x3F_FFFF_FFFF | RWX | FIC1 - 64 GB |

Note: Memory Attributes: R - Read, W- Write, X - Execute, C - Cacheable, A - Atomics.

Note: FIC2 is an AXI4 slave interface from the FPGA fabric and does not show up on the MSS memory map. FIC4 is dedicated to the User Crypto Processor and does not show up on the MSS memory map.
