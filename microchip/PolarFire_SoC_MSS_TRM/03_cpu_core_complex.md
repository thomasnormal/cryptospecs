# 3.1. CPU Core Complex

## 3.1.1. E51 RISC-V Monitor Core

The following table describes the features of E51.

| Feature | Description |
| --- | --- |
| ISA | RV64IMAC |
| iCache/ITIM | 16 KB 2-way set-associative/8 KB ITIM |
| DTIM | 8 KB |
| ECC Support | Single-Error Correction and Double-Error Detection (SECDED) on iCache and DTIM. |
| Modes | Machine Mode, User Mode |

Typically, in a system, the E51 is used to execute the following:

- Bootloader to boot the operating system on U54 cores
- Bare-metal user applications
- Monitoring user applications on U54 cores

**Note:** Load-Reserved and Store-Conditional atomic instructions (lr, sc) are not supported on the E51 processor core.

### 3.1.1.1. Instruction Fetch Unit

The instruction fetch unit consists of a 2-way set-associative 16 KB instruction cache that supports 64-byte cache line size with an access latency of one clock cycle. The instruction cache is asynchronous with the data cache. Writes to memory can be synchronized with the instruction fetch stream using the FENCE.I instruction.

### 3.1.1.2. Execution Pipeline

The E51 execution unit is a single-issue, in-order core with 5-stage execution pipeline. The pipeline comprises following five stages:

1. Instruction fetch
2. Instruction decode and register fetch
3. Execution
4. Data memory access
5. Register write back.

The pipeline has a peak execution rate of one instruction per clock cycle.

### 3.1.1.3. ITIM

The 16 KB iCache can be partially reconfigured into 8 KB ITIM. The 8 KB ITIM address range is listed in Table 10-1. ITIM is allocated in quantities of cache blocks, so it is not necessary to use the entire 8 KB as ITIM. Based on the requirement, part of the iCache can be configured as 2-way set associative and part of the cache can be configured as ITIM.

### 3.1.1.4. DTIM

E51 includes an 8 KB DTIM, the address range of the DTIM is listed in Table 10-1. The DTIM has an access latency of two clock cycles for full words and three clock cycles for smaller words. Misaligned accesses are not supported in hardware and result in a trap.

### 3.1.1.5. Hardware Performance Monitor

The CSRs described in the following table implement the hardware performance monitoring scheme.

| CSR | Function |
| --- | --- |
| mcycle | Holds a count of the number of clock cycles executed by a Hart since some arbitrary time in the past. The arbitrary time is the time since power-up. |
| minstret | Holds a count of the number of instructions retired by a Hart since some arbitrary time in the past. The arbitrary time is the time since power-up. |
| mhpmevent3 and mhpmevent4 | Event Selectors: Selects the events as described in Table 3-3, and increments the corresponding mhpmcounter3 and mhpmcounter4 counters.<br>The event selector register mhpmevent3 and mhpmevent4 are partitioned into two fields: event class and event mask as shown in Table 3-3.<br>The lower 8 bits select an event class, and the upper bits form a mask of events in that class. The counter increments if the event corresponding to any set mask bit occurs.<br>For example, if mhpmevent3 is set to 0x4200, mhpmcounter3 increments when either a load instruction or a conditional branch instruction retires.<br>**Note:** In-flight and recently retired instructions may or may not be reflected when reading or writing the performance counters, or writing the event selectors. |
| mhpmcounter3 and mhpmcounter4 | 40-bit event counters |

**Table 3-3. mhpmeventx Register**

| Event Class | mhpmeventx[8:18] Bit Field Description Events |
| --- | --- |
| mhpmeventx[7:0] = 0: Instruction Commit Events | 8: Exception taken<br>9: Integer load instruction retired<br>10: Integer store instruction retired<br>11: Atomic memory operation retired<br>12: System instruction retired<br>13: Integer arithmetic instruction retired<br>14: Conditional branch retired<br>15: JAL instruction retired<br>16: JALR instruction retired<br>17: Integer multiplication instruction retired<br>18: Integer division instruction retired |
| mhpmeventx[7:0] = 1: Micro-architectural Events | 8: Load-use interlock<br>9: Long-latency interlock<br>10: CSR read interlock<br>11: Instruction cache/ITIM busy<br>12: Data cache/DTIM busy<br>13: Branch direction misprediction<br>14: Branch/jump target misprediction<br>15: Pipeline flush from CSR write<br>16: Pipeline flush from other event<br>17: Integer multiplication interlock |
| mhpmeventx[7:0] = 2: Memory System Events | 8: Instruction cache miss<br>9: Memory-mapped I/O access<br>10: Data cache write back<br>11: Instruction TLB miss<br>12: Data TLB miss<br>**Note:** Only L1 cache performance monitoring is supported. |

### 3.1.1.6. ECC

By default, the E51 iCache and DTIM implement SECDED for ECC. The granularity at which this protection is applied (the codeword) is 32-bit (with an ECC overhead of 7 bits per codeword). The ECC feature of L1 cache is handled internally, user control is not supported.

When a single-bit error is detected in the L1 iCache, the error is corrected automatically, and the cache line is flushed and written back to the next level of memory hierarchy. When a single bit error is detected in the L1 DTIM, the error is corrected automatically and written back to L1 DTIM.

#### 3.1.1.6.1. ECC Reporting

ECC events are reported by the BEU block for a given core. The BEU can be configured to generate interrupts either globally through the Platform-Level Interrupt Controller (PLIC) or locally to the specific Hart where the ECC event occurred. When BEU interrupts are enabled, software can be used to monitor and count ECC events.

To detect uncorrectable ECC errors in the L1 cache memories, interrupts must be enabled in the BEU. The BEU must be configured to generate a local interrupt to halt the execution of a Hart when an uncorrectable instruction is detected. For more information about configuring ECC reporting, see Bus Error Unit (BEU).

## 3.1.2. U54 RISC-V Application Cores

The following table describes the features of the U54 application cores.

| Feature | Description |
| --- | --- |
| ISA | RV64GC¹ |
| iCache/ITIM | 32 KB 8-way set-associative/28 KB ITIM |
| dCache | 32 KB 8-way set-associative |
| ECC Support | ECC on iCache, ITIM, and dCache |
| MMU | 40-bit MMU compliant with Sv39 |
| Modes | Machine mode, Supervisor mode, and User mode |

**Note:**

1. In RV64GC, “G” = “IMAFD”.

Typically, in a system, the U54 cores are used to execute any of the following:

- Bare-metal user applications
- Operating systems

**Note:** Load-Reserved and Store-Conditional atomic instructions (lr, sc) are supported on U54 processor cores.

### 3.1.2.1. Instruction Fetch Unit

The instruction fetch unit consists of an 8-way set-associative 32 KB iCache/28 KB ITIM that supports 64-byte cache line size with an access latency of one clock cycle. The U54s implement the standard Compressed (C) extension of the RISC-V architecture which allows 16-bit RISC-V instructions.

### 3.1.2.2. Execution Pipeline

The U54 execution unit is a single-issue, in-order core with 5-stage execution pipeline. The pipeline comprises following five stages:

1. Instruction fetch
2. Instruction decode and register fetch
3. Execution
4. Data memory access
5. Register write back.

The pipeline has a peak execution rate of one instruction per clock cycle, and is fully bypassed so that most instructions have a one-cycle result latency.

Most CSR writes result in a pipeline flush with a five-cycle latency.

### 3.1.2.3. Instruction Cache

The iCache memory consists of a dedicated 32 KB 8-way set-associative, Virtually Indexed Physically Tagged (VIPT) instruction cache memory with a line size of 64 bytes. The access latency of any block in the iCache is one clock cycle. iCache is not coherent with the platform memory system. Writes to iCache must be synchronized with the instruction fetch stream by executing the FENCE.I instruction.

A cache line fill triggers a burst access outside the CPU Core Complex. The U54 processor core caches instructions from executable addresses, with the exception of ITIM. See CPU Memory Map for all executable address regions, which are denoted by the attribute X. Trying to execute an instruction from a non-executable address results in a trap.

### 3.1.2.4. ITIM

iCache can be partially configured as ITIM, which occupies a 28 KB of address range in CPU Memory Map. ITIM provides high-performance, predictable instruction delivery. Fetching an instruction from ITIM is as fast as an iCache hit, without any cache misses. ITIM can hold data and instructions. Load and store operations to ITIM are not as efficient as load and store operations to E51 DTIM.

The iCache can be configured as ITIM for any ways in units of cache lines (64 B bytes). A single iCache way must remain as instruction cache. ITIM is allocated simply by storing to it. A store to the nth byte of the ITIM memory map reallocates the first (n + 1) bytes of iCache as ITIM, rounded up to the next cache line.

ITIM can be deallocated by storing zero to the first byte after the ITIM region, that is 28 KB after the base address of ITIM as indicated in CPU Memory Map. The deallocated ITIM space is automatically returned to iCache.

