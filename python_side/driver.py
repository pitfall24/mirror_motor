import serial
from time import monotonic
import sys

class MirrorMotor:
    '''
    For controlling one or two mirror motors on a single arduino
    
    Commands:
    Register an axis (single stepper motor) - 
      - Start by sending `R`, waiting until `1` received
      - Transmit which mirror ('A' or 'B') followed by which axis (`x`, `y`, `z`, or `a`) followed by `r`
      - If `3` is received it failed (e.g. axis already taken), if `2` is received it succeeded
    
    Command an axis to move - 
      - Start by sending `C`, waiting until `1` received
      - Send which mirror you're controlling (`A` or `B`)
      - Send which direction you want to go (`f` or `b`), wait until `1` received. If `3` is received then that mirror doesn't exist
      - Send number of steps (required to be 4 bytes) followed by `c` until `2` is received
    
    Undo a move - 
      - Start by sending `U` until `1` is received
      - Send which mirror you're controlling ('A' or 'B'). If `3` is received then that mirror doesn't exist
      - If `3` is returned the undo failed, if `2` is returned it succeeded
    
    Redo an undone move - 
      - Start by sending `T` (R and Z are taken) until `1` is received
      - Send which mirror you're controlling ('A' or 'B'). If `3` is received then that mirror doesn't exist
      - If `3` is returned the redo failed, if `2` is returned it succeeded
    
    Sleep - 
      - Send `S` until `1` is received
      - To wake up send `W` until `1` is received 
    '''
    
    def __init__(self, serial_port='/dev/arduino1', baudrate=115200, timeout=0.1):
        self.arduino = serial.Serial(port=serial_port, baudrate=baudrate)
        
        print('MirrorMotor instantiated and serial connection made')
    
    def register(mirror, axis):
        if mirror not in ['A', 'B']:
            raise ValueError(f'Variable "mirror" must be "A" or "B", not {mirror}')
        
        if axis not in ['x', 'y', 'z', 'a']:
            raise ValueError(f'Variables "axis" must be "x", "y", "z", or "a", not {axis}')
        
        if hasattr(self, mirror):
            if hasattr(self.mirror, axis):
                raise ValueError(f'Axis {axis} for mirror {mirror} already registered')
            
            axis_obj = AxisObject(self, mirror, axis)
            setattr(self.mirror, axis, axis_obj)
        else:
            axis_obj = AxisObject(self, mirror, axis)
            mirror_sleep_interface = MirrorSleepInterface(self, axis_obj)
            mirror_obj = type('MirrorObject', (object, ), {axis: axis_obj, 'sleep': mirror_sleep_interface})
            
            setattr(self, mirror, mirror_obj)
    
    def read_chars(self, num=None):
        rec = []
        
        start = monotonic()
        while self.arduino.in_waiting > 0 and (True if num is None else len(rec) < num) and monotonic() - start < self.timeout:
            char = self.arduino.read(1)
            rec.append(char.decode())
            
            start = monotonic()
        
        return rec
    
    def write_char(self, char):
        self.arduino.write(f'{char}\n'.encode())
    
    def write_num(self, num):
        self.arduino.write(num.to_bytes(4, 'little'))
    
    def stop(self):
        self.arduino.close()
        
        raise SystemExit() # equivalent to sys.exit()

# abstract this to work for both arduino.A.sleep() and arduino.A.wake()
# should be easy with a simple metaclass or something
class MirrorSleepInterface:
    '''
    Class with callable for whole-mirror sleep
    
    Sleep - 
      - Send `S` until `1` is received
      - To wake up send `W` until `1` is received 
    '''
    
    def __init__(self, mm_instance, an_axis):
        self.mm_instance = mm_instance
        self.an_axis = an_axis
    
    def __call__(self):
        self.mm_instance.write_char('S')
        res, _ = self.an_axis.wait_for_char('1')
        if !res:
            raise Exception(f'Failed to sleep mirror {self.an_axis.mirror}.')

