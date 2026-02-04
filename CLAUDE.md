# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Collapse OS is a Z80 kernel and collection of programs designed to bootstrap post-collapse technology. It runs on minimal/improvised hardware and is entirely self-contained—the assembler (zasm) is written in Z80 assembly itself.

**Design priorities:** Simplicity > Compactness > Efficiency (except in critical loops)

## Build Commands

```bash
# Initialize submodules (required first time)
git submodule init && git submodule update

# Build emulator tools (shell, zasm, runbin)
make -C tools/emul

# Run all tests
make -C tools/tests run

# Run a single unit test
cd tools/tests/unit && ./runtests.sh test_core.asm

# Assemble a kernel
./tools/zasm.sh kernel apps < glue.asm > kernel.bin

# Update bootstrap binaries after modifying zasm
make -C tools/emul updatebootstrap

# Clean build artifacts
make -C tools/emul clean
```

## Architecture

### Directory Structure
- `kernel/` - Modular kernel components (acia, blockdev, fs, shell, stdio, sdc, ez80uart, etc.)
- `apps/` - Userspace applications (zasm assembler, ed editor, lib utilities)
- `recipes/` - Platform-specific builds (rc2014, sms, agon)
- `tools/emul/` - Z80 emulators: shell (interactive), zasm (assembler), runbin (test executor)
- `tools/tests/` - Unit tests and zasm tests

### Glue Code Pattern
Users create custom kernels by writing `glue.asm` files that combine kernel modules. Each module declares RAM usage via `<PARTNAME>_RAMSTART`/`<PARTNAME>_RAMEND` constants for chaining:

```asm
MOD1_RAMSTART .equ RAMSTART
#include "mod1.asm"
MOD2_RAMSTART .equ MOD1_RAMEND
#include "mod2.asm"
```

### Userspace Convention
- Apps are called with HL pointing to null-terminated argument string
- Return via standard return; A register = exit code (0 = success)

### Self-Hosted Toolchain
`zasm` (the assembler) is written in Z80 assembly and runs via emulation. `tools/zasm.sh` wraps it, packing includes into CFS format before assembly.

## Code Conventions

### Stack Management
Document non-routine push/pop pairs with level markers:
```asm
push    af  ; --> lvl 1
inc     a
push    af  ; --> lvl 2
inc     a
pop     af  ; <-- lvl 2
pop     af  ; <-- lvl 1
```

### Module Defines
Each kernel module has a "DEFINES" section listing required constants. Ensure these are defined before including the file.

## Testing

Tests are Z80 assembly files executed via `runbin`. Exit code comes from the A register (0 = pass).

- Unit tests: `tools/tests/unit/*.asm` - test core utilities
- Zasm tests: `tools/tests/zasm/*.asm` - test assembler output against `.expected` files
