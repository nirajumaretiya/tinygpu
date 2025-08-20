.PHONY: test test_% test_%_icarus verilator_lint compile

export LIBPYTHON_LOC=$(shell cocotb-config --libpython)

# SystemVerilog sources
SV_SRCS := $(abspath $(wildcard src/*.sv))

# Default: run tests with Verilator
test_%:
	make compile
	PATH=/home/niraj/tinygpu/verilator/bin:$$PATH \
	$(MAKE) -f $$(cocotb-config --makefiles)/Makefile.sim \
	  SIM=verilator TOPLEVEL_LANG=verilog TOPLEVEL=gpu MODULE=test.test_$* \
	  VERILOG_SOURCES="$(abspath build/gpu.v)" \
	  EXTRA_ARGS="--timing --trace -Wno-fatal -Wno-PINCONNECTEMPTY -Wno-WIDTHTRUNC -Wno-UNUSEDPARAM -Wno-UNUSEDSIGNAL -Wno-UNSIGNED -Wno-CASEINCOMPLETE -Wno-WIDTHEXPAND -Wno-ASCRANGE" \
	  WAVES=1

# # Legacy Icarus flow (kept for reference)
# test_%_icarus:
# 	make compile
# 	iverilog -o build/sim.vvp -s gpu -g2012 build/gpu.v
# 	MODULE=test.test_$* vvp -M $$(cocotb-config --prefix)/cocotb/libs -m libcocotbvpi_icarus build/sim.vvp

compile:
	make compile_alu
	sv2v -I src/* -w build/gpu.v
	echo "" >> build/gpu.v
	cat build/alu.v >> build/gpu.v
	echo '`timescale 1ns/1ns' > build/temp.v
	cat build/gpu.v >> build/temp.v
	mv build/temp.v build/gpu.v

compile_%:
	sv2v -w build/$*.v src/$*.sv

# TODO: Get gtkwave visualizaiton

# show_%: %.vcd %.gtkw
# 	gtkwave $^

# Optional: run Verilator lint on raw SV (no sv2v)
verilator_lint:
	PATH=/home/niraj/tinygpu/verilator/bin:$$PATH \
	verilator -Wall --sv --lint-only $(SV_SRCS) | cat