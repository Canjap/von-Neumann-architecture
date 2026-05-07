# ISA Specification — Accumulator Architecture

## Register Model

| Register | Width | Description |
|----------|-------|-------------|
| ACC | 32 bits | Accumulator — implicit source and destination for all ALU operations |
| PC | 32 bits | Program counter |

There is no general-purpose register file. One ALU input is always ACC; results always write back to ACC.

---

## Instruction Format

All instructions are 32 bits wide.

```
 31      26 25  24 23                  0
┌──────────┬──────┬─────────────────────┐
│  opcode  │  --  │        imm24        │
│  [31:26] │  rsvd│       [23:0]        │
└──────────┴──────┴─────────────────────┘
```

| Field | Bits | Description |
|-------|------|-------------|
| opcode | [31:26] | 6-bit instruction type |
| reserved | [25:24] | Must be `2'b00` |
| imm24 | [23:0] | 24-bit signed immediate or memory address |

---

## Instruction Set

| Opcode (hex) | Mnemonic | Operation |
|---|---|---|
| `0x00` | NOP   | No operation |
| `0x02` | ADD   | `ACC ← ACC + sign_ext(imm24)` |
| `0x03` | ADDM  | `ACC ← ACC + Mem[sign_ext(imm24)]` |
| `0x04` | BZ    | If `ACC == 0`: `PC ← branch_target` |
| `0x05` | BNZ   | If `ACC ≠ 0`: `PC ← branch_target` |
| `0x06` | JMP   | `PC ← branch_target` (unconditional) |
| `0x07` | SUBM  | `ACC ← ACC − Mem[sign_ext(imm24)]` |
| `0x08` | LDA   | `ACC ← Mem[sign_ext(imm24)]` |
| `0x10` | MULT  | `ACC ← ACC × sign_ext(imm24)` |
| `0x11` | MULTM | `ACC ← ACC × Mem[sign_ext(imm24)]` |
| `0x12` | DIV   | `ACC ← ACC ÷ sign_ext(imm24)` |
| `0x13` | DIVM  | `ACC ← ACC ÷ Mem[sign_ext(imm24)]` |
| `0x2B` | STA   | `Mem[sign_ext(imm24)] ← ACC` |

---

## Sign Extension

`imm24` is sign-extended from bit 23 to fill a 32-bit value before use:

```
sign_ext(imm24) = { {8{imm24[23]}}, imm24[23:0] }
```

---

## Branch Target Calculation

BZ, BNZ, and JMP all use the same target formula, computed relative to the **next** instruction's address.
Due to the registered PC design, `pc_out` at decode time already holds `PC_current + 4`.

```
branch_target = (pc_out + 4) + (sign_ext(imm24) << 2)
              = PC_current + 8 + (sign_ext(imm24) × 4)
```

The immediate is a **word offset** (each unit = 4 bytes). Negative values branch backward.
JMP is unconditionally taken; BZ and BNZ are conditional on ACC.

**Example:** `BNZ -6` assembled at address `0x14`
```
branch_target = 0x14 + 8 + (-6 × 4) = 0x1C - 24 = 0x04
```

---

## ALU Operation Encoding

### `aluop` → `alucontrol` (source: `alu/aludec.sv`)

`aluop` is **3 bits**. `maindec` drives it; `aludec` translates it to the 4-bit `alucontrol` consumed by the ALU.

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

### Instruction → `aluop` mapping

| Instruction | `aluop[2:0]` | Reason |
|---|---|---|
| NOP, ADD, ADDM, LDA, STA, BZ, BNZ | `000` | ADD |
| SUBM | `001` | SUB |
| MULT, MULTM | `110` | MULT |
| DIV, DIVM | `111` | DIV |

> SUB, AND, OR, SLT, NOR are available in the ALU but have no assigned opcodes yet.

---

## Control Signal Truth Table

Derived from `maindec.sv`.

| Instruction | `regwrite` | `alusrc[1:0]` | `memtoreg` | `memwrite` | `branch` | `jump` | `memaddrsrc` | `aluop[2:0]` |
|---|---|---|---|---|---|---|---|---|
| NOP   | 0 | `00` | 0 | 0 | 0 | 0 | 0 | `000` |
| ADD   | 1 | `01` | 0 | 0 | 0 | 0 | 0 | `000` |
| ADDM  | 1 | `10` | 0 | 0 | 0 | 0 | 1 | `000` |
| BZ    | 0 | `00` | 0 | 0 | 1 | 0 | 0 | `000` |
| BNZ   | 0 | `00` | 0 | 0 | 1 | 0 | 0 | `000` |
| JMP   | 0 | `00` | 0 | 0 | 0 | 1 | 0 | `000` |
| SUBM  | 1 | `10` | 0 | 0 | 0 | 0 | 1 | `001` |
| LDA   | 1 | `01` | 1 | 0 | 0 | 0 | 1 | `000` |
| MULT  | 1 | `01` | 0 | 0 | 0 | 0 | 0 | `110` |
| MULTM | 1 | `10` | 0 | 0 | 0 | 0 | 1 | `110` |
| DIV   | 1 | `01` | 0 | 0 | 0 | 0 | 0 | `111` |
| DIVM  | 1 | `10` | 0 | 0 | 0 | 0 | 1 | `111` |
| STA   | 0 | `01` | 0 | 1 | 0 | 0 | 1 | `000` |

**Signal definitions:**

| Signal | Effect when asserted |
|---|---|
| `regwrite` | Write ALU or memory result to ACC |
| `alusrc[1:0]` | ALU input B source: `00`=zero, `01`=sign\_ext(imm24), `10`=readdata (M-type instructions) |
| `memtoreg` | Route data-memory read to ACC input (vs. ALU result) |
| `memwrite` | Write ACC to data memory |
| `branch` | Enable conditional branch logic |
| `jump` | Unconditional jump |
| `memaddrsrc` | Use `sign_ext(imm24)` directly as memory address (LDA/STA); 0 = use ALU result |
