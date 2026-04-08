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


# 4 Functional Description

![Figure 4-1. Address Mapping Structure](figures/ch05_figure-041.png)

## 4.1.3.1 System and Memory

### Internal Memory

ESP32-P4’s internal memory includes:

- 128 KB of HP ROM: 200 MHz, for HP CPU booting and core functions
- 768 KB of HP L2MEM: 200 MHz, for HP CPU data and instructions
- 16 KB of LP ROM: 40 MHz, for LP CPU booting and core functions
- 32 KB of LP SRAM: 40 MHz, for LP CPU data and instructions
- 4 Kbit of eFuse: 1792 bits are reserved for user data, such as encryption key and device ID
- 8 KB of SPM (Scratchpad Memory): 360 MHz, for HP CPU fast access

### In-package PSRAM

- The size of PSRAM is detailed in Section 1 *ESP32-P4 Series Comparison*
- Maximum clock frequency: 200 MHz
- Supports up to 64 MB storage
- Supports hardware XTS-AES encryption/decryption, protecting programs and data stored in PSRAM
- Through a cache, it can map 64 KB blocks into a 64 MB instruction or data space, supporting 8-bit, 16-bit, 32-bit, and 128-bit read and write operations

### External Memory

ESP32-P4 allows connection to memories outside the chip’s package via the SPI, Dual SPI, Quad SPI, and QPI interfaces. The maximum clock frequency is 120 MHz.

The external flash can be mapped into the CPU instruction memory space and read-only data memory space. ESP32-P4 supports up to 64 MB of external flash, and hardware encryption/decryption based on XTS-AES to protect users’ programs and data in flash.

Through high-speed caches, ESP32-P4 can support at a time up to:

- External flash mapped into 64 MB instruction space as individual blocks of 64 KB
- External flash can also be mapped into 64 MB data space as individual blocks of 64 KB, supporting 8-bit, 16-bit, 32-bit, and 128-bit reads.

> **Note:**
> After ESP32-P4 is initialized, firmware can customize the mapping of external flash into the CPU address space.

## 4.1.3.2 eFuse Controller

ESP32-P4 contains a 4096-bit eFuse memory to store parameters and user data. The parameters include control parameters for some hardware modules, system data parameters and keys used for the encryption/decryption module. Once an eFuse bit is programmed to 1, it can never be reverted to 0.

### Feature List

- 4096-bit one-time programmable memory (including up to 1792 bits reserved for custom use)
- Configurable write protection
- Configurable read protection
- Various hardware encoding schemes against data corruption

## 4.1.3.3 Cache

ESP32-P4 employs the two-level cache structure.

### Feature List

- 16 KB of L1 instruction cache, 64 B of block size, four-way set associative
- 64 KB of L1 data cache, 64 B of block size, two-way set associative, supporting two writing strategies write-through and write-back
- 128 KB/256 KB/512 KB of L2 cache, 64 B/128 B of block size, eight-way set associative
- Cacheable and non-cacheable access
- Pre-load function
- Lock function
- Critical word first and early restart

## 4.1.4 System Components

This subsection describes the essential components that contribute to the overall functionality and control of the system.

### 4.1.4.1 GPIO Matrix and IO MUX

The ESP32-P4 chip features 55 GPIO pins, including 16 low-power (LP) GPIO pins and 39 high-performance (HP) GPIO pins. Each pin can be used as a general-purpose I/O, or be connected to an internal peripheral signal.

- Through HP GPIO matrix and HP IO MUX, HP peripheral input signals can be from any GPIO pins, and HP peripheral output signals can be routed to any GPIO pins.
- Through LP GPIO matrix and LP IO MUX, LP peripheral input signals can be from any LP GPIO pins, and LP peripheral output signals can be routed to any LP GPIO pins.

Together these modules provide highly configurable I/O. The 55 GPIO pins are numbered from GPIO0 to GPIO54.

- LP GPIO pins (GPIO0–GPIO15) can be used by either HP or LP peripherals.
- HP GPIO pins (GPIO16–GPIO54) can be used only by HP peripherals.

#### Feature List

HP GPIO matrix has the following features:

