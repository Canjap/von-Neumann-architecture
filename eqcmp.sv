module eqcmp
    #(parameter bitWidth = 32)(
    input  logic [(bitWidth-1):0] input1, input2,
    output logic           output
);
    
    assign output = (input1 == input2);

endmodule