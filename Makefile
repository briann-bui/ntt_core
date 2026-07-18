VCS ?= vcs
SPYGLASS ?= spyglass
URG ?= urg

TOP_MODULE ?= apb_ntt_wrapper
RTL_FILELIST ?= filelist.f

REPORT_DIR ?= reports
VCS_DIR := $(REPORT_DIR)/vcs
SPYGLASS_DIR := $(REPORT_DIR)/spyglass
UVM_DIR := $(REPORT_DIR)/vcs/uvm
COVERAGE_DIR := $(REPORT_DIR)/coverage
COVERAGE_VCS_DIR := $(REPORT_DIR)/vcs/coverage
COVERAGE_DB := $(COVERAGE_DIR)/apb_ntt.vdb
COVERAGE_REPORT := $(COVERAGE_DIR)/urg_report

LINT_PRJ ?= lint/lint.prj
CDC_PRJ ?= cdc/cdc.prj
RDC_PRJ ?= rdc/rdc.prj

VCS_FLAGS ?= -full64 -sverilog -nc -timescale=1ns/1ps +lint=all,noVCDE
UVM_TEST ?= apb_ntt_smoke_test
UVM_FILELIST ?= filelist_uvm.f
UVM_FLAGS ?= -full64 -sverilog -nc -timescale=1ns/1ps -ntb_opts uvm-1.2
COVERAGE_TESTS ?= apb_ntt_smoke_test apb_ntt_coverage_test
COVERAGE_METRICS ?= line+cond+fsm+branch
COVERAGE_THRESHOLD ?= 90

.PHONY: all check compile lint cdc rdc uvm uvm_compile uvm_run coverage coverage_compile coverage_run coverage_report clean

all: check

check: compile lint cdc rdc coverage

uvm: uvm_compile uvm_run

uvm_compile:
	@mkdir -p $(UVM_DIR)/csrc
	$(VCS) $(UVM_FLAGS) -f $(RTL_FILELIST) -f $(UVM_FILELIST) \
		-top apb_ntt_tb_top \
		-Mdir=$(UVM_DIR)/csrc \
		-o $(UVM_DIR)/simv \
		-l $(REPORT_DIR)/uvm_compile.log

uvm_run:
	@test -x $(UVM_DIR)/simv || { echo "Run 'make uvm_compile' first"; exit 1; }
	$(UVM_DIR)/simv +UVM_TESTNAME=$(UVM_TEST) +UVM_VERBOSITY=UVM_LOW \
		-l $(REPORT_DIR)/uvm.log
	@! grep -Eq 'UVM_(FATAL|ERROR)[[:space:]]*:[[:space:]]*[1-9]' $(REPORT_DIR)/uvm.log
	@{ \
		echo "APB NTT UVM summary"; \
		echo "Status: PASS"; \
		echo "Test: $(UVM_TEST)"; \
		echo "Top: apb_ntt_tb_top"; \
		echo "Full log: $(REPORT_DIR)/uvm.log"; \
	} > $(REPORT_DIR)/uvm_summary.rpt

coverage: coverage_compile coverage_run coverage_report

coverage_compile:
	rm -rf $(COVERAGE_DIR) $(COVERAGE_VCS_DIR)
	@mkdir -p $(COVERAGE_DIR) $(COVERAGE_VCS_DIR)/csrc
	$(VCS) $(UVM_FLAGS) -cm $(COVERAGE_METRICS) -cm_seqnoconst \
		-cm_hier uvm/coverage_hierarchy.cfg \
		-cm_fsmresetfilter uvm/fsm_reset_filter.cfg \
		-cm_dir $(COVERAGE_DB) \
		-f $(RTL_FILELIST) -f $(UVM_FILELIST) \
		-top apb_ntt_tb_top \
		-Mdir=$(COVERAGE_VCS_DIR)/csrc \
		-o $(COVERAGE_VCS_DIR)/simv \
		-l $(REPORT_DIR)/coverage_compile.log

coverage_run:
	@set -e; \
	for test in $(COVERAGE_TESTS); do \
		log="$(REPORT_DIR)/coverage_$${test}.log"; \
		$(COVERAGE_VCS_DIR)/simv +UVM_TESTNAME=$$test +UVM_VERBOSITY=UVM_LOW \
			-cm $(COVERAGE_METRICS) -cm_name $$test -cm_dir $(COVERAGE_DB) \
			-l $$log; \
		if grep -Eq 'UVM_(FATAL|ERROR)[[:space:]]*:[[:space:]]*[1-9]' $$log; then exit 1; fi; \
	done

