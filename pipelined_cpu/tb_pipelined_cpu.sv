`timescale 1ns/100ps

`include "pipelined_spu_top.sv"

module tb_pipelined_spu;

    logic        clk;
    logic        reset;
    logic [31:0] aluoutM;
    logic [31:0] writedataM;
    logic        memwriteM;

    pipelined_spu_top dut (
        .clk        (clk),
        .reset      (reset),
        .aluoutM    (aluoutM),
        .writedataM (writedataM),
        .memwriteM  (memwriteM)
    );

    // Clock: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_pipelined_spu.vcd");
        $dumpvars(0, tb_pipelined_spu);
        reset = 1; #22;
        reset = 0;
    end

    // Timeout
    initial begin
        #2000;
        $display("Testbench timeout");
        $finish;
    end

    // TODO: add result-checking logic once test program is defined
    // Example: watch for a STA to a sentinel address to signal program completion

endmodule
