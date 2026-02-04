ZASM = ../../tools/zasm.sh
KERNEL = ../../kernel

.PHONY: all
all: collapse.bin

collapse.bin: glue.asm $(KERNEL)/ez80uart.asm
	$(ZASM) $(KERNEL) < glue.asm > $@

.PHONY: clean
clean:
	rm -f collapse.bin
