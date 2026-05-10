module cpu_top (
    input  logic        clk, reset,
    output logic [31:0] pc,
    input  logic [31:0] instr,
    output logic        memwrite,
    output logic [31:0] dmem_addr,
    output logic [31:0] writedata,
    input  logic [31:0] readdata
);

    logic [5:0]  op;
    logic [1:0]  alusrc;
    logic [3:0]  alucontrol;
    logic        regwrite;
    logic        memtoreg;
    logic [1:0]  memaddrsrc;
    logic        branch, jump;
    logic        callout, ret, spwrite, lrwrite, usesp, accsrc;

    assign op = instr[31:26];

    cpu_controller c (
        .op         (op),
        .regwrite   (regwrite),
        .memwrite   (memwrite),
        .memtoreg   (memtoreg),
        .memaddrsrc (memaddrsrc),
        .alusrc     (alusrc),
        .alucontrol (alucontrol),
        .branch     (branch),
        .jump       (jump),
        .callout    (callout),
        .ret        (ret),
        .spwrite    (spwrite),
        .lrwrite    (lrwrite),
        .usesp      (usesp),
        .accsrc     (accsrc)
    );

    cpu_datapath dp (
        .clk        (clk),
        .reset      (reset),
        .alusrc     (alusrc),
        .regwrite   (regwrite),
        .alucontrol (alucontrol),
        .memtoreg   (memtoreg),
        .memaddrsrc (memaddrsrc),
        .branch     (branch),
        .jump       (jump),
        .callout    (callout),
        .ret        (ret),
        .spwrite    (spwrite),
        .lrwrite    (lrwrite),
        .usesp      (usesp),
        .accsrc     (accsrc),
        .op         (op),
        .pc         (pc),
        .instr      (instr),
        .dmem_addr  (dmem_addr),
        .writedata  (writedata),
        .readdata   (readdata)
    );

endmodule
