; Recursive factorial: computes factorial(4) = 24.
; Exercises CALL, RET, ADDSP, STSP, LDSP, GETLR, SETLR.
;
; Calling convention:
;   - ACC = argument on entry, ACC = return value on RET
;   - Non-leaf: save LR and n on stack before recursive CALL
;
; Stack frame layout (SP points to lowest used byte):
;   [SP+0] = n         (pushed second)
;   [SP+4] = saved LR  (pushed first)
;
; Static scratch: byte-addr 252 (dmem word 63) used as temp between
; CALL and the multiply. Safe because each level writes it immediately
; after the recursive call returns, before reading it.
;
; Sentinel: STA 0 writes result (24) to byte-addr 0 for testbench.

; ---- main ----
main:
    ADD  4          ; word 0: ACC = 4  (argument)
    CALL fact       ; word 1: LR = 8, jump to fact
    STA  0          ; word 2: Mem[0] = factorial(4) = 24  (sentinel)
done:
    JMP  done       ; word 3: halt

; ---- fact(n) ----
; Entry: ACC = n
; Exit:  ACC = n!
fact:
    BZ   base       ; word 4: if n == 0, return 1

    ; save n to static temp (safe before any nested CALL overwrites it)
    STA  252        ; word 5: Mem[252] = n

    ; push LR
    GETLR           ; word 6: ACC = LR
    ADDSP -4        ; word 7: SP -= 4
    STSP            ; word 8: Mem[SP] = LR

    ; push n (reload from temp)
    LDA  252        ; word 9: ACC = n
    ADDSP -4        ; word 10: SP -= 4
    STSP            ; word 11: Mem[SP] = n

    ; compute n-1 and recurse
    LDA  252        ; word 12: ACC = n
    ADD  -1         ; word 13: ACC = n-1
    CALL fact       ; word 14: LR = word15*4=60, recurse; returns ACC=(n-1)!

    ; on return: ACC = (n-1)!
    ; save result to temp, load n from stack, multiply
    STA  252        ; word 15: Mem[252] = (n-1)!
    LDSP            ; word 16: ACC = n  (top of stack)
    ADDSP 4         ; word 17: pop n
    MULTM 252       ; word 18: ACC = n * (n-1)! = n!

    ; restore LR from stack
    LDSP            ; word 19: ACC = saved LR
    ADDSP 4         ; word 20: pop LR
    SETLR           ; word 21: LR = saved LR

    RET             ; word 22: PC = LR

; ---- base case: 0! = 1 ----
base:
    ADD  1          ; word 23: ACC = 0+1 = 1
    RET             ; word 24: PC = LR