Software must clear the contents of ITIM after allocating it. It is unpredictable whether ITIM contents are preserved between deallocation and allocation.

### 3.1.2.5. Data Cache

The U54 dCache has an 8-way set-associative 32 KB write-back, VIPT data cache memory with a line size of 64 bytes. Access latency is two clock cycles for words and double-words, and three clock cycles for smaller quantities. Misaligned accesses are not supported in hardware and result in a trap. dCache is kept coherent with a directory-based cache coherence manager, which resides in the L2 cache.

Stores are pipelined and committed on cycles where the data memory system is otherwise idle. Loads to addresses currently in the store pipeline result in a five-cycle latency.

### 3.1.2.6. Atomic Memory Operations

The U54 core supports the RISC-V standard Atomic (A) extension on regions of the Memory Map denoted by the attribute A in CPU Memory Map. Atomic memory operations to regions that do not support them generate an access exception precisely at the core.

The load-reserved and store-conditional instructions are only supported on cached regions, hence generate an access exception on DTIM and other uncached memory regions.

See The RISC-V Instruction Set Manual, Volume I: User-Level ISA, Version 2.1 for more information on the instructions added by this extension.

### 3.1.2.7. Floating Point Unit

The U54 FPU provides full hardware support for the IEEE® 754-2008 floating-point standard for 32-bit single-precision and 64-bit double-precision arithmetic. The FPU includes a fully pipelined fused-multiply-add unit and an iterative divide and square-root unit, magnitude comparators, and float-to-integer conversion units, all with full hardware support for subnormals and all IEEE default values.

### 3.1.2.8. MMU

The U54 has support for virtual memory using a Memory Management Unit (MMU). The MMU supports the Bare and Sv39 modes as described in The RISC-V Instruction Set Manual, Volume II: Privileged Architecture, Version 1.10.

The U54 MMU has a 39-bit virtual address space mapped to a 48-bit physical address space. A hardware page-table walker refills the address translation caches. Both instruction and data address translation caches are fully associative, and have 32 entries. The MMU supports 2 MB megabytes and 1 GB gigabytes to reduce translation overheads for large contiguous regions of virtual and physical address space.

U54 cores do not automatically set the Accessed (A) and Dirty (D) bits in a Sv39 PTE. The U54 MMU raises a page fault exception for a read to a page with PTE.A=0 or a write to a page with PTE.D=0.

### 3.1.2.9. ECC

By default, the iCache, ITIM, and dCache implement SECDED for ECC. ECC is applied at the 32-bit codeword level, with an ECC overhead of 7 bits per codeword. The ECC feature of L1 cache is handled internally, user control is not supported.

When a single-bit error is detected in the ITIM, the error is corrected automatically and written back to the SRAM. When a single-bit error is detected in the L1 instruction cache, the error is corrected automatically and the cache line is flushed. When a single-bit error is detected in the L1 data cache, the data cache automatically implements the following sequence of operations:

1. Corrects the error.
2. Invalidates the cache line.
3. Writes the line back to the next level of the memory hierarchy.

The ECC reporting scheme is same as described in ECC Reporting.

### 3.1.2.10. Hardware Performance Monitor

The scheme is same as described in Hardware Performance Monitor.

## 3.1.3. CPU Memory Map

The overall physical memory map of the CPU Core Complex is shown in MSS Memory Map. The CPU Core Complex is configured with a 38-bit physical address space.

## 3.1.4. Physical Memory Protection

Exclusive access to memory regions for a processor core (Hart) can be enabled by configuring its PMP registers. Each Hart supports a Physical Memory Protection (PMP) unit with 16 PMP regions.

The PMP unit in each processor core includes the following control and status registers (CSRs) to enable the PMP:

- PMP Configuration Register (pmpcfg) – used for setting privileges (R, W, and X) for each PMP region.
- PMP Address Register (pmpaddr) – used for setting the address range for each PMP region.

> **Important:** For more information on configuring PMP, see the example project in GitHub.

### 3.1.4.1. PMP Configuration Register (pmpcfg)

pmpcfg0 and pmpcfg2 support eight PMP regions each as shown in Figure 3-1. These two registers hold the configurations for the 16 PMP regions. Each PMP region is referred as pmpicfg. In pmpicfg, i ranges from 0 to 15 (pmp0cfg, pmp1cfg ... pmp15cfg). PolarFire SoC supports RV64. For RV64, pmpcfg1 and pmpcfg3 are not used.

**Figure 3-1. RV64 PMP Configuration CSR Layout**

| 63 | 56 55 | 48 47 | 40 39 | 32 31 | 24 23 | 16 15 | 8 7 | 0 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| pmp7cfg | pmp6cfg | pmp5cfg | pmp4cfg | pmp3cfg | pmp2cfg | pmp1cfg | pmp0cfg | pmpcfg0 |
| 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 |
| 63 | 56 55 | 48 47 | 40 39 | 32 31 | 24 23 | 16 15 | 8 7 | 0 |
| pmp15cfg | pmp14cfg | pmp13cfg | pmp12cfg | pmp11cfg | pmp10cfg | pmp9cfg | pmp8cfg | pmpcfg2 |
| 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 |

The R, W, and X bits, when set, indicate that the PMP entry permits read, write, and instruction execution, respectively. When one of these bits is cleared, the corresponding access type is denied. The Address-Matching (A) field encodes the Address-Matching mode of the associated PMP address register. The Locking and Privilege mode (L) bit indicates that the PMP entry is locked.

**Figure 3-2. PMP Configuration Register Format**

| 7 | [6:5] | [4:3] | 2 | 1 | 0 |
| --- | --- | --- | --- | --- | --- |
| L | Reserved | A | X | W | R |

The A field in a PMP entry's configuration register encodes the address-matching mode of the associated PMP address register. When A=0, this PMP entry is disabled and matches no addresses. Three address-matching modes are supported—Top of Range (TOR), naturally aligned four-byte regions (NA4), naturally aligned power-of-two regions (NAPOT) as listed in the following table.

**Table 3-5. Encoding of A field in PMP Configuration Registers**

| Address Matching | Name | Description |
| --- | --- | --- |
| 0 | OFF | No region (disabled) |
| 1 | TOR | Top of range |
| 2 | NA4 | Naturally aligned four-byte region |
| 3 | NAPOT | Naturally aligned power-of-two region, ≥ 8 bytes |

NAPOT ranges make use of the low-order bits of the associated address register to encode the size of the range, as listed in Table 3-6.

**Table 3-6. NAPOT Range Encoding**

| pmpaddr (Binary) | pmpcfg.A Value | Match Type and Size |
| --- | --- | --- |
| aaaa...aaaa | NA4 | 4-byte NAPOT range |
| aaaa...aaa0 | NAPOT | 8-byte NAPOT range |
| aaaa...aa01 | NAPOT | 16-byte NAPOT range |
| aaaa...a011 | NAPOT | 32-byte NAPOT range |
| ... | ... | ... |
| aa01...1111 | NAPOT | 2XLEN-byte NAPOT range |
| a011...1111 | NAPOT | 2XLEN+1 byte NAPOT range |
| 0111...1111 | NAPOT | 2XLEN+2 byte NAPOT range |

### 3.1.4.1.1. Locking and Privilege Mode

The L bit indicates that the PMP entry is locked, that is, writes to the Configuration register (pmppcfg) and associated address registers (pmpaddr) are ignored. Locked PMP entries can only be unlocked with a system reset. In addition to locking the PMP entry, the L bit indicates whether the R/W/X permissions are enforced on Machine (M) mode accesses. When the L bit is set, these permissions are enforced for all privilege modes. When the L bit is clear, any M-mode access matching the PMP entry succeeds; the R/W/X permissions apply only to Supervisor (S) and User (U) modes.

### 3.1.4.2. PMP Address Register (pmpaddr)

The PMP address registers are CSRs named from pmpaddr0 to pmpaddr15. Each PMP address register encodes the bits [55:2] of a 56-bit physical address as shown in the following figure.

**Figure 3-3. RV64 PMP Address Register Format**

| [63:54] | [53:0] |
| --- | --- |
| Reserved | Address [55:2] |
| WIRI | WARL |

**Note:** Bits [1:0] of PMP address region are not considered because minimum granularity is four bytes.

For more information about the RISC-V physical memory protection, see The RISC-V Instruction Set Manual, Volume II: Privileged Architecture, Version 1.10.

## 3.1.5. L2 Cache

The shared 2 MB L2 cache is divided into four address-interleaved banks to improve performance. Each bank is 512 KB in size, and is a 16-way set-associative cache. The L2 also supports runtime reconfiguration between cache and scratchpad RAM.

## 3.1.6. L2 Cache Controller

The L2 cache controller offers extensive flexibility as it allows for several features in addition to the Level 2 cache functionality such as memory-mapped access to L2 cache RAM for disabled cache ways, scratchpad functionality, way masking and locking, and ECC support with error tracking statistics, error injection, and interrupt signaling capabilities.

