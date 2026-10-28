# ECSE Projects

A collection of my Electrical & Computer Systems Engineering projects from Monash University Malaysia, covering FPGA/Verilog digital design, STM32 embedded systems, analogue circuit design, PCB design, communication systems, MEMS device fabrication, and undergraduate research in visible light communication.

**Author:** Wu Li Min

## Projects

| Project | Area | Tools / Hardware | Highlights |
|---|---|---|---|
| [16-bit x72 Soft-Core Processor](16-bit%20x72%20Soft-Core%20Processor%20report/) | Digital design | Verilog, Quartus Prime, ModelSim, Intel MAX 10 (DE10-Lite) | Bus-based 16-bit processor with 7 instructions, a 4-tick FSM control unit and BCD display; 3,396 self-checking testbench cases |
| [Dual-STM32 Audio Acquisition System](Dual-STM32%20Audio%20Acquisition%20System%20slide/) | Embedded systems | STM32L432KC, STM32CubeIDE, C, Python | 44.1 kHz / 12-bit audio sampling over SPI, ultrasonic trigger, UART at 921600 bps, Python CLI exporting WAV/CSV/PNG |
| [True-RMS-to-DC Converter](TRUE-RMS-TO-DC%20CONVERTER/) | Analogue design | LTspice, TL084/TL974, 2N3904, Analog Discovery 3 | Discrete log–antilog converter; all 13 test cases within ±1 % (mean error 0.46 %), DC to 20 kHz |
| [PIR Motion-Activated LED Fader PCB](PCB_Project/) | PCB design | KiCad 10 | Two-layer board with PIR interface, adjustable RC fade-in/fade-out timing and MOSFET LED driver |
| [CDMA with Walsh–Hadamard Codes](CDMA_project/) | Communications | MATLAB | Two-user BPSK CDMA simulation: BER vs Eb/N0, near–far problem, timing-offset leakage |
| [One-Port SAW Resonator](One-Port%20SAW%20Resonator/) | MEMS / sensors | Photolithography, FESEM, AFM, NanoVNA, ESP32-C3, Python | Fabricated 129.6 MHz LiNbO₃ resonator; TCF of −48 ± 7 ppm/°C measured in a PI-controlled thermal chamber |
| [UROP – Visible Light Communication (SPI link)](UROP%20Project%20-%20Visible%20Light%20Communication%20Systems%20with%20Microcontrollers%20or%20FPGAs/) | Research | Verilog, Quartus, Teensy 4.1, PlatformIO (C++), DE2-115 | Replaced the UART PC–FPGA link with SPI; up to ~4.57 Mbps within a packet |

## Repository layout

```
.
├── 16-bit x72 Soft-Core Processor report/   Verilog sources, Quartus project, report (PDF)
├── CDMA_project/                            MATLAB simulation script, report (PDF)
├── Dual-STM32 Audio Acquisition System slide/
│   └── code/                                Sampling STM, Processing STM, Python + C CLI
├── One-Port SAW Resonator/                  Project report (PDF)
├── PCB_Project/PIR_Sensor/                  KiCad project, schematic (PDF), layout render
├── TRUE-RMS-TO-DC CONVERTER/                Project report (PDF)
└── UROP Project - Visible Light .../        FPGA + Teensy SPI code for both master/slave setups
```

Each project folder has its own README with an overview, implementation details, results and instructions for opening or running the work.

## Skills demonstrated

- **Digital design:** RTL design in Verilog, FSMs, datapath/control-unit design, self-checking testbenches, timing and resource analysis in Quartus
- **Embedded systems:** STM32 HAL/LL drivers, ADC, timers, DMA, SPI, UART, Teensy/Arduino, PlatformIO
- **Analogue electronics:** op-amp circuits, translinear log–antilog computation, precision rectifiers, calibration, LTspice simulation
- **PCB design:** schematic capture and two-layer layout in KiCad
- **Signal processing & communications:** CDMA, BPSK, BER analysis, Monte Carlo simulation in MATLAB
- **Microfabrication & characterisation:** thermal evaporation, photolithography, FESEM/AFM, VNA measurements
- **Software:** C, C++, Python (serial acquisition, data logging, automation), MATLAB
- **Teamwork:** most projects were completed in teams; collaborators are credited in each project's README
