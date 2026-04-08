# 2 Pins

## 2.1 Pin Layout

![Figure 2-1. ESP32-P4 Pin Layout (Top View)](figures/ch02_figure-002.png)

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


# 2 Pins

## 2.3.2 LP IO MUX Functions

When the chip is in Deep-sleep mode, the IO MUX described in Section 2.3.1 *IO MUX Functions* will not work. That is where the LP IO MUX comes in. It allows multiple input/output signals to be a single input/output pin in Deep-sleep mode, as the pin is connected to the LP system and powered by VDD_LP or VDD_BAT.

LP IO pins can be assigned to **LP IO MUX functions**. They can

- Either work as LP GPIOs (LP_GPIO0, LP_GPIO1, etc.), connected to the LP CPU
- Or connect to LP peripheral signals (LP_UART_TXD_PAD, LP_UART_RXD_PAD) - see Table 2-4 *LP IO MUX Functions*

### Table 2-4. LP Peripheral Signals Routed via LP IO MUX

| Pin Function | Signal | Description |
| --- | --- | --- |
| LP_UART_TXD_PAD | Transmit data | LP UART interface |
| LP_UART_RXD_PAD | Receive data | LP UART interface |

Table 2-5 *LP IO MUX Functions* shows the LP functions of LP IO pins.

### Table 2-5. LP IO MUX Functions

| Pin No. | LP IO Name<sup>1,2</sup> | F0 | Type | F1 | Type |
| --- | --- | --- | --- | --- | --- |
| 1 | LP_GPIO1 | LP_GPIO1 | I/O/T | LP_GPIO1 | I/O/T |
| 2 | LP_GPIO2 | LP_GPIO2 | I/O/T | LP_GPIO2 | I/O/T |
| 3 | LP_GPIO3 | LP_GPIO3 | I/O/T | LP_GPIO3 | I/O/T |
| 4 | LP_GPIO4 | LP_GPIO4 | I/O/T | LP_GPIO4 | I/O/T |
| 5 | LP_GPIO5 | LP_GPIO5 | I/O/T | LP_GPIO5 | I/O/T |
| 6 | LP_GPIO6 | LP_GPIO6 | I/O/T | LP_GPIO6 | I/O/T |
| 7 | LP_GPIO7 | LP_GPIO7 | I/O/T | LP_GPIO7 | I/O/T |
| 8 | LP_GPIO8 | LP_GPIO8 | I/O/T | LP_GPIO8 | I/O/T |
| 10 | LP_GPIO9 | LP_GPIO9 | I/O/T | LP_GPIO9 | I/O/T |
| 11 | LP_GPIO10 | LP_GPIO10 | I/O/T | LP_GPIO10 | I/O/T |
| 12 | LP_GPIO11 | LP_GPIO11 | I/O/T | LP_GPIO11 | I/O/T |
| 13 | LP_GPIO12 | LP_GPIO12 | I/O/T | LP_GPIO12 | I/O/T |
| 14 | LP_GPIO13 | LP_GPIO13 | I/O/T | LP_GPIO13 | I/O/T |
| 15 | LP_UART_TXD_PAD | LP_UART_TXD_PAD | O | LP_GPIO14 | I/O/T |
| 16 | LP_UART_RXD_PAD | LP_UART_RXD_PAD | I | LP_GPIO15 | I/O/T |
| 104 | LP_GPIO0 | LP_GPIO0 | I/O/T | LP_GPIO0 | I/O/T |

<sup>1</sup> This column lists the LP GPIO names, since LP functions are configured with LP GPIO registers that use LP GPIO numbering.

## 2.3.3 Analog Functions

Some IO pins also have **analog functions**, for analog peripherals (such as touch sensor and ADC) in any power mode. Internal analog signals are routed to these analog functions, see Table 2-6 *Analog Functions*.

### Table 2-6. Analog Signals Routed to Analog Functions

