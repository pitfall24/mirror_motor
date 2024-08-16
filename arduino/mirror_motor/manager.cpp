#include "mirror_motor.h"

using StepperAxis = MirrorMotor::StepperAxisType; // represents a steppers axis

class Manager {

public:

  MirrorMotor axis1 = NULL; // first axis, should be used for horizontal rotation
  MirrorMotor axis2 = NULL; // second axis, should be used for vertical rotation

  // whether or not axis1 or axis2 have been created yet, e.g. whether or not they exist/are not NULL
  bool a1 = false;
  bool a2 = false;

  Manager() { /* do nothing */ }

  Manager(StepperAxis ax) {
    this->axis1 = MirrorMotor(ax);
    a1 = true;
  }

  // this is never actually used but a registration protocol to register a pair of
  // steppers could be handy and would most likely use this
  Manager(StepperAxis ax1, StepperAxis ax2) {
    this->axis1 = MirrorMotor(ax1);
    this->axis2 = MirrorMotor(ax2);

    a1 = true;
    a2 = true;
  }

  // register an axis for use
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

  // steps can be positive or negative
  void moveAxis(StepperAxis ax, long steps) { // assumes this manager has axis ax
    if (ax == this->axis1.ax) {
      this->axis1.forward(steps);
    } else {
      this->axis2.forward(steps);
    }
  }

  // undo all steppers connected to this mirror/manager
  // in the future allow single axis undoing/redoing since it's kinda clunky at the moment
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

  // see undo()
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

  // updates all connected steppers. returns whether or not any of them are still running
  // call this as frequently as possible
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

  // returns whether this mirror/manager has control over a given axis
  // not really to be used in this class specifically
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