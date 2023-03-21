global _start


section .text


_start:         mov r10, 0xFFFFFF
                push r10
                push Result
                call PrtHex

                mov qword [rsp+8], Len
                call Printf

                ; Exit 0
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


%include "converts.s"


section .data


Result          db 64 dup(0), 10        ; String
Len             equ $ - Result          ; String length

HexTrans        db "0123456789ABCDEF"   ; Hex translator