- A full-switching matrix between HP peripheral input/output signals and the GPIO pins
- 222 HP peripheral input signals sourced from the input of any GPIO pins
- 232 HP peripheral output signals routed to the output of any GPIO pins
- Signal synchronization for HP peripheral inputs based on HP IO MUX operating clock
- GPIO Filter hardware for input signal filtering
- Glitch Filter hardware for second-time filtering on input signal
- Sigma delta modulated (SDM) output
- GPIO simple input and output
- HP GPIO Wakeup

HP IO MUX has the following features:

- Control of 55 GPIOs (GPIO0–GPIO54) for HP peripherals.
- A configuration register provided for each GPIO pin, to control the pin’s input/output, pull-up/pull-down, drive strength, and function selection.
- Better high-frequency digital performance achieved by routing some digital signals (SPI, EMAC) directly from HP IO MUX to peripherals.

LP GPIO matrix has the following features:

- A full-switching matrix between the LP peripheral input/output signals and the LP GPIO pins
- 14 LP peripheral input signals sourced from the input of any LP GPIO pins
- 14 LP peripheral output signals routed to the output of any LP GPIO pins
- GPIO Filter hardware for input signal filtering
- GPIO simple input and output
- LP GPIO Wakeup

LP IO MUX has the following feature:

- Control of 16 LP GPIO pins (GPIO0–GPIO15) for LP peripherals.
- A configuration register provided for each LP GPIO pin, to control the pin’s input/output, pull-up/pull-down, drive strength, function selection, and IO MUX selection.

### 4.1.4.2 Reset

ESP32-P4 provides four types of reset that occur at different levels, namely CPU Reset, Core Reset, System Reset, and Chip Reset. All reset types mentioned above (except Chip Reset) preserve the data stored in internal memory.

- Four reset types:
  - CPU Reset: resets CPU core. HP CPU0, HP CPU1, and LP CPU can be reset independently:
    - HP CPU0 will be automatically released from reset after chip power-up.
    - HP CPU1 is at reset by default after chip power-up, and needs to be manually released from reset.
    - LP CPU is at reset after chip power-up, and needs to be manually released from reset by configuring the power management unit (PMU).
  - Core Reset: resets the whole digital system except for LP AON. HP core and LP core can be reset independently: HP Core Reset resets HP CPU0, HP CPU1, HP peripherals, HP GPIO, etc., and LP Core Reset resets LP CPU and LP peripherals.
  - System Reset: resets the whole digital system, including the LP system.
  - Chip Reset: resets the whole chip.
- Software reset and hardware reset:
  - Software Reset: triggered via software by configuring the corresponding registers of CPU.
  - Hardware Reset: triggered directly by the hardware.

### 4.1.4.3 Clock

ESP32-P4 clocks are mainly sourced from oscillator (OSC, including Resistor-Capacitor circuit), crystal (XTAL), and PLL circuit, and then processed by the dividers or selectors, which allows most functional modules to select their working clock according to their power consumption and performance requirements.

ESP32-P4 clocks can be classified into two types depending on their frequencies:

- High speed clocks for devices working at a higher frequency, such as HP CPU0/1 and digital peripherals
  - `CPLL_CLK`: internal 360 MHz PLL clock. Its reference clock is `XTAL_CLK`
  - `MPLL_CLK`: internal 500 MHz PLL clock. Its reference clock is `XTAL_CLK`
  - `SPLL_CLK`: internal 480 MHz PLL clock. Its reference clock is `XTAL_CLK`
- Slow speed clocks for LP system and some peripherals working in low-power mode
  - `XTAL32K_CLK`: external 32 kHz crystal clock
  - `RC_SLOW_CLK`: internal slow RC oscillator with adjustable frequency (150 kHz by default)
  - `OSC_SLOW_CLK`: external slow clock input through `XTAL_32K_N`, with a frequency of 32 kHz by default. After configuring this GPIO, also configure the Hold function
  - `XTAL_CLK`: 40 MHz external crystal clock
  - `RC_FAST_CLK`: internal fast RC oscillator with adjustable frequency (20 MHz by default)
  - `PLL_LP_CLK`: internal PLL clock with a frequency of 8 MHz by default. Its reference clock can be `XTAL32K_CLK`

### 4.1.4.4 Interrupt Matrix

The Interrupt Matrix in the ESP32-P4 chip routes interrupt requests generated by various peripherals to CPU interrupts.

#### Feature List

- 126 peripheral interrupt sources accepted as input
- 32 HP CPU0 peripheral interrupts and 32 HP CPU1 peripheral interrupts generated to HP CPU as output
- Current interrupt status query of peripheral interrupt sources
- Multiple interrupt sources mapping to a single HP CPU0 or HP CPU1 interrupt (i.e., shared interrupts)

