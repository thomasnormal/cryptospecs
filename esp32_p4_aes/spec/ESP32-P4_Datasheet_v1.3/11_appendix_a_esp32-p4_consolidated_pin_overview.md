# Appendix A – ESP32-P4 Consolidated Pin Overview

You can download the Excel file for the ESP32-P4 Consolidated Pin Overview table below.

### Table 6-1. Consolidated Pin Overview

| Pin No. | Pin Name | Pin Type | Pin Providing Power | At Reset | After Reset | HP F0 | HP F0 Type | HP F1 | HP F1 Type | HP F2 | HP F2 Type | HP F3 | HP F3 Type | LP F0 | LP F0 Type | LP F1 | LP F1 Type | Analog F0 | Analog F1 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | GPIO1 | IO | VDD_LP/VDD_BAT | - | - | GPIO1 | I/O/T | GPIO1 | I/O/T | - | - | - | - | LP_GPIO1 | I/O/T | LP_GPIO1 | I/O/T | XTAL_32K_P | - |
| 2 | GPIO2 | IO | VDD_LP/VDD_BAT | - | IE, WPU | MTCK | I1 | GPIO2 | I/O/T | - | - | - | - | LP_GPIO2 | I/O/T | LP_GPIO2 | I/O/T | TOUCH_CHANNEL1 | - |
| 3 | GPIO3 | IO | VDD_LP/VDD_BAT | - | IE | MTDI | I1 | GPIO3 | I/O/T | - | - | - | - | LP_GPIO3 | I/O/T | LP_GPIO3 | I/O/T | TOUCH_CHANNEL2 | - |
| 4 | GPIO4 | IO | VDD_LP | - | IE | MTMS | I1 | GPIO4 | I/O/T | - | - | - | - | LP_GPIO4 | I/O/T | LP_GPIO4 | I/O/T | TOUCH_CHANNEL3 | - |
| 5 | GPIO5 | IO | VDD_LP | - | IE | MTDO | O/T | GPIO5 | I/O/T | - | - | - | - | LP_GPIO5 | I/O/T | LP_GPIO5 | I/O/T | TOUCH_CHANNEL4 | - |
| 6 | GPIO6 | IO | VDD_LP | - | - | GPIO6 | I/O/T | GPIO6 | I/O/T | - | - | SPI2_HOLD_PAD | I/O/T | LP_GPIO6 | I/O/T | LP_GPIO6 | I/O/T | TOUCH_CHANNEL5 | - |
| 7 | GPIO7 | IO | VDD_LP | - | - | GPIO7 | I/O/T | GPIO7 | I/O/T | - | - | SPI2_CS_PAD | I/O/T | LP_GPIO7 | I/O/T | LP_GPIO7 | I/O/T | TOUCH_CHANNEL6 | - |
| 8 | GPIO8 | IO | VDD_LP | - | - | GPIO8 | I/O/T | GPIO8 | I/O/T | - | - | SPI2_D_PAD | I/O/T | LP_GPIO8 | I/O/T | LP_GPIO8 | I/O/T | TOUCH_CHANNEL7 | - |
| 9 | VDD_LP | Power | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 10 | GPIO9 | IO | VDD_LP | - | - | GPIO9 | I/O/T | GPIO9 | I/O/T | - | - | SPI2_CK_PAD | I/O/T | LP_GPIO9 | I/O/T | LP_GPIO9 | I/O/T | TOUCH_CHANNEL8 | - |
| 11 | GPIO10 | IO | VDD_LP | - | - | GPIO10 | I/O/T | GPIO10 | I/O/T | - | - | SPI2_Q_PAD | I/O/T | LP_GPIO10 | I/O/T | LP_GPIO10 | I/O/T | TOUCH_CHANNEL9 | - |
| 12 | GPIO11 | IO | VDD_LP | - | - | GPIO11 | I/O/T | GPIO11 | I/O/T | - | - | SPI2_WP_PAD | I/O/T | LP_GPIO11 | I/O/T | LP_GPIO11 | I/O/T | TOUCH_CHANNEL10 | - |
| 13 | GPIO12 | IO | VDD_LP | - | - | GPIO12 | I/O/T | GPIO12 | I/O/T | - | - | - | - | LP_GPIO12 | I/O/T | LP_GPIO12 | I/O/T | TOUCH_CHANNEL11 | - |
| 14 | GPIO13 | IO | VDD_LP | - | - | GPIO13 | I/O/T | GPIO13 | I/O/T | - | - | - | - | LP_GPIO13 | I/O/T | LP_GPIO13 | I/O/T | TOUCH_CHANNEL12 | - |
| 15 | GPIO14 | IO | VDD_LP | - | - | GPIO14 | I/O/T | GPIO14 | I/O/T | - | - | - | - | LP_GPIO14 | I/O/T | LP_GPIO14 | I/O/T | TOUCH_CHANNEL13 | - |
| 16 | GPIO15 | IO | VDD_LP | - | - | GPIO15 | I/O/T | GPIO15 | I/O/T | - | - | - | - | LP_GPIO15 | I/O/T | LP_GPIO15 | I/O/T | TOUCH_CHANNEL14 | - |
| 17 | GPIO16 | IO | VDD_IO_0 | - | - | GPIO16 | I/O/T | GPIO16 | I/O/T | - | - | - | - | - | - | - | - | ADC1_CHANNEL0 | - |
| 18 | GPIO17 | IO | VDD_IO_0 | - | - | GPIO17 | I/O/T | GPIO17 | I/O/T | - | - | - | - | - | - | - | - | ADC1_CHANNEL1 | - |
| 19 | GPIO18 | IO | VDD_IO_0 | - | - | GPIO18 | I/O/T | GPIO18 | I/O/T | - | - | - | - | - | - | - | - | ADC1_CHANNEL2 | - |
| 20 | GPIO19 | IO | VDD_IO_0 | - | - | GPIO19 | I/O/T | GPIO19 | I/O/T | - | - | - | - | - | - | - | - | ADC1_CHANNEL3 | - |
| 21 | VDD_IO_0 | Power | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 22 | GPIO20 | IO | VDD_IO_0 | - | - | GPIO20 | I/O/T | GPIO20 | I/O/T | - | - | - | - | - | - | - | - | ADC1_CHANNEL4 | - |
| 23 | GPIO21 | IO | VDD_IO_0 | - | - | GPIO21 | I/O/T | GPIO21 | I/O/T | - | - | - | - | - | - | - | - | ADC1_CHANNEL5 | - |
| 24 | GPIO22 | IO | VDD_IO_0 | - | - | GPIO22 | I/O/T | GPIO22 | I/O/T | - | - | - | - | - | - | - | - | ADC1_CHANNEL6 | - |
| 25 | GPIO23 | IO | VDD_IO_0 | - | - | GPIO23 | I/O/T | GPIO23 | I/O/T | - | - | REF_50M_CLK_PAD | O | - | - | - | - | ADC1_CHANNEL7 | - |
| 26 | VDD_HP_0 | Power | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 27 | FLASH_CS | Dedicated | VDD_FLASHIO | - | - | FLASH_CS | O | - | - | - | - | - | - | - | - | - | - | - | - |
| 28 | FLASH_Q | Dedicated | VDD_FLASHIO | - | - | FLASH_Q | I/O/T | - | - | - | - | - | - | - | - | - | - | - | - |
| 29 | FLASH_WP | Dedicated | VDD_FLASHIO | - | - | FLASH_WP | I/O/T | - | - | - | - | - | - | - | - | - | - | - | - |
| 30 | VDD_FLASHIO | Power | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 31 | FLASH_HOLD | Dedicated | VDD_FLASHIO | - | - | FLASH_HOLD | I/O/T | - | - | - | - | - | - | - | - | - | - | - | - |
| 32 | FLASH_CK | Dedicated | VDD_FLASHIO | - | - | FLASH_CK | O | - | - | - | - | - | - | - | - | - | - | - | - |
| 33 | FLASH_D | Dedicated | VDD_FLASHIO | - | - | FLASH_D | I/O/T | - | - | - | - | - | - | - | - | - | - | - | - |
| 34 | DSI_REXT | Dedicated | VDD_MIPI_DPHY | - | - | MIPI_DSI_PHY<br>4.02 KΩ EXTERNAL RESISTOR | I/O/T | - | - | - | - | - | - | - | - | - | - | - | - |
| 35 | DSI_DATAP1 | Dedicated | VDD_MIPI_DPHY | - | - | MIPI_DSI_PHY<br>DATAP1 | I/O/T | - | - | - | - | - | - | - | - | - | - | - | - |
| 36 | DSI_DATAN1 | Dedicated | VDD_MIPI_DPHY | - | - | MIPI_DSI_PHY<br>DATAN1 | I/O/T | - | - | - | - | - | - | - | - | - | - | - | - |
| 37 | DSI_CLKN | Dedicated | VDD_MIPI_DPHY | - | - | MIPI_DSI_PHY<br>CLKN | I/O/T | - | - | - | - | - | - | - | - | - | - | - | - |
| 38 | DSI_CLKP | Dedicated | VDD_MIPI_DPHY | - | - | MIPI_DSI_PHY<br>CLKP | I/O/T | - | - | - | - | - | - | - | - | - | - | - | - |
| 39 | DSI_DATAP0 | Dedicated | VDD_MIPI_DPHY | - | - | MIPI_DSI_PHY<br>DATAP0 | I/O/T | - | - | - | - | - | - | - | - | - | - | - | - |
| 40 | DSI_DATAN0 | Dedicated | VDD_MIPI_DPHY | - | - | MIPI_DSI_PHY<br>DATAN0 | I/O/T | - | - | - | - | - | - | - | - | - | - | - | - |
| 41 | VDD_MIPI_DPHY | Power | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 42 | CSI_DATAN0 | Dedicated | VDD_MIPI_DPHY | - | - | MIPI_CSI_PHY<br>DATAN0 | I/O/T | - | - | - | - | - | - | - | - | - | - | - | - |
| 43 | CSI_DATAP0 | Dedicated | VDD_MIPI_DPHY | - | - | MIPI_CSI_PHY<br>DATAP0 | I/O/T | - | - | - | - | - | - | - | - | - | - | - | - |

