#include <AccelStepper.h>

class MirrorMotor {

public:
  
  typedef enum { // represents a steppers axis
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
  StepperAxisType ax;

  int cor_ind(int _ind);

  MirrorMotor(int stepPin, int dirPin);
  MirrorMotor(StepperAxisType axis);

  void setMaxSpeed(float speed);
  void setMaxAccel(float accel);

  void forward(long steps);
  void backward(long steps);
  void stop();

  bool undo();
  bool redo();

  bool update();
};
