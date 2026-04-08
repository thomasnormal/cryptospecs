# 4 Functional Description

- FLASH MSPI SPI0
- FLASH MSPI SPI1
- PSRAM MSPI controller
  - PSRAM MSPI SPI0
  - PSRAM MSPI SPI1
- General Purpose SPI2 (GP-SPI2)
- General Purpose SPI3 (GP-SPI3)
- Low-Power SPI (LP-SPI)

**Feature List**

GP-SPI has the following features:

- Works as master or as slave
- Half- and full-duplex communications
- CPU- and DMA-controlled transfers
- Various data modes
  - GP-SPI2
    - 1-bit SPI mode
    - 2-bit Dual SPI mode
    - 4-bit Quad SPI mode
    - QPI mode
    - 8-bit Octal SPI mode (available only when GP-SPI2 works as a master)
    - OPI mode (available only when GP-SPI2 works as a master)
  - GP-SPI3
    - 1-bit SPI mode
    - 2-bit Dual SPI mode
    - 4-bit Quad SPI mode
    - QPI mode
- Configurable module clock frequency
  - Master: up to 80 MHz
  - Slave: up to 60 MHz
- Configurable data length
  - CPU-controlled transfer as master or as slave: 1–64 bytes
  - DMA-controlled single transfer as master: 1–32 KB
  - DMA-controlled configurable segmented transfer as master: data length is unlimited
  - DMA-controlled single transfer or segmented transfer as slave: data length is unlimited
- Configurable bit read/write order
- Independent interrupts for CPU-controlled transfer and DMA-controlled transfer
- Configurable clock polarity and phase
- Four SPI clock modes: mode 0–mode 3
- Multiple CS lines as master
  - GP-SPI2: CS0–CS5
  - GP-SPI3: CS0–CS2
- Able to communicate with SPI devices, such as a sensor, a screen controller, as well as a flash or RAM chip

LP-SPI is a simplified version of GP-SPI and has a subset of GP-SPI's features:

- Works as a master or as a slave
- Half- and full-duplex communications
- CPU-controlled transfer
- 1-bit SPI data mode
- Configurable module clock frequency:
  - Master: up to 40 MHz
  - Slave: up to 40 MHz
- Configurable data length:
  - CPU-controlled transfer as master or as slave: 1–64 bytes
- Configurable bit read/write order
- Interrupts for CPU-controlled transfer
- Configurable clock polarity and phase
- Four SPI clock modes: mode 0–mode 3
- One CS line as master: CS0
- Wake-up feature as slave (the only new feature compared with GP-SPI)

**Pin Assignment**

The Flash SPI interface uses the dedicated digital pins 27–33.

The GP-SPI2 controller includes one four-line interface and one eight-line interface. The pins connected to the four-line interface are multiplexed with GPIO6–GPIO11 via the IO MUX. The pins connected to the eight-line interface are multiplexed with GPIO28–GPIO38, UART0 interface, and the first RMII interface of EMAC controller via the IO MUX. If high-speed performance is not critical for the GP-SPI2 interface, you can select pins from any GPIOs via the GPIO Matrix.

For GP-SPI3, the pins used can be chosen from any GPIOs via the GPIO Matrix.

The pins for the LP-SPI interface can be chosen from any pins via the LP GPIO Matrix.

## 4.2.2.3 I2C Controller (I2C)

ESP32-P4 has three I2C controllers: two in the main system and one in the low-power system. The two I2C controllers in the main system can act as a master or a slave (referred to as I2C below), while the one in the low-power system can only act as a master (referred to as LP_I2C below), which can still work when the main system sleeps.

**Feature List**

The I2C controller of ESP32-P4 has the following features:

- Master mode and slave mode
- Communication between multiple masters and slaves
- Standard mode (100 Kbit/s)
- Fast mode (400 Kbit/s)
- 7-bit addressing and 10-bit addressing
- Continuous data transfer achieved by pulling SCL low in slave mode
- Programmable digital noise filtering
- Dual address mode, which uses slave address and slave memory or register address

**Pin Assignment**

For I2C, the pins used can be chosen from any GPIOs via the GPIO Matrix.

For LP I2C, the pins used can be chosen from any GPIOs via the LP GPIO Matrix.

## 4.2.2.4 Analog I2C Controller

