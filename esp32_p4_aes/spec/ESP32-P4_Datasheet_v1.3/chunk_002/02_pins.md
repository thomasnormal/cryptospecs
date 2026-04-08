# 2 Pins

## 2.1 Pin Layout

![Figure 2-1. ESP32-P4 Pin Layout (Top View)](figures/figure-002.png)

## 2.2 Pin Overview

The ESP32-P4 chip integrates multiple peripherals that require communication with the outside world. To keep the chip package size reasonably small, the number of available pins has to be limited. So the only way to route all the incoming and outgoing signals is through pin multiplexing. Pin muxing is controlled via software programmable registers (see *ESP32-P4 Technical Reference Manual* > Chapter *GPIO Matrix and IO MUX*). In addition, ESP32-P4 has a number of pins that are dedicated to certain peripherals, such as MIPI DSI and CSI, and cannot be used for general-purpose IO.

All in all, the ESP32-P4 chip has the following types of pins:

- **IO pins** with the following predefined sets of functions to choose from:
  - Each IO pin has predefined **IO MUX functions** – see Table 2-3 *IO MUX Functions*
  - Some IO pins have predefined **LP IO MUX functions** – see Table 2-5 *LP IO MUX Functions*
  - Some IO pins have predefined **analog functions** – see Table 2-7 *Analog Functions*

  *Predefined functions* means that each IO pin has a set of direct connections to certain signals from on-chip components. During run-time, the user can configure which component signal from a predefined set to connect to a certain pin at a certain time via memory mapped registers.

- **Dedicated interface pins** can only be used by certain peripherals, such as flash, MIPI DSI, and MIPI CSI – see Table 2-9 *Dedicated Interface Pins*
- **Analog pins** that have exclusively-dedicated analog functions – see Table 2-10 *Analog Pins*
- **Power pins** that supply power to the chip components and non-power pins – see Table 2-11 *Power Pins*

Table 2-1 *Pin Overview* gives an overview of all the pins. For more information, see the respective sections for each pin type below, or Appendix A – *ESP32-P4 Consolidated Pin Overview*.

Table 2-1. Pin Overview

