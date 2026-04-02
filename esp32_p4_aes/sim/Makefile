# AES Accelerator - Simulation Makefile
# Supports VCS, Xcelium, and Questa

# Defaults
TEST     ?= aes_typical_128_ecb_test
SEED     ?= random
VERBOSITY ?= UVM_MEDIUM
SIM      ?= vcs

# Directories
SIM_DIR   = .
RTL_DIR   = ../rtl
TB_DIR    = ../tb
COV_DIR   = coverage

# ============================================================
# VCS
# ============================================================
ifeq ($(SIM),vcs)

COMP_OPTS = -full64 -sverilog -ntb_opts uvm-1.2 \
            -timescale=1ns/1ps \
            -f filelist.f \
            -l compile.log \
            -o simv \
            +define+UVM_NO_DEPRECATED

RUN_OPTS  = +UVM_TESTNAME=$(TEST) \
            +UVM_VERBOSITY=$(VERBOSITY) \
            +ntb_random_seed=$(SEED) \
            -l logs/$(TEST).log

COV_OPTS  = -cm line+cond+fsm+tgl+branch

compile:
	vcs $(COMP_OPTS) $(COV_OPTS)

run: compile
	@mkdir -p logs
	./simv $(RUN_OPTS) $(COV_OPTS) -cm_dir $(COV_DIR)/$(TEST).vdb

endif

# ============================================================
# Xcelium
# ============================================================
ifeq ($(SIM),xcelium)

SRC_OPTS  = -sv -uvm -uvmhome CDNS-1.2 \
            -timescale 1ns/1ps \
            -f filelist.f

COMP_OPTS = $(SRC_OPTS) -l compile.log

RUN_OPTS  = +UVM_TESTNAME=$(TEST) \
            +UVM_VERBOSITY=$(VERBOSITY) \
            +svseed=$(SEED) \
            -l logs/$(TEST).log

COV_OPTS  = -coverage all -covtest $(TEST) -covoverwrite

compile:
	xrun -compile $(COMP_OPTS) -coverage all

run:
	@mkdir -p logs
	xrun $(SRC_OPTS) $(RUN_OPTS) $(COV_OPTS)

endif

# ============================================================
# Questa
# ============================================================
ifeq ($(SIM),questa)

compile:
	vlib work
	vlog -sv +incdir+$(TB_DIR)/agents/ahb_agent \
	     +incdir+$(TB_DIR)/agents/axi_agent \
	     +incdir+$(TB_DIR)/ral \
	     +incdir+$(TB_DIR)/env \
	     +incdir+$(TB_DIR)/sequences \
	     +incdir+$(TB_DIR)/tests \
	     -f filelist.f \
	     -l compile.log

run: compile
	@mkdir -p logs
	vsim -c -do "run -all; quit" \
	     +UVM_TESTNAME=$(TEST) \
	     +UVM_VERBOSITY=$(VERBOSITY) \
	     -sv_seed $(SEED) \
	     -l logs/$(TEST).log \
	     work.tb_top

endif

# ============================================================
# Common targets
# ============================================================
regress:
	@mkdir -p logs $(COV_DIR)
	@for test in \
		aes_reg_smoke_test \
		aes_typical_128_ecb_test \
		aes_typical_256_ecb_test \
		aes_typical_consecutive_test \
		aes_dma_128_ecb_test \
		aes_dma_256_ecb_test \
		aes_dma_cbc_test \
		aes_dma_ofb_test \
		aes_dma_ctr_test \
		aes_dma_cfb_test \
		aes_dma_gcm_test \
		aes_dma_256_cbc_test \
		aes_dma_256_ofb_test \
		aes_dma_256_ctr_test \
	; do \
		echo "Running $$test..."; \
		$(MAKE) run TEST=$$test SEED=random; \
	done

coverage:
ifeq ($(SIM),vcs)
	urg -dir $(COV_DIR)/*.vdb -report $(COV_DIR)/report -format both
endif
ifeq ($(SIM),xcelium)
	imc -exec coverage_merge.tcl
endif

clean:
	rm -rf simv simv.daidir csrc *.log logs $(COV_DIR) work
	rm -rf xcelium.d waves.* *.vcd *.fsdb waves.shm
	rm -rf DVEfiles urgReport AN.DB
	rm -rf cov_work cov_report.txt html_* imc.key mdv.log
	rm -rf .bpad bpad_*.err xmsim_*.err compile.history

.PHONY: compile run regress coverage clean
