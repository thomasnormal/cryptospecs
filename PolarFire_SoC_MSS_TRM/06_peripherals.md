# 3.12 Peripherals

<!-- page 11: manual page 61 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 61
2. Using any browser, open the pfsoc_regmap.htm file from <$download_folder>\Register
Map\PF_SoC_RegMap_Vx_x.
3. Select MMUART0_LO (for example) to see the subsequent register descriptions and details.
4. Similarly, select other peripheral to see its subsequent register descriptions and details.
3.12.2. PolarFire SoC Gigabit Ethernet MAC (Ask a Question)
The PolarFire SoC MSS contains two hardened Gigabit Ethernet MAC IP blocks—GEM_0 and GEM_1
— to enable Ethernet solutions over copper or optical cabling.
GEM_0 and GEM_1 are functionally identical, hence, GEM_0 and GEM_1 are referred as GEM
throughout the document.
GEM supports 10 Mb/s, 100 Mb/s, and 1000 Mb/s (1 Gb/s) speeds. GEM provides a complete range
of solutions for implementing IEEE 802.3 standard-compliant Ethernet interfaces for chip-to-chip,
board-to-board, and backplane interconnects.
Important: The PolarFire SoC GEM IP block supports SGMII, and regarding its
PPM offset details across the PVT, see PolarFire SoC Datasheet.
3.12.2.1. Features (Ask a Question)
GEM supports the following features.
• IEEE 802.3 compliant
• IEEE 802.1Q TSN features:
– IEEE 802.1AS
– IEEE 802.1Qav
– IEEE 802.1Qbv
– IEEE 802.1CB frame redundancy and elimination
– IEEE 802.1Qci receive (ingress) traffic policing
– IEEE 802.3br frame preemption (or interspersing express traffic)
– IEEE 802.1Qbb priority-based flow control
– IEEE 802.1Q VLAN tagging with recognition of incoming VLAN and priority tagged frames
• DMA support
• TCP/IP offloading capability
• Integrated 1000 BASE-X PCS for SGMII-based applications
• Programmable jumbo frames up to 10,240 bytes
• Frame Filtering
• Full and half duplex modes at 10/100M and full duplex at 1 Gbps interface speeds for MII, GMII,
and SGMII.
• Wake-on LAN support
3.12.2.2. Overview  (Ask a Question)
GEM is accessed by the CPU Core Complex through the AXI Switch using the following interfaces:
• AXI interface—used for data transfers
• APB interface—used for configuration purpose
GEM can be configured for SGMII or MII/GMII. The MII/GMII is only connected to the FPGA fabric.
The PCS sub-block performs the 8b/10b operation for SGMII. SGMII is connected to the I/O BANK 5.
Management Data Input/Output (MDIO) interface signals can be routed either from the FPGA fabric

<!-- page 12: manual page 62 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 62
or from a dedicated MSSIO. The external PHY registers are configured using management interface
(MDIO) of the GEM.
The following figure shows a high-level block diagram of GEM blocks.
Figure 3-20. High-Level Block Diagram
3.12.2.3. Clocking  (Ask a Question)
GEM requires the following clocks:
• tsu_clk: Clock frequency ranges from 5 MHz to 400 MHz for the timestamp unit. Timestamp
accuracy improves with higher frequencies. To support single step timestamping, tsu_clk
frequency must be greater than 1/8th the frequency of tx_clk or rx_clk.
• tx_clk: Clock frequency ranges are: 1.25 MHz, 2.5 MHz,12.5 MHz, 25 MHz, and 125 MHz for MAC
transmit clock used by the MAC transmit block. In the 10/100 GMII mode, tx_clk runs at either
2.5 MHz or 25 MHz as determined by the external PHY MII clock input. When using Gigabit mode,
the transmit clock must be sourced from a 125 MHz reference clock. Depending on the system
architecture, this reference clock may be sourced from an on-chip clock multiplier, generated
directly from an off-chip oscillator, or taken from the PHY rx_clk. In the SGMII mode, this clock is
sourced from the gtx_clk.
• gtx_clk: 125 MHz PCS transmit clock. In SGMII application, this is recovered from input data and
needs to be balanced with the tx_clk.

<!-- page 13: manual page 63 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 63
• rx_clk: Clock frequency ranges are: 1.25 MHz, 2.5 MHz, 12.5 MHz, 25 MHz, 62.5 MHz, and
125 MHz. This clock is used by the MAC receive synchronization blocks. In the 10/100 and Gigabit
mode using the GMII/MII interface, this clock is sourced from the rx_clk input of the external PHY
and can be either 2.5 MHz, 25 MHz, or 125 MHz.
The following table lists the required frequencies of the transmit clock.
Table 3-56. Transmit Clock Frequencies
MAC Speed Mode (Mbps) gtx_clk (MHz) tx_clk (MHz)
SGMII GMII SGMII MII
10 125 N/A 1.25 2.5
100 125 N/A 12.5 25
1000 125 125 125 125
The following table lists the required frequencies of the receive clock.
Table 3-57. Receive Clock Frequencies
MAC Speed Mode (Mbps) pcs_rx_clk (MHz) rx_clk (MHz)
SGMII GMII/MII SGMII GMII/MII
10 125 N/A 1.25 2.5
100 125 N/A 12.5 25
1000 125 N/A 62.5 125
For more information about GEM Clocking, see PolarFire Family Clocking Resources User Guide.
3.12.2.4. Functional Description  (Ask a Question)
GEM includes the following functional blocks:
• Integrated 1000BASE-X Physical Coding Sublayer (PCS) for encoding and decoding the data and
for Auto Negotiation (AN)
• Time Stamping Unit (TSU) for timer operations
• TSN block to support Timing Sensitive Networking (TSN) features
• High-speed AXI DMA block to transfer data to and from the processor
• Filter block filters out the received frames

<!-- page 14: manual page 64 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 64
Figure 3-21. Functional Block Diagram
3.12.2.4.1. MAC Transmitter (Ask a Question)
The MAC transmitter block retrieves data from the memory using DMA controller, which is
connected through the AXI interface. DMA reads the data from memory using the AXI master
interface and stores it to the TX packet buffer. Then, the MAC transmitter block retrieves the data
from the TX packet buffer and adds preamble and, if necessary, pad and Frame Check Sequence
(FCS). The data is transmitted using configured data interface such as MII, GMII, or SGMII.
Both half-duplex and full-duplex Ethernet modes of operation are supported. When operating
in Half-Duplex mode, the MAC transmitter block generates data according to the Carrier Sense
Multiple Access with Collision Detect (CSMA/CD) protocol. The start of transmission is deferred if
Carrier Sense (CS) is active. If collision (col) becomes active during transmission, a jam sequence is
asserted, and the transmission is re-tried after a random back off. The CS and col signals have no
effect in Full-Duplex mode.
According to the IEEE 802.3 standards, an Ethernet MAC must allow a minimum amount of time
before another packet is sent. This pause time between packets is known as Inter-Packet Gap (IPG).
The purpose of the IPG is to allow enough time for the receiver to recover the clock and to perform
cleanup operations. During this period, IDLE packets will be transmitted. The standard minimum IPG
for transmission is 96 bit times. Using GEM, the IPG may be stretched beyond 96 bits depending on
the length of the previously transmitted frame. The IPG stretch only works in the Full-Duplex mode.
Transmit DMA Buffers (Ask a Question)
Frames to be transmitted are stored in one or more transmit buffers. The maximum size of a
transmit frame is 10240 bytes. The start location for each transmit buffer is stored in AXI memory
in a list of transmit buffer descriptors at a location pointed to by the transmit buffer queue pointer.
The base address for this queue pointer is set in software using the transmit buffer queue base

<!-- page 15: manual page 65 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 65
address register. The upper transmit queue base address register at 0x04c8 is used to set the upper
32 bits of the transmit buffer descriptor queue base address. All the descriptors must be located
within a region of memory that does not cross a 4 GB region. The actual 32 bits, chosen for the
upper bits, are programmed in the upper receive queue base address register at 0x04c8.
To transmit frames, the buffer descriptors must be initialized by writing an appropriate byte address
to bits 31:0 in the first word of each descriptor list entry to indicate the location of the data to be
transmitted.
The second word of the transmit buffer descriptor is initialized with control information that
indicates the length of the frame, whether or not the MAC is to append CRC and whether the buffer
is the last buffer in the frame. It also contains the “used” and “wrap” bits. It is very important that
the transmit buffer descriptor list contains at least one entry with its “used” bit set. This is because
the transmit DMA can read the buffer descriptor list very fast and will loop round retransmitting
data when it encounters the wrap bit. When initializing the descriptor list the user needs to add an
additional buffer descriptor with its “used” bit set after the buffer descriptors which describe the
data to be transmitted.
The following table lists the transmit buffer descriptor entry.
Table 3-58. Transmit Buffer Descriptor Entry
Bit Function
Word 0
31:0 Byte address of the buffer
Word 1
31 Used – must be zero for GEM to read data to the transmit
buffer.
GEM sets this to one for the first buffer of a frame once it
has been successfully transmitted. Software must clear this
bit before the buffer can be used again.
30 Wrap – marks last descriptor in transmit buffer descriptor
list.
This can be set for any buffer within the frame.
29 Retry limit exceeded, transmit error detected
28 Transmit underrun.
Occurs when the start of packet data has been written into
the FIFO and either the transmit data could not be fetched in
time, or when buffers are exhausted. This is not set when the
DMA is configured for packet buffer mode.
27 Transmit frame corruption due to AXI error – set if an error
occurs whilst midway through reading transmit frame from
the AXI, and RRESP/BRESP errors and buffers exhausted mid
frame (if the buffers run out during transmission of a frame
then transmission stops, Frame Check Sequence (FCS) shall
be bad and tx_er asserted).
26 Late collision, transmit error detected.
Late collisions only force this status bit to be set in gigabit
mode.
25:24 Reserved
23 Reserved

<!-- page 16: manual page 66 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 66
Table 3-58. Transmit Buffer Descriptor Entry (continued)
Bit Function
22:20 Transmit IP/TCP/UDP checksum generation offload errors:
• 000 - No Error
• 001 - The Packet was identified as a VLAN type, but the
header was not fully complete, or had an error in it
• 010 - The Packet was identified as a SNAP type, but the
header was not fully complete, or had an error in it
• 011 - The Packet was not of an IP type, or the IP packet
was invalidly short, or the IP was not of type IPv4/IPv6
• 100 - The Packet was not identified as VLAN, SNAP, or IP
• 101 - Non supported packet fragmentation occurred.
For IPv4 packets, the IP checksum was generated and
inserted
• 110 - Packet type detected was not TCP or UDP. TCP/UDP
checksum was therefore not generated. For IPv4 packets,
the IP checksum was generated and inserted
• 111- A premature end of packet was detected and the
TCP/UDP checksum could not be generated
19:17 Reserved.
Must be set to 3’b000 to disable TSO and UFO
16 No CRC to be appended by MAC.
When set, this implies that the data in the buffers already
contains a valid CRC and hence no CRC or padding is to be
appended to the current frame by the MAC.
This control bit must be set for the first buffer in a frame and
is ignored for the subsequent buffers of a frame.
This bit must be clear when using the transmit
IP/TCP/UDP checksum generation offload, otherwise
checksum generation and substitution will not occur.
Note: This bit must also be cleared when TX Partial Store
and Forward mode is active.
15 Last buffer.
When set, this bit indicates the last buffer in the current
frame is reached.
14 Reserved
13:0 Length of the buffer
3.12.2.4.2. MAC Receiver (Ask a Question)
MAC receiver block receives data using MII, GMII, or SGMII interface and stores the data in the RX
packet buffer. Using RX DMA controller, data from the RX packet buffer is read and transferred to
the memory using AXI interface.
The MAC receive block checks for valid preamble, FCS, alignment, and length, and presents received
frames to the MAC address checking block. Firmware can configure GEM to receive jumbo frames
up to 10,240 bytes.
The address checker identifies the following:
• Four source or destination specific 48-bit addresses
• Four different types of ID values
• A 64-bit hash register for matching multi-cast and unicast addresses as required.
• Broadcast address of all ones, copy all frames and act on external address matching signals.