> **Important:** L2 cache controller supports single-bit ECC through ECC registers. Dual-bit ECC is implemented by default and is not visible to the user.

### 3.1.6.1. Functional Description

The L2 cache controller is configured into four banks, each bank contains 512 sets of 16 ways and each way contains a 64 byte block. This subdivision into banks facilitates increased available bandwidth between CPU masters and the L2 cache as each bank has its own 128-bit TL-C (TileLink Cached) inner port. Hence, multiple requests to different banks may proceed in parallel.

The outer port of the L2 cache controller is a 128-bit TL-C port shared amongst all banks and connected to a DDR controller (see Figure 2-1). The overall organization of the L2 cache controller is shown in the following figure.

**Figure 3-4. L2 Cache Controller**

### 3.1.6.1.1. Way Enable and the L2 LIM

Similar to ITIM, L2 cache can be configured as LIM, or as a cache which is controlled by the L2 cache controller to contain a copy of any cacheable address.

When cache ways are disabled, they are addressable in the L2-LIM address space in MSS Memory Map. Fetching instructions or data from the L2-LIM provides deterministic behavior equivalent to an L2 cache hit, with no possibility of a cache miss. Accesses to L2-LIM are always given priority over cache way accesses which target the same L2 cache bank.

After reset, all ways are disabled, except way0. Cache ways can be enabled by writing to the WayEnable register described in Way Enable Register (WayEnable). Once a cache way is enabled, it cannot be disabled unless the Core Complex is reset. The highest numbered L2 cache way is mapped to the lowest L2-LIM address space, and way 1 occupies the highest L2-LIM address range. When L2 cache ways are enabled, the size of the L2-LIM address space shrinks. The mapping of L2 cache ways to L2-LIM address space is shown in the following figure.

**Figure 3-5. Mapping of L2 Cache Ways to L2-LIM Addresses**

### 3.1.6.1.2. Way Masking and Locking

The L2 cache controller controls the amount of cache allocated to a CPU master using the WayMaskX register described in Way Mask Registers (WayMaskX). WayMaskX registers only affect allocations and reads can still occur to ways which are masked. To lock down specific cache ways, mask them in all WayMaskX registers. In this scenario, all masters will be able to read data in the locked cache ways but not be able to evict.

### 3.1.6.1.3. L2 Cache Power Control

Shutdown controls are provided for the 2 MB L2 cache memory with configuration support for either 512 KB, 1 MB, or 1,512 KB of L2 cache. This enables less static power consumption. The following 4-bit control register is provided for shutting down L2 cache blocks.

**Table 3-7. L2 Cache Power Down**

| Register | Bits | Description |
| --- | --- | --- |
| L2_SHUTDOWN_CR (0x174) | [3:0] | Configured to shutdown L2 cache blocks of Bank 0 to 3 |

**Important:** Actual RAM width is 72 bits as an additional 8 ECC bits are used per 64-bit word.

**Table 3-8. L2 RAM Shutdown**

| Bank | L2_SHUTDOWN_CR[3] | L2_SHUTDOWN_CR[2] | L2_SHUTDOWN_CR[1] | L2_SHUTDOWN_CR[0] |
| --- | --- | --- | --- | --- |
| Bank 0 | cc_ram_24 | cc_ram_16 | cc_ram_8 | cc_ram_0 |
| | cc_ram_25 | cc_ram_17 | cc_ram_9 | cc_ram_1 |
| | cc_ram_26 | cc_ram_18 | cc_ram_10 | cc_ram_2 |
| | cc_ram_27 | cc_ram_19 | cc_ram_11 | cc_ram_3 |
| | cc_ram_28 | cc_ram_20 | cc_ram_12 | cc_ram_4 |
| | cc_ram_29 | cc_ram_21 | cc_ram_13 | cc_ram_5 |
| | cc_ram_30 | cc_ram_22 | cc_ram_14 | cc_ram_6 |
| | cc_ram_31 | cc_ram_23 | cc_ram_15 | cc_ram_7 |
| Bank 1 | cc_ram_24 | cc_ram_16 | cc_ram_8 | cc_ram_0 |
| | cc_ram_25 | cc_ram_17 | cc_ram_9 | cc_ram_1 |
| | cc_ram_26 | cc_ram_18 | cc_ram_10 | cc_ram_2 |
| | cc_ram_27 | cc_ram_19 | cc_ram_11 | cc_ram_3 |
| | cc_ram_28 | cc_ram_20 | cc_ram_12 | cc_ram_4 |
| | cc_ram_29 | cc_ram_21 | cc_ram_13 | cc_ram_5 |
| | cc_ram_30 | cc_ram_22 | cc_ram_14 | cc_ram_6 |
| | cc_ram_31 | cc_ram_23 | cc_ram_15 | cc_ram_7 |
| Bank 2 | cc_ram_24 | cc_ram_16 | cc_ram_8 | cc_ram_0 |
| | cc_ram_25 | cc_ram_17 | cc_ram_9 | cc_ram_1 |
| | cc_ram_26 | cc_ram_18 | cc_ram_10 | cc_ram_2 |
| | cc_ram_27 | cc_ram_19 | cc_ram_11 | cc_ram_3 |
| | cc_ram_28 | cc_ram_20 | cc_ram_12 | cc_ram_4 |
| | cc_ram_29 | cc_ram_21 | cc_ram_13 | cc_ram_5 |
| | cc_ram_30 | cc_ram_22 | cc_ram_14 | cc_ram_6 |
| | cc_ram_31 | cc_ram_23 | cc_ram_15 | cc_ram_7 |
| Bank 3 | cc_ram_24 | cc_ram_16 | cc_ram_8 | cc_ram_0 |
| | cc_ram_25 | cc_ram_17 | cc_ram_9 | cc_ram_1 |
| | cc_ram_26 | cc_ram_18 | cc_ram_10 | cc_ram_2 |
| | cc_ram_27 | cc_ram_19 | cc_ram_11 | cc_ram_3 |
| | cc_ram_28 | cc_ram_20 | cc_ram_12 | cc_ram_4 |
| | cc_ram_29 | cc_ram_21 | cc_ram_13 | cc_ram_5 |
| | cc_ram_30 | cc_ram_22 | cc_ram_14 | cc_ram_6 |
| | cc_ram_31 | cc_ram_23 | cc_ram_15 | cc_ram_7 |

### 3.1.6.1.4. Scratchpad

The L2 cache controller has a dedicated scratchpad address region which allows for allocation into the cache using an address range which is not memory backed. This address region is denoted as the L2 Zero Device in MSS Memory Map. Writes to the scratchpad region will allocate into cache ways which are enabled and not masked. Care must be taken with the scratchpad, as there is no memory backing this address space. Cache evictions from addresses in the scratchpad results in data loss.

The main advantage of the L2 scratchpad over the L2-LIM is that it is a cacheable region allowing for data stored to the scratchpad to also be cached in a master’s L1 data cache resulting in faster access.

The recommended procedure for using the L2 Scratchpad is as follows:

1. Use the WayEnable register to enable the desired cache ways.
2. Designate a single master which will be allocated into the scratchpad. For this procedure, designate the master as Master S. All other masters (CPU and non-CPU) will be denoted as Masters X.
3. Masters X: write to the WayMaskX register to mask all ways which are to be used for the scratchpad. This will prevent Masters X from evicting cache lines in the designated scratchpad ways.
4. Master S: write to the WayMaskX register to mask all ways except the ways which are to be used for the scratchpad. At this point, Master S should only be able to allocate into the cache ways meant to be used as a scratchpad.
5. Master S: write scratchpad data into the L2 Scratchpad address range (L2 Zero Device).
6. Master S: Repeat steps 4 and 5 for each way to be used as scratchpad.
7. Master S: Use the WayMaskX register to mask the scratchpad ways for Master S so that it cannot evict cache lines from the designated scratchpad ways.
8. At this point, the scratchpad ways must contain the scratchpad data, with all masters able to read, write, and execute from this address space, and no masters able to evict the scratchpad contents.

### 3.1.6.1.5. L2 ECC

The L2 cache controller supports ECC for Single-Error Correction and Double-Error Detection (SECDED). The cache controller also supports ECC for meta-data information (index and tag information) and can perform SECDED. The single-bit error injection is available for the user to control. Dual-bit error injection is handled internally without user control.

Whenever a correctable error is detected, the caches immediately repair the corrupted bit and write it back to SRAM. This corrective procedure is completely invisible to the application software. However, the automatic write-back of the corrected data only occurs when the L2 is configured and used as L2 cache memory or scratchpad memory. In LIM mode, although SECDED occurs upon read, the automatic write-back of the single-bit corrected data is not supported.

To support diagnostics, the cache records the address of the most recently corrected meta-data and data errors. Whenever a new error is corrected, a counter is incremented and an interrupt is raised. There are independent addresses, counters, and interrupts for correctable meta-data and data errors.