| Pin Function | Signal | Description |
| --- | --- | --- |
| XTAL_32K_N | Negative clock signal | 32 kHz external clock input/output connected to the oscillator |
| XTAL_32K_P | Positive clock signal | 32 kHz external clock input/output connected to the oscillator |
| TOUCH_CHANNEL... | Touch sensor channel signal | Touch sensor interface |
| ADC..._CHANNEL... | ADC1/2 channel signal | ADC1/2 interface |
| USB1P1_N... | USB D- | USB 2.0 full-speed OTG interface and USB Serial/JTAG function |
| USB1P1_P... | USB D+ | USB 2.0 full-speed OTG interface and USB Serial/JTAG function |
| ANA_COMP... | Voltage of P0/P1 | Analog voltage comparator O/1 interface |

Table 2-7 *Analog Functions* shows the analog functions of IO pins.

### Table 2-7. Analog Functions

| Pin No. | Analog IO Name | F0 | F1 |
| --- | --- | --- | --- |
| 1 | GPIO1 | XTAL_32K_P | - |
| 2 | GPIO2 | TOUCH_CHANNEL1 | - |
| 3 | GPIO3 | TOUCH_CHANNEL2 | - |
| 4 | GPIO4 | TOUCH_CHANNEL3 | - |
| 5 | GPIO5 | TOUCH_CHANNEL4 | - |
| 6 | GPIO6 | TOUCH_CHANNEL5 | - |
| 7 | GPIO7 | TOUCH_CHANNEL6 | - |
| 8 | GPIO8 | TOUCH_CHANNEL7 | - |
| 10 | GPIO9 | TOUCH_CHANNEL8 | - |
| 11 | GPIO10 | TOUCH_CHANNEL9 | - |
| 12 | GPIO11 | TOUCH_CHANNEL10 | - |
| 13 | GPIO12 | TOUCH_CHANNEL11 | - |
| 14 | GPIO13 | TOUCH_CHANNEL12 | - |
| 15 | GPIO14 | TOUCH_CHANNEL13 | - |
| 16 | GPIO15 | TOUCH_CHANNEL14 | - |
| 17 | GPIO16 | ADC1_CHANNEL0 | - |
| 18 | GPIO17 | ADC1_CHANNEL1 | - |
| 19 | GPIO18 | ADC1_CHANNEL2 | - |
| 20 | GPIO19 | ADC1_CHANNEL3 | - |
| 22 | GPIO20 | ADC1_CHANNEL4 | - |
| 23 | GPIO21 | ADC1_CHANNEL5 | - |
| 24 | GPIO22 | ADC1_CHANNEL6 | - |

Table 2-7 - cont’d from previous page

| Pin No. | Analog IO Name | F0 | F1 |
| --- | --- | --- | --- |
| 25 | GPIO23 | ADC1_CHANNEL7 | - |
| 52 | GPIO24 | USB1P1_N0 | - |
| 53 | GPIO25 | USB1P1_P0 | - |
| 55 | GPIO26 | USB1P1_N1 | - |
| 56 | GPIO27 | USB1P1_P1 | - |
| 92 | GPIO49 | ADC2_CHANNEL0 | - |
| 93 | GPIO50 | ADC2_CHANNEL1 | - |
| 94 | GPIO51 | ADC2_CHANNEL2 | ANA_COMP0 |
| 95 | GPIO52 | ADC2_CHANNEL3 | ANA_COMP0 |
| 97 | GPIO53 | ADC2_CHANNEL4 | ANA_COMP1 |
| 98 | GPIO54 | ADC2_CHANNEL5 | ANA_COMP1 |
| 104 | GPIO0 | XTAL_32K_N | - |

<sup>1</sup> Bold marks the default pin functions in the default boot mode. See Section 3.1 *Chip Boot Mode Control*.

<sup>2</sup> Regarding highlighted cells, see Section 2.3.4 *Restrictions for GPIOs and LP GPIOs*.

## 2.3.4 Restrictions for GPIOs and LP GPIOs

All IO pins of ESP32-P4 have GPIO pin functions, and some have LP GPIO pin functions. However, the IO pins are multiplexed and can be configured for different purposes based on the requirements. Some IOs have restrictions for usage. It is essential to consider the multiplexed nature and the limitations when using these IO pins.

