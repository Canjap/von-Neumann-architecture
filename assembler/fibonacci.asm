; Fibonacci — computes F0 through F9 (0, 1, 1, 2, 3, 5, 8, 13, 21, 34)
; Result: ACC = 34 (F9) after the loop.
;
; Memory layout:
;   Mem[0] = a       (current fib,  starts at 0)
;   Mem[1] = b       (next fib,     starts at 1)
;   Mem[2] = counter (loop counter, starts at 8)
;   Mem[3] = temp    (scratch)

; --- init ---
    MULT 0      ; ACC = 0
    STA  0      ; Mem[0] = 0  (a = F0)
    ADD  1      ; ACC = 1
    STA  1      ; Mem[1] = 1  (b = F1)
    ADD  7      ; ACC = 8
    STA  2      ; Mem[2] = 8  (8 iterations → F2 through F9)

; --- loop ---
loop:
    LDA  1      ; ACC = b
    ADDM 0      ; ACC = a + b  (new b)
    STA  3      ; Mem[3] = new b  (temp)
    LDA  1      ; ACC = b  (becomes new a)
    STA  0      ; Mem[0] = b  (a ← old b)
    LDA  3      ; ACC = new b
    STA  1      ; Mem[1] = new b  (b ← a + b)
    LDA  2      ; ACC = counter
    ADD  -1     ; ACC = counter - 1
    STA  2      ; Mem[2] = counter - 1
    BNZ  loop   ; repeat until counter == 0

; --- done: ACC = 0, load result ---
    LDA  1      ; ACC = F9 = 34
