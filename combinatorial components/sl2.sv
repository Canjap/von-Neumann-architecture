`ifndef SL2
`define SL2

`timescale 1ns/100ps

module sl2
    #(parameter bitWidth = 32)(
    input  logic [(bitWidth-1):0] in,
    output logic [(bitWidth-1):0] out
);
    assign out = {in[(bitWidth-3):0], 2'b00};
endmodule

`endif // SL2