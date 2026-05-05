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