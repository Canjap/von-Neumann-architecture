// Control unit: decodes opcode into pipeline control signals.
//No funct field (no R-type instructions in accumulator ISA)
//No regdst (destination is always ACC)
//aluop is 3-bit

`include "../shared_components/maindec.sv"
`include "../shared_components/alu/aludec.sv"

module controller (
    input  logic [5:0] opD,
    output logic       memtoregD,
    output logic       memwriteD,
    output logic       alusrcD,
    output logic       regwriteD,
    output logic       branchD,
    output logic       jumpD,
    output logic [2:0] alucontrolD
);

    logic [2:0] aluopD;

    maindec md (
        .reset    (1'b0),
        .op       (opD),
        .regwrite (regwriteD),
        .alusrc   (alusrcD),
        .memtoreg (memtoregD),
        .memwrite (memwriteD),
        .branch   (branchD),
        .jump     (jumpD),
        .aluop    (aluopD)
    );

    aludec ad (
        .aluop      (aluopD),
        .alucontrol (alucontrolD)
    );

endmodule
