module maindec(
    input  logic        reset,
    input  logic [5:0]  op,
    output logic        memtoreg, memwrite,
    output logic        branch,
    output logic [1:0]  alusrc,
    output logic        regwrite, jump,
    output logic        memaddrsrc,
    output logic [2:0]  aluop
);
    // alusrc encoding: 00=zero  01=sign_ext(imm24)  10=readdata (M-type)
    logic [10:0] controls;
    assign {regwrite, alusrc, memtoreg, memwrite, branch, jump, memaddrsrc, aluop} = controls;

    always_comb begin
        if (reset) controls = 11'b0_00_0_0_0_0_0_000;
        else begin
            case(op)
                6'h02:   controls = 11'b1_01_0_0_0_0_0_000; // ADD
                6'h03:   controls = 11'b1_10_0_0_0_0_1_000; // ADDM  alusrc=readdata
                6'h04:   controls = 11'b0_00_0_0_1_0_0_000; // BZ
                6'h05:   controls = 11'b0_00_0_0_1_0_0_000; // BNZ
                6'h06:   controls = 11'b0_00_0_0_0_1_0_000; // JMP
                6'h07:   controls = 11'b1_10_0_0_0_0_1_001; // SUBM  alusrc=readdata
                6'h08:   controls = 11'b1_01_1_0_0_0_1_000; // LDA   memaddrsrc=1
                6'h10:   controls = 11'b1_01_0_0_0_0_0_110; // MULT
                6'h11:   controls = 11'b1_10_0_0_0_0_1_110; // MULTM alusrc=readdata
                6'h12:   controls = 11'b1_01_0_0_0_0_0_111; // DIV
                6'h13:   controls = 11'b1_10_0_0_0_0_1_111; // DIVM  alusrc=readdata
                6'h2B:   controls = 11'b0_01_0_1_0_0_1_000; // STA   memaddrsrc=1
                default: controls = 11'b0_00_0_0_0_0_0_000; // NOP
            endcase
        end
    end
endmodule