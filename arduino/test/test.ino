#include <AccelStepper.h>

#define ENABLE_PIN 8

#define X_STEP_PIN 2
#define X_DIR_PIN 5

#define Y_STEP_PIN 3
#define Y_DIR_PIN 6

#define Z_STEP_PIN 4
#define Z_DIR_PIN 7

#define A_STEP_PIN 12
#define A_DIR_PIN 13

AccelStepper xStepper(AccelStepper::DRIVER, X_STEP_PIN, X_DIR_PIN);
AccelStepper yStepper(AccelStepper::DRIVER, Y_STEP_PIN, Y_DIR_PIN);
//AccelStepper zStepper(AccelStepper::DRIVER, Z_STEP_PIN, Z_DIR_PIN);
//AccelStepper aStepper(AccelStepper::DRIVER, A_STEP_PIN, A_DIR_PIN);

AccelStepper* steppers[] = {&xStepper, &yStepper};

int maxSpeed = 3000;
int maxAccel = 10000;

void setup() {
  Serial.begin(115200);

  pinMode(ENABLE_PIN, HIGH);

  xStepper.setMaxSpeed(maxSpeed);
  xStepper.setAcceleration(maxAccel);

  yStepper.setMaxSpeed(maxSpeed);
  yStepper.setAcceleration(maxAccel);

  //zStepper.setMaxSpeed(maxSpeed);
  //zStepper.setAcceleration(maxAccel);

  //aStepper.setMaxSpeed(maxSpeed);
  //aStepper.setAcceleration(maxAccel);

  xStepper.moveTo(1600); // 2 rotations?
  yStepper.moveTo(8000); // 1 rotation?
}

void loop() {
  for (AccelStepper* stepper : steppers) {
    if (stepper->distanceToGo() == 0) {
      stepper->moveTo(-stepper->currentPosition());
    }
  }

  xStepper.run();
  yStepper.run();
}
