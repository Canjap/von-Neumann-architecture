module tb_aludec;
    // Parameters
    parameter n = 32; // Kept to match component signature

    // Inputs
    logic [2:0] aluop;

    // Outputs
    logic [3:0] alucontrol;

    // Instantiate the Unit Under Test (UUT)
    aludec #(.n(n)) uut (
        .aluop(aluop),
        .alucontrol(alucontrol)
    );

    initial begin
        $display("Time | ALUOp | ALUControl");
        $display("-------------------------");
        $monitor("%4t |  %b  |    %b", $time, aluop, alucontrol);

        // Test all possible 3-bit ops
        aluop = 3'b000; #10; // add
        aluop = 3'b001; #10; // sub
        aluop = 3'b010; #10; // and
        aluop = 3'b011; #10; // or
        aluop = 3'b100; #10; // slt
        aluop = 3'b101; #10; // nor
        aluop = 3'b110; #10; // mult
        aluop = 3'b111; #10; // div
        
        $finish;
    end
endmodule
