// =============================================================================
// cpu_top.sv — Single-Cycle CPU Top Level
// =============================================================================
// Wires cpu_controller and cpu_datapath together.
// All internal signals match the updated port lists exactly.
// =============================================================================

module cpu_top (
    input  logic        clk, reset,
    output logic [31:0] pc,
    input  logic [31:0] instr,
    output logic        memwrite,
    output logic [31:0] dmem_addr,   // was 'aluout' — now the memaddrsrc mux output
    output logic [31:0] writedata,
    input  logic [31:0] readdata
);

    // ── internal control signals ──────────────────────────────────────────────
    logic [7:0]  op;
    logic [1:0]  alusrc;
    logic [3:0]  alucontrol;
    logic        acc_write;
    logic        memtoreg;
    logic        memaddrsrc;
    logic        branch;
    logic        jump;

    // opcode is always instr[31:24] — 8 bits, not 6
    assign op = instr[31:24];

    // ── controller ───────────────────────────────────────────────────────────
    cpu_controller c (
        .op          (op),
        .memwrite    (memwrite),
        .memtoreg    (memtoreg),
        .memaddrsrc  (memaddrsrc),
        .alusrc      (alusrc),
        .alucontrol  (alucontrol),
        .branch      (branch),
        .jump        (jump)
    );

    // ── datapath ─────────────────────────────────────────────────────────────
    cpu_datapath dp (
        .clk         (clk),
        .reset       (reset),
        .alusrc      (alusrc),
        .acc_write   (acc_write),
        .alucontrol  (alucontrol),
        .memtoreg    (memtoreg),
        .memaddrsrc  (memaddrsrc),
        .branch      (branch),
        .jump        (jump),
        .op          (op),
        .pc          (pc),
        .instr       (instr),
        .dmem_addr   (dmem_addr),
        .writedata   (writedata),
        .readdata    (readdata)
    );

endmodule
