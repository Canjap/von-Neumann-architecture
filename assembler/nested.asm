; Program 2 — Nested Procedures: main calls outer, outer calls inner.
;
; Call chain: main → outer → inner
; inner is a leaf (adds 7).
; outer is a non-leaf (calls inner, then adds 3 to the result).
; Result: inner(0) + 3 = 7 + 3 = 10.
;
; Calling convention:
;   ACC = argument on entry, ACC = return value on RET
;   Non-leaf: save LR on stack before CALL, restore before RET
;
; Stack frame layout for outer (SP grows downward from 0x100):
;   [SP+0] = saved LR  (one word, popped before RET)
;
; Static scratch: byte-addr 4 used to preserve the result across the
; LR-restore sequence (LDSP clobbers ACC with the saved LR value).
;
; Sentinel: STA 0 writes result (10) to byte-addr 0.

; ---- main ----
main:
    CALL outer      ; word 0: ACC=0 at reset, LR=4 (word 1), jump to outer
    STA  0          ; word 1: Mem[0] = 10  (sentinel)
done:
    JMP  done       ; word 2: halt

; ---- outer: non-leaf ----
; Entry: ACC (unused — outer calls inner with ACC=0)
; Exit:  ACC = 10
outer:
    GETLR           ; word 3: ACC = LR  (= 4, save-point in main)
    ADDSP -4        ; word 4: SP -= 4  (make room)
    STSP            ; word 5: Mem[SP] = LR  (push LR)
    MULT  0         ; word 6: ACC = 0  (argument for inner)
    CALL  inner     ; word 7: LR = 32 (word 8), jump to inner
    ADD   3         ; word 8: ACC = 7 + 3 = 10  (inner returned 7)
    STA   4         ; word 9: Mem[4] = 10  (save result; LDSP below clobbers ACC with LR)
    LDSP            ; word 10: ACC = saved LR  (= 4)
    ADDSP 4         ; word 11: SP += 4  (pop LR)
    SETLR           ; word 12: LR = 4  (restore LR)
    LDA   4         ; word 13: ACC = 10  (reload result)
    RET             ; word 14: PC = LR = 4  (return to word 1 in main)

; ---- inner: leaf ----
; Entry: ACC = 0
; Exit:  ACC = 7
inner:
    ADD   7         ; word 15: ACC = 0 + 7 = 7
    RET             ; word 16: PC = LR = 32 (word 8, return to outer)
