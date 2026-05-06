module aludec(
    input  logic [1:0] aluop,
    output logic [3:0] alucontrol
);

    always_comb begin
        case (aluop)
            2'b00: alucontrol = 4'b0010; // ADD
            2'b01: alucontrol = 4'b0110; // SUB (used for branch comparison)
            2'b10: alucontrol = 4'b1000; // MULT
            2'b11: alucontrol = 4'b1001; // DIV
            default: alucontrol = 4'b0010;
        endcase
    end
endmodule