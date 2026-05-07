# Assembly Language Specification — Accumulator Architecture

## Overview

One instruction per line. All instructions are 32 bits wide and share a single format.
The only programmer-visible register is the accumulator (**ACC**).

---

## File Format

```
; this is a comment
# this is also a comment

loop:           ; label (must start with a letter or underscore)
    ADD  -1     ; mnemonic  operand
    BNZ  loop
```

- **Comments**: `;` or `#` to end of line
- **Labels**: `name:` on its own line or immediately before an instruction; must match `[A-Za-z_][A-Za-z0-9_]*`
- **Mnemonics**: case-insensitive (`add`, `ADD`, `Add` all work)
- **Operands**: decimal (`-1`, `5`) or hex (`0xFF`); labels allowed on branch/jump instructions

---

## Instruction Format

Every instruction encodes to a single 32-bit word:

```
 31      26 25  24 23                  0
┌──────────┬──────┬─────────────────────┐
│  opcode  │  00  │        imm24        │
│  [31:26] │ rsvd │       [23:0]        │
└──────────┴──────┴─────────────────────┘
```

`imm24` is a **signed 24-bit** value (two's complement). Range: −8 388 608 to +8 388 607.

---

## Instruction Reference

| Mnemonic | Opcode | Operand | Operation |
|---|---|---|---|
| `NOP` | `0x00` | — | No operation |
| `ADD` | `0x02` | imm | `ACC ← ACC + imm` |
| `BZ` | `0x04` | label / offset | If `ACC == 0`: jump to target |
| `BNZ` | `0x05` | label / offset | If `ACC ≠ 0`: jump to target |
| `JMP` | `0x06` | label / offset | Unconditional jump to target |
| `LDA` | `0x08` | imm | `ACC ← Mem[imm]` |
| `MULT` | `0x10` | imm | `ACC ← ACC × imm` |
| `DIV` | `0x12` | imm | `ACC ← ACC ÷ imm` |
| `STA` | `0x2B` | imm | `Mem[imm] ← ACC` |

---

## Branch and Jump Targets

BZ, BNZ, and JMP all use the same target formula in hardware:

```
branch_target = PC_current + 8 + (imm24 × 4)
```

### Using a label (recommended)

The assembler computes `imm24` automatically:

```
imm24 = (label_byte_address − current_byte_address) / 4 − 2
```

```asm
loop:
    ADD  -1
    BNZ  loop   ; assembler fills in imm24 = -2 (branches back to ADD)
```

### Using a literal offset

`imm24` is a **word offset from PC+2**. Use this only if you need a fixed numeric offset.
A literal of `-6` means: jump to `PC_current + 8 + (−6 × 4) = PC_current − 16`.

---

## Example Program — Countdown from 5 to 0

```asm
; Load the value 5 from data memory (address 5) into ACC.
; Requires Mem[5] = 5 to be pre-loaded in dmem.
    LDA  5

loop:
    ADD  -1         ; ACC = ACC - 1
    NOP
    NOP
    NOP
    BNZ  loop       ; repeat until ACC == 0

; Victory lap
    NOP
    NOP
    NOP
```

Assembled output matches `test_prog.hex`.

---

## Usage

```bash
python3 assembler.py <input.asm> <output.hex>
```

The `.hex` output is loaded into instruction memory via `$readmemh` in `imem.sv`.
