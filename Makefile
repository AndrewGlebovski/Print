all: printf_asm.exe


printf_asm.exe: printf.o main.o
	g++ -no-pie printf.o main.o -o $@


main.o: main.cpp
	g++ -c main.cpp -o $@


printf.o: printf.s
	nasm -f elf64 printf.s
