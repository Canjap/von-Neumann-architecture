module tb_dmem;
    // Inputs
    logic        clk;
    logic        we;
    logic [31:0] a;
    logic [31:0] wd;

    // Outputs
    logic [31:0] rd;

    // Instantiate the Unit Under Test (UUT)
    dmem uut (
        .clk(clk),
        .we(we),
        .a(a),
        .wd(wd),
        .rd(rd)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 time-unit period
    end

    // VCD Dumpfile setup for waveform viewing
    initial begin
        $dumpfile("tb_dmem.vcd");
        $dumpvars(0, tb_dmem);
    end

    initial begin
        $display("Time | Clk | WE | Address    | WriteData  | ReadData");
        $display("------------------------------------------------------");
        $monitor("%4t |  %b  |  %b | %h | %h | %h", $time, clk, we, a, wd, rd);

        // Initialize inputs
        we = 0; a = 0; wd = 0;

        // Wait for a few clock cycles
        #15;

        // Test 1: Write to memory at byte-address 0x04 (Word index 1)
        we = 1;
        a  = 32'h00000004;
        wd = 32'hDEADBEEF;
        #10; // Wait for positive clock edge to write
        
        // Test 2: Disable write, read from the same address
        we = 0;
        wd = 32'h00000000;
        #10;
        
        // Test 3: Write to memory at byte-address 0x10 (Word index 4)
        we = 1;
        a  = 32'h00000010;
        wd = 32'hCAFEF00D;
        #10;
        
        // Test 4: Read both addresses to ensure non-destructive writes
        we = 0;
        a  = 32'h00000004; #10;
        a  = 32'h00000010; #10;

        $finish;
    end
endmodule