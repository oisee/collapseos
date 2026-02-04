; ez80uart
;
; UART driver for eZ80F92 internal UART0 (16550-style).
; Used on Agon Light 2 and similar eZ80-based systems.
;
; In Z80 compatibility mode, this provides serial I/O through UART0.
; On Agon, UART0 normally connects to the ESP32/VDP, but can also be
; used for direct serial communication.

; *** DEFINES ***
; EZ80UART_PORT: Base I/O port for UART0 (typically 0xC0)
; EZ80UART_RAMSTART: Address for variables

; *** CONSTS ***
; UART0 register offsets from base
.equ	EZ80UART_RBR	0	; Receive Buffer (read)
.equ	EZ80UART_THR	0	; Transmit Holding (write)
.equ	EZ80UART_IER	1	; Interrupt Enable
.equ	EZ80UART_IIR	2	; Interrupt ID (read)
.equ	EZ80UART_FCR	2	; FIFO Control (write)
.equ	EZ80UART_LCR	3	; Line Control
.equ	EZ80UART_LSR	5	; Line Status

; Line Status Register bits
.equ	EZ80UART_LSR_DR		0x01	; Data Ready
.equ	EZ80UART_LSR_THRE	0x20	; TX Holding Register Empty

; Buffer size
.equ	EZ80UART_BUFSIZE	0x20

; *** VARIABLES ***
.equ	EZ80UART_BUF		EZ80UART_RAMSTART
.equ	EZ80UART_BUFRDIDX	EZ80UART_BUF+EZ80UART_BUFSIZE
.equ	EZ80UART_BUFWRIDX	EZ80UART_BUFRDIDX+1
.equ	EZ80UART_RAMEND		EZ80UART_BUFWRIDX+1

ez80uartInit:
	; Initialize buffer indices
	xor	a
	ld	(EZ80UART_BUFRDIDX), a
	ld	(EZ80UART_BUFWRIDX), a

	; Enable FIFO, clear buffers
	ld	a, 0x07		; Enable FIFO, clear RX/TX FIFOs
	ld	c, EZ80UART_PORT+EZ80UART_FCR
	out	(c), a

	; 8N1 format (8 data bits, no parity, 1 stop bit)
	ld	a, 0x03
	ld	c, EZ80UART_PORT+EZ80UART_LCR
	out	(c), a

	; Enable receive interrupt
	ld	a, 0x01
	ld	c, EZ80UART_PORT+EZ80UART_IER
	out	(c), a
	ret

; Increment circular buffer index in A
ez80uartIncIndex:
	inc	a
	cp	EZ80UART_BUFSIZE
	ret	nz
	xor	a
	ret

; Interrupt handler - read char into buffer
ez80uartInt:
	push	af
	push	hl

	; Check if data ready
	ld	c, EZ80UART_PORT+EZ80UART_LSR
	in	a, (c)
	bit	0, a		; Data Ready?
	jr	z, .end

	; Check buffer space
	ld	a, (EZ80UART_BUFRDIDX)
	call	ez80uartIncIndex
	ld	l, a
	ld	a, (EZ80UART_BUFWRIDX)
	cp	l
	jr	z, .end		; Buffer full

	push	de		; --> lvl 1
	ld	de, EZ80UART_BUF
	call	addDE
	call	ez80uartIncIndex
	ld	(EZ80UART_BUFWRIDX), a

	; Read the character
	ld	c, EZ80UART_PORT+EZ80UART_RBR
	in	a, (c)
	ld	(de), a
	pop	de		; <-- lvl 1

.end:
	pop	hl
	pop	af
	ei
	reti

; Get character from buffer (blockdev API)
; Returns char in A, Z set if success
ez80uartGetC:
	push	de

	ld	a, (EZ80UART_BUFWRIDX)
	ld	e, a
	ld	a, (EZ80UART_BUFRDIDX)
	cp	e
	jr	z, .nothingToRead

	ld	de, EZ80UART_BUF
	call	addDE
	call	ez80uartIncIndex
	ld	(EZ80UART_BUFRDIDX), a

	ld	a, (de)
	cp	a		; Set Z
	jr	.end

.nothingToRead:
	call	unsetZ
.end:
	pop	de
	ret

; Put character in A to UART (blockdev API)
ez80uartPutC:
	push	af
	push	bc
.wait:
	ld	c, EZ80UART_PORT+EZ80UART_LSR
	in	a, (c)
	bit	5, a		; TX Holding Register Empty?
	jr	z, .wait
	pop	bc
	pop	af
	ld	c, EZ80UART_PORT+EZ80UART_THR
	out	(c), a
	ret
