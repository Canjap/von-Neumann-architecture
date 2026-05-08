// Hazard detection and forwarding unit — accumulator architecture.
// Only one register (ACC), so every instruction is a potential hazard source/sink.
//
// Forwarding priority: MEM-stage result over WB-stage result.
// Load-use stall: LDA in EX needs 1 extra cycle before consumer can proceed.
// Branch stall:   branch in ID cannot evaluate ACC if a write is still in EX,
//                 or an LDA result is still in MEM (not yet in WB).
// Branch flush:   handled internally in the datapath (branch_taken flushes IF/ID).
// M-type stall:   TODO — ADDM/SUBM/MULTM/DIVM need readdata before EX.

module hazard (
    // Pipeline register visibility
    input  logic       regwriteE,
    input  logic       regwriteM,
    input  logic       regwriteW,
    input  logic       memtoregE,   // 1 = LDA is in EX stage
    input  logic       memtoregM,   // 1 = LDA is in MEM stage
    input  logic       branchD,     // 1 = branch instruction is in ID stage

    // Forwarding select for ACC input in EX stage
    // 2'b00 = use accE  (no hazard)
    // 2'b01 = forward resultW  from WB (handles LDA: resultW = readdataW)
    // 2'b10 = forward aluoutM  from MEM (ALU result one stage back)
    output logic [1:0] forwardE,

    // Stall / flush control
    output logic       stallF,
    output logic       stallD,
    output logic       flushD,
    output logic       flushE
);

    // ACC forwarding: MEM-stage takes priority (more recent result)
    always_comb begin
        if      (regwriteM) forwardE = 2'b10;
        else if (regwriteW) forwardE = 2'b01;
        else                forwardE = 2'b00;
    end

    // Load-use stall: LDA in EX, any following instruction needs ACC
    logic lwstall;
    assign lwstall = memtoregE;

    // Branch stall: branch in ID needs ACC, but a write is still in-flight
    logic branchstall;
    assign branchstall = branchD && (regwriteE || memtoregM);

    logic stall;
    assign stall  = lwstall || branchstall;
    assign stallF = stall;
    assign stallD = stall;
    assign flushE = stall;
    assign flushD = 1'b0;  // branch flush handled in datapath via branch_taken

endmodule
