# UROP: Visible Light Communication Systems with Microcontrollers or FPGAs

An Undergraduate Research Opportunities Program (UROP) project at Monash University Malaysia. The goal was to speed up the PC–FPGA link in a visible light communication (VLC) system by replacing UART with SPI, using a Teensy 4.1 between the PC and the FPGA.

**Researchers:** Wu Li Min, Khong Yin Jou

## Motivation

The optical channel in the existing VLC setup reaches about **50 kB/s**, but the UART link between the PC and the FPGA is limited to about **14.4 kB/s**. That bottleneck means the optical channel's capacity is never fully used. SPI is synchronous and full-duplex, and it does not depend on accurate baud timing.

## Implementation

All links use SPI Mode 0 (CPOL = 0, CPHA = 0) between a Teensy 4.1 (C++, PlatformIO) and a DE2-115 board (Cyclone IV E `EP4CE115F29C7`, Verilog, Quartus).

### A. Teensy master → FPGA slave (`Teensy_Master_FPGA_Slave/`)
- The Teensy sends up to 8 ASCII characters, one byte per chip-select pulse.
- The FPGA synchronises the SPI signals and shifts in each byte using a 3-state FSM (IDLE → RECEIVE → TIMEOUT). It latches complete bytes into eight registers and clears incomplete ones on timeout.
- A BCD decoder shows each byte on the 7-segment displays.

### B. FPGA master → Teensy slave (`FPGA_Master_Teensy_Slave/`)
- When a button is pressed, the FPGA reads its 16 switches as 2 bytes and sends a 14-byte packet while chip select is held low:

  | Word | Content |
  |---|---|
  | 0 | Header (fixed value) |
  | 1 | Slave ID (must match the Teensy) |
  | 2 | Length |
  | 3 | Command code |
  | 4 | Packet ID (increments on each send) |
  | 5 | Switch data (payload) |
  | 6 | Checksum (packet ID XOR switch data) |

- The Teensy receives the packet in a callback using the `SPI_MSTransfer_T4` library, then prints the decoded characters and binary values to the serial monitor.

## Results

| Configuration | Measurement | Throughput |
|---|---|---|
| Teensy master, FPGA slave | 8-byte packet in ~14 µs (~5 MHz SCK) | **~571 kB/s (4.57 Mbps)** within the packet |
| FPGA master, Teensy slave | 14-byte packet in 1.128 ms | **~12.42 kB/s (99.3 kbps)** |

- The string `77852143` was received and displayed correctly with no data loss.
- The switch payload was decoded correctly on the Teensy (for example `B.` = `01000010 00000000`).
- In the Teensy-master setup, SPI is much faster than the previous UART link. The FPGA-master setup is slower because the FPGA used a lower SPI clock.

**Future work:** reduce the chip-select overhead between bytes and raise the FPGA-side SPI clock.

## Files

| Path | Contents |
|---|---|
| `Teensy_Master_FPGA_Slave/Teensy_Master/` | PlatformIO project for the Teensy SPI master |
| `Teensy_Master_FPGA_Slave/FPGA_Slave/` | Quartus project: `FPGA_slave.v`, top level and BCD decoder |
| `Teensy_Master_FPGA_Slave/*.png` | 7-segment display results for the test strings |
| `FPGA_Master_Teensy_Slave/FPGA_Master/` | Quartus project: `FPGA_Master.v` (parameterised SPI master), top level and BCD |
| `FPGA_Master_Teensy_Slave/Teensy_Slave/` | PlatformIO project for the Teensy SPI slave using `SPI_MSTransfer_T4` |
| `Visible Light Communication Systems ... .pdf` | Research report |
| `UROP_certification.pdf` | UROP completion certificate |

The `cycloneRTSigGenBits` files inside `FPGA_Slave/` come from a third-party open-source project and keep their own `LICENSE`.

## How to run

**FPGA:** open the `.qpf` in Quartus Prime, compile, and program the DE2-115.

**Teensy:** open the project folder in VS Code with PlatformIO, then build and upload:
```bash
pio run -t upload
```
Open the serial monitor at 115200 baud:
```bash
pio device monitor -b 115200
```
Connect SCK, MOSI, MISO, CS and GND between the two boards. The pin assignments are in the `.qsf` files and in `src/main.cpp`.
