; Generate first 10 fibonnacci numbers
;
; --- Initialize Mem[0] = 10 ---
    ADD  10          ; ACC = 0 + 5 = 5  (ACC is 0 at reset)
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

; --- Done: ACC == 0 ---
    NOP
    NOP
    NOP