### 4.1.4.5 Event Task Matrix

The Event Task Matrix (ETM) peripheral contains 50 configurable channels. Each channel can map an event of any specified peripheral to a task of any specified peripheral. In this way, peripherals can be triggered to execute specified tasks without CPU intervention.

#### Feature List

- Receive various events from multiple peripherals
- Generate various tasks for multiple peripherals
- 50 independently configurable ETM channels
- An ETM channel can be set up to receive any event, and map it to any task
- Each ETM channel can be enabled independently. If not enabled, the channel will not respond to the configured event and generate the task mapped to that event
- Support for checking event and task status
- Peripherals supporting ETM include GPIO, LED PWM, general-purpose timers, RTC Timer, system timer, MCPWM, temperature sensor, ADC, I2S, LP CPU, GDMA-AHB, GDMA-AXI, 2D DMA, and PMU

### 4.1.4.6 Low-Power Management

With advanced power-management technologies, ESP32-P4 can switch between different power modes.

- Active mode: CPU and all peripherals are powered on.
- Light-sleep mode: CPU is paused. Any wake-up events (host, RTC timer, or external interrupts) will wake up the chip. CPU (excluding L2MEM) and most peripherals (See ESP32-P4 Block Diagram) can also be powered down based on requirements to further reduce power consumption.
- Deep-sleep mode: CPU (including L2MEM) and most peripherals (See ESP32-P4 Block Diagram) are powered down. Only the LP memory is powered on, and some peripherals of the LP system can be powered down based on requirements.

### 4.1.4.7 System Timer

ESP32-P4 provides a 52-bit system timer, which can be used to generate tick interrupts for the operating system, or be used as a general timer to generate periodic interrupts or one-time interrupts.

#### Feature List

- Two 52-bit counters and three 52-bit comparators
- Software accessing registers clocked by APB_CLK
- CNT_CLK used for counting, with an average frequency of 16 MHz in two counting cycles
- 40 MHz XTAL_CLK as the clock source of CNT_CLK
- 52-bit alarm values (t) and 26-bit alarm periods (δt)
- Two modes to generate alarms:
  - Target mode: only a one-time alarm is generated based on the alarm value (t)
  - Period mode: periodic alarms are generated based on the alarm period (δt)
- Three comparators generating three independent interrupts based on configured alarm value (t) or alarm period (δt)
- Software configuring the reference count value. For example, the system timer is able to load back the sleep time recorded by RTC timer via software after Light-sleep
- Able to stall or continue running when CPU stalls or enters the on-chip-debugging mode
- Alarm for Event Task Matrix (ETM) event

### 4.1.4.8 Timer Group (TIMG)

ESP32-P4 chip contains two timer groups. Each timer group consists of two general-purpose timers and one Main System Watchdog Timer (MWDT). The general-purpose timer is based on a 16-bit prescaler and a 54-bit auto-reload-capable up-down counter.

#### Feature List

- A 54-bit time-base counter programmable to incrementing or decrementing
- Three clock sources: PLL_F80M_CLK or XTAL_CLK or RC_FAST_CLK
- A 16-bit clock prescaler, from 2 to 65536
- Able to read real-time value of the time-base counter
- Able to halt and resume the time-base counter
- Programmable alarm generation
- Timer value reload —Auto-reload at alarm or software-controlled instant reload
- Calculate clock frequency — Calculate the measured frequency of the clock based on the crystal clock
- Level interrupt generation
- Support several ETM tasks and events

### 4.1.4.9 Watchdog Timers (WDT)

ESP32-P4 contains three digital watchdog timers: one in each of the two timer groups (called Main System Watchdog Timers, or MWDT) and one in the LP system (called the RTC Watchdog Timer, or RWDT).

In SPI Boot mode, RWDT and the MWDT in timer group 0 are enabled automatically in order to detect errors that may occur during the flash boot process and facilitate recovery.

ESP32-P4 also has one analog watchdog timer: Super watchdog (SWD). It is an ultra-low-power circuit in analog domain that helps to prevent the system from operating in a sub-optimal state and resets the system if required.

#### Feature List

- Four stages, each with a separately programmable timeout value and timeout action
- Timeout actions:
  - MWDT: interrupt, HP CPU reset, HP core reset
  - RWDT: interrupt, HP CPU reset, HP core reset, system reset
