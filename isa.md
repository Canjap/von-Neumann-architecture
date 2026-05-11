# ISA Specification — Accumulator Architecture

---

## ISA Parameters

### ALU Operand Size
32 bits. Both ALU inputs and the result are 32-bit values.

### Address Bus Size
32 bits. The PC and all memory addresses are 32-bit byte addresses.

### Addressability
Byte-addressed. The PC increments by 4 each cycle; instruction words are 4-byte aligned.
Data memory is also byte-addressed — `imm26` encodes a byte address, and the hardware indexes
word-aligned locations via `a[7:2]`.

### Register File Size
**Not applicable.** This is an accumulator architecture. There is no general-purpose register
file. A single 32-bit ACC register serves as the implicit source and destination of every ALU
operation. Three special-purpose registers are also present:

| Register | Width | Description |
|----------|-------|-------------|
| ACC | 32 bits | Accumulator — implicit ALU source/destination |
| PC  | 32 bits | Program counter |
| LR  | 32 bits | Link register — holds return address for CALL/RET |
| SP  | 32 bits | Stack pointer — initialised to `0x100`; grows downward |

### Opcode Size
6 bits, occupying `instruction[31:26]`.

### Function Size
**Not applicable.** There are no R-type instructions. Every instruction is fully specified by
its 6-bit opcode; no secondary function field is needed.

### shamt Size
**Not applicable.** The ISA has no shift instructions with an in-instruction shift amount.
The branch-target shift (`imm26 × 4`) is implemented in hardware via bit concatenation
(`{sign_ext(imm26)[29:0], 2'b00}`) — no shamt field is used.

### Instruction Size
32 bits, fixed-width.

```
 31      26 25                         0
┌──────────┬───────────────────────────┐
│  opcode  │           imm26           │
│  [31:26] │          [25:0]           │
└──────────┴───────────────────────────┘
```

| Field  | Bits    | Description |
|--------|---------|-------------|
| opcode | [31:26] | 6-bit instruction type |
| imm26  | [25:0]  | 26-bit signed immediate, memory address, or branch offset |

### PC Increment
`PC ← PC + 4` for all sequential (non-branch, non-jump) instructions.
For branches and jumps the target is computed as:

```
branch_target = (pcplus4D + 4) + (sign_ext(imm26) << 2)
```

`pcplus4D` is the decode-stage value of PC+4. The extra `+4` compensates for the registered
PC design. RET uses `PC ← LR` instead of this formula.

### Immediate Size
26 bits (`imm26[25:0]`), sign-extended to 32 bits before use:

```
sign_ext(imm26) = { {6{imm26[25]}}, imm26[25:0] }
```

---

## Instruction Type Support

### R-type Instruction Support
**Not applicable.** The accumulator architecture has no register-to-register operations.
ACC is always the implicit source and destination, so no rs/rt/rd fields exist and no
function-code dispatch is needed.

### I-type Instruction Support
**Supported.** All arithmetic, memory, and procedure-stack instructions use the I-type
format (opcode[31:26] + imm26[25:0]). ACC is the implicit second operand and the write destination.

### Memory Reference Support
**Supported.** Four categories of memory access are provided:

| Category | Instructions | Address source |
|----------|-------------|----------------|
| Direct load/store | LDA, STA | `sign_ext(imm26)` |
| ALU-memory (M-type) | ADDM, SUBM, MULTM, DIVM | `sign_ext(imm26)` |
| Stack load/store | LDSP, STSP | SP register |

### J-type Instruction Support
**Supported.** Unconditional jump, conditional branches, and procedure call/return are
all provided. They share the same 32-bit I-format encoding; the distinction is purely
in the opcode and how the target is computed.

---

## Instructions

### R-type Instructions
**Not applicable** — see above.

### I-type Instructions

#### Arithmetic (immediate operand)

| Opcode | Mnemonic | Operation |
|--------|----------|-----------|
| `0x00` | NOP   | No operation |
| `0x02` | ADD   | `ACC ← ACC + sign_ext(imm26)` |
| `0x10` | MULT  | `ACC ← ACC × sign_ext(imm26)` |
| `0x12` | DIV   | `ACC ← ACC ÷ sign_ext(imm26)` |

#### Arithmetic (memory operand — M-type)

| Opcode | Mnemonic | Operation |
|--------|----------|-----------|
| `0x03` | ADDM  | `ACC ← ACC + Mem[sign_ext(imm26)]` |
| `0x07` | SUBM  | `ACC ← ACC − Mem[sign_ext(imm26)]` |
| `0x11` | MULTM | `ACC ← ACC × Mem[sign_ext(imm26)]` |
| `0x13` | DIVM  | `ACC ← ACC ÷ Mem[sign_ext(imm26)]` |

#### Memory Load / Store

| Opcode | Mnemonic | Operation |
|--------|----------|-----------|
| `0x08` | LDA  | `ACC ← Mem[sign_ext(imm26)]` |
| `0x2B` | STA  | `Mem[sign_ext(imm26)] ← ACC` |

#### Procedure / Stack

| Opcode | Mnemonic | Operation |
|--------|----------|-----------|
| `0x14` | ADDSP | `SP ← SP + sign_ext(imm26)` |
| `0x15` | STSP  | `Mem[SP] ← ACC` |
| `0x16` | LDSP  | `ACC ← Mem[SP]` |
| `0x17` | GETLR | `ACC ← LR` |
| `0x18` | SETLR | `LR ← ACC` |

