#include "mirror_motor.h"

using StepperAxis = MirrorMotor::StepperAxisType;

inline bool exists(MirrorMotor ax) {
  return &ax != NULL;
}

class Manager {

public:

  MirrorMotor axis1 = NULL; // first axis, should be used for horizontal rotation
  MirrorMotor axis2 = NULL; // second axis, should be used for vertical rotation

  Manager(StepperAxis ax) {
    this->axis1 = MirrorMotor(ax);
  }

  Manager(StepperAxis ax1, StepperAxis ax2) {
    this->axis1 = MirrorMotor(ax1);
    this->axis2 = MirrorMotor(ax2);
  }

  bool registerAxis(StepperAxis ax) {
    if (!exists(this->axis1)) {
      this->axis1 = MirrorMotor(ax);
    } else {
      if (!exists(this->axis2)) {
        this->axis2 = MirrorMotor(ax);
      } else {
        return false;
      }
    }

    return true;
  }

  void update() {
    if (exists(this->axis1)) {
      this->axis1.update();
    }

    if (exists(this->axis2)) {
      this->axis2.update();
    }
  }
};