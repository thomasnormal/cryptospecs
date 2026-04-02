# IFX-Like Hardware IP Implementations

Synthesizable RTL + UVM verification environments for crypto/security accelerators,
modelled from vendor TRMs and register maps.

## Target Feature Profile

Specs are selected based on the following criteria. The more boxes a device checks,
the higher priority it is for implementation.

### Bus / Interface
- MMIO register file accessible via **AHB or AXI** (AHB-Lite slave for config, AHB5 preferred)
- Separate **AXI master** or AHB master for DMA-style memory access (src/dst operand fetch)
- Standard IO ports: `interrupt_level`, AHB slave signals, AXI signals
- ~150 pages of register documentation (enough detail to build a complete RAL model)
- **Front-door register access** through UVM RAL model

### Register Set (desired coverage)
| Register | Purpose |
|----------|---------|
| `CTRL` | Enable, soft-reset, power mode |
| `MODE` | Algorithm and cipher mode select |
| `STATUS` / `BUSY` | Operation state, error flags |
| `IV_ADDR` | Initialisation vector pointer |
| `AAD_ADDR` / `AAD_LEN` / `AAD_TOTLEN` | Additional authenticated data |
| `SRC_ADDR` / `SRC_LEN` / `SRC_TOTLEN` | Plaintext / ciphertext source |
| `DST_ADDR` | Destination address |
| `MAC_ADDR` / `MAC_VERIF_RESULT` / `MAC_VERIF_MIN_LEN` | MAC output and verification |
| `XOF_LEN` | Extendable-output function length |
| `KEY_ADDR` / `KEY_ID` | Key material and key-slot index |
| `KEYTP1_PERM` / `KEYTP1_VALID` | Key type / permission / validity |
| `ERROR_DESC` / `ERROR_ADDR` | Fault description and faulting address |
| `QDENY_CFG` / `QDENY_STATUS` | Queue-deny / access-protection config |
| `INTR_SRC` / `INTR_MASK` / `INTR_MASKED` | Interrupt quad (RW1C / RW1S / RO) |
| `USER_PERM` | Per-user permission bitmap |
| `FEATURE_AVAIL` / `FEATURE_CFG` | Feature discovery and runtime config |
| `SYSTEM_STATE` | Lifecycle / security state |
| `CTX_ADDR` | Context save/restore pointer |
| `CANCEL` | In-flight operation cancellation |

### Algorithms (nice to have)
- Symmetric cipher: **AES** (ECB, CBC, CTR, CFB, OFB, GCM/CCM), **DES / 3DES**
- Hash / MAC: **SHA-1, SHA-2, SHA-3**, HMAC, CMAC, GHASH
- Asymmetric: **RSA**, **ECC** (NIST P-curves), DH key exchange, Ed25519
- RNG: **TRNG** (ring-oscillator based) + **PRNG** (LFSR)
- CRC (programmable polynomial)

### Verification (nice to have)
- **DPI-C reference model** for encryption engines (OpenSSL or BoringSSL backend)
- Constrained-random operand generation covering corner cases
- Cross-coverage for algorithm × mode × key-size
- Error injection sequences (bad key, bad length, cancellation mid-flight)

---

## Implemented

| Project | Chip | Peripheral | Key sizes | Algorithms / Modes | Bus | Status |
|---------|------|------------|-----------|--------------------|-----|--------|
| [esp32_p4_aes](esp32_p4_aes/) | Espressif ESP32-P4 | AES accelerator | 128 / 256 | ECB, CBC, OFB, CTR, CFB-8, CFB-128, GCM | AHB-Lite (ctrl) + AXI4 (DMA) | RTL + UVM complete, 14 regression tests |
| [psoc6](psoc6/) | Infineon PSoC 6 | Crypto block | 128 / 192 / 256 | AES, DES/3DES, SHA-1/2/3, CRC, PRNG, TRNG, VU (RSA/ECC) | AHB-Lite slave + AHB master | RTL in progress |
| [psoc_c3](psoc_c3/) | Infineon PSoC Control C3 | CryptoLite | 128 | AES-128 ECB, SHA-256, TRNG, VU (RSA/ECC) | AHB-Lite slave + AHB master | RTL in progress |

