module tb_imem;
    // Parameters
    parameter n = 32;
    parameter r = 8;

    // Inputs
    logic [(r-1):0] addr;

    // Outputs
    logic [(n-1):0] readdata;

    // Instantiate the Unit Under Test (UUT)
    instr_mem #(
        .n(n),
        .r(r)
    ) uut (
        .addr(addr),
        .readdata(readdata)
    );

    // Setup dummy hex file for testing
    initial begin
        integer file;
        file = $fopen("test_prog.hex", "w");
        $fdisplay(file, "08000005"); // Word 0 (Address 0x00)
        $fdisplay(file, "38000001"); // Word 1 (Address 0x04)
        $fdisplay(file, "AC000000"); // Word 2 (Address 0x08)
        $fdisplay(file, "18FFFFFE"); // Word 3 (Address 0x0C)
        $fclose(file);
    end

    initial begin
        $display("Time | Address (Hex) | Read Data (Hex)");
        $display("--------------------------------------");
        $monitor("%4t |      %h       |   %h", $time, addr, readdata);

        // Wait a moment for memory to initialize
        #5; 

        // Test 1: Read Word 0 (Byte address 0)
        addr = 8'h00; #10;
        
        // Test 2: Read Word 1 (Byte address 4)
        // Notice it indexes via addr[7:2], so 4 >> 2 = 1
        addr = 8'h04; #10;
        
        // Test 3: Read Word 2 (Byte address 8)
        addr = 8'h08; #10;
        
        // Test 4: Read Word 3 (Byte address 12 or 0x0C)
        addr = 8'h0C; #10;

        // Test 5: Read uninitialized memory (should be 0)
        addr = 8'h10; #10;

        $finish;
    end
endmodule
