# 4 Functional Description

## 4.1 System

This section describes the core of the chip’s operation, covering its microprocessor, DMA controllers, memory organization, system components, and security features.

### 4.1.1 Microprocessor and Master

This subsection describes the core processing units within the chip and their capabilities.

#### 4.1.1.1 High-Performance CPU

ESP32-P4 has an HP 32-bit RISC-V dual-core processor with the following features:

Feature List

- Five-stage pipeline that supports clock frequency of up to 360 MHz
- RV32IMAFC ISA (instruction set architecture)
- Zc extensions (Zcb, Zcmp, and Zcmt)
- Custom AI and DSP extension (XespV)
- Custom hardware loop instructions (XespLoop)
- Compliant with RISC-V Core Local Interrupt (CLINT)
- Compliant with RISC-V Core-Local Interrupt Controller (CLIC)
- Branch predictor BHT, BTB, and RAS
- Up to three hardware breakpoints/watchpoints
- Up to 16 PMP/PMA regions
- Machine and User privilege modes
- USB/JTAG for debugging
- Compliant with RISC-V debug specification v0.13
- Offline trace debug that is compliant with RISC-V Trace Specification v2.0

#### 4.1.1.2 RISC-V Trace Encoder (TRACE)

The RISC-V Trace Encoder in the ESP32-P4 chip provides a way to capture detailed trace information from the High-Performance CPU’s execution, enabling deeper analysis and optimization of the system. It connects to the HP CPU’s instruction trace interface and compresses the information into smaller packets, which are then stored in internal SRAM.

Feature List

- Compatible with Efficient Trace for RISC-V v2.0
- Delta address mode and full address mode
- A filter unit
- Notifying an instruction address via debug trigger or filter unit
- Support for the following sideband signals to control trace data flow:
  - Debugging trigger to start or end encoder
  - When the hart is halted, the encoder can report the last packet and then stop
  - When the hart is reset, the encoder can report the last packet and then stop
  - Stalling the hart when FIFO is almost full
- Arbitrary address range of the trace memory size
- Configurable synchronization modes:
  - Synchronization counter counts by packet
  - Synchronization counter counts by cycle
  - Synchronization counter can be disabled
- Trace lost status to indicate packet loss
- Automatic restart after packet loss
- Memory writing in the loop or non-loop mode
- Two interrupts:
  - Triggered when the packet size exceeds the configured memory space
  - Triggered when a packet is lost
- FIFO (128 × 8 bits) to buffer packets
- AHB burst transmission with configurable burst length

#### 4.1.1.3 Processor Instruction Extensions

The ESP32-P4 HP 32-bit RISC-V dual-core processor supports standard RV32IMAFCZc extensions, and it also contains a custom extended instruction set Xhwlp which reduces the number of instructions in the loop body to improve performance, and a custom AI and DSP extension Xai to improve operation efficiency of specific AI and DSP algorithms.

Feature List

- Eight new 128-bit general-purpose registers
- 128-bit vector operations, including complex multiplication, addition, subtraction, multiplication, shifting, and comparison
- Combined data handling instructions and load/store operation instructions
- Aligned and unaligned 128-bit vector data load/store
- Configurable rounding and saturation modes

#### 4.1.1.4 Low-Power CPU

ESP32-P4 integrates an LP 32-bit RISC-V single-core processor. This LP CPU is designed as a simplified, low-power replacement of HP CPU in sleep modes. It can be also used to supplement the functions of the HP CPU in normal working mode. The LP CPU and LP memory remain powered on in Deep-sleep mode. Hence, the developer can store a program for the LP CPU in the LP memory to access LP IO, LP peripherals, and real-time timers in Deep-sleep mode.

Feature List

- Two-stage pipeline that supports a clock frequency of up to 40 MHz
- RV32IMAC ISA (instruction set architecture)
- 18 vector interrupts
- Debug module compliant with RISC-V External Debug Support Version 0.13 with external debugger support over an industry-standard JTAG/USB port
- Hardware trigger compliant with RISC-V External Debug Support Version 0.13 with up to 2 breakpoints/watchpoints
- Core performance metric events
- Wake-up interrupt for HP CPU
- Access to HP memory and LP memory
- Access to the entire peripheral address space

