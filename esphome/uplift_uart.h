#include "esphome.h"

class UartUpliftSensor : public Component, public UARTDevice, public Sensor {
 public:
  UartUpliftSensor(UARTComponent *parent) : UARTDevice(parent) {}

  void setup() override {
  }

  bool startcode(int readch)
  {
    static int lastch = 0;
    if (readch == 1 && lastch == 1) {
      lastch = 0;
      return true;
    } else {
      lastch = readch;
    }
    return false;
  }

  void loop() override {
    const int max_line_length = 5;
    static char buffer[max_line_length];
    static bool mode = false;
    static bool first_byte = true;
    static unsigned short raw_data = 0;
    static unsigned short previous_raw_data = 0;

    //wait for start code to be detected
    while (mode == false && available()) {
      mode = startcode(read());
      first_byte = true;
    }
    //get the actual data
    while (mode == true && available()) {
      if (first_byte) {
        raw_data = 256*read();
        first_byte = false;
        if (raw_data > 256) { //data is being interpreted out of sequence, restart the process
          mode = false;
        }
      } else {
        raw_data += read();
        mode=false;
        if (previous_raw_data != raw_data) {
          publish_state((raw_data / 10.0));
          previous_raw_data = raw_data;
        }
      }
    }
  }
};