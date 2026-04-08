# 5 Electrical Characteristics

### Table 5-5. ADC Characteristics

| Symbol | Min | Max | Unit |
| --- | --- | --- | --- |
| DNL (Differential nonlinearity)¹ | −1 | 3 | LSB |
| INL (Integral nonlinearity) | −5 | 3 | LSB |
| Sampling rate | — | 100 | kSPS² |

¹ To get better DNL results, you can sample multiple times and apply a filter, or calculate the average value.
² kSPS means kilo samples-per-second.

The calibrated ADC results after hardware calibration and software calibration are shown in Table 5-6 ADC Characteristics. For higher accuracy, you may implement your own calibration methods.

### Table 5-6. ADC Calibration Results

| Parameter | Description | Min | Max | Unit |
| --- | --- | --- | --- | --- |
| Total error | ATTEN0, effective measurement range of 0–1000 | −12 | 12 | mV |
| Total error | ATTEN1, effective measurement range of 0–1300 | −12 | 12 | mV |
| Total error | ATTEN2, effective measurement range of 0–1900 | −12 | 12 | mV |
| Total error | ATTEN3, effective measurement range of 0–3300 | −15 | 15 | mV |

## 5.6 Current Consumption in Active and Low-power Modes

### Table 5-7. Current Consumption in Active Mode

| Work mode | Frequency (MHz) | Description | Typ¹ (mA) | Typ² (mA) |
| --- | --- | --- | --- | --- |
| Active³ | 360 | WAIT1 (Dual core in idle state) | 35 | 65 |
| Active³ | 360 | Dual-core while(1) loop operation | 80 | 103 |
| Active³ | 360 | Single core running CoreMark instructions, the other core in idle state | 70 | 92 |
| Active³ | 360 | Dual core running 32-bit data access instructions | 92 | 123 |
| Active³ | 180 | WAIT1 (Dual core in idle state) | 32 | 59 |
| Active³ | 180 | Dual-core while(1) loop operation | 56 | 77 |
| Active³ | 180 | Single core running CoreMark instructions, the other core in idle state | 51 | 72 |
| Active³ | 180 | Dual core running 32-bit data access instructions | 65 | 87 |
| Active³ | 90 | WAIT1 (Dual core in idle state) | 28 | 44 |
| Active³ | 90 | Dual-core while(1) loop operation | 40 | 53 |
| Active³ | 90 | Single core running CoreMark instructions, the other core in idle state | 37 | 51 |
| Active³ | 90 | Dual core running 32-bit data access instructions | 45 | 61 |
| Active³ | 40 | WAIT1 (Dual core in idle state) | 26 | 35 |
| Active³ | 40 | Dual-core while(1) loop operation | 31 | 39 |
| Active³ | 40 | Single core running CoreMark instructions, the other core in idle state | 30 | 38 |
| Active³ | 40 | Dual core running 32-bit data access instructions | 33 | 41 |

¹ Current consumption when all peripheral clocks are disabled.
² Current consumption when all peripheral clocks are enabled. In practice, the current consumption might be different depending on which peripherals are enabled.
³ In Active mode, the current consumption might be higher when accessing flash/PSRAM.

### Table 5-8. Current Consumption in Low-Power Modes

| Mode | Description | Typ (mA)¹ |
| --- | --- | --- |
| Light-sleep² | All GPIOs are high-impedance, and all power supplies are enabled | 3.5 |
| Light-sleep² | All GPIOs are high-impedance, most of peripherals are disabled, and chip is connected through USB | 0.25 |
| Light-sleep² | All peripherals are disabled, and data is stored in HP memory | 0.2 |
| Deep-sleep | LP timer and LP memory are powered on | 0.025 |
| Power off | CHIP_PU is set to low level, the chip is powered off | 0.002 |

¹ The power consumption data was measured with USB 2.0 not working.
² The current in Light-sleep mode refers to the current measured when the PSRAM is not powered. In Light-sleep mode, if the PSRAM is powered on, the chip’s internal current increases by about 0.2 mA, in addition to the current required for the PSRAM’s operating mode.


# 5 Electrical Characteristics (continued)

## 5.6 Current Consumption in Active and Low-power Modes (continued)

| Work mode | Frequency (MHz) | Description | Typ¹ (mA) | Typ² (mA) |
| --- | --- | --- | --- | --- |
| Active³ | 360 | WAIT1 (Dual core in idle state) | 35 | 65 |
| Active³ | 360 | Dual-core while(1) loop operation | 80 | 103 |
| Active³ | 360 | Single core running CoreMark instructions, the other core in idle state | 70 | 92 |
| Active³ | 360 | Dual core running 32-bit data access instructions | 92 | 123 |
| Active³ | 180 | WAIT1 (Dual core in idle state) | 32 | 59 |
| Active³ | 180 | Dual-core while(1) loop operation | 56 | 77 |
| Active³ | 180 | Single core running CoreMark instructions, the other core in idle state | 51 | 72 |
| Active³ | 180 | Dual core running 32-bit data access instructions | 65 | 87 |
| Active³ | 90 | WAIT1 (Dual core in idle state) | 28 | 44 |
| Active³ | 90 | Dual-core while(1) loop operation | 40 | 53 |
| Active³ | 90 | Single core running CoreMark instructions, the other core in idle state | 37 | 51 |
| Active³ | 90 | Dual core running 32-bit data access instructions | 45 | 61 |
| Active³ | 40 | WAIT1 (Dual core in idle state) | 26 | 35 |
| Active³ | 40 | Dual-core while(1) loop operation | 31 | 39 |
| Active³ | 40 | Single core running CoreMark instructions, the other core in idle state | 30 | 38 |
| Active³ | 40 | Dual core running 32-bit data access instructions | 33 | 41 |

