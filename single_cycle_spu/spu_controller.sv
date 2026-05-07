module spu_controller(
    input  logic [5:0] opcode,
    output logic       memwrite, alusrc, acc_write,
    output logic [3:0] alucontrol
);

    always_comb begin
        // Default values to prevent latches
        acc_write  = 0;
        memwrite   = 0;
        alusrc     = 0;
        alucontrol = 4'b0010; // Default to ADD

        case (opcode)
            6'h01: begin // LDA (Load Accumulator from Memory)
                acc_write = 1;
                alusrc    = 0; // Select readdata from memory
                alucontrol = 4'b1111; // Use ALU to pass B through (ADD Acc+0)
            end
            6'h02: begin // STA (Store Accumulator to Memory)
                memwrite  = 1;
                acc_write = 0;
            end
            6'h03: begin // ADD (Acc = Acc + Memory)
                acc_write = 1;
                alusrc    = 0;
                alucontrol = 4'b0010; // ALU ADD code
            end
            6'h04: begin // SUB (Acc = Acc - Memory)
                acc_write = 1;
                alusrc    = 0;
                alucontrol = 4'b0110; // ALU SUB code
            end
            default: ; 
        endcase
    end
endmodule
