module tb_ireg;
    // Inputs
    logic        clk;
    logic        reset;
    logic        en;
    logic        clear;
    logic [31:0] instr_in;

    // Outputs
    logic [31:0] instr_out;

    // Instantiate the Unit Under Test (UUT)
    instr_reg uut (
        .clk(clk),
        .reset(reset),
        .en(en),
        .clear(clear),
        .instr_in(instr_in),
        .instr_out(instr_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 time-unit period
    end

    // VCD Dumpfile setup for waveform viewing
    initial begin
        $dumpfile("tb_ireg.vcd");
        $dumpvars(0, tb_ireg);
    end

    initial begin
        $display("Time | Clk | Rst | En | Clear |  Instr In  |  Instr Out");
        $display("---------------------------------------------------------");
        $monitor("%4t |  %b  |  %b  | %b  |   %b   | %h | %h", 
                 $time, clk, reset, en, clear, instr_in, instr_out);

        // Initialize inputs
        reset = 1;
        en = 0;
        clear = 0;
        instr_in = 32'h00000000;

        // Test 1: Asynchronous Reset Check
        #15; // Wait past first clock edge
        reset = 0;
        
        // Test 2: Standard Load (Enable = 1, Clear = 0)
        en = 1;
        clear = 0;
        instr_in = 32'hDEADBEEF;
        #10; // Wait 1 clock cycle
        
        // Test 3: Stall Behavior (Enable = 0)
        en = 0;
        clear = 0;
        instr_in = 32'hCAFEF00D; // Change input, but it shouldn't load
        #10;
        
        // Test 4: Load a new instruction
        en = 1;
        instr_in = 32'hCAFEF00D;
        #10;

        // Test 5: Synchronous Clear/Flush (Enable = 1, Clear = 1)
        en = 1;
        clear = 1; 
        instr_in = 32'h12345678; // Input is ignored during clear
        #10;
        
        // Test 6: Clear removed, load new data
        clear = 0;
        #10;

        $finish;
    end
endmodule