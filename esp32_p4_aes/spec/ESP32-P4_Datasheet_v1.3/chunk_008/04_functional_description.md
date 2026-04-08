# 4 Functional Description

- RMII Group 2: Signals are multiplexed with GPIO40–GPIO48 via IO MUX.
- RMII Group 3: Provides partial signal routing (excluding transmit signals except for RMII_TXEN) and is multiplexed with GPIO49–GPIO54 via IO MUX.

Each RMII signal can be assigned independently to any of these three groups to form a complete RMII interface.

The MII interface, MDIO interface, and other peripheral signals can be routed to any GPIO via the GPIO Matrix for additional flexibility.

## 4.2.2.13 Two-Wire Automotive Interface (TWAI)

ESP32-P4 contains three TWAI controllers. Each controller can individually be connected to a TWAI bus via an external transceiver.

### Feature List

- Compatibility with ISO 11898-1 protocol (CAN Specification 2.0)
- Standard Frame Format (11-bit ID) and Extended Frame Format (29-bit ID)
- Bit rates from 1 Kbit/s to 1 Mbit/s
- Multiple modes of operation:
  - Normal
  - Listen-only (no influence on bus)
  - Self-test (no acknowledgment required during data transmission)
- 64-byte Receive FIFO
- Special transmissions:
  - Single-shot transmissions (does not automatically re-transmit upon error)
  - Self-reception (the TWAI controller transmits and receives messages simultaneously)
- Acceptance Filter (supports Single and Dual-filter modes)
- Error detection and handling:
  - Error counters
  - Configurable error warning limit
  - Error code capture
  - Arbitration lost capture
  - Automatic transceiver standby

### Pin Assignment

The pins for the two-wire automotive interface can be chosen from any GPIOs via the GPIO Matrix.

## 4.2.2.14 SD/MMC Host Controller (SDHOST)

ESP32-P4 has an SD/MMC Host Controller.

### Feature List

- Two external cards
- SD memory Card specification v3.0 and v3.01
- Secure Digital I/O (SDIO 3.0)
- MMC: v4.41, v4.5, and v4.51
- CE-ATA: v1.1
- 1-bit, 4-bit, and 8-bit modes

### Pin Assignment

For the SD/MMC host controller, card one (SDMMC_HOST_SLOT_0) signals are multiplexed with GPIO39–GPIO48, the second RMII interface of EMAC, and the output signal of 50 MHz clock via IO MUX. Card two (SDMMC_HOST_SLOT_1) signals can be routed to any GPIOs via the GPIO matrix.

For the SDIO2.0 interface, the pins can be chosen from any GPIOs via the GPIO Matrix.

## 4.2.2.15 LED PWM Controller (LEDC)

The LED PWM Controller is a peripheral designed to generate PWM signals for LED control. It has specialized features such as automatic duty cycle fading. However, the LED PWM Controller can also be used to generate PWM signals for other purposes.

### Feature List

- Eight independent PWM generators (i.e., eight channels)
- Maximum PWM duty cycle resolution: 20 bits
- Four independent timers that support fractional division
- Adjustable phase of PWM signal output
- PWM duty cycle dithering
- Automatic duty cycle fading — gradual increase/decrease of a PWM’s duty cycle without interference from the processor. An interrupt will be generated upon fade completion
- Up to 16 duty cycle ranges for each PWM generator to generate gamma curve signals - each range can be independently configured in terms of fading direction (increase or decrease), fading amount (the amount by which the duty cycle increases or decreases each time), the number of fades (how many times the duty cycle fades in one range), and fading frequency
- PWM signal output in low-power mode (Light-sleep mode)
- Event generation and task response related to the Event Task Matrix (ETM) peripheral

### Pin Assignment

The pins for the LED PWM controller can be chosen from any GPIOs via the GPIO Matrix.

## 4.2.2.16 Motor Control PWM (MCPWM)

ESP32-P4 integrates two MCPWMs that can be used to drive digital motors and smart light. Every MCPWM has a clock divider (prescaler), three PWM timers, three PWM operators, a dedicated capture submodule, an Event Task Matrix (ETM) module, and a fault detection module.

### Feature List

PWM timers are used to generate timing references. The PWM operators generate desired waveform based on the timing references. By configuration, a PWM operator can use the timing reference of any PWM timer, and use the same timing reference with other PWM operators. PWM operators can also use different PWM timers’ values to produce independent PWM signals. PWM timers can be synchronized.