<!-- page 17: manual page 67 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 67
• Supports offloading of IP, TCP, and UDP checksum calculations (both IPv4 and IPv6 packet
types are supported) and can automatically discard frames with a bad checksum. As the MAC
supports TSN features, it identifies 802.1CB streams and automatically eliminates duplicate
frames. Statistics are provided to report counts of rogue and out-of-order frames, latent errors,
and the timer reset events.
• Broadcast address of all ones, copy all frames and act on external address matching signals.
During frame reception, if the frame is too long, a bad frame indication is sent to the DMA controller
and the receiver logic does not store that frame in the internal DMA buffer. At the end of frame
reception, the receive block indicates to the DMA block whether the frame is good or bad. The DMA
block recovers the current receive buffer if the frame is bad.
Receive DMA Buffers (Ask a Question)
Received frames, optionally including FCS, are written to receive buffers in the AXI memory. The
receive buffer depth is 16384 bytes.
The start location of each receive buffer is stored as a list of receive buffer descriptors. The receive
buffer queue pointer stores the address of each buffer descriptor. The base address for the receive
buffer queue pointer is configured in software using the receive buffer queue base address register
at 0x04d4 location. This register is used to set the upper 32 bits of the base address of the
descriptor. With 64-bit addressing, there is a restriction that all the descriptors must be located
within a region of memory that does not cross a 4 GB region, in other words the upper 32 bits of the
64-bit address must be fixed. This is only true of the descriptors and not the packet data which can
be anywhere in the 64-bit address space.
Each receive buffer start location is a word address. The start of the first buffer in a frame can
be offset by up to three bytes depending on the value written to bits 14 and 15 of the network
configuration register.
The following table lists the receive buffer descriptor entry.
Table 3-59. Receive Buffer Descriptor Entry
Bit Function
Word 0
31:2 Address [31:2] of beginning of buffer
1 Wrap - marks last descriptor in receive buffer descriptor list.
0 Ownership - needs to be zero for GEM to write data to the
receive buffer. GEM sets this to 1 once it has successfully
written a frame to memory. Software has to clear this bit
before the buffer can be used again.
Word 1
31 Global all ones broadcast address detected
30 Multicast hash match
29 Unicast hash match
28 External address match.
Note: If the packet buffer mode and the number of
configured specific address filters is greater than four in
gem_gxl_defs.v then external address matching is not
reported in this bit and instead it is set if there has been
a match in the first eight specific address registers. Bit 27
is then used along with bits 26:25 to indicate which register
matched.
27 Indicates a specific address register match found, bit 25 and
bit 26 indicates which specific address register causes the
match. See description of preceding bit 28.

<!-- page 18: manual page 68 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 68
Table 3-59. Receive Buffer Descriptor Entry (continued)
Bit Function
26:25 Specific address register match. Encoded as follows:
• 00 - Specific address register 1 match
• 01 - Specific address register 2 match
• 10 - Specific address register 3 match
• 11 - Specific address register 4 match
If more than one specific address is matched only one is
indicated with priority 4 down to 1.
24 This bit has a different meaning depending on whether RX
checksum offloading is enabled.
• With RX checksum offloading disabled: (bit 24 clear in
Network Configuration)
Type ID register match found, bit 22 and bit 23 indicate
which type ID register causes the match.
• With RX checksum offloading enabled: (bit 24 set in
Network Configuration)
– 0 - The frame was not SNAP encoded and/or had a
VLAN tag with the CFI bit set.
– 1 - The frame was SNAP encoded and had either no
VLAN tag or a VLAN tag with the CFI bit not set.
23:22 This bit has a different meaning depending on whether RX
checksum offloading is enabled.
• With RX checksum offloading disabled: (bit 24 clear in
Network Configuration)
Type ID register match. Encoded as follows:
– 00 - Type ID register 1 match
– 01 - Type ID register 2 match
– 10 - Type ID register 3 match
– 11 - Type ID register 4 match
If more than one Type ID is matched only one is indicated
with priority 4 down to 1.
• With RX checksum offloading enabled: (bit 24 set in
Network Configuration)
– 00 - Neither the IP header checksum nor the
TCP/UDP checksum was checked.
– 01 - The IP header checksum was checked and was
correct. Neither the TCP nor UDP checksum was
checked.
– 10 - Both the IP header and TCP checksum were
checked and were correct.
– 11 - Both the IP header and UDP checksum were
checked and were correct.
21 VLAN tag detected — type ID of 0x8100.
For packets incorporating the stacked VLAN processing
feature, this bit will be set if the second VLAN tag received
has a type ID of 0x8100.
20 Priority tag detected — type ID of 0x8100 and null VLAN
identifier.
For packets incorporating the stacked VLAN processing
feature, this bit will be set if the second VLAN tag received
has a type ID of 0x8100 and a null VLAN identifier.

<!-- page 19: manual page 69 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 69
Table 3-59. Receive Buffer Descriptor Entry (continued)
Bit Function
19:17 When bit 15 (End of frame) and bit 21 (VLAN tag) are set,
these bits represent the VLAN priority.
When header/data splitting is enabled (through bit 5 of the
DMA configuration register, offset 0x10) bit 17 indicates this
descriptor is pointing to the last buffer of the header.
16 This bit has a different meaning depending on the state of
bit 13 (report bad FCS in bit 16 of word 1 of the receive
buffer descriptor) and bit 5 (header/data splitting) of the DMA
Configuration register (offset 0x10).
When header/data splitting is enabled and this buffer
descriptor (BD) is not the last BD of the frame (as indicated in
bit 15 of this BD), this bit will indicate that the BD is pointing
to a data buffer containing header bytes.
When this BD is the last BD of the frame (as indicated in bit
15 of this BD), and bit 13 of the DMA configuration register is
set, this bit represents FCS/CRC error.
When this BD is the last BD of the frame (as indicated in bit
15 of this BD), and bit 13 of the DMA configuration register
is clear, and the received frame is VLAN tagged, this bit
represents the Canonical format indicator (CFI).
15 End of frame - when set, the buffer contains the end of a
frame.
If end of frame is not set, then the only valid status bit (unless
header/data splitting is enabled) is start of frame (bit 14). If
header/data splitting is enabled, then bits 16 and 17 are also
valid status bits when this bit is not set.
14 Start of frame - when set, the buffer contains the start of a
frame.
If both bits 15 and 14 are set, the buffer contains a whole
frame.
13 This bit has a different meaning depending on whether
jumbo frames and ignore FCS mode are enabled. If no mode
is enabled, this bit will be zero.
• With jumbo frame mode enabled: (bit 3 set in Network
Configuration Register)
Additional bit for length of frame (bit[13]), that is
concatenated with bits[12:0]
• With ignore FCS mode enabled and jumbo frames
disabled: (bit 26 set in Network Configuration Register
and bit 3 clear in Network Configuration Register)
This indicates per frame FCS status as follows:
– 0 – Frame had good FCS
– 1 – Frame had bad FCS, but was copied to memory
as ignore FCS enabled

<!-- page 20: manual page 70 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 70
Table 3-59. Receive Buffer Descriptor Entry (continued)
Bit Function
12:0 When header/data splitting enabled (through bit 5 of the
DMA configuration register, offset 0x10) and bit 17 is set
(last buffer of header), these bits represent the length of the
header in bytes.
When bit 15 (End of frame) is set, these bits represent the
length of the received frame which may or may not include
FCS depending on whether FCS discard mode is enabled.
• With FCS discard mode disabled: (bit 17 clear in Network
Configuration Register)
Least significant 12-bits for length of frame including
FCS. If jumbo frames are enabled, these 12-bits are
concatenated with bit[13] of the preceding descriptor.
• With FCS discard mode enabled: (bit 17 set in Network
Configuration Register)
Least significant 12-bits for length of frame excluding
FCS. If jumbo frames are enabled, these 12-bits are
concatenated with bit[13] of the preceding descriptor.
3.12.2.4.3. Register Interface (Ask a Question)
Control registers drive the MDIO interface, set up DMA activity, start frame transmission, and select
modes of operation such as Full-Duplex, Half-Duplex, and 10/100/1000 Mbps operation. The register
interface is through APB interface, which connects to the core complex subsystem.
The Statistics register block contains registers for counting various types of an event associated with
transmit and receive operations. These registers, along with the status words stored in the receive
buffer list, enable the software to generate Network Management Statistics registers.
3.12.2.4.4. AXI DMA  (Ask a Question)
The built-in DMA controller is attached to the MAC buffer memories to provide a scatter-gather type
capability for packet data storage.
DMA uses the AXI interface for data transfer and uses the APB interface for configuration and
monitoring DMA descriptors. DMA uses separate transmit and receive buffers as memories to store
the frames to be transmitted or received. It uses separate transmit and receive lists of buffer
descriptors, with each descriptor describing a buffer area in the memory. This allows the Ethernet
packets to be broken and scattered around the system memory.
TX DMA is responsible for the transmit operations and RX DMA is responsible for the receive
operations. TX DMA reads the data from memory, which is connected through the AXI interface and
stores data to the transmit packet buffers. RX DMA fetches the data from the receive packet buffers
and transfers it to the application memory.
Receive buffer depth is programmable within the range of 64 bytes to 16,320 bytes. The start
location for each receive buffer is stored in the memory in a list of receive buffer descriptors, at
an address location pointed by the receive buffer queue pointer. The base address for the receive
buffer queue pointer is configured using the DMA registers.
Transmit frames can be in the range of 14 bytes to 10,240 bytes long. As a result, it is possible to
transmit jumbo frames. The start location for each transmit buffer is stored in a list of transmit
buffer descriptors at a location pointed by the transmit buffer queue pointer. The base address for
this queue pointer is configured using the DMA registers.
Following are the features of DMA Controller:
• 64-bit data bus width support
• 64-bit address bus width support

