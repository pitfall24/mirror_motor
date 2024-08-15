#include "mirror_motor.h"

using StepperAxis = MirrorMotor::StepperAxisType;

class Manager {

public:

  MirrorMotor axis1 = NULL; // first axis, should be used for horizontal rotation
  MirrorMotor axis2 = NULL; // second axis, should be used for vertical rotation

  bool a1 = false;
  bool a2 = false;

  Manager() { /* do nothing */ }

  Manager(StepperAxis ax) {
    this->axis1 = MirrorMotor(ax);
    a1 = true;
  }

  Manager(StepperAxis ax1, StepperAxis ax2) {
    this->axis1 = MirrorMotor(ax1);
    this->axis2 = MirrorMotor(ax2);

    a1 = true;
    a2 = true;
  }

  bool registerAxis(StepperAxis ax) {
    if (!a1) {
      this->axis1 = MirrorMotor(ax);
      a1 = true;
    } else {
      if (!a2) {
        this->axis2 = MirrorMotor(ax);
        a2 = true;
      } else {
        return false;
      }
    }

    return true;
  }

  void moveAxis(StepperAxis ax, long steps) { // assumes this manager has axis ax
    if (ax == this->axis1.ax) {
      this->axis1.forward(steps);
    } else {
      this->axis2.forward(steps);
    }
  }

  bool undo() {
    bool ax1, ax2;

    if (a1) {
      ax1 = this->axis1.undo();
    } else {
      ax1 = true;
    }

    if (a2) {
      ax2 = this->axis2.undo();
    } else {
      ax2 = true;
    }

    return ax1 && ax2;
  }

  bool redo() {
    bool ax1, ax2;

    if (a1) {
      ax1 = this->axis1.redo();
    } else {
      ax1 = true;
    }

    if (a2) {
      ax2 = this->axis2.redo();
    } else {
      ax2 = true;
    }

    return ax1 && ax2;
  }

  bool update() {
    bool ax1, ax2;

    if (a1) {
      ax1 = this->axis1.update();
    } else {
      ax1 = false;
    }

    if (a2) {
      ax2 = this->axis2.update();
    } else {
      ax2 = false;
    }

    return ax1 || ax2;
  }

  void stop() {
    if (a1) {
      this->axis1.stop();
    }
    
    if (a2) {
      this->axis2.stop();
    }
  }

  bool hasAxis(StepperAxis ax) {
    if (a1) {
      if (a2) {
        return this->axis1.ax == ax || this->axis2.ax == ax;
      } else {
        return this->axis1.ax == ax;
      }
    } else {
      if (a2) {
        return this->axis2.ax == ax;
      } else {
        return false;
      }
    }
  }
};