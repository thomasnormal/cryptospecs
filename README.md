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
  vector-unit add
  vector-unit multiply
  interrupt/error propagation
  busy-time command blocking

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