- Flash boot protection under SPI Boot mode at stage 0:
  - MWDTO: HP core reset upon timeout
  - RWDT: system reset upon timeout
- Write protection that makes WDT register read only unless unlocked
- 32-bit timeout counter
- Clock source:
  - MWDT: PLL_F80M_CLK, RC_FAST_CLK or XTAL_CLK
  - RWDT: LP_DYN_SLOW_CLK

### 4.1.4.10 RTC Timer

RTC Timer is an important module for implementing low power management of ESP32-P4. Based on a 48-bit readable counter, RTC Timer is mainly used as a system timer in low power mode when the timer peripheral in the HP system is unavailable. It also allows for configuring timer interrupts and logging the time when specific events happen in the system.

#### Feature List

- 48-bit counter
- Time logging when one of the following events happens:
  - HP system reset
  - CPU enters stall state
  - CPU exits stall state
  - Crystal powers up
  - Crystal powers down
- Time logging through register configuration
- Occurrence time cached of the most recent two specific events
- Generation of interrupts at target times, which are configurable. It is also possible to configure two target times simultaneously.
- Uninterrupted operation during any reset or sleep mode, except for power-on reset of LP system.

### 4.1.4.11 Permission Control (PMS)

ESP32-P4 integrates an APM module to manage access permissions.

#### Feature List

- Up to 32 configurable address ranges for each DMA master
- Access permission management for each CPU core to access internal memory, external memory, and peripheral registers
- Support for interrupts
- Support for exception information record

### 4.1.4.12 System Registers

The System Registers in the ESP32-P4 chip are used to configure various auxiliary chip features.

#### Feature List

- Control External memory encryption and decryption
- Control HP core/LP core debugging
- Control Bus timeout protection

### 4.1.4.13 Debug Assistant

The Debug Assistant provides a set of functions to help locate bugs and issues during software debugging. It offers various monitoring capabilities and logging features to assist in identifying and resolving software errors efficiently.

#### Feature List

- Read/write monitoring: Monitors whether the High-Performance dual-core CPU (HP CPU0 and HP CPU1) bus reads from or writes to a specified memory address space. A detected read or write in the monitored address space will trigger an interrupt.
- Stack pointer (SP) monitoring: Monitors whether the SP exceeds the specified address space. A bounds violation will trigger an interrupt.
- Program counter (PC) logging: Records the PC value. The developer can get the last PC value at the most recent reset of HP CPU0 or HP CPU1.
- Bus access logging: Records the information about bus access. When the HP CPU0, HP CPU1, or the Direct Memory Access controller (DMA) writes a specified value, the Debug Assistant module will record the data type, address of this write operation, and additionally the PC value when the write is performed by HP CPU0 or HP CPU1, and push such information to the HP L2MEM.

### 4.1.4.14 LP Mailbox

ESP32-P4 integrates an LP Mailbox module which provides an efficient inter-core communication mechanism between the LP CPU and HP CPU0/1. The LP Mailbox module comprises of sixteen 32-bit message registers that the LP CPU and HP CPU0/1 can use to store and exchange message. Inter-core communication between LP CPU and HP CPU0/1 is achieved through an interrupt mechanism implemented within the LP Mailbox module.

#### Feature List

- Sixteen 32-bit message registers for inter-core communication
- LP CPU external interrupt signal
- HP CPU0/1 external interrupt signal

### 4.1.4.15 Brown-out Detector

With the Brown-out detector, ESP32-P4 monitors the voltage levels of pins VDD_ANA and VDD_BAT. If the voltage on these pins drops below the predefined threshold (defaulting to 2.7 V), the detector triggers signals to shut down certain power-consuming blocks (e.g., flash), ensuring that the digital module has sufficient time to save and transfer important data.

#### Feature List

- Monitors the voltage level of pins VDD_ANA and VDD_BAT
- Two configurable monitoring modes
  - Mode 0: The brown-out detector triggers interrupts when the brown-out counter reaches the predefined threshold and selects the reset mode according to the configuration.
  - Mode 1: The brown-out detector triggers a system reset when the voltage falls below the threshold.
- Configurable voltage-monitoring thresholds and noise tolerance
- Configurable handling modes for under-voltage events

## 4.1.5 Cryptography/Security Component

