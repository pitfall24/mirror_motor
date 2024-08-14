#include "manager.cpp"
#include <avr/wdt.h>

#define ENABLE_PIN 8
#define LOG_LEN 25

using StepperAxis = MirrorMotor::StepperAxisType;

Manager mirrorA = NULL;
Manager mirrorB = NULL;

char cmd_log[LOG_LEN];
int log_ind = 0;
bool cmd_to_log;

typedef enum {
  REGISTERING,
  RUNNING,
  COMMANDING,
  SLEEPING,
} Mode;

typedef enum {
  PASSIVE,
  WAITING_FOR_STEPS,
  UNDOING,
  REDOING,
} RunningMode;

Mode mode;
RunningMode runningMode;
bool moving;

char specifiedMirror;
char specifiedAxis;
char specifiedDirection;

long steps;
int stepsRec;

int num_updates;

bool man_exists(Manager man) {
  return &man != NULL;
}

StepperAxis resolveAxis(char ax) {
  if (ax == 'x') {
    return StepperAxis::X;
  } else if (ax == 'y') {
    return StepperAxis::Y;
  } else if (ax == 'z') {
    return StepperAxis::Z;
  } else if (ax == 'a') {
    return StepperAxis::A;
  } else {
    // whoops
  }
}

void reboot() {
  wdt_disable();
  wdt_enable(WDTO_15MS);
}

void setup() {
  Serial.begin(115200);
  pinMode(ENABLE_PIN, HIGH);

  for (int i = 0; i < LOG_LEN; i++) {
    cmd_log[i] = 'n';
  }
  
  mode = Mode::RUNNING;
  runningMode = RunningMode::PASSIVE;
  moving = false;

  specifiedMirror = '0';
  specifiedAxis = '0';
  specifiedDirection = '0';

  steps = 0;
  stepsRec = 0;

  num_updates = 0;
}

