# IFX-Like Hardware IP Implementations

Synthesizable RTL + UVM verification environments for crypto/security accelerators,
reverse-engineered from vendor TRMs.

## Implemented

| Project | Chip | Peripheral | Key sizes | Modes | Bus | Status |
|---------|------|------------|-----------|-------|-----|--------|
| [esp32_p4_aes](esp32_p4_aes/) | Espressif ESP32-P4 | AES accelerator | 128 / 256 | ECB, CBC, OFB, CTR, CFB-128, GCM | AHB-Lite (ctrl) + AXI4 (DMA) | RTL + UVM complete, 14 regression tests |
| [psoc6](psoc6/) | Infineon PSoC 6 | Crypto block | — | ISA-programmable crypto engine | AHB | In progress |

## Unimplemented specs (`other_specs/`)

| Vendor | Device / Doc | Notes |
|--------|-------------|-------|
| Infineon | PSoC Control C3 (arch + registers TRM) | Next-gen PSoC, M33 core |
| Infineon | PSoC Edge E8x (datasheet + programming spec) | ML-focused, dual-core |
| Microchip | PolarFire SoC MSS TRM + Security User Guide | RISC-V, fabric-based crypto |
| NXP | i.MX23 Reference Manual | ARM926, DCP crypto engine |
| Rambus / Inside Secure | SafeXcel EIP-93, EIP-97 brochures | Packet engine IP cores |
| Realtek | Ameba-ZII (app note + user manual) | IoT SoC, AES/SHA HW |
| Dialog | DA1459x / DA14683 / DA1469x datasheets | Bluetooth SoCs |
| CAST | AES-CCM IP briefs (ASIC + Intel) | Licensable IP core |
| Synopsys | Security IP brochure | Broad portfolio overview |

## Structure

Each implemented project follows the same layout:

```
<project>/
  spec/     vendor PDFs (TRM, datasheet, register map)
  rtl/      synthesizable SystemVerilog
  tb/       UVM 1.2 testbench (agents, RAL, scoreboard, sequences, tests)
  sim/      Makefile + filelist.f (VCS / Xcelium / Questa)
```

Run a regression: `cd <project>/sim && make regress SIM=xcelium`
