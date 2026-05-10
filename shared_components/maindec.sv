module maindec(
    input  logic        reset,
    input  logic [5:0]  op,
    output logic        memtoreg, memwrite,
    output logic        branch,
    output logic [1:0]  alusrc,
    output logic        regwrite, jump,
    output logic [1:0]  memaddrsrc,   // 2-bit: 00=aluout  01=signimm  10=SP
    output logic [2:0]  aluop,
    // New outputs for P1-P3 procedure support
    output logic        callout,      // CALL: write pcplus4D → LR in ID
    output logic        ret,          // RET: PC ← LR
    output logic        spwrite,      // ADDSP: write ALU result → SP in WB
    output logic        lrwrite,      // SETLR: write resultW → LR in WB
    output logic        usesp,        // ADDSP: use SP as ALU input1
    output logic        accsrc        // GETLR: select LR as resultW source
);
    // controls[17:0]:
    // {regwrite, alusrc[1:0], memtoreg, memwrite, branch, jump,
    //  memaddrsrc[1:0], callout, ret, spwrite, lrwrite, usesp, accsrc, aluop[2:0]}
    logic [17:0] controls;
    assign {regwrite, alusrc, memtoreg, memwrite, branch, jump,
            memaddrsrc, callout, ret, spwrite, lrwrite, usesp, accsrc, aluop} = controls;

    always_comb begin
        if (reset) controls = 18'b0;
        else begin
            case(op)
                // Existing instructions — memaddrsrc widened: 0→2'b00, 1→2'b01
                6'h02:   controls = 18'b1_01_0_0_0_0_00_0_0_0_0_0_0_000; // ADD
                6'h03:   controls = 18'b1_10_0_0_0_0_01_0_0_0_0_0_0_000; // ADDM
                6'h04:   controls = 18'b0_00_0_0_1_0_00_0_0_0_0_0_0_000; // BZ
                6'h05:   controls = 18'b0_00_0_0_1_0_00_0_0_0_0_0_0_000; // BNZ
                6'h06:   controls = 18'b0_00_0_0_0_1_00_0_0_0_0_0_0_000; // JMP
                6'h07:   controls = 18'b1_10_0_0_0_0_01_0_0_0_0_0_0_001; // SUBM
                6'h08:   controls = 18'b1_01_1_0_0_0_01_0_0_0_0_0_0_000; // LDA
                6'h10:   controls = 18'b1_01_0_0_0_0_00_0_0_0_0_0_0_110; // MULT
                6'h11:   controls = 18'b1_10_0_0_0_0_01_0_0_0_0_0_0_110; // MULTM
                6'h12:   controls = 18'b1_01_0_0_0_0_00_0_0_0_0_0_0_111; // DIV
                6'h13:   controls = 18'b1_10_0_0_0_0_01_0_0_0_0_0_0_111; // DIVM
                6'h2B:   controls = 18'b0_01_0_1_0_0_01_0_0_0_0_0_0_000; // STA
                // New procedure instructions
                6'h0E:   controls = 18'b0_00_0_0_0_1_00_1_0_0_0_0_0_000; // CALL: jump=1, callout=1
                6'h0F:   controls = 18'b0_00_0_0_0_0_00_0_1_0_0_0_0_000; // RET:  ret=1
                6'h14:   controls = 18'b0_01_0_0_0_0_00_0_0_1_0_1_0_000; // ADDSP: alusrc=01, spwrite=1, usesp=1
                6'h15:   controls = 18'b0_00_0_1_0_0_10_0_0_0_0_0_0_000; // STSP:  memwrite=1, memaddrsrc=2'b10
                6'h16:   controls = 18'b1_00_1_0_0_0_10_0_0_0_0_0_0_000; // LDSP:  regwrite=1, memtoreg=1, memaddrsrc=2'b10
                6'h17:   controls = 18'b1_00_0_0_0_0_00_0_0_0_0_0_1_000; // GETLR: regwrite=1, accsrc=1
                6'h18:   controls = 18'b0_00_0_0_0_0_00_0_0_0_1_0_0_000; // SETLR: lrwrite=1
                default: controls = 18'b0;                                 // NOP
            endcase
        end
    end
endmodule
