module fetch_tb;

reg clk;
reg reset;
reg stall;
reg branch_taken;
wire [31:0] branch_target;
assign branch_target = 32'b0;

wire [31:0] pc_out;
wire [31:0] instr;
wire [31:0] ir_out;

wire [23:0] immediateD = ir_out[23:0];
wire [5:0]  opcodeD    = ir_out[31:26];
wire [31:0] acc_val;
wire [31:0] alu_out;
wire [31:0] operand2;
// reg         acc_we;

assign operand2 = {8'b0, ir_out[23:0]}; // Zero-extended

// used to test ALU manually
// reg [3:0] manual_alu_control;


// --- Control Signals --- Decoder
wire regwrite, alusrc, memtoreg, memwrite, branch, jump;
wire [2:0] aluop;
wire [3:0] alucontrol;


// --- Main Decoder ---
maindec md (
    .reset(reset),
    .op(opcodeD),
    .regwrite(regwrite),
    .alusrc(alusrc),
    .memtoreg(memtoreg),
    .memwrite(memwrite),
    .branch(branch),
    .jump(jump),
    .aluop(aluop)
);

// --- ALU Decoder ---
aludec ad (
    .aluop(aluop),
    .alucontrol(alucontrol)
);

// --- The Accumulator ---
acc #(.n(32)) main_acc (
    .clk(clk),
    .reset(reset),
    .en(regwrite),      // We'll set this to 1 for this test
    .d(alu_out),
    .q(acc_val)
);

// --- The ALU ---
alu #(.bitWidth(32)) dut_alu (
    .input1(acc_val),  // ACC provides the current running total
    .input2(operand2), // Instruction provides the value to add/sub
    .alucontrol(alucontrol),
    .result(alu_out),
    .zero(alu_zero)
);

// clock
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// reset sequence
initial begin
    reset = 1;
    #12 reset = 0;
    #100 $finish;
end

initial begin
    stall = 0;
    branch_taken = 0;
end

// PC
pc pc_inst (
    .clk(clk),
    .reset(reset),
    .stall(stall),
    .branch_taken(branch_taken),
    .branch_target(branch_target),
    .pc_out(pc_out)
);


// Instruction memory
instr_mem imem (
    .addr(pc_out[7:0]),
    .readdata(instr)
);

// Instruction register
instr_reg ir (
    .clk(clk),
    .reset(reset),
    .en(1'b1),      // 1 means "never stall" for now
    .clear(1'b0),   // 0 means "never flush" for now
    .instr_in(instr),
    .instr_out(ir_out)
);

// waveform dump
initial begin
    $dumpfile("fetch.vcd");
    $dumpvars(0, fetch_tb);
end

endmodule