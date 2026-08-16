import serial
import subprocess
import matplotlib.pyplot as plt
import numpy as np
import csv
import time
# ======================================================
# Set up
# ======================================================
port_name = "COM11"
baud_rate = 921600
team_id = "08"
Receiving_rate = 44100
# ======================================================
# manual_recording
# ======================================================
def manual_recording(ser, sec, formats):
    total = int(Receiving_rate * 2 * sec) # Calculate total bytes to receive (2 bytes per sample)
    chunk = 500 # Read data in chunks of 500 bytes  
    byte_received = 0 # Counter for received bytes
    all_samples = [] # List to store audio samples
    txt_filename = f"recorded_audio_{team_id}_{Receiving_rate}.txt"
    raw_data_file = open(txt_filename, "wb")
    print(f"\n{'='*50}")
    print(f"  Manual Recording Mode")
    print(f"{'='*50}")
    print(f"  Target : {total:,} bytes")
    print(f"  Duration: {sec}s")
    print(f"{'─'*50}")
    start_time = time.time()
    while byte_received < total: # Keep reading until we get all expected bytes
        x = ser.read(chunk) # Read a chunk of data from serial
        if len(x) > 0: # If received some data
            raw_data_file.write(x) # Save raw bytes to file
            byte_received += len(x) # Update counter
            # Show progress
            percent = (byte_received / total) * 100
            elapsed = time.time() - start_time
            print(f"\rProgress: {percent:.1f}% ({byte_received}/{total} bytes) {elapsed:.1f}s", end="")
            # Convert bytes to samples
            if len(x) % 2 == 0:
                samples = np.frombuffer(x, dtype=np.uint8)
                all_samples.extend(samples)
    raw_data_file.close() # Close the raw data file
    data_generator(all_samples, formats) # Process and generate output files
# ======================================================
# distance trigger mode
# ======================================================
def distance_trigger_mode(ser, cm, formats):
    print(f"\n{'='*50}")
    print(f"  Distance Trigger Mode")
    print(f"{'='*50}")
    print(f"  Threshold: {cm} cm")
    print(f"  Press Ctrl+C to return to menu")
    print(f"{'─'*50}")
    ser.write(str(cm).encode('utf-8')) # # Send distance threshold to STM32
    time.sleep(0.1)
    ser.reset_input_buffer() # Clear all data
    SILENCE_TIMEOUT = 0.5  # seconds of no data = recording done
    chunk = 50  # Matched from manual_recording
    while True: # Keep waiting for new triggers
        all_samples = []
        txt_filename = f"recorded_audio_{team_id}_{Receiving_rate}.txt"
        raw_data_file = None
        try:
            # Wait for first byte (someone entered range)
            print("\nWaiting for trigger...")
            while ser.in_waiting == 0:
                time.sleep(0.01)   
            # First byte arrived = recording starts
            print(" detected!  Recording...")
            raw_data_file = open(txt_filename, "wb")
            last_received = time.time()
            byte_received = 0
            while True: # Record while person is near
                # Read using fixed chunk size just like manual mode
                x = ser.read(chunk)
                if len(x) > 0:
                    raw_data_file.write(x)
                    byte_received += len(x)
                    print(f"\rRecording... {byte_received} bytes received", end="")
                    if len(x) % 2 == 0:
                        samples = np.frombuffer(x, dtype=np.uint8)
                        all_samples.extend(samples)
                    last_received = time.time()  # Reset silence timer
                else:
                    current = time.time()
                    # Check if silence is long enough to stop recording
                    if current - last_received > SILENCE_TIMEOUT:
                        break  # silence = out of range = stop
            raw_data_file.close()
            print(f"\n  Out of range — {byte_received:,} bytes recorded.")
            print(f"{'─'*50}")
            data_generator(all_samples, formats) # Generate output files
            print(f"{'─'*50}")
        except KeyboardInterrupt:
            print("\nExit.")
            if raw_data_file and not raw_data_file.closed:
                raw_data_file.close()
            return
