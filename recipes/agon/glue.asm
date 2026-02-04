; Agon Light 2 glue code for Collapse OS
;
; Target: eZ80F92 in Z80 compatibility mode
; Memory: Uses lower 32K (0x0000-0x7FFF) in Z80 mode
; I/O: UART0 for serial communication
;
; This configuration runs Collapse OS in Z80 legacy mode on the Agon.
; UART0 connects to the ESP32/VDP by default. For standalone serial
; operation, you may need to reconfigure or use GPIO serial pins.

; Memory map for Z80 mode on Agon
; 0x0000-0x7FFF: Available to user program (32K)
; We put code at the start, RAM at the end
.equ	RAMSTART	0x4000
.equ	RAMEND		0x7FFF

; eZ80 UART0 base port
.equ	EZ80UART_PORT	0xC0

	jp	init

; Interrupt vector at 0x38 for mode 1
.fill	0x38-$
	jp	ez80uartInt

.inc "err.h"
.inc "core.asm"
.inc "parse.asm"

.equ	EZ80UART_RAMSTART	RAMSTART
.inc "ez80uart.asm"

.equ	STDIO_RAMSTART		EZ80UART_RAMEND
.inc "stdio.asm"

.equ	SHELL_RAMSTART		STDIO_RAMEND
.equ	SHELL_EXTRA_CMD_COUNT	0
.inc "shell.asm"

init:
	di
	; Setup stack at top of RAM
	ld	hl, RAMEND
	ld	sp, hl
	im	1

	call	ez80uartInit
	ld	hl, ez80uartGetC
	ld	de, ez80uartPutC
	call	stdioInit
	call	shellInit
	ei
	jp	shellLoop
