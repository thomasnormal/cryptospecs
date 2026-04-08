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
