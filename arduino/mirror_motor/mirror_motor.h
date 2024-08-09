#include <AccelStepper.h>

class MirrorMotor {

public:
  
  typedef enum {
    X,
    Y,
    Z,
    A,
  } StepperAxisType;

  AccelStepper stepper;

  long prev_pos[10] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
  int stored_moves;
  int ind;
  int undoes;

  int cor_ind(int _ind);

  MirrorMotor(int stepPin, int dirPin);
  MirrorMotor(StepperAxisType axis);

  void setMaxSpeed(float speed);
  void setMaxAccel(float accel);

  void forward(int steps);
  void backward(int steps);
  void stop();

  bool undo();
  bool redo();

  bool update();
};
