`ifndef MUX2
`define MUX2

`timescale 1ns/100ps

module mux2
    #(parameter bitWidth = 32)(
    input  logic [(bitWidth-1):0] Data0, Data1,
    input  logic Selector,
    output logic [(bitWidth-1):0] Output
);
    assign Output = Selector ? Data1 : Data0;
endmodule

`endif