This module is a dedicated I2C host that communicates with some analog modules to configure parameters of these modules. Each configurable module has an I2C slave with its own address.

**Feature List**

- Master mode only
- 7-bit addressing
- Adjustable transmission rate
- Communication in the sleep modes supported by the Low-Power CPU
- Dual master operation mode

**Pin Assignment**

The analog I2C interface connects internal analog components without requiring allocating IO pins.

## 4.2.2.5 I3C Controller

ESP32-P4 includes one I3C master interface.

**Feature List**

The I3C master interface supports the following features:

- Compliant with I3C protocol
- Compatible with I2C mode (FM, FM+)
- SDR mode
- Dynamic address allocation
- In-Band interrupts
- DMA transfer

**Pin Assignment**

For I3C master interface, the pins for clock and data signals are multiplexed with GPIO32–GPIO33 via the GPIO matrix. Other signals can be routed to any GPIOs via the GPIO matrix.

## 4.2.2.6 I2S Controller (I2S)

ESP32-P4 has three built-in I2S interfaces, which provide flexible communication interfaces for streaming digital data in multimedia applications, especially digital audio applications.

**Feature List**

- Master mode and slave mode
- Full-duplex and half-duplex communications
- Separate TX and RX units that can work independently or simultaneously
- A variety of audio standards supported:
  - TDM Philips standard
  - TDM MSB alignment standard
  - TDM PCM standard
  - PDM standard
- Various TX/RX modes supported:
  - TDM TX mode, up to 16 channels supported
  - TDM RX mode, up to 16 channels supported
  - PDM TX mode
    - Raw PDM data transmission
    - PCM-to-PDM data format conversion (for I2S0 only), up to two channels supported
  - PDM RX mode
    - Raw PDM data reception
    - PDM-to-PCM data format conversion (for I2S0 only), up to eight channels supported
- Configurable APLL clock with frequencies up to 240 MHz
- Configurable high-precision sample clock with a variety of sampling frequencies supported
- 8/16/24/32-bit data width
- Synchronous counter in TX mode
- ETM feature
- Direct Memory Access (GDMA-AHB only)
- Standard I2S interface interrupts

**Pin Assignment**

The pins for the I2S interfaces can be chosen from any GPIOs via the GPIO Matrix.

## 4.2.2.7 LP I2S Controller

ESP32-P4 has a built-in LP I2S interface, which provides a data reception communication interface for Voice Activity Detection (VAD) and some digital audio applications in low power mode.

**Feature List**

- RX master mode and slave mode
- A variety of audio standards supported:
  - TDM Philips standard
  - TDM MSB alignment standard
  - TDM PCM standard
  - PDM standard
- Various RX modes supported:
  - TDM RX mode, up to two channels supported
  - PDM RX mode
    - Raw PDM data reception
    - PDM-to-PCM data format conversion, up to two channels supported
- Configurable sample clock with a variety of sampling frequencies supported
- 16-bit data communication
- Standard LP I2S interface interrupts

**Pin Assignment**

The pins for the LP I2S controller can be chosen from any LP GPIOs via the LP GPIO Matrix.

## 4.2.2.8 Pulse Count Controller (PCNT)

The pulse count controller (PCNT) is designed to count input pulses.

**Feature List**

- Four independent pulse counters (units) that count from 1 to 65535
- Each unit consists of two independent channels sharing one pulse counter
- All channels have input pulse signals with their corresponding control signals
- Independently filter glitches of input pulse signals and control signals on each unit
- Each channel has the following parameters:
  1. Selection between counting on rising or falling edges of the input pulse signal
  2. Configuration to Increment, Decrement, or Disable counter mode for control signal's high and low states
- Maximum frequency of pulses: f_APB_CLK / 2

**Pin Assignment**

The pins for the pulse count controller can be chosen from any GPIOs via the GPIO Matrix.

## 4.2.2.9 USB 2.0 High-Speed OTG

The ESP32-P4 chip features a USB 2.0 High-Speed On-The-Go peripheral (OTG_HS) with an integrated transceiver. This OTG_HS complies with the USB 2.0 specification, OTG Revision 1.3, and OTG Revision 2.0 specifications. The interface supports USB 2.0 High-Speed mode (480 Mbit/s), Full-Speed mode (12 Mbit/s), and Low-Speed mode (1.5 Mbit/s).