coverage_report:
	$(URG) -dir $(COVERAGE_DB) -metric $(COVERAGE_METRICS)+group \
		-report $(COVERAGE_REPORT) -format both -show tests
	@cp $(COVERAGE_REPORT)/dashboard.txt $(REPORT_DIR)/coverage_dashboard.rpt
	@score=$$(awk '/Total Coverage Summary/{getline; getline; print $$1; exit}' $(COVERAGE_REPORT)/dashboard.txt); \
		awk -v score="$$score" -v threshold="$(COVERAGE_THRESHOLD)" \
			'BEGIN { if (score < threshold) exit 1; }'; \
		{ \
			echo "APB NTT coverage summary"; \
			echo "Status: PASS"; \
			echo "Threshold: $(COVERAGE_THRESHOLD)%"; \
			echo "Tests: $(COVERAGE_TESTS)"; \
			sed -n '/Total Coverage Summary/,+2p' $(COVERAGE_REPORT)/dashboard.txt; \
		} > $(REPORT_DIR)/coverage_summary.rpt
	@echo "Coverage summary: $(REPORT_DIR)/coverage_summary.rpt"

compile:
	@mkdir -p $(VCS_DIR)/compile/csrc
	$(VCS) $(VCS_FLAGS) -f $(RTL_FILELIST) -top $(TOP_MODULE) \
		-Mdir=$(VCS_DIR)/compile/csrc \
		-o $(VCS_DIR)/compile/simv \
		-l $(REPORT_DIR)/compile.log
	@{ \
		echo "APB NTT VCS compile summary"; \
		echo "Status: PASS"; \
		echo "Top: $(TOP_MODULE)"; \
		echo "File list: $(RTL_FILELIST)"; \
		echo "Full log: $(REPORT_DIR)/compile.log"; \
	} > $(REPORT_DIR)/compile_summary.rpt

lint:
	@mkdir -p $(SPYGLASS_DIR)/lint
	@cp $(LINT_PRJ) $(SPYGLASS_DIR)/lint/lint.prj
	$(SPYGLASS) -batch -project $(SPYGLASS_DIR)/lint/lint.prj \
		-goals "lint/lint_rtl" > $(REPORT_DIR)/lint.log 2>&1
	@report=$$(find $(SPYGLASS_DIR)/lint -path '*/lint/lint_rtl/spyglass_reports/moresimple.rpt' -print -quit); \
		test -n "$$report"; cp "$$report" $(REPORT_DIR)/lint_summary.rpt
	@! grep -Eq '[[:space:]](Fatal|Error)[[:space:]]' $(REPORT_DIR)/lint_summary.rpt
	@echo "Lint summary: $(REPORT_DIR)/lint_summary.rpt"

cdc:
	@mkdir -p $(SPYGLASS_DIR)/cdc
	@cp $(CDC_PRJ) $(SPYGLASS_DIR)/cdc/cdc.prj
	$(SPYGLASS) -batch -project $(SPYGLASS_DIR)/cdc/cdc.prj \
		-goals "cdc/cdc_setup_check,cdc/cdc_verify" > $(REPORT_DIR)/cdc.log 2>&1
	@report=$$(find $(SPYGLASS_DIR)/cdc -path '*/cdc/cdc_verify/spyglass_reports/moresimple.rpt' -print -quit); \
		test -n "$$report"; cp "$$report" $(REPORT_DIR)/cdc_summary.rpt
	@! grep -Eq '[[:space:]](Fatal|Error)[[:space:]]' $(REPORT_DIR)/cdc_summary.rpt
	@echo "CDC summary: $(REPORT_DIR)/cdc_summary.rpt"

rdc:
	@mkdir -p $(SPYGLASS_DIR)/rdc
	@cp $(RDC_PRJ) $(SPYGLASS_DIR)/rdc/rdc.prj
	$(SPYGLASS) -batch -project $(SPYGLASS_DIR)/rdc/rdc.prj \
		-goals "rdc/rdc_verify_struct" > $(REPORT_DIR)/rdc.log 2>&1
	@report=$$(find $(SPYGLASS_DIR)/rdc -path '*/rdc/rdc_verify_struct/spyglass_reports/moresimple.rpt' -print -quit); \
		test -n "$$report"; cp "$$report" $(REPORT_DIR)/rdc_summary.rpt
	@! grep -Eq '[[:space:]](Fatal|Error)[[:space:]]' $(REPORT_DIR)/rdc_summary.rpt
	@echo "RDC summary: $(REPORT_DIR)/rdc_summary.rpt"

clean:
	rm -rf $(VCS_DIR) $(SPYGLASS_DIR) $(COVERAGE_DIR)
	rm -rf csrc simv simv.daidir DVEfiles AN.DB novas.conf novas.rc verdiLog
	rm -rf lint/lint cdc/cdc rdc/rdc
	rm -f ucli.key vc_hdrs.h tr_db.log spyglass.log transcript .fsm.sch.verilog.xml
	rm -f *.vpd *.vcd *.fsdb *.wlf *.vstf *.ucdb *.log
	@echo "Removed generated work files; kept the main reports in reports/."