void loop() {
  if (!Serial.available()/* && mode != Mode::SLEEPING // I dont think I need this*/) {
    goto update;
  }

  // !!!
  // serial communication parsing here!!
  // !!!

  char next = Serial.read();
  if (next == -1) {
    goto update;
  } else {
    cmd_to_log = true;
  }

  if (next == 'Q') {
    reboot();
  }

  if (next == 'F') {
    if (man_exists(mirrorA)) {
      mirrorA.stop();
    }

    if (man_exists(mirrorB)) {
      mirrorB.stop();
    }

    pinMode(ENABLE_PIN, HIGH);

    mode = Mode::RUNNING;
    runningMode = RunningMode::PASSIVE;
    moving = false;

    specifiedMirror = '0';
    specifiedAxis = '0';

    while (Serial.available()) { // flush any characters in the buffer
      Serial.read();
    }

    Serial.write('1');
  }

  if (next == 'L') {
    for (int i = 0; i < LOG_LEN; i++) {
      Serial.write(cmd_log[cor_log_ind(log_ind + i)]);
    }

    goto update;
  }

  if (next == 'P') { // adjust this at some point to reflect the value of `moving`
    char ret;

    if (mode == Mode::REGISTERING) {
      ret = '4';
    } else if (mode == Mode::RUNNING) {
      if (moving) {
        ret = '2';
      } else {
        if (runningMode == RunningMode::PASSIVE) {
          ret = '1';
        }
      }
    } else if (mode == Mode::SLEEPING) {
      ret = '3';
    } else {
      ret = '0'; // failed state
    }

    Serial.write(ret);
  }

  if (next == 'R' && mode != Mode::REGISTERING) {
    mode = Mode::REGISTERING;
    Serial.write('1');
    goto update;
  }

  if (mode == Mode::REGISTERING) {
    if (specifiedMirror == '0') {
      if (next != 'A' && next != 'B') {
        Serial.write('3'); // we have a problem
        goto update;
      }

      specifiedMirror = next;
    } else if (specifiedAxis == '0') {
      if (next != 'x' && next != 'y' && next != 'z' && next != 'a') {
        Serial.write('3'); // we have a problem
        goto update;
      }

      specifiedAxis = next;
    } else {
      if (next == 'r') {
        Serial.write('2');
        
        StepperAxis ax = resolveAxis(specifiedAxis);
        if (specifiedMirror == 'A') {
          if (!man_exists(mirrorA)) {
            mirrorA = Manager();
          }

          mirrorA.registerAxis(ax);
        } else if (specifiedMirror == 'B') {
          if (!man_exists(mirrorB)) {
            mirrorB = Manager();
          }

          mirrorB.registerAxis(ax);
        } else { /* we should never get here */ }

        specifiedMirror = '0';
        specifiedAxis = '0';
        mode = Mode::RUNNING;
      }
    }
  }

  if (mode == Mode::RUNNING && runningMode == RunningMode::PASSIVE && next == 'C') {
    Serial.write('1');
    mode = Mode::COMMANDING;
    goto update;
  }

  if (mode == Mode::COMMANDING && runningMode != RunningMode::WAITING_FOR_STEPS) {
    if (specifiedMirror == '0') {
      if (next != 'A' && next != 'B') {
        Serial.write('4'); // we have a problem
        goto update;
      }

      specifiedMirror = next;
    } else if (specifiedAxis == '0') {
      if (next != 'x' && next != 'y' && next != 'z' && next != 'a') {
        Serial.write('5'); // we have a problem
        goto update;
      }

      specifiedAxis = next;
    } else if(specifiedDirection == '0') {
      if (next != 'f' && next != 'b') {
        Serial.write('6'); // we have a problem
        goto update;
      }

      specifiedDirection = next;
      Serial.write('1');
      runningMode = RunningMode::WAITING_FOR_STEPS;
    } else {
      Serial.write('7'); // we have a problem
    }

    goto update;
  }

  if (mode == Mode::COMMANDING && runningMode == RunningMode::WAITING_FOR_STEPS) {
    steps += (long) next << (8 * stepsRec++);
    cmd_to_log = false;

    if (stepsRec == 4) {
      mode == Mode::RUNNING;
      runningMode = RunningMode::PASSIVE;

      steps *= specifiedDirection == 'f' ? 1 : -1;
      StepperAxis ax = resolveAxis(specifiedAxis);

      if (specifiedMirror == 'A') {
        if (!man_exists(mirrorA)) {
          Serial.write('3');
        } else if (!mirrorA.hasAxis(ax)) {
          Serial.write('3');
        } else {
          mirrorA.moveAxis(ax, steps);
          Serial.write('2');
        }
      } else if (specifiedMirror == 'B') {
        if (!man_exists(mirrorB)) {
          Serial.write('3');
        } else if (!mirrorB.hasAxis(ax)) {
          Serial.write('3');
        } else {
          mirrorB.moveAxis(ax, steps);
          Serial.write('2');
        }
      } else { /* we should never get here */ }

      specifiedMirror = '0';
      specifiedAxis = '0';
      specifiedDirection = '0';

      steps = 0;
      stepsRec = 0;

      mode = Mode::RUNNING;
      runningMode = RunningMode::PASSIVE;
      moving = true;

      cmd_to_log = true;
      next = 'V';
    }
  }

  if (next == 'U' && mode == Mode::RUNNING && runningMode == RunningMode::PASSIVE) {
    Serial.write('1');
    runningMode = RunningMode::UNDOING;
  }

  if (runningMode == RunningMode::UNDOING) {
    if (next == 'A' && man_exists(mirrorA)) {
      mirrorA.undo();
      Serial.write('2');
    } else if (next == 'B' && man_exists(mirrorB)) {
      mirrorB.undo();
      Serial.write('2');
    } else {
      Serial.write('3');
    }
  }

  if (next == 'T' && mode == Mode::RUNNING && runningMode == RunningMode::PASSIVE) {
    Serial.write('1');
    runningMode = RunningMode::REDOING;
  }

  if (runningMode == RunningMode::REDOING) {
    if (next == 'A' && man_exists(mirrorA)) {
      mirrorA.redo();
      Serial.write('2');
    } else if (next == 'B' && man_exists(mirrorB)) {
      mirrorB.redo();
      Serial.write('2');
    } else {
      Serial.write('3');
    }
  }

  if (mode != Mode::SLEEPING && next == 'S') {
    if (runningMode == RunningMode::PASSIVE) {
      Serial.write('1');
      mode = Mode::SLEEPING;
      runningMode = RunningMode::PASSIVE;
      pinMode(ENABLE_PIN, LOW);
      
      if (man_exists(mirrorA)) {
        mirrorA.stop();
      }

      if (man_exists(mirrorB)) {
        mirrorB.stop();
      }
    } else {
      Serial.write('2'); // couldn't sleep, likely because were moving, possibly because some error occurred
    }

    goto update;
  }

  if (mode == Mode::SLEEPING) {
    if (next != 'W') {
      // do nothing because were asleep
      // we can however register axes (above)
    } else {
      Serial.write('1');
      mode = Mode::RUNNING;
      runningMode = RunningMode::PASSIVE;
      pinMode(ENABLE_PIN, HIGH);
    }
  }

  if (next == 'j') {
    Serial.print(num_updates, DEC);
  }

  update:
  bool mA = false;
  bool mB = false;
  if (man_exists(mirrorA)) {
    mA = mirrorA.update();
    num_updates += 1;
  }

  if (man_exists(mirrorB)) {
    mB = mirrorB.update();
  }

  if (mA || mB) {
    moving = true;
  } else {
    moving = false;
  }

  if (cmd_to_log) {
    cmd_log[log_ind] = next;
    log_ind = cor_log_ind(log_ind + 1);

    cmd_to_log = false;
  }
}

int cor_log_ind(int ind) {
  if (ind < 0) {
    return ind + LOG_LEN;
  } else {
    return ind % LOG_LEN;
  }
}
