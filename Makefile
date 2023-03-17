all: printf


# Трансляция ассемблера
printf: printf.s
	nasm -f elf64 -l $@.lst $@.s
	ld -s -o $@.exe $@.o
