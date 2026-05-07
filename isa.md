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
| `0x00` | NOP | No operation |
| `0x02` | ADD | `ACC ← ACC + sign_ext(imm24)` |
| `0x04` | BZ | If `ACC == 0`: `PC ← branch_target` |
| `0x05` | BNZ | If `ACC ≠ 0`: `PC ← branch_target` |
| `0x08` | LDA | `ACC ← Mem[ACC + sign_ext(imm24)]` |
| `0x10` | MULT | `ACC ← ACC × sign_ext(imm24)` |
| `0x12` | DIV | `ACC ← ACC ÷ sign_ext(imm24)` |
| `0x2B` | STA | `Mem[ACC + sign_ext(imm24)] ← ACC` |

> **Addressing note:** LDA and STA use base+offset addressing where ACC is the base register.
> At reset (ACC = 0), `LDA addr` and `STA addr` reduce to direct addressing.

---

## Sign Extension

`imm24` is sign-extended from bit 23 to fill a 32-bit value before use:

```
sign_ext(imm24) = { {8{imm24[23]}}, imm24[23:0] }
```

---

## Branch Target Calculation

Branch instructions compute their target relative to the **next** instruction's address.
Due to the registered PC design, `pc_out` at decode time already holds `PC_current + 4`.

```
branch_target = (pc_out + 4) + (sign_ext(imm24) << 2)
              = PC_current + 8 + (sign_ext(imm24) × 4)
```

The immediate is a **word offset** (each unit = 4 bytes). Negative values branch backward.

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
| NOP, ADD, LDA, STA, BZ, BNZ | `000` | All use ADD for address/immediate arithmetic |
| MULT | `110` | Selects MULT |
| DIV | `111` | Selects DIV |

> SUB, AND, OR, SLT, NOR are available in the ALU but have no assigned opcodes yet.

---

## Control Signal Truth Table

Derived from `maindec.sv`. `aluop` shown in 3-bit form (updated from current 2-bit implementation).

| Instruction | `regwrite` | `alusrc` | `memtoreg` | `memwrite` | `branch` | `jump` | `aluop[2:0]` |
|---|---|---|---|---|---|---|---|
| NOP | 0 | 0 | 0 | 0 | 0 | 0 | `000` |
| ADD | 1 | 1 | 0 | 0 | 0 | 0 | `000` |
| BZ | 0 | 0 | 0 | 0 | 1 | 0 | `000` |
| BNZ | 0 | 0 | 0 | 0 | 1 | 0 | `000` |
| LDA | 1 | 1 | 1 | 0 | 0 | 0 | `000` |
| MULT | 1 | 1 | 0 | 0 | 0 | 0 | `110` |
| DIV | 1 | 1 | 0 | 0 | 0 | 0 | `111` |
| STA | 0 | 1 | 0 | 1 | 0 | 0 | `000` |

**Signal definitions:**

| Signal | Effect when asserted |
|---|---|
| `regwrite` | Write ALU or memory result to ACC |
| `alusrc` | Drive `sign_ext(imm24)` as ALU input B (0 = drive 0) |
| `memtoreg` | Route data-memory read to ACC input (vs. ALU result) |
| `memwrite` | Write ACC to data memory |
| `branch` | Enable conditional branch logic |
| `jump` | Unconditional jump (no opcode assigned yet) |

---

## Implementation Notes

- **`maindec.sv`** must be updated to output 3-bit `aluop` (currently 2-bit). The MULT and DIV encodings change from `2'b10`/`2'b11` to `3'b110`/`3'b111`.
- **`fetch_tb.sv`** does not connect the `memtoreg` mux — the ACC is wired directly to `alu_out`. LDA therefore behaves as load-immediate in that testbench. The full datapath integration must wire a 2:1 mux on ACC's write data, selecting between `alu_out` and `dmem.rd` based on `memtoreg`.
- **Authoritative modules:** `alu/alu.sv`, `alu/aludec.sv`, `alu/eqcmp.sv`, `combinatorial components/` (adder, signext, sl2, mux2/3/4).
