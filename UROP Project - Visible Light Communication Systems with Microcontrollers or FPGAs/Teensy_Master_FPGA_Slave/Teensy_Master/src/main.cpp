#include <Arduino.h>
#include <SPI.h>

const int slaveSelectPin = 10;
const size_t FRAME_SIZE = 8;

// Teensy -> FPGA SPI: 5 MHz, MSB-first, mode 0.
SPISettings Teensysetting(5000000, MSBFIRST, SPI_MODE0);

void fpgaWriteFrame(const uint8_t frame[FRAME_SIZE]);

void setup() {
    Serial.begin(9600);
    while (!Serial && millis() < 5000) {
    }

    pinMode(slaveSelectPin, OUTPUT);
    digitalWrite(slaveSelectPin, HIGH);
    SPI.begin();

    Serial.println("--- FPGA is ready to receive 8 characters ---");
}

void loop() {
    String input;

    Serial.print("Enter up to 8 characters: ");

    while (true) {
        if (Serial.available() > 0) {
            const char c = Serial.read();

            if (c == '\r') {
                continue;
            }

            if (c == '\n') {
                Serial.println();
                break;
            }

            if (c == 8 || c == 127) {
                if (input.length() > 0) {
                    input.remove(input.length() - 1);
                    Serial.print("\b \b");
                }
            } else if (input.length() < FRAME_SIZE) {
                input += c;
                Serial.print(c);
            }
        }
    }

    uint8_t frame[FRAME_SIZE];

    // Pad unused display positions with ASCII spaces.
    for (size_t i = 0; i < FRAME_SIZE; ++i) {
        frame[i] = (i < input.length())
            ? static_cast<uint8_t>(input.charAt(i))
            : static_cast<uint8_t>(' ');
    }

    fpgaWriteFrame(frame);

    Serial.print("Sent: [");
    for (size_t i = 0; i < FRAME_SIZE; ++i) {
        Serial.print(static_cast<char>(frame[i]));
    }
    Serial.println("]");
}

void fpgaWriteFrame(const uint8_t frame[FRAME_SIZE]) {
    SPI.beginTransaction(Teensysetting);

    // Keep CS low for the entire 8-byte frame.
    digitalWrite(slaveSelectPin, LOW);
    delay(2);

    for (size_t i = 0; i < FRAME_SIZE; ++i) {
        SPI.transfer(frame[i]);
    }

    delay(2);
    digitalWrite(slaveSelectPin, HIGH);
    SPI.endTransaction();
}