## 5.7 Memory Specifications

The data below is sourced from the memory vendor datasheet. These values are guaranteed through design and/or characterization but are not fully tested in production. Devices are shipped with the memory erased.

### Table 5-9. Flash Specifications

| Parameter | Description | Min | Typ | Max | Unit |
| --- | --- | --- | --- | --- | --- |
| VCC | Power supply voltage (1.8 V) | 1.65 | 1.80 | 2.00 | V |
| VCC | Power supply voltage (3.3 V) | 2.7 | 3.3 | 3.6 | V |
| F<sub>C</sub> | Maximum clock frequency | 80 | — | — | MHz |
| — | Program/erase cycles | 100,000 | — | — | cycles |
| T<sub>RET</sub> | Data retention time | 20 | — | — | years |
| T<sub>PP</sub> | Page program time | — | 0.8 | 5 | ms |
| T<sub>SE</sub> | Sector erase time (4 KB) | — | 70 | 500 | ms |
| T<sub>BE1</sub> | Block erase time (32 KB) | — | 0.2 | 2 | s |
| T<sub>BE2</sub> | Block erase time (64 KB) | — | 0.3 | 3 | s |
| T<sub>CE</sub> | Chip erase time (16 Mb) | — | 7 | 20 | s |
| T<sub>CE</sub> | Chip erase time (32 Mb) | — | 20 | 60 | s |
| T<sub>CE</sub> | Chip erase time (64 Mb) | — | 25 | 100 | s |
| T<sub>CE</sub> | Chip erase time (128 Mb) | — | 60 | 200 | s |
| T<sub>CE</sub> | Chip erase time (256 Mb) | — | 70 | 300 | s |


# 5 Electrical Characteristics (continued)

### Table 5-9. Flash Specifications (continued)

| Parameter | Description | Min | Typ | Max | Unit |
| --- | --- | --- | --- | --- | --- |
| T<sub>CE</sub> | Chip erase time (16 Mb) | — | 7 | 20 | s |
| T<sub>CE</sub> | Chip erase time (32 Mb) | — | 20 | 60 | s |
| T<sub>CE</sub> | Chip erase time (64 Mb) | — | 25 | 100 | s |
| T<sub>CE</sub> | Chip erase time (128 Mb) | — | 60 | 200 | s |
| T<sub>CE</sub> | Chip erase time (256 Mb) | — | 70 | 300 | s |

### Table 5-10. PSRAM Specifications

| Parameter | Description | Min | Typ | Max | Unit |
| --- | --- | --- | --- | --- | --- |
| VCC | Power supply voltage (1.8 V) | 1.62 | 1.80 | 1.98 | V |
| VCC | Power supply voltage (3.3 V) | 2.7 | 3.3 | 3.6 | V |
| F<sub>C</sub> | Maximum clock frequency | 80 | — | — | MHz |

## 5.8 Reliability

### Table 5-11. Reliability Qualifications

| Test Item | Test Conditions | Test Standard |
| --- | --- | --- |
| HTOL (High Temperature Operating Life) | 125 °C, 1000 hours | JESD22-A108 |
| ESD (Electro-Static Discharge Sensitivity) | HBM (Human Body Mode)¹ ± 2000 V | JS-001 |
| ESD (Electro-Static Discharge Sensitivity) | CDM (Charge Device Mode)² ± 1000 V | JS-002 |
| Latch up | Current trigger ± 200 mA | JESD78 |
| Latch up | Voltage trigger 1.5 × VDD<sub>max</sub> | JESD78 |
| Preconditioning | Bake 24 hours @125 °C<br>Moisture soak (level 3: 192 hours @30 °C, 60% RH)<br>IR reflow solder: 260 + 0 °C, 20 seconds, three times | J-STD-020, JESD47, JESD22-A113 |
| TCT (Temperature Cycling Test) | −65 °C / 150 °C, 500 cycles | JESD22-A104 |
| uHAST (Highly Accelerated Stress Test, unbiased) | 130 °C, 85% RH, 96 hours | JESD22-A118 |
| HTSL (High Temperature Storage Life) | 150 °C, 1000 hours | JESD22-A103 |
| LTSL (Low Temperature Storage Life) | −40 °C, 1000 hours | JESD22-A119 |

¹ JEDEC document JEP155 states that 500 V HBM allows safe manufacturing with a standard ESD control process.
² JEDEC document JEP157 states that 250 V CDM allows safe manufacturing with a standard ESD control process.
