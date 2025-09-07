TEST_MODULE?=dma_system

TOP_MODULE?=$(TEST_MODULE)_tb_top

RGGEN_SV_RTL_ROOT ?= ./rggen-sv-rtl/
export RGGEN_SV_RTL_ROOT


FILE_LIST?=file.f

UVM_TEST?=base_test

UVM_VERBOSITY?=UVM_MEDIUM
NO_OF_TRANSACTIONS?=1

ifeq ($(OS),Windows_NT)
    RM_CMD = powershell if (Test-Path $(TEST_MODULE)) { Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $(TEST_MODULE) }
else
    RM_CMD = rm -rf $(TEST_MODULE)
endif

all: clean run_uvm

run_uvm: 
# 	mkdir $(TEST_MODULE)
	qrun -verbose -lint=default -parallel -vlog.sv \
		-vopt.access=rw+/. \
		-f $(FILE_LIST) \
		+define+NO_OF_TRANSACTIONS=$(NO_OF_TRANSACTIONS) \
		+define+UVM_NO_DEPRECATED \
		+define+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR \
		-top $(TOP_MODULE) \
		+UVM_TESTNAME=$(UVM_TEST) \
		+UVM_VERBOSITY=$(UVM_VERBOSITY) \
		-coverage +cover=bcestf \
		-cvgperinstance	\
		-sva -assertdebug \
		-outdir $(TEST_MODULE) \
		-l $(TEST_MODULE)/qrun.log \
		-designfile $(TEST_MODULE)/$(TEST_MODULE).bin \
		-qwavedb=+memory=all+cell+signal+assertion+class+wavefile=$(TEST_MODULE)/$(TEST_MODULE).db \
		-do "coverage save -onexit $(TEST_MODULE)/$(UVM_TEST)_0.ucdb; run -all; quit -f"

report_coverage: 
	@echo ""
	@echo "=============== COVERAGE SUMMARY ==============="
	vcover report -summary $(TEST_MODULE)/$(UVM_TEST)_0.ucdb
	@echo "================================================"

report_html: 
	@echo ""
	@echo "=============== GENERATING HTML REPORT ==============="
	vcover report -html -details -output $(TEST_MODULE)/coverage_html -annotate  $(UVM_TEST)_0.ucdb
	@echo "HTML report generated in: $(TEST_MODULE)/coverage_html"
	@echo "===================================================="

clean:
	$(RM_CMD)

run_no_uvm:	
# 	mkdir $(TEST_MODULE)
	qrun -verbose -lint=default -parallel -vlog.sv \
		-vopt.access=rw+/. \
		-f $(FILE_LIST) \
		-top $(TOP_MODULE) \
		-outdir $(TEST_MODULE) \
		-l $(TEST_MODULE)/qrun.log \
		-designfile $(TEST_MODULE)/$(TEST_MODULE).bin \
		-qwavedb=+memory=all+assertion+cell+signal+class+wavefile=$(TEST_MODULE)/$(TEST_MODULE).db

.PHONY: all clean run_uvm