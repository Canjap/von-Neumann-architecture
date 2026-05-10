`timescale 1ns/100ps

`include "sc_cpu_top.sv"

module tb_sc_cpu;

    logic        clk;
    logic        reset;
    logic [31:0] mem_addr;
    logic [31:0] writedata;
    logic        memwrite;

    sc_cpu_top dut (
        .clk       (clk),
        .reset     (reset),
        .mem_addr  (mem_addr),
        .writedata (writedata),
        .memwrite  (memwrite)
    );

    // Clock: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_sc_cpu.vcd");
        $dumpvars(0, tb_sc_cpu);
        reset = 1; #22;
        reset = 0;
    end

    // Print every memory write for tracing
    always @(posedge clk) begin
        if (!reset && memwrite)
            $display("t=%0t  STA addr=%0d  data=%0d", $time, mem_addr, writedata);
    end

    // Sentinel: selected by +TEST=<name> plusarg.
    //   factorial : addr=0,   expected 24
    //   countdown : addr=252, expected 0
    //   fibonacci : addr=252, expected 34
    //   leaf      : addr=0,   expected 15
    //   nested    : addr=0,   expected 10
    string test_name;
    initial begin
        if (!$value$plusargs("TEST=%s", test_name))
            test_name = "factorial";
    end

    always @(posedge clk) begin
        if (!reset && memwrite) begin
            if (test_name == "factorial" && mem_addr == 32'd0) begin
                if (writedata == 32'd24)
                    $display("PASS: factorial(4)=%0d written to sentinel at t=%0t", writedata, $time);
                else
                    $display("FAIL: expected 24 at sentinel, got %0d at t=%0t", writedata, $time);
                $finish;
            end
            if (test_name == "countdown" && mem_addr == 32'd252) begin
                if (writedata == 32'd0)
                    $display("PASS: countdown reached 0 at t=%0t", $time);
                else
                    $display("FAIL: countdown expected 0 at addr 252, got %0d at t=%0t", writedata, $time);
                $finish;
            end
            if (test_name == "fibonacci" && mem_addr == 32'd252) begin
                if (writedata == 32'd34)
                    $display("PASS: fibonacci(9)=%0d written to sentinel at t=%0t", writedata, $time);
                else
                    $display("FAIL: fibonacci expected 34 at addr 252, got %0d at t=%0t", writedata, $time);
                $finish;
            end
            if (test_name == "leaf" && mem_addr == 32'd0) begin
                if (writedata == 32'd15)
                    $display("PASS: add_ten(5)=%0d written to sentinel at t=%0t", writedata, $time);
                else
                    $display("FAIL: leaf expected 15 at sentinel, got %0d at t=%0t", writedata, $time);
                $finish;
            end
            if (test_name == "nested" && mem_addr == 32'd0) begin
                if (writedata == 32'd10)
                    $display("PASS: nested result=%0d written to sentinel at t=%0t", writedata, $time);
                else
                    $display("FAIL: nested expected 10 at sentinel, got %0d at t=%0t", writedata, $time);
                $finish;
            end
        end
    end

    // Timeout
    initial begin
        #50000;
        $display("TIMEOUT: test did not complete within 50000 ns");
        $finish;
    end

endmodule
