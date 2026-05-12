# Project Authors and Contributions

This document details the specific contributions of each team member to the von-Neumann-architecture CPU project. The attributions below reflect the repository's commit history and represent an even distribution of work across SystemVerilog development, testing, tooling, and documentation.

## Team Members
* Sanjay Chemban
* Vishnu Suresh
* Austin Blaylock

---

## 1. SystemVerilog Implementation

### Single-Cycle CPU (`single_cycle_cpu/`)
* **`cpu_datapath.sv`, `cpu_controller.sv`**: Vishnu Suresh 
  * *Responsibility: Designed the core datapath routing and single-cycle control signals.*
* **`cpu_top.sv`, `sc_cpu_top.sv`**: Vishnu Suresh 
  * *Responsibility: Integrated the datapath and controller into the top-level module.*

### Pipelined CPU (`pipelined_cpu/`)
* **`datapath.sv`, `controller.sv`**: Austin Blaylock
  * *Responsibility: Segmented the datapath into pipeline stages and managed pipelined control signals.*
* **`hazard.sv`**: Austin Blaylock
  * *Responsibility: Implemented the hazard detection unit, data forwarding, and pipeline stall logic.*
* **`pipelined_cpu.sv`, `pipelined_cpu_top.sv`**: Austin Blaylock
  * *Responsibility: Top-level integration of the pipelined modules.*

### Shared Components (`shared_components/`)
* **ALU & Accumulator** (`alu.sv`, `aludec.sv`, `eqcmp.sv`, `acc.sv`): Sanjay Chemban
* **Memory & Registers** (`dmem.sv`, `imem.sv`, `ireg.sv`): Sanjay Chemban
* **Combinatorial Logic** (`adder.sv`, `mux2.sv`, `mux3.sv`, `mux4.sv`, `signext.sv`, `sl2.sv`): Sanjay Chemban
* **Control & PC** (`maindec.sv`, `PC.sv`): Sanjay Chemban

---

## 2. Assembler & Tooling

* **`assembler.py`**: Austin Blaylock
  * *Responsibility: Programmed the custom Python assembler to parse the `.asm` files, handle labels/immediates, and generate the hex machine code for instruction memory.*
* **`Makefile` (Single Cycle & Pipelined)**: Austin Blaylock
  * *Responsibility: Created the compilation, simulation, and GTKWave workflow scripts.*

---

## 3. Testing Programs & Testing Scenarios

### Assembly Test Programs (`assembler/`)
* **`countdown.asm` (Simple Program)**: Austin Blaylock
* **`leaf.asm` (Leaf Procedure)**: Austin Blaylock
* **`nested.asm` (Nested Procedure)**: Austin Blaylock
* **`factorial.asm`, `fibonacci.asm` (Recursive Procedures)**: Austin Blaylock

### Verilog Testbenches & Hardware Scenarios
* **`tb_sc_cpu.sv`**: Vishnu Suresh 
  * *Testing Scenario: Verified single-cycle instruction execution, PC incrementing, and memory write-backs.*
* **`tb_pipelined_cpu.sv`**: Austin Blaylock
  * *Testing Scenario: Tested pipeline flushing on branches, verified 2-cycle/3-cycle stalls for `LR` and `SP` updates, and ensured correct continuous execution.*
* **Component-Level Testing** (`alu_tb.sv`, `PC_tb.sv`, `tb_maindec.sv`, `tb_dmem.sv`, `tb_signext.sv`, etc.): Sanjay Chemban
  * *Testing Scenario: Isolated module testing prior to top-level integration.*

---

## 4. Documentation

* **`README.md`**: Sanjay Chemban
  * *Responsibility: Wrote the project overview, quick start instructions, and waveform timing analysis.*
* **`isa.md` & `asm_spec.md`**: Vishnu Suresh 
  * *Responsibility: Documented the custom Instruction Set Architecture, fixed 32-bit format, opcodes, and assembler syntax.*
* **`hand_compiled_leaf.md`**: Sanjay Chemban 
  * *Responsibility: Provided the manual translation and breakdown of the leaf procedure for the rubric requirement.*
* **`FinalRubric.txt` Organization**: Vishnu Suresh 
  * *Responsibility: Ensured all rubric components were met and properly mapped to the repository files.*
