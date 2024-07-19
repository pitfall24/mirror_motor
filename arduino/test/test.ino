#include <AccelStepper.h>

#define X_STEP_PIN 2
#define X_DIR_PIN 5
#define ENABLE_PIN 8

AccelStepper stepper(AccelStepper::DRIVER, X_STEP_PIN, X_DIR_PIN);

/*bool doneSwitching;

unsigned long curMillis;
unsigned long steps = 0;
unsigned long prevMillis = 0;
unsigned long stepMillis = 25;*/

void setup() {
  Serial.begin(115200);

  stepper.setMaxSpeed(80);
  stepper.setAcceleration(300);

  //pinMode(X_STEP_PIN, OUTPUT);
  //pinMode(X_DIR_PIN, OUTPUT);
  //pinMode(ENABLE_PIN, OUTPUT);

  //digitalWrite(X_DIR_PIN, HIGH);
  //digitalWrite(ENABLE_PIN, LOW);
  stepper.setPinsInverted(false, false, true);

  stepper.setEnablePin(8);
  stepper.enableOutputs();
}

void loop() {
  Serial.write("Going to 20\n");

  stepper.moveTo(240);
  stepper.runToPosition();

  Serial.write("Going to 0\n");

  stepper.moveTo(0);
  stepper.runToPosition();
}
