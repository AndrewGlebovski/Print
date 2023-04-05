all: printf


# Трансляция ассемблера
printf: printf.s
	nasm -f elf64 -l $@.lst $@.s
	ld -s -o $@.exe $@.o /lib/x86_64-linux-gnu/libc.so -dynamic-linker /lib64/ld-linux-x86-64.so.2
