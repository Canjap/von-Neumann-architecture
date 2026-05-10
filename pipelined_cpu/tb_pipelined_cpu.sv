`timescale 1ns/100ps

`include "pipelined_cpu_top.sv"

module tb_pipelined_cpu;

    logic        clk;
    logic        reset;
    logic [31:0] mem_addrM;
    logic [31:0] aluoutM;
    logic [31:0] writedataM;
    logic        memwriteM;

    pipelined_cpu_top dut (
        .clk        (clk),
        .reset      (reset),
        .mem_addrM  (mem_addrM),
        .aluoutM    (aluoutM),
        .writedataM (writedataM),
        .memwriteM  (memwriteM)
    );

    // Clock: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_pipelined_cpu.vcd");
        $dumpvars(0, tb_pipelined_cpu);
        reset = 1; #22;
        reset = 0;
    end

    // Print every memory write for tracing
    always @(posedge clk) begin
        if (!reset && memwriteM)
            $display("t=%0t  STA addr=%0d  data=%0d", $time, mem_addrM, writedataM);
    end

    // Sentinel: factorial.asm stores result to byte-addr 0 when done
    always @(posedge clk) begin
        if (!reset && memwriteM && mem_addrM == 32'd0) begin
            if (writedataM == 32'd24)
                $display("PASS: factorial(4)=%0d written to sentinel at t=%0t", writedataM, $time);
            else
                $display("FAIL: expected 24 at sentinel, got %0d at t=%0t", writedataM, $time);
            $finish;
        end
    end

    // Timeout
    initial begin
        #20000;
        $display("TIMEOUT: test did not complete within 20000 ns");
        $finish;
    end

endmodule
