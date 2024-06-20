void setup() {
  Serial.begin(115200);
  Serial.setTimeout(50);

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

  String rec = Serial.readString();
  rec.trim();

  if (rec.equals("on")) {
    digitalWrite(LED_BUILTIN, HIGH);
    Serial.write("succesfully turned LED on\n");
  } else if (rec.equals("off")) {
    digitalWrite(LED_BUILTIN, LOW);
    Serial.write("succesfully turned LED off\n");
  } else {
    Serial.write("invalid string received\n");
  }
}