- When OTG_HS operates in High-Speed or Full-Speed modes, it can be configured as either a Host or a Device.
- When OTG_HS operates in Low-Speed mode, it can only be configured as a Host.

**Feature List**

**General Features**

- USB 2.0 specification, OTG Revision 1.3 and OTG Revision 2.0 specifications
- High-Speed, Full-Speed, and Low-Speed data rates
- As a host and a device in High-Speed mode and Full-Speed mode
- Dynamic FIFO (DFIFO) sizing, each device EP/host channel can dynamically allocate a maximum of 4 KB FIFO.
- Multiple modes of memory access
  - Scatter/Gather DMA mode
  - Buffer DMA mode
  - Slave mode
- Integrated UTMI High-Speed transceiver

**Device Mode Features**

- Endpoint 0 always present, bi-directional, consisting of EP0 IN and EP0 OUT
- 15 additional endpoints 1–15, configurable as IN or OUT
- Maximum of eight IN endpoints concurrently active at any time, including EP0 IN
- All OUT endpoints share a single RX FIFO
- Each IN endpoint has a dedicated TX FIFO

**Host Mode Features**

- 16 host channels
- RX FIFO: shared by all periodic and non-periodic transactions
- Two TX FIFO:
  - One shared by all non-periodic transactions
  - One shared by all periodic transactions
- All of the above FIFOs share a 4 KB RAM.
- The size of each FIFO is configurable, with a maximum of 4 KB.

**Pin Assignment**

The pins connected to USB2 OTG PHY DM (USB_D-) and USB2 OTG PHY DP (USB_D+) signals of USB 2.0 High-Speed OTG are dedicated pin49 and pin50. Other signals can be routed to any GPIOs via the GPIO matrix.

## 4.2.2.10 USB 2.0 Full-Speed OTG

The ESP32-P4 features a USB 2.0 Full-Speed On-The-Go peripheral (henceforth referred to as OTG_FS) along with integrated transceivers. This OTG_FS conforms to USB 2.0 specification, OTG Revision 1.3, and OTG Revision 2.0 specifications. OTG_FS can operate as either a USB Host or Device and supports 12 Mbit/s full-speed (FS) and 1.5 Mbit/s low-speed (LS) data rates of the USB 2.0 specification. The Host Negotiation Protocol (HNP) and the Session Request Protocol (SRP) are also supported.

**Feature List**

**General Features**

- USB 2.0 specification, OTG Revision 1.3 and OTG Revision 2.0 specifications
- USB 2.0 full-speed and low-speed data rates
- HNP and SRP as A-device or B-device
- Dynamic FIFO (DFIFO) sizing, maximum to 1 KB
- Multiple modes of memory access
  - Scatter/Gather DMA mode
  - Buffer DMA mode
  - Slave mode
- Two integrated transceivers

**Device Mode Features**

- Endpoint 0 always present, bi-directional, consisting of EP0 IN and EP0 OUT
- Six additional endpoints 1–6, configurable as IN or OUT
- Maximum of five IN endpoints concurrently active at any time, including EP0 IN
- All OUT endpoints share a single RX FIFO
- Each IN endpoint has a dedicated TX FIFO

**Host Mode Features**

- Eight host channels
- RX FIFO: shared by all periodic and non-periodic transactions
- Two TX FIFO:
  - One shared by all non-periodic transactions
  - One shared by all periodic transactions
- All of the above FIFOs share a 1 KB RAM.
- The size of each FIFO is configurable, with a maximum of 1 KB.

**Pin Assignment**

The pins connected to D+ and D- signals for two pairs of USB PHY are multiplexed with GPIO24–GPIO25 and GPIO26–GPIO27. The USB 2.0 Full-Speed OTG interface can use each of them. By default, the pins are multiplexed with GPIO26–GPIO27. In addition, the functionalities of USB_D- and USB_D+ can be exchanged.

Other signals can be routed to any GPIOs via the GPIO matrix.

## 4.2.2.11 USB Serial/JTAG Controller (USB_SERIAL_JTAG)

ESP32-P4 contains a USB Serial/JTAG Controller. This unit can be used to program the SoC's flash, read program output, as well as attach a debugger to the running program.

**Feature List**

