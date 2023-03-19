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
; Destr:    RAX, RDX, RDI, RSI
;----------------------------------------

printf:         ; Syscall to output using arguments from stack
                mov rax, 1
                mov rdi, 1
                mov rsi, [rsp+8]
                mov rdx, [rsp+16]
                syscall

                ret

;----------------------------------------


section .data


msg             db "Hello, World!", 10  ; Message to print
len             equ $ - msg             ; Message length
