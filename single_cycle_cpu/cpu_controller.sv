// =============================================================================
// cpu_controller.sv — Single-Cycle CPU Controller
// =============================================================================
// Split into maindec (opcode → control word) and aludec (aluop+op → alucontrol)
// matching the pipelined_cpu/controller.sv pattern.
// All opcodes match isa.md exactly.
// =============================================================================

module cpu_controller (
    input  logic [7:0]  op,          // instr[31:24]
    output logic        memwrite,    // 1 → write dmem (STA)
    output logic        memtoreg,    // 1 → ACC ← readdata (LDA)
    output logic        memaddrsrc,  // 1 → dmem addr = sign_ext(imm24), not aluout
    output logic [1:0]  alusrc,      // 00=zero  01=sign_ext(imm24)  10=readdata
    output logic [3:0]  alucontrol,  // to ALU
    output logic        branch,      // 1 → BZ or BNZ; datapath checks op to pick which
    output logic        jump         // 1 → JMP, always taken
);

    logic [1:0] aluop;

    // -------------------------------------------------------------------------
    // maindec — opcode → control word
    // Bit layout: memwrite | memtoreg | memaddrsrc | alusrc[1:0] | aluop[1:0] | branch | jump
    // -------------------------------------------------------------------------
    logic [8:0] controls;

    always_comb begin
        case (op)
            // LDA 0x08: ACC ← Mem[imm24]
            //   memtoreg=1, memaddrsrc=1, ALU unused
            8'h08: controls = 9'b0_1_1_00_00_0_0;

            // STA 0x2B: Mem[imm24] ← ACC
            //   memwrite=1, memaddrsrc=1, ALU unused
            8'h2B: controls = 9'b1_0_1_00_00_0_0;

            // ADD 0x02: ACC ← ACC + 0  (R-type, SrcB=zero)
            8'h02: controls = 9'b0_0_0_00_01_0_0;

            // MULT 0x10: ACC ← ACC * 0  (R-type)
            8'h10: controls = 9'b0_0_0_00_01_0_0;

            // DIV 0x12: ACC ← ACC / 0  (R-type)
            // WEAKNESS: DIV and MULT with SrcB=zero are not useful on their own.
            // These opcodes likely expect a memory operand; if so change alusrc
            // to 10 (readdata) and set memaddrsrc=0 so the ALU computes the addr.
            8'h12: controls = 9'b0_0_0_00_01_0_0;

            // ADDM 0x03: ACC ← ACC + sign_ext(imm24)
            8'h03: controls = 9'b0_0_0_01_10_0_0;

            // SUBM 0x07: ACC ← ACC - sign_ext(imm24)
            8'h07: controls = 9'b0_0_0_01_10_0_0;

            // MULTM 0x11: ACC ← ACC * sign_ext(imm24)
            8'h11: controls = 9'b0_0_0_01_10_0_0;

            // DIVM 0x13: ACC ← ACC / sign_ext(imm24)
            8'h13: controls = 9'b0_0_0_01_10_0_0;

            // BZ 0x04: branch if ACC == 0
            8'h04: controls = 9'b0_0_0_00_00_1_0;

            // BNZ 0x05: branch if ACC != 0
            8'h05: controls = 9'b0_0_0_00_00_1_0;

            // JMP 0x06: unconditional jump
            8'h06: controls = 9'b0_0_0_00_00_0_1;

            // WEAKNESS: unknown opcodes silently NOP. Add an illegal_op output
            // and tie it to a simulation assertion for easier debugging.
            default: controls = 9'b0_0_0_00_00_0_0;
        endcase
    end

    assign {memwrite, memtoreg, memaddrsrc, alusrc, aluop, branch, jump} = controls;

    // -------------------------------------------------------------------------
    // aludec — aluop + op → alucontrol
    // Maps to alu.sv alucontrol encoding:
    //   4'b0010 = add
    //   4'b0110 = sub
    //   4'b1000 = mult (lower 32 bits)
    //   4'b1001 = div  (quotient)
    // -------------------------------------------------------------------------
    always_comb begin
        case (aluop)
            2'b00: alucontrol = 4'b0000; // ALU unused (LDA/STA/branch)

            2'b01, // R-type
            2'b10: begin // I-type — same decode table, op selects operation
                case (op)
                    8'h02, 8'h03: alucontrol = 4'b0010; // ADD / ADDM
                    8'h07:        alucontrol = 4'b0110; // SUBM
                    8'h10, 8'h11: alucontrol = 4'b1000; // MULT / MULTM
                    8'h12, 8'h13: alucontrol = 4'b1001; // DIV  / DIVM
                    default:      alucontrol = 4'b0000;
                endcase
            end

            default: alucontrol = 4'b0000;
        endcase
    end

endmodule
