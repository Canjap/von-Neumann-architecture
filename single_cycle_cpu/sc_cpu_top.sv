// Simulation top: wires cpu_top with instruction and data memories.

`include "../shared_components/imem_ireg/imem.sv"
`include "../shared_components/dmem.sv"
`include "cpu_top.sv"
`include "cpu_controller.sv"
`include "cpu_datapath.sv"
`include "acc.sv"
`include "alu.sv"
`include "mux2.sv"
`include "PC.sv"

module sc_cpu_top (
    input  logic        clk,
    input  logic        reset,
    // Debug / testbench visibility
    output logic [31:0] mem_addr,
    output logic [31:0] writedata,
    output logic        memwrite
);

    logic [31:0] pc, instr, readdata;

    cpu_top cpu (
        .clk       (clk),
        .reset     (reset),
        .pc        (pc),
        .instr     (instr),
        .memwrite  (memwrite),
        .dmem_addr (mem_addr),
        .writedata (writedata),
        .readdata  (readdata)
    );

    instr_mem imem (
        .addr     (pc[7:0]),
        .readdata (instr)
    );

    dmem dmem_inst (
        .clk (clk),
        .we  (memwrite),
        .a   (mem_addr),
        .wd  (writedata),
        .rd  (readdata)
    );

endmodule
