// CPU wrapper: connects controller, datapath, and hazard unit.
// Analogous to cpu.sv in the professor's guide.
// No regfile — accumulator replaces the register file entirely.

`include "controller.sv"
`include "datapath.sv"
`include "hazard.sv"

module pipelined_cpu (
    input  logic        clk,
    input  logic        reset,
    // Instruction memory interface (IF stage)
    output logic [31:0] pcF,
    input  logic [31:0] instrF,
    // Data memory interface (MEM stage)
    output logic        memwriteM,
    output logic [31:0] aluoutM,
    output logic [31:0] writedataM,
    input  logic [31:0] readdataM
);

    // Instruction decode stage — opcode fed to controller
    logic [5:0] opD;

    // Control signals (decode stage)
    logic        memtoregD, memwriteD;
    logic        alusrcD, regwriteD;
    logic        branchD, jumpD;
    logic        memaddrsrcD;
    logic [2:0]  alucontrolD;

    // Hazard unit → datapath
    logic        stallF, stallD;
    logic        flushD, flushE;
    logic [1:0]  forwardE;   // ACC forwarding mux select for EX stage

    // Datapath → hazard unit (pipeline register contents)
    logic        regwriteE, regwriteM_haz, regwriteW;
    logic        memtoregE,  memtoregM_haz;

    controller ctrl (
        .opD          (opD),
        .memtoregD    (memtoregD),
        .memwriteD    (memwriteD),
        .alusrcD      (alusrcD),
        .regwriteD    (regwriteD),
        .branchD      (branchD),
        .jumpD        (jumpD),
        .memaddrsrcD  (memaddrsrcD),
        .alucontrolD  (alucontrolD)
    );

    datapath dp (
        .clk          (clk),
        .reset        (reset),
        // Memory interfaces
        .pcF          (pcF),
        .instrF       (instrF),
        .aluoutM      (aluoutM),
        .writedataM   (writedataM),
        .readdataM    (readdataM),
        .memwriteM    (memwriteM),
        // From controller
        .memtoregD    (memtoregD),
        .memwriteD    (memwriteD),
        .alusrcD      (alusrcD),
        .regwriteD    (regwriteD),
        .branchD      (branchD),
        .jumpD        (jumpD),
        .memaddrsrcD  (memaddrsrcD),
        .alucontrolD  (alucontrolD),
        // To controller
        .opD          (opD),
        // From hazard unit
        .stallF       (stallF),
        .stallD       (stallD),
        .flushD       (flushD),
        .flushE       (flushE),
        .forwardE     (forwardE),
        // To hazard unit
        .regwriteE    (regwriteE),
        .regwriteM_dp (regwriteM_haz),
        .regwriteW    (regwriteW),
        .memtoregE    (memtoregE),
        .memtoregM_dp (memtoregM_haz)
    );

    hazard haz (
        .regwriteE  (regwriteE),
        .regwriteM  (regwriteM_haz),
        .regwriteW  (regwriteW),
        .memtoregE  (memtoregE),
        .memtoregM  (memtoregM_haz),
        .branchD    (branchD),
        .forwardE   (forwardE),
        .stallF     (stallF),
        .stallD     (stallD),
        .flushD     (flushD),
        .flushE     (flushE)
    );

endmodule
