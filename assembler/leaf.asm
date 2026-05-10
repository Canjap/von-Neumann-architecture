; Program 1 — Leaf Procedure: computes add_ten(5) = 15.
;
; A leaf procedure makes no further CALL, so LR does not need to be
; saved or restored — no stack frame required.
;
; Calling convention:
;   ACC = argument on entry, ACC = return value on RET
;
; Sentinel: STA 0 writes result (15) to byte-addr 0.

; ---- main ----
main:
    ADD  5          ; word 0: ACC = 5  (argument)
    CALL add_ten    ; word 1: LR = 8 (word 2), jump to add_ten
    STA  0          ; word 2: Mem[0] = 15  (sentinel)
done:
    JMP  done       ; word 3: halt

; ---- add_ten(n): returns n + 10 ----
; Entry: ACC = n
; Exit:  ACC = n + 10
; Leaf: no stack frame needed.
add_ten:
    ADD  10         ; word 4: ACC = 5 + 10 = 15
    RET             ; word 5: PC = LR = 8  (return to word 2 in main)
