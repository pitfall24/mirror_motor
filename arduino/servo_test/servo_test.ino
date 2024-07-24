//#include <Servo.h>
#include <math.h>

//Servo servo;
int cycle;

void setup() {
  Serial.begin(115200);

  pinMode(2, OUTPUT);
  pinMode(9, OUTPUT);
  //servo.attach(9);

  digitalWrite(2, LOW);
}

void loop() {
  cycle = (cycle + 1) % 25500;
  Serial.print(170 + cycle / 666, DEC);
  Serial.write("\n");

  analogWrite(9, 170 + cycle / 666);
}
