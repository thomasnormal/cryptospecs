// PSoC 6 Crypto Block — Phase 1 filelist
// Add new files here as each phase is implemented.
// Run: xrun -f filelist.f -f tb_filelist.f (or vcs / questa equivalent)

// ---- Packages (must be first) ----
+incdir+../rtl/pkg
../rtl/pkg/crypto_pkg.sv
../rtl/pkg/crypto_isa_pkg.sv

// ---- Control / infrastructure ----
../rtl/ctrl/sync_fifo.sv
../rtl/ctrl/instr_fifo.sv
../rtl/ctrl/reg_buffer.sv
../rtl/ctrl/mem_buffer.sv
../rtl/ctrl/load_store_fifo.sv
../rtl/ctrl/instr_decoder.sv

// ---- Top-level / bus ----
../rtl/top/ahb_slave.sv
../rtl/top/ahb_master.sv
../rtl/top/crypto_top.sv

// ---- Phase 2: AES cipher ----
../rtl/cipher/aes_sbox.sv
../rtl/cipher/aes_mix_columns.sv
../rtl/cipher/aes_round.sv
../rtl/cipher/aes_inv_round.sv
../rtl/cipher/aes_key_expand.sv
../rtl/cipher/aes_core.sv

// ---- Phase 3: Hash engines ----
../rtl/hash/sha1_core.sv
../rtl/hash/sha2_256_core.sv
../rtl/hash/sha2_512_core.sv
../rtl/hash/sha3_keccak.sv

// ---- Phase 4: CRC + PRNG ----
../rtl/rng/crc_engine.sv
../rtl/rng/prng_engine.sv

// ---- Phase 5: TRNG ----
// ../rtl/rng/trng_core.sv
// ../rtl/rng/trng_health_mon.sv

// ---- Phase 6: DES/TDES ----
// ../rtl/cipher/des_core.sv

// ---- Phase 6: GCM (used by AES GCM mode) ----
// ../rtl/cipher/gf_mult_128.sv
// ../rtl/cipher/ghash.sv

// ---- Phase 7: Vector Unit ----
// ../rtl/vu/vu_register_file.sv
// ../rtl/vu/vu_alu.sv
// ../rtl/vu/vu_shifter.sv
// ../rtl/vu/vu_multiplier.sv
// ../rtl/vu/vu_controller.sv
// ../rtl/vu/vu_top.sv
