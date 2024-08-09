import serial
import time
import sys

class MirrorMotor:
    '''
    For controlling one or two mirror motors on a single arduino
    
    Commands:
    Register an axis (single stepper motor) - 
      - Start by sending `R`, waiting until `1` received
      - Transmit which axis (`x`, `y`, `z`, or `a`) followed by `r` until `2` is received
    
    Command an axis to move - 
     - Start by sending `C`, waiting until `1` received
     - Send which mirror you're controlling (`A` or `B`)
     - Send which direction you want to go (`f` or `b`), wait until `1` received
     - Send number of steps (required to be 4 bytes) followed by `c` until `2` is received
   
   Undo a move - 
     - Start by sending `U` until `1` is received
   
   Redo an undone move - 
     - Start by sending `T` (R and Z are taken) until `1` is received
    '''
    
    def __init__(self, serial_port='/dev/arduino1', baudrate=115200):
        self.arduino = serial.Serial(port=serial_port, baudrate=baudrate)
        
        print('MirrorMotor instantiated and serial connection made')
    
    def read_chars(self, num=None):
        rec = []
        
        while self.arduino.in_waiting > 0 and (True if num is None else len(rec) < num):
            char = self.arduino.read(1)
            rec.append(char.decode())
        
        return rec
    
    def write_char(self, char):
        self.arduino.write(f'{char}\n'.encode())
    
    def stop(self):
        self.arduino.close()
        
        raise SystemExit() # equivalent to sys.exit()

