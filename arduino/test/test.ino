#include <AccelStepper.h>

#define X_STEP_PIN 2
#define X_DIR_PIN 5

AccelStepper stepper(AccelStepper::DRIVER, X_STEP_PIN, X_DIR_PIN);
 
void setup() {
  Serial.begin(115200);

  stepper.setMaxSpeed(100);
  stepper.setAcceleration(100);

  stepper.setEnablePin(8);
  stepper.enableOutputs();

  stepper.setPinsInverted(false, false, true);
}

void loop() {
  Serial.write("Going to 20000\n");

  stepper.moveTo(20000);
  stepper.runToPosition();

  delay(10);
  Serial.write("Going to -200\n");

  stepper.moveTo(-20);
  stepper.runToPosition();

  delay(10);
}
