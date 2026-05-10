PROJECT  = pipelined_cpu
TOP      = tb_pipelined_cpu
SRC      = $(TOP).sv
PROG     ?= test_prog

# Include paths to shared resources
INCLUDES = -I. -I../shared_components -I../shared_components/imem_ireg -I../shared_components/alu -I../shared_components/combinatorial\ components

all: compile run

compile:
	iverilog -g2012 $(INCLUDES) -o $(PROJECT).vvp $(SRC)

run:
	vvp $(PROJECT).vvp +PROG=../assembler/$(PROG).hex > debug_output.txt

waves: 
	gtkwave $(TOP).vcd

clean:
	rm -f *.vvp *.vcd debug_output.txt