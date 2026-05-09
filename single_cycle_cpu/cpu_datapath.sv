// =============================================================================
// cpu_datapath.sv — Single-Cycle CPU Datapath
// =============================================================================
// Uses only the modules confirmed present in single_cycle_cpu/:
//   pc.sv     — ports: clk, reset, stall, branch_taken, branch_target, pc_out
//   acc.sv    — ports: clk, reset, en, d, q
//   alu.sv    — ports: input1, input2, alucontrol, result, zero
//   mux2.sv   — ports: Data0, Data1, Selector, Output  (#parameter bitWidth)
//
// signext is implemented as a local assign (no shared_components file present).
// eqcmp is replaced by alu.sv's zero flag (result == 0), already computed.
// =============================================================================

module cpu_datapath (
    input  logic        clk, reset,

    // ── control signals from cpu_controller ──────────────────────────────────
    input  logic [1:0]  alusrc,      // 00=zero  01=sign_ext(imm24)  10=readdata
    input  logic        acc_write,   // ACC write enable
    input  logic [3:0]  alucontrol,
    input  logic        memtoreg,    // 1 → ACC ← readdata (LDA)
    input  logic        memaddrsrc,  // 1 → dmem addr = sign_ext(imm24)
    input  logic        branch,      // 1 → BZ or BNZ
    input  logic        jump,        // 1 → JMP
    input  logic [7:0]  op,          // opcode — tells datapath BZ vs BNZ

    // ── memory interfaces ─────────────────────────────────────────────────────
    output logic [31:0] pc,          // to imem address port
    input  logic [31:0] instr,       // from imem
    output logic [31:0] dmem_addr,   // to dmem address port
    output logic [31:0] writedata,   // to dmem write data port (ACC value)
    input  logic [31:0] readdata     // from dmem
);

    // =========================================================================
    // 1. Instruction fields
    // =========================================================================
    logic [23:0] imm24;
    assign imm24 = instr[23:0];

    // Sign extension — no signext.sv present, done inline.
    // Replicates bit 23 into bits [31:24].
    logic [31:0] sign_ext_imm;
    assign sign_ext_imm = {{8{imm24[23]}}, imm24};

    // =========================================================================
    // 2. Internal signals
    // =========================================================================
    logic [31:0] acc_q;       // accumulator output
    logic [31:0] alu_result;  // raw ALU output
    logic        alu_zero;    // alu_result == 0, from alu.sv
    logic [31:0] acc_wdata;   // data written into ACC (after memtoreg mux)
    logic [31:0] alu_srcb;    // ALU input B (after alusrc mux)
    logic [31:0] branch_target;
    logic        branch_taken;

    // =========================================================================
    // 3. Branch / jump logic
    // =========================================================================
    // branch_target = pc_out + 4 + (sign_ext(imm24) << 2)
    // pc.sv exposes pc_out; pc_out+4 is computed inside pc.sv but not exported,
    // so we recompute it here for the branch target adder.
    // WEAKNESS: this duplicates the pc+4 adder in pc.sv. If you later export
    // pc_plus4 from pc.sv, remove this assign to avoid the redundant adder.
    assign branch_target = (pc + 32'd4) + (sign_ext_imm << 2);

    // BZ  (0x04): taken if ACC == 0   → alu_zero == 1
    // BNZ (0x05): taken if ACC != 0   → alu_zero == 0
    // JMP (0x06): always taken
    always_comb begin
        case ({branch, jump})
            2'b10:   branch_taken = (op == 8'h04) ? alu_zero : ~alu_zero;
            2'b01:   branch_taken = 1'b1;
            default: branch_taken = 1'b0;
        endcase
    end

    // =========================================================================
    // 4. PC
    // =========================================================================
    pc pcreg (
        .clk           (clk),
        .reset         (reset),
        .stall         (1'b0),         // single-cycle: never stall
        .branch_taken  (branch_taken),
        .branch_target (branch_target),
        .pc_out        (pc)
    );

    // =========================================================================
    // 5. ALU source mux — 3-way, built from two mux2 instances
    // =========================================================================
    // Stage 1: choose between zero and sign_ext_imm  (covers 00 and 01)
    // Stage 2: choose between stage-1 output and readdata  (covers 10)
    //
    // alusrc[0] selects stage 1:  0→zero  1→sign_ext_imm
    // alusrc[1] selects stage 2:  0→stage1  1→readdata
    //
    // WEAKNESS: an illegal alusrc=11 would pick readdata over sign_ext_imm,
    // which may be unintentional. Gate with an assertion in simulation.
    logic [31:0] alusrcb_stage1;

    mux2 #(.bitWidth(32)) srcb_mux1 (
        .Data0    (32'h0),
        .Data1    (sign_ext_imm),
        .Selector (alusrc[0]),
        .Output   (alusrcb_stage1)
    );

    mux2 #(.bitWidth(32)) srcb_mux2 (
        .Data0    (alusrcb_stage1),
        .Data1    (readdata),
        .Selector (alusrc[1]),
        .Output   (alu_srcb)
    );

    // =========================================================================
    // 6. ALU
    // =========================================================================
    alu main_alu (
        .input1     (acc_q),
        .input2     (alu_srcb),
        .alucontrol (alucontrol),
        .result     (alu_result),
        .zero       (alu_zero)    // used for BZ / BNZ — replaces eqcmp
    );

    // =========================================================================
    // 7. memtoreg mux — selects ACC write data
    // =========================================================================
    // memtoreg=1 (LDA): ACC ← readdata
    // memtoreg=0 (ALU): ACC ← alu_result
    // This replaces the broken alucontrol=4'b1111 pass-through that hit the
    // ALU default case and returned 0 instead of readdata.
    mux2 #(.bitWidth(32)) memtoreg_mux (
        .Data0    (alu_result),
        .Data1    (readdata),
        .Selector (memtoreg),
        .Output   (acc_wdata)
    );

    // =========================================================================
    // 8. Accumulator
    // =========================================================================
    acc main_acc (
        .clk   (clk),
        .reset (reset),
        .en    (acc_write),
        .d     (acc_wdata),   // fed through memtoreg mux, not raw alu_result
        .q     (acc_q)
    );

    // =========================================================================
    // 9. Data memory address mux (memaddrsrc)
    // =========================================================================
    // memaddrsrc=1 (LDA/STA): dmem addr = sign_ext(imm24) — bypasses ALU
    // memaddrsrc=0 (others):  dmem addr = alu_result
    mux2 #(.bitWidth(32)) dmemaddr_mux (
        .Data0    (alu_result),
        .Data1    (sign_ext_imm),
        .Selector (memaddrsrc),
        .Output   (dmem_addr)
    );

    // =========================================================================
    // 10. Data memory write data
    // =========================================================================
    // STA always writes ACC; no mux needed.
    assign writedata = acc_q;

endmodule
