# Hardware Crypto Accelerator Models

Synthesizable SystemVerilog RTL and UVM testbenches for documentation-driven
models of embedded crypto and security peripherals.

This repository collects block-level implementations inspired by vendor SoCs and
IP blocks. The goal is to build usable open reference models of the hardware
interface, register map, and dataflow, together with runnable verification
environments.

## Repository Contents

| Project | Device Family | Block | Bus Model | Status |
|---------|---------------|-------|-----------|--------|
| [esp32_p4_aes](esp32_p4_aes/) | Espressif ESP32-P4 | AES accelerator | AHB-Lite control + AXI4 DMA | RTL + UVM |
| [psoc6](psoc6/) | Infineon PSoC 6 | Crypto block | AHB-Lite slave + AHB master | RTL in progress |
| [psoc_c3](psoc_c3/) | Infineon PSoC Control C3 | CryptoLite | AHB-Lite slave + AHB master | RTL + UVM |
| [other_specs](other_specs/) | Various | Reference material | N/A | Research inputs |

## What These Models Focus On

- Bus-visible behavior: register layout, control flow, interrupts, and DMA-style operand movement.
- Practical block structure: top-level integration, sub-engines, and realistic memory-side interfaces.
- Verification that is runnable in commercial simulators and lightweight open-source flows where possible.
- Clear mapping from public documentation to RTL structure.

These are not drop-in vendor netlist replacements. They are clean-room,
documentation-based hardware models intended for study, experimentation, and
verification work.

## Project Highlights

### `esp32_p4_aes`
- AES accelerator model with multiple block and stream modes.
- AHB-Lite control plane and AXI4 operand/data path.
- UVM environment with regression coverage for the supported modes.

### `psoc6`
- Work-in-progress model of the larger PSoC 6 crypto subsystem.
- Includes cipher, hash, RNG, and vector-unit oriented structure.
- Shared verification agents in `psoc6/tb/agents` are reused by other projects in this repo.

### `psoc_c3`
- CryptoLite model covering AES-128 ECB, SHA-256 schedule/process flows, TRNG behavior, and a vector-unit style arithmetic engine.
- AHB-Lite slave MMIO interface plus AHB master operand-memory interface.
- UVM environment with:
  active AHB front-door agent
  passive IRQ monitoring
  DUT-side operand memory model
  virtual sequencer
  feature-level directed sequences
  lightweight scoreboard and register-access coverage
- Current regression tests cover:
  AES descriptor execution
  SHA-256 schedule pass
  SHA-256 process pass
  full SHA-256 two-pass flow
  TRNG basic result path
  TRNG Von Neumann mode
  TRNG repetition-count detection
  TRNG adaptive-proportion detection
  vector-unit opcode coverage for move, add, subtract, xor, multiply, carry-less multiply, shift-right-by-1, shift-left-by-1, immediate shift-right, and conditional subtract
  interrupt/error propagation
  busy-time command blocking

## Spec Coverage

Approximate coverage of each project's public spec in RTL and UVM.

| Project | RTL vs. spec | UVM vs. spec | Notable gap |
|---------|--------------|--------------|-------------|
| `esp32_p4_aes` | ~95% | ~85% | CFB8 declared in package but not implemented; GCM exercised only with the NIST empty-input vector |
| `psoc6`        | ~80% (engines full; AEAD / cancel / context / key / feature-discovery / protection modules are stubs) | ~80% (stubs are unexercised) | AEAD orchestration, context/key management, protection unit |
| `psoc_c3`      | ~100% | ~100% | None substantive |

### `esp32_p4_aes`
- **Spec**: AES-128/-256 (no -192), modes ECB/CBC/OFB/CTR/CFB8/CFB128/GCM, Typical (register) and DMA working modes, completion IRQ.
- **RTL**: AES-128/256 cores with key expansion and forward/inverse rounds; ECB, CBC, OFB, CTR, CFB128, GCM (two-phase with GHASH / GF-mult); AHB-Lite slave and AXI4 master DMA. CFB8 is the conspicuous miss.
- **UVM**: 16 regression tests — register smoke, Typical ECB 128/256, consecutive Typical, DMA ECB/CBC/OFB/CTR for 128 and 256, DMA CFB128 (128 only), GCM (empty-plaintext vector). Covergroups cross mode × key length × direction; AHB SVA; runs under VCS, Xcelium, and Questa.

