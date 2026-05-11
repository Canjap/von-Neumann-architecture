# von-Neumann-architecture (ECE251 Final Project)

**Team:** Sanjay Chemban, Vishnu Suresh, and Austin Blaylock.

## Project Overview

This project implements a custom Accumulator Architecture CPU. Unlike a general-purpose register file architecture, this design uses a single 32-bit accumulator register as the implicit source and destination for all ALU operations.

The repository includes:

* A **Single-Cycle CPU** implementation.
* A **Pipelined CPU** implementation with hazard detection and stalling.
* A custom **Python-based Assembler**.
* A set of assembly programs (Fibonacci, Factorial, etc.) to demonstrate functionality.

---

## ISA Specification

The Instruction Set Architecture (ISA) is a fixed-width 32-bit format.

### Key Parameters

* **ALU Operand Size:** 32 bits.
* **Address Bus:** 32 bits (byte-addressed).
* **Instruction Size:** 32 bits (fixed).
* **Registers:** * `ACC`: Accumulator (Implicit ALU source/destination).
* `PC`: Program Counter.
* `LR`: Link Register (Holds return addresses for `CALL`/`RET`).
* `SP`: Stack Pointer (Initialized to `0x100`, grows downward).

### Instruction Format

```
 31      26 25  24 23                  0
┌──────────┬──────┬─────────────────────┐
│  opcode  │ rsvd │        imm24        │
└──────────┴──────┴─────────────────────┘

```

* **Opcode:** 6 bits.
* **imm24:** 24-bit signed immediate used for arithmetic, memory addresses, or branch offsets.

### Instruction Subset

| Mnemonic | Opcode | Description |
| --- | --- | --- |
| `LDA` / `STA` | `0x08` / `0x2B` | Load/Store Accumulator from Memory. |
| `ADD` / `MULT` | `0x02` / `0x10` | ACC = ACC + (Immediate) / ACC * (Immediate). |
| `ADDM` / `SUBM` | `0x03` / `0x07` | ALU operation using a value from Memory. |
| `BZ` / `BNZ` | `0x04` / `0x05` | Branch if ACC is Zero / Not Zero. |
| `CALL` / `RET` | `0x0E` / `0x0F` | Procedure call (save PC+4 to LR) and Return. |
| `STSP` / `LDSP` | `0x15` / `0x16` | Stack-based Store/Load. |

---

## Quick Start Instructions

### 1. Assemble Programs

Before running the processor, convert your assembly (`.asm`) code into a hex file that the hardware can read.

```bash
cd assembler
python3 assembler.py <input_file.asm> <output_file.hex>

```

### 2. Simulate Single-Cycle CPU

To run the single-cycle implementation:

```bash
cd single_cycle_cpu
make
# This will compile the SystemVerilog files and run the testbench (tb_sc_cpu.sv)

```

### 3. Simulate Pipelined CPU

The pipelined version handles hazards and includes the same instruction support.

```bash
cd pipelined_cpu
make
# This will compile the SystemVerilog files and run the testbench (tb_pipelined_cpu.sv)

```

---

## Memory Layout and Addressing

* **Instruction Memory:** 32-bit words, byte-addressed (PC increments by 4).
* **Data Memory:** Word-aligned via `addr[7:2]`. Although byte addresses are used in code, the hardware indexes word-aligned locations.
* **Stack:** The `SP` register starts at `0x100`. Use `ADDSP` to allocate space and `STSP`/`LDSP` to save/restore the Accumulator.

## Hazard Management (Pipelined Only)

The Pipelined CPU includes hardware-level stall logic. However, the assembly language specification notes specific timing considerations:

* **SP Updates:** Up to 3 stall cycles may be inserted between `ADDSP` and subsequent stack operations.
* **Link Register:** 2 stall cycles between `SETLR` and `RET`/`GETLR`.

## Project Rubric Compliance

This implementation covers the following requirements from the Final Rubric:

* **ISA Design:** Full 32-bit specification, including J-type and I-type support.
* **Processor Design:** Implementation of `maindec`, `aludec`, and functional datapaths for both single-cycle and pipelined designs.
* **Documentation:** Detailed timing and design explanations provided in `isa.md` and `asm_spec.md`.
