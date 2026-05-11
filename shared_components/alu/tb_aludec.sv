module tb_aludec;
    parameter n = 32;

    logic [2:0] aluop;
    logic [3:0] alucontrol;
    logic [3:0] expected_control;

    aludec #(.n(n)) uut (
        .aluop(aluop),
        .alucontrol(alucontrol)
    );

    initial begin
        $dumpfile("tb_aludec.vcd");
        $dumpvars(0, tb_aludec);
    end

    task check_alu(input [2:0] op, input [3:0] expected, input string name);
        begin
            aluop = op;
            expected_control = expected;
            #10; 
            
            if (alucontrol !== expected) begin
                $display("%4t | FAIL | %s | ALUOp: %b | Expected: %b | Got: %b", 
                         $time, name, aluop, expected, alucontrol);
            end else begin
                $display("%4t | PASS | %s | ALUOp: %b | ALUControl: %b", 
                         $time, name, aluop, alucontrol);
            end
        end
    endtask

    initial begin
        $display("Time | Stat | Operation | ALUOp | ALUControl");
        $display("----------------------------------------------");

        check_alu(3'b000, 4'b0010, "ADD ");
        check_alu(3'b001, 4'b0110, "SUB ");
        check_alu(3'b010, 4'b0000, "AND ");
        check_alu(3'b011, 4'b0001, "OR  ");
        check_alu(3'b100, 4'b0111, "SLT ");
        check_alu(3'b101, 4'b0011, "NOR ");
        check_alu(3'b110, 4'b1000, "MULT");
        check_alu(3'b111, 4'b1001, "DIV ");

        aluop = 3'bxxx; 
        #10;
        if (alucontrol === 4'b0010) begin
            $display("%4t | PASS | DFLT| ALUOp: %b | ALUControl: %b", $time, aluop, alucontrol);
        end else begin
            $display("%4t | FAIL | DFLT| ALUOp: %b | Expected: 0010 | Got: %b", $time, aluop, alucontrol);
        end

        $finish;
    end
endmodule