In tables of this chapter, some pin functions are highlighted. The non-highlighted GPIO or LP_GPIO pins are recommended for use first. If more pins are needed, the highlighted GPIOs or LP_GPIOs should be chosen carefully to avoid conflicts with important pin functions.

The highlighted IO pins have one of the following important functions:

- **Strapping pins** - need to be at certain logic levels at startup. See Section 3 *Boot Configurations*.
- **USB1P1_N0/P0** - by default, connected to the USB Serial/JTAG Controller. To function as GPIOs, these pins need to be reconfigured.
- **JTAG interface** - often used for debugging. See Table 2-2 *IO MUX Functions*. To free these pins up, the pin functions USB1P1_N/P of the USB Serial/JTAG Controller can be used instead. See also Section 3.4 *JTAG Signal Source Control*.
- **UART interface** - often used for debugging. See Table 2-2 *IO MUX Functions*.

See also Appendix A - ESP32-P4 Consolidated Pin Overview.

## 2.4 Dedicated Interface Pins

Some pins are dedicated to a few important peripherals, such as MIPI DSI and MIPI CSI.

### Table 2-8. Peripheral-Dedicated Signals

| Pin Function | Signal | Description |
| --- | --- | --- |
| FLASH_CS | Chip select | Flash connection |
| FLASH_Q | Data output | Flash connection |
| FLASH_WP | Write protect | Flash connection |
| FLASH_HOLD | Hold | Flash connection |
| FLASH_CK | Clock | Flash connection |
| FLASH_D | Data in | Flash connection |
| MIPI DSI PHY 4.02 kΩ EXTERNAL RESISTOR | External resistor 4.02 kΩ | MIPI DSI connection |
| MIPI DSI PHY DATAP... | Data positive channel 0/1 | MIPI DSI connection |
| MIPI DSI PHY DATAN... | Data negative channel 0/1 | MIPI DSI connection |
| MIPI DSI PHY CLKN | Clock negative channel | MIPI DSI connection |
| MIPI DSI PHY CLKP | Clock positive channel | MIPI DSI connection |
| MIPI CSI PHY 4.02 kΩ EXTERNAL RESISTOR | External resistor 4.02 kΩ | MIPI CSI connection |
| MIPI CSI PHY DATAP... | Data positive channel 0/1 | MIPI CSI connection |
| MIPI CSI PHY DATAN... | Data negative channel 0/1 | MIPI CSI connection |
| MIPI CSI PHY CLKN | Clock negative channel | MIPI CSI connection |
| MIPI CSI PHY CLKP | Clock positive channel | MIPI CSI connection |
| USB2 OTG PHY DM | USB D- | USB 2.0 high-speed OTG connection |
| USB2 OTG PHY DP | USB D+ | USB 2.0 high-speed OTG connection |

Table 2-9 *Dedicated Interface Pins* lists the peripheral-dedicated functions of pins.

### Table 2-9. Dedicated Interface Pins

| Pin No. | Dedicated Interface Pin | F0 | Type |
| --- | --- | --- | --- |
| 27 | FLASH_CS | FLASH_CS | O |
| 28 | FLASH_Q | FLASH_Q | I/O/T |
| 29 | FLASH_WP | FLASH_WP | I/O/T |
| 31 | FLASH_HOLD | FLASH_HOLD | I/O/T |
| 32 | FLASH_CK | FLASH_CK | O |
| 33 | FLASH_D | FLASH_D | I/O/T |
| 34 | DSI_REXT | MIPI DSI PHY 4.02 KΩ EXTERNAL RESISTOR | I/O/T |
| 35 | DSI_DATAP1 | MIPI DSI PHY DATAP1 | I/O/T |
| 36 | DSI_DATAN1 | MIPI DSI PHY DATAN1 | I/O/T |
| 37 | DSI_CLKN | MIPI DSI PHY CLKN | I/O/T |
| 38 | DSI_CLKP | MIPI DSI PHY CLKP | I/O/T |
| 39 | DSI_DATAP0 | MIPI DSI PHY DATAP0 | I/O/T |

