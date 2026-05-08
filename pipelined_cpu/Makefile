PROJECT  = pipelined_cpu
TOP      = tb_pipelined_cpu
SRC      = $(TOP).sv
PROG     ?= test_prog

all: compile run

compile:
	iverilog -g2012 -o $(PROJECT).vvp $(SRC)

run:
	vvp $(PROJECT).vvp +PROG=../$(PROG).hex > debug_output.txt

clean:
	rm -f *.vvp *.vcd debug_output.txt
