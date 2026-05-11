module alu_tb;
    parameter bitWidth = 32;

    reg  [31:0] a, b;
    reg  [3:0]  ctrl;
    wire [31:0] result;
    wire        zero;

    // Instantiate the ALU
    alu #(.bitWidth(bitWidth)) dut (
        .input1(a),
        .input2(b),
        .alucontrol(ctrl),
        .result(result),
        .zero(zero)
    );

    // Generate VCD file
    initial begin
        $dumpfile("alu_tb.vcd");
        $dumpvars(0, alu_tb);
    end

    initial begin
        $display("Starting ALU Unit Test...");
        $display("Time | Ctrl |       A       |       B       |     Result    | Zero");
        $display("------------------------------------------------------------------");
        $monitor("%4t | %b | %13d | %13d | %13d |  %b", $time, ctrl, a, b, result, zero);

        // Test 1: AND (4'b0000)
        a = 32'd12; b = 32'd10; ctrl = 4'b0000; #10;
        if (result !== 32'd8) $display("Error: AND failed");

        // Test 2: OR (4'b0001)
        a = 32'd12; b = 32'd10; ctrl = 4'b0001; #10;
        if (result !== 32'd14) $display("Error: OR failed");

        // Test 3: ADD (4'b0010)
        a = 32'd10; b = 32'd5; ctrl = 4'b0010; #10;
        if (result !== 32'd15) $display("Error: ADD failed");

        // Test 4: NOR (4'b0011)
        a = 32'd0; b = 32'd0; ctrl = 4'b0011; #10;
        if (result !== 32'hFFFFFFFF) $display("Error: NOR failed");

        // Test 5: SUB (4'b0110)
        a = 32'd20; b = 32'd8; ctrl = 4'b0110; #10;
        if (result !== 32'd12) $display("Error: SUB failed");

        // Test 6: SLT (4'b0111)
        a = 32'd5; b = 32'd10; ctrl = 4'b0111; #10;
        if (result !== 32'd1) $display("Error: SLT failed (5 < 10)");

        // Test 7: MULT (4'b1000)
        a = 32'd4; b = 32'd3; ctrl = 4'b1000; #10;
        if (result !== 32'd12) $display("Error: MULT failed");

        // Test 8: DIV (4'b1001)
        a = 32'd100; b = 32'd10; ctrl = 4'b1001; #10;
        if (result !== 32'd10) $display("Error: DIV failed");

        // Test 9: ZERO FLAG
        a = 32'd5; b = 32'd5; ctrl = 4'b0110; // 5 - 5
        #10;
        if (zero !== 1'b1) $display("Error: Zero flag failed");

        $display("ALU Testing Complete.");
        $finish;
    end
endmodule