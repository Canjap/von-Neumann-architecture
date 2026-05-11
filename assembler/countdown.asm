; Countdown from 5 to 0.
;
; LDA/STA use the immediate as a direct memory address.

; --- Initialize Mem[0] = 5 ---
    ADD  5          ; ACC = 0 + 5 = 5  (ACC is 0 at reset)
    STA  0          ; Mem[0] <- 5

; --- Load countdown start value ---
    LDA  0          ; ACC = Mem[0] = 5

; --- Countdown loop ---
loop:
    ADD  -1         ; ACC = ACC - 1
    NOP
    NOP
    NOP
    BNZ  loop       ; branch back if ACC != 0

; --- Done: ACC == 0, write sentinel and halt ---
    STA  252        ; Mem[252] = 0  (sentinel)
done:
    JMP  done       ; halt
