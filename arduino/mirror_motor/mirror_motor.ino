#include "manager.cpp"

#define ENABLE_PIN 8

#define LOG_LEN 50
#define BUF_LEN 50

Manager mirrorA = NULL;
Manager mirrorB = NULL;

char buffer[BUF_LEN];
char cmd_log[LOG_LEN];
int log_ind = 0;

typedef enum {
  REGISTERING,
  RUNNING,
  SLEEPING,
} Mode;

Mode mode;

bool man_exists(Manager man) {
  return &man != NULL;
}

void setup() {
  Serial.begin(115200);

  mode = Mode::RUNNING;
}

void loop() {
  if (!Serial.available() && mode != Mode::SLEEPING) {
    goto update;
  }

  // serial communication parsing here!!
  char next = Serial.peek();

  update:
  if (man_exists(mirrorA)) {
    mirror1.update();
  }

  if (man_exists(mirrorB)) {
    mirror2.update();
  }
}

bool send_char(char ch) {
  Serial.write(ch);
}

int read_char() {
  return Serial.read();
}

int cor_log_ind(int ind) {
  if (ind < 0) {
    return ind + LOG_LEN;
  } else {
    return ind % LOG_LEN;
  }
}