| Pin No. | Pin Name | Pin Type | Pin Providing Power^2,3 | Pin Settings^4 At Reset | Pin Settings^4 After Reset | Pin Function Sets^1 IO MUX | Pin Function Sets^1 LP IO MUX | Pin Function Sets^1 Analog |
|---|---|---|---|---|---|---|---|---|
| 1 | GPIO1 | IO | VDD_LP / VDD_BAT | – | – | IO MUX | LP IO MUX | Analog |
| 2 | GPIO2 | IO | VDD_LP / VDD_BAT | – | IE, WPU^5 | IO MUX | LP IO MUX | Analog |
| 3 | GPIO3 | IO | VDD_LP / VDD_BAT | – | IE | IO MUX | LP IO MUX | Analog |
| 4 | GPIO4 | IO | VDD_LP | – | IE | IO MUX | LP IO MUX | Analog |
| 5 | GPIO5 | IO | VDD_LP | – | – | IO MUX | LP IO MUX | Analog |
| 6 | GPIO6 | IO | VDD_LP | – | – | IO MUX | LP IO MUX | Analog |
| 7 | GPIO7 | IO | VDD_LP | – | – | IO MUX | LP IO MUX | Analog |
| 8 | GPIO8 | IO | VDD_LP | – | – | IO MUX | LP IO MUX | Analog |
| 9 | VDD_LP | Power | – | – | – | – | – | – |
| 10 | GPIO9 | IO | VDD_LP | – | – | IO MUX | LP IO MUX | Analog |
| 11 | GPIO10 | IO | VDD_LP | – | – | IO MUX | LP IO MUX | Analog |
| 12 | GPIO11 | IO | VDD_LP | – | – | IO MUX | LP IO MUX | Analog |
| 13 | GPIO12 | IO | VDD_LP | – | – | IO MUX | LP IO MUX | Analog |
| 14 | GPIO13 | IO | VDD_LP | – | – | IO MUX | LP IO MUX | Analog |
| 15 | GPIO14 | IO | VDD_LP | – | – | IO MUX | LP IO MUX | Analog |
| 16 | GPIO15 | IO | VDD_LP | – | – | IO MUX | LP IO MUX | Analog |
| 17 | GPIO16 | IO | VDD_IO_0 | – | – | IO MUX | – | Analog |
| 18 | GPIO17 | IO | VDD_IO_0 | – | – | IO MUX | – | Analog |
| 19 | GPIO18 | IO | VDD_IO_0 | – | – | IO MUX | – | Analog |
| 20 | GPIO19 | IO | VDD_IO_0 | – | – | IO MUX | – | Analog |
| 21 | VDD_IO_0 | Power | – | – | – | – | – | – |
| 22 | GPIO20 | IO | VDD_IO_0 | – | – | IO MUX | – | Analog |
| 23 | GPIO21 | IO | VDD_IO_0 | – | – | IO MUX | – | Analog |
| 24 | GPIO22 | IO | VDD_IO_0 | – | – | IO MUX | – | Analog |
| 25 | GPIO23 | IO | VDD_IO_0 | – | – | IO MUX | – | Analog |
| 26 | VDD_HP_0 | Power | – | – | – | – | – | – |
| 27 | FLASH_CS | Dedicated | VDD_FLASHIO | – | – | – | – | – |
| 28 | FLASH_Q | Dedicated | VDD_FLASHIO | – | – | – | – | – |
| 29 | FLASH_WP | Dedicated | VDD_FLASHIO | – | – | – | – | – |
| 30 | VDD_FLASHIO | Power | – | – | – | – | – | – |
| 31 | FLASH_HOLD | Dedicated | VDD_FLASHIO | – | – | – | – | – |
| 32 | FLASH_CK | Dedicated | VDD_FLASHIO | – | – | – | – | – |
| 33 | FLASH_D | Dedicated | VDD_FLASHIO | – | – | – | – | – |
| 34 | DSI_REXT | Dedicated | VDD_MIPI_DPHY | – | – | – | – | – |
| 35 | DSI_DATAP1 | Dedicated | VDD_MIPI_DPHY | – | – | – | – | – |
| 36 | DSI_DATAN1 | Dedicated | VDD_MIPI_DPHY | – | – | – | – | – |
| 37 | DSI_CLKN | Dedicated | VDD_MIPI_DPHY | – | – | – | – | – |
| 38 | DSI_CLKP | Dedicated | VDD_MIPI_DPHY | – | – | – | – | – |
| 39 | DSI_DATAP0 | Dedicated | VDD_MIPI_DPHY | – | – | – | – | – |
| 40 | DSI_DATANO | Dedicated | VDD_MIPI_DPHY | – | – | – | – | – |
| 41 | VDD_MIPI_DPHY | Power | – | – | – | – | – | – |
| 42 | CSI_DATANO | Dedicated | VDD_MIPI_DPHY | – | – | – | – | – |
| 43 | CSI_DATAP0 | Dedicated | VDD_MIPI_DPHY | – | – | – | – | – |
| 44 | CSI_CLKP | Dedicated | VDD_MIPI_DPHY | – | – | – | – | – |
| 45 | CSI_CLKN | Dedicated | VDD_MIPI_DPHY | – | – | – | – | – |
| 46 | CSI_DATAN1 | Dedicated | VDD_MIPI_DPHY | – | – | – | – | – |
| 47 | CSI_DATAP1 | Dedicated | VDD_MIPI_DPHY | – | – | – | – | – |
| 48 | CSI_REXT | Dedicated | VDD_MIPI_DPHY | – | – | – | – | – |
| 49 | USB_DM | Dedicated | VDD_USBPHY | – | – | – | – | – |
| 50 | USB_DP | Dedicated | VDD_USBPHY | – | – | – | – | – |
| 51 | VDD_USBPHY | Power | – | – | – | – | – | – |
| 52 | GPIO24 | IO | VDD_IO_4 | – | – | IO MUX | – | Analog |
| 53 | GPIO25 | IO | VDD_IO_4 | – | USB_PU | IO MUX | – | Analog |
| 54 | NC | – | – | – | – | – | – | – |
| 55 | GPIO26 | IO | VDD_IO_4 | – | – | IO MUX | – | Analog |
| 56 | GPIO27 | IO | VDD_IO_4 | – | – | IO MUX | – | Analog |
| 57 | GPIO28 | IO | VDD_IO_4 | – | – | IO MUX | – | – |
| 58 | GPIO29 | IO | VDD_IO_4 | – | – | IO MUX | – | – |
| 59 | VDD_PSRAM_0 | Power | – | – | – | – | – | – |
| 60 | GPIO30 | IO | VDD_IO_4 | – | – | IO MUX | – | – |
| 61 | GPIO31 | IO | VDD_IO_4 | – | – | IO MUX | – | – |
| 62 | VDD_IO_4 | Power | – | – | – | – | – | – |
| 63 | GPIO32 | IO | VDD_IO_4 | IE | – | IO MUX | – | – |
| 64 | GPIO33 | IO | VDD_IO_4 | IE | – | IO MUX | – | – |
| 65 | GPIO34 | IO | VDD_IO_4 | IE | – | IO MUX | – | – |
| 66 | GPIO35 | IO | VDD_IO_4 | IE, WPU | – | IO MUX | – | – |
| 67 | VDD_PSRAM_1 | Power | – | – | – | – | – | – |
| 68 | GPIO36 | IO | VDD_IO_4 | IE | – | IO MUX | – | – |
| 69 | GPIO37 | IO | VDD_IO_4 | IE | – | IO MUX | – | – |
| 70 | GPIO38 | IO | VDD_IO_4 | IE | – | IO MUX | – | – |
| 71 | VDDO_FLASH | Power | – | – | – | – | – | – |
| 72 | VDDO_PSRAM | Power | – | – | – | – | – | – |
| 73 | VDDO_3 | Power | – | – | – | – | – | – |
| 74 | VDDO_4 | Power | – | – | – | – | – | – |
| 75 | VDD_LDO | Power | – | – | – | – | – | – |
| 76 | VDD_HP_2 | Power | – | – | – | – | – | – |
| 77 | VDD_DCDCC | Power | – | – | – | – | – | – |
| 78 | FB_DCDC | Analog | – | – | – | – | – | – |
| 79 | EN_DCDC | Analog | – | – | – | – | – | – |
| 80 | GPIO39 | IO | VDD_IO_5 | – | – | IO MUX | – | – |
| 81 | GPIO40 | IO | VDD_IO_5 | – | – | IO MUX | – | – |
| 82 | GPIO41 | IO | VDD_IO_5 | – | – | IO MUX | – | – |
| 83 | GPIO42 | IO | VDD_IO_5 | – | – | IO MUX | – | – |
| 84 | GPIO43 | IO | VDD_IO_5 | – | – | IO MUX | – | – |
| 85 | VDD_IO_5 | Power | – | – | – | – | – | – |
| 86 | GPIO44 | IO | VDD_IO_5 | – | – | IO MUX | – | – |
| 87 | GPIO45 | IO | VDD_IO_5 | – | – | IO MUX | – | – |
| 88 | GPIO46 | IO | VDD_IO_5 | – | – | IO MUX | – | – |
| 89 | GPIO47 | IO | VDD_IO_5 | – | – | IO MUX | – | – |
| 90 | GPIO48 | IO | VDD_IO_5 | – | – | IO MUX | – | – |
| 91 | VDD_HP_3 | Power | – | – | – | – | – | – |
| 92 | GPIO49 | IO | VDD_IO_6 | – | – | IO MUX | – | Analog |
| 93 | GPIO50 | IO | VDD_IO_6 | – | – | IO MUX | – | Analog |
| 94 | GPIO51 | IO | VDD_IO_6 | – | – | IO MUX | – | Analog |
| 95 | GPIO52 | IO | VDD_IO_6 | – | – | IO MUX | – | Analog |
| 96 | VDD_IO_6 | Power | – | – | – | – | – | – |
| 97 | GPIO53 | IO | VDD_IO_6 | – | – | IO MUX | – | Analog |
| 98 | GPIO54 | IO | VDD_IO_6 | – | – | IO MUX | – | Analog |
| 99 | XTAL_N | Analog | – | – | – | – | – | – |
| 100 | XTAL_P | Analog | – | – | – | – | – | – |
| 101 | VDD_ANA | Power | – | – | – | – | – | – |
| 102 | VDD_BAT | Power | – | – | – | – | – | – |
| 103 | CHIP_PU | Analog | – | – | – | – | – | – |
| 104 | GPIO0 | IO | VDD_LP / VDD_BAT | – | – | IO MUX | LP IO MUX | Analog |
| 105 | GND | Power | – | – | – | – | – | – |

