module fetch_tb;

    reg clk;
    reg reset;
    reg stall;
    reg zero_reg; // Sequential register to bridge the timing gap

    // --- Branch & Control Signals ---
    wire branch_taken;      
    wire [31:0] branch_target;
    wire alu_zero;          
    wire regwrite, alusrc, memtoreg, memwrite, branch, jump;
    wire [1:0] aluop;       
    wire [3:0] alucontrol;  

    // --- Data & Instruction Wires ---
    wire [31:0] pc_out;
    wire [31:0] instr;
    wire [31:0] ir_out;
    wire [31:0] acc_val;
    wire [31:0] alu_out;
    wire [31:0] operand2;
    wire [31:0] read_data; 
    wire [31:0] imm_ext;

    // --- Combinational Logic ---
    wire [23:0] immediateD = ir_out[23:0];
    wire [5:0]  opcodeD    = ir_out[31:26];

    // BZ and BNZ logic
    wire is_bz = (opcodeD == 6'h04);
    wire is_bnz = (opcodeD == 6'h05);

    assign branch_taken = (is_bz && zero_reg) || (is_bnz && !zero_reg);

    // Sign-extend immediate and calculate target
    assign imm_ext = {{8{immediateD[23]}}, immediateD};
    assign branch_target = (pc_out + 4) + (imm_ext << 2);

    // Operand2 Multiplexer (ALUSRC logic)
    assign operand2 = alusrc ? {{8{ir_out[23]}}, ir_out[23:0]} : 32'b0;

    // --- Module Instantiations ---

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

    aludec ad (
        .aluop(aluop),
        .alucontrol(alucontrol)
    );

    acc #(.n(32)) main_acc (
        .clk(clk),
        .reset(reset),
        .en(regwrite),
        .d(alu_out),
        .q(acc_val)
    );

    alu #(.bitWidth(32)) dut_alu (
        .input1(acc_val),
        .input2(operand2),
        .alucontrol(alucontrol),
        .result(alu_out),
        .zero(alu_zero)
    );

    dmem data_mem (
        .clk(clk),
        .we(memwrite),
        .a(alu_out),
        .wd(acc_val),
        .rd(read_data)
    );

    pc pc_inst (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .branch_taken(branch_taken),
        .branch_target(branch_target),
        .pc_out(pc_out)
    );

    instr_mem imem (
        .addr(pc_out[7:0]),
        .readdata(instr)
    );

    instr_reg ir (
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .clear(1'b0),
        .instr_in(instr),
        .instr_out(ir_out)
    );

    // --- Clock & Reset Generation ---

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        reset = 1;
        stall = 0;
        #12 reset = 0;
        #300 $finish;
    end

    // --- Logic for Flag Synchronization ---

    always @(posedge clk or posedge reset) begin
        if (reset) 
            zero_reg <= 0;
        else
            zero_reg <= alu_zero; 
    end

// --- Enhanced Debug Logging ---
initial begin
    $display("\nTime | PC_OUT   | IR_OUT   | ACC_VAL  | ALU_OUT  | REGW | BR | ZERO_R | TAKEN | TARGET");
    $display("------------------------------------------------------------------------------------------");
    forever @(negedge clk) begin // Logging on negedge captures values after the clock transition
        $display("%4t | %h | %h | %h | %h |  %b   | %b  |   %b    |   %b   | %h", 
            $time, 
            pc_out, 
            ir_out, 
            acc_val, 
            alu_out, 
            regwrite, 
            branch, 
            zero_reg, 
            branch_taken, 
            branch_target
        );
    end
end

    initial begin
        $dumpfile("fetch.vcd");
        $dumpvars(0, fetch_tb);
    end

endmodule