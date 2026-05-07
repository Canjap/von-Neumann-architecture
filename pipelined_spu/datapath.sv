// Pipelined accumulator datapath — 5 stages: IF, ID, EX, MEM, WB.
// Key differences:
//   - No register file; a single ACC register replaces it
//   - One ALU input is always ACC; result always writes back to ACC
//   - Only one forwarding mux needed (ACC source for EX stage)
//   - Branch condition is ACC==0 (BZ) or ACC!=0 (BNZ), not register equality
//   - Instruction format: opcode[31:26], imm24[23:0] — no rs/rt/rd fields

`include "../shared_components/acc.sv"
`include "../shared_components/alu/alu.sv"
`include "../shared_components/alu/eqcmp.sv"
`include "../shared_components/combinatorial components/adder.sv"
`include "../shared_components/combinatorial components/sl2.sv"
`include "../shared_components/combinatorial components/signext.sv"
`include "../shared_components/combinatorial components/multiplexors/mux2.sv"
`include "../shared_components/combinatorial components/multiplexors/mux3.sv"

module datapath (
    input  logic        clk,
    input  logic        reset,

    // --- IF stage: instruction memory interface ---
    output logic [31:0] pcF,
    input  logic [31:0] instrF,

    // --- MEM stage: data memory interface ---
    output logic [31:0] aluoutM,
    output logic [31:0] writedataM,   // ACC value to store (STA)
    input  logic [31:0] readdataM,
    output logic        memwriteM,

    // --- Control signals (decode stage, from controller) ---
    input  logic        memtoregD,
    input  logic        memwriteD,
    input  logic        alusrcD,
    input  logic        regwriteD,
    input  logic        branchD,
    input  logic        jumpD,
    input  logic [2:0]  alucontrolD,

    // --- To controller: opcode of instruction in decode stage ---
    output logic [5:0]  opD,

    // --- Hazard unit interface ---
    input  logic        stallF,
    input  logic        stallD,
    input  logic        flushD,
    input  logic        flushE,
    input  logic [1:0]  forwardE,     // 00=accE  01=resultW  10=aluoutM

    // --- To hazard unit: pipeline register control bits ---
    output logic        regwriteE,
    output logic        regwriteM_dp,
    output logic        regwriteW,
    output logic        memtoregE,
    output logic        memtoregM_dp
);

    // =========================================================
    // IF STAGE
    // =========================================================
    // TODO: PC next-select mux (sequential, branch, jump)
    // TODO: PC register (stall-aware)
    // TODO: pcplus4F = pcF + 4

    // =========================================================
    // IF/ID PIPELINE REGISTER
    // =========================================================
    // Signals to latch: instrD, pcplus4D
    // Flush on: flushD or branch taken
    // Stall on: stallD
    // TODO

    logic [31:0] instrD, pcplus4D;
    assign opD = instrD[31:26];

    // =========================================================
    // ID STAGE
    // =========================================================
    // ACC is read here; branch condition evaluated against ACC
    // TODO: instantiate eqcmp — checks accD == 0 for BZ/BNZ
    // TODO: branch target = pcplus4D + (sign_ext(imm24) << 2)
    //       See isa.md: effective formula is PC_current+8 + imm*4
    // TODO: sign-extend imm24 (instrD[23:0]) to 32 bits

    // =========================================================
    // ID/EX PIPELINE REGISTER
    // =========================================================
    // Signals to latch: all control signals, accD, signimmD, pcplus4D, opD
    // Flush on: flushE
    // TODO

    // =========================================================
    // EX STAGE
    // =========================================================
    // TODO: forwarding mux on ACC input (forwardE selects accE / resultW / aluoutM)
    // TODO: srcb mux (alusrcE selects signimmE or 0)
    // TODO: instantiate alu

    // =========================================================
    // EX/MEM PIPELINE REGISTER
    // =========================================================
    // Signals to latch: regwriteM_dp, memtoregM_dp, memwriteM,
    //                   aluoutM, writedataM, pcplus4M
    // TODO

    // =========================================================
    // MEM STAGE
    // =========================================================
    // Data memory read/write driven by aluoutM (address) and writedataM (STA data)
    // No logic here beyond passing signals — dmem is instantiated in pipelined_spu_top

    // =========================================================
    // MEM/WB PIPELINE REGISTER
    // =========================================================
    // Signals to latch: regwriteW, memtoregW, readdataW, aluoutW
    // TODO

    // =========================================================
    // WB STAGE
    // =========================================================
    // TODO: resultW mux — selects aluoutW (ALU result) or readdataW (LDA)
    // TODO: feed resultW back to ACC write port (in ID stage) and forwarding mux (in EX)

endmodule