# ======================================================
# Data generator
# ======================================================
def data_generator(all_samples, formats):
    raw = np.array(all_samples, dtype=np.uint8)
    samples = raw.view(np.uint16)

    if 'csv' in formats:
        csv_filename = f"recorded_audio_{team_id}_{Receiving_rate}.csv"
        csv_file = open(csv_filename, "w", newline='')
        writer = csv.writer(csv_file)
        writer.writerow(["Sample Rate", Receiving_rate])
        for i in samples:
            writer.writerow([i])
        csv_file.close()
        print(f"\n  [saved] {csv_filename}")

    if 'png' in formats:
        png_filename = f"recorded_audio_{team_id}_{Receiving_rate}.png"
        time_axis = np.arange(len(samples)) / Receiving_rate
        plt.figure()
        plt.plot(time_axis, samples)
        plt.title(f"Recorded Audio Waveform_{team_id}_{Receiving_rate}")
        plt.ylabel("Amplitude (ADC Value 0-4095)")
        plt.xlabel("Time (seconds)")
        plt.ylim(1250, 2750)
        plt.grid(True)
        plt.savefig(png_filename)
        plt.close()
        print(f"  [saved] {png_filename}")

    if 'wav' in formats:
        compile_proc = subprocess.run(
            ["gcc","team_08_CLI.c", "-o", "team_08_CLI.exe"],
            capture_output=True, text=True
        )
        if compile_proc.returncode == 0:
            run_proc = subprocess.run(
                ["./team_08_CLI.exe", team_id, str(Receiving_rate)],
                capture_output=True, text=True
            )
            print(f"  [saved] recorded_audio_{team_id}_{Receiving_rate}.wav")
        else:
            print("  [error] Compile error:", compile_proc.stderr)

# ======================================================
# Select output formats
# ======================================================
def select_formats():
    print(f"\n{'─'*50}")
    print("Select output formats (use comma to separate):")
    print("  1. WAV")
    print("  2. CSV")
    print("  3. PNG")
    print("  4. ALL")
    print(f"\n{'─'*50}")
    choice = input("  Enter: ").strip()
    formats = set()
    for c in choice.split(','):
        c = c.strip()
        if c == '1': formats.add('wav')
        if c == '2': formats.add('csv')
        if c == '3': formats.add('png')
    if not formats:
        print("No valid format selected, defaulting to all.")
        formats = {'wav', 'csv', 'png'}
    print(f"  Selected: {', '.join(sorted(formats)).upper()}")
    print(f"{'─'*50}")
    return formats
# ======================================================
# Command Line Interface
# ======================================================        
def CLI():
    while True:
        try:
            # Step 1: Choose mode
            print(f"\n{'='*50}")
            print(f"  Main Menu")
            print(f"{'='*50}")
            print("    1. Recording Mode        (Enter: m)")
            print("    2. Distance Trigger Mode  (Enter: d)")
            print("    3. Exit                  (Enter: exit)")
            print(f"{'─'*50}")
            mode_input = input("Choose mode: ").strip().lower()
            
            if mode_input == "exit":
                print("  Exiting program.")
                break

            if mode_input not in ('m', '1', 'd', '2'):
                print("Invalid mode. Enter 'm'/'1' or 'd'/'2'.")
                continue

            mode = 'm' if mode_input in ('m', '1') else 'd'

            # Step 2: Enter value
            if mode == 'm':
                value_str = input("  Enter recording time (seconds): ").strip()
            else:
                value_str = input("  Detecting distance (cm): ").strip()

            if not value_str.isdigit():
                print("Invalid value. Please enter a number.")
                continue

            value = int(value_str)
            formats = select_formats()

            # Step 3: Open serial & send command to STM32
            ser = serial.Serial(port=port_name, baudrate=baud_rate, timeout=0.1)
            command = f"{mode}{value_str}"
            ser.write(command.encode('utf-8'))
            time.sleep(0.1)

            # Step 4: Run selected mode
            if mode == 'm':
                manual_recording(ser, value, formats)
            else:
                distance_trigger_mode(ser, value, formats)
            ser.close()

        except KeyboardInterrupt:
            print("\nExiting")
            break

# ======================================================
# Main function
# ====================================================== 
if __name__ == "__main__":
    CLI()