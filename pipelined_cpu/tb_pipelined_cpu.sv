`timescale 1ns/100ps

`include "pipelined_cpu_top.sv"

module tb_pipelined_cpu;

    // --- Signals ---
    logic        clk;
    logic        reset;
    logic [31:0] mem_addrM;
    logic [31:0] aluoutM;
    logic [31:0] writedataM;
    logic        memwriteM;

    // --- Device Under Test (DUT) ---
    pipelined_cpu_top dut (
        .clk        (clk),
        .reset      (reset),
        .mem_addrM  (mem_addrM),
        .aluoutM    (aluoutM),
        .writedataM (writedataM),
        .memwriteM  (memwriteM)
    );

    // --- Clock Generation (10ns period) ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // --- Reset and Waveform Logic ---
    initial begin
        $dumpfile("tb_pipelined_cpu.vcd");
        $dumpvars(0, tb_pipelined_cpu);
        
        reset = 1;
        #22;
        reset = 0;
    end

    // --- Runtime Monitor ---
    always @(posedge clk) begin
        if (!reset) begin
            // FIXED: Using aluoutE_val to match the updated datapath.sv
            $display("t=%0t | PC=%h | Instr=%h | ACC_EX=%d", 
                     $time, 
                     dut.cpu.dp.pcF, 
                     dut.cpu.instrF, 
                     dut.cpu.dp.aluoutE_val);
        end
    end

    // --- Memory Write Tracker & Sentinel ---
    always @(posedge clk) begin
        if (!reset && memwriteM) begin
            $display("t=%0t | MEM_WRITE | Addr=%d | Data=%d", $time, mem_addrM, writedataM);
            
            // Sentinel: The countdown program stores 0 to addr 252 when done
            if (mem_addrM == 32'd252) begin
                $display("\n--- SENTINEL REACHED ---");
                if (writedataM == 32'd0)
                    $display("RESULT: PASS (Countdown reached 0)");
                else
                    $display("RESULT: FAIL (Expected 0, Got %d)", writedataM);
                $finish;
            end
        end
    end

    // --- Global Timeout ---
    initial begin
        #100000; 
        $display("\nTIMEOUT: Simulation forced stop.");
        $finish;
    end

endmodule