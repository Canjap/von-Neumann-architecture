// Accumulator architecture so no R-type instructions, so no funct field
// aluop is 3 bits maindec will map each opcode directly to one of these values
module aludec
    #(parameter n = 32)(
    input  logic [2:0] aluop,
    output logic [3:0] alucontrol);
    always @*
    begin
        case(aluop)
            3'b000: alucontrol <= 4'b0010; // add  (LDA, STA, ADD, ADDI)
            3'b001: alucontrol <= 4'b0110; // sub  (SUB, BEQ comparison)
            3'b010: alucontrol <= 4'b0000; // and
            3'b011: alucontrol <= 4'b0001; // or
            3'b100: alucontrol <= 4'b0111; // slt
            3'b101: alucontrol <= 4'b0011; // nor
            3'b110: alucontrol <= 4'b1000; // mult
            3'b111: alucontrol <= 4'b1001; // div
            default: alucontrol <= 4'b0010; // default add to prevent X propagation
        endcase
    end

endmodule