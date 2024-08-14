void setup() {
  Serial.begin(115200);

  pinMode(LED_BUILTIN, OUTPUT);
}

void loop() {
  /*
   For future reference:
    - can use Serial.readBytesUntil() or Serial.readStringUntil() to avoid Serial.setTimeout() slow downs
    - can reference https://forum.arduino.cc/t/serial-input-basics-updated/382007
    - as well as https://www.arduino.cc/reference/en/language/functions/communication/serial/
    - read functions return NULL if something goes wrong
   */

  while (!Serial.available()) {
    continue;
  }

  char rec = Serial.read();
  Serial.write("Got: ");
  Serial.write(rec);
  Serial.write(", equivalent? ");
  Serial.write(rec == 'a' ? "true" : "false");
  Serial.write("\n");
}
