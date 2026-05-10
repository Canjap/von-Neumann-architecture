`include "../shared_components/PC/PC.sv"
`include "../shared_components/acc.sv"
`include "../shared_components/alu/alu.sv"
`include "../shared_components/alu/eqcmp.sv"
`include "../shared_components/combinatorial components/adder.sv"
`include "../shared_components/combinatorial components/signext.sv"
`include "../shared_components/combinatorial components/multiplexors/mux2.sv"
`include "../shared_components/combinatorial components/multiplexors/mux3.sv"

module datapath (
    input  logic        clk, reset,
    output logic [31:0] pcF,
    input  logic [31:0] instrF,
    output logic [31:0] mem_addrM, aluoutM, writedataM,
    input  logic [31:0] readdataM,
    output logic        memwriteM,
    input  logic        memtoregD, memwriteD, regwriteD, branchD, jumpD,
    input  logic [1:0]  memaddrsrcD, alusrcD,
    input  logic [3:0]  alucontrolD,
    input  logic        callD, retD, spwriteD, lrwriteD, usespD, accsrcD,
    output logic [5:0]  opD,
    input  logic        stallF, stallD, flushD, flushE, forwardD,
    input  logic [1:0]  forwardE,
    output logic        regwriteE, regwriteM_dp, regwriteW,
    output logic        memtoregE, memtoregM_dp, memwriteE,
    output logic        spwriteE, spwriteM_dp, spwriteW_out,
    output logic        lrwriteE, lrwriteM_dp
);
    logic [31:0] resultW, readdataW, aluoutW, lrW_reg;
    logic memtoregW, spwriteW, lrwriteW, accsrcW;

    // IF STAGE
    logic [31:0] pcplus4F, branch_target;
    logic branch_taken;
    pc pcreg (.clk(clk), .reset(reset), .stall(stallF), .branch_taken(branch_taken), .branch_target(branch_target), .pc_out(pcF));
    assign pcplus4F = pcF + 32'd4;

    // IF/ID
    logic [31:0] instrD, pcplus4D;
    always_ff @(posedge clk or posedge reset) begin
        if (reset || branch_taken || flushD) begin 
            instrD <= 0; 
            pcplus4D <= 0; 
        end else if (!stallD) begin 
            instrD <= instrF; 
            pcplus4D <= pcplus4F; 
        end
    end
    assign opD = instrD[31:26];

    // ID STAGE
    logic [31:0] signimmD, accD, acc_for_cmpD, lr, sp;
    logic zeroD;
    signext #(32, 24) se (.in(instrD[23:0]), .out(signimmD));
    
    mux2 #(32) brfwdmux (.Data0(accD), .Data1(aluoutM), .Selector(forwardD), .Output(acc_for_cmpD));
    eqcmp #(32) eq (.acc(acc_for_cmpD), .zero(zeroD));

    assign branch_target = retD ? lr : (pcplus4D + 32'd4 + {signimmD[29:0], 2'b00});
    assign branch_taken  = jumpD || retD || (branchD && opD == 6'h04 && zeroD) || (branchD && opD == 6'h05 && !zeroD);
    
    acc #(32) main_acc (.clk(clk), .reset(reset), .en(regwriteW), .d(resultW), .q(accD));

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            lr <= 32'b0;
            sp <= 32'h100;
        end else begin 
            if (callD) lr <= pcplus4D; else if (lrwriteW) lr <= resultW;
            if (spwriteW) sp <= resultW; 
        end
    end

    // ID/EX
    logic [1:0] alusrcE, memaddrsrcE;
    logic [3:0] alucontrolE;
    logic [31:0] accE, signimmE, lrE, spE;
    logic usespE, accsrcE;
    always_ff @(posedge clk or posedge reset) begin
        if (reset || flushE) begin
            {memtoregE, memwriteE, regwriteE, spwriteE, lrwriteE, usespE, accsrcE} <= 7'b0;
            {alusrcE, memaddrsrcE} <= 4'b0; alucontrolE <= 4'b0; {accE, signimmE, lrE, spE} <= 128'b0;
        end else begin
            memtoregE <= memtoregD; memwriteE <= memwriteD; alusrcE <= alusrcD; regwriteE <= regwriteD;
            memaddrsrcE <= memaddrsrcD; alucontrolE <= alucontrolD; accE <= accD; signimmE <= signimmD;
            spwriteE <= spwriteD; lrwriteE <= lrwriteD; usespE <= usespD; accsrcE <= accsrcD;
            {lrE, spE} <= {lr, sp};
        end
    end

    // EX STAGE
    logic [31:0] fwd_accE, alu_in1, srcbE, aluoutE_val;
    mux3 #(32) fwdmux (.Data0(accE), .Data1(resultW), .Data2(aluoutM), .Selector(forwardE), .Output(fwd_accE));
    mux2 #(32) a1mux (.Data0(fwd_accE), .Data1(spE), .Selector(usespE), .Output(alu_in1));
    mux3 #(32) sbux (.Data0(32'b0), .Data1(signimmE), .Data2(readdataM), .Selector(alusrcE), .Output(srcbE));
    alu #(32) main_alu (.input1(alu_in1), .input2(srcbE), .alucontrol(alucontrolE), .result(aluoutE_val));

    // EX/MEM
    logic [1:0] memaddrsrcM;
    logic [31:0] signimmM, spM, lrM_val;
    logic accsrcM;
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            {regwriteM_dp, memtoregM_dp, memwriteM, spwriteM_dp, lrwriteM_dp, accsrcM} <= 6'b0;
            {aluoutM, writedataM, signimmM, lrM_val, spM} <= 160'b0; memaddrsrcM <= 2'b0;
        end else begin
            regwriteM_dp <= regwriteE; memtoregM_dp <= memtoregE; memwriteM <= memwriteE; aluoutM <= aluoutE_val;
            writedataM <= fwd_accE; 
            memaddrsrcM <= memaddrsrcE; signimmM <= signimmE; {spwriteM_dp, lrwriteM_dp, accsrcM} <= {spwriteE, lrwriteE, accsrcE};
            {lrM_val, spM} <= {lrE, spE};
        end
    end

    // MEM STAGE
    logic [31:0] m_mux;
    mux3 #(32) maddrmux (.Data0(aluoutM), .Data1(signimmM), .Data2(spM), .Selector(memaddrsrcM), .Output(m_mux));
    assign mem_addrM = (memaddrsrcE == 2'b01 && !memtoregE) ? signimmE : m_mux;

    // MEM/WB
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin {regwriteW, memtoregW, spwriteW, lrwriteW, accsrcW} <= 5'b0; {readdataW, aluoutW, lrW_reg} <= 96'b0; end
        else begin 
            {regwriteW, memtoregW, spwriteW, lrwriteW, accsrcW} <= {regwriteM_dp, memtoregM_dp, spwriteM_dp, lrwriteM_dp, accsrcM};
            {readdataW, aluoutW, lrW_reg} <= {readdataM, aluoutM, lrM_val}; 
        end
    end

    // WB STAGE
    mux3 #(32) resmux (.Data0(aluoutW), .Data1(readdataW), .Data2(lrW_reg), .Selector({accsrcW, memtoregW}), .Output(resultW));
    assign spwriteW_out = spwriteW;
endmodule