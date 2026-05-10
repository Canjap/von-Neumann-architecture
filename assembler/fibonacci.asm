; Fibonacci — computes F0 through F9 (0, 1, 1, 2, 3, 5, 8, 13, 21, 34)
; Result: ACC = 34 (F9), written to sentinel byte-addr 252.
;
; Memory layout (byte-addressed, word-aligned — dmem uses a[7:2]):
;   byte  0 = a       (current fib,  starts at 0)
;   byte  4 = b       (next fib,     starts at 1)
;   byte  8 = counter (loop counter, starts at 8)
;   byte 12 = temp    (scratch)

; --- init ---
    MULT 0      ; ACC = 0
    STA  0      ; Mem[0]  = 0  (a = F0)
    ADD  1      ; ACC = 1
    STA  4      ; Mem[4]  = 1  (b = F1)
    ADD  7      ; ACC = 8
    STA  8      ; Mem[8]  = 8  (8 iterations → F2 through F9)

; --- loop ---
loop:
    LDA  4      ; ACC = b
    ADDM 0      ; ACC = a + b  (new b)
    STA  12     ; Mem[12] = new b  (temp)
    LDA  4      ; ACC = b  (becomes new a)
    STA  0      ; Mem[0]  = b  (a ← old b)
    LDA  12     ; ACC = new b
    STA  4      ; Mem[4]  = new b  (b ← a + b)
    LDA  8      ; ACC = counter
    ADD  -1     ; ACC = counter - 1
    STA  8      ; Mem[8]  = counter - 1
    BNZ  loop   ; repeat until counter == 0

; --- done ---
    LDA  4      ; ACC = F9 = 34
    STA  252    ; sentinel: write result to byte-addr 252 (dmem word 63)
