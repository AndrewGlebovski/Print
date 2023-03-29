global _start


section .text


CallWrite       equ 1
CallExit        equ 60

StdOut          equ 1

QWordSize       equ 8

BinBufSize      equ 32
OctBufSize      equ 11
DecBufSize      equ 11
HexBufSize      equ 8

BufSize         equ 512                 ; Buffer flush is not necessary until buffer size reach this limit
ExtraSize       equ 64                  ; Extra space after BufSize to protect data from buffer overflow


_start:         ; Set arguments
                push Example
                push 0x21
                push 2147483647
                push 2147483647
                push 2147483647
                push 2147483647
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
; Destr:        RAX, RCX, RDX, RDI, RSI, R10, R11
;----------------------------------------

Printf:         ; Save RBX, RBP
                push rbx
                push rbp

                mov rbp, rsp            ; RBP always points to current argument

                ; Set arguments from stack
                mov rsi, [rsp+24]
                mov rdi, Buffer

                mov r10, [rsp+32]
                add r10, rsi

                add rbp, 40             ; Skip return address, format string address and size

                ; Test length for 0 first
                jmp .Test

.Loop:          ; Format specifier check
                cmp byte [rsi], '%'
                je .Special

                movsb
                jmp .Test

.Special:       ; Special format case
                inc rsi                 ; Update RSI manually
                xor rax, rax
                mov al, byte [rsi]      ; Get specifier

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

                shl rax, 3
                jmp JumpTable[rax]

.b:             ; Binary print
                mov rax, [rbp]
                mov r11, BinBufSize
                mov cl, 1
                call Converter

                add rdi, BinBufSize     ; Update RDI manually

                jmp .NextArg

.c:             ; Character print
                mov rax, rsi            ; Save RSI

                mov rsi, rbp
                movsb

                mov rsi, rax            ; Restore RSI

                jmp .NextArg

.d:             ; Decimal print
                mov rax, [rbp]
                call PrtDec

                add rdi, DecBufSize     ; Update RSI (and RDI) manually

                jmp .NextArg

.o:             ; Octal print
                mov rax, [rbp]
                mov r11, OctBufSize
                mov cl, 3
                call Converter

                add rdi, OctBufSize     ; Update RSI (and RDI) manually

                jmp .NextArg

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
                pop rsi                 ; Restore RSI

                jmp .NextArg

.x:             ; Hexadecimal print
                mov rax, [rbp]
                mov r11, HexBufSize
                mov cl, 4
                call Converter

                add rdi, HexBufSize     ; Update RDI manually

                jmp .NextArg

.error:         ; Unknown format (Restore RBP and return immediately)
                pop rbp                 ; Restore RBP
                pop rbx                 ; Restore RBX

                mov rax, 1              ; Exit code 1

                ret

.NextArg:       ; To next argument in stack
                add rbp, QWordSize

.Test:          ; Buffer overflow check
                cmp rdi, Buffer + BufSize
                jb .SkipFlush

                push rsi                ; Save RSI

                FlushBuf

                pop rsi                 ; Restore RSI
                mov rdi, Buffer         ; Set RDI manully

.SkipFlush:     ; Check if format string over
                cmp rsi, r10
                jb .Loop

                pop rbp                 ; Restore RBP
                pop rbx                 ; Restore RBX

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


;----------------------------------------
; Converts int32 to bin, oct, hex format
;----------------------------------------
; Enter:        RAX = integer, RDI = buffer address, R11 = buffer size, CL = bit shift
; Exit:         None
; Destr:        RAX, RBX, R11, RDX
;----------------------------------------

Converter:      ; Set bit mask
                mov rdx, 1
                shl rdx, cl
                sub rdx, 1

                dec r11                 ; RDI + R11 points to last symbol in buffer

.Loop:          mov rbx, rax
                and rbx, rdx

                mov bl, HexTrans[rbx]
                mov [rdi, r11], bl

                dec r11
                shr rax, cl
                jne .Loop

                jmp .Test

                ; Set forward zeros
.Next           mov byte [rdi, r11], '0'
                dec r11

.Test           cmp r11, -1
                jne .Next

                ret

;----------------------------------------


;----------------------------------------
; Converts int32 to decimal format and writes result to buffer
;----------------------------------------
; Enter:        RAX = integer, RDI = buffer address
; Exit:         None
; Destr:        RAX, RBX, RCX, RDX, R11
;----------------------------------------

PrtDec:         ; Set high order bits of RAX to low order bits of RDX and set loop length
                xor rdx, rdx

                mov rcx, DecBufSize - 1
                mov rbx, 10

                xor r11, r11

                cmp eax, 0
                jge .Loop

                ; Take number module
                mov r11, 1 << 32        
                sub r11, rax
                mov rax, r11

                mov r11, 1              ; Remember number sign in R11

                ; Set digits
.Loop:          div ebx
                add dl, '0'

                mov [rdi, rcx], dl

                xor rdx, rdx
                dec rcx

                cmp eax, 0
                jne .Loop

                ; Check if number was negative
                cmp r11, 0
                je .Test

                ; Set sign
                mov byte [rdi, rcx], '-'
                dec rcx

                jmp .Test

                ; Set forward zeros
.Next           mov byte [rdi, rcx], 0
                dec rcx

.Test           cmp rcx, -1
                jne .Next

                ret

;----------------------------------------


section .data


Example         db "Hello, World!", 0
FormatStr       db "Dec: %d", 10, "Hex: %x", 10, "Oct: %o", 10, "Bin: %b", 10, "Chr: %c", 10, "Str: %s", 10, "Pro: %%", 10
FormatStrLen    equ $ - FormatStr

Buffer          db BufSize + ExtraSize dup(0)   ; Printf buffer
RealBufSize     equ $ - Buffer                  ; Real buffer length = BufSize + ExtraSize


section .rodata


align 8
JumpTable:                                      ; Printf jump table
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

HexTrans        db "0123456789ABCDEF"           ; Array for numbers convertions
