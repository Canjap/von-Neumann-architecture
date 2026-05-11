import sys
import re

opcodes = {
    'nop':   0x00,
    'add':   0x02,
    'addm':  0x03,
    'bz':    0x04,
    'bnz':   0x05,
    'jmp':   0x06,
    'subm':  0x07,
    'lda':   0x08,
    'mult':  0x10,
    'multm': 0x11,
    'div':   0x12,
    'divm':  0x13,
    'sta':   0x2B,
    # Procedure support (P1-P3)
    'call':  0x0E,
    'ret':   0x0F,
    'addsp': 0x14,
    'stsp':  0x15,
    'ldsp':  0x16,
    'getlr': 0x17,
    'setlr': 0x18,
}

branch_ops = {'bz', 'bnz', 'jmp', 'call'}

# Instructions that take no operand (imm = 0)
no_operand_ops = {'nop', 'ret', 'stsp', 'ldsp', 'getlr', 'setlr'}

def assemble(asm_file, exe_file):
    with open(asm_file, 'r') as f:
        content = f.read()

    content = content.replace('−', '-')  # replace unicode minus with hyphen
    lines = content.split('\n')

    labels = {}
    instructions = []

    # Pass 1
    pc = 0
    for line in lines:
        line = re.split(r'[;#]', line)[0].strip()
        if not line or line.startswith('.end'): continue
        if line.startswith('.org'):
            target_addr = int(line.split()[1], 0) // 4
            while pc < target_addr:
                instructions.append((pc, 'nop'))
                pc += 1
            continue
        elif ':' in line:
            label, rest = line.split(':', 1)
            labels[label.strip()] = pc
            if rest.strip():
                instructions.append((pc, rest.strip()))
                pc += 1
        else:
            instructions.append((pc, line.strip()))
            pc += 1

    # Pass 2
    machine_code = []
    for pc, inst in instructions:
        parts = [p.strip() for p in re.split(r'[\s,]+', inst) if p.strip()]
        op = parts[0].lower()

        if op not in opcodes:
            print(f"Unknown op: {op}")
            sys.exit(1)

        if op in no_operand_ops:
            imm = 0
        elif op in branch_ops:
            target = parts[1]
            if target in labels:
                imm = labels[target] - (pc + 2)
            else:
                imm = int(target)
        else:
            imm = int(parts[1], 0)

        machine_code.append(f"{(opcodes[op] << 26) | (imm & 0x3FFFFFF):08x}")

    with open(exe_file, 'w') as f:
        for c in machine_code:
            f.write(c + '\n')

    print(f"Compiled {len(machine_code)} instructions to {exe_file}")

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: python3 assembler.py <input.asm> <output.hex>")
        sys.exit(1)
    assemble(sys.argv[1], sys.argv[2])
