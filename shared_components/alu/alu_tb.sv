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

    initial begin
        $display("Starting ALU Unit Test...");
        $monitor("Time=%0t | Ctrl=%b | A=%d, B=%d | Result=%d | Zero=%b", $time, ctrl, a, b, result, zero);

        // Test 1: ADD (4'b0010)
        a = 32'd10; b = 32'd5; ctrl = 4'b0010;
        #10;
        if (result !== 32'd15) $display("Error: ADD failed");

        // Test 2: SUB (4'b0110)
        a = 32'd20; b = 32'd8; ctrl = 4'b0110;
        #10;
        if (result !== 32'd12) $display("Error: SUB failed");

        // Test 3: MULT (4'b1000)
        a = 32'd4; b = 32'd3; ctrl = 4'b1000;
        #10;
        if (result !== 32'd12) $display("Error: MULT failed");

        // Test 4: DIV (4'b1001)
        a = 32'd100; b = 32'd10; ctrl = 4'b1001;
        #10;
        if (result !== 32'd10) $display("Error: DIV failed");

        // Test 5: ZERO FLAG
        a = 32'd5; b = 32'd5; ctrl = 4'b0110; // 5 - 5
        #10;
        if (zero !== 1'b1) $display("Error: Zero flag failed");

        $display("ALU Testing Complete.");
        $finish;
    end
endmodule