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
| `NOP`   | `0x00` | —           | No operation |
| `ADD`   | `0x02` | imm         | `ACC ← ACC + imm` |
| `ADDM`  | `0x03` | addr        | `ACC ← ACC + Mem[addr]` |
| `BZ`    | `0x04` | label / offset | If `ACC == 0`: jump to target |
| `BNZ`   | `0x05` | label / offset | If `ACC ≠ 0`: jump to target |
| `JMP`   | `0x06` | label / offset | Unconditional jump to target |
| `SUBM`  | `0x07` | addr        | `ACC ← ACC − Mem[addr]` |
| `LDA`   | `0x08` | addr        | `ACC ← Mem[addr]` |
| `MULT`  | `0x10` | imm         | `ACC ← ACC × imm` |
| `MULTM` | `0x11` | addr        | `ACC ← ACC × Mem[addr]` |
| `DIV`   | `0x12` | imm         | `ACC ← ACC ÷ imm` |
| `DIVM`  | `0x13` | addr        | `ACC ← ACC ÷ Mem[addr]` |
| `STA`   | `0x2B` | addr        | `Mem[addr] ← ACC` |
| `CALL`  | `0x0E` | label / offset | `LR ← PC+4; PC ← target` |
| `RET`   | `0x0F` | —           | `PC ← LR` |
| `ADDSP` | `0x14` | imm         | `SP ← SP + imm` |
| `STSP`  | `0x15` | —           | `Mem[SP] ← ACC` |
| `LDSP`  | `0x16` | —           | `ACC ← Mem[SP]` |
| `GETLR` | `0x17` | —           | `ACC ← LR` |
| `SETLR` | `0x18` | —           | `LR ← ACC` |

---

## Stack and Procedure Calls

The stack pointer **SP** resets to `0x100` (256) and grows **downward**. All stack accesses are word-aligned (multiples of 4).

### CALL and RET

```asm
    CALL  proc      ; LR = address of next instruction; jump to proc
    ; ... execution resumes here after RET

proc:
    ; body
    RET             ; PC ← LR
```

### Push and pop sequences

Since there is no single PUSH/POP instruction, use two-instruction sequences:

```asm
; Push ACC onto stack:
    ADDSP -4        ; SP = SP - 4
    STSP            ; Mem[SP] = ACC

; Pop ACC from stack:
    LDSP            ; ACC = Mem[SP]
    ADDSP 4         ; SP = SP + 4

; Push LR onto stack (save return address before a nested CALL):
    GETLR           ; ACC = LR
    ADDSP -4        ; SP = SP - 4
    STSP            ; Mem[SP] = LR

; Pop LR from stack (restore return address):
    LDSP            ; ACC = Mem[SP]
    ADDSP 4         ; SP = SP + 4
    SETLR           ; LR = ACC
```

### Calling convention

- **Argument**: ACC on entry to callee
- **Return value**: ACC on RET
- **Non-leaf functions** must save LR before any nested CALL and restore it before RET
- Stack space is limited to the dmem size (256 bytes); reserve the lower addresses for static data

### Hazard notes

The hardware inserts stall cycles automatically:
- Up to 3 stall cycles between `ADDSP` and `STSP`/`LDSP` (SP register takes 3 cycles to update)
- 2 stall cycles between `SETLR` and `RET`/`GETLR`
- No stall needed between `CALL` and `RET` (LR is written immediately in the decode stage)

---

## Memory Addressing

All `addr` operands (LDA, STA, ADDM, SUBM, MULTM, DIVM) are **byte addresses**. The data memory is word-addressed internally using `addr[7:2]`, so the lower two bits are ignored. Addresses must be **multiples of 4** to access distinct words.

| Word | Byte address to use |
|------|---------------------|
| 0    | 0                   |
| 1    | 4                   |
| 2    | 8                   |
| 3    | 12                  |
| n    | n × 4               |

Using consecutive integers (0, 1, 2, …) as addresses is a common mistake — they all resolve to word 0.

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
