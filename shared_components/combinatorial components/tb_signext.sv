module tb_signext;
    // Test parameters matched to your ISA specification
    parameter BW = 32;
    parameter IW = 24; 

    // Inputs
    logic [(IW-1):0] in;

    // Outputs
    logic [(BW-1):0] out;

    // Instantiate the Unit Under Test (UUT) with custom parameters
    signext #(.bitWidth(BW), .immediateWidth(IW)) uut (
        .in(in),
        .out(out)
    );

    initial begin
        $display("Time | In (24-bit) | Out (32-bit Sign Extended)");
        $display("------------------------------------------------");
        $monitor("%4t |    %h     | %h", $time, in, out);

        // Test 1: Positive number (MSB is 0)
        in = 24'h00000F; #10; 
        
        // Test 2: Another positive number
        in = 24'h7FFFFF; #10; 
        
        // Test 3: Negative number (MSB is 1) - small magnitude
        in = 24'hFFFFFF; #10; // Should extend to 32'hFFFFFFFF (-1)
        
        // Test 4: Negative number - large magnitude
        in = 24'h800000; #10; // Should extend to 32'hFF800000
        
        $finish;
    end
endmodule
