module pc_tb;

reg clk;
reg reset;
reg stall;
reg branch_taken;
reg [31:0] branch_target;
wire [31:0] pc_out;

pc uut (
    .clk(clk),
    .reset(reset),
    .stall(stall),
    .branch_taken(branch_taken),
    .branch_target(branch_target),
    .pc_out(pc_out)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10ns clock
end

initial begin

    $dumpfile("pc.vcd");
    $dumpvars(0, pc_tb);
    
    reset = 1; stall = 0; branch_taken = 0; branch_target = 0;
    #10 reset = 0;

    // normal increment
    #30;

    // branch
    branch_taken = 1;
    branch_target = 32'h00000020;
    #10;

    branch_taken = 0;
    #30;

    $finish;
end

endmodule