### PSoC 6 notable features
- Instruction-FIFO execution model: CPU pushes 32-bit instruction words; HW decodes and dispatches
- 16-register Vector Unit (VU) for large-integer arithmetic (RSA, ECC up to 8192-bit operands)
- Conditional execution on all VU instructions (11 condition codes, ARM-style)
- 2048-bit register buffer (two 1024-bit partitions) shared across cipher/hash/VU
- 4 KB internal SRAM memory buffer for operand data
- TRNG: up to 6 ring oscillators (RO11, RO15, GARO15/31, FIRO15/31) + RC and AP health monitors
- PRNG: 3 Fibonacci LFSRs (32-bit, 31-bit, 29-bit) combined by XOR
- Interrupt quad: `INTR` (RW1C) / `INTR_SET` (RW1S) / `INTR_MASK` / `INTR_MASKED` (RO)
- Reference drivers: [`psoc6/pdl`](psoc6/pdl/) submodule (`Infineon/mtb-pdl-cat1`)

---

## Unimplemented specs (`other_specs/`)

| Vendor | Device / Doc | Highlights | Score |
|--------|-------------|-----------|-------|
| Infineon | [PSoC Edge E8x](other_specs/infineon/) | ML-focused, dual-core, hardware crypto | High |
| Infineon | [PSoC Edge E8x](other_specs/infineon/) | ML-focused, dual-core, hardware crypto | High |
| Rambus / Inside Secure | [SafeXcel EIP-93, EIP-97](other_specs/rambus_insidesecure/) | Packet engine IP cores, AHB/AXI, full cipher+hash+AEAD | High |
| Microchip | [PolarFire SoC MSS](other_specs/microchip/) | RISC-V, fabric-based crypto subsystem | Medium |
| NXP | [i.MX23](other_specs/nxp/) | ARM926, DCP crypto engine | Medium |
| Realtek | [Ameba-ZII](other_specs/realtek/) | IoT SoC, AES/SHA HW | Medium |
| Dialog | [DA1459x / DA14683 / DA1469x](other_specs/dialog/) | Bluetooth SoCs | Low |
| CAST | [AES-CCM IP](other_specs/cast/) | Licensable IP core brief | Low |
| Synopsys | [Security IP](other_specs/synopsys/) | Broad portfolio overview only | Low |
| Espressif | [ESP32-P4](other_specs/espressif/) | Reference for esp32_p4_aes implementation | — |

---

## Repository Structure

```
ifx_like/
  esp32_p4_aes/          RTL + UVM for Espressif ESP32-P4 AES
  psoc6/                 RTL + UVM for Infineon PSoC 6 Crypto
  psoc_c3/               RTL + UVM for Infineon PSoC Control C3 CryptoLite
    pdl/                 Submodule: Infineon/mtb-pdl-cat1 (reference drivers)
    rtl/
      pkg/               crypto_pkg.sv, crypto_isa_pkg.sv
      ctrl/              instruction FIFO, register buffer, memory buffer
      cipher/            AES, DES, TDES engines
      hash/              SHA-1/2/3 engines
      rng/               TRNG, PRNG
      vu/                Vector Unit (large-integer arithmetic)
      top/               crypto_top.sv, AHB slave/master interfaces
    tb/                  UVM 1.2 testbench (agents, RAL, scoreboard, sequences)
    sim/                 Makefile + filelist.f
    spec/                Vendor PDFs
  other_specs/           Unimplemented vendor specs for future reference
  README.md
```

To initialise submodules after cloning:
```
git submodule update --init
```

Run a regression:
```
cd <project>/sim && make regress SIM=xcelium
```
