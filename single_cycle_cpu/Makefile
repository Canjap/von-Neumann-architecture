PROG  ?= factorial
TEST  ?= $(PROG)
HEX   ?= ../assembler/$(PROG).hex

.PHONY: all run clean

all: tb_sc_cpu.vvp

tb_sc_cpu.vvp: tb_sc_cpu.sv
	iverilog -g2012 -o $@ $<

run: tb_sc_cpu.vvp
	vvp $< +PROG=$(HEX) +TEST=$(TEST)

clean:
	rm -f tb_sc_cpu.vvp tb_sc_cpu.vcd
