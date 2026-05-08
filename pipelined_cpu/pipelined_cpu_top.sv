// Top-level: wires together pipelined_cpu, imem, and dmem.
// Analogous to computer.sv in the professor's guide.

`include "../shared_components/imem_ireg/imem.sv"
`include "../shared_components/dmem.sv"
`include "pipelined_cpu.sv"

module pipelined_cpu_top (
    input  logic        clk,
    input  logic        reset,
    // Debug/testbench visibility
    output logic [31:0] aluoutM,
    output logic [31:0] writedataM,
    output logic        memwriteM
);

    logic [31:0] pcF, instrF, readdataM;

    pipelined_cpu cpu (
        .clk        (clk),
        .reset      (reset),
        .pcF        (pcF),
        .instrF     (instrF),
        .memwriteM  (memwriteM),
        .aluoutM    (aluoutM),
        .writedataM (writedataM),
        .readdataM  (readdataM)
    );

    // TODO: confirm addr slice matches imem address width
    instr_mem imem (
        .addr     (pcF[7:0]),
        .readdata (instrF)
    );

    dmem dmem (
        .clk (clk),
        .we  (memwriteM),
        .a   (aluoutM),
        .wd  (writedataM),
        .rd  (readdataM)
    );

endmodule
