// Pipelined accumulator datapath — 5 stages: IF, ID, EX, MEM, WB.
// Key differences from a MIPS datapath:
//   - No register file; a single ACC register replaces it
//   - Only one forwarding mux needed (ACC source for EX stage)
//   - Branch condition is ACC==0 (BZ) or ACC!=0 (BNZ), evaluated in ID
//   - Instruction format: opcode[31:26], imm24[23:0] — no rs/rt/rd fields
//   - Assembler encodes branch offset as: imm = target_word - (branch_word + 2)
//     so hardware branch target = pcplus4D + 4 + (sign_ext(imm24) << 2)

`include "../shared_components/PC/PC.sv"
`include "../shared_components/acc.sv"
`include "../shared_components/alu/alu.sv"
`include "../shared_components/alu/eqcmp.sv"
`include "../shared_components/combinatorial components/adder.sv"
`include "../shared_components/combinatorial components/signext.sv"
`include "../shared_components/combinatorial components/multiplexors/mux2.sv"
`include "../shared_components/combinatorial components/multiplexors/mux3.sv"

module datapath (
    input  logic        clk,
    input  logic        reset,

    // IF stage: instruction memory interface
    output logic [31:0] pcF,
    input  logic [31:0] instrF,

    // MEM stage: data memory interface
    output logic [31:0] mem_addrM,    // muxed memory address for dmem
    output logic [31:0] aluoutM,      // raw ALU result (forwarding + debug)
    output logic [31:0] writedataM,   // ACC value to store (STA)
    input  logic [31:0] readdataM,
    output logic        memwriteM,

    // Control signals (decode stage, from controller)
    input  logic        memtoregD,
    input  logic        memwriteD,
    input  logic [1:0]  alusrcD,
    input  logic        regwriteD,
    input  logic        branchD,
    input  logic        jumpD,
    input  logic        memaddrsrcD,
    input  logic [3:0]  alucontrolD,

    // To controller: opcode of instruction in decode stage
    output logic [5:0]  opD,

    // Hazard unit interface
    input  logic        stallF,
    input  logic        stallD,
    input  logic        flushD,
    input  logic        flushE,
    input  logic [1:0]  forwardE,     // 00=accE  01=resultW  10=aluoutM

    // To hazard unit: pipeline register control bits
    output logic        regwriteE,
    output logic        regwriteM_dp,
    output logic        regwriteW,
    output logic        memtoregE,
    output logic        memtoregM_dp,
    output logic        memwriteE      // needed for M-type stall detection
);

    // ---- Forward-declared WB signals (used in EX forwarding mux) ----
    logic [31:0] resultW;   // writeback value: aluoutW or readdataW
    logic        memtoregW;
    logic [31:0] readdataW, aluoutW;

    // =========================================================
    // IF STAGE
    // =========================================================
    logic [31:0] pcplus4F;
    logic        branch_taken;
    logic [31:0] branch_target;

    pc pcreg (
        .clk          (clk),
        .reset        (reset),
        .stall        (stallF),
        .branch_taken (branch_taken),
        .branch_target(branch_target),
        .pc_out       (pcF)
    );

    assign pcplus4F = pcF + 32'd4;

    // =========================================================
    // IF/ID PIPELINE REGISTER
    // Flush on: reset, branch taken, or hazard flushD.
    // Stall on: stallD (holds current instruction).
    // =========================================================
    logic [31:0] instrD, pcplus4D;

    always_ff @(posedge clk or posedge reset) begin
        if (reset || branch_taken || flushD) begin
            instrD   <= 32'b0;
            pcplus4D <= 32'b0;
        end else if (!stallD) begin
            instrD   <= instrF;
            pcplus4D <= pcplus4F;
        end
    end

    assign opD = instrD[31:26];

    // =========================================================
    // ID STAGE
    // =========================================================
    logic [31:0] signimmD, accD;
    logic        zeroD;

    signext #(32, 24) se (.in(instrD[23:0]), .out(signimmD));
    eqcmp   #(32)     eq (.acc(accD), .zero(zeroD));

    // Assembler offset: imm = target_word - (branch_word + 2)
    // Hardware: target_byte = (branch_word + 2)*4 + imm*4
    //         = (pcplus4D + 4) + (signimmD << 2)
    assign branch_target = pcplus4D + 32'd4 + {signimmD[29:0], 2'b00};
    assign branch_taken  = jumpD
                         || (branchD && opD == 6'h04 &&  zeroD)   // BZ
                         || (branchD && opD == 6'h05 && !zeroD);  // BNZ

    // ACC register — written by WB stage, read combinatorially in ID
    acc #(32) main_acc (
        .clk  (clk),
        .reset(reset),
        .en   (regwriteW),
        .d    (resultW),
        .q    (accD)
    );

    // =========================================================
    // ID/EX PIPELINE REGISTER
    // Flush on: reset or flushE (load-use / branch stall).
    // =========================================================
    logic [1:0]  alusrcE;
    logic        memaddrsrcE;
    logic [3:0]  alucontrolE;
    logic [31:0] accE, signimmE;
    // regwriteE, memtoregE, memwriteE are outputs (declared in port list)

    always_ff @(posedge clk or posedge reset) begin
        if (reset || flushE) begin
            memtoregE   <= 1'b0;  memwriteE   <= 1'b0;
            alusrcE     <= 2'b0;  regwriteE   <= 1'b0;
            memaddrsrcE <= 1'b0;  alucontrolE <= 4'b0;
            accE        <= 32'b0; signimmE    <= 32'b0;
        end else begin
            memtoregE   <= memtoregD;   memwriteE   <= memwriteD;
            alusrcE     <= alusrcD;     regwriteE   <= regwriteD;
            memaddrsrcE <= memaddrsrcD; alucontrolE <= alucontrolD;
            accE        <= accD;        signimmE    <= signimmD;
        end
    end

    // =========================================================
    // EX STAGE
    // =========================================================
    logic [31:0] fwd_accE, srcbE, aluoutE;
    logic        zero_aluE;   // ALU zero flag (not used for branching)

    // Forwarding mux: select ACC source
    mux3 #(32) fwdmux (
        .Data0   (accE),     // 00: no hazard — use latched accE
        .Data1   (resultW),  // 01: WB-stage forward (handles LDA result too)
        .Data2   (aluoutM),  // 10: MEM-stage forward (ALU result one stage back)
        .Selector(forwardE),
        .Output  (fwd_accE)
    );

    // ALU source-B mux
    mux3 #(32) srcbmux (
        .Data0   (32'b0),     // 00: zero (used by NOP / STA address path)
        .Data1   (signimmE),  // 01: sign-extended immediate (ADD, SUB, LDA, STA)
        .Data2   (readdataM), // 10: memory read data (M-type: ADDM, SUBM, etc.)
        .Selector(alusrcE),
        .Output  (srcbE)
    );

    alu #(32) main_alu (
        .input1    (fwd_accE),
        .input2    (srcbE),
        .alucontrol(alucontrolE),
        .result    (aluoutE),
        .zero      (zero_aluE)
    );

    // =========================================================
    // EX/MEM PIPELINE REGISTER
    // =========================================================
    // regwriteM_dp, memtoregM_dp, aluoutM, writedataM, memwriteM are outputs
    logic        memaddrsrcM;
    logic [31:0] signimmM;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            regwriteM_dp <= 1'b0;  memtoregM_dp <= 1'b0;
            memwriteM    <= 1'b0;  aluoutM      <= 32'b0;
            writedataM   <= 32'b0; memaddrsrcM  <= 1'b0;
            signimmM     <= 32'b0;
        end else begin
            regwriteM_dp <= regwriteE;  memtoregM_dp <= memtoregE;
            memwriteM    <= memwriteE;  aluoutM      <= aluoutE;
            writedataM   <= fwd_accE;   // ACC value stored by STA
            memaddrsrcM  <= memaddrsrcE; signimmM    <= signimmE;
        end
    end

    // =========================================================
    // MEM STAGE
    // Address mux: LDA/STA/M-type use immediate directly; others use ALU result.
    // M-type bypass: when an M-type instruction is in EX (memaddrsrcE=1,
    // memtoregE=0), present signimmE directly to dmem so readdataM is available
    // combinatorially in the same cycle as the ALU (srcbE = readdataM).
    // The hazard unit's mstall guarantees a NOP is in MEM at this moment,
    // so the bypass never conflicts with a real memory read or write.
    // =========================================================
    logic [31:0] mem_addr_mux;
    mux2 #(32) memaddrmux (
        .Data0   (aluoutM),
        .Data1   (signimmM),
        .Selector(memaddrsrcM),
        .Output  (mem_addr_mux)
    );
    assign mem_addrM = (memaddrsrcE && !memtoregE) ? signimmE : mem_addr_mux;

    // =========================================================
    // MEM/WB PIPELINE REGISTER
    // =========================================================
    // regwriteW is an output (declared in port list)

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            regwriteW <= 1'b0; memtoregW <= 1'b0;
            readdataW <= 32'b0; aluoutW  <= 32'b0;
        end else begin
            regwriteW <= regwriteM_dp; memtoregW <= memtoregM_dp;
            readdataW <= readdataM;    aluoutW   <= aluoutM;
        end
    end

    // =========================================================
    // WB STAGE
    // =========================================================
    // resultW feeds back to: (1) acc.d for register writeback, (2) EX forwarding mux
    mux2 #(32) resultmux (
        .Data0   (aluoutW),   // 0: ALU result (ADD, SUB, MULT, etc.)
        .Data1   (readdataW), // 1: memory read data (LDA)
        .Selector(memtoregW),
        .Output  (resultW)
    );

endmodule
