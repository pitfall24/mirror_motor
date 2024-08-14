#include <AccelStepper.h>
#include <avr/wdt.h>

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
//AccelStepper yStepper(AccelStepper::DRIVER, Y_STEP_PIN, Y_DIR_PIN);
//AccelStepper zStepper(AccelStepper::DRIVER, Z_STEP_PIN, Z_DIR_PIN);
//AccelStepper aStepper(AccelStepper::DRIVER, A_STEP_PIN, A_DIR_PIN);

AccelStepper* steppers[] = {&xStepper};//, &yStepper};
char labels[] = {'x'};

int maxSpeed = 600; // 1 rev / s
int maxAccel = 5000;

int xTarg = 1200; // 1.5 rotations
int yTarg = 800; // 1 rotation

int num_updates;

void setup() {
  Serial.begin(115200);

  pinMode(ENABLE_PIN, HIGH);

  xStepper.setMaxSpeed(maxSpeed);
  xStepper.setAcceleration(maxAccel);

  //yStepper.setMaxSpeed(maxSpeed);
  //yStepper.setAcceleration(maxAccel);

  //zStepper.setMaxSpeed(maxSpeed);
  //zStepper.setAcceleration(maxAccel);

  //aStepper.setMaxSpeed(maxSpeed);
  //aStepper.setAcceleration(maxAccel);

  xStepper.move(xTarg);
  //yStepper.moveTo(yTarg);

  num_updates = 0;
}

void loop() {
  for (int i = 0; i < sizeof(steppers) / sizeof(steppers[0]); i++) {
    AccelStepper* stepper = steppers[i];
    char name = labels[i];

    if (stepper->distanceToGo() == 0) {
      stepper->move(stepper->currentPosition() == 0 ? (name == 'x' ? xTarg : yTarg) : -xTarg);
    }
  }

  xStepper.run();
  //yStepper.run();

  num_updates += 1;

  if (Serial.available()) {
    char next = Serial.read();
    if (next == 'j') {
      Serial.print(num_updates, DEC);
    }

    if (next == 'Q') {
      reboot();
    }
  }
}

void reboot() {
  wdt_disable();
  wdt_enable(WDTO_15MS);
}
