basic workflow - can be shell script w nec fixes
    iverilog -o cpu_sim src/*.v tests/cpu_tb.v
    vvp cpu_sim
    gtkwave tests/waveforms/cpu_test.vcd