<!-- page 21: manual page 71 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 71
• Support up to 16 outstanding AXI transactions. These transactions can cross multiple frame
transfers.
• Ability to store multiple frames in the packet buffer resulting in the maximum line rate
• Supports priority queuing
• Supports TCP/IP advanced offloads to reduce CPU overhead
AXI read operations are routed to the AXI read channel and all write operations to the
write channel. Both read and write channels may operate simultaneously. Arbitration logic is
implemented when multiple requests are active on the same channel. For example, when the
transmit and receive DMA request for data for transmission and reception of data at the same
time, the receive DMA is granted the bus before the transmit DMA. However, most requests are
either receive data writes or transmit data reads both of which can operate in parallel and can
execute simultaneously.
3.12.2.4.5. MAC Filter (Ask a Question)
The filter block determines which frames are written to the DMA interface. Filtering is performed
on received frames based on the state of the external matching pins, the contents of the specific
address, type and hash registers, and the frame’s destination address and the field type.
If bit [25] of the Network Configuration register is not set, a frame is not copied to memory if GEM is
transmitting in half-duplex mode at the time a destination address is received.
Ethernet frames are transmitted a byte at a time, least significant bit first. The first six bytes (48
bits) of an Ethernet frame make up the destination address. The first bit of the destination address,
which is the LSB of the first byte of the frame, is the group or individual bit. This is one for multicast
addresses and zero for unicast. The all ones address is the broadcast address and a special case of
multicast.
GEM supports the recognition of specific source or destination addresses. The number of specific
source or destination address filters is configurable and can range from zero to 36. Each specific
address filter requires two registers:
• Specific Address Register Bottom: Stores the first four bytes of the compared source or
destination address.
• Specific Address Register Top: Contains the last two bytes of this address, a control bit to select
between source or destination address filtering and a 6-bit byte mask field to allow the user to
mask bytes during the comparison.
The first filter (Filter 1) is slightly different from all other filters in that there is no byte mask. Instead
address comparison against individual bits of specific address register 1 can be masked using the
unique specific address mask register. The addresses stored in all filters can be specific (unicast),
group (multicast), local or universal.
GEM is configured to have four specific address filters. Each filter is configured to contain a MAC
address, which is specified to be compared against the Source Address (SA) or Destination Address
(DA) of each received frame. There is also a mask field to allow certain bytes of the address that are
not to be included in the comparison. If the filtering matches for a specific frame, then it is passed
on to the DMA memory. Otherwise, the frame is dropped.
The destination or source address of received frames is compared against the data stored in the
specific address registers once they have been activated. The addresses are deactivated at reset
or when their corresponding specific address register bottom is written. They are activated when
specific address register top is written. If a received frame address matches an active address, the
frame is written to the external FIFO interface and, if used, to the DMA interface.
Frames can be filtered using the type ID field for matching. Four type ID registers exist in the register
address space and each can be enabled for matching by writing a one to the MSB (bit [31]) of the
respective register. When a frame is received, the matching is implemented as an OR function of the
various types of match.

<!-- page 22: manual page 72 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 72
The contents of each type ID registers (when enabled) are compared against the length/type ID of
the frame being received (for example, bytes 13 and 14 in non-VLAN and non-SNAP encapsulated
frames) and are copied to memory if a match is found. The encoded type ID match bits (Word 0,
Bit 22 and Bit 23) in the receive buffer descriptor status are set, indicating which type ID register
generated the match, if the receive checksum offload is disabled. The reset state of the type ID
registers is zero; hence, each is initially disabled.
The following example illustrates the use of the address and type ID match registers for a MAC
address of 21:43:65:87:A9:CB.
Table 3-60. Address and Type ID Match Register (Example)
Field Value Checked
Preamble 55
SFD D5
DA (Octet 0 - LSB) 21
DA (Octet 1) 43
DA (Octet 2) 65
DA (Octet 3) 87
DA (Octet 4) A9
DA (Octet 5 - MSB) CB
SA (LSB) 001
SA 001
SA 001
SA 001
SA 001
SA (MSB) 0
Type ID (MSB) 43
Type ID (LSB) 21
Note:
1. Contains the address of the transmitting device.
The sequence in the preceding table shows the beginning of an Ethernet frame. Byte order of
transmission is from top to bottom, as shown. For a successful match to specific address 1, the
following address matching registers must be set up:
• Specific address 1 bottom (address 0x088): 0x87654321
• Specific address 1 top (address 0x08C): 0x0000CBA9
Broadcast Address (Ask a Question)
Frames with the broadcast address of 0xFFFFFFFFFFFF are stored to memory if the "no broadcast"
bit in the network configuration register is set to zero.
Hash Addressing  (Ask a Question)
The hash address register is 64-bit long and takes up two locations in the memory map. The least
significant bits are stored in hash register bottom and the most significant bits in hash register top.
The unicast hash enable and the multicast hash enable bits in the network configuration register
enable the reception of hash matched frames. The destination address is reduced to a 6-bit index
into the 6-bit hash register using the following hash function. The hash function is an XOR of every
sixth bit of the destination address.
hash_index[05] = da[05] ^ da[11] ^ da[17] ^ da[23] ^ da[29] ^ da[35] ^ da[41] ^ da[47]
hash_index[04] = da[04] ^ da[10] ^ da[16] ^ da[22] ^ da[28] ^ da[34] ^ da[40] ^ da[46]
hash_index[03] = da[03] ^ da[09] ^ da[15] ^ da[21] ^ da[27] ^ da[33] ^ da[39] ^ da[45]
hash_index[02] = da[02] ^ da[08] ^ da[14] ^ da[20] ^ da[26] ^ da[32] ^ da[38] ^ da[44]

<!-- page 23: manual page 73 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 73
hash_index[01] = da[01] ^ da[07] ^ da[13] ^ da[19] ^ da[25] ^ da[31] ^ da[37] ^ da[43]
hash_index[00] = da[00] ^ da[06] ^ da[12] ^ da[18] ^ da[24] ^ da[30] ^ da[36] ^ da[42]
da[0] represents the least significant bit of the first byte received, that is, the multicast/unicast
indicator, and da[47] represents the most significant bit of the last byte received.
If the hash index points to a bit that is set in the hash register, then the frame will be matched
according to whether the frame is multicast or unicast.
A multicast match is signaled if the multicast hash enable bit is set, da[0] is logic 1 and the hash
index points to a bit set in the hash register.
A unicast match is signaled if the unicast hash enable bit is set, da[0] is logic 0 and the hash index
points to a bit set in the hash register.
To receive all multicast frames, the hash register must be set with all ones and the multicast hash
enable bit must be set in the network configuration register.
Copy All Frames (or Promiscuous Mode) (Ask a Question)
If the "copy all frames" bit is set in the Network Configuration register, all frames (except those
that are too long, too short, have FCS errors or have rx_er asserted during reception) are copied to
memory. Frames with FCS errors are copied if bit [26] is set in the network configuration register.
Disable Copy of Pause Frames (Ask a Question)
Pause frames can be prevented from being written to memory by setting the disable copying of
pause frames control bit [23] in the Network Configuration register. When set, pause frames are not
copied to memory regardless of the "copy all frames" bit, whether a hash match is found, a type ID
match is identified, or a destination address match is found.
VLAN Support  (Ask a Question)
The following table shows an Ethernet encoded 802.1Q VLAN tag.
Table 3-61. VLAN Tag
TPID (Tag Protocol Identifier) 16 Bits TCI (Tag Control Information) 16 Bits
0x8100 First 3 bits priority, then CFI bit, last 12 bits VID
The VLAN tag is inserted at the 13th byte of the frame, adding an extra four bytes to the frame. To
support these extra four bytes, GEM can accept frame lengths up to 1536 bytes by setting bit [8] in
the Network Configuration register.
If the VID (VLAN identifier) is null (0x000), this indicates a priority-tagged frame.
The following bits in the receive buffer descriptor status word give information about VLAN tagged
frames:
• Bit [21] set if receive frame is VLAN tagged (type ID of 0x8100).
• Bit [20] set if receive frame is priority tagged (type ID of 0x8100 and null VID). (If bit [20] is set bit
[21] is also set).
• Bit [19], [18] and [17] set to priority if bit [21] is set.
• Bit [16] set to CFI if bit [21] is set.
GEM can be configured to reject all frames except VLAN tagged frames by setting the discard
non-VLAN frames bit in the Network Configuration register.
3.12.2.4.6. Time Stamping Unit  (Ask a Question)
TSU implements a timer, which counts the time in seconds and nanoseconds format. This block is
supplied with tsu_clk, which ranges from 5 MHz to 400 MHz. The timer is implemented as a 94-bit
register as follows.
• The upper 48 bits counts seconds

<!-- page 24: manual page 74 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 74
• The next 30 bits counts nanoseconds
• The lower 16 bits counts sub nanoseconds
Note: sub nanoseconds is a time-interval measurement unit which is shorter than nanoseconds.
The timer increments at each tsu_clk period and an interrupt is generated in the seconds
increment. The timer value can be read, written, and adjusted through the APB interface.
There are two modes of operation:
• Timer Adjust Mode
• Increment Mode
Timer Adjust Mode  (Ask a Question)
In Timer Adjust mode, the tsu_clk is supplied from the FPGA fabric. The maximum clock frequency is
125 MHz. There are several signals, synchronous to tsu_clk output by the MAC.
In this mode, the timer operation is also controlled from the fabric by input signals called
gem_tsu_inc_ctrl [1:0] along with gem_tsu_ms.
When the gem_tsu_inc_ctrl [1:0] is set to:
• 2b’11 – Timer register increments as normal
• 2b’01 – Timer register increments by an additional nanosecond
• 2b’10 – Timer increments by a nanosecond less
• 2b’00:
– When the gem_tsu_ms is set to: logic 1, the nanoseconds timer register is cleared and the
seconds timer register is incremented with each clock cycle.
– When the gem_tsu_ms is set to: logic 0, the timer register increments as normal, but the
timer value is copied to the Sync Strobe register.
The TSU timer count value can be compared to a programmable comparison value. For the
comparison, the 48 bits of the seconds value and the upper 22 bits of the nanoseconds value are
used. The timer_cmp_val signal is output from the core to indicate when the TSU timer value is equal
to the comparison value stored in the timer comparison value registers.
The following diagram shows TSU from fabric in Timer Adjust mode.

<!-- page 25: manual page 75 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 75
Figure 3-22. TSU from Fabric (Timer Adjust Mode)
Gigabit Ethernet MAC (GEM_0)
GEM_0_TSU_CLK_F2M
GEM_0_TSU_GEM_INC_CTRL_F2M[1:0]
GEM_0_TSU_GEM_MS_F2M
GEM_0_TSU_TIMER_CMP_VAL_M2F
GEM_0_TSU_TIMER_CNT_M2F[93:0]
Gigabit Ethernet MAC (GEM_1)
MSS
FPGA Fabric
PLLPLL
tsu_clk
(125 MHz max)
GEM_1_TSU_CLK_F2M
GEM_1_TSU_GEM_INC_CTRL_F2M[1:0]
GEM_1_TSU_GEM_MS_F2M
GEM_1_TSU_TIMER_CMP_VAL_M2F
GEM_1_TSU_TIMER_CNT_M2F[93:0]
tsu_clk
(125 MHz max)
Increment Mode (Ask a Question)
In the Increment mode, the tsu_clk is supplied either from an external reference clock or from the
FPGA fabric. The maximum clock frequency is 400 MHz. In this mode, the timer signals interfacing
the FPGA fabric are gated off.
The following diagram shows the TSU from MSS in Increment Mode.

<!-- page 26: manual page 76 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 76
Figure 3-23. TSU from MSS (Increment Mode)
Gigabit Ethernet MAC (GEM 0) Gigabit Ethernet MAC (GEM 1)
MSS
FPGA Fabric
PLLPLL
tsu_clk
(400 MHz max)
tsu_clk
(400 MHz max)
3.12.2.4.7. IEEE 1588 Implementation (Ask a Question)
IEEE 1588 is a standard for precision time synchronization in local area networks. It works with the
exchange of special PTP frames. The PTP messages can be transported over IEEE 802.3/Ethernet,
over Internet Protocol Version 4 (IPv4) or over Internet Protocol Version 6 (IPv6). GEM detects when
the PTP event messages: sync, delay_req, pdelay_req, and pdelay_resp are transmitted and received.
GEM asserts various strobe signals for different PTP event messages.
GEM supports the following functionalities:
• Identifying PTP frames
• Extracting timestamp information out of received PTP frames
• Inserting timestamp information into received data frames, before passing to buffer memory
• Inserting timestamp information into transmitted data frames
• Allowing control of TSU either through MSS or FPGA fabric
GEM samples the TSU timer value when the TX or RX SOF event of the frame passes the MII/GMII
boundary. This event is an existing signal synchronous to MAC TX/RX clock domains. The MAC uses
the sampled timestamp to insert the timestamp into transmitted PTP sync frames (if one step sync
feature is enabled) or to pass to the register block to capture the timestamp in APB accessible
registers, or to pass to the DMA to insert into TX or RX descriptors. For each of these, the SOF
event, which is captured in the tx_clk and rx_clk domains respectively, is synchronized to the tsu_clk
domain and the resulting signal is used to sample the TSU count value.
There is a difference between IEEE 802.1 AS and IEEE 1588. The difference is, IEEE 802.1AS uses
the Ethernet multi-cast address 0180C200000E for sync frame recognition whereas IEEE 1588 does
not. GEM is designed to recognize sync frames with both 802.1AS and 1588 addresses and so can
support both 1588 and 802.1AS frame recognition simultaneously.
PTP Strobes  (Ask a Question)
There are a number of strobe signals from the GEM to the FPGA fabric. These signals indicate the
transmission/reception of various PTP frames. The following table lists these signals.

