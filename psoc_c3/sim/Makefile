# PSoC Control C3 CryptoLite simulation Makefile
# Usage: make compile SIM=xcelium
#        make sim    SIM=xcelium TEST=cryptolite_aes_ecb_test
#        make regress SIM=xcelium

SIM      ?= xcelium
TOP      ?= cryptolite_top
TB_TOP  ?= cryptolite_tb
IVERILOG ?= iverilog
VVP      ?= vvp
UNIT_VU_OUT ?= vu_engine_tb.out

# Simulator-specific invocation
ifeq ($(SIM),xcelium)
  XRUN_COMPILE = -sv -uvm -access +rwc -f filelist.f -top $(TB_TOP)
  XRUN_COMMON  = -sv -uvm -timescale 1ns/1ps -access +rwc -f filelist.f -top $(TB_TOP)
  COMP  = xrun -compile $(XRUN_COMPILE)
  ELAB  = xrun -elaborate $(XRUN_COMMON)
  RUN   = xrun $(XRUN_COMMON) \
               +UVM_TESTNAME=$(TEST) \
               +UVM_VERBOSITY=UVM_MEDIUM \
               -messages
else ifeq ($(SIM),vcs)
  COMP  = vcs -full64 -sverilog -ntb_opts uvm -f filelist.f -top $(TB_TOP)
  RUN   = simv +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=UVM_MEDIUM
endif

.PHONY: compile elab sim regress unit-vu clean

compile:
	$(COMP)

sim:
	$(RUN)

regress: compile
	@for test in \
	  cryptolite_aes_ecb_test \
	  cryptolite_sha256_sch_test \
	  cryptolite_sha256_proc_test \
	  cryptolite_sha256_full_test \
	  cryptolite_trng_basic_test \
	  cryptolite_trng_vn_test \
	  cryptolite_trng_rc_test \
	  cryptolite_trng_ap_test \
	  cryptolite_vu_add_test \
	  cryptolite_vu_mul_test \
	  cryptolite_intr_test \
	  cryptolite_busy_block_test; do \
	  echo "=== Running $$test ==="; \
	  $(MAKE) sim TEST=$$test SIM=$(SIM) || exit 1; \
	done
	@echo "=== All tests passed ==="

unit-vu:
	$(IVERILOG) -g2012 -o $(UNIT_VU_OUT) \
	  ../rtl/pkg/cryptolite_pkg.sv \
	  ../rtl/vu/vu_engine.sv \
	  ../tb/vu_engine_tb.sv
	$(VVP) $(UNIT_VU_OUT)

clean:
	rm -rf xrun.log xrun.history simv* csrc *.shm *.vcd INCA_libs $(UNIT_VU_OUT)
