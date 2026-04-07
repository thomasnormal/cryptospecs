// PSoC Control C3 CryptoLite — RTL + UVM filelist
// Pass to xcelium/vcs with: xrun -f filelist.f

// Include directories
+incdir+../rtl/pkg
+incdir+../tb/common
+incdir+../tb/env
+incdir+../tb/sequences
+incdir+../tb/tests
+incdir+../../psoc6/tb/agents/ahb_agent
+incdir+../../psoc6/tb/agents/irq_agent

// Design package first
../rtl/pkg/cryptolite_pkg.sv

// Shared AES package and core from esp32_p4_aes project
../../esp32_p4_aes/rtl/aes_accel_pkg.sv
../../esp32_p4_aes/rtl/core/aes_sbox.sv
../../esp32_p4_aes/rtl/core/aes_mix_columns.sv
../../esp32_p4_aes/rtl/core/aes_round.sv
../../esp32_p4_aes/rtl/core/aes_inv_round.sv
../../esp32_p4_aes/rtl/core/aes_key_expand.sv
../../esp32_p4_aes/rtl/core/aes_core.sv

// CryptoLite RTL
../rtl/ctrl/cryptolite_regfile.sv
../rtl/cipher/aes_engine.sv
../rtl/hash/sha_engine.sv
../rtl/rng/trng.sv
../rtl/vu/vu_engine.sv
../rtl/top/cryptolite_top.sv

// Interfaces used by UVM and the DUT-side memory model
../../psoc6/tb/agents/ahb_agent/ahb_if.sv
../../psoc6/tb/agents/irq_agent/irq_if.sv
../tb/common/cryptolite_mem_if.sv

// Shared UVM agents
../../psoc6/tb/agents/ahb_agent/ahb_agent_pkg.sv
../../psoc6/tb/agents/irq_agent/irq_agent_pkg.sv

// CryptoLite UVM environment
../tb/env/cryptolite_env_pkg.sv
../tb/sequences/cryptolite_seq_pkg.sv
../tb/tests/cryptolite_test_pkg.sv

// Top-level UVM testbench
../tb/cryptolite_tb.sv