<!-- page 27: manual page 77 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 77
Table 3-62. PTP Strobe Signals
Signal Name Description
DELAY_REQ_RX Asserted when the PTP RX delay request is detected.
DELAY_REQ_TX Asserted when the PTP TX delay request is detected.
PDELAY_REQ_RX Asserted when the PTP PDELAY RX request is detected.
PDELAY_REQ_TX Asserted when the PTP PDELAY TX request is detected.
PDELAY_RESP_RX Asserted when the PTP PDELAY RX response request is detected.
PDELAY_RESP_TX Asserted when the PTP PDELAY TX response request is detected.
SOF_RX Asserted on SFD, de-asserted at EOF.
SOF_TX Asserted on SFD, de-asserted at EOF.
SYNC_FRAME_RX Asserted when the SYNC_FRAME RX response request is detected.
SYNC_FRAME_TX Asserted when the SYNC_FRAME TX response request is detected.
PTP Strobe Usage (GMII) (Ask a Question)
When GEM is configured in the GMII/MII mode, transmit PTP strobes are synchronous to mac_tx_clk
and receive PTP strobes are synchronous to mac_rx_clk. GEM sources these clocks from the fabric.
PTP Strobe Usage (SGMII) (Ask a Question)
When GEM is configured in the SGMII mode, the PTP strobes must be considered asynchronous
because the Tx and Rx clocks are not available in the FPGA fabric. Hence, the strobe signals must be
synchronized with a local clock in the fabric before being used.
3.12.2.4.8. Time Sensitive Networking  (Ask a Question)
GEM includes the following key TSN functionalities among others:
• IEEE 802.1 Qav Support – Credit based Shaping
• IEEE 802.1 Qbv – Enhancement for Scheduled Traffic
• IEEE 802.1 CB Support
• IEEE 802.1 Qci Receive Traffic Policing
• IEEE 802.3br Support
IEEE 802.1 Qav Support – Credit based Shaping (Ask a Question)
A credit-based shaping algorithm is available on the two highest priority active queues and is
defined in IEEE 802.1Qav Forwarding and Queuing Enhancements for Time-Sensitive Streams. Traffic
shaping is enabled through the register configuration. Queuing can be handled using any of the
following methods.
• Fixed priority
• Deficit Weighted Round Robin (DWRR)
• Enhanced transmission selection
Selection of the queuing method is done through register configuration. The internal registers of the
GEM are described in Register Address Map.
IEEE 802.1 Qbv – Enhancement for Scheduled Traffic (Ask a Question)
IEEE 802.1 Qbv is a TSN standard for enhancement for scheduled traffic and specifies time aware
queue-draining procedures based on the timing derived from IEEE 802.1 AS. It adds transmission
gates to the eight priority queues, which allow low priority queues to be shut down at specific times
to allow higher priority queues immediate access to the network at specific times.
GEM supports IEEE 802.1Qbv by allowing time-aware control of individual transmit queues. GEM has
the ability to enable and disable transmission on a particular queue on a periodic basis with the ON
or OFF cycling, starting at a specified TSU clock time.

<!-- page 28: manual page 78 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 78
IEEE 802.1 CB Support  (Ask a Question)
IEEE 802.1CB “Frame Replication and Elimination for Reliability” is one of the Time Sensitive
Networking (TSN) standards. Using Frame Replication and Elimination for Reliability (FRER) within
a network increases the probability that a given packet is delivered using multi-path paths through
the network.
The MAC supports a subset of this standard and provides the capability for stream identification and
frame elimination but does not provide support for the replication of frames.
IEEE 802.1 Qci Receive Traffic Policing  (Ask a Question)
IEEE 802.11 Qci is a policy mechanism that discards frames in receive (ingress) if they exceed their
allocated frame length or flow rate. TSN standards enable provisioning the resources in a network in
such a way that high priority traffic is ensured to get through as long as it does not exceed its frame
length and flow rate allocation.
IEEE 802.3br Support  (Ask a Question)
All default operations of MAC are done by using PMAC. One more MAC, which is identical to PMAC
is used, termed as EMAC, which is used when IEEE 802.3br is configured. IEEE 802.3br Interspersing
Express Traffic is one of the TSN standards, which defines a mechanism to allow an express frame
to be transmitted with minimum delay at the expense of delaying completion of normal priority
frames.
This standard has been implemented by instantiating two separate MAC modules with related DMA,
a MAC Merge Sub Layer (MMSL) and an AXI arbiter. One MAC is termed the express or eMAC and
the other is a pre-emptable or pMAC. The eMAC is designed to carry time sensitive traffic, which
must be delivered within a known time.
Figure 3-24. IEEE 802.3br Support
3.12.2.4.9. PHY Interface (Ask a Question)
GEM can be configured to support the SGMII or the GMII/MII PHY. When using SGMII, the PCS block
of that GEM is used.

<!-- page 29: manual page 79 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 79
Physical Coding Sublayer (Ask a Question)
A PCS is incorporated for 1000BASE-X operation which includes 8b/10b encoder, decoder, and the
Auto Negotiation module. This interface is connected to I/O BANK 5.
GMII / MII Interface (Ask a Question)
A GMII/MII is interfaced between each MAC and the FPGA fabric, to provide flexibility to the user. It
allows the following:
• Perform customized manipulation of data on-the-fly
• 8-bit parallel data lines are used for data transfer.
• In 10/100 Mbps mode txd[3:0] is used, txd[7:4] tied to Logic 0 while transmission. rxd[3:0] is used,
rxd[7:4] is tied to Logic 0 during reception of data.
• In 1000 Mbps mode, all txd[7:0] and rxd[7:0] bits are used.
SGMII  (Ask a Question)
GEM includes the SGMII functional block, which provides the SGMII interface between GEM and
Ethernet PHY. The SGMII block provides the following functionalities:
• Clock Domain Recovery (CDR) of received 125 MHz clock
• Serializing or De-serializing
• PLL for synthesis of a 125 MHz transmit clock
The SGMII block routes the data to the PHY through the dedicated I/O BANK 5.
PHY Management Interface (Ask a Question)
GEM includes an MDIO interface, which can be routed through the MSSIO or the FPGA I/Os. The
MDIO interface is provided to allow GEM to access the PHY’s management registers. This interface
is controlled by the PHY management register. Writing to this register causes a PHY management
frame to be sent to the PHY over the MDIO interface. PHY management frames are used to either
write or read from PHY’s control and STATUS registers.
If desired, however, the user can just bring out one management interface (and not use the second)
as it is possible to control multiple PHYs through one interface. Management Data Clock (MDC) must
not toggle faster than 2.5 MHz (minimum period of 400 ns), as defined by the IEEE 802.3 standard.
MDC is generated by dividing processor clock (pclk). A register configuration determines by how
much pclk must be divided to produce MDC.
3.12.2.5. Register Address Map (Ask a Question)
GEM is configured using the following internal registers.
Table 3-63. Register Address Map
Address Offset (Hex) Register Type Width
MAC Registers or Pre-emptable MAC Registers
0x0000 Control and STATUS 32
0x0100 Statistics 32
0x01BC Time Stamp Unit 32
0x0200 Physical Coding Sublayer 32
0x0260 Miscellaneous 32
0x0300 Extended Filter 32
0x0400 Priority Queue and Screening 32
0x0800 Time Sensitive Networking 32
0x0F00 MAC Merge Sublayer 32
eMAC Registers
0x1000 to 0x1FFF eMAC 32
For more information about registers, see PolarFire SoC Device Register Map.

<!-- page 30: manual page 80 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 80
3.12.3. CAN Controller (Ask a Question)
PolarFire SoC FPGAs contain an integrated control area network (CAN) peripheral. It is an APB slave
on the MSS AMBA interconnect. A master such as the MSS Core Complex or a master in the FPGA
fabric configures the CAN controller through the APB slave interface.
The CAN controller in the PolarFire SoC FPGAs supports the concept of mailboxes and contains
32 receive buffers. Each buffer has its own message filter and 32 transmit buffers with prioritized
arbitration scheme. For optimal support of HLP such as DeviceNet, the message filter also covers
the first two data bytes of the message payload. A block diagram of the CAN controller is shown
in Figure 3-25. Transmit and receive message buffers are SECDED through the error detection and
correction (EDAC) controller.
To remove the requirement of APB clock in multiples of 8 MHz, a separate MSS CAN clock is
provided and a clock domain crossing (CDC) logic is added from the APB bus. The CDC logic uses
toggle synchronizers and there is no restriction on the APB clock relative to the CAN clock.
The CAN clock is dervied from MSS PLL output. The MSS CAN clock frequency is based on the MSS
PLL clock frequency. The supported frequencies in MHz are 8, 16, 24, 32, 40, 48, 56, 64, 72, and 80.
Figure 3-25. CAN Controller Block Diagram
CAN Framer
Interrupt
Controller
Status and
Configuration
Control and
Command
Receive
Message
Handler
Transmit
Message
Handler
APB Slave
Interface
Memory Arbiter
EDAC
RAM I/F
CDCExternal
Transceiver
Chip
APB Bus
TX_EN_N
TX
RX
3.12.3.1. Features (Ask a Question)
CAN controller supports the following features:
Compliance
• Full CAN 2.0B compliant
• Conforms to ISO 11898-1

<!-- page 31: manual page 81 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 81
• Maximum baud rate of 1 Mbps with 8 MHz CAN clock
APB
• APB 3.0 compliant
• APB interface has clock-domain-crossing to CAN logic, allowing APB to operate at any frequency.
Receive Path
• 32 receive (Rx) buffers
• Each buffer has its own message filter
• Message filter covers: ID, IDE, remote transmission request (RTR), data byte 1, and data byte 2
• Message buffers can be linked together to build a bigger message array
• Automatic RTR response handler with optional generation of RTR interrupt
Transmit Path
• 32 transmit (Tx) message holding registers with programmable priority arbitration
• Message abort command
• Single-shot transmission (SST); no automatic retransmission upon error or arbitration loss
System Bus Interface
• AMBA 3 APB Interface
• Full synchronous zero wait-states interface
• Status and configuration interface
Programmable Interrupt Controller
• Local interrupt controller covering message and CAN error sources
Test and Debugging Support
• Listen Only mode
• Internal Loopback mode
• External Loopback mode
• SRAM Test mode
• Error Capture register
• Provides option to either: show current bit position within CAN message
• Provides option to either: show bit position and type of last captured CAN error
SRAM Based Message Buffers
• Optimized for low gate-count implementation
• Single port, synchronous memory based
• 100% synchronous design
3.12.3.1.1. EDAC (Ask a Question)
An internal 256 x 32 RAM in the CAN controller is protected with EDAC. EDAC configurations and
error counters related to the CAN are maintained in MSS system registers. For more information
about CAN EDAC registers, see PolarFire SoC Device Register Map.
After power-up, the internal SRAM is not initialized and any READ to the memory location results in
an ECC error if EDAC is enabled. To initialize the SRAM, you can put the CAN controller into SRAM
Test mode, initialize the SRAM, and enable the EDAC. If SECDED is enabled, it is recommended that
the CAN controller must be put into SRAM Test mode and the RAM initialized with user defined

