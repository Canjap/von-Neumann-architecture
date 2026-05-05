// ACCUMULATOR 

module acc #(parameter n = 32)(
    input  logic         clk,
    input  logic         reset,
    input  logic         en,      // Write Enable from Controller
    input  logic [n-1:0] d,       // Data from ALU or Memory
    output logic [n-1:0] q        // Current Accumulator Value
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) 
            q <= {n{1'b0}};
        else if (en) 
            q <= d;
    end

endmodule