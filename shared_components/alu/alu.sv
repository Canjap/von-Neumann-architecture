module alu
    #(parameter bitWidth = 32)(
    input  logic [(bitWidth-1):0] input1, input2,
    input  logic [3:0]  alucontrol,
    output logic [(bitWidth-1):0] result,
    output logic        zero
);

    logic [(bitWidth-1):0] condinvb, sumSlt;

    assign zero = (result == {bitWidth{1'b0}});
    assign condinvb = alucontrol[2] ? ~input2 : input2;
    assign sumSlt = input1 + condinvb + alucontrol[2];

    always @(*) begin
        case (alucontrol)
            4'b0000: result = input1 & input2;              // and
            4'b0001: result = input1 | input2;              // or
            4'b0010: result = input1 + input2;              // add
            4'b0011: result = ~(input1 | input2);           // nor
            4'b0110: result = sumSlt;                       // sub
            4'b0111: begin                                  // slt
                if (input1[31] != input2[31])
                    result = input1[31] ? 1 : 0;
                else
                    result = (input1 < input2) ? 1 : 0;
            end
            // Accumulator: mult/div are fully combinational; ACC receives lower 32 bits, we dont need separate mflo/mfhi instructions
            4'b1000: result = input1 * input2;              // mult (lower 32 bits → ACC)
            4'b1001: result = input1 / input2;              // div  (quotient → ACC)
            default: result = {bitWidth{1'b0}};
        endcase
    end

endmodule