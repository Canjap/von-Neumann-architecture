module maindec(
    input  logic       reset,   // Added reset to kill signals during boot
    input  logic [5:0] op,
    output logic       memtoreg, memwrite,
    output logic       branch, alusrc,
    output logic       regwrite, jump,
    output logic [2:0] aluop
);

    always_comb begin
        if (reset) begin
            // Force everything to 0 during reset
            {regwrite, alusrc, memtoreg, memwrite, branch, jump, aluop} = 9'b0;
        end else begin
            case(op)
                6'h02: {regwrite, alusrc, memtoreg, memwrite, branch, jump, aluop} = 9'b1_1_1_0_0_0_000; // LDA
                6'h06: {regwrite, alusrc, memtoreg, memwrite, branch, jump, aluop} = 9'b1_1_0_0_0_0_000; // ADD
                6'h08: {regwrite, alusrc, memtoreg, memwrite, branch, jump, aluop} = 9'b1_1_0_0_0_0_001; // SUB
                6'h10: {regwrite, alusrc, memtoreg, memwrite, branch, jump, aluop} = 9'b1_1_0_0_0_0_110; // MULT
                6'h12: {regwrite, alusrc, memtoreg, memwrite, branch, jump, aluop} = 9'b1_1_0_0_0_0_111; // DIV
                default: {regwrite, alusrc, memtoreg, memwrite, branch, jump, aluop} = 9'b0_0_0_0_0_0_000; // NOP/Illegal
            endcase
        end
    end
endmodule