### Table 6-1. Consolidated Pin Overview (continued)

| Pin No. | Pin Name | Pin Type | Pin Providing Power | At Reset | After Reset | HP F0 | HP F0 Type | HP F1 | HP F1 Type | HP F2 | HP F2 Type | HP F3 | HP F3 Type | LP F0 | LP F0 Type | LP F1 | LP F1 Type | Analog F0 | Analog F1 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 44 | CSI_CLKP | Dedicated | VDD_MIPI_DPHY | - | - | MIPI_CSI_PHY<br>CLKP | I/O/T | - | - | - | - | - | - | - | - | - | - | - | - |
| 45 | CSI_CLKN | Dedicated | VDD_MIPI_DPHY | - | - | MIPI_CSI_PHY<br>CLKN | I/O/T | - | - | - | - | - | - | - | - | - | - | - | - |
| 46 | CSI_DATAN1 | Dedicated | VDD_MIPI_DPHY | - | - | MIPI_CSI_PHY<br>DATAN1 | I/O/T | - | - | - | - | - | - | - | - | - | - | - | - |
| 47 | CSI_DATAP1 | Dedicated | VDD_MIPI_DPHY | - | - | MIPI_CSI_PHY<br>DATAP1 | I/O/T | - | - | - | - | - | - | - | - | - | - | - | - |
| 48 | CSI_REXT | Dedicated | VDD_MIPI_DPHY | - | - | MIPI_CSI_PHY<br>4.02 KΩ EXTERNAL RESISTOR | I/O/T | - | - | - | - | - | - | - | - | - | - | - | - |
| 49 | DM | Dedicated | VDD_USBPHY | - | - | USB2 OTG PHY<br>DM | I/O/T | - | - | - | - | - | - | - | - | - | - | - | - |
| 50 | DP | Dedicated | VDD_USBPHY | - | - | USB2 OTG PHY<br>DP | I/O/T | - | - | - | - | - | - | - | - | - | - | - | - |
| 51 | VDD_USBPHY | Power | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 52 | GPIO24 | IO | VDD_IO_4 | - | - | GPIO24 | I/O/T | GPIO24 | I/O/T | - | - | - | - | - | - | - | - | USB1P1_N0 | - |
| 53 | GPIO25 | IO | VDD_IO_4 | - | IE, USB_WPU | GPIO25 | I/O/T | GPIO25 | I/O/T | - | - | - | - | - | - | - | - | USB1P1_P0 | - |
| 54 | NC | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 55 | GPIO26 | IO | VDD_IO_4 | - | - | GPIO26 | I/O/T | GPIO26 | I/O/T | - | - | - | - | - | - | - | - | USB1P1_N1 | - |
| 56 | GPIO27 | IO | VDD_IO_4 | - | - | GPIO27 | I/O/T | GPIO27 | I/O/T | - | - | - | - | - | - | - | - | USB1P1_P1 | - |
| 57 | GPIO28 | IO | VDD_IO_4 | - | - | GPIO28 | I/O/T | GPIO28 | I/O/T | SPI2_CS_PAD | I/O/T | GMAC_PHY_RXDV_PAD | IO | - | - | - | - | - | - |
| 58 | GPIO29 | IO | VDD_IO_4 | - | - | GPIO29 | I/O/T | GPIO29 | I/O/T | SPI2_D_PAD | I/O/T | GMAC_PHY_RXD0_PAD | IO | - | - | - | - | - | - |
| 59 | VDD_PSRAM_0 | Power | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 60 | GPIO30 | IO | VDD_IO_4 | - | - | GPIO30 | I/O/T | GPIO30 | I/O/T | SPI2_CK_PAD | I/O/T | GMAC_PHY_RXD1_PAD | IO | - | - | - | - | - | - |
| 61 | GPIO31 | IO | VDD_IO_4 | - | - | GPIO31 | I/O/T | GPIO31 | I/O/T | SPI2_Q_PAD | I/O/T | GMAC_PHY_RXER_PAD | IO | - | - | - | - | - | - |
| 62 | VDD_IO_4 | Power | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 63 | GPIO32 | IO | VDD_IO_4 | - | - | GPIO32 | I/O/T | GPIO32 | I/O/T | SPI2_HOLD_PAD | I/O/T | GMAC_PHY_RMII_CLK_PAD | IO | - | - | - | - | - | - |
| 64 | GPIO33 | IO | VDD_IO_4 | IE | - | GPIO33 | I/O/T | GPIO33 | I/O/T | SPI2_WP_PAD | I/O/T | GMAC_PHY_TXEN_PAD | O | - | - | - | - | - | - |
| 65 | GPIO34 | IO | VDD_IO_4 | IE | - | GPIO34 | I/O/T | GPIO34 | I/O/T | SPI2_IO4_PAD | I/O/T | GMAC_PHY_TXD0_PAD | O | - | - | - | - | - | - |
| 66 | GPIO35 | IO | VDD_IO_4 | IE, WPU | - | GPIO35 | I/O/T | GPIO35 | I/O/T | SPI2_IO5_PAD | I/O/T | GMAC_PHY_TXD1_PAD | O | - | - | - | - | - | - |
| 67 | VDD_PSRAM_1 | Power | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 68 | GPIO36 | IO | VDD_IO_4 | IE | - | GPIO36 | I/O/T | GPIO36 | I/O/T | SPI2_IO6_PAD | I/O/T | GMAC_PHY_TXER_PAD | O | - | - | - | - | - | - |
| 69 | GPIO37 | IO | VDD_IO_4 | IE | IE | UART0_TXD_PAD | O | GPIO37 | I/O/T | SPI2_IO7_PAD | I/O/T | - | - | - | - | - | - | - | - |
| 70 | GPIO38 | IO | VDD_IO_4 | IE | - | UART0_RXD_PAD | I1 | GPIO38 | I/O/T | SPI2_DQS_PAD | O/T | - | - | - | - | - | - | - | - |
| 71 | VDDO_FLASH | Power | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 72 | VDDO_PSRAM | Power | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 73 | VDDO_3 | Power | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 74 | VDD_IO_4 | Power | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 75 | VDD_LDO | Power | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 76 | VDD_HP_2 | Power | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 77 | VDD_DCDCC | Power | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 78 | FB_DCDC | Analog | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 79 | EN_DCDC | Analog | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 80 | GPIO39 | IO | VDD_IO_5 | - | - | SD1_CDATA0_PAD | I/O/T | GPIO39 | I/O/T | - | - | REF_50M_CLK_PAD | O | - | - | - | - | - | - |
| 81 | GPIO40 | IO | VDD_IO_5 | - | - | SD1_CDATA1_PAD | I/O/T | GPIO40 | I/O/T | - | - | GMAC_PHY_TXEN_PAD | O | - | - | - | - | - | - |
| 82 | GPIO41 | IO | VDD_IO_5 | - | - | SD1_CDATA2_PAD | I/O/T | GPIO41 | I/O/T | - | - | GMAC_PHY_TXD0_PAD | O | - | - | - | - | - | - |
| 83 | GPIO42 | IO | VDD_IO_5 | - | - | SD1_CDATA3_PAD | I/O/T | GPIO42 | I/O/T | - | - | GMAC_PHY_TXD1_PAD | O | - | - | - | - | - | - |
| 84 | GPIO43 | IO | VDD_IO_5 | - | - | SD1_CCLK_PAD | O | GPIO43 | I/O/T | - | - | GMAC_PHY_TXER_PAD | O | - | - | - | - | - | - |
| 85 | VDD_IO_5 | Power | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 86 | GPIO44 | IO | VDD_IO_5 | - | - | SD1_CCMD_PAD | I/O/T | GPIO44 | I/O/T | - | - | GMAC_RMII_CLK_PAD | IO | - | - | - | - | - | - |
| 87 | GPIO45 | IO | VDD_IO_5 | - | - | SD1_CDATA4_PAD | I/O/T | GPIO45 | I/O/T | - | - | GMAC_PHY_RXDV_PAD | IO | - | - | - | - | - | - |
| 88 | GPIO46 | IO | VDD_IO_5 | - | - | SD1_CDATA5_PAD | I/O/T | GPIO46 | I/O/T | - | - | GMAC_PHY_RXD0_PAD | IO | - | - | - | - | - | - |
| 89 | GPIO47 | IO | VDD_IO_5 | - | - | SD1_CDATA6_PAD | I/O/T | GPIO47 | I/O/T | - | - | GMAC_PHY_RXD1_PAD | IO | - | - | - | - | - | - |
| 90 | GPIO48 | IO | VDD_IO_5 | - | - | SD1_CDATA7_PAD | I/O/T | GPIO48 | I/O/T | - | - | GMAC_PHY_RXER_PAD | IO | - | - | - | - | - | - |
| 91 | VDD_HP_3 | Power | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 92 | GPIO49 | IO | VDD_IO_6 | - | - | GPIO49 | I/O/T | GPIO49 | I/O/T | - | - | GMAC_PHY_TXEN_PAD | IO | - | - | - | - | ADC2_CHANNEL0 | - |
| 93 | GPIO50 | IO | VDD_IO_6 | - | - | GPIO50 | I/O/T | GPIO50 | I/O/T | - | - | GMAC_RMII_CLK_PAD | IO | - | - | - | - | ADC2_CHANNEL1 | - |
| 94 | GPIO51 | IO | VDD_IO_6 | - | - | GPIO51 | I/O/T | GPIO51 | I/O/T | - | - | GMAC_PHY_RXDV_PAD | IO | - | - | - | - | ADC2_CHANNEL2 | ANA_COMP0 |
| 95 | GPIO52 | IO | VDD_IO_6 | - | - | GPIO52 | I/O/T | GPIO52 | I/O/T | - | - | GMAC_PHY_RXD0_PAD | IO | - | - | - | - | ADC2_CHANNEL3 | ANA_COMP0 |
| 96 | VDD_IO_6 | Power | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |

