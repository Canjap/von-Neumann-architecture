`ifndef MUX4
`define MUX4

`timescale 1ns/100ps

module mux4
    #(parameter bitWidth = 32)(
    input  logic [(bitWidth-1):0] Data0, Data1, Data2, Data3,
    input  logic [1:0] Selector,
    output logic [(bitWidth-1):0] Output
);
    always_comb
        case (Selector)
            2'b00: Output = Data0;
            2'b01: Output = Data1;
            2'b10: Output = Data2;
            default: Output = Data3;
        endcase
endmodule

`endif