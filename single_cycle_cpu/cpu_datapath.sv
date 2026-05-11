module cpu_datapath (
    input  logic        clk, reset,

    // control signals
    input  logic [1:0]  alusrc,       // 00=zero  01=signimm  10=readdata
    input  logic        regwrite,     // 1 → write result to ACC
    input  logic [3:0]  alucontrol,
    input  logic        memtoreg,     // 1 → ACC ← readdata (LDA/LDSP)
    input  logic [1:0]  memaddrsrc,   // 00=aluout  01=signimm  10=SP
    input  logic        branch,       // BZ or BNZ
    input  logic        jump,         // JMP or CALL
    input  logic        callout,      // CALL: latch PC+4 into LR
    input  logic        ret,          // RET: PC ← LR
    input  logic        spwrite,      // ADDSP: latch ALU result into SP
    input  logic        lrwrite,      // SETLR: latch ACC into LR
    input  logic        usesp,        // ADDSP: ALU input1 = SP instead of ACC
    input  logic        accsrc,       // GETLR: write-back data = LR
    input  logic [5:0]  op,           // opcode (BZ vs BNZ discriminator)

    // memory interfaces
    output logic [31:0] pc,
    input  logic [31:0] instr,
    output logic [31:0] dmem_addr,
    output logic [31:0] writedata,
    input  logic [31:0] readdata
);

    // =========================================================================
    // Instruction fields
    // =========================================================================
    logic [25:0] imm26;
    logic [31:0] sign_ext_imm;
    assign imm26        = instr[25:0];
    assign sign_ext_imm = {{6{imm26[25]}}, imm26};

    // =========================================================================
    // Internal signals
    // =========================================================================
    logic [31:0] acc_q;
    logic [31:0] lr;
    logic [31:0] sp;
    logic [31:0] alu_result;
    logic        alu_zero;
    logic [31:0] result;        // data written to ACC
    logic [31:0] alu_input1;    // ACC or SP (ADDSP)
    logic [31:0] alu_srcb;

    // =========================================================================
    // LR register
    //   CALL:   lr ← PC + 4  (return address = instruction after CALL)
    //   SETLR:  lr ← ACC
    // =========================================================================
    always_ff @(posedge clk or posedge reset) begin
        if (reset)        lr <= 32'b0;
        else if (callout) lr <= pc + 32'd4;
        else if (lrwrite) lr <= acc_q;
    end

    // =========================================================================
    // SP register  (grows downward; initialised to 0x100 = 256)
    //   ADDSP: sp ← ALU result (sp + sign_ext(imm24))
    // =========================================================================
    always_ff @(posedge clk or posedge reset) begin
        if (reset)        sp <= 32'h100;
        else if (spwrite) sp <= alu_result;
    end

    // =========================================================================
    // Branch / jump target
    //   Matches the pipelined formula so the same assembled .hex runs on both:
    //   target = (pc + 4 + 4) + (sign_ext(imm24) << 2)
    //   RET overrides target to LR.
    // =========================================================================
    logic [31:0] branch_target;
    logic        branch_taken;

    assign branch_target = ret ? lr
                               : ((pc + 32'd8) + {sign_ext_imm[29:0], 2'b00});

    assign branch_taken  = ret
                        || jump
                        || (branch && op == 6'h04 &&  alu_zero)   // BZ
                        || (branch && op == 6'h05 && !alu_zero);  // BNZ

    // =========================================================================
    // PC
    // =========================================================================
    pc pcreg (
        .clk           (clk),
        .reset         (reset),
        .stall         (1'b0),
        .branch_taken  (branch_taken),
        .branch_target (branch_target),
        .pc_out        (pc)
    );

    // =========================================================================
    // ALU input1 mux  (ACC normally; SP for ADDSP)
    // =========================================================================
    mux2 #(.bitWidth(32)) alu1mux (
        .Data0    (acc_q),
        .Data1    (sp),
        .Selector (usesp),
        .Output   (alu_input1)
    );

    // =========================================================================
    // ALU source-B mux  (3-way via two mux2)
    //   alusrc 00→zero  01→signimm  10→readdata
    // =========================================================================
    logic [31:0] alusrcb_s1;

    mux2 #(.bitWidth(32)) srcb_mux1 (
        .Data0    (32'h0),
        .Data1    (sign_ext_imm),
        .Selector (alusrc[0]),
        .Output   (alusrcb_s1)
    );
    mux2 #(.bitWidth(32)) srcb_mux2 (
        .Data0    (alusrcb_s1),
        .Data1    (readdata),
        .Selector (alusrc[1]),
        .Output   (alu_srcb)
    );

    // =========================================================================
    // ALU
    // =========================================================================
    alu main_alu (
        .input1     (alu_input1),
        .input2     (alu_srcb),
        .alucontrol (alucontrol),
        .result     (alu_result),
        .zero       (alu_zero)
    );

    // =========================================================================
    // Write-back mux  selector = {accsrc, memtoreg}
    //   2'b00 → alu_result   (arithmetic / ADDM / SUBM / etc.)
    //   2'b01 → readdata     (LDA, LDSP)
    //   2'b10 → lr           (GETLR)
    // =========================================================================
    always_comb begin
        case ({accsrc, memtoreg})
            2'b01:   result = readdata;
            2'b10:   result = lr;
            default: result = alu_result;
        endcase
    end

    // =========================================================================
    // Accumulator
    // =========================================================================
    acc main_acc (
        .clk   (clk),
        .reset (reset),
        .en    (regwrite),
        .d     (result),
        .q     (acc_q)
    );

    // =========================================================================
    // Data memory address mux  (3-way via two mux2)
    //   memaddrsrc 00→aluout  01→signimm  10→SP
    // =========================================================================
    logic [31:0] memaddr_s1;

    mux2 #(.bitWidth(32)) memaddr_mux1 (
        .Data0    (alu_result),
        .Data1    (sign_ext_imm),
        .Selector (memaddrsrc[0]),
        .Output   (memaddr_s1)
    );
    mux2 #(.bitWidth(32)) memaddr_mux2 (
        .Data0    (memaddr_s1),
        .Data1    (sp),
        .Selector (memaddrsrc[1]),
        .Output   (dmem_addr)
    );

    // =========================================================================
    // Data memory write data — always ACC (STA, STSP)
    // =========================================================================
    assign writedata = acc_q;

endmodule
