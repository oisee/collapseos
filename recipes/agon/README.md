# Agon Light 2

The [Agon Light 2][agon] is a modern Z80-compatible single-board computer based
on the eZ80F92 microcontroller running at 18.432MHz. It features:

- eZ80F92 CPU (Z80-compatible with 24-bit extensions)
- 512KB RAM
- VGA output via ESP32-based VDP
- PS/2 keyboard via VDP
- SD card slot
- USB for power and serial

## Z80 Compatibility Mode

The eZ80 can run in two modes:
- **ADL mode**: 24-bit addressing, full 16MB address space
- **Z80 mode**: 16-bit addressing, 64K address space (lower 32K usable)

This recipe targets Z80 compatibility mode, which provides 32K of address space
from 0x0000-0x7FFF for user programs.

## Hardware Architecture

Unlike traditional Z80 systems with external ACIA chips, the Agon uses the
eZ80's internal UART0 (16550-style) which connects to an ESP32 that handles:
- VGA display output
- PS/2 keyboard input
- Sound

Communication between the eZ80 and ESP32 uses a serial protocol. This recipe
provides a basic UART driver (`ez80uart.asm`) for serial I/O.

## Goal

Run the Collapse OS shell via UART0 serial connection.

## Pre-collapse

### Gathering parts

* Agon Light 2 (or compatible: Console8, Agon Origins)
* [zasm][zasm]
* USB cable for power and serial
* Serial terminal software

### Building

    cd recipes/agon
    ../../tools/zasm.sh ../../kernel < glue.asm > collapse.bin

### Loading

The Agon normally boots into MOS/BBC BASIC from flash. To run Collapse OS:

**Option 1: Load via MOS**

If MOS is running, you can load the binary to RAM and execute:

    load collapse.bin
    run &0

**Option 2: Replace MOS (advanced)**

Flash collapse.bin to the eZ80's internal flash. This requires ZDS II
tools and a Zilog Smart Cable. See the [MOS documentation][mos] for
flash programming details.

**Option 3: Serial bootstrap**

The eZ80F92 supports serial bootstrap mode. Hold the BOOT button while
resetting to enter bootstrap mode, then upload via UART.

### Running

Connect to the Agon's serial port at 115200 baud (or the configured rate).
The Collapse OS shell prompt should appear.

## Limitations

- **VDP not supported**: This basic recipe uses raw UART, not the VDP protocol.
  No graphics or PS/2 keyboard support yet.
- **Z80 mode only**: Does not use eZ80's extended 24-bit addressing.
- **No SD card yet**: Would require additional driver work.

## Future work

- Add VDP protocol support for display output and keyboard input
- Add SD card driver using eZ80's SPI interface
- Consider ADL mode for more memory

## Post-collapse

The Agon Light 2 uses modern SMD components and would be difficult to
replicate post-collapse. However, its open-source design and available
schematics make it a good reference platform for understanding eZ80 systems.

[agon]: https://www.olimex.com/Products/Retro-Computers/AgonLight2/open-source-hardware
[zasm]: ../../tools/emul
[mos]: https://github.com/breakintoprogram/agon-mos