1. **Bold** marks the pin function set in which a pin has its default function in the default boot mode. See Section 3.1 *Chip Boot Mode Control*.

2. In column *Pin Providing Power*, regarding pins powered by VDD_LP / VDD_BAT:
   - Pin Providing Power (either VDD_LP or VDD_BAT) can be configured via a register.

3. Default drive strength for IO pins is 20 mA except for GPIO24 and GPIO25 which have default drive strength of 40 mA.

4. Column *Pin Settings* shows predefined settings at reset and after reset with the following abbreviations:
   - IE – input enabled
   - WPU – internal weak pull-up resistor enabled
   - USB_PU – USB pull-up resistor enabled
     - By default, the USB function is enabled for USB pins (i.e., GPIO24/26 and GPIO25/27), and the pin pull-up is decided by the USB pull-up. The USB pull-up is controlled by USB_SERIAL_JTAG_DP/DM_PULLUP and the pull-up resistor value is controlled by USB_SERIAL_JTAG_PULLUP_VALUE.
     - When the USB function is disabled, USB pins are used as regular GPIOs and the pin's internal weak pull-up and pull-down resistors are disabled by default (configurable by IO_MUX_GPIOx_FUN_WPU/WPD).

5. Depends on the value of EFUSE_DIS_PAD_JTAG
   - 0 (default), input enabled, pull-up resistor enabled (IE = 1, WPU = 1)
   - 1, input disabled, in high impedance state (IE = 0)