- USB 2.0 full speed compliant, capable of up to 12 Mbit/s transfer speed (Note that this controller does not support the faster 480 Mbit/s high-speed transfer mode)
- CDC-ACM virtual serial port and JTAG adapter functionality
- Programming the chip's flash
- CPU debugging with compact JTAG instructions
- A full-speed USB PHY integrated in the chip
- Two integrated full-speed transceivers
- Choosing from two full-speed integrated transceivers GPIO24/GPIO25 and GPIO26/GPIO27
- Supporting USB 2.0 OTG using one of the integrated transceivers while USB Serial/JTAG using the other one

**Pin Assignment**

The pins connected to D+ and D- signals for two pairs of USB PHY are multiplexed with GPIO24–GPIO25 and GPIO26–GPIO27. The USB Serial/JTAG Controller interface can use each of them. By default, the pins are multiplexed with GPIO24–GPIO25.

## 4.2.2.12 Ethernet Media Access Controller (EMAC)

By using the external Ethernet PHY (physical layer), ESP32-P4 can send and receive data via Ethernet MAC (Media Access Controller) according to the IEEE 802.3 standard.

ESP32-P4 Ethernet MAC complies with the following standards:

- IEEE 802.3-2002 for Ethernet MAC
- IEEE 1588-2008 standard for precise networked clock synchronization
- IEEE 802.3 standard Media Independent Interface (MII) and Reduced Media Independent Interface (RMII)
- IEEE 802.3az-2010 for Energy Efficient Ethernet
- IEEE 802.1Q for VLAN frame format

**Feature List**

- Data rates of 10/100 Mbit/s through an external PHY interface
- Communication with an external Fast Ethernet PHY through IEEE 802.3-compliant MII or RMII interface (only one can be used at a time)
- Full-duplex and half-duplex modes
  - Carrier Sense Multiple Access or Collision Detection (CSMA/CD) protocol in half-duplex mode
  - IEEE 802.3x flow control in full-duplex mode
  - Optional forwarding of received pause control frame to the user application in full-duplex mode
  - Back-pressure flow control in half-duplex mode
  - Automatic transmission of zero-quanta pause frame on deassertion of flow control input in full-duplex mode
- Preamble and start-of-frame data (SFD) insertion in Transmit, and deletion in Receive paths
- Automatic CRC and padding (all 0) generation controllable on a per-frame basis
- Options for automatic padding generation for data below the minimum frame length
- Programmable frame length supporting jumbo frames of up to 16 KB
- Programmable inter-frame gap (IFG) from 40 to 96 bit times in steps of 8
- Flexible address filtering modes:
  - Up to eight 48-bit perfect address filters with per-byte masking
  - Up to eight 48-bit source address (SA) comparisons with per-byte masking
  - Option to pass all multicast addressed frames
  - Promiscuous mode to pass all frames without filtering for network monitoring
  - Passes all incoming packets (as per filter) with a status report
- Separate 32-bit status returned for transmission and reception packets
- IEEE 802.1Q VLAN tag detection for reception frames
- Separate transmission, reception, and control interfaces for the application
- Management Data Input/Output (MDIO) interface for PHY device configuration and management
- Checksum offload for received IPv4 and TCP packets encapsulated by the Ethernet frame
- Checking IPv4 header checksum and TCP, UDP, or ICMP checksum encapsulated in IPv4 or IPv6 datagrams
- 64-bit timestamp for each transmitted and received frame (see IEEE 1588-2008)
- Energy Efficient Ethernet support (see IEEE 802.3az-2010)
- CRC replacement, SA insertion/replacement, and VLAN insertion/replacement/deletion in transmit frames
- Two FIFOs: 256-byte TX FIFO and 256-byte RX FIFO
- Receive status vectors inserted into RX FIFO after the EOF (end of frame) transfer, allowing multiple-frame storage without requiring an additional FIFO for status
- Option to forward good runt frames
- Statistics generation with pulse signaling for dropped or corrupted frames due to RX FIFO overflow
- Automatic re-transmission of collision frames
- Frame discarding in cases of late collisions, excessive collisions, excessive deferrals, or underflow conditions
- Software control for TX FIFO flushing

**Pin Assignment**

The Ethernet media access controller includes only one RMII interface. For flexible pin routing, each RMII signal offers three alternative GPIO mappings:

- RMII Group 1: Signals are multiplexed with GPIO28–GPIO36 and the SPI2 interface via IO MUX.
