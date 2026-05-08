`ifndef ADDER
`define ADDER

`timescale 1ns/100ps

module adder
    #(parameter n = 32)(
    input  logic [(n-1):0] A, B,
    output logic [(n-1):0] Y
);
    assign Y = A + B;
endmodule

`endif
