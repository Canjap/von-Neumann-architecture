// acc.sv - Standard 32-bit Accumulator Register

module acc (
    input  logic        clk,
    input  logic        reset,
    input  logic        en,    // Logic high to update the accumulator
    input  logic [31:0] d,     // Input from ALU Result
    output logic [31:0] q      // Output to ALU Input A
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) 
            q <= 32'b0;
        else if (en) 
            q <= d;
    end

endmodule
