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

BufSize         equ 512
ExtraSize       equ 64


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
; Flush buffer to STDOUT
;----------------------------------------
; Enter:        None
; Exit:         None
; Destr:        RAX, RDX, RDI, RSI
;----------------------------------------

%macro          FlushBuf 0

                sub rdi, Buffer
                mov rdx, rdi
                mov rax, CallWrite
                mov rdi, StdOut
                mov rsi, Buffer
                syscall

%endmacro

;----------------------------------------


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
                mov rsi, [rsp+16]
                mov rdi, Buffer

                mov r10, [rsp+24]
                add r10, rsi

                add rbp, 32             ; Skip return address, format string address and size

                ; Test length for 0 first
                jmp .Test

.Loop:          ; Format specifier check
                cmp byte [rsi], '%'
                je .Special

                movsb
                jmp .Test

.Special:       ; Special format case
                inc rsi
                xor rax, rax
                mov al, byte [rsi]

                cmp rax, '%'
                jne .Switch

                ; Print '%'
                movsb
                jmp .Test

.Switch:        ; My switch implementation
                inc rsi                 ; Update RSI manually

                sub rax, 'b'
                cmp rax, 'x' - 'b'
                ja .error

                jmp JumpTable[rax * QWordSize]

.b:             ; Binary print
                mov eax, [rbp]
                call PrtBin

                add rbp, DWordSize      ; To next arg in stack

                add rdi, BinBufSize     ; Update RDI manually

                jmp .Test

.c:             ; Character print
                mov rax, rsi            ; Save RSI

                mov rsi, rbp
                movsb

                mov rsi, rax             ; Restore RSI

                inc rbp                 ; To next arg in stack

                jmp .Test

.d:             ; Decimal print
                mov eax, [rbp]
                call PrtDec

                add rbp, DWordSize      ; To next arg in stack

                add rdi, DecBufSize     ; Update RSI (and RDI) manually

                jmp .Test

.o:             ; Octal print
                mov eax, [rbp]
                call PrtDec

                add rbp, DWordSize      ; To next arg in stack

                add rdi, OctBufSize     ; Update RSI (and RDI) manually

                jmp .Test

.s:             ; String print
                push rsi                ; Save RSI

                mov rsi, [rbp]
                call StrLen             ; RAX = string length

                cmp rax, RealBufSize    ; Check if string is bigger than whole buffer
                jb .SmallStr

                push rax                ; Save original length

                FlushBuf                ; Flush buffer

                pop rdx                 ; Restore length
                mov rsi, [rbp]
                mov rax, CallWrite
                mov rdi, StdOut
                syscall                 ; Flush string

                mov rdi, Buffer         ; Set RDI manually

                jmp .Update

.SmallStr:      ; Check if string overflowing buffer
                mov rcx, rdi
                add rcx, rax
                cmp rcx, Buffer + RealBufSize
                jbe .NoOverflow
                
                mov rcx, Buffer + RealBufSize
                sub rcx, rdi            ; RCX = Amount of symbols needed to fill buffer
                sub rax, rcx            ; RAX = Amount of symbols left after buffer filled
                push rax                ; Save symbols that left in string to print

                rep movsb               ; Fill buffer to it's maximum

                FlushBuf                ; Flush buffer
                mov rdi, Buffer         ; Set RDI manually

                pop rax                 ; Restore symbols that left to read
                mov rsi, [rbp]          ; Set RSI to string again

.NoOverflow:    ; Write string to buffer
                mov rcx, rax
                rep movsb

.Update:        ; Update and restore some params
                add rbp, QWordSize      ; To next arg in stack

                pop rsi                 ; Restore RSI

                jmp .Test

.x:             ; Hexadecimal print
                mov eax, [rbp]
                call PrtDec

                add rbp, DWordSize      ; To next arg in stack

                add rdi, HexBufSize     ; Update RDI manually

                jmp .Test

.error:         ; Unknown format (Restore RBP and return immediately)
                pop rbp

                mov rax, 1              ; Exit code 1

                ret
                
.Test:          ; Buffer overflow check
                cmp rdi, Buffer + BufSize
                jb .SkipFlush

                push rsi                ; Save RSI

                FlushBuf

                pop rsi                 ; Restore RSI
                mov rdi, Buffer         ; Set RDI manully

                jmp .Test

.SkipFlush:     ; Check if format string over
                cmp rsi, r10
                jb .Loop

                pop rbp                 ; Restore RBP

                FlushBuf                ; Final flush

                xor rax, rax            ; Exit code 0

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


Example         db 1000 dup('!'), 0
FormatStr       db "Dec: %b", 10, "Hex: %b", 10, "Oct: %b", 10, "Bin: %b", 10, "Chr: %c", 10, "Str: %s", 10, "Pro: %%", 10
FormatStrLen    equ $ - FormatStr

Buffer          db BufSize + ExtraSize dup(0)   ; Result buffer
RealBufSize     equ $ - Buffer                  ; Result buffer length



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