Table 2-9 - cont’d from previous page

| Pin No. | Dedicated Interface Pin | F0 | Type |
| --- | --- | --- | --- |
| 40 | DSI_DATAN0 | MIPI DSI PHY DATAN0 | I/O/T |
| 42 | CSI_DATAN0 | MIPI CSI PHY DATAN0 | I/O/T |
| 43 | CSI_DATAP0 | MIPI CSI PHY DATAP0 | I/O/T |
| 44 | CSI_CLKP | MIPI CSI PHY CLKP | I/O/T |
| 45 | CSI_CLKN | MIPI CSI PHY CLKN | I/O/T |
| 46 | CSI_DATAN1 | MIPI CSI PHY DATAN1 | I/O/T |
| 47 | CSI_DATAP1 | MIPI CSI PHY DATAP1 | I/O/T |
| 48 | CSI_REXT | MIPI CSI PHY 4.02 kΩ EXTERNAL RESISTOR | I/O/T |
| 49 | USB_DM | USB2 OTG PHY DM | I/O/T |
| 50 | USB_DP | USB2 OTG PHY DP | I/O/T |

## 2.5 Analog Pins

### Table 2-10. Analog Pins

| Pin No. | Pin Name | Pin Type | Pin Function |
| --- | --- | --- | --- |
| 78 | FB_DCDC | - | Feedback pin of power supply for external DC/DC. It regulates the voltage of VDD_HP_0/2/3 together with feedback resistors of external DC/DC |
| 79 | EN_DCDC | O | Enable pin of external DC/DC |
| 99 | XTAL_N | - | External clock input/output connected to chip's crystal or oscillator. |
| 100 | XTAL_P | - | P/N means differential clock positive/negative. |
| 103 | CHIP_PU | I | High: on, enables the chip (powered up).<br>Low: off, disables the chip (powered down).<br>Note: Do not leave the CHIP_PU pin floating. |

## 2.6 Power Supply

### 2.6.1 Power Pins

The chip is powered via the power pins described in Table 2-11 *Power Pins*.

### Table 2-11. Power Pins

| Pin No. | Pin Name | Direction | Power Domain / Other<sup>3</sup> | IO Pins |
| --- | --- | --- | --- | --- |
| 9 | VDD_LP | Input | LP power domain | LP IO<sup>4</sup> |
| 21 | VDD_IO_0 | Input | Digital power domain | HP IO |
| 26 | VDD_HP_0 | Input | Digital power domain |  |
| 30 | VDD_FLASHIO<sup>2</sup> | Input | Flash | flash IO |
| 41 | VDD_MIPI_DPHY | Input | MIPI PHY | MIPI IO |
| 51 | VDD_USBPHY | Input | USB PHY | High-speed USB IO |
| 59 | VDD_PSRAM_0 | Input | PSRAM | PSRAM IO |
| 62 | VDD_IO_4 | Input | Digital power domain | HP IO |
| 67 | VDD_PSRAM_1 | Input | PSRAM | PSRAM IO |
| 71 | VDDO_FLASH | Output | Off-package flash, output 50 mA current at the maximum |  |
| 72 | VDDO_PSRAM | Output | In-package and off-package PSRAM, output 50 mA current at the maximum |  |
| 73 | VDDO_3 | Output | Output 50 mA current at the maximum |  |
| 74 | VDDO_4 | Output | Output 50 mA current at the maximum |  |
| 75 | VDD_LDO | Input | Analog power domain, providing power for LDOs |  |
| 76 | VDD_HP_2 | Input | Digital power domain |  |
| 77 | VDD_DCDCC | Input | Analog power domain, providing power for DC/DC control |  |
| 85 | VDD_IO_5 | Input | Digital power domain | HP IO |
| 91 | VDD_HP_3 | Input | Digital power domain |  |
| 96 | VDD_IO_6 | Input | Digital power domain | HP IO |
| 101 | VDD_ANA | Input | Analog power domain |  |
| 102 | VDD_BAT | Input | Analog power domain, connecting to external batteries optionally |  |
| 105 | GND | - | External ground connection |  |

