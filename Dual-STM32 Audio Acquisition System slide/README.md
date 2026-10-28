# Dual-STM32 Audio Acquisition System

An audio recording system that uses two STM32L432KC microcontrollers: one samples the audio and the other processes it. A Python command-line tool on the PC receives the samples and saves them as WAV, CSV or PNG files. Completed for unit ECE2071 (Group 8).

**Team:** Hui Man Kitt (Sampling STM), Hans Chung Zheng Sheng (Processing STM), **Wu Li Min (Python CLI)**, Nicholas Wong Zhong Hao (project management), Rohan Kee Zhong Ren (presentation)

## System overview

```
Microphone ──► Sampling STM ──SPI──► Processing STM ──UART 921600 bps──► PC (Python CLI)
               (ADC 44.1 kHz)        ▲ (filtering,                       │
                                     │  trigger logic)                   ▼
                          Ultrasonic sensor                     .wav / .csv / .png
```

### Sampling STM
- TIM1's hardware TRGO output triggers ADC conversions at a fixed **44.1 kHz** with **12-bit** resolution, so no software interrupt is involved and sampling is free of jitter.
- Each 12-bit sample is packed into one 16-bit SPI word and streamed straight to the Processing STM using the Low-Layer (LL) drivers to keep overhead low.

### Processing STM
- Receives samples over SPI with DMA.
- Measures distance with an ultrasonic sensor (timer input capture for the echo, a timer for the trigger) and starts or stops the stream when an object enters the set range.
- Applies a moving-average filter and outlier rejection.
- Sends data to the PC over UART at 921600 bps using DMA.

### Python CLI (my part)
- Reads the incoming UART packets from the serial port in real time (`pyserial`).
- Offers two modes: **manual recording** for a set number of seconds, and **distance trigger** with a user-set threshold in cm.
- Lets the user choose output formats and saves the data as `.csv`, a waveform plot `.png` (`matplotlib`), and `.wav`.
- Compiles and calls a C program (`team_08_CLI.c`) that writes the WAV header and converts the raw binary samples into a WAV file.

## Results
- Audio sampled and transmitted at 44.1 kHz with 12-bit resolution
- Exported to WAV, CSV and PNG on the PC
- Works in both manual and distance-trigger modes
- Moving-average filter and outlier rejection implemented

## Files

| Path | Contents |
|---|---|
| `Dual-STM32 Audio Acquisition System slide.pdf` | Presentation slides with block diagrams and results |
| `code/Sampling_STM/` | STM32CubeIDE project for the sampling board (ADC + TIM1 + SPI) |
| `code/Processing_STM/` | STM32CubeIDE project for the processing board (SPI DMA, ultrasonic, UART) |
| `code/Python_and_C/team_08_CLI.py` | Python command-line interface |
| `code/Python_and_C/team_08_CLI.c` | Binary-to-WAV converter called by the CLI |

## How to run

1. Open `code/Sampling_STM` and `code/Processing_STM` in STM32CubeIDE, then build and flash each one to its own NUCLEO-L432KC board.
2. Wire SPI1 between the two boards and connect the ultrasonic sensor to the Processing STM (pin assignments are in the `.ioc` files).
3. Install the Python dependencies:
   ```bash
   pip install pyserial numpy matplotlib
   ```
4. Set `port_name` in `team_08_CLI.py` to your board's COM port (default `COM11`). Make sure `gcc` is on your PATH, then run:
   ```bash
   python team_08_CLI.py
   ```
