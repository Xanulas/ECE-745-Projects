export ECE745_PROJECT_HOME ?= $(PWD)/../../..

include $(ECE745_PROJECT_HOME)/verification_ip/data_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/wb_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/ncsu_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/enviornment_packages/i2cmb_env_pkg/Makefile

clean: 
	rm -rf work *.wlf transcript *.ucdb

comp_I2C_MB:
	vcom -cover bcefst ../rtl/iicmb_int_pkg.vhd
	vcom -cover bcefst ../rtl/iicmb_pkg.vhd
	vcom -cover bcefst ../rtl/mbyte.vhd
	vcom -cover bcefst ../rtl/mbit.vhd
	vcom -cover bcefst ../rtl/bus_state.vhd
	vcom -cover bcefst ../rtl/filter.vhd
	vcom -cover bcefst ../rtl/conditioner.vhd
	vcom -cover bcefst ../rtl/conditioner_mux.vhd
	vcom -cover bcefst ../rtl/iicmb_m.vhd
	vcom -cover bcefst ../rtl/regblock.vhd
	vcom -cover bcefst ../rtl/wishbone.vhd
	vcom -cover bcefst ../rtl/iicmb_m_wb.vhd

comp_bench: comp_ncsu_pkg comp_data_pkg comp_wb_pkg comp_i2c_pkg comp_i2cmb_env_pkg
	vlog ../testbench/top.sv

optimize:
	vopt +acc top -o optimized_debug_top_tb

compile: clean comp_I2C_MB comp_bench optimize

simulate:
	vsim  -i -classdebug -msgmode both -do "set NoQuitOnFinish 1; do wave.do" optimized_debug_top_tb

simulate_display:
	vsim  -c -classdebug -msgmode both -do "set NoQuitOnFinish 1; do wave.do" optimized_debug_top_tb	

debug: clean compile simulate

display: clean compile simulate_display


TEST_SEED ?= 1234567890
CLI_DO_COMMANDS = -do " \
                    set NoQuitOnFinish 1; \
                    run -all; \
	 	            do save_coverage.do $(GEN_TRANS_TYPE); \
                    quit -f;" 

DEBUG_DO_COMMANDS = -do " \
                    set NoQuitOnFinish 1; \
                    do wave.do;\
                    run -a;"\

# run_cli:
# 	vsim -c -coverage -sv_seed $(TEST_SEED) $(CLI_DO_COMMANDS) +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) optimized_debug_top_tb



run_gui:
	vsim -coverage -sv_seed $(TEST_SEED) $(DEBUG_DO_COMMANDS) +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) optimized_debug_top_tb

cli: clean compile optimize run_cli

debug_gui: clean compile optimize run_gui

merge_coverage:
	xml2ucdb -format Excel ./i2cmb_test_plan.xml ./i2cmb_test_plan.ucdb
	vcover merge -stats=none -strip 0 -totals sim_and_testplan_merged.ucdb ./*.ucdb 

regress:
	./regress.sh

view_coverage:
	vsim -viewcov ./sim_and_testplan_merged.ucdb

debug_coverage: cli merge_coverage view_coverage

run_cli:
	vsim  -c -sv_seed $(TEST_SEED) -coverage -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(GEN_TRANS_TYPE); coverage save $(GEN_TRANS_TYPE).$(TEST_SEED).ucdb; quit -f" +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) optimized_debug_top_tb

