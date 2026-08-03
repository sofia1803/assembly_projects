CC = gcc
AS = nasm
CFLAGS = -m32 -Wall -O2
ASFLAGS = -f elf32

all: histogram

histogram: main.o histogram.o
	$(CC) $(CFLAGS) -o histogram main.o histogram.o

main.o: main.c
	$(CC) $(CFLAGS) -c main.c

histogram.o: histogram.asm
	$(AS) $(ASFLAGS) histogram.asm

clean:
	rm -f *.o histogram

.PHONY: clean