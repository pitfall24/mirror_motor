#include "manager.cpp"
#include <avr/wdt.h>
#include <stdlib.h>

#define ENABLE_PIN 8
#define LOG_LEN 25

using StepperAxis = MirrorMotor::StepperAxisType;

Manager mirrorA = NULL;
Manager mirrorB = NULL;

bool maA;
bool maB;

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

  maA = false;
  maB = false;
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
    Serial.write('x');
    reboot();
  }

  if (next == 'F') {
    if (maA) {
      mirrorA.stop();
    }

    if (maB) {
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

  if (next == 'P') { // add more possible status options in the future
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
    goto update;
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
        bool success = false;
        
        StepperAxis ax = resolveAxis(specifiedAxis);
        if (specifiedMirror == 'A') {
          if (!maA) {
            mirrorA = Manager();
            maA = true;
          }

          success = mirrorA.registerAxis(ax);
        } else if (specifiedMirror == 'B') {
          if (!maB) {
            mirrorB = Manager();
            maB = true;
          }

          success = mirrorB.registerAxis(ax);
        } else { /* we should never get here */ }

        if (success) {
          Serial.write('2');
        } else {
          Serial.write('9');
        }

        specifiedMirror = '0';
        specifiedAxis = '0';
        mode = Mode::RUNNING;
        goto update;
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

  if (mode == Mode::COMMANDING && runningMode == RunningMode::WAITING_FOR_STEPS) { // DEBUG THIS: maybe a byte is unknowingly being intercepted?
    steps |= (long) next << (8 * stepsRec);
    stepsRec++;

    char buf[10];
    itoa(steps, buf, 10);

    int ind = 0;
    while (buf[ind] != '\0') {
      log_cmd(buf[ind++]);
    }
    log_cmd('e');

    if (stepsRec == 4) {
      mode = Mode::RUNNING;
      runningMode = RunningMode::PASSIVE;

      if (steps & 0x80000000) {
        steps |= 0xFFFFFFFF00000000;
      }

      steps *= specifiedDirection == 'f' ? 1 : -1;
      StepperAxis ax = resolveAxis(specifiedAxis);

      if (specifiedMirror == 'A') {
        if (!maA) {
          Serial.write('3');
        } else if (!mirrorA.hasAxis(ax)) {
          Serial.write('4');
        } else {
          mirrorA.moveAxis(ax, steps);
          Serial.write('2');
        }
      } else if (specifiedMirror == 'B') {
        if (!maB) {
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

    goto update;
  }

  if (next == 'U' && mode == Mode::RUNNING && runningMode == RunningMode::PASSIVE) {
    Serial.write('1');
    runningMode = RunningMode::UNDOING;
    goto update;
  }

  if (runningMode == RunningMode::UNDOING) {
    if (next == 'A' && maA) {
      mirrorA.undo();
      Serial.write('2');
    } else if (next == 'B' && maB) {
      mirrorB.undo();
      Serial.write('2');
    } else {
      Serial.write('3');
    }

    runningMode = RunningMode::PASSIVE;
    goto update;
  }

  if (next == 'T' && mode == Mode::RUNNING && runningMode == RunningMode::PASSIVE) {
    Serial.write('1');
    runningMode = RunningMode::REDOING;
    goto update;
  }

  if (runningMode == RunningMode::REDOING) {
    if (next == 'A' && maA) {
      mirrorA.redo();
      Serial.write('2');
    } else if (next == 'B' && maB) {
      mirrorB.redo();
      Serial.write('2');
    } else {
      Serial.write('3');
    }

    runningMode = RunningMode::PASSIVE;
    goto update;
  }

  if (mode != Mode::SLEEPING && next == 'S') {
    if (runningMode == RunningMode::PASSIVE) {
      Serial.write('1');
      mode = Mode::SLEEPING;
      runningMode = RunningMode::PASSIVE;
      pinMode(ENABLE_PIN, LOW);
      
      if (maA) {
        mirrorA.stop();
      }

      if (maB) {
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

  update:
  bool mA = false;
  bool mB = false;
  if (maA) {
    mA = mirrorA.update();
  }

  if (maB) {
    mB = mirrorB.update();
  }

  if (mA || mB) {
    moving = true;
  } else {
    moving = false;
  }

  if (cmd_to_log) {
    log_cmd(next);
    cmd_to_log = false;
  }
}

void log_cmd(char cmd) {
  cmd_log[log_ind] = cmd;
  log_ind = cor_log_ind(log_ind + 1);
}

int cor_log_ind(int ind) {
  if (ind < 0) {
    return ind + LOG_LEN;
  } else {
    return ind % LOG_LEN;
  }
}