This subsection describes the security features incorporated into the chip, which safeguard data and operations.

### 4.1.5.1 AES Accelerator (AES)

ESP32-P4 integrates an Advanced Encryption Standard (AES) accelerator, which is a hardware device that speeds up computation using AES algorithm significantly, compared to AES algorithms implemented solely in software. The AES accelerator integrated in ESP32-P4 has two working modes, which are Typical AES and DMA-AES.

#### Feature List

- Typical AES working mode
  - AES-128/AES-256 encryption and decryption
- DMA-AES working mode
  - AES-128/AES-256 encryption and decryption
  - Block cipher mode
    - ECB (Electronic Codebook)
    - CBC (Cipher Block Chaining)
    - OFB (Output Feedback)
    - CTR (Counter)
    - CFB8 (8-bit Cipher Feedback)
    - CFB128 (128-bit Cipher Feedback)


# 4 Functional Description

- GCM (Galois/Counter Mode)
- Interrupt on completion of computation

## 4.1.5.2 ECC Accelerator (ECC)

Elliptic Curve Cryptography (ECC) is an approach to public-key cryptography based on the algebraic structure of elliptic curves. ECC allows smaller keys compared to RSA cryptography while providing equivalent security.

ESP32-P4’s ECC accelerator can complete various calculations based on different elliptic curves, thus accelerating the ECC algorithm and ECC-derived algorithms (such as ECDSA).

### Feature List

- 2 different elliptic curves, namely P-192 and P-256 defined in FIPS 186-3
- 11 working modes
- Interrupt upon completion of calculation

## 4.1.5.3 HMAC Accelerator (HMAC)

The Hash-based Message Authentication Code (HMAC) module computes Message Authentication Codes (MACs) using hash algorithm SHA-256 and keys as described in RFC 2104. The 256-bit HMAC key is stored in an eFuse key block and can be set as read-protected, i.e., the key is not accessible from outside the HMAC accelerator.

### Feature List

- Standard HMAC-SHA-256 algorithm
- HMAC-SHA-256 calculation based on key in eFuse,
  - whose result cannot be accessed by software in downstream mode for high security
  - whose result can be accessed by software in upstream mode
- Generates required keys for the Digital Signature Algorithm (DSA) peripheral in downstream mode
- Re-enables soft-disabled JTAG in downstream mode

## 4.1.5.4 RSA Accelerator (RSA)

The RSA accelerator provides hardware support for high-precision computation used in various RSA asymmetric cipher algorithms, significantly reducing the operation time and software complexity. Compared with RSA algorithms implemented solely in software, this hardware accelerator speeds up RSA algorithms significantly. The RSA accelerator also supports operands of different lengths, which provides more flexibility during the computation.

### Feature List

- Large-number modular exponentiation with two optional acceleration options
- Large-number modular multiplication, up to 4096 bits
- Large-number multiplication, with operands up to 2048 bits
- Operands of different lengths
- Interrupt on completion of computation

## 4.1.5.5 SHA Accelerator (SHA)

ESP32-P4 integrates an SHA accelerator, which is a hardware device that speeds up the SHA algorithm significantly, compared with an SHA algorithm implemented solely in software. The SHA accelerator integrated in ESP32-P4 has two working modes, Typical SHA and DMA-SHA.

### Feature List

- The following hash algorithms introduced in FIPS PUB 180-4 Spec:
  - SHA-1
  - SHA-224
  - SHA-256
  - SHA-384
  - SHA-512
  - SHA-512/224
  - SHA-512/256
  - SHA-512/t
- Two working modes
  - Typical SHA
  - DMA-SHA
- Interleaved function when working in Typical SHA working mode
- Interrupt function when working in DMA-SHA working mode

## 4.1.5.6 Digital Signature Algorithm (DSA)

The Digital Signature Algorithm (DSA) is used to verify the authenticity and integrity of a message using a cryptographic algorithm. This can be used to validate a device’s identity to a server or to check the integrity of a message.

ESP32-P4 includes a Digital Signature Algorithm (DSA) module providing hardware acceleration of messages’ signatures based on RSA. HMAC is used as the key derivation function (KDF) to output the DSA_KEY key using a key stored in eFuse as the input key. Subsequently, the DSA module uses DSA_KEY to decrypt the pre-encrypted parameters and calculate the signature. The whole process happens in hardware so that all the keys involved during the calculating process cannot be seen by users, guaranteeing the security of the operation.