### Table 6-1. Consolidated Pin Overview (continued)

| Pin No. | Pin Name | Pin Type | Pin Providing Power | At Reset | After Reset | HP F0 | HP F0 Type | HP F1 | HP F1 Type | HP F2 | HP F2 Type | HP F3 | HP F3 Type | LP F0 | LP F0 Type | LP F1 | LP F1 Type | Analog F0 | Analog F1 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 97 | GPIO53 | IO | VDD_IO_6 | - | - | GPIO53 | I/O/T | GPIO53 | I/O/T | - | - | GMAC_PHY_RXD1_PAD | IO | - | - | - | - | ADC2_CHANNEL4 | ANA_COMP1 |
| 98 | GPIO54 | IO | VDD_IO_6 | - | - | GPIO54 | I/O/T | GPIO54 | I/O/T | - | - | GMAC_PHY_RXER_PAD | IO | - | - | - | - | ADC2_CHANNEL5 | ANA_COMP1 |
| 99 | XTAL_N | Analog | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 100 | XTAL_P | Analog | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 101 | VDD_AA | Power | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 102 | VDD_BAT | Power | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 103 | CHIP_PU | Analog | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 104 | GPIO0 | IO | VDD_LP/VDD_BAT | - | - | GPIO0 | I/O/T | GPIO0 | I/O/T | - | - | - | - | LP_GPIO0 | I/O/T | LP_GPIO0 | I/O/T | XTAL_32K_N | - |
| 105 | GND | Power | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - | - |

* For details, see Section 2 Pins. Regarding highlighted cells, see Section 2.3.4 Restrictions for GPIOs and LP GPIOs.
