ARTIFACT=boot

.PHONY: all clean test

all: ${ARTIFACT}.img

${ARTIFACT}.img: ${ARTIFACT}.com
	cp $< $@
	truncate --size=4M $@

${ARTIFACT}.vmdk: ${ARTIFACT}.img
	qemu-img convert -f raw -O vmdk $< $@

main.s: main.c
	$(CC) -std=gnu11 -O0 -nostdlib -march=i386 -m16 -ffreestanding -ffunction-sections -o $@ -S $<

halt.o: halt.s
	$(AS) --32 -o $@ $<

main.o: main.s
	$(AS) --32 -o $@ $<

startup.o: startup.s
	$(AS) --32 -o $@ $<

bootcode.o: startup.o main.o halt.o
	$(LD) -T bootcode.ld -r -o $@ $^

jump.o: jump.s
	$(AS) --32 -o $@ $<

${ARTIFACT}.o: bootcode.o jump.o
	$(LD) -T mbr.ld -o $@ $^

${ARTIFACT}.com: ${ARTIFACT}.o
	objcopy $< $@ -O binary

test: ${ARTIFACT}.img
	qemu-system-i386 -nodefaults -nodefconfig -no-user-config -m 1M -device VGA -drive file=$<,format=raw -d guest_errors	

clean:
	rm -f ${ARTIFACT}.img ${ARTIFACT}.vmdk ${ARTIFACT}.com main.s *.o
