module signext
    #(parameter bitWidth = 32, immediateWidth = 16)(
    input  logic [(immediateWidth-1):0] in,
    output logic [(bitWidth-1):0] out
);
    logic sign;
    assign sign = in[(immediateWidth-1)];
    assign out = { {(bitWidth-immediateWidth){sign}}, in };
endmodule