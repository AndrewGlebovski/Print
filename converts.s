;----------------------------------------
; Prints data using format string
;
; Arguments order in stack:
;  <integer to print>
;  <buffer to print>
;----------------------------------------
; Enter:        None
; Exit:         None
; Destr:        RAX, RBX, RCX, RSI
;----------------------------------------

PrtHex:         ; Set argument in RAX
                mov rax, [rsp+16]
                mov rsi, [rsp+8]

                mov rcx, 15

.Loop:          mov rbx, rax
                and rbx, 0x0f

                mov bl, HexTrans[rbx]
                mov [rsi, rcx], bl

                dec rcx
                shr rax, 4
                jne .Loop

                jmp .Test

                ; Set forward zeros
.Next           mov byte [rsi, rcx], 0
                dec rcx
.Test           cmp rcx, -1
                jne .Next

                ret

;----------------------------------------


;----------------------------------------
; Prints data using format string
;
; Arguments order in stack:
;  <integer to print>
;  <buffer to print>
;----------------------------------------
; Enter:        None
; Exit:         None
; Destr:        RAX, RBX, RCX, RSI
;----------------------------------------

PrtBin:         ; Set argument in RAX
                mov rax, [rsp+16]
                mov rsi, [rsp+8]

                mov rcx, 63

.Loop:          mov bl, al
                and bl, 1
                add bl, '0'

                mov [rsi, rcx], bl

                dec rcx
                shr rax, 1

                cmp rax, 0
                jne .Loop

                jmp .Test

                ; Set forward zeros
.Next           mov byte [rsi, rcx], 0
                dec rcx
.Test           cmp rcx, -1
                jne .Next

                ret

;----------------------------------------


;----------------------------------------
; Prints data using format string
;
; Arguments order in stack:
;  <integer to print>
;  <buffer to print>
;----------------------------------------
; Enter:        None
; Exit:         None
; Destr:        RAX, RBX, RCX, RDX, RSI
;----------------------------------------

PrtDec:         ; Set argument
                mov rax, [rsp+16]
                mov rdx, rax
                shr rdx, 32
                mov rsi, [rsp+8]

                mov rcx, 19
                mov rbx, 10

                ; Set digits
.Loop:          div ebx
                add dl, '0'

                mov [rsi, rcx], dl

                xor rdx, rdx
                dec rcx

                cmp eax, 0
                jne .Loop

                jmp .Test

                ; Set forward zeros
.Next           mov byte [rsi, rcx], 0
                dec rcx
.Test           cmp rcx, -1
                jne .Next

                ret

;----------------------------------------
