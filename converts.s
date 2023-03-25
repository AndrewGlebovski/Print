;----------------------------------------
; Converts argument to hexadecimal format and writes result to buffer
; !!! Buffer must be at least 16 bytes size
;----------------------------------------
; Enter:        RAX = integer, RDI = buffer address
; Exit:         None
; Destr:        RAX, RBX, RCX
;----------------------------------------

PrtHex:         ; Set loop length
                mov rcx, HexBufSize - 1

.Loop:          mov rbx, rax
                and rbx, 0x0f

                mov bl, HexTrans[rbx]
                mov [rdi, rcx], bl

                dec rcx
                shr rax, 4
                jne .Loop

                jmp .Test

                ; Set forward zeros
.Next           mov byte [rdi, rcx], 0
                dec rcx
.Test           cmp rcx, -1
                jne .Next

                ret

;----------------------------------------


;----------------------------------------
; Converts argument to octal format and writes result to buffer
; !!! Buffer must be at least 22 bytes size
;----------------------------------------
; Enter:        RAX = integer, RDI = buffer address
; Exit:         None
; Destr:        RAX, RBX, RCX
;----------------------------------------

PrtOct:         ; Set loop length
                mov rcx, OctBufSize - 1

.Loop:          mov rbx, rax
                and rbx, 7
                add rbx, '0'

                mov [rdi, rcx], bl

                dec rcx
                shr rax, 3
                jne .Loop

                jmp .Test

                ; Set forward zeros
.Next           mov byte [rdi, rcx], 0
                dec rcx
.Test           cmp rcx, -1
                jne .Next

                ret

;----------------------------------------


;----------------------------------------
; Converts argument to binary format and writes result to buffer
; !!! Buffer must be at least 64 bytes size
;----------------------------------------
; Enter:        RAX = integer, RDI = buffer address
; Exit:         None
; Destr:        RAX, RBX, RCX
;----------------------------------------

PrtBin:         ; Set loop length
                mov rcx, BinBufSize - 1

.Loop:          mov bl, al
                and bl, 1
                add bl, '0'

                mov [rdi, rcx], bl

                dec rcx
                shr rax, 1

                cmp rax, 0
                jne .Loop

                jmp .Test

                ; Set forward zeros
.Next           mov byte [rdi, rcx], 0
                dec rcx
.Test           cmp rcx, -1
                jne .Next

                ret

;----------------------------------------


;----------------------------------------
; Converts argument to decimal format and writes result to buffer
; !!! Buffer must be at least 20 bytes size
;----------------------------------------
; Enter:        RAX = integer, RDI = buffer address
; Exit:         None
; Destr:        RAX, RBX, RCX, RDX
;----------------------------------------

PrtDec:         ; Set high order bits of RAX to low order bits of RDX and set loop length
                mov rdx, rax
                shr rdx, 32

                mov rcx, DecBufSize - 1
                mov rbx, 10

                ; Set digits
.Loop:          div ebx
                add dl, '0'

                mov [rdi, rcx], dl

                xor rdx, rdx
                dec rcx

                cmp eax, 0
                jne .Loop

                jmp .Test

                ; Set forward zeros
.Next           mov byte [rdi, rcx], 0
                dec rcx
.Test           cmp rcx, -1
                jne .Next

                ret

;----------------------------------------
