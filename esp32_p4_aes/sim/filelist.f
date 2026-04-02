// AES Accelerator - Source File List

// Include paths
+incdir+../tb/agents/ahb_agent
+incdir+../tb/agents/axi_agent
+incdir+../tb/ral
+incdir+../tb/env
+incdir+../tb/sequences
+incdir+../tb/tests

// RTL Package (must be first)
../rtl/aes_accel_pkg.sv

// RTL Core
../rtl/core/aes_sbox.sv
../rtl/core/aes_mix_columns.sv
../rtl/core/aes_round.sv
../rtl/core/aes_inv_round.sv
../rtl/core/aes_key_expand.sv
../rtl/core/aes_core.sv

// RTL Modes
../rtl/modes/gf_mult_128.sv
../rtl/modes/ghash.sv
../rtl/modes/block_mode_ctrl.sv
../rtl/modes/gcm_unit.sv

// RTL Bus
../rtl/bus/ahb_slave.sv
../rtl/bus/axi_master.sv

// RTL DMA
../rtl/common/sync_fifo.sv
../rtl/dma/dma_engine.sv

// RTL Top
../rtl/aes_accel_top.sv

// TB Interfaces (must be before packages)
../tb/agents/ahb_agent/ahb_if.sv
../tb/agents/axi_agent/axi_if.sv

// Reference Model DPI (C source compiled by simulator)
../tb/ref_model/aes_ref_model_dpi.c

// TB Packages (order matters)
../tb/agents/ahb_agent/ahb_agent_pkg.sv
../tb/agents/axi_agent/axi_agent_pkg.sv
../tb/ral/aes_ral_pkg.sv
../tb/ref_model/aes_ref_model_pkg.sv
../tb/env/aes_env_pkg.sv
../tb/sequences/aes_seq_pkg.sv
../tb/tests/aes_test_pkg.sv

// SVA Assertions
../tb/sva/ahb_protocol_checker.sv
../tb/sva/aes_internal_sva.sv

// TB Top
../tb/top/tb_top.sv
