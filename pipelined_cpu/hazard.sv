// Hazard detection and forwarding unit — accumulator architecture.
//
// Forwarding priority: MEM-stage result over WB-stage result.
//
// Load-use stall (lwstall): LDA in EX needs 1 extra cycle before consumer
//   can use readdataW from WB via forward 01.
//
// M-type stall (mstall): ADDM/SUBM/MULTM/DIVM in ID.
//   These instructions use alusrcE=10 (srcbE = readdataM) in EX.
//   The datapath bypasses signimmE directly to dmem when M-type is in EX,
//   so readdataM is available combinatorially in the same cycle.
//   BUT the bypass conflicts if MEM simultaneously holds a real memory access.
//   Stall for 1 cycle when M-type is in ID and EX contains any instruction
//   that writes ACC or memory (regwriteE || memwriteE). This guarantees a
//   NOP bubble is in MEM by the time the M-type reaches EX.
//
// Branch stall (branchstall): branch in ID cannot safely read ACC if a write
//   is still in EX, or an LDA result is still in MEM.
//
// Branch flush: handled inside the datapath (branch_taken flushes IF/ID).

module hazard (
    // Pipeline register visibility — from datapath
    input  logic       regwriteE,
    input  logic       regwriteM,
    input  logic       regwriteW,
    input  logic       memtoregE,   // 1 = LDA is in EX
    input  logic       memtoregM,   // 1 = LDA is in MEM
    input  logic       memwriteE,   // 1 = STA is in EX

    // Decode-stage control signals — from controller (via pipelined_cpu)
    input  logic       memaddrsrcD, // 1 = instruction uses direct immediate address
    input  logic       memtoregD,   // 1 = instruction is a load (LDA)

    // Branch signal — from controller
    input  logic       branchD,     // 1 = branch instruction is in ID

    // Forwarding select for ACC input in EX stage
    // 2'b00 = use accE  (no hazard)
    // 2'b01 = forward resultW  from WB (includes LDA: resultW = readdataW)
    // 2'b10 = forward aluoutM  from MEM (ALU result one stage back)
    output logic [1:0] forwardE,

    // Stall / flush control
    output logic       stallF,
    output logic       stallD,
    output logic       flushD,
    output logic       flushE
);

    // ACC forwarding: MEM-stage takes priority (more recent)
    always_comb begin
        if      (regwriteM) forwardE = 2'b10;
        else if (regwriteW) forwardE = 2'b01;
        else                forwardE = 2'b00;
    end

    // Load-use stall: LDA in EX, next instruction needs ACC
    logic lwstall;
    assign lwstall = memtoregE;

    // M-type stall: ADDM/SUBM/MULTM/DIVM in ID (memaddrsrcD=1, memtoregD=0),
    // and EX holds a real instruction (not a NOP bubble) that would conflict
    // with the EX→dmem address bypass.
    logic mstall;
    assign mstall = (memaddrsrcD && !memtoregD) && (regwriteE || memwriteE);

    // Branch stall: branch in ID needs correct ACC; stall while a write is
    // in EX or an LDA result is still in MEM.
    logic branchstall;
    assign branchstall = branchD && (regwriteE || memtoregM);

    logic stall;
    assign stall  = lwstall || mstall || branchstall;
    assign stallF = stall;
    assign stallD = stall;
    assign flushE = stall;
    assign flushD = 1'b0;  // branch flush handled in datapath via branch_taken

endmodule