### Feature List

- RSA digital signatures with key length up to 4096 bits
- Encrypted private key data, only decryptable by the DSA module
- SHA-256 digest to protect private key data against tampering by an attacker

## 4.1.5.7 Elliptic Curve Digital Signature Algorithm (ECDSA)

In cryptography, the Elliptic Curve Digital Signature Algorithm (ECDSA) offers a variant of the Digital Signature Algorithm (DSA) which uses elliptic-curve cryptography.

ESP32-P4’s ECDSA accelerator provides a secure and efficient environment for computing ECDSA signatures. It enables high-speed cryptographic operations while preserving the confidentiality of the signing process, effectively minimizing the risk of information leakage. This makes it particularly valuable for applications that demand both strong security and fast performance. With the ECDSA accelerator, users can trust that their data is well protected—without compromising on speed.

### Feature List

- Digital signature verification
- Two different elliptic curves, namely P-192 and P-256, defined in FIPS 186-3 Spec
- Two hash algorithms for message hash in the ECDSA operation, namely SHA-224 and SHA-256, defined in FIPS PUB 180-4 Spec
- Dynamic access permission in different operation statuses to ensure information security

## 4.1.5.8 External Memory Encryption and Decryption (XTS_AES)

The ESP32-P4 integrates an External Memory Encryption and Decryption module that complies with the XTS-AES standard algorithm specified in IEEE Std 1619-2007, providing security for users’ application code and data stored in the external memory (flash and RAM). Users can store proprietary firmware and sensitive data (e.g., credentials for gaining access to a private network) in the external flash, or store general data in the external RAM.

### Feature List

- General XTS-AES algorithm, compliant with IEEE Std 1619-2007
- Software-based manual encryption
- High-speed auto encryption and decryption without software’s participation
- Encryption and decryption functions jointly enabled/disabled by register configuration, eFuse parameters, and boot mode
- Configurable Anti-DPA

## 4.1.5.9 Random Number Generator (RNG)

The ESP32-P4 contains a true random number generator (TRNG), which generates 32-bit random numbers that can be used for cryptographical operations, among other things.

The TRNG in ESP32-P4 generates true random numbers, which means random numbers generated from a physical process, rather than by means of an algorithm. No number generated within the specified range is more or less likely to appear than any other number.

## 4.2 Peripherals

This section describes the chip’s peripheral capabilities, covering connectivity interfaces and on-chip sensors that extend its functionality.

### 4.2.1 Image Processing

This subsection describes the peripherals for image and voice processing.

#### 4.2.1.1 JPEG Codec

ESP32-P4’s JPEG codec is an image codec, which is based on the JPEG baseline standard, for compressing (encoding) and decompressing (decoding) images to reduce the bandwidth required to transmit images or the space required to store images, making it possible to process large-resolution images.

##### Feature List

When used as an encoder, the JPEG codec has the following features:

- Integrated discrete cosine transform algorithm
- Integrated canonical Huffman coding
- RGB888, RGB565, YUV422 and GRAY as original input image formats
- conversion of RGB888 and RGB565 into YUV444, YUV422 or YUV420 (the only formats supported by impression) for image compression
- Four configurable quantization coefficient tables with 8-bit or 16-bit precision
- Performance:
  - Still image compression: up to 4K resolution
  - Dynamic image compression: up to 1080P@40fps,720P@70fps (excluding header encoding time)
- Automatically added stuffed zero byte
- Automatically added EOI marker

When used as a decoder, the JPEG codec has the following features:

- Integrated inverse discrete cosine transform algorithm
- Integrated Huffman decoding
- Supported image formats for compressed bitstream decoding: YUV444, YUV422, YUV420, and GRAY.
- Four configurable quantization coefficient tables with 8-bit or 16-bit precision
- Two DC and two AC Huffman tables
- Supports image decoding of any resolution. However, the resolution of the output decoded image differs from the format of the input image:
  - YUV444, GRAY: both the horizontal and vertical resolutions of the output decoded image are multiples of 8, i.e., 150 × 150 images with an output resolution of 152 × 152
  - YUV422: the horizontal resolution of the output decoded image is the multiples of 16 and the vertical resolution is multiples of 8, i.e., 150 × 150 images with an output resolution of 160 × 152
  - YUV420: both the horizontal and vertical resolutions of the output decoded image are multiples of 16, i.e., 150 × 150 images with an output resolution of 160 × 160