### J-type Instructions

| Opcode | Mnemonic | Operation |
|--------|----------|-----------|
| `0x04` | BZ   | If `ACC == 0`: `PC ← branch_target` |
| `0x05` | BNZ  | If `ACC ≠ 0`: `PC ← branch_target` |
| `0x06` | JMP  | `PC ← branch_target` (unconditional) |
| `0x0E` | CALL | `LR ← PC+4` (written in ID stage); `PC ← branch_target` |
| `0x0F` | RET  | `PC ← LR` |

**Branch target formula** (BZ, BNZ, JMP, CALL):

```
branch_target = (pcplus4D + 4) + (sign_ext(imm26) << 2)
```

Assembler encodes the offset as: `imm = target_word − (branch_word + 2)`

**Example:** `BNZ loop` assembled at word 7, `loop` at word 3:
```
imm = 3 − (7 + 2) = −6
branch_target = (32 + 4) + (−6 × 4) = 36 − 24 = 12  (word 3)
```

---

## ALU Operation Encoding

`maindec` drives a 3-bit `aluop`; `aludec` translates it to the 4-bit `alucontrol` consumed by the ALU.

| `aluop[2:0]` | `alucontrol[3:0]` | ALU Operation |
|---|---|---|
| `000` | `0010` | ADD |
| `001` | `0110` | SUB |
| `010` | `0000` | AND |
| `011` | `0001` | OR |
| `100` | `0111` | SLT |
| `101` | `0011` | NOR |
| `110` | `1000` | MULT |
| `111` | `1001` | DIV |

> AND, OR, SLT, and NOR are available in the ALU but have no assigned opcodes in the current ISA.

### Instruction → `aluop` mapping

| Instruction | `aluop[2:0]` |
|---|---|
| NOP, ADD, ADDM, LDA, STA, BZ, BNZ, ADDSP, LDSP, STSP, GETLR, SETLR | `000` (ADD) |
| SUBM | `001` (SUB) |
| MULT, MULTM | `110` (MULT) |
| DIV, DIVM | `111` (DIV) |

---

## Control Signal Truth Table

Derived from `shared_components/maindec.sv`. Procedure signals (`callout`, `ret`, `spwrite`, `lrwrite`, `usesp`, `accsrc`) omitted for brevity — see maindec.sv for full encoding.

| Instruction | `regwrite` | `alusrc[1:0]` | `memtoreg` | `memwrite` | `branch` | `jump` | `memaddrsrc[1:0]` | `aluop[2:0]` |
|---|---|---|---|---|---|---|---|---|
| NOP    | 0 | `00` | 0 | 0 | 0 | 0 | `00` | `000` |
| ADD    | 1 | `01` | 0 | 0 | 0 | 0 | `00` | `000` |
| ADDM   | 1 | `10` | 0 | 0 | 0 | 0 | `01` | `000` |
| BZ     | 0 | `00` | 0 | 0 | 1 | 0 | `00` | `000` |
| BNZ    | 0 | `00` | 0 | 0 | 1 | 0 | `00` | `000` |
| JMP    | 0 | `00` | 0 | 0 | 0 | 1 | `00` | `000` |
| SUBM   | 1 | `10` | 0 | 0 | 0 | 0 | `01` | `001` |
| LDA    | 1 | `01` | 1 | 0 | 0 | 0 | `01` | `000` |
| MULT   | 1 | `01` | 0 | 0 | 0 | 0 | `00` | `110` |
| MULTM  | 1 | `10` | 0 | 0 | 0 | 0 | `01` | `110` |
| DIV    | 1 | `01` | 0 | 0 | 0 | 0 | `00` | `111` |
| DIVM   | 1 | `10` | 0 | 0 | 0 | 0 | `01` | `111` |
| STA    | 0 | `01` | 0 | 1 | 0 | 0 | `01` | `000` |
| CALL   | 0 | `00` | 0 | 0 | 0 | 1 | `00` | `000` |
| RET    | 0 | `00` | 0 | 0 | 0 | 0 | `00` | `000` |
| ADDSP  | 0 | `01` | 0 | 0 | 0 | 0 | `00` | `000` |
| STSP   | 0 | `00` | 0 | 1 | 0 | 0 | `10` | `000` |
| LDSP   | 1 | `00` | 1 | 0 | 0 | 0 | `10` | `000` |
| GETLR  | 1 | `00` | 0 | 0 | 0 | 0 | `00` | `000` |
| SETLR  | 0 | `00` | 0 | 0 | 0 | 0 | `00` | `000` |

**Signal definitions:**

| Signal | Effect when asserted |
|---|---|
| `regwrite` | Write ALU or memory result to ACC |
| `alusrc[1:0]` | ALU input B: `00`=zero, `01`=sign\_ext(imm26), `10`=readdata (M-type / LDSP) |
| `memtoreg` | Route data-memory read to ACC (vs. ALU result) |
| `memwrite` | Write ACC to data memory |
| `branch` | Enable conditional branch evaluation (BZ/BNZ) |
| `jump` | Unconditional PC redirect (JMP/CALL) |
| `memaddrsrc[1:0]` | Memory address select: `00`=ALU result, `01`=sign\_ext(imm26), `10`=SP |