DirError, DirFail, DataError, and DataFail signals are used to indicate that an L2 meta-data, data, or un-correctable L2 data error has occurred respectively. These signals are connected to the PLIC as described in Interrupt Sources and are cleared upon reading their respective count registers.

### 3.1.6.2. Register Map

The L2 cache controller register map is described in the following table.

**Table 3-9. L2 Cache Controller Register Map**

| Offset | Width | Attributes | Register Name | Notes |
| --- | --- | --- | --- | --- |
| 0x000 | 4B | RO | Config | Information on the configuration of the L2 cache |
| 0x008 | 1B | RW | WayEnable | Way enable register |
| 0x040 | 4B | RW | ECCInjectError | ECC error injection register |
| 0x100 | 8B | RO | ECCDirFixAddr | Address of most recently corrected metadata error |
| 0x108 | 4B | RO | ECCDirFixCount | Count of corrected metadata errors |
| 0x120 | 8B | RO | ECCDirFailAddr | Address of most recent uncorrectable metadata error |
| 0x128 | 8B | RO | ECCDirFailCount | Count of uncorrectable metadata errors |
| 0x140 | 8B | RO | ECCDataFixAddr | Address of most recently corrected data error |
| 0x148 | 4B | RO | ECCDataFixCount | Count of corrected data errors |
| 0x160 | 8B | RO | ECCDataFailAddr | Address of most recent uncorrectable data error |
| 0x168 | 4B | RO | ECCDataFailCount | Count of uncorrectable data errors |
| 0x200 | 8B | WO | Flush64 | Flush cache block, 64-bit address |
| 0x240 | 4B | WO | Flush32 | Flush cache block, 32-bit address |
| 0x800 | 8B | RW | Master 0 way mask register | DMA |
| 0x808 | 8B | RW | Master 1 way mask register | AXI4_front_port ID#0 |
| 0x810 | 8B | RW | Master 2 way mask register | AXI4_front_port ID#1 |
| 0x818 | 8B | RW | Master 3 way mask register | AXI4_front_port ID#2 |
| 0x820 | 8B | RW | Master 4 way mask register | AXI4_front_port ID#3 |
| 0x828 | 8B | RW | Master 5 way mask register | Hart 0 dCache MMIO |
| 0x830 | 8B | RW | Master 6 way mask register | Hart 0 iCache |
| 0x838 | 8B | RW | Master 7 way mask register | Hart 1 dCache |
| 0x840 | 8B | RW | Master 8 way mask register | Hart 1 iCache |
| 0x848 | 8B | RW | Master 9 way mask register | Hart 2 dCache |
| 0x850 | 8B | RW | Master 10 way mask register | Hart 2 iCache |
| 0x858 | 8B | RW | Master 11 way mask register | Hart 3 dCache |
| 0x860 | 8B | RW | Master 12 way mask register | Hart 3 iCache |
| 0x868 | 8B | RW | Master 13 way mask register | Hart 4 dCache |
| 0x870 | 8B | RW | Master 14 way mask register | Hart 4 iCache |

### 3.1.6.3. Register Descriptions

This section describes registers of the L2 cache controller. For more information, see PolarFire SoC Device Register Map.

#### 3.1.6.3.1. Cache Configuration Register (Config)

The Config register can be used to programmatically determine information regarding the cache.

**Table 3-10. Cache Configuration Register (Config)**

| Bits | Field Name | Attributes | Reset | Description |
| --- | --- | --- | --- | --- |
| [7:0] | Banks | RO | 4 | Return the number of banks in the cache |
| [15:8] | Ways | RO | 16 | Return the total number of enabled ways in the cache |
| [23:16] | Sets | RO | 9 | Return the Base-2 logarithm of the number of sets in a cache bank |
| [31:24] | Bytes | RO | 6 | Return the Base-2 logarithm of the number of bytes in a cache blocks |

#### 3.1.6.3.2. Way Enable Register (WayEnable)

The WayEnable register determines which ways of the L2 cache controller are enabled as cache. Cache ways which are not enabled, are mapped into the L2-LIM as described in MSS Memory Map.

This register is initialized to 0 on reset and may only be increased. This means that, out of Reset, only a single L2 cache way is enabled as one cache way must always remain enabled. Once a cache way is enabled, the only way to map it back into the L2-LIM address space is by a Reset.

**Table 3-11. Way Enable Register (WayEnable)**

| Register Offset | 0x008 |
| --- | --- |
| Bits | Field Name | Attributes | Reset | Description |
| [7:0] | Way Enable | RW | 0 | Way indexes less than or equal to this register value may be used by the cache |
| [63:8] | Reserved | RW | — | — |

#### 3.1.6.3.3. ECC Error Injection Register (ECCInjectError)

The ECCInjectError register can be used to insert an ECC error into either the backing data or meta-data SRAM. This function can be used to test error correction logic, measurement, and recovery.

The ECC Error injection system works only during writes, which means that the stored data and ECC bits are modified on a write. ECC error is not injected or detected until a write occurs. Hence, a read will complete without ECC errors being detected if a write is not carried out after enabling the ECC error injection register.

**Table 3-12. ECC Error Injection Register (ECCInjectError)**

| Register Offset | 0x040 |
| --- | --- |
| Bits | Field Name | Attributes | Reset | Description |
| [7:0] | Bit Position | RW | 0 | Specifies a bit position to toggle, within an SRAM. The width is SRAM width depends on the micro architecture, but is typically 72 bits for data SRAMs and ≈ 24 bits for Directory SRAM. |
| [15:8] | Reserved | RW |  | — |
| 16 | Target | RW | 0 | Setting this bit means the error injection will target the metadata SRAMs. Otherwise, the error injection targets the data SRAMs. |
| [31:17] | Reserved | RW | — | — |

#### 3.1.6.3.4. ECC Directory Fix Address (ECCDirFixAddr)

The ECCDirFixAddr register is a Read-Only register which contains the address of the most recently corrected metadata error. This field only supplies the portions of the address which correspond to the affected set and bank, because all ways are corrected together.

#### 3.1.6.3.5. ECC Directory Fix Count (ECCDirFixCount)

The ECCDirFixCount register is a Read Only register which contains the number of corrected L2 meta-data errors. Reading this register clears the DirError interrupt signal described in L2 ECC.

#### 3.1.6.3.6. ECC Directory Fail Address (ECCDirFailAddr)

The ECCDirFailAddr register is a Read-Only register which contains the address of the most recent uncorrected L2 metadata error.

#### 3.1.6.3.7. ECC Directory Fail Count (ECCDirFailCount)

The ECCDirFailCount register is a Read-Only register which contains the number of uncorrected L2 metadata errors.

#### 3.1.6.3.8. ECC Data Fix Address (ECCDataFixAddr)

The ECCDataFixAddr register is a Read-Only register which contains the address of the most recently corrected L2 data error.

#### 3.1.6.3.9. ECC Data Fix Count (ECCDataFixCount)

The ECCDataFixCount register is a Read Only register which contains the number of corrected data errors. Reading this register clears the DataError interrupt signal described in L2 ECC.

#### 3.1.6.3.10. ECC Data Fail Address (ECCDataFailAddr)

The ECCDataFailAddr register is a Read-Only register which contains the address of the most recent uncorrected L2 data error.

#### 3.1.6.3.11. ECC Data Fail Count (ECCDataFailCount)

The ECCDataFailCount register is a Read-Only register which contains the number of uncorrected data errors. Reading this register clears the DataFail interrupt signal described in L2 ECC.

#### 3.1.6.3.12. Cache Flush Registers

The L2 cache controller provides two registers which can be used for flushing specific cache blocks. Flush64 is a 64-bit write only register that will flush the cache block containing the address written. Flush32 is a 32-bit write only register that will flush a cache block containing the written address left shifted by 4 bytes. In both registers, all bits must be written in a single access for the flush to take effect.

#### 3.1.6.3.13. Way Mask Registers (WayMaskX)

The WayMaskX register allows a master connected to the L2 cache controller to specify which L2 cache ways can be evicted by master ‘X’ as specified in the WayMaskX register. Masters can still access memory cached in masked ways. At least one cache way must be enabled. It is recommended to set/clear bits in this register using atomic operations.

**Table 3-13. Way MaskX Register (WayMaskX)**

| Register Offset | 0x800 + (8 x Master ID) |
| --- | --- |
| Bits | Field Name | Attributes | Reset | Description |
| 0 | Way0 Mask | RW | 1 | Clearing this bit masks L2 Cache Way 0 |
| 1 | Way1 Mask | RW | 1 | Clearing this bit masks L2 Cache Way 1 |
| ... | ... | ... | ... | ... |
| 15 | Way15 Mask | RW | 1 | Clearing this bit masks L2 Cache Way 15 |
| [63:16] | Reserved | RW | 1 | — |

**Important:** For Master ID, see Master 0 to 15 in Table 3-9.

**Front Port Way Masks**

