
ifeq ($(CROSS_COMPILE),)
CROSS_COMPILE=arm-none-linux-gnueabi-
endif

# Base address to load the program
RAM_BASE=0x00100000

AS = $(CROSS_COMPILE)as
CC = $(CROSS_COMPILE)gcc
LD = $(CROSS_COMPILE)ld
AR = $(CROSS_COMPILE)ar
GDB = $(CROSS_COMPILE)gdb
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump 

.PHONY: clean all dump

# -O0          : Disable optimizations
# -g           : Generate debug info
# -ffixed-r8   : Don't touch register r8
CFLAGS = -nostdinc \
		-fno-common \
		-fno-builtin \
		-ffixed-r8 \
		-msoft-float \
		-ffreestanding \
		-I./ \
		-DTEXT_BASE=$(RAM_BASE) \
		-O0 \
		-g -Wall \
		-marm -mcpu=arm1176jzf-s

# Name of target program
PROG=hello-arm

# List of all *c sources
CSRC=main.c

#List of all *S (asm) sources
ASRC=start.S

COBJ = $(subst .c,.o,$(CSRC))
AOBJ = $(subst .S,.o,$(ASRC))

all: $(PROG).bin
	
$(AOBJ): %.o : %.S
	$(CC) $(CFLAGS) -c -o $@ $<
	
$(COBJ): %.o : %.c
	$(CC) $(CFLAGS) -c -o $@ $<
	
$(PROG).elf: $(COBJ) $(AOBJ)
	$(LD) -T boot.lds -Ttext=$(RAM_BASE) $^ -o $@

$(PROG).bin: $(PROG).elf
	$(OBJCOPY) -v -O binary $^ $@

clean:
	rm -f *.a
	rm -f *.o 
	rm -f *.elf
	rm -f *.v
	rm -f *.bin
	rm -f *.md5
	rm -f *.hex
	rm -f *.dmp

# Show the disassembly
disassemble: $(PROG).elf
	$(OBJDUMP) -d $(PROG).elf

# Connect to the remote gdb and start debugging
debug: $(PROG).bin
	rm .gdbscript ; \
	echo 'target remote 10.7.9.42:4000' >> .gdbscript ; \
	echo 'restore $(PROG).bin binary $(RAM_BASE)' >> .gdbscript ; \
	echo 'jump *$(RAM_BASE)' >> .gdbscript ; \
	$(GDB) -x .gdbscript $(PROG).elf ;



