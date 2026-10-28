# CDMA Signal Spreading and Recovery with Walsh–Hadamard Codes

A MATLAB simulation of a two-user Code Division Multiple Access (CDMA) system that uses 8-chip Walsh–Hadamard (WH) spreading codes and BPSK modulation. It studies how noise, unequal power and timing errors affect data recovery. Completed for unit ECE3141 (Information and Networks).

**Team:** Wu Li Min, Lee Guo-Yi

## What the simulation covers

1. **Spreading and despreading:** Each user's bits are BPSK-mapped and multiplied by that user's 8-chip WH code. The receiver correlates the combined signal with each code to recover each user's bits.
2. **Orthogonality:** Confirms W1·W2 = 0 and W1·W1 = W2·W2 = 8, so each correlator rejects the other user completely.
3. **AWGN:** Plots BER against Eb/N0 using 500 Monte Carlo trials and compares it with the theoretical BPSK curve. Despreading gives about 9 dB of processing gain (10·log₁₀ 8).
4. **Imperfect power control:** With user gains of 0.5 and 2.0, the near–far problem appears, and the weaker user's BER is about 500 times higher at Eb/N0 = 4 dB.
5. **Imperfect synchronisation:** Upsampling is used to model integer and fractional chip offsets. Cross-correlation leakage stays near zero for offsets under 0.5 chip and rises to about 0.13 beyond that.

## Key findings

- Under ideal conditions, both users' data are recovered with no errors.
- Spreading suppresses AWGN effectively, and the simulated BER follows the theoretical BPSK curve.
- The system is sensitive to unequal received power and to timing errors larger than half a chip, which is why real CDMA systems need power control and tight synchronisation.

## Files

| Path | Contents |
|---|---|
| `CDMA_Code.m` | MATLAB simulation script |
| `CDMA_Report.pdf` | Report in IEEE format |

## How to run

1. Open `CDMA_Code.m` in MATLAB and run it.
2. When prompted, enter a binary string for each user, for example `101` for User 1 and `010` for User 2.
3. The script prints the decoded bits and plots the chip waveforms, the noisy channel, BER vs SNR, BER under imperfect power control, and leakage vs timing offset.
