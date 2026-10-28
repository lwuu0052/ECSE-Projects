# One-Port SAW Resonator: Fabrication and Temperature Characterisation

We fabricated one-port surface acoustic wave (SAW) resonators on 128° YX-cut lithium niobate (LiNbO₃) and aluminium nitride (AlN), then measured how their resonant frequency changes with temperature to evaluate them as passive temperature sensors.

**Team:** Wu Li Min, Liew Wei Shen, Gary Tan Jia Hoong, Tang Wei Zhi
**Supervisor:** Dr. Howgen Pratama Kesuma

## Method

**Fabrication**
- Cleaned the substrates and deposited about 200 nm of aluminium by thermal evaporation
- Patterned the interdigital transducer (IDT) and reflector gratings with contact photolithography (S1805 resist, 365 nm UV) and wet etching
- Design wavelength λ = 30 µm (15 µm pitch, 7.5 µm finger width), giving an expected resonance of about 130 MHz

**Characterisation**
- FESEM (Hitachi SU8010) to inspect the electrodes
- AFM (Bruker MultiMode 8) to measure step height and roughness
- Filmetrics F20 reflectometer to measure film thickness

**Test setup**
- Each die was mounted on a PCB with an SMA connector and protected by a 3D-printed cover
- A custom thermal chamber used two 12 V heaters driven by a BTS7960, a DHT22 sensor, and a XIAO ESP32-C3 running temperature control and a cooling fan. Safety cut-offs disabled the heaters at 55 °C or on a sensor fault
- A NanoVNA-H4 measured S₁₁ from 127 to 133 MHz
- A Python logger waited for each temperature to stabilise, turned off the heaters, took five sweeps, logged the results to CSV, and showed a live dashboard on `localhost:8000`. A cleaning script then removed outlier sweeps

## Results

| Metric | Value |
|---|---|
| Resonant frequency (LiNbO₃) | **129.6 MHz** (within 0.3 % of the design value) |
| Effective SAW velocity | ~3888 m/s |
| Temperature sensitivity | **−6.2 ± 1.0 kHz/°C** over 29.2–40.6 °C (R² = 0.86) |
| TCF | **−48 ± 7 ppm/°C** |
| Chamber heating response (2 °C steps) | 196–407 s |
| Chamber cooling (39.8 → 30.0 °C) | ~770 s |

- The measured TCF has the expected negative sign but is smaller in magnitude than the literature value (about −75 ppm/°C). This is most likely because the die, insulated by its cover, lagged behind the chamber air temperature that the sensor measured.
- The AlN device showed no measurable resonance, probably because of weaker electromechanical coupling, electrode mass loading and fabrication losses.

**Future work:** place a thermistor on the die, improve the chamber insulation to reach 55 °C, use wire bonding, and add an impedance-matching network.

## Files

| Path | Contents |
|---|---|
| `Project Report.pdf` | Full report in IEEE Sensors Journal format |