- Performance:
  - Still image decoding: up to 4K resolution
  - Dynamic image decoding: up to 1080P@40fps, 720P@70fps (excluding header parsing time)

##### Pin Assignment

The JPEG Codec does not interact directly with IOs, so it has no pins assigned.

#### 4.2.1.2 Image Signal Processor (ISP)

ESP32-P4 includes an image signal processor (ISP), which is a pipeline composed of various image processing algorithms.

##### Feature List

- Maximum resolution: 1920 x 1080
- Three input channels: MIPI-CSI, DVP, and AXI-DMAC
- Input formats: RAW8, RAW10, and RAW12
- Output formats: RAW8, RGB888, RGB565, YUV422, and YUV420
- Pipeline features:
  - Bayer filter (BF)
  - Demosaic
  - Color correction matrix (CCM)
  - Gamma correction
  - RGB2YUV
  - Sharpen
  - Contrast/hue/saturation/luminance adjustment (COLOR)
  - YUV_limit
  - YUV2RGB
  - Automatic exposure statistics (AE)
  - Automatic focus statistics (AF)
  - Automatic white balance statistics (AWB)
  - Histogram statistics (HIST)

##### Pin Assignment

For the CAM interface of the image signal processor, the pins used can be chosen from any GPIOs via the GPIO Matrix.

#### 4.2.1.3 Pixel-Processing Accelerator (PPA)

ESP32-P4 includes a pixel-processing accelerator (PPA) with scaling-rotation-mirror (SRM) and image blending (BLEND) functionalities.

##### Feature List

- Image rotation, scaling, and mirroring by SRM:
  - Input formats: ARGB8888, RGB888, RGB565, YUV420
  - Output formats: ARGB8888, RGB888, RGB565, YUV420
  - Counterclockwise rotation angles: 0°, 90°, 180°, 270°
  - Horizontal and vertical scaling with scaling factors of 4-bit integer part and 8-bit fractional part
  - Horizontal and vertical mirroring
- Blending two layers of the same size and filling images with specific pixels by BLEND:
  - Input formats: ARGB8888, RGB888, RGB565, L4, L8, A4, A8
  - Output formats: ARGB8888, RGB888, RGB565
  - Layer blending based on the Alpha channel. If layers lack an Alpha channel, it can be provided through register configuration.
  - Special color filtering by setting color-key ranges of foreground and background layers

##### Pin Assignment

The pixel-processing accelerator does not directly interact with IOs, so it has no pins assigned.

#### 4.2.1.4 LCD and Camera Controller (LCD_CAM)

The LCD and Camera controller (LCD_CAM) on the ESP32-P4, consisting of an independent LCD control module and a camera control module, is a versatile component designed to facilitate interfacing with both LCDs and cameras.

##### Feature List

- Operation modes:
  - LCD master TX mode
  - Camera slave RX mode
  - Camera master RX mode
- Simultaneous connection to an external LCD and a camera
- External LCD interface:
  - 8/16/24-bit parallel output modes
  - RGB, MOTO6800, and I8080 LCD formats
  - LCD data retrieved from internal memory or external memory via GDMA
- External camera (DVP image sensor) interface:
  - 8/16-bit parallel input modes
  - Camera data stored in internal or external memory via GDMA
- Interrupt support

##### Pin Assignment

For CAM and LCD interfaces of the Camera-LCD controller, the pins used can be chosen from any GPIOs via the GPIO Matrix.

#### 4.2.1.5 H264 Encoder

ESP32-P4 contains a baseline H264 encoder, which is used for real-time video sequence compression, significantly reducing the total amount of data while minimizing video quality loss.

##### Feature List

