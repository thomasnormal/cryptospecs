# PSoC 6 Crypto Block — Simulation Makefile
# Supports: Xcelium (default), VCS, Questa
# Usage:
#   make compile            — compile RTL only
#   make run TEST=<name>    — run a single test
#   make regress            — run all regression tests
#   make coverage           — merge and generate HTML coverage report
#   make clean              — remove build artifacts

SIM        ?= xcelium
SEED       ?= 1
UVM_VERB   ?= UVM_MEDIUM
WAVE       ?= 0

TESTS := \
    crypto_reg_smoke_test

# ------------------------------------------------------------------
# Xcelium
# ------------------------------------------------------------------
ifeq ($(SIM),xcelium)

COMPILE_OPTS := \
    -sv \
    -uvm \
    -access +rwc \
    -timescale 1ns/1ps \
    -elaborate \
    -top tb_top \
    -f filelist.f \
    -f tb_filelist.f

RUN_OPTS := \
    -R \
    +UVM_TESTNAME=$(TEST) \
    +UVM_VERBOSITY=$(UVM_VERB) \
    -svseed $(SEED)

COV_OPTS := \
    -coverage all \
    -covworkdir cov_work

compile:
	xrun $(COMPILE_OPTS) $(COV_OPTS) -compile_only 2>&1 | tee compile.log

run: compile
	xrun $(COMPILE_OPTS) $(RUN_OPTS) $(COV_OPTS) \
	    -log logs/$(TEST)_$(SEED).log \
	    2>&1 | tee logs/$(TEST)_$(SEED).run.log

endif

# ------------------------------------------------------------------
# VCS
# ------------------------------------------------------------------
ifeq ($(SIM),vcs)

VCS_OPTS := \
    -sverilog \
    -ntb_opts uvm-1.2 \
    -timescale=1ns/1ps \
    -debug_access+all \
    -f filelist.f \
    -f tb_filelist.f \
    -top tb_top

compile:
	vcs $(VCS_OPTS) -o simv 2>&1 | tee compile.log

run: compile
	./simv \
	    +UVM_TESTNAME=$(TEST) \
	    +UVM_VERBOSITY=$(UVM_VERB) \
	    +ntb_random_seed=$(SEED) \
	    -l logs/$(TEST)_$(SEED).log

endif

# ------------------------------------------------------------------
# Questa
# ------------------------------------------------------------------
ifeq ($(SIM),questa)

compile:
	vlog -sv -mfcu -f filelist.f -f tb_filelist.f 2>&1 | tee compile.log
	vopt -sv tb_top -o tb_top_opt 2>&1 | tee compile.log

run: compile
	vsim -c tb_top_opt \
	    +UVM_TESTNAME=$(TEST) \
	    +UVM_VERBOSITY=$(UVM_VERB) \
	    -sv_seed $(SEED) \
	    -do "run -all; quit" \
	    -l logs/$(TEST)_$(SEED).log

endif

# ------------------------------------------------------------------
# Regression
# ------------------------------------------------------------------
regress:
	@mkdir -p logs
	@fail=0; \
	for t in $(TESTS); do \
	    echo "=== Running $$t (seed=$(SEED)) ==="; \
	    $(MAKE) run TEST=$$t SEED=$(SEED) || fail=1; \
	done; \
	[ $$fail -eq 0 ] && echo "REGRESSION PASSED" || echo "REGRESSION FAILED"; \
	exit $$fail

# ------------------------------------------------------------------
# Coverage
# ------------------------------------------------------------------
coverage:
ifeq ($(SIM),xcelium)
	imc -load cov_work -execcmd "merge -out merged_cov -runfile runs.lst"
	imc -load merged_cov -execcmd "report -html -out html_cov -metrics all"
endif

# ------------------------------------------------------------------
# Clean
# ------------------------------------------------------------------
clean:
	rm -rf simv simv.daidir csrc xcelium.d work AN.DB DVEfiles \
	    urgReport cov_work coverage html_* imc.key mdv.log \
	    waves.shm *.vcd *.fsdb .bpad bpad_*.err xmsim_*.err \
	    compile.history logs *.log *.history novas.*

.PHONY: compile run regress coverage clean
