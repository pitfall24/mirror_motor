#include <Servo.h>

Servo servo;
int val;
int sign;

void setup() {
  Serial.begin(9600);

  servo.attach(11);
  val = 0;
  sign = 1;
}

void loop() {
  val += 1 * sign;

  if (val == 180 || val == 0) {
    sign = -sign;
  }

  servo.write(val);

  delay(10);
  Serial.print(val, DEC);
  Serial.write("\n");
}
