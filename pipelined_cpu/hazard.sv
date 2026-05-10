// Hazard detection and forwarding unit — accumulator architecture.
//
// Forwarding priority: MEM-stage result over WB-stage result.
//
// Load-use stall (lwstall): LDA in EX needs 1 extra cycle before consumer
//   can use readdataW from WB via forward 01.
//
// M-type stall (mstall): ADDM/SUBM/MULTM/DIVM in ID.
//   alusrcE=10 (srcbE = readdataM) in EX. The datapath bypasses signimmE
//   directly to dmem when M-type is in EX, so readdataM is available
//   combinatorially. Stall for 1 cycle when M-type is in ID and EX contains
//   any instruction that writes ACC or memory (regwriteE || memwriteE).
//   mstall checks memaddrsrcD == 2'b01 to avoid triggering on STSP/LDSP.
//
// Branch stall (branchstall): branch in ID cannot safely read ACC if a write
//   is still in EX, or an LDA result is still in MEM.
//
// SP stall (spstall): STSP, LDSP, or a second ADDSP in ID cannot safely use
//   the SP register value if a prior ADDSP result is still in EX/MEM/WB.
//   Stall until spwriteW clears (ADDSP has exited WB and SP is current).
//
// LR stall (lrstall): RET or GETLR in ID cannot safely read LR if SETLR
//   is still in EX or MEM. (CALL writes LR directly in ID — no hazard.)
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
    input  logic [1:0] memaddrsrcD, // 2'b01=M-type/LDA/STA  2'b10=SP-based
    input  logic       memtoregD,   // 1 = LDA in ID
    input  logic       branchD,     // 1 = branch in ID
    // New signals for SP/LR hazards
    input  logic       usespD,      // 1 = ADDSP in ID (reads SP as ALU input)
    input  logic       spwriteE,    // 1 = ADDSP in EX
    input  logic       spwriteM,    // 1 = ADDSP in MEM
    input  logic       spwriteW,    // 1 = ADDSP in WB
    input  logic       retD,        // 1 = RET in ID (reads LR)
    input  logic       accsrcD,     // 1 = GETLR in ID (reads LR)
    input  logic       lrwriteE,    // 1 = SETLR in EX
    input  logic       lrwriteM,    // 1 = SETLR in MEM
    input  logic       lrwriteW,    // 1 = SETLR in WB

    // Forwarding select for ACC input in EX stage
    // 2'b00 = use accE  (no hazard)
    // 2'b01 = forward resultW  from WB
    // 2'b10 = forward aluoutM  from MEM (priority)
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

    // Load-use stall: LDA in EX
    logic lwstall;
    assign lwstall = memtoregE;

    // M-type stall: ADDM/SUBM/MULTM/DIVM in ID (memaddrsrcD==2'b01, memtoregD=0)
    logic mstall;
    assign mstall = (memaddrsrcD == 2'b01 && !memtoregD) && (regwriteE || memwriteE);

    // Branch stall: stall BZ/BNZ while any register write is in EX, MEM, or
    // WB.  regwriteM is needed (not just memtoregM) because at the posedge
    // where WB commits, combinatorial branch_taken still sees the OLD accD;
    // the extra stall ensures ACC is stable before the branch evaluates.
    logic branchstall;
    assign branchstall = branchD && (regwriteE || regwriteM);

    // SP stall: any instruction that reads SP (STSP/LDSP: memaddrsrcD==2'b10,
    // or ADDSP: usespD) must wait until a prior ADDSP has cleared WB.
    logic spstall;
    assign spstall = (memaddrsrcD == 2'b10 || usespD) && (spwriteE || spwriteM || spwriteW);

    // LR stall: RET (retD) or GETLR (accsrcD) reads LR; stall while SETLR in EX/MEM.
    logic lrstall;
    assign lrstall = (retD || accsrcD) && (lrwriteE || lrwriteM || lrwriteW);

    logic stall;
    assign stall  = lwstall || mstall || branchstall || spstall || lrstall;
    assign stallF = stall;
    assign stallD = stall;
    assign flushE = stall;
    assign flushD = 1'b0;  // branch flush handled in datapath via branch_taken

endmodule
