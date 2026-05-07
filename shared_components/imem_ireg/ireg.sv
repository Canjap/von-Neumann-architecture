module instr_reg (
    input  logic        clk,
    input  logic        reset,
    input  logic        en,     // Connect to ~stallD
    input  logic        clear,  // Connect to flushD
    input  logic [31:0] instr_in,
    output logic [31:0] instr_out
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            instr_out <= 32'b0;
        end else if (en) begin
            if (clear) 
                instr_out <= 32'b0; // Convert instruction to a NOP
            else 
                instr_out <= instr_in;
        end
    end

endmodule