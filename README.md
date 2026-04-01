# Crypto Accelerator Spec Collection

Reference specs for AHB/AXI MMIO crypto accelerator IP blocks. Collected to study architectures that combine an AHB slave control plane (MMIO SFRs) with AXI/DMA-based data movement, supporting multiple cipher and hash algorithms.

## Target architecture

- MMIO SFRs accessed via AHB (AHB5 / AHB-Lite) slave interface
- AXI master interface for bulk memory access (DMA)
- Registers for control, mode, status, interrupt, key/IV/AAD/src/dst addressing
- IO ports: interrupt, AHB slave, AXI signals
- Front-door access through UVM RAL model
- Multi-algorithm support (AES-ECB/CBC/CTR/GCM/CCM, SHA, HMAC)

## Directory layout

Specs are organized by vendor. Each vendor directory contains PDF specs and optionally a markdown conversion of key documents.

---

## microchip/ — PolarFire SoC (strongest overall match)

| File | Description |
|------|-------------|
| `PolarFire_SoC_MSS_TRM.pdf` | **MSS Technical Reference Manual (~158 pages).** AXI Switch feeding AXI-to-AHB bridge with UserCrypto as a peripheral. Closest match to the ~150-page AHB+AXI bridged crypto subsystem target. |
| `PolarFire_SoC_MSS_TRM/` | Markdown conversion of the TRM (22 chapters, 38 figures). |
| `AC464_UserCrypto_AppNote.pdf` | **Implementing Data Security Using User Cryptoprocessor (AC464, ~39 pages).** Athena TeraFire EXP-F5200B crypto core with AHB-Lite slave + AHB-Lite master DMA. AES (ECB/CBC/CTR/GCM), SHA, HMAC, elliptic curve, SCA-resistant modes. |
| `PolarFire_Security_User_Guide.pdf` | Security architecture: UserCrypto, secure boot, anti-tamper, key management. |
| `PolarFire_SoC_Architecture.pdf` | SoC-level architecture: RISC-V MSS, fabric interfaces, security features. |
| `PolarFire_SoC_Product_Overview.pdf` | High-level product overview. |
| `PolarFire_System_Services_User_Guide.pdf` | System services including crypto service APIs. |

## espressif/ — ESP32-P4 (best freely available register-level detail)

| File | Description |
|------|-------------|
| `ESP32-P4_TRM.pdf` | **Technical Reference Manual (~1400 pages).** Full register maps for AES, SHA, HMAC, ECC accelerators. Both GDMA-AHB and GDMA-AXI controllers. DMA-AES supports ECB/CBC/OFB/CTR/CFB/GCM. |
| `ESP32-P4_TRM_v1.3.pdf` | Same TRM for chip revision v1.3. |
| `ESP32-P4_Datasheet_v1.3.pdf` | Chip datasheet (~93 pages). GDMA-AHB/AXI and crypto accelerator summary. |
| `ESP32-P4_Datasheet_prelim.pdf` | Earlier preliminary datasheet. |

## dialog/ — Dialog Semiconductor (AHB crypto peripherals)

| File | Description |
|------|-------------|
| `da14683_datasheet.pdf` | DA14683 datasheet. AHB-based crypto engine (AES, HASH). |
| `da1469x_datasheet.pdf` | DA1469x datasheet. AHB-connected crypto accelerator with DMA. |
| `da1459x_datasheet.pdf` | DA1459x datasheet. Crypto peripheral documentation. |

## nxp/ — NXP (DMA + crypto subsystem reference)

| File | Description |
|------|-------------|
| `imx23_rm.pdf` | **i.MX23 Reference Manual.** DCP (Data Co-Processor) with AES/SHA, DMA-based crypto engine with channel-based descriptor architecture. |

## realtek/ — Ameba-Z II (descriptor-style crypto DMA)

| File | Description |
|------|-------------|
| `Ameba-ZII_Application_Note.pdf` | **AN0500 Application Note.** Security engine with source/destination descriptor registers for HMAC key, cipher key, IV, AAD, and plaintext buffers. Closest public match to IV_ADDR/AAD_ADDR/SRC_ADDR/DST_ADDR register style. |
| `Ameba-ZII_DEV_User_Manual.pdf` | Dev board user manual with peripheral overview. |

## rambus_insidesecure/ — SafeXcel (DMA ring-mode packet engines)

| File | Description |
|------|-------------|
| `SafeXcel_EIP-93_Brochure.pdf` | **EIP-93 Inline Packet Engine (~3 pages).** Low gate count, autonomous ring-mode DMA, AES (incl. CCM), SHA, HMAC. AHB interface option. |
| `SafeXcel_EIP-97_Brochure.pdf` | **EIP-97 Look-Aside Packet Engine (~3 pages).** Higher-performance variant for multi-core SoCs. |

## synopsys/ — SPAcc (configurable protocol accelerator)

| File | Description |
|------|-------------|
| `Synopsys_SecurityIP_Brochure.pdf` | **Security IP portfolio brochure (~8 pages).** SPAcc with AEAD (CCM, GCM, ChaCha20-Poly1305), SHAKE/XOF, scatter/gather DMA, selectable AXI or AHB interfaces. |

## cast/ — Crypto IP core briefs

| File | Description |
|------|-------------|
| `CAST_AES-CCM_Brief_ASIC.pdf` | **AES-CCM core brief (~2 pages, ASIC target).** Standalone authenticated encryption engine, HDL deliverables and testbench. |
| `CAST_AES-CCM_Brief_Intel.pdf` | Same core targeting Intel (Altera) FPGAs. |

---

## Not publicly available

- **Rambus CRYPT-IP-120 (EIP-120)** — AES + SHA-2 + DMA with AHB master/slave; AXI on request. Contact [Rambus](https://www.rambus.com/security/crypto-accelerator-hardware-cores/basic-crypto-blocks/crypt-ip-120/).
- **Synopsys SPAcc full datasheet** — Gated behind [Synopsys DesignWare portal](https://www.synopsys.com/dw/ipdir.php?ds=security-protocol-accelerator).
- **PolarFireSoC_Register_Map.zip** — Microchip download portal broken; HTML version at [MSU mirror](https://web.pa.msu.edu/people/edmunds/Disco_Kraken/PolarFire_SoC_Register_Map/PF_SoC_RegMap/pfsoc_regmap.htm).