class AxisObject:
    '''
    Controls a given axis of a specific mirror
    '''
    
    def __init__(self, mm_instance, mirror, axis):
        self.mm_instance = mm_instance
        self.mirror = mirror
        self.axis = axis
        
        self.timeout = self.mm_instance.timeout
        
        self.remotely_register()
    
    '''
    Register an axis (single stepper motor) - 
      - Start by sending `R`, waiting until `1` received
      - Transmit which mirror ('A' or 'B') followed by which axis (`x`, `y`, `z`, or `a`) followed by `r`
      - If `3` is received it failed (e.g. axis already taken), if `2` is received it succeeded
    '''
    def remotely_register(self):
        self.mm_instance.write_char('R')
        
        res, _ = self.wait_for_char('1')
        if !res:
           raise Exception(f'Failed to register axis {self.axis} while confirming connection.')
        
        self.mm_instance.write_char(self.mirror)
        self.mm_instance.write_char(self.axis)
        self.mm_instance.write_char('r')
        
        res, got = self.wait_for_char('2')
        if got != '2':
            raise Exception(f'Axis {self.axis} has already been taken (on the arduino).')
        
        if !res:
            raise Exception(f'Failed to register axis {self.axis} while transmitting axis.')
    
    '''
    Command an axis to move - 
      - Start by sending `C`, waiting until `1` received
      - Send which mirror you're controlling (`A` or `B`)
      - Send which direction you want to go (`f` or `b`), wait until `1` received. If `3` is received then that mirror doesn't exist
      - Send number of steps (required to be 4 bytes) followed by `c` until `2` is received
    '''
    def move(self, direction, steps):
        if direction not in ['f', 'b']:
            raise ValueError(f'Direction must be "f" or "b", not {direction}.')
        
        self.mm_instance.write_char('C')
        res, _ = self.wait_for_char('1')
        if !res:
            raise Exception(f'Failed to move axis {self.axis} while confirming connection.')
        
        self.mm_instance.write_char(self.mirror)
        self.mm_instance.write_char(direction)
        res, got = self.wait_for_char('1')
        if got != '1':
            raise Exception(f'Axis {self.axis} on mirror {self.mirror} doesn\'t exist.')
        
        if !res:
            raise Exception(f'Failed to move axis {self.axis} on mirror {self.mirror} while confirming assignment.')
        
        self.mm_instance.write_num(steps)
        self.mm_instance.write_char('c')
        res, got = self.wait_for_char('2')
        if got != '2' or !res:
            raise Exception(f'Failed to send {steps} steps to axis {self.axis} on mirror {self.mirror}.')
    
    '''
    Undo a move - 
      - Start by sending `U` until `1` is received
      - Send which mirror you're controlling ('A' or 'B'). If `3` is received then that mirror doesn't exist
      - If `3` is returned the undo failed, if `2` is returned it succeeded
    '''
    def undo(self):
        self.mm_instance.write_char('U')
        res, _ = self.wait_for_char('1')
        if !res:
            raise Exception(f'Failed to undo move for axis {self.axis} on mirror {self.mirror} while confirming communication.')
        
        self.mm_instance.write_char(self.mirror)
        res, got = self.wait_for_char('2')
        if got == '3':
            raise Exception(f'Axis {self.axis} or mirror {self.mirror} doesn\'t exist while redoing')
        
        if got != '2' or !res:
            raise Exception(f'Failed to send mirror assignment to axis {self.axis} on mirror {self.mirror}.')
    
    '''
    Redo an undone move - 
      - Start by sending `T` (R and Z are taken) until `1` is received
      - Send which mirror you're controlling ('A' or 'B'). If `3` is received then that mirror doesn't exist
      - If `3` is returned the redo failed, if `2` is returned it succeeded
    '''
    def redo(self):
        self.mm_instance.write_char('T')
        res, _ = self.wait_for_char('1')
        if !res:
            raise Exception(f'Failed to redo move for axis {self.axis} on mirror {self.mirror} while confirming communication.')
        
        self.mm_instance.write_char(self.mirror)
        res, got = self.wait_for_char('2')
        if got == '3':
            raise Exception(f'Axis {self.axis} or mirror {self.mirror} doesn\'t exist while redoing')
        
        if got != '2' or !res:
            raise Exception(f'Failed to send mirror assignment to axis {self.axis} on mirror {self.mirror}.')
    
    def wait_for_char(self, char):
        start = monotonic()
        
        while monotonic() - start < self.timeout and self.mm_instance.arduino.in_waiting == 0:
            # sleeping might be better/safer?
            #sleep(0.001)
            pass
        
        if self.mm_instance.arduino.in_waiting > 0:
            rec = self.mm_instance.arduino.read(1).decode()
            
            return rec == char, rec
        
        return False, None