### `psoc6`
- **Spec**: AES-128/256, DES/3DES, SHA-1 / SHA2-224/256/384/512 / SHA3, GCM, TRNG + health, PRNG, CRC-32, 16-register vector unit with large-integer arithmetic, instruction FIFO / descriptor dispatch, AHB slave and master.
- **RTL** (~6.8 kLOC): cipher (AES, DES/3DES), hash (SHA-1, SHA2-256, SHA2-512, SHA3 Keccak), RNG (TRNG + health, PRNG, CRC-32), full six-module VU, instruction decoder, load/store FIFOs, register buffer, AHB slave/master, top-level orchestrator. Empty stubs: `aead_controller`, `cancel_logic`, `ctx_manager`, `feature_discovery`, `key_manager`, `protection_unit`.
- **UVM**: 16 passing regression tests covering register smoke, AES-128-ECB and AES-256-CBC, AEAD-GCM, DES, 3DES, SHA-1/256/3-256, CRC-32, PRNG, TRNG, VU, cancel, error handling, and instruction-FIFO overflow. RAL, DPI reference models for each engine, AHB + IRQ agents, scoreboard, coverage.

### `psoc_c3`
- **Spec**: AES-128 ECB, SHA-256 schedule + process, TRNG with Von Neumann debiasing and repetition-count / adaptive-proportion health monitors, vector unit with 10 opcodes (MOV, ADD, SUB, XOR, XMUL, MUL, LSR1, LSL1, LSR-immediate, COND_SUB), descriptor-pointer programming model over AHB slave with AHB-master operand memory.
- **RTL** (~2.1 kLOC): `aes_engine`, `sha_engine` (full 64-round SHA-256), `trng` (ring/GARO/FIRO oscillators + Von Neumann + RC + AP), `vu_engine` covering all 10 opcodes, 26-register MMIO file, AHB-slave + AHB-master top. No stubs.
- **UVM**: 20 passing regression tests — AES-ECB; SHA-256 schedule / process / full; TRNG basic / VN / RC / AP; one test per VU opcode; interrupt/error; busy-time MMIO blocking.

## Layout

```text
ifx_like/
  esp32_p4_aes/   RTL + UVM for the ESP32-P4 AES accelerator
  psoc6/          RTL + shared verification infrastructure for the PSoC 6 crypto block
  psoc_c3/        RTL + UVM for the PSoC Control C3 CryptoLite block
  other_specs/    Public reference documents and notes for future implementations
```

Typical subproject structure:

```text
<project>/
  rtl/            Design RTL
  tb/             UVM environment, agents, sequences, tests
  sim/            Simulator Makefile and filelists
  spec/           Public documentation used as implementation input
```

## Getting Started

Clone the repository:

```bash
git clone <repo-url>
cd ifx_like
```

Run a regression:

```bash
cd <project>/sim
make regress SIM=xcelium
```

Run a single test:

```bash
cd psoc_c3/sim
make sim SIM=xcelium TEST=cryptolite_aes_ecb_test
```

There is also a lightweight standalone unit test for the current PSoC C3 vector
unit model:

```bash
cd psoc_c3/sim
make unit-vu
```

## Simulator Notes

- Xcelium is the primary simulator target for the UVM environments in this repo.
- Some focused unit tests are also runnable with `iverilog`.
- Each project keeps its own `sim/Makefile` and `filelist.f` so flows stay local to the block being developed.

## Scope and Intent

This repository is aimed at engineers who want:

- readable reference RTL for documented crypto peripherals
- executable UVM environments around those blocks
- a base for experimentation, model comparison, or downstream tooling work

Where behavior is underspecified in public documentation, the implementations aim
to be explicit and internally consistent rather than vendor-exact by accident.
