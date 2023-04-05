global _start


extern printf


section .text


CallExit        equ 60


_start:         ; Set arguments
                test rsp, 0xF
                je .Skip1

                push 0

.Skip1:         push 0
                push 33
                push 100
                push 3802
                push Str2
                push -1

                mov r9, Example
                mov r8, 0x21
                mov rcx, 2147483647
                mov rdx, 2147483647
                mov rsi, 2147483647
                mov rdi, FormatStr

                xor rax, rax

                call printf

                ; Exit 0
                mov eax, CallExit
                xor rdi, rdi
                syscall


section .data


Example         db "Hello, World!", 0
Str2            db "Love", 0
FormatStr       db "Dec: %d", 10, "Hex: %x", 10, "Oct: %o", 10, "Chr: %c", 10, "Str: %s", 10, "Pro: %%", 10, "%d %s %x %d%%%c", 10, 0
