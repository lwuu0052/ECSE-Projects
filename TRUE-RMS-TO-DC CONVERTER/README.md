# True-RMS-to-DC Converter

A fully analogue true-RMS-to-DC converter designed, simulated in LTspice, and built from discrete op-amps and BJTs. It runs from the ±5 V rails of an Analog Discovery 3. Completed for the ECE3161 mini-project (Group A2).

**Team:** Wu Li Min, Nicholas Wong Zhong Hao, Yeoh Jie Ying, Joyce Ngaa Chee Siew, Hui Man Kitt

## Specification

| Parameter | Requirement |
|---|---|
| Input | 100–200 mVpp with DC offset from −3 V to +3 V |
| Frequency | DC to 20 kHz |
| Crest factor | 1 to 3 |
| Input impedance | ≥ 1 MΩ, ≤ 50 pF |
| Accuracy | Error < 10 % (design goal: < 1 %) |
| Settling time | < 10 s (design goal: < 3 s) |
| Constraints | Analogue only, kit components only, ±5 V supply |

## Design

After comparing average-responding, thermal, explicit, implicit and digital methods, we chose **implicit log–antilog computation**. The input spans about 100:1, so an explicit squarer would need a 10,000:1 internal range. The implicit method computes V<sub>in</sub>²/V<sub>out</sub> instead, so its internal signals keep the same range as the input. The design combines an AD536A-style translinear squarer/divider with AD637-style op-amp averaging.

| Block | Function |
|---|---|
| 0 – Input buffer | Inverting TL084 with a 1 MΩ input resistor to meet the input-impedance spec |
| 1 – Precision full-wave rectifier | Op-amp rectifier with transistor diodes, accurate for signals below a junction drop |
| 2 – Log squarer | Two diode-connected 2N3904s give 2·ln(V<sub>r</sub>), i.e. ln(V<sub>r</sub>²) |
| 3 – Feedback log | Log of the output voltage, fed back to perform the division |
| 4 – Averaging & square root | Q4 with a 10 kΩ / 10 µF network (τ = 0.1 s) performs the implicit square root |
| 5 – Output filter & buffer | 1.59 Hz RC low-pass filter and unity-gain buffer |

Four multi-turn trimmers (offset, negative-input gain, overall gain, output offset) were set once and kept fixed for every test.

## Results

- All **13 test cases within ±1 %** of the expected value (**mean absolute error 0.46 %**, worst case −0.89 %)
- Includes the smallest input (28.9 mV<sub>rms</sub> triangle), crest factor 3, DC offsets of ±3 V, and frequencies up to 20 kHz
- Settles to within ±1 % in about **0.7 s**
- Hardware matches the LTspice simulation within **0.92 %** (mean difference 0.33 %)

**Limitations and future work:** the translinear transistors were unmatched and not thermally bonded, residual op-amp offset dominates at the smallest inputs, and accuracy drops slightly at higher frequencies because of rectifier slewing. A matched transistor array, lower-offset op-amps and a faster rectifier op-amp would help.

## Files

| Path | Contents |
|---|---|
| `Project Report.pdf` | Full report: literature survey, design equations, LTspice results, measurements, calibration record and bill of materials |
