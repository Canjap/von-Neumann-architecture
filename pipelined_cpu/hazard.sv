// Hazard detection and forwarding unit — accumulator architecture.
// Simpler than the MIPS version because there is only one register (ACC):
//   - No rs/rt/rd tracking needed — every instruction uses ACC
//   - One forwarding mux (forwardE) instead of two (forwardaE, forwardbE)
//   - Load-use stall: if LDA is in EX (memtoregE=1), next instruction must wait 1 cycle
//   - Branch stall: if a regwrite instruction is in EX or MEM when a branch is in ID

module hazard (
    // Pipeline register visibility
    input  logic       regwriteE,
    input  logic       regwriteM,
    input  logic       regwriteW,
    input  logic       memtoregE,   // 1 = LDA is in EX stage
    input  logic       memtoregM,
    input  logic       branchD,     // 1 = branch instruction is in ID stage

    // Forwarding select for ACC input in EX stage
    // 2'b00 = use accE (latched from ID/EX register, no hazard)
    // 2'b01 = forward resultW from WB stage
    // 2'b10 = forward aluoutM from MEM stage
    output logic [1:0] forwardE,

    // Stall / flush control
    output logic       stallF,
    output logic       stallD,
    output logic       flushD,
    output logic       flushE
);

    // TODO: ACC forwarding logic
    // Priority: MEM-stage forward (aluoutM) takes precedence over WB-stage (resultW)
    // always_comb begin
    //     forwardE = 2'b00;
    //     if      (regwriteM) forwardE = 2'b10;  // EX→EX: result available from MEM
    //     else if (regwriteW) forwardE = 2'b01;  // MEM→EX: result available from WB
    // end

    // TODO: load-use stall (LDA in EX, any instruction in ID needs ACC)
    // logic lwstall;
    // assign lwstall = memtoregE;  // ACC is always needed, so stall whenever LDA is in EX

    // TODO: branch stall (branch in ID, preceding write still in EX or MEM)
    // logic branchstall;
    // assign branchstall = branchD && (regwriteE || memtoregM);

    // TODO: drive stall/flush signals
    // assign stallD  = lwstall || branchstall;
    // assign stallF  = stallD;
    // assign flushE  = stallD;
    // assign flushD  = 1'b0;  // only needed if branches flush decode stage

endmodule
