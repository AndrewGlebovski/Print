global _start


section .text


CallWrite       equ 1
CallExit        equ 60

StdOut          equ 1

QWordSize       equ 8
DWordSize       equ 4
WordSize        equ 2
ByteSize        equ 1

BinBufSize      equ 64
OctBufSize      equ 22
DecBufSize      equ 20
HexBufSize      equ 16


_start:         ; Set arguments
                sub rsp, 25
                mov qword [rsp+17], Example
                mov byte [rsp+16], 0x21
                mov dword [rsp+12], 40000000
                mov dword [rsp+8], 40000000
                mov dword [rsp+4], 40000000
                mov dword [rsp], 40000000
                push FormatStrLen
                push FormatStr

                call Printf

                ; Exit 0
                mov eax, CallExit
                xor rdi, rdi
                syscall


;----------------------------------------
; Prints data using format string
;
; Arguments order in stack:
;  <arguments in reverse order>
;  <format string size>
;  <format string pointer>
;----------------------------------------
; Enter:        None
; Exit:         RAX = 1 - something went wrong | 0 - ok
; Destr:        RAX, RBX, RCX, RDX, RDI, RSI, R10, R11
;----------------------------------------

Printf:         ; Save RBP
                push rbp
                mov rbp, rsp            ; RBP always points to current argument

                ; Set arguments from stack
                mov rax, CallWrite
                mov rdi, ByteSize
                mov rsi, [rsp+16]
                mov r10, [rsp+24]
                
                mov rdx, ByteSize
                add rbp, 32             ; Skip return address, format string address and size
                add r10, rsi

                ; Test length for 0 first
                jmp .Test

.Loop:          ; Format specifier check
                cmp byte [rsi], '%'
                je .Special

                syscall

                inc rsi

                jmp .Test

.Special:       ; Special format case
                inc rsi
                xor rax, rax
                mov al, byte [rsi]

                cmp rax, '%'
                jne .Switch

                ; Print '%'
                mov rax, CallWrite

                syscall

                inc rsi

                jmp .Loop

.Switch:        ; My switch implementation
                sub rax, 'b'

                cmp rax, 'x' - 'b'
                ja .error

                jmp JumpTable[rax * QWordSize]

.b:             ; Binary print
                push rsi

                mov eax, [rbp]
                mov rsi, Buffer
                call PrtBin

                add rbp, DWordSize

                mov rax, CallWrite
                mov rdx, BinBufSize

                jmp .Write

.c:             ; Character print
                push rsi

                mov rsi, rbp

                inc rbp

                jmp .Write

.d:             ; Decimal print
                push rsi

                mov eax, [rbp]
                mov rsi, Buffer
                call PrtDec

                add rbp, DWordSize

                mov rax, CallWrite
                mov rdx, DecBufSize

                jmp .Write

.o:             ; Octal print
                push rsi

                mov eax, [rbp]
                mov rsi, Buffer
                call PrtOct

                add rbp, DWordSize

                mov rax, CallWrite
                mov rdx, OctBufSize

                jmp .Write

.s:             ; String print
                push rsi

                mov rsi, [rbp]
                call StrLen

                mov rdx, rax
                mov rax, CallWrite

                add rbp, QWordSize

                jmp .Write

.x:             ; Hexadecimal print
                push rsi

                mov eax, [rbp]
                mov rsi, Buffer
                call PrtHex

                add rbp, DWordSize

                mov rax, CallWrite
                mov rdx, HexBufSize

                jmp .Write

.error:         ; Unknown format (Restore RBP and return immediately)
                pop rbp

                ; Exit code 1
                mov rax, 1

                ret

.Write:         ; Write result to stdout
                syscall

                pop rsi

                mov rax, CallWrite
                mov rdx, ByteSize

                inc rsi
                
.Test:          ; Test
                cmp rsi, r10
                jne .Loop

                ; Restore RBP
                pop rbp

                ; Exit code 0
                xor rax, rax

                ret

;----------------------------------------


;----------------------------------------
; Returns string length
;----------------------------------------
; Enter:        RSI = string address
; Exit:         RAX = string size
; Destr:        RAX
;----------------------------------------

StrLen:         xor rax, rax

.Loop:          ; While [rsi] != '\0'
                cmp byte [rsi, rax], 0
                je .Finish

                inc rax

                jmp .Loop

.Finish         ret

;----------------------------------------


%include "converts.s"


section .data


Example         db "Hello, World!", 0
FormatStr       db "Dec: %d", 10, "Hex: %x", 10, "Oct: %o", 10, "Bin: %b", 10, "Chr: %c", 10, "Str: %s", 10, "Pro: %%", 10
FormatStrLen    equ $ - FormatStr

Buffer          db 64 dup(0)            ; Result buffer for convert functions
BufSize         equ $ - Buffer          ; Result buffer length



section .rodata


align 8
JumpTable:
        dq Printf.b
        dq Printf.c
        dq Printf.d
        dq Printf.error
        dq Printf.error
        dq Printf.error
        dq Printf.error
        dq Printf.error
        dq Printf.error
        dq Printf.error
        dq Printf.error
        dq Printf.error
        dq Printf.error
        dq Printf.o
        dq Printf.error
        dq Printf.error
        dq Printf.error
        dq Printf.s
        dq Printf.error
        dq Printf.error
        dq Printf.error
        dq Printf.error
        dq Printf.x

HexTrans        db "0123456789ABCDEF"   ; Hex translator
