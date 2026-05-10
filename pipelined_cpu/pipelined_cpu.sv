`include "controller.sv"
`include "datapath.sv"
`include "hazard.sv"

module pipelined_cpu (
    input  logic        clk, reset,
    output logic [31:0] pcF,
    input  logic [31:0] instrF,
    output logic [31:0] mem_addrM, aluoutM, writedataM,
    input  logic [31:0] readdataM,
    output logic        memwriteM
);
    logic memtoregD, memwriteD, regwriteD, branchD, jumpD, callD, retD, spwriteD, lrwriteD, usespD, accsrcD, forwardD;
    logic [1:0] alusrcD, memaddrsrcD, forwardE;
    logic [3:0] alucontrolD;
    logic [5:0] opD;
    logic regwriteE, regwriteM_haz, regwriteW, memtoregE, memtoregM_haz, memwriteE, spwriteE, spwriteM_haz, spwriteW, lrwriteE, lrwriteM_haz, stallF, stallD, flushD, flushE;

    controller c (.opD(opD), .memtoregD(memtoregD), .memwriteD(memwriteD), .alusrcD(alusrcD), .regwriteD(regwriteD), .branchD(branchD), .jumpD(jumpD), .memaddrsrcD(memaddrsrcD), .alucontrolD(alucontrolD), .callD(callD), .retD(retD), .spwriteD(spwriteD), .lrwriteD(lrwriteD), .usespD(usespD), .accsrcD(accsrcD));

    datapath dp (
        .clk(clk), .reset(reset), .pcF(pcF), .instrF(instrF), .mem_addrM(mem_addrM), .aluoutM(aluoutM), .writedataM(writedataM), .readdataM(readdataM), .memwriteM(memwriteM), .memtoregD(memtoregD), .memwriteD(memwriteD), .alusrcD(alusrcD), .regwriteD(regwriteD), .branchD(branchD), .jumpD(jumpD), .memaddrsrcD(memaddrsrcD), .alucontrolD(alucontrolD), .callD(callD), .retD(retD), .spwriteD(spwriteD), .lrwriteD(lrwriteD), .usespD(usespD), .accsrcD(accsrcD), .opD(opD), .stallF(stallF), .stallD(stallD), .flushD(flushD), .flushE(flushE), .forwardE(forwardE), .forwardD(forwardD), 
        .regwriteE(regwriteE), .regwriteM_dp(regwriteM_haz), .regwriteW(regwriteW), .memtoregE(memtoregE), .memtoregM_dp(memtoregM_haz), .memwriteE(memwriteE), .spwriteE(spwriteE), .spwriteM_dp(spwriteM_haz), .spwriteW_out(spwriteW), .lrwriteE(lrwriteE), .lrwriteM_dp(lrwriteM_haz)
    );

    hazard haz (
        .regwriteE(regwriteE), .regwriteM(regwriteM_haz), .regwriteW(regwriteW), .memtoregE(memtoregE), .memtoregM(memtoregM_haz), .memwriteE(memwriteE), .memaddrsrcD(memaddrsrcD), .memtoregD(memtoregD), .branchD(branchD), .usespD(usespD), .spwriteE(spwriteE), .spwriteM(spwriteM_haz), .spwriteW(spwriteW), .retD(retD), .accsrcD(accsrcD), .lrwriteE(lrwriteE), .lrwriteM(lrwriteM_haz), .forwardE(forwardE), .forwardD(forwardD), .stallF(stallF), .stallD(stallD), .flushD(flushD), .flushE(flushE)
    );
endmodule