### Pin Assignment

The pins for the motor control PWM can be chosen from any GPIOs via the GPIO Matrix.

## 4.2.2.17 Remote Control Peripheral (RMT)

The Remote Control Peripheral (RMT) supports four channels of infrared remote transmission and four channels of infrared remote reception. By controlling pulse waveform through software, it supports various infrared and other single wire protocols.

### Feature List

- Eight channels:
  - TX channels 0–3
  - RX channels 4–7
  - Eight channels share a 384 x 32-bit RAM
- The transmitter supports:
  - Normal TX mode
  - Wrap TX mode
  - Continuous TX mode
  - Modulation on TX pulses
  - Multiple channels transmitting data simultaneously (programmable)
  - GDMA access supported by TX channel 3
- The receiver supports:
  - Normal RX mode
  - Wrap RX mode
  - RX filtering
  - Demodulation on RX pulses
  - GDMA access supported by RX channel 7

### Pin Assignment

The pins for the remote control peripheral can be chosen from any GPIOs via the GPIO Matrix.

## 4.2.2.18 Parallel IO Controller (PARLIO)

ESP32-P4 contains a Parallel IO controller (PARLIO) capable of transferring data between external devices and internal memory on a parallel bus through General Direct Memory Access (GDMA).

### Feature List

- Various clock sources:
  - Including external IO clock PAD_CLK_TX/RX and internal system clock XTAL_CLK, PLL_F160M_CLK, and RC_FAST_CLK
  - Maximum IO clock frequency of 40 MHz
  - Integer and fractional clock frequency division
- 1/2/4/8/16-bit configurable data bus width
- Full-duplex communication with 16-bit data bus width
- Bit reversal when data bus width is 1/2/4-bit
- RX unit for receiving IO parallel data, which supports:
  - Output clock gating
  - RX unit input and output clock inverse
  - Various receive modes
  - Configurable GDMA SUC EOF generation
  - Configurable IO pin of external enable signal
- TX unit for sending IO parallel data, which supports:
  - Output clock gating
  - TX unit input and output clock inverse
  - Configurable TX EOF generation
  - Valid signal output
  - Configurable bus idle value

### Pin Assignment

The pins for the parallel IO controller can be chosen from any GPIOs via the GPIO Matrix.

## 4.2.2.19 BitScrambler

The ESP32-P4 has an extensive amount of DMA-capable peripherals. These can move data from memory to an external device, and vice versa, without any interference from the CPU. This only works if the external device needs or emits the data in question in the same format as the software expects it: if not, the CPU needs to rewrite the format of the data. Examples include a need to swap bytes, reverse bytes, and shift the data left or right.

Since bitwise operations can be relatively CPU-intensive and DMA is designed specifically to offload such work from the CPU, ESP32-P4 integrates two dedicated peripherals called BitScramblers. These modules are designed to transform data formats during transfers between memory and peripherals. One BitScrambler handles memory-to-peripheral (or memory-to-memory) transfers, while the other is dedicated to peripheral-to-memory transfers. While BitScramblers can handle the bitwise operations mentioned earlier, they are in fact flexible, programmable state machines capable of performing more advanced transformations as well.

### Feature List

- Two BitScramblers, one for RX (peripheral-to-memory), one for TX (memory-to-peripheral)
- Support for memory-to-memory transfers
- Processing up to 32 bits per DMA clock period
- Data path controlled by a BitScrambler program stored in instruction memory
- Input registers able to read 0, 8, 16, or 32 bits per clock cycle
- Output registers:
  - Able to write 0, 8, 16, or 32 bits per clock cycle
  - Data sources for output register bits: 64 bits of input data, two counters, LUT RAM data, data output of last cycle, comparators
  - With some restrictions, each of the 32 output register bits can come from any bit on the data sources
- An 8 x 257-bit instruction memory for storing eight instructions, controlling control flow, and the data path
- 2048 bytes of lookup table (LUT) memory, configurable as various word widths

### Pin Assignment

The BitScrambler does not directly interact with IOs, so it has no pins assigned.

## 4.2.3 Analog Signal Processing

This subsection describes components on the chip that sense and process real-world data.

### 4.2.3.1 Touch Sensor

