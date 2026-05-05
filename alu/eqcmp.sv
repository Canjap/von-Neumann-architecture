// Accumulator architecture: branches test ACC == 0, instead of two specified registers
module eqcmp
    #(parameter bitWidth = 32)(
    input  logic [(bitWidth-1):0] acc,
    output logic                  zero
);

    assign zero = (acc == {bitWidth{1'b0}});

endmodule
