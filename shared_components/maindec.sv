module maindec(
    input  logic       reset,
    input  logic [5:0] op,
    output logic       memtoreg, memwrite,
    output logic       branch, alusrc,
    output logic       regwrite, jump,
    output logic       memaddrsrc,
    output logic [2:0] aluop
);
    logic [9:0] controls;
    assign {regwrite, alusrc, memtoreg, memwrite, branch, jump, memaddrsrc, aluop} = controls;

    always_comb begin
        if (reset) controls = 10'b0000000_000;
        else begin
            case(op)
                6'h05:   controls = 10'b0_0_0_0_1_0_0_000; // BNZ
                6'h04:   controls = 10'b0_0_0_0_1_0_0_000; // BZ
                6'h06:   controls = 10'b0_0_0_0_0_1_0_000; // JMP
                6'h08:   controls = 10'b1_1_1_0_0_0_1_000; // LDA  memaddrsrc=1
                6'h02:   controls = 10'b1_1_0_0_0_0_0_000; // ADD
                6'h10:   controls = 10'b1_1_0_0_0_0_0_110; // MULT
                6'h12:   controls = 10'b1_1_0_0_0_0_0_111; // DIV
                6'h2B:   controls = 10'b0_1_0_1_0_0_1_000; // STA  memaddrsrc=1
                default: controls = 10'b0_0_0_0_0_0_0_000; // NOP
            endcase
        end
    end
endmodule