<sup>1</sup> See in conjunction with Section 2.6.2 *Power Scheme*.

<sup>2</sup> VDD_FLASHIO provides power for flash IO, and the voltage should be adjusted according to the specific flash model. In this document, all related descriptions are based on a 3.3 V flash as an example.

<sup>3</sup> For recommended and maximum voltage and current, see Section 5.1 *Absolute Maximum Ratings* and Section 5.2 *Recommended Operating Conditions*.

<sup>4</sup> LP IO pins are those powered by VDD_LP or VDD_BAT, as shown in Figure 2-2 *ESP32-P4 Power Scheme*. See also Table 2-1 *Pin Overview* &gt; Column *Pin Providing Power*.

### 2.6.2 Power Scheme

The power scheme is shown in Figure 2-2 *ESP32-P4 Power Scheme*.

The components on the chip are powered via voltage regulators.

![Figure 2-2. ESP32-P4 Power Scheme](figures/ch03_figure-002.png)

### Table 2-12. Voltage Regulators

| Voltage Regulator | Output | Power Supply |
| --- | --- | --- |
| HP LDO | 1.1 V | HP power domain |
| LP LDO | 1.1 V | LP power domain |
| Flash LDO | 1.8 V/3.3 V | Can be configured to power off-package flash |
| VDD_PSRAM LDO | 1.9 V | Can be configured to power in-package PSRAM |
| VO3 LDO | 0.5 ~ 2.7 V/3.3 V | Can be configured to power external devices |
| VO4 LDO | 0.5 ~ 2.7 V/3.3 V | Can be configured to power external devices |

### 2.6.3 Chip Power-up and Reset

Once the power is supplied to the chip, its power rails need a short time to stabilize. After that, CHIP_PU - the pin used for power-up and reset - is pulled high to activate the chip. For information on CHIP_PU as well as power-up and reset timing, see Figure 2-3 and Table 2-13.

![Figure 2-3. Visualization of Timing Parameters for Power-up and Reset](figures/ch03_figure-003.png)

### Table 2-13. Description of Timing Parameters for Power-up and Reset

| Parameter | Description | Min (µs) |
| --- | --- | --- |
| t_STBL | Time reserved for the power rails of VDD_LP, VDD_IO_0, VDD_USBPHY, VDD_PSRAM_0/1, VDD_IO_4, VDD_LDO, VDD_DCDCC, VDD_IO_5, VDD_IO_6 and VDD_ANA to stabilize before the CHIP_PU pin is pulled high to activate the chip | 50 |
| t_RST | Time reserved for CHIP_PU to stay below V_IL_nRST to reset the chip (see Table 5-4) | 1000 |


# 2 Pins

## 2.7 Pin Mapping Between Chip and Flash

ESP32-P4 requires off-package flash to store application firmware and data. ESP32-P4 supports up to 64 MB flash, which can be connected through SPI, Dual SPI, and Quad SPI/QPI.

ESP32-P4 includes sixteen-line PSRAM with the operation voltage of 1.8 V. Please note that PSRAM is not pinned out.

Table 2-14 lists the pin mapping between the chip and flash for all SPI modes.

For more information on SPI controllers, see also Section 4.2.2.2 SPI Controller (SPI).

Table 2-14. Pin Mapping Between Chip and off-package Flash

| Pin No. | Pin Name   | Single SPI | Dual SPI | Quad SPI/QPI |
| --- | --- | --- | --- | --- |
| 27 | FLASH_CS   | CS#  | CS#  | CS#  |
| 28 | FLASH_Q    | DO   | DO   | DO   |
| 29 | FLASH_WP   | WP#  | WP#  | WP#  |
| 31 | FLASH_HOLD | HOLD# | HOLD# | HOLD# |
| 32 | FLSH_CK    | CLK  | CLK  | CLK  |
| 33 | FLSHA_D    | DI   | DI   | DI   |
