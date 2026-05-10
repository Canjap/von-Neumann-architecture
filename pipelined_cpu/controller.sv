// Control unit: decodes opcode into pipeline control signals.
//No funct field (no R-type instructions in accumulator ISA)
//No regdst (destination is always ACC)
//aluop is 3-bit

`include "../shared_components/maindec.sv"
`include "../shared_components/alu/aludec.sv"

module controller (
    input  logic [5:0] opD,
    output logic        memtoregD,
    output logic        memwriteD,
    output logic [1:0]  alusrcD,
    output logic        regwriteD,
    output logic        branchD,
    output logic        jumpD,
    output logic [1:0]  memaddrsrcD,  // widened: 00=aluout 01=signimm 10=SP
    output logic [3:0]  alucontrolD,
    // New outputs for procedure support
    output logic        callD,
    output logic        retD,
    output logic        spwriteD,
    output logic        lrwriteD,
    output logic        usespD,
    output logic        accsrcD
);

    logic [2:0] aluopD;

    maindec md (
        .reset      (1'b0),
        .op         (opD),
        .regwrite   (regwriteD),
        .alusrc     (alusrcD),
        .memtoreg   (memtoregD),
        .memwrite   (memwriteD),
        .branch     (branchD),
        .jump       (jumpD),
        .memaddrsrc (memaddrsrcD),
        .aluop      (aluopD),
        .callout    (callD),
        .ret        (retD),
        .spwrite    (spwriteD),
        .lrwrite    (lrwriteD),
        .usesp      (usespD),
        .accsrc     (accsrcD)
    );

    aludec ad (
        .aluop      (aluopD),
        .alucontrol (alucontrolD)
    );

endmodule