The CPU Core Complex front port passes through an AXI to TileLink interface. This interface maps incoming transactions to the four internal TileLink IDs, which are referred to in the preceding WayMaskX table. These IDs are not related to the incoming AXI transaction IDs. The allocation of the TileLink IDs is dependent on the number of outstanding AXI transactions, the arrival rate relative to the transaction completion cycle, and previous events. It is not possible to predict which internal ID will be allocated to each AXI transaction and therefore which set of way masks will apply to that AXI transaction. Hence, it is recommended that all four front port way masks are configured identically. See Table 3-9 for front port WayMaskX registers.

## 3.1.7. Branch Prediction

Branch prediction is supported by all the processor cores. The branch prediction block includes the following components:

- A 28-entry branch target buffer (BTB), for predicting the target of taken branches.
- A 512-entry branch history table (BHT), for predicting the direction of conditional branches.
- A 6-entry return address stack (RAS), for predicting the target of procedure returns.

The branch prediction incurs a one-cycle latency, such that correctly predicted control-flow instructions result in no penalty. Mispredicted control-flow instructions incur a three-cycle latency. The Branch Prediction Mode (bpm) M-mode CSR at 0x7C0 is used to customize the current branch prediction behavior for predictable execution time. The following table lists the bpm CSR.

**Table 3-14. Branch Prediction Mode (bpm) CSR**

| Branch Prediction Mode (0x7C0) |
| --- |
| Bits | Field Name | Attribute | Description |
| 0 | bdp | WARL | Branch Direction Prediction. Determines the value returned by the BHT component of the branch prediction system.<br>- A zero value indicates the dynamic direction prediction<br>- a non-zero value indicates the static-taken direction prediction.<br>The BTB is cleared on any write to bdp, and the RAS is unaffected by writes to bdp. |
| [63:1] | Reserved | RO | — |

## 3.1.8. TileLink

TileLink is a chip-scale interconnect which provides multiple initiators with coherent access to memory and other target peripherals for low-latency and high throughput transfers. The TileLink arbitration is fixed as a round-robin scheme and there are no specific registers or parameters for adjusting the arbitration behaviour. The round-robin arbitration scheme is used when multiple initiators access the shared resources like the PLIC or CLINT. This scheme ensures that requests are serviced in a cyclic order, giving each initiator a chance to access the shared resource. The arbitration rotates through initiators sequentially, and if an initiator does not have a pending request during its turn, the next initiators in line gets the opportunity.

For more information, see TileLink Specification v1.7.1.

## 3.1.9. External Bus Interfaces

The following six AMBA AXI4 compliant external ports enable the CPU Core Complex to access main memory and peripherals (see Figure 2-1).

- AXI 128 to DDR Controller
- D0 (Datapath0)
- D1 (Datapath1)
- F0 (FIFO0)
- F1 (FIFO1)
- NC (Non-Cached)

To enable non-CPU masters to access the CPU Core Complex, there is an AMBA AXI4 compliant master bus port (S8 on the AXI Switch).

## 3.1.10. DMA Engine

The DMA Engine supports the following:

- Independent concurrent DMA transfers using four DMA channels.
- Generation of PLIC interrupts on various conditions during DMA execution.

The memory-mapped control registers of the DMA engine can be accessed over the TileLink slave interface. This interface enables the software to initiate DMA transfers. The DMA engine also includes a master port which goes into the TileLink bus. This interface enables the DMA engine to independently transfer data between slave devices and main memory, or to rapidly copy data between two locations in the main memory.

The DMA engine includes four independent DMA channels capable of operating in parallel to enable multiple concurrent transfers. Each channel supports an independent set of control registers and two interrupts which are described in the next sections.

The DMA engine supports two interrupts per channel to signal a transfer completion or a transfer error. The channel's interrupts are configured using its Control register described in the next section. The mapping of the CPU Core Complex DMA interrupt signals to the PLIC is described in Platform Level Interrupt Controller.

### 3.1.10.1. DMA Memory Map

The DMA engine contains an independent set of registers for each channel. Each channel’s registers start at the offset 0x1000 so that the base address for any DMA channel is: DMA Base Address + (0x1000 × Channel ID). For information about the start and end address of the DMA Controller, see DMA Controller address space in Table 10-1. The register map of a DMA channel is described in the following table.

**Table 3-15. DMA Register Map**

| DMA Memory Map per channel |  |
| --- | --- |
| Channel Base Address | DMA Controller Base Address + (0x1000 × Channel ID) |

| Offset | Width | Attributes | Register Name | Description |
| --- | --- | --- | --- | --- |
| 0x000 | 4B | RW | Control | Channel control register |
| 0x004 | 4B | RW | NextConfig | Next transfer type |
| 0x008 | 8B | RW | NextBytes | Number of bytes to move |
| 0x010 | 8B | RW | NextDestination | Destination start address |
| 0x018 | 8B | RW | NextSource | Source start address |
| 0x104 | 4B | R | ExecConfig | Active transfer type |
| 0x108 | 8B | R | ExecBytes | Number of bytes remaining |
| 0x110 | 8B | R | ExecDestination | Destination current address |
| 0x118 | 8B | R | ExecSource | Source current address |

The following sections describe the Control and Status registers of a channel.

### 3.1.10.2. Control Register

The Control register stores the current status of the channel. It can be used to claim a DMA channel, initiate a transfer, enable interrupts, and to check for the completion of a transfer. The following table defines the bit fields of the Control register.

**Table 3-16. Control Register (Control)**

| Register Offset | 0x000 + (0x1000 × Channel ID) |
| --- | --- |
| Bits | Field Name | Attributes | Reset | Description |
| 0 | claim | RW | 0 | Indicates that the channel is in use. Setting this bit clears all of the channel’s Next registers (NextConfig, NextBytes, NextDestination, and NextSource). This bit can only be cleared when run (CR bit 0) is low. |
| 1 | run | RW | 0 | Setting this bit starts a DMA transfer by copying the Next registers into their Exec counterparts |
| [13:2] | Reserved | — | 0 | — |
| 14 | doneIE | RW | 0 | Setting this bit will trigger the channel’s Done interrupt once a transfer is complete |
| 15 | errorIE | RW | 0 | Setting this bit will trigger the channel’s Error interrupt upon receiving a bus error |
| [28:16] | Reserved | — | 0 | — |
| 29 | Reserved | — | 0 | — |
| 30 | done | RW | 0 | Indicates that a transfer has completed since the channel was claimed |
| 31 | error | RW | 0 | Indicates that a transfer error has occurred since the channel was claimed |

### 3.1.10.3. Channel Next Configuration Register (NextConfig)

The read-write NextConfig register holds the transfer request type. The wsize and rsize fields are used to determine the size and alignment of individual DMA transactions as a single DMA transfer may require multiple transactions. There is an upper bound of 64B on a transaction size (read and write).

**Note:** The DMA engine supports the transfer of only a single contiguous block at a time. Supports byte-aligned source and destination size (rsize and wsize) because the granularity is at the byte level in terms of only the base 2 Logarithm (1 byte, 8 byte, 32 byte).

These fields are WARL (Write-Any Read-Legal), so the actual size used can be determined by reading the field after writing the requested size. The DMA can be programmed to automatically repeat a transfer by setting the repeat bit field. If this bit is set, once the transfer completes, the Next registers are automatically copied to the Exec registers and a new transfer is initiated. The Control.run bit remains set during “repeated” transactions so that the channel can not be claimed. To stop repeating transfers, a master can monitor the channel’s Done interrupt and lower the repeat bit accordingly.

**Table 3-17. Channel Next Configuration Register**

| Register Offset | 0x004 + (0x1000 × Channel ID) |
| --- | --- |
| Bits | Field Name | Attributes | Reset | Description |
| [1:0] | Reserved | — | — | — |
| 2 | repeat | RW | 0 | If set, the Exec registers are reloaded from the Next registers once a transfer is complete. The repeat bit must be cleared by software for the sequence to stop. |
| 3 | order | RW | 0 | Enforces strict ordering by only allowing one of each transfer type in-flight at a time. |
| [23:4] | Reserved | — | — | — |
| [27:24] | wsize | WARL | 0 | Base 2 Logarithm of DMA transaction sizes. Example: 0 is 1 byte, 3 is 8 bytes, 5 is 32 bytes |
| [31:28] | rsize | WARL | 0 | Base 2 Logarithm of DMA transaction sizes. Example: 0 is 1 byte, 3 is 8 bytes, 5 is 32 bytes |

### 3.1.10.4. Channel Next Bytes Register (NextBytes)

The read-write NextBytes register holds the number of bytes to be transferred by the channel. The NextConfig.xsize fields are used to determine the size of the individual transactions which will be used to transfer the number of bytes specified in this register. The NextBytes register is a WARL register with a maximum count that can be much smaller than the physical address size of the machine.

### 3.1.10.5. Channel Next Destination Register (NextDestination)

The read-write NextDestination register holds the physical address of the destination for the transfer.

### 3.1.10.6. Channel Next Source Address (NextSource)

The read-write NextSource register holds the physical address of the source data for the transfer.

