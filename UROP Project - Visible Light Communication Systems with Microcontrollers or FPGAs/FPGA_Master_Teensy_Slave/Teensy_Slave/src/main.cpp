#include "SPI_MSTransfer_T4.h"

#define MY_SLAVE_ID 0x1111

SPI_MSTransfer_T4<&SPI, MY_SLAVE_ID> mst;

static char printableAscii(uint8_t code) {
  if (code >= 32 && code <= 126) {
    return (char)code;
  }
  return '.';
}

static void print8Bits(uint8_t value) {
  for (int bit = 7; bit >= 0; bit--) {
    Serial.print((value >> bit) & 1);
  }
}

static void print16Bits(uint16_t value) {
  for (int bit = 15; bit >= 0; bit--) {
    Serial.print((value >> bit) & 1);
  }
}

void onSwitchData(uint16_t *buffer, uint16_t length, AsyncMST info) {
  uint16_t switches = buffer[0];

  uint8_t ascii1 = (switches >> 8) & 0xFF;
  uint8_t ascii2 = switches & 0xFF;

  Serial.print(printableAscii(ascii1));
  Serial.print(printableAscii(ascii2));
  Serial.print(" (");
  print8Bits(ascii1);
  Serial.print(" ");
  print8Bits(ascii2);
  Serial.println(")");
}

void setup() {
  Serial.begin(115200);
  while (!Serial && millis() < 3000) { }

  mst.onTransfer(onSwitchData);
  mst.begin();

  Serial.println("Teensy 4.1 SPI slave ready, waiting for FPGA ASCII data...");
}

void loop() {
  mst.events();
}