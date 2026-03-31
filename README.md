# Crypto Accelerator Spec Collection

Reference specs for AHB/AXI MMIO crypto accelerator IP blocks. Collected to study architectures that combine an AHB slave control plane (MMIO SFRs) with AXI/DMA-based data movement, supporting multiple cipher and hash algorithms.

## Target architecture

- MMIO SFRs accessed via AHB (AHB5 / AHB-Lite) slave interface
- AXI master interface for bulk memory access (DMA)
- Registers for control, mode, status, interrupt, key/IV/AAD/src/dst addressing
- IO ports: interrupt, AHB slave, AXI signals
- Front-door access through UVM RAL model
- Multi-algorithm support (AES-ECB/CBC/CTR/GCM/CCM, SHA, HMAC)

---

## Specs

### Microchip PolarFire SoC (strongest overall match)

| File | Pages | Description |
|------|-------|-------------|
| `PolarFire_SoC_MSS_TRM.pdf` | ~158 | **MSS Technical Reference Manual.** Shows AXI Switch feeding AXI-to-AHB bridge with UserCrypto as a peripheral. Closest match to the ~150-page AHB+AXI bridged crypto subsystem target. |
| `AC464_UserCrypto_AppNote.pdf` | ~39 | **Implementing Data Security Using User Cryptoprocessor (AC464).** Describes the Athena TeraFire EXP-F5200B crypto core with AHB-Lite slave for control and AHB-Lite master for DMA. Covers AES (ECB/CBC/CTR/GCM), SHA, HMAC, elliptic curve, and SCA-resistant modes. |
| `PolarFire_Security_User_Guide.pdf` | — | Security architecture overview: UserCrypto, secure boot, anti-tamper, key management. |
| `PolarFire_SoC_Architecture.pdf` | — | SoC-level architecture document covering RISC-V MSS, fabric interfaces, and security features. |
| `PolarFire_SoC_Product_Overview.pdf` | — | High-level product overview of the PolarFire SoC FPGA family. |
| `PolarFire_System_Services_User_Guide.pdf` | — | System services including crypto service APIs for the MSS. |

### Espressif ESP32-P4 (best freely available register-level detail)

| File | Pages | Description |
|------|-------|-------------|
| `ESP32-P4_TRM.pdf` | ~1400 | **Technical Reference Manual.** Full register maps for AES, SHA, HMAC, ECC accelerators. Documents both GDMA-AHB and GDMA-AXI controllers. DMA-AES mode supports ECB/CBC/OFB/CTR/CFB/GCM. The most complete single document for studying MMIO crypto register layouts. |
| `ESP32-P4_TRM_v1.3.pdf` | ~1400 | Same TRM for chip revision v1.3. |
| `ESP32-P4_Datasheet_v1.3.pdf` | ~93 | Chip datasheet. Summarizes GDMA-AHB/AXI and crypto accelerator features at a high level. |
| `ESP32-P4_Datasheet_prelim.pdf` | ~93 | Earlier preliminary version of the datasheet. |

### Realtek Ameba-Z II (descriptor-style crypto DMA)

| File | Pages | Description |
|------|-------|-------------|
| `Ameba-ZII_Application_Note.pdf` | — | **AN0500 Application Note.** Documents the security engine with source/destination descriptor registers for HMAC key, cipher key, IV, AAD, and plaintext buffers. Closest public match to the IV_ADDR/AAD_ADDR/SRC_ADDR/DST_ADDR register style. |
| `Ameba-ZII_DEV_User_Manual.pdf` | — | Dev board user manual with peripheral overview. |

### Inside Secure / Rambus SafeXcel (DMA ring-mode packet engines)

| File | Pages | Description |
|------|-------|-------------|
| `SafeXcel_EIP-93_Brochure.pdf` | ~3 | **EIP-93 Inline Packet Engine.** Low gate count crypto accelerator with autonomous ring-mode DMA operation. AES (including CCM), SHA, HMAC. AHB interface option. Reads/writes packet data and descriptors from host memory via DMA. |
| `SafeXcel_EIP-97_Brochure.pdf` | ~3 | **EIP-97 Look-Aside Packet Engine.** Higher-performance variant for multi-core SoCs. Multiple ring interfaces, broader algorithm support. |

### Synopsys SPAcc (configurable protocol accelerator)

| File | Pages | Description |
|------|-------|-------------|
| `Synopsys_SecurityIP_Brochure.pdf` | ~8 | **Security IP portfolio brochure.** Covers the SPAcc family which supports AEAD (CCM, GCM, ChaCha20-Poly1305), SHAKE128/256, XOF, scatter/gather DMA, and selectable AMBA AXI or AHB interfaces. The XOF support is relevant if your spec includes XOF_LEN registers. |

### CAST (crypto IP core briefs)

| File | Pages | Description |
|------|-------|-------------|
| `CAST_AES-CCM_Brief_ASIC.pdf` | ~2 | **AES-CCM core brief (ASIC target).** Describes a standalone AES-CCM authenticated encryption engine with HDL deliverables and testbench. Core-level only, not a full bus-attached DMA subsystem. |
| `CAST_AES-CCM_Brief_Intel.pdf` | ~2 | Same core targeting Intel (Altera) FPGAs. |

---

## Not publicly available

These specs match the target architecture closely but require NDA, sales contact, or gated access:

- **Rambus CRYPT-IP-120 (EIP-120)** — AES + SHA-2 + DMA with AHB master/slave; AXI available on request. Contact [Rambus](https://www.rambus.com/security/crypto-accelerator-hardware-cores/basic-crypto-blocks/crypt-ip-120/).
- **Synopsys SPAcc full datasheet** — Gated behind [Synopsys DesignWare portal](https://www.synopsys.com/dw/ipdir.php?ds=security-protocol-accelerator).
- **PolarFireSoC_Register_Map.zip** — Microchip's download portal is broken; HTML version browsable at [MSU mirror](https://web.pa.msu.edu/people/edmunds/Disco_Kraken/PolarFire_SoC_Register_Map/PF_SoC_RegMap/pfsoc_regmap.htm).
