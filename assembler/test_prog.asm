; Pipelined CPU smoke test: countdown from 5 to 0.
; Exercises: immediate ADD, STA, LDA (load-use stall), BNZ (branch flush + stall).
; Completion: stores 0 to byte-addr 252 (dmem word 63) as sentinel.

    ADD  5      ; word 0: ACC = 0+5 = 5  (ACC starts at 0 after reset)
    STA  0      ; word 1: Mem[0] = 5
    LDA  0      ; word 2: ACC = Mem[0] = 5  (load-use stall auto-inserted by hazard unit)
loop:
    ADD  -1     ; word 3: ACC -= 1
    NOP         ; word 4
    NOP         ; word 5
    NOP         ; word 6: NOPs ensure ADD result in WB before BNZ reads ACC
    BNZ  loop   ; word 7: branch if ACC != 0  (imm = 3 - (7+2) = -6)
    STA  252    ; word 8: sentinel — only reached when ACC == 0
