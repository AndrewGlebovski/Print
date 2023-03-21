global _start


section .text


_start:         ; Exit 0
                mov eax, 60
                xor rdi, rdi
                syscall


;----------------------------------------
; Prints data using format string
;
; Arguments order in stack:
;  <variable number of arguments in reverse order>
;  <format string size>;
;  <format string pointer>
;----------------------------------------
; Enter:        None
; Exit:         None
; Destr:        RAX, RBX, RDX, RDI, RSI
;----------------------------------------

Printf:         ; Syscall to output using arguments from stack
                mov rax, 1
                mov rdi, 1
                mov rsi, [rsp+8]
                mov rbx, [rsp+16]
                
                mov rdx, 1

                ; Test length for 0 first
                jmp .Test

.Loop:          ; Format specifier check
                cmp byte [rsi], '%'
                je .Special

                syscall

                inc rsi
                dec rbx

                jmp .Test

.Special:       ; Switch statement (It ain't done yet)

                nop
                inc rsi
                dec rbx
                
.Test:          ; Test
                cmp rbx, 0
                jne .Loop

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


section .data


Result          db 64 dup(0), 10        ; String
Len             equ $ - Result          ; String length

HexTrans        db "0123456789ABCDEF"   ; Hex translator
