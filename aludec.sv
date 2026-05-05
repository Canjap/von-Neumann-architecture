module aludec(
    input  logic [2:0] aluop,
    output logic [3:0] alucontrol
);
    always_comb begin
        case(aluop)
            3'b000:  alucontrol = 4'b0010; // ADD (LDA, ADD)
            3'b001:  alucontrol = 4'b0110; // SUB
            3'b010:  alucontrol = 4'b0000; // AND
            3'b011:  alucontrol = 4'b0001; // OR
            3'b100:  alucontrol = 4'b0111; // SLT
            3'b110:  alucontrol = 4'b1000; // MULT
            3'b111:  alucontrol = 4'b1001; // DIV
            default: alucontrol = 4'b0010; // Default to ADD
        endcase
    end
endmodule