// Top-level: wires together pipelined_cpu, imem, and dmem.

`include "../shared_components/imem_ireg/imem.sv"
`include "../shared_components/dmem.sv"
`include "pipelined_cpu.sv"

module pipelined_cpu_top (
    input  logic        clk,
    input  logic        reset,
    // Debug/testbench visibility
    output logic [31:0] mem_addrM,    // actual memory address sent to dmem
    output logic [31:0] aluoutM,      // raw ALU result
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
        .mem_addrM  (mem_addrM),
        .aluoutM    (aluoutM),
        .writedataM (writedataM),
        .readdataM  (readdataM)
    );

    instr_mem imem (
        .addr     (pcF[7:0]),
        .readdata (instrF)
    );

    dmem dmem (
        .clk (clk),
        .we  (memwriteM),
        .a   (mem_addrM),   // muxed address: sign_ext(imm) for LDA/STA, aluout otherwise
        .wd  (writedataM),
        .rd  (readdataM)
    );

endmodule
