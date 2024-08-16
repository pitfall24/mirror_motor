#include "manager.cpp"
#include <avr/wdt.h>
#include <stdlib.h>

#define ENABLE_PIN 8 // enable pin to begin supplying power to the steppers and CNC shield
#define LOG_LEN 50

using StepperAxis = MirrorMotor::StepperAxisType; // represents a steppers axis

Manager mirrorA = NULL;
Manager mirrorB = NULL;

// whether or not mirrorA or mirrorB have been created yet, e.g. whether they exist/are not NULL
bool maA;
bool maB;

// logging variables
byte cmd_log[LOG_LEN];
int log_ind = 0;
bool cmd_to_log;

// these two enums act as a state machine for the whole arduino and its serial communication
typedef enum { // current operating mode of the arduino (self explanatory names)
  REGISTERING,
  RUNNING,
  COMMANDING,
  SLEEPING,
} Mode;

typedef enum { // more specific running modes (also self explanatory)
  PASSIVE,
  WAITING_FOR_STEPS, // while commanding
  UNDOING,
  REDOING,
} RunningMode;

Mode mode;
RunningMode runningMode;
bool moving; // whether or not were currently trying to move a stepper

byte specifiedMirror;
byte specifiedAxis;
byte specifiedDirection;

// for when were receiving a move command
long steps;
int stepsRec;

// convert a transmitted axis character (x, y, z, a) to the axis type
StepperAxis resolveAxis(byte ax) {
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

// reboot arduino, resetting all variables and states
void reboot() {
  wdt_disable();
  wdt_enable(WDTO_15MS);
}

void setup() {
  Serial.begin(115200);
  pinMode(ENABLE_PIN, HIGH); // default to allowing current to flow e.g. awake

  for (int i = 0; i < LOG_LEN; i++) {
    cmd_log[i] = 'n'; // fill log with n's (=nulls?, idk)
  }
  
  // state prep
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
    cmd_to_log = false;
    goto update; // if no commands are coming in just run the steppers as quick as we can
  }

  // !!!
  // serial communication parsing here!!
  // !!!

  // if we expect a char instead we get really weird stuff with converting to valid ASCII values
  // at least according to my painful debugging
  byte next = Serial.read(); // we have an incoming command or data value
  cmd_to_log = true;

  // reboot. avoid rebooting if were waiting for steps since certain bytes intended for stepping
  // can look like 'Q' which would be bad (this is a common patter)
  if (next == 'Q' && runningMode != RunningMode::WAITING_FOR_STEPS) {
    reboot();
  }

  // free all tasks (same byte checks for steps)
  if (next == 'F' && runningMode != RunningMode::WAITING_FOR_STEPS) {
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

  // send whole log (same checks)
  if (next == 'L' && runningMode != RunningMode::WAITING_FOR_STEPS) {
    for (int i = 0; i < LOG_LEN; i++) {
      Serial.write(cmd_log[cor_log_ind(log_ind + i)]);
    }

    goto update;
  }

  // send over the current status
  if (next == 'P' && runningMode != RunningMode::WAITING_FOR_STEPS) { // add more possible status options in the future
    byte ret;

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

  // go into registering mode
  if (next == 'R' && mode != Mode::REGISTERING && runningMode != RunningMode::WAITING_FOR_STEPS) {
    mode = Mode::REGISTERING;
    Serial.write('1');
    goto update;
  }

  // process inputs while registering
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

  // go into commanding mode
  if (mode == Mode::RUNNING && runningMode == RunningMode::PASSIVE && next == 'C') {
    Serial.write('1');
    mode = Mode::COMMANDING;
    goto update;
  }

  // process inputs and possibly go into WAITING_FOR_STEPS mode if commanding
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

  // get 4 bytes required to get number of steps to move a stepper
  if (mode == Mode::COMMANDING && runningMode == RunningMode::WAITING_FOR_STEPS) { // DEBUG THIS: maybe a byte is unknowingly being intercepted?
    steps |= ((long) next) << (8 * stepsRec);
    stepsRec++;
    cmd_to_log = false;

    // uncomment this if specific step values are being weird. this sends successive bytes recieved and adds
    // their "interpretation" (alleged decimal value) to the log. if this is happening read the log frequently
    /*
    log_cmd(next);
    byte buf[10];
    itoa(steps, buf, 10);

    int ind = 0;
    while (buf[ind] != '\0' && ind < 10) {
      log_cmd(buf[ind++]);
    }
    log_cmd('e');
    */

    // if we've gotten all 4 bytes
    if (stepsRec == 4) {
      mode = Mode::RUNNING;
      runningMode = RunningMode::PASSIVE;

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

  // go into undoing mode
  if (next == 'U' && mode == Mode::RUNNING && runningMode == RunningMode::PASSIVE) {
    Serial.write('1');
    runningMode = RunningMode::UNDOING;
    goto update;
  }

  // process inputs and execute undo
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

  // redo
  if (next == 'T' && mode == Mode::RUNNING && runningMode == RunningMode::PASSIVE) {
    Serial.write('1');
    runningMode = RunningMode::REDOING;
    goto update;
  }

  // process redo
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

  // go to sleep zzzzzzzzzz
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

  // wake up
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

  // update steppers, certain values, and write to log if applicable
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

// log a cmd/byte
void log_cmd(byte cmd) {
  cmd_log[log_ind] = cmd;
  log_ind = cor_log_ind(log_ind + 1);
}

// make sure the log index is correct so that it loops correctly
int cor_log_ind(int ind) {
  if (ind < 0) {
    return ind + LOG_LEN;
  } else {
    return ind % LOG_LEN;
  }
}
