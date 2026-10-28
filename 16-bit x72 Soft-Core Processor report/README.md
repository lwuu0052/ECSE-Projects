# 16-bit x72 Soft-Core Processor

A simplified 16-bit processor ("x72") designed in Verilog and implemented on an Intel MAX 10 FPGA (DE10-Lite board, `10M50DAF484C7G`). Completed for unit ECE2072 (Team 77).

**Team:** Wu Li Min, Yeoh Jie Ying

## Overview

The processor uses a shared 16-bit bus that connects every component, which keeps resource usage low. A one-hot tick counter steps each instruction through four states:

| Tick | Action |
|---|---|
| 1 | Load the 9-bit instruction (`DIN`) into the instruction register, sign-extend it to 16 bits, and decode the opcode |
| 2 | Put the source register (Type 1) or the immediate value (Type 2) on the bus and latch it into register A (ALU input) or H (display) |
| 3 | Put the second operand on the bus; the ALU computes and stores the result in register G |
| 4 | Write register G back to the destination register (R0–R7) |

For `movi` and `disp`, ticks 3 and 4 are idle.

### Instruction set

Instruction format: `opcode[8:6] | rx[5:3] | ry[2:0]`

| Opcode | Mnemonic | Type | Operation |
|---|---|---|---|
| `000` | `disp` | — | Show Rx as a signed decimal on the HEX displays |
| `001` | `add` | 1 (reg–reg) | Rx ← Rx + Ry |
| `010` | `addi` | 2 (immediate) | Rx ← Rx + imm |
| `011` | `sub` | 1 | Rx ← Rx − Ry |
| `100` | `mul` | 1 | Rx ← Rx × Ry |
| `101` | `ssi` | 2 | Rx ← Rx shifted by a signed immediate (left if positive, right if negative) |
| `111` | `movi` | 2 | Rx ← imm |

## Components

| Module | Description |
|---|---|
| Sign extender | Extends the 9-bit `DIN` to 16-bit two's complement |
| Tick FSM | One-hot 4-state counter (`0001 → 0010 → 0100 → 1000`) |
| ALU | Multiply, add, subtract, and signed shift selected by a 3-bit `alu_op` |
| Multiplexer | Selects one of 10 sources (DIN, R0–R7, G) onto the bus using a 4-bit select |
| Register | Parameterised width `N` (9-bit IR, 16-bit data registers) with reset and enable |
| BCD / HEX | Converts register values to signed decimal for the 7-segment displays |

The final task adds a program counter, branch logic and an instruction memory (ROM initialised from a `.mif` file), so the processor runs a program automatically.

## Resource usage and timing (Task 1 components)

| Module | Fmax (MHz) | Logic usage |
|---|---|---|
| Sign extender | 1094.09 | 26 LEs |
| Tick FSM counter | 510.46 | 12 LEs |
| ALU | 152.44 | 240 LEs + 2 DSPs |
| Multiplexer | 242.31 | 190 LEs |
| Register | 562.75 | 51 LEs |

The ALU is the critical path because of the multiplier.

## Verification

Self-checking testbenches compare the DUT with a behavioural model in the testbench and print a summary of passes and errors.

- **Components:** all 512 sign-extender inputs, two full FSM cycles, all 16 mux selects, 133 ALU cases (including overflow/underflow and shift edge cases), and 660 register cases
- **Processor (Tasks 2 & 3):** reset; `movi`, `add`, `sub`, `addi`, `mul`, `ssi` and `disp` over all 8 × 8 register pairs across multiple loops; HEX5 tick display; and hand-computed edge cases such as `32767 + 1 → 0x8000`, `−32768 − 1 → 0x7FFF` and `(−256) × (−256) → 0x0000`
- **Total:** 3,396 processor test cases passed, and the design was also verified on the FPGA board

## Files

| Path | Contents |
|---|---|
| `16-bit x72 Soft-Core Processor report.pdf` | Full report with timing screenshots, waveforms and transcripts |
| `Verilog/components.v`, `components_tb.v` | Task 1 components and their testbench |
| `Verilog/proc.v`, `proc_tb.v`, `proc_top_level.v` | Task 2 processor, testbench and board top level |
| `Verilog/proc_extension*.v` | Task 3 extension (`mul`, `ssi`, `disp` with 5-digit signed output) |
| `Verilog/proc_memory*.v`, `ROM.v`, `*.mif` | Processor with program counter and instruction memory |
| `Verilog/BCD*.v` | Binary-to-BCD and 7-segment decoders |
| `Verilog/Project_Group77.qpf` / `.qar` | Quartus project and archive |

## How to run

1. Open `Verilog/Project_Group77.qpf` in Intel Quartus Prime (Lite), or restore `Project_Group77.qar`.
2. Choose the top-level entity for the task you want (for example `proc_top_level`), then compile.
3. Program the DE10-Lite with `output_files/Project_Group77.sof`.
4. To simulate, run the testbenches (such as `proc_tb.v` or `proc_extension_tb.v`) in ModelSim through Quartus NativeLink.
