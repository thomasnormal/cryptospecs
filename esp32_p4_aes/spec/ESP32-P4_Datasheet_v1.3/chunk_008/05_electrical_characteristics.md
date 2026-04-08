# 5 Electrical Characteristics

## 5.1 Absolute Maximum Ratings

Stresses above those listed in Table 5-1 Absolute Maximum Ratings may cause permanent damage to the device. These are stress ratings only and normal operation of the device at these or any other conditions beyond those indicated in Section 5.2 Recommended Operating Conditions is not implied. Exposure to absolute-maximum-rated conditions for extended periods may affect device reliability.

Table 5-1. Absolute Maximum Ratings

| Parameter | Description | Min | Max | Unit |
| --- | --- | --- | --- | --- |
| VDD_LDO, VDD_DCDCC, VDD_ANA, VDD_BAT, VDD_LP | Allowed input voltage | −0.3 | 3.6 | V |
| VDD_IO_0, VDD_FLASHIO^3, VDD_IO_4, VDD_IO_5, VDD_IO_6 | Allowed input voltage | 1.62/−0.3 | 1.98/3.6 | V |
| VDD_PSRAM_0, VDD_PSRAM_1 | Allowed input voltage | 1.62 | 1.98 | V |
| VDD_HP_0, VDD_HP_2, VDD_HP_3 | Allowed input voltage | 0 | 1.3 | V |
| VDD_MIPI_DPHY | Allowed input voltage | 0 | 2.75 | V |
| VDD_USBPHY | Allowed input voltage | −0.66 | 3.96 | V |
| I<sub>output</sub><sup>2</sup> | Cumulative IO output current | — | 1500 | mA |
| T<sub>STORE</sub> | Storage temperature | −40 | 150 | °C |

1 For more information on input power pins, see Section 2.6.1 Power Pins.
2 The product proved to be fully functional after all its IO pins were pulled high while being connected to ground for 24 consecutive hours at ambient temperature of 25 °C.
3 VDD_FLASHIO provides power for flash IO, and the voltage should be adjusted according to the specific flash model.

## 5.2 Recommended Operating Conditions

Table 5-2. Recommended Operating Conditions

| Parameter | Description | Min | Typ | Max | Unit |
| --- | --- | --- | --- | --- | --- |
| VDD_LDO, VDD_DCDCC, VDD_ANA, VDD_LP | Recommended input voltage | 3.0 | 3.3 | 3.6 | V |
| VDD_BAT | Recommended input voltage | 2.5 | 3.3 | 3.6 | V |
| VDD_IO_0, VDD_FLASHIO, VDD_IO_4, VDD_IO_5, VDD_IO_6 | Recommended input voltage | 1.65/3.0 | 1.8/3.3 | 1.95/3.6 | V |
| VDD_PSRAM_0, VDD_PSRAM_1 | Recommended input voltage | 1.65 | 1.8 | 1.95 | V |
| VDD_HP_0, VDD_HP_2, VDD_HP_3^1 | Recommended input voltage | 0.99 | 1.1 | 1.3 | V |
| VDD_MIPI_DPHY | Recommended input voltage | 2.25 | 2.5 | 2.75 | V |
| VDD_USBPHY | Recommended input voltage | 2.97 | 3.3 | 3.63 | V |
| I_VDD | Current supplied to core | 0.5 | — | — | A |
| T_A | Ambient temperature | −40 | — | 85 | °C |

1 The chip can automatically adjust the input voltage of VDD_HP_x based on the situation.

## 5.3 VDDO_FLASH Output Characteristics

Table 5-3. VDDO_FLASH Internal and Output Characteristics

| Parameter | Description | Typ | Unit |
| --- | --- | --- | --- |
| R_VFB | VDDO_FLASH powered by VDD_LDO via R_VFB for 3.3 V flash^1 | 3 | Ω |
| I_VFB | Output current when VDDO_FLASH is powered by Flash Voltage Regulator for 1.8 V flash | 50 | mA |

1 See in conjunction with Section 2.6.2 Power Scheme.
1 VDD_LDO must be more than VDD_flash_min + I_flash_max × R_VFB:

where

- VDD_flash_min – minimum operating voltage of flash
- I_flash_max – maximum operating current of flash

## 5.4 DC Characteristics (3.3 V, 25 °C)

Table 5-4. DC Characteristics (3.3 V, 25 °C)

| Parameter | Description | Min | Typ | Max | Unit |
| --- | --- | --- | --- | --- | --- |
| C_IN | Pin capacitance | — | 2 | — | pF |
| V_IH | High-level input voltage | 0.75 × VDD^1 | — | VDD^1 + 0.3 | V |
| V_IL | Low-level input voltage | −0.3 | — | 0.25 × VDD^1 | V |
| I_IH | High-level input current | — | — | 50 | nA |
| I_IL | Low-level input current | — | — | 50 | nA |
| V_OH^2 | High-level output voltage | 0.8 × VDD^1 | — | — | V |
| V_OL^2 | Low-level output voltage | — | — | 0.1 × VDD^1 | V |
| I_OH | High-level source current (VDD^1 = 3.3 V, V_OH >= 2.64 V, PAD_DRIVER = 3) | — | 40 | — | mA |
| I_OL | Low-level sink current (VDD^1 = 3.3 V, V_OL = 0.495 V, PAD_DRIVER = 3) | — | 28 | — | mA |
| R_PU | Pull-up resistor | — | 45 | — | kΩ |
| R_PD | Pull-down resistor | — | 45 | — | kΩ |
| V_IH_nRST | Chip reset release voltage (CHIP_PU should satisfy the required voltage) | 0.75 × VDD_BAT | — | VDD_BAT + 0.3 | V |
| V_IL_nRST | Chip reset voltage (CHIP_PU should satisfy the required voltage) | −0.3 | — | 0.25 × VDD_BAT | V |

1 VDD is the voltage for power pins VDD_IO_0/4/5/6.
2 V_OH and V_OL are measured using high-impedance load.

## 5.5 ADC Characteristics

The measurements in this section are taken with an external 100 nF capacitor connected to the ADC, using DC signals as input, and at an ambient temperature of 25 °C.