<!-- page 32: manual page 82 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 82
known data before operation so that a future read or an uninitialized address does not trigger a
SECDED error.
3.12.3.1.2. Reset (Ask a Question)
The CAN controller resets on power-up and is held in Reset until enabled in the SOFT_RESET_CR
register. The CAN controller can be Reset by writing to CAN0 or CAN1 of the SOFT_RESET_CR
register. The SOFT_RESET_CR register is located in the pfsoc_mss_top_sysreg block.
3.12.3.2. Functional Description  (Ask a Question)
3.12.3.2.1. CAN Controller Interface Signals (Ask a Question)
The external interface signals connecting the PolarFire SoC FPGA to an off-chip CAN transceiver are
listed in the following table.
Table 3-64. CAN BUS Interface
Signal Name Direction Description
canclk Input CAN Clock.
RX Input CAN bus receive signal. This signal connects to the receiver bus of the external transceiver.
TX Output CAN bus transmit signal. This signal connects to the external transceiver.
TX_EN_N Output External driver enable control signal.
This signal is used to enable or disable an external CAN transceiver.
TX_EN_N is asserted when the CAN controller is stopped or if the CAN state is bus-off (shut
down completely). The CAN transmit enable TX_EN_N signal provided through the I/O MUX to
the I/O pads are active-low and the CAN transmit enable provided to the fabric is active-high.
When enabled, CAN ports are configured to connect to multi-standard I/Os (MSIOs) by default.
CAN signals can also be configured to interface with the FPGA fabric and the MSS general purpose
inputs/outputs (GPIOs).
Note: The MSIOs allocated to the CAN instance are shared with other MSS peripherals. These
shared I/Os are available to connect to the MSS GPIOs and other peripherals when the CAN instance
is disabled or if the CAN instance ports are only connected to the FPGA fabric.
3.12.3.2.2. Transmit Procedures (Ask a Question)
The CAN controller provides 32 transmit message holding buffers. An internal priority arbiter selects
the message according to the chosen arbitration scheme. Upon transmission of a message or
message arbitration loss, the priority arbiter re-evaluates the message priority of the next message.
The following figure gives an overall view of the transmit message buffers.

