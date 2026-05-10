// CPU wrapper: connects controller, datapath, and hazard unit.
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
    output logic [31:0] mem_addrM,    // muxed address for dmem
    output logic [31:0] aluoutM,      // raw ALU result (debug)
    output logic [31:0] writedataM,
    input  logic [31:0] readdataM
);

    // Instruction decode stage — opcode fed to controller
    logic [5:0] opD;

    // Control signals (decode stage)
    logic        memtoregD, memwriteD;
    logic [1:0]  alusrcD;
    logic        regwriteD;
    logic        branchD, jumpD;
    logic [1:0]  memaddrsrcD;   // widened to 2 bits
    logic [3:0]  alucontrolD;
    // New procedure control signals
    logic        callD, retD;
    logic        spwriteD, lrwriteD;
    logic        usespD, accsrcD;

    // Hazard unit → datapath
    logic        stallF, stallD;
    logic        flushD, flushE;
    logic [1:0]  forwardE;

    // Datapath → hazard unit (pipeline register contents)
    logic        regwriteE, regwriteM_haz, regwriteW;
    logic        memtoregE,  memtoregM_haz;
    logic        memwriteE_dp;
    logic        spwriteE_dp, spwriteM_dp2, spwriteW_dp;
    logic        lrwriteE_dp, lrwriteM_dp2;

    controller ctrl (
        .opD          (opD),
        .memtoregD    (memtoregD),
        .memwriteD    (memwriteD),
        .alusrcD      (alusrcD),
        .regwriteD    (regwriteD),
        .branchD      (branchD),
        .jumpD        (jumpD),
        .memaddrsrcD  (memaddrsrcD),
        .alucontrolD  (alucontrolD),
        .callD        (callD),
        .retD         (retD),
        .spwriteD     (spwriteD),
        .lrwriteD     (lrwriteD),
        .usespD       (usespD),
        .accsrcD      (accsrcD)
    );

    datapath dp (
        .clk          (clk),
        .reset        (reset),
        // Memory interfaces
        .pcF          (pcF),
        .instrF       (instrF),
        .mem_addrM    (mem_addrM),
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
        .callD        (callD),
        .retD         (retD),
        .spwriteD     (spwriteD),
        .lrwriteD     (lrwriteD),
        .usespD       (usespD),
        .accsrcD      (accsrcD),
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
        .memtoregM_dp (memtoregM_haz),
        .memwriteE    (memwriteE_dp),
        .spwriteE     (spwriteE_dp),
        .spwriteM_dp  (spwriteM_dp2),
        .spwriteW_out (spwriteW_dp),
        .lrwriteE     (lrwriteE_dp),
        .lrwriteM_dp  (lrwriteM_dp2)
    );

    hazard haz (
        .regwriteE   (regwriteE),
        .regwriteM   (regwriteM_haz),
        .regwriteW   (regwriteW),
        .memtoregE   (memtoregE),
        .memtoregM   (memtoregM_haz),
        .memwriteE   (memwriteE_dp),
        .memaddrsrcD (memaddrsrcD),
        .memtoregD   (memtoregD),
        .branchD     (branchD),
        .usespD      (usespD),
        .spwriteE    (spwriteE_dp),
        .spwriteM    (spwriteM_dp2),
        .spwriteW    (spwriteW_dp),
        .retD        (retD),
        .accsrcD     (accsrcD),
        .lrwriteE    (lrwriteE_dp),
        .lrwriteM    (lrwriteM_dp2),
        .forwardE    (forwardE),
        .stallF      (stallF),
        .stallD      (stallD),
        .flushD      (flushD),
        .flushE      (flushE)
    );

endmodule