### 3.1.10.7. Channel Exec Registers

Each DMA channel contains a set of Exec registers which hold the information about the currently executing transfer. These registers are Read-Only and initialized when the Control.run bit is set. Upon initialization, all of the Next registers are copied into the Exec registers and a transfer begins. The status of the transfer can be monitored by reading the following Exec registers.

- ExecBytes: Indicates the number of bytes remaining in a transfer
- ExecSource: Indicates the current source address
- ExecDestination: Indicates the current destination address

The base addresses of the preceding registers are listed in Table 3-15.

### 3.1.11. Write Combining Buffer (WCB)

WCB combines multiple consecutive writes to a given address range into a TileLink burst to increase the efficiency of Write transactions. Read Transactions are bypassed by WCB. WCB accesses the 256 MB of non-cached DDR region through system port 4 AXI-NC as shown in the following table.

**Table 3-18. WCB Address Range**

| Base Address | Top | Port |
| --- | --- | --- |
| 0xD000_0000 | 0xDFFF_FFFF | System Port 4 (AXI4-NC) |
| 0x18_0000_0000 | 0x1B_FFFF_FFFF | System Port 4 (AXI4-NC) |

WCB manages its internal buffers efficiently based on the incoming Write/Read transaction addresses. The key properties of WCB are as follows:

- The WCB supports all single byte, multi-byte, and word writes (any single beat writes).
- Multi-beat transactions bypass WCB
- If all internal buffers are in use, and a write to a different base address occurs, the WCB may insert idle cycles while it empties a buffer.
- A buffer in WCB is also emptied under the following conditions:
  - All bytes in the buffer have been written.
  - The buffer is not written for idle cycles.
  - A write to WCB address range followed by a read of the same address will cause a buffer to flush. The read is not allowed to pass through the WCB until the write has completed.
  - A write from a different master that matches a buffer’s base address.
  - A write from the same master to an already written byte(s) in the buffer.

#### 3.1.11.1. Idle Configuration Register (idle)

The idle register specifies the number of idle cycles before a buffer is automatically emptied. WCB can be configured to be idle for up to 255 cycles.

When idle is set to 0, WCB is disabled and writes to the WCB address range bypass WCB.

**Table 3-19. Idle Configuration Register**

| Register Offset | 0 |
| --- | --- |
| Bits | Field Name | Attributes | Reset | Description |
| [7:0] | idle | RW | 16 | Number of idle cycles before flushing a buffer. Setting to 0 disables WCB and all buffers are emptied. |
| [31:8] | Reserved | RW | X | — |

### 3.1.12. Bus Error Unit (BEU)

There is a Bus Error Unit (BEU) for each processor core. The address range of BEU 0, BEU 1, BEU 2, BEU 3, and BEU 4 is given in CPU Memory Map. BEUs record erroneous events in L1 instruction and data caches, and report them using the global and local interrupts. Each BEU can be configured to generate interrupts on L1 correctable and uncorrectable memory errors, including TileLink bus errors.

#### 3.1.12.1. BEU Register Map

The register map of a BEU is listed in the following table.

**Table 3-20. BEU Register Map**

| Offset | Width | Attributes | Register Name | Description |
| --- | --- | --- | --- | --- |
| 0x000 | 1B | RW | cause | Cause of error event based on mhpmevent register (see Table 3-21). |
| 0x008 | 1B | RW | value | Physical address of the error event |
| 0x010 | 1B | RW | enable | Event enable mask |
| 0x018 | 1B | RW | plic_interrupt | Platform level interrupt enable mask |
| 0x020 | 1B | RW | accrued | Accrued event mask |
| 0x028 | 1B | RW | local_interrupt | Local interrupt enable mask |

#### 3.1.12.2. Functional Description

The following table lists the mhpmevent[7:0] register bit fields which correspond to BEU events that can be reported.

**Table 3-21. mhpmevent[7:0]**

| Cause | Meaning |
| --- | --- |
| 0 | No Error |
| 1 | Reserved |
| 2 | Instruction cache or ITIM correctable ECC error |
| 3 | ITIM uncorrectable error |
| 4 | Reserved |
| 5 | Load or store TileLink bus error |
| 6 | Data cache correctable ECC error |
| 7 | Data cache uncorrectable ECC error |

When one of the events listed in Table 3-21 occurs, the BEU can record information about that event and can generate a global or local interrupt to the Hart. The enable register (Table 3-20) contains a mask of the events that can be recorded by the BEU. Each bit in the enable register corresponds to an event in Table 3-21. For example, if enable[3] is set, the BEU records uncorrectable ITIM errors.

The cause register indicates the event recorded most recently by the BEU. For example, a value of 3 indicates an uncorrectable ITIM error. The cause value 0 is reserved to indicate no error. The cause register is only written for events enabled in the enable register. The cause register is written when its current value is 0; that is, if multiple events occur, only the first one is latched, until software clears the cause register.

The value register holds the physical address that caused the event, or 0 if the address is unknown. The BEU writes to the value register whenever it writes the cause register. For example, when an event is enabled in the enable register and when the cause register contains 0.

The accrued register indicates all the events that occurred since the register was cleared by the software. Its format is the same as the enable register. The BEU sets bits in the accrued register whether or not they are enabled in the enable register.

The plic_interrupt register indicates the accrued events for which an interrupt must be generated through the PLIC. An interrupt is generated when any bit is set in accrued and plic_interrupt register. For example, when accrued and plic_interrupt is not 0.

The local_interrupt register indicates the accrued events for which an interrupt must be generated directly to the Hart. An interrupt is generated when any bit is set in both accrued and local_interrupt registers. For example, when accrued and local_interrupt is not 0.

The interrupt cause is 128; it does not have a bit in the mie CSR, so it is always enabled; nor does it have a bit in the mideleg CSR, so it cannot be delegated to a mode less privileged than M-mode.

## 3.1.13. Debug

The MSS includes a JTAG debug port that enables an external system to initiate debug operations on all of the processor cores. For example, a Host PC through a JTAG probe. The JTAG interface conforms to the RISC-V External Debug Support Version 0.13.

The Debug interface uses an 8-bit instruction register (IR) and supports JTAG instructions. The JTAG port within the MSS operates at 50 MHz and the JTAG pins operate at 25 MHz.

### 3.1.13.1. Debug CSRs

The per-Hart Trace and Debug Registers (TDRs) are listed in the following table.

**Table 3-22. Trace and Debug CSRs**

| CSR Name | Description | Allowed Access Modes |
| --- | --- | --- |
| tselect | Trace and debug register select | D, M |
| tdata1 | First field of selected TDR | D, M |
| tdata2 | Second field of selected TDR | D, M |
| tdata3 | Third field of selected TDR | D, M |
| dcsr | Debug control and status register | D |
| dpc | Debug PC | D |
| dscratch | Debug scratch register | D |

The dcsr, dpc, and dscratch registers are accessible only in the Debug mode. The tselect and tdata1–3 registers are accessible in the Debug mode or Machine mode.

#### 3.1.13.1.1. Trace and Debug Register Select (tselect)

The tselect register selects which bank of the three tdata1–3 registers are accessed through the other three addresses. The tselect register format is as follows:

The index field is a WARL field that does not hold indices of the unimplemented TDRs. Even if the index can hold a TDR index, it does not ensure the TDR exists. The type field of tdata1 must be inspected to determine whether the TDR exists.

**Table 3-23. tselect CSR**

| Trace and Debug Select Register |  |
| --- | --- |
| CSR | tselect |
| Bits | Field Name | Attributes | Description |
| [31:0] | index | WARL | Selection index of trace and debug registers |

#### 3.1.13.1.2. Trace and Debug Data Registers (tdata1–3)

The tdata1–3 registers are XLEN-bit read/write registers that are selected from a larger underlying bank of TDR registers by the tselect register.

**Table 3-24. tdata1 CSR**

| Trace and Debug Data Register 1 |  |
| --- | --- |
| CSR | tdata1 |
| Bits | Field Name | Attributes | Description |
| [27:0] | TDR-Specific Data | — | — |
| [31:28] | type | RO | Type of the trace and debug register selected by tselect |

**Table 3-25. tdata2–3 CSRs**

| Trace and Debug Data Registers 2-3 |  |
| --- | --- |
| CSR | tdata2-3 |
| Bits | Field Name | Attributes | Description |
| [31:0] | type | — | TDR-Specific Data |

The high nibble of tdata1 contains a 4-bit type code that is used to identify the type of TDR selected by tselect. The currently defined types are shown as follows.

**Table 3-26. TDR Types**

| Type | Description |
| --- | --- |
| 0 | No such TDR register |
| 1 | Reserved |
| 2 | Address/Data Match Trigger |
| ≥3 | Reserved |

The dmode bit of the Breakpoint Match Control Register (mcontrol) selects between the Debug mode (dmode=1) and Machine mode (dmode=1) views of the registers, where only the Debug mode code can access the Debug mode view of the TDRs. Any attempt to read/write the tdata1–3 registers in the Machine mode when dmode=1 raises an illegal instruction exception.

