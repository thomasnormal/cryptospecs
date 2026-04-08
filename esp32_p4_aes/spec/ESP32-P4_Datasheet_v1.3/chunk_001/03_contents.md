# Contents

## Contents

### Product Overview

- Features 2
- Applications 5

### 1 ESP32-P4 Series Comparison

- 1.1 Nomenclature 11
- 1.2 Comparison 11

### 2 Pins

- 2.1 Pin Layout 12
- 2.2 Pin Overview 13
- 2.3 IO Pins 17
  - 2.3.1 IO MUX Functions 17
  - 2.3.2 LP IO MUX Functions 21
  - 2.3.3 Analog Functions 22
  - 2.3.4 Restrictions for GPIOs and LP GPIOs 24
- 2.4 Dedicated Interface Pins 25
- 2.5 Analog Pins 27
- 2.6 Power Supply 28
  - 2.6.1 Power Pins 28
  - 2.6.2 Power Scheme 28
  - 2.6.3 Chip Power-up and Reset 29
- 2.7 Pin Mapping Between Chip and Flash 31

### 3 Boot Configurations

- 3.1 Chip Boot Mode Control 33
- 3.2 VDDO_FLASH Voltage Control 34
- 3.3 ROM Messages Printing Control 34
- 3.4 JTAG Signal Source Control 35

### 4 Functional Description

- 4.1 System 36
  - 4.1.1 Microprocessor and Master 36
    - 4.1.1.1 High-Performance CPU 36
    - 4.1.1.2 RISC-V Trace Encoder (TRACE) 36
    - 4.1.1.3 Processor Instruction Extensions 37
    - 4.1.1.4 Low-Power CPU 38
  - 4.1.2 System DMA 38
    - 4.1.2.1 GDMA Controller (GDMA-AHB, GDMA-AXI) 38
    - 4.1.2.2 VDMA Controller (VDMA) 39
    - 4.1.2.3 2D-DMA Controller (2D-DMA) 40
  - 4.1.3 Memory Organization 40
    - 4.1.3.1 System and Memory 41
    - 4.1.3.2 eFuse Controller 42
    - 4.1.3.3 Cache 42
  - 4.1.4 System Components 43
    - 4.1.4.1 GPIO Matrix and IO MUX 43
    - 4.1.4.2 Reset 44
    - 4.1.4.3 Clock 45
    - 4.1.4.4 Interrupt Matrix 45
    - 4.1.4.5 Event Task Matrix 45
    - 4.1.4.6 Low-Power Management 46
    - 4.1.4.7 System Timer 46
    - 4.1.4.8 Timer Group (TIMG) 47
    - 4.1.4.9 Watchdog Timers (WDT) 47
    - 4.1.4.10 RTC Timer 48
    - 4.1.4.11 Permission Control (PMS) 48
    - 4.1.4.12 System Registers 49
    - 4.1.4.13 Debug Assistant 49
    - 4.1.4.14 LP Mailbox 49
    - 4.1.4.15 Brown-out Detector 50
  - 4.1.5 Cryptography/Security Component 50
    - 4.1.5.1 AES Accelerator (AES) 50
    - 4.1.5.2 ECC Accelerator (ECC) 51
    - 4.1.5.3 HMAC Accelerator (HMAC) 51
    - 4.1.5.4 RSA Accelerator (RSA) 51
    - 4.1.5.5 SHA Accelerator (SHA) 52
    - 4.1.5.6 Digital Signature Algorithm (DSA) 52
    - 4.1.5.7 Elliptic Curve Digital Signature Algorithm (ECDSA) 53
    - 4.1.5.8 External Memory Encryption and Decryption (XTS_AES) 53
    - 4.1.5.9 Random Number Generator (RNG) 54