## 2.3 IO Pins

### 2.3.1 IO MUX Functions

The IO MUX allows multiple input/output signals to be connected to a single input/output pin. Each IO pin of ESP32-P4 can be connected to one of the four signals (IO MUX functions, i.e., F0–F3), as listed in Table 2-3 *IO MUX Functions*.

Among the four sets of signals:

- Some are routed via the GPIO Matrix (**GPIO0**, **GPIO1**, etc.), which incorporates internal signal routing circuitry for mapping signals programmatically. It gives the pin access to almost any peripheral signals. However, the flexibility of programmatic mapping comes at a cost as it might affect the latency of routed signals.
- Some are directly routed from certain peripherals (**U0TXD**, **MTCK**, etc.), including UART0, JTAG, and SPI2 - see Table 2-2 *IO MUX Functions*.

Table 2-2. Peripheral Signals Routed via IO MUX

| Pin Function | Signal | Description |
|---|---|---|
| MTCK | Test clock | JTAG interface for debugging |
| MTDO | Test data out | JTAG interface for debugging |
| MTDI | Test data in | JTAG interface for debugging |
| MTMS | Test mode select | JTAG interface for debugging |
| SPI2_HOLD_PAD | Hold | 3.3 V SPI2 interface which can operate in master and slave modes. The interface supports 1-line, 2-line, 4-line, and 8-line modes (the 8-line mode is supported only in the master mode). |
| SPI2_CS_PAD | Chip select | 3.3 V SPI2 interface which can operate in master and slave modes. The interface supports 1-line, 2-line, 4-line, and 8-line modes (the 8-line mode is supported only in the master mode). |
| SPI2_D_PAD | Data in | 3.3 V SPI2 interface which can operate in master and slave modes. The interface supports 1-line, 2-line, 4-line, and 8-line modes (the 8-line mode is supported only in the master mode). |
| SPI2_CK_PAD | Clock | 3.3 V SPI2 interface which can operate in master and slave modes. The interface supports 1-line, 2-line, 4-line, and 8-line modes (the 8-line mode is supported only in the master mode). |
| SPI2_Q_PAD | Data out | 3.3 V SPI2 interface which can operate in master and slave modes. The interface supports 1-line, 2-line, 4-line, and 8-line modes (the 8-line mode is supported only in the master mode). |
| SPI2_WP_PAD | Write protect | 3.3 V SPI2 interface which can operate in master and slave modes. The interface supports 1-line, 2-line, 4-line, and 8-line modes (the 8-line mode is supported only in the master mode). |
| SPI2_IO..._PAD | Data | The high 4-bit data line interface and the DQS interface for 3.3 V SPI2 interface in 8-line SPI mode |
| SPI2_DQS_PAD | Data strobe/data mask | The high 4-bit data line interface and the DQS interface for 3.3 V SPI2 interface in 8-line SPI mode |
| UART0_TXD_PAD | Transmit data | UART0 Interface |
| UART0_RXD_PAD | Receive data | UART0 Interface |
| REF_50M_CLK_PAD | 50 MHz reference clock output | Provides 50 MHz clock for internal and external modules |
| GMAC_PHY_RXDV_PAD^1 | Receive data valid | RMII Ethernet PHY interface |
| GMAC_PHY_RXD..._PAD | Receive data line 0/1 | RMII Ethernet PHY interface |
| GMAC_PHY_RXER_PAD | Receive error | RMII Ethernet PHY interface |
| GMAC_PHY_TXDV_PAD | Transmit data valid | RMII Ethernet PHY interface |
| GMAC_PHY_TXD..._PAD | Transmit data line 0/1 | RMII Ethernet PHY interface |
| GMAC_PHY_TXER_PAD | Transmit error | RMII Ethernet PHY interface |
| GMAC_PHY_TXEN_PAD | Transmit enable | RMII Ethernet PHY interface |
| GMAC_RMII_CLK_PAD | RMII clock | RMII Ethernet PHY interface |
| SD1_CDATA..._PAD | Card data line 0–7 of SD1 | SDIO3.0 interface |
| SD1_CCLK_PAD | Card clock of SD1 | SDIO3.0 interface |
| SD1_CCMD_PAD | Card command of SD1 | SDIO3.0 interface |

