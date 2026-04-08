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
