module maindec(
    input  logic       reset,
    input  logic [5:0] op,
    output logic       memtoreg, memwrite,
    output logic       branch, alusrc,
    output logic       regwrite, jump,
    output logic [1:0] aluop 
);
    logic [7:0] controls;
    assign {regwrite, alusrc, memtoreg, memwrite, branch, jump, aluop} = controls;

    always_comb begin
        if (reset) controls = 8'b00000000;
        else begin
            case(op)
                // alusrc=0 ensures check Acc, not Acc vs Offset
                6'h05:   controls = 8'b0_0_0_0_1_0_00; // BNZ (Same control as BZ)
                6'h04:   controls = 8'b0_0_0_0_1_0_00; // BZ
                6'h08:   controls = 8'b1_1_1_0_0_0_00; // LDA
                6'h02:   controls = 8'b1_1_0_0_0_0_00; // ADD
                6'h10:   controls = 8'b1_1_0_0_0_0_10; // MULT
                6'h12:   controls = 8'b1_1_0_0_0_0_11; // DIV
                6'h2B:   controls = 8'b0_1_0_1_0_0_00; // STA
                default: controls = 8'b0_0_0_0_0_0_00; // NOP
            endcase
        end
    end
endmodule