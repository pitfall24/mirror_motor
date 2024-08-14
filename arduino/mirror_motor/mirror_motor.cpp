#pragma once
#include "mirror_motor.h"

#define X_STEP_PIN 2
#define X_DIR_PIN 5

#define Y_STEP_PIN 3
#define Y_DIR_PIN 6

#define Z_STEP_PIN 4
#define Z_DIR_PIN 7

#define A_STEP_PIN 12
#define A_DIR_PIN 13

using StepperAxis = MirrorMotor::StepperAxisType;

int getStepPin(StepperAxis axis) {
  switch (axis) {
    case StepperAxis::X: return X_STEP_PIN;
    case StepperAxis::Y: return Y_STEP_PIN;
    case StepperAxis::Z: return Z_STEP_PIN;
    case StepperAxis::A: return A_STEP_PIN;
  }
}

int getDirPin(StepperAxis axis) {
  switch (axis) {
    case StepperAxis::X: return X_DIR_PIN;
    case StepperAxis::Y: return Y_DIR_PIN;
    case StepperAxis::Z: return Z_DIR_PIN;
    case StepperAxis::A: return A_DIR_PIN;
  }
}

int MirrorMotor::cor_ind(int _ind) {
  if (_ind < 0) {
    return _ind + this->stored_moves;
  } else {
    return _ind % this->stored_moves;
  }
}

MirrorMotor::MirrorMotor(int stepPin, int dirPin) {
  this->stepper = AccelStepper(AccelStepper::DRIVER, stepPin, dirPin);

  this->stepper.setMaxSpeed(600.0);
  this->stepper.setAcceleration(2000.0);

  this->stored_moves = sizeof(this->prev_pos) / sizeof(this->prev_pos[0]);
  this->ind = 0;
  this->undoes = 0;
}

MirrorMotor::MirrorMotor(StepperAxis axis) {
  this->stepper = AccelStepper(AccelStepper::DRIVER, getStepPin(axis), getDirPin(axis));

  this->stored_moves = sizeof(this->prev_pos) / sizeof(this->prev_pos[0]);
  this->ind = 0;
  this->undoes = 0;
  this->ax = axis;
}

void MirrorMotor::setMaxSpeed(float speed) {
  this->stepper.setMaxSpeed(speed);
}

void MirrorMotor::setMaxAccel(float accel) {
  this->stepper.setAcceleration(accel);
}

void MirrorMotor::forward(long steps) {
  this->prev_pos[ind] = this->stepper.currentPosition();
  this->ind = (this->ind + 1) % this->stored_moves;

  // gearing causes clockwise rotation to be counterclockwise output so we reverse it
  this->stepper.move(-steps);
}

void MirrorMotor::backward(long steps) {
  this->prev_pos[ind] = this->stepper.currentPosition();
  this->ind = (this->ind + 1) % this->stored_moves;

  // gearing causes clockwise rotation to be counterclockwise output so we reverse it
  this->stepper.move(steps);
}

void MirrorMotor::stop() {
  this->stepper.stop();
}

bool MirrorMotor::undo() {
  if (undoes >= 9 || this->stepper.isRunning()) {
    return false;
  }

  this->ind = this->cor_ind(ind - 1);
  this->stepper.moveTo(this->prev_pos[this->ind]);
  this->undoes += 1;

  return true;
}

bool MirrorMotor::redo() {
  if (undoes == 0 || this->stepper.isRunning()) {
    return false;
  }

  this->ind = this->cor_ind(ind + 1);
  this->stepper.moveTo(this->prev_pos[this->ind]);
  this->undoes -= 1;

  return true;
}

bool MirrorMotor::update() {
  return this->stepper.run();
}
