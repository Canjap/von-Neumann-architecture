module spu_top(
    input  logic        clk, reset,
    output logic [31:0] pc,
    input  logic [31:0] instr,
    output logic        memwrite,
    output logic [31:0] aluout, writedata,
    input  logic [31:0] readdata
);

    logic alusrc, acc_write;
    logic [3:0] alucontrol;

    // Connect the Controller
    spu_controller c(
        .opcode(instr[31:26]),
        .memwrite(memwrite),
        .alusrc(alusrc),
        .acc_write(acc_write),
        .alucontrol(alucontrol)
    );

    // Connect the Datapath
    spu_datapath dp(
        .clk(clk),
        .reset(reset),
        .alusrc(alusrc),
        .acc_write(acc_write),
        .alucontrol(alucontrol),
        .pc(pc),
        .instr(instr),
        .aluout(aluout),
        .writedata(writedata),
        .readdata(readdata)
    );

endmodule
