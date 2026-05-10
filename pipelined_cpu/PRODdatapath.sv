// Pipelined accumulator datapath — 5 stages: IF, ID, EX, MEM, WB.
// Key differences from a MIPS datapath:
//   - No register file; a single ACC register replaces it
//   - Only one forwarding mux needed (ACC source for EX stage)
//   - Branch condition is ACC==0 (BZ) or ACC!=0 (BNZ), evaluated in ID
//   - Instruction format: opcode[31:26], imm24[23:0] — no rs/rt/rd fields
//   - Assembler encodes branch offset as: imm = target_word - (branch_word + 2)
//     so hardware branch target = pcplus4D + 4 + (sign_ext(imm24) << 2)
//
// P1-P3 extensions:
//   - LR (Link Register): written by CALL in ID, by SETLR in WB
//   - SP (Stack Pointer): written by ADDSP in WB, reset to 0x100
//   - memaddrsrc widened to 2-bit: 2'b10 = use SP as memory address
//   - ADDSP uses alu1mux to route SP as ALU input1
//   - resultmux extended to mux3: {accsrcW, memtoregW} selects LR for GETLR

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
    output logic [31:0] writedataM,   // ACC value to store (STA/STSP)
    input  logic [31:0] readdataM,
    output logic        memwriteM,

    // Control signals (decode stage, from controller)
    input  logic        memtoregD,
    input  logic        memwriteD,
    input  logic [1:0]  alusrcD,
    input  logic        regwriteD,
    input  logic        branchD,
    input  logic        jumpD,
    input  logic [1:0]  memaddrsrcD,  // 00=aluout 01=signimm 10=SP
    input  logic [3:0]  alucontrolD,
    // New procedure control signals
    input  logic        callD,        // CALL: write pcplus4D → LR in ID
    input  logic        retD,         // RET: PC ← LR
    input  logic        spwriteD,     // ADDSP: write ALU result → SP
    input  logic        lrwriteD,     // SETLR: write resultW → LR
    input  logic        usespD,       // ADDSP: use SP as ALU input1
    input  logic        accsrcD,      // GETLR: select LR as resultW

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
    output logic        memwriteE,    // needed for M-type stall detection
    // New hazard visibility signals
    output logic        spwriteE,
    output logic        spwriteM_dp,
    output logic        spwriteW_out,  // ADDSP in WB — needed by hazard spstall
    output logic        lrwriteE,
    output logic        lrwriteM_dp
);

    // ---- Forward-declared WB signals (used in EX forwarding mux and register writes) ----
    logic [31:0] resultW;
    logic        memtoregW;
    logic [31:0] readdataW, aluoutW;
    logic        spwriteW, lrwriteW;
    logic        accsrcW;
    logic [31:0] lrW;

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

    // LR and SP are readable combinatorially in ID (like accD)
    logic [31:0] lr, sp;

    // Assembler offset: imm = target_word - (branch_word + 2)
    // Hardware: target = (pcplus4D + 4) + (signimmD << 2)
    // RET overrides target with LR.
    assign branch_target = retD ? lr : (pcplus4D + 32'd4 + {signimmD[29:0], 2'b00});
    assign branch_taken  = jumpD || retD
                         || (branchD && opD == 6'h04 &&  zeroD)   // BZ
                         || (branchD && opD == 6'h05 && !zeroD);  // BNZ


    always @(posedge clk) begin
        if (branch_taken && !reset) begin
            $display("t=%0t | BRANCH TAKEN: Target=%h | PC_Decode=%h", 
                    $time, branch_target, pcplus4D-4);
        end
    end

    // ACC register — written by WB stage, read combinatorially in ID
    acc #(32) main_acc (
        .clk  (clk),
        .reset(reset),
        .en   (regwriteW),
        .d    (resultW),
        .q    (accD)
    );

    // LR (Link Register)
    // CALL writes pcplus4D directly in ID (no pipeline hazard for CALL→RET).
    // SETLR writes resultW from WB.
    always_ff @(posedge clk or posedge reset) begin
        if (reset)          lr <= 32'b0;
        else if (callD)     lr <= pcplus4D;
        else if (lrwriteW)  lr <= resultW;
    end

    // SP (Stack Pointer) — resets to 0x100 (top of 256-byte dmem space)
    always_ff @(posedge clk or posedge reset) begin
        if (reset)         sp <= 32'h100;
        else if (spwriteW) sp <= resultW;
    end

    // =========================================================
    // ID/EX PIPELINE REGISTER
    // Flush on: reset or flushE (any stall type).
    // =========================================================
    logic [1:0]  alusrcE;
    logic [1:0]  memaddrsrcE;
    logic [3:0]  alucontrolE;
    logic [31:0] accE, signimmE;
    logic        usespE, accsrcE;
    logic [31:0] lrE, spE;
    // regwriteE, memtoregE, memwriteE, spwriteE, lrwriteE are outputs (port list)

    always_ff @(posedge clk or posedge reset) begin
        if (reset || flushE) begin
            memtoregE    <= 1'b0;  memwriteE    <= 1'b0;
            alusrcE      <= 2'b0;  regwriteE    <= 1'b0;
            memaddrsrcE  <= 2'b0;  alucontrolE  <= 4'b0;
            accE         <= 32'b0; signimmE     <= 32'b0;
            spwriteE     <= 1'b0;  lrwriteE     <= 1'b0;
            usespE       <= 1'b0;  accsrcE      <= 1'b0;
            lrE          <= 32'b0; spE          <= 32'b0;
        end else begin
            memtoregE    <= memtoregD;    memwriteE    <= memwriteD;
            alusrcE      <= alusrcD;      regwriteE    <= regwriteD;
            memaddrsrcE  <= memaddrsrcD;  alucontrolE  <= alucontrolD;
            accE         <= accD;         signimmE     <= signimmD;
            spwriteE     <= spwriteD;     lrwriteE     <= lrwriteD;
            usespE       <= usespD;       accsrcE      <= accsrcD;
            lrE          <= lr;           spE          <= sp;
        end
    end

    // =========================================================
    // EX STAGE
    // =========================================================
    logic [31:0] fwd_accE, alu_input1, srcbE, aluoutE;
    logic        zero_aluE;

    // Forwarding mux: select ACC source
    mux3 #(32) fwdmux (
        .Data0   (accE),     // 00: no hazard — use latched accE
        .Data1   (resultW),  // 01: WB-stage forward
        .Data2   (aluoutM),  // 10: MEM-stage forward
        .Selector(forwardE),
        .Output  (fwd_accE)
    );

    // ALU input1 mux: fwd_accE normally, spE for ADDSP
    mux2 #(32) alu1mux (
        .Data0   (fwd_accE),
        .Data1   (spE),
        .Selector(usespE),
        .Output  (alu_input1)
    );

    // ALU source-B mux
    mux3 #(32) srcbmux (
        .Data0   (32'b0),     // 00: zero (NOP / STA address path)
        .Data1   (signimmE),  // 01: sign-extended immediate
        .Data2   (readdataM), // 10: memory read data (M-type)
        .Selector(alusrcE),
        .Output  (srcbE)
    );

    alu #(32) main_alu (
        .input1    (alu_input1),
        .input2    (srcbE),
        .alucontrol(alucontrolE),
        .result    (aluoutE),
        .zero      (zero_aluE)
    );

    // Insert around line 84
    always @(posedge clk) begin
        if (!reset) begin
            $display("t=%0t | EX Stage: ALU Out=%h | Fwd ACC=%h | ForwardE=%b", 
                    $time, aluoutE, fwd_accE, forwardE);
            if (regwriteW)
                $display("t=%0t | WB Stage: Writing ACC Result=%h", $time, resultW);
        end
    end

    // =========================================================
    // EX/MEM PIPELINE REGISTER
    // =========================================================
    logic [1:0]  memaddrsrcM;
    logic [31:0] signimmM;
    logic        accsrcM;
    logic [31:0] lrM, spM;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            regwriteM_dp  <= 1'b0;  memtoregM_dp  <= 1'b0;
            memwriteM     <= 1'b0;  aluoutM       <= 32'b0;
            writedataM    <= 32'b0; memaddrsrcM   <= 2'b0;
            signimmM      <= 32'b0; spwriteM_dp   <= 1'b0;
            lrwriteM_dp   <= 1'b0;  accsrcM       <= 1'b0;
            lrM           <= 32'b0; spM           <= 32'b0;
        end else begin
            regwriteM_dp  <= regwriteE;    memtoregM_dp  <= memtoregE;
            memwriteM     <= memwriteE;    aluoutM       <= aluoutE;
            writedataM    <= fwd_accE;     memaddrsrcM   <= memaddrsrcE;
            signimmM      <= signimmE;     spwriteM_dp   <= spwriteE;
            lrwriteM_dp   <= lrwriteE;    accsrcM       <= accsrcE;
            lrM           <= lrE;          spM           <= spE;
        end
    end

    // =========================================================
    // MEM STAGE
    // Address mux3: 2'b00=aluoutM, 2'b01=signimmM, 2'b10=spM
    // M-type bypass: when M-type is in EX (memaddrsrcE==2'b01 && !memtoregE),
    //   present signimmE directly to dmem so readdataM is available
    //   combinatorially as srcbE. The mstall guarantees NOP is in MEM.
    // =========================================================
    logic [31:0] mem_addr_mux;
    mux3 #(32) memaddrmux (
        .Data0   (aluoutM),
        .Data1   (signimmM),
        .Data2   (spM),
        .Selector(memaddrsrcM),
        .Output  (mem_addr_mux)
    );
    assign mem_addrM = (memaddrsrcE == 2'b01 && !memtoregE) ? signimmE : mem_addr_mux;

    // =========================================================
    // MEM/WB PIPELINE REGISTER
    // =========================================================

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            regwriteW <= 1'b0; memtoregW <= 1'b0;
            readdataW <= 32'b0; aluoutW  <= 32'b0;
            spwriteW  <= 1'b0;  lrwriteW <= 1'b0;
            accsrcW   <= 1'b0;  lrW      <= 32'b0;
        end else begin
            regwriteW <= regwriteM_dp; memtoregW <= memtoregM_dp;
            readdataW <= readdataM;    aluoutW   <= aluoutM;
            spwriteW  <= spwriteM_dp;  lrwriteW  <= lrwriteM_dp;
            accsrcW   <= accsrcM;      lrW       <= lrM;
        end
    end

    // =========================================================
    // WB STAGE
    // resultmux: {accsrcW, memtoregW}
    //   2'b00 → aluoutW   (ADD, ADDSP, MULT, etc.)
    //   2'b01 → readdataW (LDA, LDSP)
    //   2'b10 → lrW       (GETLR)
    // resultW feeds: (1) acc.d  (2) EX forwarding mux
    //               (3) sp register when spwriteW=1
    //               (4) lr register when lrwriteW=1
    // =========================================================
    mux3 #(32) resultmux (
        .Data0   (aluoutW),
        .Data1   (readdataW),
        .Data2   (lrW),
        .Selector({accsrcW, memtoregW}),
        .Output  (resultW)
    );

    assign spwriteW_out = spwriteW;

endmodule
