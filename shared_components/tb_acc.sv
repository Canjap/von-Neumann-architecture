module tb_acc;
    // Parameters
    parameter n = 32;

    // Inputs
    logic         clk;
    logic         reset;
    logic         en;
    logic [n-1:0] d;

    // Outputs
    logic [n-1:0] q;

    // Instantiate the Unit Under Test (UUT)
    acc #(.n(n)) uut (
        .clk(clk),
        .reset(reset),
        .en(en),
        .d(d),
        .q(q)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 time-unit clock period
    end

    // VCD Dumpfile setup for waveform viewing
    initial begin
        $dumpfile("tb_acc.vcd");
        $dumpvars(0, tb_acc);
    end

    initial begin
        $display("Starting Accumulator Unit Test...");
        $display("Time | Clk | Rst | En |    D (In)    |   Q (Out)   ");
        $display("---------------------------------------------------");
        $monitor("%4t |  %b  |  %b  |  %b | %h | %h", $time, clk, reset, en, d, q);

        // Initialize Inputs
        reset = 1;
        en = 0;
        d = 32'h00000000;

        // Test 1: Verify Asynchronous Reset
        #15; // Wait past first clock edge
        reset = 0; // Release reset
        #5;

        // Test 2: Write data to ACC
        en = 1;
        d = 32'hDEADBEEF;
        #10; // Wait for one clock cycle to load
        if (q !== 32'hDEADBEEF) $display("Error: Failed to write to ACC");

        // Test 3: Disable write, change input data (Q should remain DEADBEEF)
        en = 0;
        d = 32'hCAFEF00D;
        #10; 
        if (q !== 32'hDEADBEEF) $display("Error: ACC did not hold its value when en=0");

        // Test 4: Write new data
        en = 1;
        d = 32'h12345678;
        #10;
        if (q !== 32'h12345678) $display("Error: Failed to update ACC with new data");

        // Test 5: Verify Asynchronous Reset mid-operation
        reset = 1; // Should clear Q immediately
        #5; 
        if (q !== 32'h00000000) $display("Error: Reset did not clear the ACC");
        
        #5;
        $display("ACC Testing Complete.");
        $finish;
    end
endmodule