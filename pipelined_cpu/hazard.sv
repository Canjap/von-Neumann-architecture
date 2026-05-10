module hazard (
    input  logic       regwriteE, regwriteM, regwriteW,
    input  logic       memtoregE, memtoregM,
    input  logic       memwriteE,
    input  logic [1:0] memaddrsrcD,
    input  logic       memtoregD,
    input  logic       branchD,
    input  logic       usespD, 
    input  logic       spwriteE, spwriteM, spwriteW,
    input  logic       retD, 
    input  logic       accsrcD, 
    input  logic       lrwriteE, lrwriteM,
    output logic [1:0] forwardE,
    output logic       forwardD, 
    output logic       stallF, stallD, flushD, flushE
);
    // ACC Forwarding to EX stage (for ALU ops)
    always_comb begin
        if      (regwriteM) forwardE = 2'b10;
        else if (regwriteW) forwardE = 2'b01;
        else                forwardE = 2'b00;
    end

    // Forwarding to ID stage for Branch logic
    assign forwardD = branchD && regwriteM;

    // Stall logic
    logic lwstall, branchstall, spstall, lrstall, mstall, stall;
    
    assign lwstall = memtoregE;
    assign branchstall = branchD && (regwriteE || memtoregM);
    assign mstall = (memaddrsrcD == 2'b01 && !memtoregD) && (regwriteE || memwriteE);
    assign spstall = (memaddrsrcD == 2'b10 || usespD) && (spwriteE || spwriteM || spwriteW);
    assign lrstall = (retD || accsrcD) && (lrwriteE || lrwriteM);

    assign stall  = lwstall || mstall || branchstall || spstall || lrstall;
    assign stallF = stall;
    assign stallD = stall;
    assign flushE = stall;
    assign flushD = 1'b0; 

endmodule