- 4.2 Peripherals 55
  - 4.2.1 Image Processing 55
    - 4.2.1.1 JPEG Codec 55
    - 4.2.1.2 Image Signal Processor (ISP) 56
    - 4.2.1.3 Pixel-Processing Accelerator (PPA) 57
    - 4.2.1.4 LCD and Camera Controller (LCD_CAM) 57
    - 4.2.1.5 H264 Encoder 58
    - 4.2.1.6 MIPI CSI 59
    - 4.2.1.7 MIPI DSI 59
  - 4.2.2 Connectivity Interface 59
    - 4.2.2.1 UART Controller (UART) 60
    - 4.2.2.2 SPI Controller (SPI) 60
    - 4.2.2.3 I2C Controller (I2C) 63
    - 4.2.2.4 Analog I2C Controller 63
    - 4.2.2.5 I3C Controller 64
    - 4.2.2.6 I2S Controller (I2S) 64
    - 4.2.2.7 LP I2S Controller 65
    - 4.2.2.8 Pulse Count Controller (PCNT) 66
    - 4.2.2.9 USB 2.0 High-Speed OTG 66
    - 4.2.2.10 USB 2.0 Full-Speed OTG 67
    - 4.2.2.11 USB Serial/JTAG Controller (USB_SERIAL_JTAG) 68
    - 4.2.2.12 Ethernet Media Access Controller (EMAC) 69
    - 4.2.2.13 Two-Wire Automotive Interface (TWAI) 71
    - 4.2.2.14 SD/MMC Host Controller (SDHOST) 72
    - 4.2.2.15 LED PWM Controller (LEDC) 72
    - 4.2.2.16 Motor Control PWM (MCPWM) 73
    - 4.2.2.17 Remote Control Peripheral (RMT) 73
    - 4.2.2.18 Parallel IO Controller (PARLIO) 74
    - 4.2.2.19 BitScrambler 75
  - 4.2.3 Analog Signal Processing 75
    - 4.2.3.1 Touch Sensor 75
    - 4.2.3.2 Temperature Sensor (TSENS) 76
    - 4.2.3.3 ADC Controller (ADC) 77
    - 4.2.3.4 Analog Voltage Comparator 77
    - 4.2.3.5 Voice Activity Detection (VAD) 78

### 5 Electrical Characteristics

- 5.1 Absolute Maximum Ratings 79
- 5.2 Recommended Operating Conditions 79
- 5.3 VDDO_FLASH Output Characteristics 80
- 5.4 DC Characteristics (3.3 V, 25 °C) 80
- 5.5 ADC Characteristics 80
- 5.6 Current Consumption in Active and Low-power Modes 81
- 5.7 Memory Specifications 82
- 5.8 Reliability 83

### 6 Packaging 84

### Related Documentation and Resources 85

### Appendix A – ESP32-P4 Consolidated Pin Overview 86

### Revision History 89

## List of Tables

- 1-1 ESP32-P4 Series Comparison 11
- 2-1 Pin Overview 13
- 2-2 Peripheral Signals Routed via IO MUX 17
- 2-3 IO MUX Pin Functions 18
- 2-4 LP Peripheral Signals Routed via LP IO MUX 21
- 2-5 LP IO MUX Functions 21
- 2-6 Analog Signals Routed to Analog Functions 22
- 2-7 Analog Functions 22
- 2-8 Peripheral-Dedicated Signals 25
- 2-9 Dedicated Interface Pins 25
- 2-10 Analog Pins 27
- 2-11 Power Pins 28
- 2-12 Voltage Regulators 29
- 2-13 Description of Timing Parameters for Power-up and Reset 30
- 2-14 Pin Mapping Between Chip and off-package Flash 31
- 3-1 Default Configuration of Strapping Pins 32
- 3-2 Description of Timing Parameters for the Strapping Pins 33
- 3-3 Boot Mode Control 33
- 3-4 VDDO_FLASH Voltage Control 34
- 3-5 UART0 ROM Message Printing Control 34
- 3-6 USB Serial/JTAG ROM Message Printing Control 35
- 3-7 JTAG Signal Source Control 35
- 4-1 UART and LP UART Feature Comparison 60
- 5-1 Absolute Maximum Ratings 79
- 5-2 Recommended Operating Conditions 79
- 5-3 VDDO_FLASH Internal and Output Characteristics 80
- 5-4 DC Characteristics (3.3 V, 25 °C) 80
- 5-5 ADC Characteristics 81
- 5-6 ADC Calibration Results 81
- 5-7 Current Consumption in Active Mode 81
- 5-8 Current Consumption in Low-Power Modes 82
- 5-9 Flash Specifications 82
- 5-10 PSRAM Specifications 83
- 5-11 Reliability Qualifications 83

## List of Figures

- 1-1 ESP32-P4 Series Nomenclature 11
- 2-1 ESP32-P4 Pin Layout (Top View) 12
- 2-2 ESP32-P4 Power Scheme 29
- 2-3 Visualization of Timing Parameters for Power-up and Reset 29
- 3-1 Visualization of Timing Parameters for the Strapping Pins 33
- 4-1 Address Mapping Structure 41
- 6-1 QFN104 (10×10 mm) Package 84