ESP32-P4 has 14 capacitive-sensing GPIOs, which detect variations induced by touching or approaching the GPIOs with a finger or other objects. The low-noise nature of the design and the high sensitivity of the circuit allow relatively small pads to be used. Arrays of pads can also be used, so that a larger area or more points can be detected. The touch sensing performance can be further enhanced by the waterproof design, detection of frequency hopping, and digital filtering feature.

### Feature List

- Detection of 14 capacitive touch pins
- Sampling triggered by software or dedicated hardware timer
- Two sampling methods:
  - Pulses from the touch pins used as clock signals to count the sampling period
  - Pulses from the touch pins used as digital signals; sample the rising edge of the digital signal with the system clock to count the sampling period
- Scan mode, supporting sequential sampling of multiple touch pins by configuring the Touch FSM.
- Timeout mechanism to monitor channel abnormality
- Frequency hopping to increase the anti-interference of detection
- Proximity sensing mode with up to three configurable channels
- Configuration of individual touch sensors to operate normally in sleep mode
- Wake-up by touch sensor
- Moisture resistance
- Waterproof design

### Pin Assignment

The pins of the touch sensor are multiplexed with GPIO2–GPIO15, LP_GPIO2–LP_GPIO15, LP_UART interface, and one four-line interface of SPI2. When the pins are configured for the analog function, the multiplexed digital functions are disabled.

### 4.2.3.2 Temperature Sensor (TSENS)

ESP32-P4 provides a temperature sensor for real-time monitoring of temperature changes within the chip. The sensor converts analog voltage to digital values and provides compensation for temperature offsets.

### Feature List

- Software-triggered temperature measurement, which once triggered, the sensor continuously measures temperature. Software can read the data at any time.
- Hardware-triggered automatic temperature monitoring, supporting two wake-up modes
- Configurable temperature offset based on the application scenario for improved accuracy
- Configurable temperature measurement range
- Support for Event Task Matrix (ETM)-related events and tasks

### Pin Assignment

The temperature sensor does not directly interact with IOs, so it has no pins assigned.

### 4.2.3.3 ADC Controller (ADC)

ESP32-P4 integrates two 12-bit successive approximation ADCs (SAR ADCs) for measuring analog signals from up to 14 pins.

### Feature List

- HP ADC and LP ADC controllers can control the SAR ADC via software
- 12-bit resolution
- Analog input sampling from up to 14 pins
- HP ADC controllers:
  - Multi-channel sampling control module with configurable channel sampling sequence
  - Mode control module supporting dual HP ADC sampling
  - Two filters with configurable filter coefficients
  - Two threshold monitors that trigger an interrupt when filtered data exceeds a high threshold or falls below a low threshold
  - Continuous transfer of conversion results to memory via the GDMA interface
- LP ADC controllers:
  - One-shot sampling mode
  - Sampling in sleep mode (e.g., Deep-sleep)
- Event Task Matrix (ETM) support for various events and tasks

### Pin Assignment

The pins of the ADC controller are multiplexed with GPIO16–GPIO23, GPIO49–GPIO54, the interfaces of two analog voltage comparators, and the third RMII interface of EMAC.

### 4.2.3.4 Analog Voltage Comparator

ESP32-P4 integrates two analog voltage comparators. These comparators rely on special pads that support voltage comparison functionality to monitor voltage changes on these pads.

### Feature List

- Voltage comparison
  - Configurable voltage comparison mode
  - Configurable reference voltage
- Interrupt upon changes of voltage comparison result
- ETM event generation

### Pin Assignment

The pins of the analog voltage comparator are multiplexed with GPIO51–GPIO52, GPIO53–GPIO54, the interface of one ADC controller, and the third RMII interface of EMAC.

### 4.2.3.5 Voice Activity Detection (VAD)

ESP32-P4 integrates a Voice Activity Detection (VAD) module. This module facilitates the hardware implementation of the first-stage algorithm for voice wake-up and other multimedia functions. Additionally, it provides hardware support for low-power voice wake-up solutions.

### Feature List

- VAD algorithm processes voice data frame by frame, with each frame containing 256 data points. The data sampling rate is 8 kHz, and the bit width is 16 bits
- 2 KB buffer that stores up to four frames of data
- Independent system wake-up source
- Configurable interrupt sources
- Flexible configuration of algorithm parameters

### Pin Assignment

The VAD module does not directly interact with IOs, so it has no pins assigned.