^1 The PAD layer does not distinguish between MII and RMII interfaces. This signal is used as RX_DV in MII mode and as CRS_DV in RMII mode.

Table 2-3. IO MUX Pin Functions

| Pin No. | IO MUX / GPIO Name^2 | F0 | Type^3 | F1 | Type | F2 | Type | F3 | Type |
|---|---|---|---|---|---|---|---|---|---|
| 1 | GPIO1 | GPIO1 | I/O/T | GPIO1 | I/O/T | – | – | – | – |
| 2 | GPIO2 | MTCK | I1 | GPIO2 | I/O/T | – | – | – | – |
| 3 | GPIO3 | MTDI | I1 | GPIO3 | I/O/T | – | – | – | – |
| 4 | GPIO4 | MTMS | IO | GPIO4 | I/O/T | – | – | – | – |
| 5 | GPIO5 | MTDO | O/T | GPIO5 | I/O/T | – | – | – | – |
| 6 | GPIO6 | GPIO6 | I/O/T | GPIO6 | I/O/T | – | – | SPI2_HOLD_PAD | I1/O/T |
| 7 | GPIO7 | GPIO7 | I/O/T | GPIO7 | I/O/T | – | – | SPI2_CS_PAD | I1/O/T |
| 8 | GPIO8 | GPIO8 | I/O/T | GPIO8 | I/O/T | – | – | SPI2_D_PAD | I1/O/T |
| 10 | GPIO9 | GPIO9 | I/O/T | GPIO9 | I/O/T | – | – | SPI2_CK_PAD | I1/O/T |
| 11 | GPIO10 | GPIO10 | I/O/T | GPIO10 | I/O/T | – | – | SPI2_Q_PAD | I1/O/T |
| 12 | GPIO11 | GPIO11 | I/O/T | GPIO11 | I/O/T | – | – | SPI2_WP_PAD | I1/O/T |
| 13 | GPIO12 | GPIO12 | I/O/T | GPIO12 | I/O/T | – | – | – | – |
| 14 | GPIO13 | GPIO13 | I/O/T | GPIO13 | I/O/T | – | – | – | – |
| 15 | GPIO14 | GPIO14 | I/O/T | GPIO14 | I/O/T | – | – | – | – |
| 16 | GPIO15 | GPIO15 | I/O/T | GPIO15 | I/O/T | – | – | – | – |
| 17 | GPIO16 | GPIO16 | I/O/T | GPIO16 | I/O/T | – | – | – | – |
| 18 | GPIO17 | GPIO17 | I/O/T | GPIO17 | I/O/T | – | – | – | – |
| 19 | GPIO18 | GPIO18 | I/O/T | GPIO18 | I/O/T | – | – | – | – |
| 20 | GPIO19 | GPIO19 | I/O/T | GPIO19 | I/O/T | – | – | – | – |
| 22 | GPIO20 | GPIO20 | I/O/T | GPIO20 | I/O/T | – | – | – | – |
| 23 | GPIO21 | GPIO21 | I/O/T | GPIO21 | I/O/T | – | – | – | – |
| 24 | GPIO22 | GPIO22 | I/O/T | GPIO22 | I/O/T | – | – | – | – |
| 25 | GPIO23 | GPIO23 | I/O/T | GPIO23 | I/O/T | – | – | REF_50M_CLK_PAD | O |
| 52 | GPIO24 | GPIO24 | I/O/T | GPIO24 | I/O/T | – | – | – | – |
| 53 | GPIO25 | GPIO25 | I/O/T | GPIO25 | I/O/T | – | – | – | – |
| 55 | GPIO26 | GPIO26 | I/O/T | GPIO26 | I/O/T | – | – | – | – |
| 56 | GPIO27 | GPIO27 | I/O/T | GPIO27 | I/O/T | – | – | – | – |
| 57 | GPIO28 | GPIO28 | I/O/T | GPIO28 | I/O/T | SPI2_CS_PAD | I1/O/T | GMAC_PHY_RXDV_PAD | IO |
| 58 | GPIO29 | GPIO29 | I/O/T | GPIO29 | I/O/T | SPI2_D_PAD | I1/O/T | GMAC_PHY_RXD0_PAD | IO |
| 60 | GPIO30 | GPIO30 | I/O/T | GPIO30 | I/O/T | SPI2_CK_PAD | I1/O/T | GMAC_PHY_RXD1_PAD | IO |
| 61 | GPIO31 | GPIO31 | I/O/T | GPIO31 | I/O/T | SPI2_Q_PAD | I1/O/T | GMAC_PHY_RXER_PAD | IO |
| 63 | GPIO32 | GPIO32 | I/O/T | GPIO32 | I/O/T | SPI2_HOLD_PAD | I1/O/T | GMAC_RMII_CLK_PAD | IO |
| 64 | GPIO33 | GPIO33 | I/O/T | GPIO33 | I/O/T | SPI2_WP_PAD | I1/O/T | GMAC_PHY_TXEN_PAD | O |
| 65 | GPIO34 | GPIO34 | I/O/T | GPIO34 | I/O/T | SPI2_IO4_PAD | I1/O/T | GMAC_PHY_TXD0_PAD | O |
| 66 | GPIO35 | GPIO35 | I/O/T | GPIO35 | I/O/T | SPI2_IO5_PAD | I1/O/T | GMAC_PHY_TXD1_PAD | O |
| 68 | GPIO36 | GPIO36 | I/O/T | GPIO36 | I/O/T | SPI2_IO6_PAD | I1/O/T | GMAC_PHY_TXER_PAD | O |
| 69 | GPIO37 | UART0_TXD_PAD | O | GPIO37 | I/O/T | SPI2_IO7_PAD | I1/O/T | – | – |
| 70 | GPIO38 | UART0_RXD_PAD | I1 | GPIO38 | I/O/T | SPI2_DQS_PAD | O/T | – | – |
| 80 | GPIO39 | SD1_CDATA0_PAD | I1/O/T | GPIO39 | I/O/T | – | – | REF_50M_CLK_PAD | O |
| 81 | GPIO40 | SD1_CDATA1_PAD | I1/O/T | GPIO40 | I/O/T | – | – | GMAC_PHY_TXEN_PAD | O |
| 82 | GPIO41 | SD1_CDATA2_PAD | I1/O/T | GPIO41 | I/O/T | – | – | GMAC_PHY_TXD0_PAD | O |
| 83 | GPIO42 | SD1_CDATA3_PAD | I1/O/T | GPIO42 | I/O/T | – | – | GMAC_PHY_TXD1_PAD | O |
| 84 | GPIO43 | SD1_CCLK_PAD | O | GPIO43 | I/O/T | – | – | GMAC_PHY_TXER_PAD | O |
| 86 | GPIO44 | SD1_CCMD_PAD | I1/O/T | GPIO44 | I/O/T | – | – | GMAC_RMII_CLK_PAD | IO |
| 87 | GPIO45 | SD1_CDATA4_PAD | I1/O/T | GPIO45 | I/O/T | – | – | GMAC_PHY_RXDV_PAD | IO |
| 88 | GPIO46 | SD1_CDATA5_PAD | I1/O/T | GPIO46 | I/O/T | – | – | GMAC_PHY_RXD0_PAD | IO |
| 89 | GPIO47 | SD1_CDATA6_PAD | I1/O/T | GPIO47 | I/O/T | – | – | GMAC_PHY_RXD1_PAD | IO |
| 90 | GPIO48 | SD1_CDATA7_PAD | I1/O/T | GPIO48 | I/O/T | – | – | GMAC_PHY_RXER_PAD | IO |
| 92 | GPIO49 | GPIO49 | I/O/T | GPIO49 | I/O/T | – | – | GMAC_PHY_TXEN_PAD | O |
| 93 | GPIO50 | GPIO50 | I/O/T | GPIO50 | I/O/T | – | – | GMAC_RMII_CLK_PAD | IO |
| 94 | GPIO51 | GPIO51 | I/O/T | GPIO51 | I/O/T | – | – | GMAC_PHY_RXDV_PAD | IO |
| 95 | GPIO52 | GPIO52 | I/O/T | GPIO52 | I/O/T | – | – | GMAC_PHY_RXD0_PAD | IO |
| 97 | GPIO53 | GPIO53 | I/O/T | GPIO53 | I/O/T | – | – | GMAC_PHY_RXD1_PAD | IO |
| 98 | GPIO54 | GPIO54 | I/O/T | GPIO54 | I/O/T | – | – | GMAC_PHY_RXER_PAD | IO |
| 104 | GPIO0 | GPIO0 | I/O/T | GPIO0 | I/O/T | – | – | – | – |

^2 Bold marks the default pin functions in the default boot mode. See Section 3.1 *Chip Boot Mode Control*.

^3 Regarding highlighted cells, see Section 2.3.4 *Restrictions for GPIOs and LP GPIOs*.

^4 Each IO MUX function (Fn, n = 0–3) is associated with a type. The description of type is as follows:
   - I – input. O – output. T – high impedance.
   - I1 – input; if the pin is assigned a function other than Fn, the input signal of Fn is always 1.
   - I0 – input; if the pin is assigned a function other than Fn, the input signal of Fn is always 0.