#### 3.1.13.1.3. Debug Control and STATUS Register (dcsr)

dcsr gives information about debug capabilities and status. Its detailed functionality is described in RISC-V Debug Specification.

#### 3.1.13.1.4. Debug PC (dpc)

dpc stores the current PC value when the execution switches to the Debug Mode. When the Debug mode is exited, the execution resumes at this PC.

#### 3.1.13.1.5. Debug Scratch (dscratch)

dscratch is reserved for Debug ROM to save registers needed by the code in Debug ROM. The debugger may use it as described in RISC-V Debug Specification.

### 3.1.13.2. Breakpoints

The CPU Core Complex supports two hardware breakpoint registers, which can be flexibly shared between Debug mode and Machine mode.

When a breakpoint register is selected with tselect, the other CSRs access the following information for the selected breakpoint:

**Table 3-27. Breakpoint Registers**

| TDR CSRs when used as Breakpoints |  |  |
| --- | --- | --- |
| CSR Name | Breakpoint Alias | Description |
| tselect | tselect | Breakpoint selection index |
| tdata1 | mcontrol | Breakpoint Match control |
| tdata2 | maddress | Breakpoint Match address |
| tdata3 | N/A | Reserved |

#### 3.1.13.2.1. Breakpoint Match Control Register (mcontrol)

Each breakpoint control register is a read/write register laid out as follows.

**Table 3-28. Test and Debug Data Register 1**

| Breakpoint Control Register (mcontrol) |  |
| --- | --- |
| Register Offset | CSR |
| Bits | Field Name | Attributes | Reset | Description |
| 0 | R | WARL | X | Address match on LOAD |
| 1 | W | WARL | X | Address match on STORE |
| 2 | X | WARL | X | Address match on Instruction FETCH |
| 3 | U | WARL | X | Address match on User mode |
| 4 | S | WARL | X | Address match on Supervisor mode |
| 5 | H | WARL | X | Address match on Hypervisor mode |
| 6 | M | WARL | X | Address match on Machine mode |
| [10:7] | match | WARL | X | Breakpoint Address Match type |
| 11 | chain | WARL | 0 | Chain adjacent conditions |
| [17:12] | action | WARL | 0 | Breakpoint action to take. 0 or 1. |
| 18 | timing | WARL | 0 | Timing of the breakpoint. Always 0 |
| 19 | select | WARL | 0 | Perform match on address or data. Always 0 |
| 20 | Reserved | WARL | X | Reserved |
| [26:21] | maskmax | RO | 4 | Largest supported NAPOT range |
| 27 | dmode | RW | 0 | Debug-Only Access mode |
| [31:28] | type | RO | 2 | Address/Data match type, always 2 |

The type field is a 4-bit read-only field holding the value 2 to indicate that this is a breakpoint containing address match logic.

The bpaction field is an 8-bit read-write WARL field that specifies the available actions when the address match is successful. The value 0 generates a breakpoint exception, and the value 1 enters Debug mode. Other actions are unimplemented.

The R/W/X bits are individual WARL fields. If they are set, it indicates an address match must only be successful for loads/stores/instruction fetches respectively. All combinations of implemented bits must be supported.

The M/H/S/U bits are individual WARL fields. If they are set, it indicates an address match must only be successful in the Machine/Hypervisor/Supervisor/User modes respectively. All combinations of implemented bits must be supported.

The match field is a 4-bit read-write WARL field that encodes the type of address range for breakpoint address matching. Three different match settings are currently supported: exact, NAPOT, and arbitrary range. A single breakpoint register supports both exact address matches and matches with address ranges that are Naturally Aligned Powers-Of-Two (NAPOT) in size. Breakpoint registers can be paired to specify arbitrary exact ranges, with the lower-numbered breakpoint register giving the byte address at the bottom of the range, the higher-numbered breakpoint register giving the address one byte above the breakpoint range, and using the chain bit to indicate both must match for the action to be taken.

NAPOT ranges make use of low-order bits of the associated breakpoint address register to encode the size of the range as listed in the following table.

**Table 3-29. NAPOT Ranges**

| maddressoor | Match type and size |
| --- | --- |
| a...aaaaaa | Exact 1 byte |
| a...aaaaa0 | 2-byte NAPOT range |
| a...aaaa01 | 4-byte NAPOT range |
| a...aaa011 | 8-byte NAPOT range |
| a...aa0111 | 16-byte NAPOT range |
| a...a01111 | 32-byte NAPOT range |
| ... | ... |
| a01...1111 | 231-byte NAPOT range |

The maskmax field is a 6-bit read-only field that specifies the largest supported NAPOT range. The value is the logarithm base 2 of the number of bytes in the largest supported NAPOT range. A value of 0 indicates that only exact address matches are supported (one-byte range). A value of 31 corresponds to the maximum NAPOT range, which is 231 bytes in size. The largest range is encoded in maddressoor with the 30 least-significant bits set to 1, bit 30 set to 0, and bit 31 holding the only address bit considered in the address comparison.

> **Important:** The unary encoding of NAPOT ranges was chosen to reduce the hardware cost of storing and generating the corresponding address mask value.

To provide breakpoints on an exact range, two neighboring breakpoints can be combined with the chain bit. The first breakpoint can be set to match on an address using the action of greater than or equal to two. The second breakpoint can be set to match on address using the action of less than three. Setting the chain bit on the first breakpoint will then cause it to prevent the second breakpoint from firing unless they both match.

#### 3.1.13.2.2. Breakpoint Match Address Register (maddress)

Each breakpoint match address register is an XLEN-bit read/write register used to hold significant address bits for address matching, and the unary-encoded address masking information for NAPOT ranges.

#### 3.1.13.2.3. Breakpoint Execution

Breakpoint traps are taken precisely. Implementations that emulate misaligned accesses in the software will generate a breakpoint trap when either half of the emulated access falls within the address range. Implementations that support misaligned accesses in hardware must trap if any byte of access falls within the matching range.

Debug mode breakpoint traps jump to the debug trap vector without altering Machine mode registers.

Machine mode breakpoint traps jump to the exception vector with “Breakpoint” set in the mcause register, and with badaddr holding the instruction or data address that caused the trap.

#### 3.1.13.2.4. Sharing Breakpoints between Debug and Machine mode

When Debug mode uses a breakpoint register, it is no longer visible to Machine mode (that is, the tdrtype will be 0). Usually, the debugger will grab the breakpoints it needs before entering Machine mode, so Machine mode will operate with the remaining breakpoint registers.

### 3.1.13.3. Debug Memory Map

This section describes the debug module’s memory map when accessed through the regular system interconnect. The debug module is only accessible to the debug code running in the Debug mode on a Hart (or through a debug transport module).

#### 3.1.13.3.1. Debug RAM and Program Buffer (0x300–0x3FF)

The CPU Core Complex has 16 32-bit words of Program Buffer for the debugger to direct a Hart to execute an arbitrary RISC-V code. Its location in memory can be determined by executing auipc instructions and storing the result into the Program Buffer.

The CPU Core Complex has one 32-bit word of Debug Data RAM. Its location can be determined by reading the DMHARTINFO register as described in the RISC-V Debug Specification. This RAM space is used to pass data for the Access Register abstract command described in the RISC-V Debug Specification. The CPU Core Complex supports only GPR register access when Harts are halted. All other commands must be implemented by executing from the Debug Program Buffer.

In the CPU Core Complex, both the Program Buffer and Debug Data RAM are general purpose RAM and are mapped contiguously in the CPU Core Complex’s memory space. Therefore, additional data can be passed in the Program Buffer, and additional instructions can be stored in the Debug Data RAM.

Debuggers must not execute Program Buffer programs that access any Debug Module memory except defined Program Buffer and Debug Data addresses.

#### 3.1.13.3.2. Debug ROM (0x800–0xFFF)

This ROM region holds the debug routines.

#### 3.1.13.3.3. Debug Flags (0x100 – 0x110, 0x400 – 0x7FF)

The flag registers in the Debug module are used to communicate with each Hart. These flags are set and read by the Debug ROM, and must not be accessed by any Program Buffer code. The specific behavior of flags is beyond the scope of this document.

#### 3.1.13.3.4. Safe Zero Address

In the CPU Core Complex, the Debug module contains the address 0 in the memory map. Reads to this address always return 0 and writes to this address have no impact. This property allows a “safe” location for unprogrammed parts, as the default mtvec location is 0x0.

### 3.1.13.4. PolarFire SoC Debug

PolarFire SoC MSS contains a Debug block that allows an external host PC to initiate debug operations on processor cores through JTAG. Using Microchip’s SoftConsole, users can perform multi-core application debugging. Using Microchip’s SmartDebug, users can perform FPGA hardware debug. For more information about SmartDebug, see SmartDebug User Guide.

#### 3.1.13.4.1. Debug Architecture

