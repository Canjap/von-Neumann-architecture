`include "../shared_components/maindec.sv"
`include "../shared_components/alu/aludec.sv"

module cpu_controller (
    input  logic [5:0]  op,           // instr[31:26]
    output logic        regwrite,     // 1 → write result to ACC
    output logic        memwrite,     // 1 → write ACC to dmem (STA/STSP)
    output logic        memtoreg,     // 1 → ACC ← readdata (LDA/LDSP)
    output logic [1:0]  memaddrsrc,   // 00=aluout  01=signimm  10=SP
    output logic [1:0]  alusrc,       // 00=zero  01=signimm  10=readdata
    output logic [3:0]  alucontrol,
    output logic        branch,       // BZ or BNZ
    output logic        jump,         // JMP or CALL
    output logic        callout,      // CALL: write PC+4 → LR this cycle
    output logic        ret,          // RET: PC ← LR
    output logic        spwrite,      // ADDSP: write ALU result → SP
    output logic        lrwrite,      // SETLR: write ACC → LR
    output logic        usesp,        // ADDSP: select SP as ALU input1
    output logic        accsrc        // GETLR: select LR as write-back data
);
    logic [2:0] aluop;

    maindec md (
        .reset      (1'b0),
        .op         (op),
        .regwrite   (regwrite),
        .alusrc     (alusrc),
        .memtoreg   (memtoreg),
        .memwrite   (memwrite),
        .branch     (branch),
        .jump       (jump),
        .memaddrsrc (memaddrsrc),
        .aluop      (aluop),
        .callout    (callout),
        .ret        (ret),
        .spwrite    (spwrite),
        .lrwrite    (lrwrite),
        .usesp      (usesp),
        .accsrc     (accsrc)
    );

    aludec ad (
        .aluop      (aluop),
        .alucontrol (alucontrol)
    );
endmodule
