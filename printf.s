global _start


section .text


_start:         ; Calling printf
                push len
                push msg
                call printf

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
; Enter:    None
; Exit:     None
; Destr:    RAX, RBX, RDX, RDI, RSI
;----------------------------------------

printf:         ; Syscall to output using arguments from stack
                mov rax, 1
                mov rdi, 1
                mov rsi, [rsp+8]
                mov rbx, [rsp+16]
                
                ; Set RDX for char print
                mov rdx, 1

                ; Test length for 0 first
                jmp Test

StrLoop:        ; Format specifier check
                cmp byte [rsi], '%'
                je Special

                ; Print current character
                syscall

                ; To next iteration
                jmp Iterate

Special:        ; Switch statement
                nop

Iterate:        ; Iterate
                inc rsi
                dec rbx      
                
Test:           ; Test
                cmp rbx, 0
                jne StrLoop

                ret

;----------------------------------------


section .data


msg             db "Hello, World!", 10  ; Message to print
len             equ $ - msg             ; Message length