Debugging of MSS processor cores can be performed through fabric JTAG I/Os or on-chip JTAG I/Os, as shown in the following figure.

**Figure 3-6. Debug Connectivity**

The Debug options can be configured using the Standalone MSS Configurator. For more information see, Standalone MSS Configurator User Guide for PolarFire SoC.

#### 3.1.13.4.2. Multi-Core Application Debug

SoftConsole enables debugging of multi-core applications. At any given time, a single core is debugged. For information about multi-core application debug, see SoftConsole User Guide (to be published).

## 3.1.14. Trace

The MSS includes a Trace block to enable an external system to run trace functionalities through the JTAG interface. The Trace block supports the following features:

- Instruction trace of all five processor cores.
- Full AXI trace of a selectable slave interface on the main AXI switch.
- Trace of AXI transactions (address only) on L2 cache in the CPU Core Complex.
- Trace of 40-fabric signals through the Electrical Interconnect and Package (EIP) interface (40 data plus clock and valid signal).
- Interfaced through an external JTAG interface.
- An AXI communicator module is implemented allowing the firmware running on the CPU Core Complex to configure the trace system
- A Virtual Console is implemented allowing message passing between the processor cores and an external trace system.

For more information and support on the Trace functionality, contact Lauterbach.

### 3.1.14.1. Instruction Trace Interface

This section describes the interface between a core and its RISC-V trace module (see Figure 3-7). The trace interface conveys information about instruction-retirement and exception events.

Table 3-30 lists the fields of an instruction trace packet. The valid signal is 1 if and only if an instruction retires or traps (either by generating a synchronous exception or taking an interrupt). The remaining fields in the packet are only defined when valid is 1.

The iaddr field holds the address of the instruction that was retired or trapped. If address translation is enabled, it is a virtual address else it is a physical address. Virtual addresses narrower than XLEN bits are sign-extended, and physical addresses narrower than XLEN bits are zero-extended.

The insn field holds the instruction that was retired or trapped. For instructions narrower than the maximum width, for example, those in the RISC-V C extension, the unused high-order bits are zero-filled. The length of the instruction can be determined by examining the low-order bits of the instruction, as described in The RISC-V Instruction Set Manual, Volume I: User-Level ISA, Version 2.1. The width of the insn field, ILEN, is 32 bits for current implementations.

The priv field indicates the Privilege mode at the time of instruction execution. (On an exception, the next valid trace packet’s priv field gives the Privilege mode of the activated trap handler.) The width of the priv field, PRIVLEN, is 3, and it is encoded as shown in Table 3-30.

The exception field is 0 if this packet corresponds to a retired instruction, or 1 if it corresponds to an exception or interrupt. In the former case, the cause and interrupt fields are undefined, and the tval field is zero. In the latter case, the fields are set as follows:

- Interrupt is 0 for synchronous exceptions and 1 for interrupts.
- Cause supplies the exception or interrupt cause, as would be written to the lower CAUSELEN bits of the mcause CSR. For current implementations, CAUSELEN = log2XLEN.
- tval supplies the associated trap value, for example, the faulting virtual address for address exceptions, as would be written to the mtval CSR.
- Future optional extensions may define tval to provide ancillary information in cases where it currently supplies zero.

For cores that can retire N instructions per clock cycle, this interface is replicated N times. Lower numbered entries correspond to older instructions. If fewer than N instructions retire, the valid packets need not be consecutive, that is, there may be invalid packets between two valid packets. If one of the instructions is an exception, no recent instruction is valid.

**Table 3-30. Fields of an Instruction Trace Packet**

| Name | Description |
| --- | --- |
| valid | Indicates an instruction has retired or trapped. |
| iaddr[XLEN-1:0] | The address of the instruction. |
| insn[ILEN-1:0] | The instruction. |
| priv[PRIVLEN-1:0] | Privilege mode during execution. |
| exception | 0 if the instruction retired; 1 if it trapped. |
| interrupt | 0 if the exception was synchronous; 1 if interrupt. |
| cause[CAUSELEN-1:0] | Exception cause. |
| tval[XLEN-1:0] | Exception data. |

**Table 3-31. Encoding of priv Field**

| Value | Description |
| --- | --- |
| 000 | User mode |
| 001 | Supervisor mode |
| 011 | Machine mode |
| 111 | Debug mode |

**Note:** Unspecified values are reserved.

### 3.1.14.2. Trace Features

The Trace block implements a message-based protocol between a Trace Integrated Development Environment (IDE) and the Trace block through JTAG. The Trace block provides the following features:

- Instruction trace per processor core
- Full AXI (64) trace of a selectable single slave interface on the AXI Switch
- AXI transaction (no-data) trace of AXI (128) bus between L2 cache to DDR
- Status monitoring of up to 40 fabric signals

The Trace block collects the trace data and sends it to a Trace IDE running on a Host PC. The trace data can be used to identify performance and fault points during program execution.

### 3.1.14.3. Trace Architecture

The following figure shows the high-level architecture and components of the Trace block.

**Figure 3-7. Trace Block Diagram**

### 3.1.14.4. Trace Components

The Trace contains the following components:

- JTAG Communicator
- JPAM
- Message Infrastructure Bus
- AXI Monitor 0
- AXI Monitor 1
- Virtual Console
- AXI Communicator
- System Memory Buffer (SMB)
- RISC-V Trace
- Fabric Trace

#### 3.1.14.4.1. JTAG Communicator

JTAG Communicator connects a Host to the Trace block through JTAG. The JTAG Communicator Test Access Point (TAP) contains an 8-bit instruction register (IR) and supports the JTAG instructions.

#### 3.1.14.4.2. JPAM

JTAG Processor Analytic Module (JPAM) provides access to the JTAG debug module of the CPU Core Complex. This debug module enables the debugging of processor cores. JPAM can connect to the fabric JTAG controller or the On-Chip JTAG controller.

#### 3.1.14.4.3. Message Infrastructure Bus

The message infrastructure bus provides a basic message and event routing function. This component enables message exchange between JTAG Communicator and analytic modules, and vice versa.

The message infrastructure bus contains the following:

- A 32-bit bus configured for downstream messages for data trace
- An 8-bit bus for upstream messages (control)

These two buses operate using the MSS AXI clock.

#### 3.1.14.4.4. AXI Monitor 0

AXI Monitor 0 is an analytic module that provides full address and data trace on a selectable single slave interface of the AXI Switch (S1 to S8). This module also provides an 3-bit GPIO control unit to enable the trace of slave port from S1:S8. For example, setting GPIO_0 enables the trace of S1 port on the AXI switch.

#### 3.1.14.4.5. AXI Monitor 1

AXI Monitor 1 is an analytic module that provides full address trace on the AXI4-128 bus between the CPU Core Complex L2 Cache and DDR. AXI Monitor 1 does not provide data trace ability. This component enables the trace of effectiveness of the L2 Cache and DDR response rates.

#### 3.1.14.4.6. Virtual Console

Virtual Console is an analytic module that provides an AXI4 interface to enable communication between the Debug module and the Trace IDE. This peripheral interface enables the software to communicate with the Debug module through the Message Infrastructure Bus sub-block of Trace.

#### 3.1.14.4.7. AXI Communicator

The AXI Communicator module provides an AXI4 interface for the system software to communicate with any analytic module in the Trace block.

#### 3.1.14.4.8. System Memory Buffer (SMB)

System Memory Buffer (SMB) is a communicator module that provides buffering and storing of messages in a region of shared system memory. The SMB connects to the system memory through AXI Switch and to the Message Infrastructure Bus sub-block through input and output message interfaces.

#### 3.1.14.4.9. RISC-V Trace

RISC-V trace module is a processor analytic module that provides instruction trace from a processor core. Optional statistics counters are also available. The five identical RISC-V trace modules support the RISC-V ISA enabling the trace of E51 and four U54 processor cores. These modules support filtering which can be used to specify the attributes to be traced and when to be traced.

#### 3.1.14.4.10. Fabric Trace

Fabric Trace is a status monitoring analytic module that provides a 40 channel logic analyzer required for hardware tracing of the FPGA fabric design concurrently with CPU and AXI trace functions. It also provides an 8-bit GPIO control unit enabling the Trace block to control internal FPGA fabric functions. One of these GPIO connections can be used to control a 2:1 MUX allowing greater than 32 channels to be traced (32 at a time) without reprogramming the PolarFire SoC device.

The following table lists the interfaces ports of Fabric Trace.

**Table 3-32. Fabric Trace IO Ports**

| EIP Connection | MSS Direction | Function |
| --- | --- | --- |
| USOC_TRACE_CLOCK_F2M | Input | Clock input to Fabric Trace |
| USOC_TRACE_VALID_F2M | Input | Valid input to Fabric Trace |
| USOC_TRACE_DATA_F2M[39:0] | Input | 40-bit trace input to Fabric Trace |
| USOC_CONTROL_DATA_M2F[7:0] | Output | 8-bit GPIO to the fabric |