### 4.1.2 System DMA

This subsection describes the system DMA.

#### 4.1.2.1 GDMA Controller (GDMA-AHB, GDMA-AXI)

General Direct Memory Access (GDMA) is a feature that allows peripheral-to-memory, memory-to-peripheral, and memory-to-memory data transfer at high speed. The CPU is not involved in the GDMA transfer and therefore is more efficient with less workload.

ESP32-P4 has two types of general-purpose DMA controllers, namely GDMA-AHB and GDMA-AXI, to directly access the AHB bus or the AXI bus respectively.

Feature List

- Architecture:
  - GDMA-AHB: AHB bus architecture
  - GDMA-AXI: AXI bus architecture, which gives the possibility to complete up to eight transactions out of order and up to eight outstanding transactions
- Programmable length of data to be transferred in bytes
- Access via any address and size
- Alignment:
  - GDMA-AHB:
    - Descriptor address: 1-word aligned
    - Data address and length:
      - Internal memory and non-encrypted external memory address space: no requirements
      - Encrypted external memory address space: 16-byte aligned
  - GDMA-AXI:
    - Descriptor address: 2-word aligned
    - Data address and length:
      - Internal memory and non-encrypted external memory address space: no requirements
      - Encrypted external memory address space: 16-byte aligned
- Linked list of descriptors
- INCR burst transfer when accessing memory
- Three transmit channels and three receive channels for each controller
- Software-configurable selection of peripheral requesting its service
- Configurable channel priority and weight arbitration
- Support for memory transfer
- CRC calculation of data

#### 4.1.2.2 VDMA Controller (VDMA)

DMA (Direct Memory Access) enables direct access to system memory or peripherals without CPU involvement. The VDMA controller on ESP32-P4 is a general-purpose DMA that performs high-speed data transfer from memory to memory, from memory to peripheral, and from peripheral to memory. The VDMA complies with the AXI3 protocol and includes two AXI master interfaces. This design allows users to select between the two interfaces for data transfer dynamically.

Feature List

- Four channels for unidirectional data transfer from source to destination
- Two AXI master interfaces
- Handshake with MIPI DSI (Display Serial Interface) and ISP (Image Signal Processor)
- Memory-to-memory, ISP-to-memory, and MIPI DSI-to-memory transfer types
- Multiple levels of DMA transfer hierarchy
- Configurable transfer type, transfer length, and transfer size for each channel
- Single-block transfer
- Multi-block transfer based on contiguous address, automatic reloading register configuration, shadow registers, and linked lists
- Independent configuration of multi-block transfer type for source transfer and destination transfer
- Channel disabling without data loss
- Channel suspension, resume, and abortion
- Configurable priorities among arbitration channels
- Flow control using VDMA or peripherals
- Programmable mapping between peripherals and channels

#### 4.1.2.3 2D-DMA Controller (2D-DMA)

The 2D-DMA controller is a DMA (Direct Memory Access) dedicated to two-dimensional image processing. In addition to all the features of GDMA-AXI, it includes support for macroblock reordering and color space conversion (CSC) to better meet the data transfer requirements from JPEG and PPA. Notably, the 2D-DMA facilitates memory-to-memory transfers, enabling the movement of macroblocks between different segments of memory address space while concurrently performing color space conversion.

Feature List

- One AXI master interface
- Data transfer with unaligned starting addresses
- Memory-to-memory, peripheral-to-memory (RX), and memory-to-peripheral (TX) data transfer
- Three memory-to-peripheral channels, and two peripheral-to-memory channels
- Support for PPA and JPEG Codec
- Macroblock reordering
- Color space conversion
- Configurable channel priority and weight

### 4.1.3 Memory Organization

This subsection describes the memory arrangement to explain how data is stored, accessed, and managed for efficient operation.

Figure 4-1 Address Mapping Structure illustrates the address mapping structure of ESP32-P4.
