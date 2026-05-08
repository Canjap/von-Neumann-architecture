
module spu_datapath(
    input  logic        clk, reset,
    input  logic        alusrc, acc_write,
    input  logic [3:0]  alucontrol,
    output logic [31:0] pc,            // Connected to imem address
    input  logic [31:0] instr,         // From imem
    output logic [31:0] aluout,        // Connected to dmem address
    output logic [31:0] writedata,     // Connected to dmem write data
    input  logic [31:0] readdata       // From dmem
);

    // Internal signals
    logic [31:0] acc_q; 

    // --- 1. Program Counter Logic ---
    // Using your specific PC.sv module
    pc pcreg(
        .clk(clk),
        .reset(reset),
        .stall(1'b0),            // Not used in single cycle; tied to 0
        .branch_taken(1'b0),     // Tied to 0 (extend later for BEQ)
        .branch_target(32'b0),   // Tied to 0
        .pc_out(pc)              // This is the current address for imem
    );

    // --- 2. The Accumulator (Your unique acc.sv) ---
    acc main_acc(
        .clk(clk),
        .reset(reset),
        .en(acc_write),
        .d(aluout),   // ALU result loops back to become the new Acc value
        .q(acc_q)     // Current Acc value goes to ALU input 1
    );

    // --- 3. Memory Write Logic ---
    // For STA (Store) instructions, we send the Accumulator value to Data Memory
    assign writedata = acc_q;

    // --- 4. The Arithmetic Logic Unit (Teacher's alu.sv) ---
    // Note: alusrc is present for future expansion (like immediate values),
    // but for now, we primarily use readdata (Memory) as Input 2.
    alu main_alu(
        .input1(acc_q),      // Operand 1 is always the Accumulator
        .input2(readdata),   // Operand 2 is data from Memory
        .alucontrol(alucontrol),
        .result(aluout),
        .zero()              // Zero flag output (unused for basic LDA/STA/ADD)
    );

endmodule