- YUV420 progressive video with the maximum encoding performance of 1080p@30fps
- I-frame and P-frame
- GOP mode and dual-stream mode (in dual-stream mode, the total bandwidth of the two video image sequences to be encoded should not exceed 1080p@30fps)
- Intra luma macroblock of 4 x 4 and 16 x 16 partitioning
- All nine prediction modes for 4 x 4 partitioning and all four prediction modes for 16 x 16 partitioning of intra luma macroblock
- All four prediction modes for intra chroma macroblock
- All partition modes of inter prediction macroblock: 4 x 4, 4 x 8, 8 x 4, 8 x 8, 8 x 16, 16 x 8, and 16 x 16
- Motion estimation with the precision of 1/2 and 1/4 pixel
- Search range of inter prediction horizontal motion being [-29.75, +16.75], vertical search range being [-13.75, +13.75]
- Enabling and disabling the deblocking filter
- Context adaptive variable length coding (CAVLC)
- P-skip macroblock
- P slice supporting I macroblock
- Decimate operation of luma and chroma component quantization results
- Fixed QP and rate control at the macroblock level
- MV merge for outputting the MV of each macroblock to memory
- Region of interest (ROI). It can configure up to eight rectangular ROI areas at any position. These ROI areas have fixed priorities and can overlap with each other. Each ROI area can be assigned a fixed QP or QP offset, and a non-ROI area can be specified with a QP offset.

##### Pin Assignment

The H264 encoder does not directly interact with IOs, so it has no pins assigned.

#### 4.2.1.6 MIPI CSI

ESP32-P4 includes one MIPI CSI interface for connecting cameras of the MIPI interface.

##### Feature List

- Compliant with MIPI CSI-2
- Compliant with DPHY v1.1
- 2-lane x 1.5 Gbps
- Input formats: RGB888, RGB666, RGB565, YUV422, YUV420, RAW8, RAW10, and RAW12

##### Pin Assignment

The MIPI CSI interface uses the dedicated digital pins 42–48.

#### 4.2.1.7 MIPI DSI

ESP32-P4 features a MIPI DSI interface for connecting displays of the MIPI interface.

##### Feature List

- Compliant with MIPI DSI
- Compliant with DPHY v1.1
- 2-lane x 1.5 Gbps
- Input formats: RGB888, RGB666, RGB565, and YUV422
- Output formats: RGB888, RGB666, and RGB565
- Using the video mode to output video stream
- Outputting image patterns

##### Pin Assignment

The MIPI DSI interface uses the dedicated digital pins 34–40.

### 4.2.2 Connectivity Interface

This subsection describes the connectivity interfaces on the chip that enable communication and interaction with external devices and networks.

#### 4.2.2.1 UART Controller (UART)

ESP32-P4 has six UART controllers, including five UARTs in the HP system and one low-power (LP) UART.

##### Feature List

| UART Feature | LP UART Feature |
| --- | --- |
| Programmable baud rate up to 5 MBaud | Programmable baud rate up to 5 MBaud |
| 260 x 8-bit RAM, shared by TX FIFOs and RX FIFOs of the UART controllers | 20 x 8-bit RAM, shared by the TX FIFO and RX FIFO of LP UART |
| Full-duplex asynchronous communication | Full-duplex asynchronous communication |
| Data bits (5 to 8 bits) | Data bits (5 to 8 bits) |
| Stop bits (1, 1.5, or 2 bits) | Stop bits (1, 1.5, or 2 bits) |
| Parity bit | Parity bit |
| Special character AT_CMD detection | Special character AT_CMD detection |
| RS485 protocol | — |
| IrDA protocol | — |
| High-speed data communication using GDMA | — |
| Receive timeout | Receive timeout |
| UART as wakeup source | UART as wakeup source |
| Software and hardware flow control | Software and hardware flow control |
| Three prescalable clock sources: 1. XTAL_CLK 2. RC_FAST_CLK 3. PLL_F80M_CLK | Three prescalable clock sources: 1. RC_FAST_CLK 2. XTAL_DIV_CLK 3. PLL_F8M_CLK |

##### Pin Assignment

For UART0–UART4 interfaces, the pins used can be chosen from any GPIOs via the GPIO Matrix. By default, the pins connected to transmit and receive signals (UART0_TXD_PAD and UART0_RXD_PAD) of UART0 are multiplexed with GPIO37–GPIO38 and the eight-line interface of SPI2 controller via IO MUX.

For LP UART, the pins used can be chosen from any LP GPIOs via the LP GPIO Matrix. By default, the pins connected to transmit and receive signals (LP_UART_TXD_PAD and LP_UART_RXD_PAD) are multiplexed with LP_GPIO14–LP_GPIO15 via LP IO MUX.

#### 4.2.2.2 SPI Controller (SPI)

The Serial Peripheral Interface (SPI) is a synchronous serial interface commonly used for communicating with external peripherals. The ESP32-P4 chip integrates four SPI controllers:

- MSPI controller, including two sub-controllers
  - FLASH MSPI controller


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