<!-- page 33: manual page 83 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 83
Figure 3-26. Transmit Message Buffers
CDC
RX
TxReq
TxReq
TxReq
TxReq
TX
TX_EN_N
APB BusExternal
Transceiver
Chip
CAN Framer
TxMessage0
TxMessage1
TxMessage2
TxMessage31
Priority
Arbiter
APB Slave
Interface
Two types of message priority arbitration are supported. The type of arbitration is selected using the
CAN_CONFIG configuration register. Following are the arbitration types:
• Round Robin: Buffers are served in a defined order: 0-1-2... 31-0-1... A particular buffer is
only selected if its TxReq flag is set. This scheme guarantees that all buffers receive the same
probability to send a message.
• Fixed Priority: Buffer 0 has the highest priority. This way it is possible to designate buffer 0 as the
buffer for error messages and it is guaranteed that they are sent first.
Note: RTR message requests are served before transmit message buffers are handled. For
example, RTRreq0, RTRreq31, TxMessage0, TxMessage1, and TxMessage31.
Procedure for Sending a Message (Ask a Question)
1. Write message into an empty transmit message holding buffer. An empty buffer is indicated by
the TxReq (Bit 0 of TX_MSG#_CTRL_CMD register) that is equal to zero.
2. Request transmission by setting the respective TxReq flag to 1.
3. The TxReq flag remains set as long as the message transmit request is pending. The content of
the message buffer must not be changed while the TxReq flag is set.
4. The internal message priority arbiter selects the message according to the chosen arbitration
scheme.
5. Once the message is transmitted, the TxReq flag is set to zero and the TX_MSG (Bit 11 of the
INT_STATUS register) interrupt status bit is asserted.
Remove a Message from a Transmit Holding Register (Ask a Question)
A message can be removed from the transmit holding buffer by asserting the TxAbort (Bit 1 if
TX_MSG#_CTRL_CMD register) flag. The content of a particular transmit message buffer can be
removed by setting TxAbort to 1 to request message removal. This flag remains set as long as the
message abort request is pending. It is cleared when either the message wins arbitration (TX_MSG
interrupt active) or the message is removed (TX_MSG interrupt inactive).

<!-- page 34: manual page 84 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 84
Single-Shot Transmission (Ask a Question)
Single-shot transmission (SST) mode is used in systems where the re-transmission of a CAN
message due to an arbitration loss or a bus error must be prevented. An SST request is set by
asserting TxReq and TxAbort at the same time. Upon a successful message transmission, both flags
are cleared.
If an arbitration loss or if a bus error happens during the transmission, the TxReq and TxAbort flags
are cleared when the message is removed or when the message wins arbitration. At the same time,
the SST_FAILURE interrupt is asserted.
3.12.3.2.3. Receive Procedures (Ask a Question)
The CAN controller provides 32 individual receive message buffers. Each one has its own message
filter mask. Automatic reply to RTR messages is supported. If a message is accepted in a receive
buffer, its MsgAv flag is set. The message remains valid as long as MsgAv flag is set. The master
CPU has to reset the MsgAv flag to enable receipt of a new message. The following figure shows the
overall block diagram of the receive message buffers.
Figure 3-27. Receive Message Buffers
RxMessage0
RxMessage1
RxMessage2
RxMessage31
External
Transceiver
Chip
CAN
Framer
Receive Message
Handler
RX
TX
TX_EN_N
Received Message Processing (Ask a Question)
After a new message is received, the receive message handler searches all receive buffers, starting
from the receive message0 until it finds a valid buffer. A valid buffer is indicated by:
• Receive buffer is enabled (indicated by RxBufferEbl = 1)
• Acceptance filter of receive buffer matches incoming message
If the receive message handler finds a valid buffer that is empty, then the message is stored and the
MsgAv flag of this buffer is set to 1. If the RxIntEbl flag is set, then the RX_MSG flag of the interrupt
controller is asserted.
If the receive buffer already contains a message indicated by MsgAv = 1 and the link flag is not set,
then the RX_MSG_LOSS interrupt flag is asserted. Refer to Receive Buffer Linking.
If an incoming message has its RTR flag set and the RTR reply flag of the matching buffer is set, then
the message is not stored but an RTR auto-reply request is issued. Refer to RTR Auto-Reply and the
RX_MSG0_CTRL_CMD register for more details.

<!-- page 35: manual page 85 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 85
Note: In case of an Extended frame, the received message ID is stored in [31:3] bits of RX ID
(RX_MSGn_ID) register. In case of a Standard frame, the message ID is stored in [31:21] bits of RX
ID (RX_MSGn_ID) register. Both message identifier (Standard frame and Extended frame) is stored at
different bit position of RX ID (RX_MSGn_ID) register.
Acceptance Filter (Ask a Question)
Each receive buffer has its own acceptance filter that is used to filter incoming messages. An
acceptance filter consists of acceptance mask register (AMR) and acceptance code register (ACR)
pair. The AMR defines which bits of the incoming CAN message match the corresponding ACR bits.
The following message fields are covered:
• ID
• IDE
• RTR
• Data byte 1 and data byte 2
Note: Some CAN HLPs such as Smart Distributed System (SDS) or DeviceNet carry additional
protocol related information in the first or first and second data bytes that are used for message
acceptance and selection. Having the capability to filter these fields provides a more efficient
implementation of the protocol stack running on the processor.
The AMR register defines whether the incoming bit is checked against the ACR register. The
incoming bit is checked against the respective ACR when the AMR register is 0. The message is
not accepted when the incoming bit does not match the respective ACR flag. When the AMR register
is 1, the incoming bit is a “don't care”.
RTR Auto-Reply (Ask a Question)
The CAN controller supports automatic answering of RTR message requests. All 32 receive buffers
support this feature. If an RTR message is accepted in a receive buffer where the RTRreply flag is
set, then this buffer automatically replies to this message with the content of this receive buffer.
The RTRreply pending flag is set when the RTR message request is received. It is cleared when the
message is sent or when the message buffer is disabled. To abort a pending RTRreply message, use
the RTRabort command.
If the RTR auto-reply option is selected, the RTR sent (RTRS) flag is asserted when the RTR auto-reply
message is successfully sent. It is cleared by writing “1” to it.
An RTR message interrupt is generated, if the MsgAv_RTRS flag and RxIntEbl are set. This interrupt is
cleared by clearing the RTRS flag.
Receive Buffer Linking  (Ask a Question)
Several receive buffers can be linked together to form a receive buffer array which acts almost like a
receive FIFO. For a set of receive buffers to be linked together, the following conditions must be met:
• All buffers of the same array must have the same message filter setting (AMR and ACR are
identical).
• The last buffer of an array may not have its link flag set.
When a receive buffer already contains a message (MsgAv = 1) and a new message arrives for
this buffer, this message is discarded (RX_MSG_LOSS Interrupt). To avoid this situation, several
receive buffers can be linked together. When the CAN controller receives a new message, the
receive message handler searches for a valid receive buffer. If one is found that is already full
(MsgAv = 1) and the link flag is set (LF = 1); the search for a valid receive buffer continues. If no
other buffer is found, the RX_MSG_LOSS interrupt is set and the message is discarded.
It is possible to build several message arrays. Each of these arrays must use the same AMR and
ACR.
Note:
The receive buffer locations do not need to be contiguous.

<!-- page 36: manual page 86 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 86
3.12.3.3. Register Map (Ask a Question)
For information about CAN Controller register map, see PolarFire SoC Device Register Map.
3.12.4. eNVM Controller (Ask a Question)
PolarFire SoC FPGA devices include one embedded non-volatile memory (eNVM) block size of
128 KB. The eNVM controller interfaces the eNVM block to the AMBA interconnect.
3.12.4.1. Features (Ask a Question)
eNVM supports the following features:
• SECDED protected
• High Data Retention Time
• 32-bit data input and 64-bit data output
3.12.4.2. Functional Description  (Ask a Question)
The eNVM controller implements a AHB interface to the eNVM R and C interfaces. The C-Bus (32-bit)
is used for programming operations and the R-Bus (64-bit) for read operations.
The eNVM controller operates at the AHB clock, and generates a slower clock for the eNVM whose
maximum clock rate is 26.3 MHz. This is achieved by creating a clock pulse that is multiple of the
master clock that supports an NVM access time of up to 80 ns.
To minimize clock synchronization latency, the AHB controller only generates an eNVM clock when
it needs access or the eNVM requests a clock. This allows the AHB controller to send the address to
the eNVM as soon as it is ready as it can restart the clock at any AHB clock cycle.
3.12.4.2.1. Data Retention Time  (Ask a Question)
The following table shows the retention time of the eNVM with respect to the junction temperature.
Table 3-65. Data Retention Time
Junction Temperature Data Retention Write Cycles
110 °C 10 years 10000
125 °C 4 years 1000
3.12.4.2.2. eNVM Access Time Speed  (Ask a Question)
See the Embedded NVM (eNVM) Characteristics section from PolarFire SoC FPGA Datasheet for
eNVM Maximum Read Frequency and eNVM Page Programming Time.
3.12.4.2.3. R-Bus Access  (Ask a Question)
The AHB controller interfaces the 32-bit AHB bus to the 64-bit R (Read) interface on the eNVM. The
controller always reads 64-bits from the eNVM and stores the data in case there is a subsequent
read requests data from the same 64-bit location.
When an AHB read request is made, the controller checks whether the data for the requested
address is held in the buffer and returns the data.
3.12.4.2.4. C-Bus Access  (Ask a Question)
The AHB controller simply maps the AHB read/write operations directly to the C-Bus signals. The
controller stalls write operations until the eNVM indicates that it is ready (c_grant asserted) and
then asserts HREADY, this releases the MSS Core Complex Processor while the eNVM completes any
required operations. If a second operation is requested, it is stalled until the eNVM re-asserts the
c_grant signal.
3.12.4.2.5. eNVM Address and Segments (Ask a Question)
The eNVM consists of four segments mapped into a contiguous 128 KB address space as listed in
Table 3-66. The C-Bus provides eNVM configuration, read/write capability. The R-Bus allows reading
of the eNVM over AHB. For more information about the C-Bus configuration registers, see PolarFire
SoC Device Register Map.

<!-- page 37: manual page 87 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 87
Table 3-66. eNVM Segments and Addresses
Bus Size Access Offset Description Address
C-Bus 512 Bytes RW 0x00000000 Configuration 0x20200000
R-Bus 128 K Bytes 8K RO 0x00000000 Sector 2 0x20220000
56K RO 0x00002000 Sector 0 0x20222000
56K RO 0x00010000 Sector 1 0x20230000
8K RO 0x0001E000 Sector 3 0x2023E000
3.12.4.2.6. eNVM Access Capabilities  (Ask a Question)
The eNVM is an optional boot ROM for the MSS. For the MSS boot process, eNVM is used to store
a baremetal application or a Zero Stage Boot Loader (ZSBL). The eNVM programming is executed
during the device programming through JTAG. The eNVM read access is available to the System
Controller to support MSS boot. The MSS CPU Core Complex can read eNVM through the R-Bus.
However, CPU Core Complex eNVM write is not supported.
For more information about how the eNVM is used for booting MSS, see Boot Modes Fundamentals
page.
3.12.4.3. Register Map (Ask a Question)
For information about eNVM register map, see PolarFire SoC Device Register Map.
3.12.5. Quad SPI with XIP  (Ask a Question)
Quad Serial Peripheral Interface (QSPI) is a synchronous serial data protocol that enables the
microprocessor and peripheral devices to communicate with each other. The QSPI controller is an
AHB slave in the PolarFire SoC FPGA that provides a serial interface compliant with the Motorola
SPI format. QSPI with execute in place (XIP) support allows a processor to directly boot rather than
moving the SPI content to SRAM before execution.
3.12.5.1. Features (Ask a Question)
Quad SPI supports the following features:
• Master only operation with SPI data-rate
– Programmable SPI clock—HCLK/2, HCLK/4, or HCLK/6
– Maximum data-rate is HCLK/2
• FIFOs
– Transmit and Receive FIFO
– 16-byte transmit FIFO depth
– 32-byte receive FIFO depth
– AHB interface transfers up to four bytes at a time
• SPI Protocol
– Master operation
– Motorola SPI supported
– Slave Select operation in idle cycles configurable
– Extended SPI operation (1, 2, and 4-bit)
– QSPI operation (4-bit operation)
– BSPI operation (2-bit operation)
– Execute in place (XIP)
– Three or four-byte SPI address.
• Frame Size

<!-- page 38: manual page 88 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 88
– 8-bit frames directly
– Back-to-back frame operation supports greater than 8-bit frames
– Up to 4 GB Transfer (2 × 32 bytes)
• Processor overhead reduction
– SPI Flash command/data packets with automatic data generation and discard function
• Direct Mode
– Allows a CPU to directly control the SPI interface pins.
3.12.5.2. Functional Description  (Ask a Question)
The QSPI controller supports only Master mode operation. The Master mode operation runs directly
off the controller clock (HCLK) and supports SPI transfer rates at the HCLK/2 frequency and slower.
The SPI peripherals consist mainly of the following components.
• Transmit and receive FIFOs
• Configuration and control logic
Figure 3-28. QSPI Controller Block Diagram
AHB
Interface
Transmit
FIFO
16 Byte
Receive
FIFO
32 Byte
Frame
Counter
TX/RX Logic
Configuration
and
Control Logic
XIP Mode Enable
SPI
Interface
3.12.5.2.1. Transmit and Receive FIFOs (Ask a Question)
The QSPI controller embeds two FIFOs for receive and transmit, as shown in Figure 3-28 . These
FIFOs are accessible through ReceiveData and TransmitData registers. Writing to the TransmitData
register causes the data to be written to the transmit FIFO. This is emptied by the transmit logic.
Similarly, reading from the ReceiveData register causes the data to be read from the receive FIFO.
3.12.5.2.2. Configuration and Control Logic (Ask a Question)
The SPI peripheral is configured for master-only operation. The type of data transfer protocol can
be configured by using the QSPIMODE0 and QSPIMODE21 bits of the CONTROL register. The control
logic monitors the number of data frames to be sent or received and enables the XIP mode when
the data frame transmission or reception is completed. During data frames transmission/reception,
if a transmit under-run error or receive overflow error is detected, the STATUS Register is updated.
3.12.5.3. XIP Operation (Ask a Question)
Execute in place (XIP) allows a processor to directly boot from the QSPI device rather than moving
the SPI content to SRAM before execution. A system Configuration bit (XIP bit in CONTROL register)
is used to set the controller in XIP mode.

<!-- page 39: manual page 89 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 89
When QSPI is in XIP mode, all AHB reads simply return the 32-bit data value associated with the
requested address. Each access to the QSPI device requires a 3-byte or 4-byte address transfers, a
3-byte IDLE period and 4-byte data transfer. Assuming the SPI clock is ¼ of the AHB clock, then this
requires approximately 80 clock cycles per 32-bit read cycle. In XIP mode, data is returned directly to
the AHB bus in response to an AHB read, data is not read from the FIFO’s. The QSPI device stays in
XIP mode as long as the Xb bit is zero.
In XIP mode, AHB write cycles access the core registers allowing the values to change, although the
registers cannot be read when in XIP mode.
In the application, the XIP mode is not enabled at Reset as the CPUs are initially booted by system
controller and the boot code can initialize the normal QSPI configuration registers.
To exit XIP mode, the firmware must clear the XIP bit in the CONTROL register, at this time it should
not be executing from the QSPI device. When this bit is written to zero, the QSPI core returns to
Normal mode and the reads access the core registers.
3.12.5.4. Register Map (Ask a Question)
When in XIP mode, only writes can be performed to the registers, read operations return to the SPI
contents. For information about QSPI XIP register map, see PolarFire SoC Device Register Map.
3.12.6. MMUART (Ask a Question)
Multi-mode universal asynchronous/synchronous receiver/transmitter (MMUART) performs serial-
to-parallel conversion on data originating from modems or other serial devices, and performs
parallel-to-serial conversion on data from the MSS Core Complex processor or fabric master to
these devices. PolarFire SoC FPGAs contain five identical MMUART peripherals in the microprocessor
subsystem (MMUART_0, MMUART_1, MMUART_2, MMUART_3, and MMUART_4).
3.12.6.1. Features (Ask a Question)
MMUART supports the following features:
• Asynchronous and synchronous operations
• Full programmable serial interface characteristics
– Data width is programmable to 5, 6, 7, or 8 bits
– Even, odd, or no-parity bit generation/detection
– 1, 1½, and 2 stop bit generation
• 9-bit address flag capability used for multi-drop addressing topologies
• Separate transmit (Tx) and receive (Rx) FIFOs to reduce processor interrupt service loading
• Single-wire Half-Duplex mode in which Tx pad can be used for bidirectional data transfer
• Local Interconnect Network (LIN) header detection and auto-baud rate calculation
• Communication with ISO 7816 smart cards
• Fractional baud rate capability
• Return to Zero Inverted (RZI) mod/demod blocks that allow infrared data association (IrDA) and
serial infrared (SIR) communications
• The MSb or the LSb is the first bit while sending or receiving data
3.12.6.2. Functional Description  (Ask a Question)
The functional block diagram of MMUART is shown in Figure 3-29. The main components of
MMUART include Transmit and Receive FIFOs (TX FIFO and RX FIFO), Baud Rate Generator (BRG),
input filters, LIN Header Detection and Auto Baud Rate Calculation block, RZI modulator and
demodulator, and interrupt controller.
While transmitting data, the parallel data is written to TX FIFO of the MMUART to transmit in serial
form. While receiving data to RX FIFO, the MMUART transforms the serial input data into parallel
form to facilitate reading by the processor.

<!-- page 40: manual page 90 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 90
The Baud Rate Generator contains free-running counters and utilizes the asynchronous and
synchronous baud rate generation circuits. The input filters in MMUART suppress the noise and
spikes of incoming clock signals and serial input data based on the filter length. The RZI modulation/
demodulation blocks are intended to allow for IrDA serial infrared (SIR) communications.
Figure 3-29. MMUART Block Diagram
APB
RWCONTROL
MSB or
LSB First
LIN Header Detect
and Auto Baud Rate
Calc Regs
UART_REG and
FIFO CTRL
16 Byte
RX_FIFO
16 Byte
TX_FIFO
Baud Rate Generator
Sync Modes
Frac Baud Rate Calc
Filter
Filter
TX BLOCK
RX BLOCK
TX Time
Guard
RX
Timeout
Interrupt
Control
RZI
Demod
RZI
Mod
MMUART
Interface
Block
MMUART_X_ESWM
MMUART_X_INTR
MMUART_X_TXD
MMUART_X_TXD
MMUART_X_TE
MMUART_X_SCK_IN
MMUART_X_SCK_OUTBAUDRATEN
MMUART_X_E_MST_SCK
MMUART_X_RXD MMUART_X_RXD
MMUART_X_RTS
MMUART_X_DTR
MMUART_X_CTS
MMUART_X_DSR
MMUART_X_RI
MMUART_X_DCD
MMUART_X_SCK
3.12.6.3. Register Map (Ask a Question)
The base addresses and register descriptions of MMUART_0, MMUART_1, MMUART_2, MMUART_3,
and MMUART_4 are listed in PolarFire SoC Device Register Map.
3.12.7. SPI Controller (Ask a Question)
Serial peripheral interface (SPI) is a synchronous serial data protocol that enables the
microprocessor and peripheral devices to communicate with each other. The SPI controller is an
APB slave in the PolarFire SoC FPGA that provides a serial interface compliant with the Motorola
SPI, Texas Instruments synchronous serial, and National Semiconductor MICROWIRE™ formats. In
addition, SPI supports interfacing with large SPI Flash and EEPROM devices and a hardware-based
slave protocol engine. PolarFire SoC FPGAs contain two identical SPI controllers SPI_0 and SPI_1 in
the microprocessor subsystem.
3.12.7.1. Features (Ask a Question)
SPI peripherals support the following features:
• Master and Slave modes
• Configurable Slave Select operation
• Configurable clock polarity
• Separate transmit (Tx) and receive (Rx) FIFOs to reduce interrupt service loading
3.12.7.2. Functional Description  (Ask a Question)
The SPI controller supports Master and Slave modes of an operation.

<!-- page 41: manual page 91 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 91
• In Master mode, the SPI generates SPI_X_CLK, selects a slave using SPI_X_SS, transmits the data
on SPI_X_DO, and receives the data on SPI_X_DI.
• In Slave mode, the SPI is selected by SPI_X_SS. The SPI receives a clock on SPI_X_CLK and
incoming data on SPI_X_DI.
The SPI peripherals consist mainly of the following components (see Figure 3-30).
• Transmit and receive FIFOs
• Configuration and control logic
• SPI clock generator
The following figure shows the SPI controller block diagram.
Figure 3-30. SPI Controller Block Diagram
Configuration and Control
Logic
4x32 Transmit FIFIO
4x32 Receive FIFIO
Tx/Rx
Logic
APB_X_CLK
SPI_X_DI
SPI_X_SS
SPI_X_DOE_N
SPI Clock Generator
APB Bus
PRDATA[31:0]
PWDATA[31:0]
SPI_X_INT
SPI_X_DO
SPI_X_CLK
Notes:
• The SPI_X_DO, SPI_X_DI, SPI_X_SS, and SPI_X_CLK signals are available to the FPGA fabric.
• SPI_X_DOE_N is accessible through the SPI control register.
• SPI_X_INT is sent to the MSS Core Complex.
Note: X is used as a place holder for 0 or 1 in the register and signal descriptions. It indicates SPI _0
(on the APB_0 bus) or SPI_1 (on the APB_1 bus).
3.12.7.2.1. Transmit and Receive FIFOs (Ask a Question)
The SPI controller embeds two 4 × 32 (depth × width) FIFOs for receive and transmit, as shown in
Figure 3-30. These FIFOs are accessible through RX data and TX data registers. Writing to the TX data

<!-- page 42: manual page 92 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 92
register causes the data to be written to the transmit FIFO. This is emptied by the transmit logic.
Similarly, reading from the RX data register causes the data to be read from the receive FIFO.
3.12.7.2.2. Configuration and Control Logic (Ask a Question)
The SPI peripheral can be configured for Master or Slave mode by using the Mode bit of the SPI
CONTROL register. This type of data transfer protocol can be configured by using the TRANSFPRTL
bit of the SPI CONTROL register. The control logic monitors the number of data frames to be sent
or received and enables the interrupts when the data frame transmission or reception is completed.
During data frames transmission or reception, if a transmit under-run error or receive overflow
error is detected, the STATUS Register is updated.
3.12.7.2.3. SPI Clock Generator (Ask a Question)
In Master mode, the SPI clock generator generates the serial programmable clock from the APB
clock.
3.12.7.3. Register Map (Ask a Question)
The base addresses and register descriptions of SPI_0 and SPI_1 are listed in PolarFire SoC Device
Register Map.
3.12.8. I2C  (Ask a Question)
Philips Inter-Integrated Circuit (I2C) is a two-wire serial bus interface that provides data transfer
between many devices. PolarFire SoC FPGAs contain two identical I2C peripherals in the
microprocessor subsystem (I2C_0 and I2C_1), that provide a mechanism for serial communication
between the PolarFire SoC FPGA and the external I2C compliant devices.
PolarFire I2C peripherals support the following protocols:
• I2C protocol as per v2.1 specification
• SMBus protocol as per v2.0 specification
• PMBus protocol as per v1.1 specification
3.12.8.1. Features (Ask a Question)
I2C peripherals support the following features:
• Master and Slave modes
• 7-bit addressing format and data transfers up to 100 Kbit/s in Standard mode and up to 400
Kbit/s in Fast mode
• Multi-master collision detection and arbitration
• Own slave address and general call address detection
• Second slave address detection
• System management bus (SMBus) time-out and real-time idle condition counters
• Optional SMBus signals, SMBSUS_N, and SMBALERT_N, which are controlled through the APB
interface
• Input glitch or spike filters
The I2C peripherals are connected to the AMBA interconnect through the advanced peripheral bus
(APB) interfaces.
3.12.8.2. Functional Description  (Ask a Question)
The I2C peripherals consist mainly of the following components (see Figure 3-31).
• Input Glitch Filter
• Arbitration and Synchronization Logic
• Address Comparator

<!-- page 43: manual page 93 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 93
• Serial Clock Generator
Figure 3-31. I2C Block Diagram
Address Comparator
AP B In te rfac e
I2C_X_BCLK
Input Glitch Filter
SMBus Register
Frequency Register
I2C_X_SMBSUS_NI
I2C_X_SMBALERT_NI
I2C_X_SMBALERT_NO
Glitch Filter Register
Input Glitch Filter
Output
Output
I2C_X_SMBSUS_NO
Control Register
Status Register
Serial Clock
Generator
SMBus and
Filtering
Registers
I2C_X_SMBA_INT
I2C_X_SMBS_INT
Shift Register
Slave0 and Slave1
Address Registers
Arbitration and
Synchronization Logic
Tip: MSS I2C ports can be connected to Fabric I/Os by routing them through
fabric with appropriate BIBUF fabric logic to make them bidirectional.
3.12.8.2.1. Input Glitch Filter (Ask a Question)
The I2C Fast mode (400 Kbit/s) specification states that glitches 50 ns or less must be filtered out of
the incoming clock and data lines. The input glitch filter performs this function by filtering glitches
on incoming clock and data signals. Glitches shorter than the glitch filter length are filtered out. The
glitch filter length is defined in terms of APB interface clock cycles and configurable from 3 to 21 APB
interface clock cycles. Input signals are synchronized with the internal APB interface clock.
3.12.8.2.2. Arbitration and Synchronization Logic  (Ask a Question)
In Master mode, the arbitration logic monitors the data line. If any other device on the bus drives
the data line Low, the I2C peripheral immediately changes from Master-Transmitter mode to Slave-
Receiver mode. The synchronization logic synchronizes the serial clock generator block with the
transmitted clock pulses coming from another master device.
The arbitration and synchronization logic implements the time-out requirements as per the SMBus
specification version 2.0.
3.12.8.2.3. Address Comparator (Ask a Question)
When a master transmits a slave address on the bus, the address comparator checks the 7-bit slave
address with its own slave address. If the transmitted slave address does not match, the address
comparator compares the first received byte with the general call address (0x00). If the address
matches, the STATUS Register is updated. The general call address is used to address each device
connected to the I2C bus.
3.12.8.2.4. Serial Clock Generator (Ask a Question)
In Master mode, the serial clock generator generates the serial clock line (SCL). The clock generator
is switched OFF when I2C is in Slave mode.

<!-- page 44: manual page 94 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 94
MSS I2C uses APB clock to generate the serial clock. See the MSS_I2C_init() function in the MSS
I2C Driver. This driver provides access to the I2C : I2C0_CTRL  control register, which configures
I2C serial clock using the provided divider value to generate the serial clock from the APB clock. For
more information about I2C : I2C0_CTRL  control register, see PolarFire SoC Register Map.
3.12.8.3. Register Map (Ask a Question)
The base addresses and register descriptions of I2C_0 and I2C_1 are listed in PolarFire SoC Device
Register Map.
3.12.9. GPIO  (Ask a Question)
The microprocessor subsystem (MSS) general purpose input/output (GPIO) block is an advanced
peripheral bus (APB) slave that provides access to 32 GPIOs. MSS Masters and fabric Masters can
access the MSS GPIO block through the AMBA interconnect. PolarFire SoC FPGAs contain three
identical GPIO blocks in the microprocessor subsystem (GPIO_0, GPIO_1, and GPIO_2).
3.12.9.1. Features (Ask a Question)
MSS GPIO supports the following features:
• GPIO_0 drives up to 14 MSIOs
• GPIO_1 drives up to 24 MSIOs
• GPIO_2 drives up to 32 device IOs through the FPGA fabric.
• 32 individually configurable GPIOs
• Each GPIO is dynamically programmable as an input, output, or bidirectional I/O.
• Each GPIO can be configured as an interrupt source to the MSS processor in Input mode
• The GPIOs can be selectively reset by either the Hard Reset (Power-on Reset, User Reset from the
fabric) or the Soft Reset from the SYSREG block
3.12.9.2. Functional Description  (Ask a Question)
Figure 3-32 shows the internal architecture of the MSS GPIO block. GPIOs and MSS peripherals,
such as MMUART, SPI, and I2C, can be routed to MSIO pads or to the FPGA fabric through I/O
multiplexers (MUXes), as shown in the figure.
Figure 3-32. GPIO, IOMUX, and MSIO
MSS GPIO
To MSS
Core Complex
Interrupts
MSS Peripherals
(MMUART, USB etc)
GPIO_I_IN
In
IOMUX
i/p
Oe
O/p
In
GPIO_I_OUT
Out
Out
GPIO_I_OE
OE MSIO
Fabric Interface
OE
Interrupts
The MSS GPIO block contains the following:
• 32-bit input register (GPIO_IN), which holds the input values
• 32-bit output register (GPIO_OUT), which holds the output values

<!-- page 45: manual page 95 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 95
• 32-bit interrupt register (GPIO_INTR), which holds the interrupt state
• 32 configuration registers (GPIO_X_CONFIG), one register for each GPIO
When a GPIO is configured in Input mode, the GPIO input is passed through two flip-flop
synchronizer and latched into the GPIO_IN register. The GPIO_IN register value is read through
the APB bus and is accessible to the processor or fabric master. The inputs to GPIO0 and GPIO1 are
from MSIOs. The inputs to GPIO2 are from the fabric.
The GPIO_IN register output can also be used as an interrupt to the processor. This can be
configured as an edge triggered (on rising edge, falling edge, or both edges) or as a level sensitive
(active-low or active-high) interrupt. The interrupt is latched in the GPIO_INTR register and is
accessible through the APB bus.
In Edge-sensitive mode, GPIO_INTR register is cleared either by disabling the interrupt or writing
a Logic 1 through the APB interface. If an edge and GPIO_INTR clearing through the APB occurs
simultaneously, the edge has higher priority.
When the GPIO is configured in an Output mode, the output value can be configured using the APB
bus and is accessible to the processor or fabric Master. GPIO0 and GPIO1 outputs are available to
MSIOs. GPIO2 outputs are available to the fabric.
Figure 3-33. MSS GPIO Block Diagram
MSS GPIO
To
INT[i]
INT[i]
GPIO_i_IN
GPIO_i_OUT
GPIO_i_OE
GPIO_OUT Reg
Interrupt
Reg
(GPIO_IRQ[i])
Interrupt
Generate
Logic
I/O
MUX
(Input Enable)
EN_IN_i
EN_INT_i
EN_OUT_i
TYPES_INT_i
CONFIG_X
Configuration register-32bit
(Interrupt  Types)
(Output Enable)
(Interrupt Enable)
APB INTERFACE
SyncGPIO_IN Reg
0
DQ
MSIO
DQ DQ
00 31:811 22 3 4 5 6 7
0
D Q
3.12.9.3. Register Map (Ask a Question)
The base addresses and register descriptions of GPIO_0, GPIO_1, and GPIO_2 are listed in PolarFire
SoC Device Register Map.
3.12.10. Real-time Counter (RTC) (Ask a Question)
The PolarFire SoC FPGA real-time counter (RTC) keeps track of seconds, minutes, hours, days, weeks,
and years.

<!-- page 46: manual page 96 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 96
3.12.10.1. Features (Ask a Question)
It has two modes of operation:
• Real-time Calendar: Counts seconds, minutes, hours, days, week, months, and years
• Binary Counter: Consecutively counts from 0 to 2 43 - 1
The RTC is connected to the main MSS AMBA interconnect through an APB interface.
3.12.10.2. Functional Description  (Ask a Question)
The RTC architecture and its components are as follows:
• Prescaler
• RTC Counter
• Alarm Wake-up Comparator
Figure 3-34. RTC Block Diagram
Seconds
Minutes
Hours
Day
Month
Year
Day of Week
Week
RTC Counter
Prescaler
APB
Registers Configuration
Strobe 1 Hz
Enable
RTCCLK
PCLK
Alarm
Wake-up
Comparator
RTC_MATCH
RTC_WAKEUP
3.12.10.2.1. Prescaler  (Ask a Question)
The prescaler divides the input frequency to create a time-based strobe (typically 1 Hz) for the
calendar counter. The Alarm and Compare Registers, in conjunction with the calendar counter,
facilitate time-matched events.
To properly operate in Calendar mode, (Clock mode: 1), the 26-bit prescaler must be programmed
to generate a 1 Hz strobe to the RTC. In Binary mode, (Clock mode: 0), the prescaler can be
programmed as required in the application.
3.12.10.2.2. RTC Counter (Ask a Question)
The RTC counter keeps track of seconds, minutes, hours, days, weeks, and years when in Calendar
mode, and for this purpose it requires a 43-bit counter. When counting in Binary mode, the 43-bit
register is treated as a linear up counter.
The following table lists the details of Calendar mode and Binary mode.
Table 3-67. Calendar Counter Description
Function Number
of Bits
Range Reset Value
Calendar Mode Binary Mode Calendar Mode Binary Mode
Second 6 0–59 0–63 0 0
Minute 6 0–59 0–63 0 0
Hour 5 0–23 0–31 0 0
Day 5 1–31 (auto adjust by month and year) 0–31 1 0
Month 4 1–12 0–15 1 0
Year 8 0–255
Year 2000 to 2255
0–255 0 (year 2000) 0

<!-- page 47: manual page 97 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 97
Table 3-67. Calendar Counter Description (continued)
Function Number
of Bits
Range Reset Value
Calendar Mode Binary Mode Calendar Mode Binary Mode
Weekday 3 1–7 0–7 7 0
Week 6 1–52 0–63 1 0
The long-term accuracy of the RTC depends on the accuracy of the external reference frequency. For
example, if the external reference frequency is 124.988277868 MHz rather than 125 MHz, the RTC
loses approximately 8 seconds over 24 hours. The deviation is calculated by the following equations.
The user must calculate the clock ticks deviation per 24 hours using the following equation.
Ctd24 = Ect24 − Act24
where:
• C td24 denotes the clock ticks deviation per 24 hours.
• E ct24 denotes the expected clock ticks per 24 hours, which is based on the ideal external
frequency of 125 MHz. This can be calculated as follows:
Etps × 24 × 60 × 60 = 10800000000000.00
Etps denotes the number of expected clock ticks per second based on the ideal external
frequency. It is 125000000 (125 × 1000000).
• A ct24 denotes the actual clock ticks per 24 hours, which is based on the actual external frequency.
In this example, it is 124.988277868 MHz. Act24 can be calculated as follows:
Atps × 24 × 60 × 60 = 10798987210560.00
Atps denotes the actual clock ticks per second based on the actual external frequency. In this
example, it is 124988277.9 (124.9882779 × 1000000).
Therefore,
Ctd24 = 10800000000000.00 − 10798987210560.00 = 1012789440
Based on the preceding calculations, the number of seconds lost in 24 hours can be calculated as
follows:
Ns = Ctd24
Etps
= 1012789440
125000000 = 8.10231552
Where, Ns denotes the number of seconds lost in 24 hours.
3.12.10.2.3. Alarm Wake-up Comparator (Ask a Question)
The RTC has two modes of operation, selectable through the clock_mode bit.
In Calendar mode, the RTC counts seconds, minutes, hours, days, month, years, weekdays, and
weeks. In Binary mode, the RTC consecutively counts from 0 all the way to 243 - 1. In both the
modes, the alarm event generation logic simply compares the content of the Alarm register with
that of the RTC; when they are equal, the RTC_MATCH output is asserted.
3.12.10.3. Register Map (Ask a Question)
The base address and register description of RTC is listed in PolarFire SoC Device Register Map.
3.12.11. Timer  (Ask a Question)
The PolarFire SoC FPGA system Timer (hereinafter referred as Timer) consists of two programmable
32-bit decrementing counters that generate interrupts to the processor and FPGA fabric.
3.12.11.1. Features (Ask a Question)
The timer supports the following features:

<!-- page 48: manual page 98 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 98
• Two count modes: One-shot and Periodic
• Decrementing 32-bit counters
• Two 32-bit timers can be concatenated to create a 64-bit timer
• Option to enable or disable the interrupt requests when timer reaches zero
• Controls to start, stop, and Reset the Timer
3.12.11.2. Functional Description  (Ask a Question)
The Timer is an APB slave that provides two programmable, interrupt generating, 32-bit
decrementing counters, as shown in the following figure. The counters generate the interrupts
TIMER1INT and TIMER2INT on reaching zero.
Figure 3-35. Timer Block Diagram
Timer
APB Interface
Counter 1
Counter 2
Registers
PCLK
PRESETn
PSEL
PWRITE
PENABLE
PADDR[7:0]
PWDATA[31:0]
PRDATA[31:0]
TIMER1INT
TIMER2INT
The Timer has an APB interface through which the processor can access various CONTROL and
STATUS registers to control and monitor the operation of the Timer.
3.12.11.3. Register Map (Ask a Question)
The base address and register description of the timer is listed in PolarFire SoC Device Register Map.
3.12.12. Watchdog (Ask a Question)
The watchdog timer is an advanced peripheral bus (APB) slave that guards against the system
crashes requiring regular service by the processor or by a bus master in the FPGA fabric. PolarFire
SoC FPGAs contain five identical watchdog timers in the microprocessor subsystem (watchdog_0,
watchdog_1, watchdog_2, watchdog_3, and watchdog_4). Watchdog_0 is associated with the E51
core and is the only one out of the five MSS watchdogs capable of resetting the MSS when it triggers.
Each of the other four watchdogs is maintained by a dedicated U54 core and is only capable of
interrupting the E51 upon triggering.
3.12.12.1. Features (Ask a Question)
The watchdog timer supports following features:
• A 32-bit timer counts down from a preset value to zero, then performs one of the following
user-configurable operations: If the counter is not refreshed, it times out and either causes a
system reset or generates an interrupt to the processor.
• The watchdog timer counter is halted when the processor enters the Debug state.
• The watchdog timer can be configured to generate a wake-up interrupt when the processor is in
WFI mode.
The watchdog timer is connected to the MSS AMBA interconnect through the APB interface.

<!-- page 49: manual page 99 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 99
3.12.12.2. Functional Description  (Ask a Question)
The watchdog timer consists of following components (as shown in the following figure):
• APB Interface
• 32-Bit Counter
• Timeout Detection
Figure 3-36. WatchDog Block Diagram
PRDATA[31:0]
WDOGTIMEOUT
WDOGTIMEOUTINT
WDOGWAKEUPINT
APB Interface
Watchdog
32-Bit Counter
Timeout Detection
PCLK
PRESETn
PSEL
PWRITE
PENABLE
PADDR[7:0]
PWDATA[31:0]
PORESETN
RCOSCRESETN
WDOGMODE
WDOGMVRP[31:0]
WDOGLOAD[25:0]
WDOGENABLE
SLEEPING
HALTED
PROGRAMMING
3.12.12.2.1. APB Interface (Ask a Question)
The watchdog timer has an APB interface through which the processor can access various CONTROL
and STATUS registers to control and monitor its operation. The APB interface is clocked by the PCLK
clock signal.
3.12.12.2.2. 32-Bit Counter (Ask a Question)
The operation of the watchdog timer is based on a 32-bit down counter that must be refreshed at
regular intervals by the processor. If not refreshed, the counter will time-out. In normal operation,
the generation of a Reset or time-out interrupt by the watchdog timer does not occur because the
watchdog timer counter is refreshed on a regular basis.
The MSS watchdogs are not enabled initially when the MSS comes out of Reset. When the device
is powered up, the watchdog timer is enabled with the timeout period set to approximately 10.47
seconds (if VDD = 1.2 V).
3.12.12.2.3. Timeout Detection (Ask a Question)
A control bit in the WDOG_CONTROL register is used to determine whether the watchdog timer
generates a Reset or an interrupt if a counter time-out occurs. The default setting is Reset
generation on time-out. When interrupt generation is selected, the WDOGTIMEOUTINT output is
asserted on time-out and remains asserted until the interrupt is cleared. When Reset generation is
selected, the watchdog timer does not directly generate the system Reset signal. Instead, when the
counter reaches zero, the watchdog timer generates a pulse on the WDOGTIMEOUT output, and this
is routed to the Reset controller to cause it to assert the necessary Reset signals.
Note: Only watchdog_0 can reset the MSS. The other watchdogs can only generate interrupts to the
E51 core.
3.12.12.3. Register Map (Ask a Question)
The base addresses and register descriptions of watchdog timers are listed in PolarFire SoC Device
Register Map.

<!-- page 50: manual page 100 -->
Functional Blocks
 Technical Reference Manual
© 2025 Microchip Technology Inc. and its subsidiaries
DS60001702Q - 100
3.12.13. Universal Serial Bus OTG Controller (Ask a Question)
Universal serial bus (USB) is an industry standard that defines cables, connectors, and serial
communication protocol used in a bus for connection, communication, and power supply between
electronic devices. PolarFire SoC FPGA device contains a USB On-The-Go (OTG) controller as part
of the microprocessor subsystem (MSS). USB OTG controller provides a mechanism for the USB
communication between the PolarFire SoC FPGA and external USB host/USB device/USB OTG
protocol compliant devices.
3.12.13.1. Features (Ask a Question)
USB OTG controller supports the following features:
• Operates as a USB host in a point-to-point or multi-point communication with other USB devices
• Operates as a USB peripheral with other USB hosts
• Compliant with the USB 2.0 standard and includes OTG supplement
• Supports USB 2.0 speeds:
– High speed (480 Mbps)
– Full speed (12 Mbps)
• Supports session request protocol (SRP) and host negotiation protocol (HNP)
• Supports suspend and resume signaling
• Supports multi-point capabilities
• Supports four direct memory access (DMA) channels for data transfers
• Supports high bandwidth isochronous (ISO) pipe enabled endpoints
• Hardware selectable option for 8-bit/4-bit Low Pin Count Interface (LPI)
• Supports ULPI hardware interface to external USB physical layer (PHY)
• Soft connect/disconnect
• Configurable for up to five transmit endpoints (TX EP) and up to five receive endpoints (RX EP),
including control endpoint (EP0)
• Offers dynamic allocation of endpoints, to maximize the number of devices supported
• Internal memory of 8 KB with support for dynamic allocation to each endpoint
• Performs all USB 2.0 transaction scheduling in hardware
• Supports link power management
• SECDED protection on the internal USB memory with the following features:
– Generates interrupts on 1-bit or 2-bit errors; these interrupts can be masked
– Corrects 1-bit errors
– Counts the number of 1-bit and 2-bit errors
For more information on USB 2.0 and OTG protocol specifications, see the following web pages:
• www.usb.org/developers/docs/
• www.usb.org/developers/onthego/
The USB OTG controller can function as an AHB master for DMA data transfers and as an AHB slave
for configuring the USB OTG controller from the masters processor or from the FPGA fabric logic.
The USB OTG controller can function as one of the following:
• A high speed or a full speed peripheral USB device attached to a conventional USB host (such as
a PC)
• A point-to-point or multi-point USB host
