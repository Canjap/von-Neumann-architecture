# Hand-Compiled Assembly: `leaf.asm`

This document provides a detailed, step-by-step manual compilation of the `leaf.asm` program into machine code based on the our custom ISA. 

## 1. Instruction Set Architecture (ISA) Recap

Before translating, recall the 32-bit instruction format:
```
 31      26 25                         0
┌──────────┬───────────────────────────┐
│  opcode  │           imm26           │
└──────────┴───────────────────────────┘
```
* **Opcode (6 bits):** Determines the instruction.
* **Immediate (26 bits):** Signed 26-bit integer.

### Branching / Jump Formula
According to the ISA specification, jump and branch targets (`CALL`, `JMP`, `BZ`, `BNZ`) are calculated relative to the Program Counter (PC). Because of the pipeline, the PC is effectively `PC + 8` during the execution stage.
* **Formula:** `Target_Address = (PC + 8) + (imm26 * 4)`
* **To solve for imm26:** `imm26 = (Target_Address - PC - 8) / 4`

---

## 2. Program Breakdown & Addresses

We will assign a byte-address (PC) to each instruction. PC starts at `0` and increments by `4`.

```assembly
; ---- main ----
0x00: main:     ADD  5         
0x04:           CALL add_ten   
0x08:           STA  0         
0x0C: done:     JMP  done      

; ---- add_ten ----
0x10: add_ten:  ADD  10        
0x14:           RET            
```

---

## 3. Step-by-Step Translation

### Instruction 1: `ADD 5` (Address `0x00`)
* **Operation:** Accumulator = Accumulator + 5
* **Opcode for ADD:** `0x02` (`000010` in binary)
* **Immediate:** `5` (`0x0000005` in 26-bit hex)
* **Binary Assembly:** `[000010] [00 0000 0000 0000 0000 0000 0101]`
* **Hex Conversion:**
  `0000 1000 0000 0000 0000 0000 0000 0101`
* **Final Machine Code:** **`0x08000005`**

### Instruction 2: `CALL add_ten` (Address `0x04`)
* **Operation:** Save Return Address, Jump to `add_ten` (Target = `0x10`)
* **Opcode for CALL:** `0x0E` (`001110` in binary)
* **Immediate Calculation:** `imm26 = (0x10 - 0x04 - 0x08) / 4`
  `imm26 = (16 - 4 - 8) / 4 = 4 / 4 = 1`
* **Binary Assembly:** `[001110] [00 0000 0000 0000 0000 0000 0001]`
* **Hex Conversion:**
  `0011 1000 0000 0000 0000 0000 0000 0001`
* **Final Machine Code:** **`0x38000001`**

### Instruction 3: `STA 0` (Address `0x08`)
* **Operation:** Store Accumulator into Memory at address 0
* **Opcode for STA:** `0x2B` (`101011` in binary)
* **Immediate:** `0`
* **Binary Assembly:** `[101011] [00 0000 0000 0000 0000 0000 0000]`
* **Hex Conversion:**
  `1010 1100 0000 0000 0000 0000 0000 0000`
* **Final Machine Code:** **`0xAC000000`**

### Instruction 4: `JMP done` (Address `0x0C`)
* **Operation:** Infinite loop jumping to itself (Target = `0x0C`)
* **Opcode for JMP:** `0x06` (`000110` in binary)
* **Immediate Calculation:** `imm26 = (0x0C - 0x0C - 0x08) / 4`
  `imm26 = (12 - 12 - 8) / 4 = -8 / 4 = -2`
* **Two's Complement of -2 (26-bit):** `0x3FFFFFE`
* **Binary Assembly:** `[000110] [11 1111 1111 1111 1111 1111 1110]`
* **Hex Conversion:**
  `0001 1011 1111 1111 1111 1111 1111 1110`
* **Final Machine Code:** **`0x1BFFFFFE`**

### Instruction 5: `ADD 10` (Address `0x10`)
* **Operation:** Accumulator = Accumulator + 10
* **Opcode for ADD:** `0x02` (`000010` in binary)
* **Immediate:** `10` (`0x000000A` in 26-bit hex)
* **Binary Assembly:** `[000010] [00 0000 0000 0000 0000 0000 1010]`
* **Hex Conversion:**
  `0000 1000 0000 0000 0000 0000 0000 1010`
* **Final Machine Code:** **`0x0800000A`**

### Instruction 6: `RET` (Address `0x14`)
* **Operation:** Return to the address stored in the Link Register (LR)
* **Opcode for RET:** `0x0F` (`001111` in binary)
* **Immediate:** Ignored by hardware, assembler sets to `0`.
* **Binary Assembly:** `[001111] [00 0000 0000 0000 0000 0000 0000]`
* **Hex Conversion:**
  `0011 1100 0000 0000 0000 0000 0000 0000`
* **Final Machine Code:** **`0x3C000000`**

---

## 4. Final Hex File Result

Compiling using `assembler.py` would generate a`.hex` file that looks like this:

```hex
08000005
38000001
AC000000
1BFFFFFE
0800000A
3C000000
```
