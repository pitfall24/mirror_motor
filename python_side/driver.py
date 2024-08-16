import serial
from time import monotonic, sleep
import sys

class MirrorMotor:
    '''
    For controlling one or two mirror motors on a single arduino
    
    Commands:
    x Register an axis (single stepper motor) - 
      - Start by sending `R`, waiting until `1` received
      - Transmit which mirror ('A' or 'B') followed by which axis (`x`, `y`, `z`, or `a`) followed by `r`
      - If `3` is received it failed (e.g. axis already taken), if `2` is received it succeeded
    
    x Command an axis to move - 
      - Start by sending `C`, waiting until `1` received
      - Send which mirror you're controlling (`A` or `B`) followed by which axis (`x`, `y`, `z`, or `a`)
      - Send which direction you want to go (`f` or `b`), wait until `1` received. If `3` is received then that mirror doesn't exist
      - Send number of steps (required to be 4 bytes) until `2` is received
    
    x Undo a move - 
      - Start by sending `U` until `1` is received
      - Send which mirror you're controlling ('A' or 'B'). If `3` is received then that mirror doesn't exist
      - If `3` is returned the undo failed, if `2` is returned it succeeded
    
    x Redo an undone move - 
      - Start by sending `T` (R and Z are taken) until `1` is received
      - Send which mirror you're controlling ('A' or 'B'). If `3` is received then that mirror doesn't exist
      - If `3` is returned the redo failed, if `2` is returned it succeeded
    
    x Sleep - 
      - Send `S` until `1` is received
      - To wake up send `W` until `1` is received
    
    x Request status - 
      - Send `P`. If nothing comes back its broken, otherwise:
         - `1` means its free and awake
         - `2` means its still running (a stepper)
         - `3` means its asleep
         - `4` means its registering
    
    x Free everything and set the arduino to passive mode - 
      - Send `F`. If `1` is received it succeeded, if `2` is received it failed
    
    x Reboot the arduino to escape some failed state - 
      - Send `Q`. We can't expect anything to be returned, and this class instance is reset as well
    
    x Retrieve log - 
      - Send `L`, read in 50 characters
    '''
    
    def __init__(self, serial_port='/dev/arduino1', baudrate=115200, timeout=0.1):
        self.serial_port = serial_port
        self.baudrate = baudrate
        self.timeout = timeout
        
        self.arduino = serial.Serial(port=self.serial_port, baudrate=self.baudrate, timeout=self.timeout)
        
        self.sleeping = False
        
        print('MirrorMotor instantiated and serial connection made')
    
    def register(self, mirror, axis):
        if mirror not in ['A', 'B']:
            raise ValueError(f'Variable "mirror" must be "A" or "B", not {mirror}')
        
        if axis not in ['x', 'y', 'z', 'a']:
            raise ValueError(f'Variables "axis" must be "x", "y", "z", or "a", not {axis}')
        
        if hasattr(self, mirror):
            mir_ob = getattr(self, mirror)
            if hasattr(mir_ob, axis):
                 u = f'Axis {axis} for mirror {mirror} already registered'
                 print(u)
                 return u
            
            axis_obj = AxisObject(self, mirror, axis)
            setattr(getattr(self, mirror), axis, axis_obj)
        else:
            axis_obj = AxisObject(self, mirror, axis)
            mirror_interface = MirrorInterface(self, axis_obj)
            
            setattr(self, mirror, mirror_interface)
    
    def sleep(self):
        self.write_char('S')
        res, _ = self.wait_for_char('1')
        if not res:
            if self.sleeping:
                u = 'Failed to sleep since it is likely already asleep.'
                print(u)
                return u
            else:
                raise Exception(f'Failed to sleep. It may be already asleep.')
        else:
            self.sleeping = True
    
    def wake(self):
        self.write_char('W')
        res, _ = self.wait_for_char('1')
        if not res:
            if not self.sleeping:
                u = 'Failed to wake likely because it is already awake.'
                print(u)
                return u
            else:
                raise Exception(f'Failed to wake. It may be already awake.')
        else:
            self.sleeping = False
    
    def cancel_all(self):
        self.write_char('F')
        _, got = self.wait_for_char('1')
        if got != '1':
            print(f'Got {got} from arduino.')
            raise Exception(f'Failed to cancel tasks.')
    
    def reboot(self):
        self.write_char('Q')
        sleep(0.01)
        # we can't really expect it to be able to return anything after this
        # we also have to reset all preconcieved states on this end which is done by the AttributeProxy class
    
    def get_log(self):
        self.write_char('L')
        log = self.read_chars(num=50)
        
        try:
            s = ' '.join(''.join(log[i:i + 5]) for i in range(0, len(log), 5))
        except TypeError:
            s = log
        
        res = f'Log (most recent LAST) (length {len(log)}): {s}.'
        
        print(res)
        return res
    
    def status(self): # add more status options in the future
        self.write_char('P')
        _, got = self.wait_for_char('1')
        if got is None:
            raise Exception(f'Failed to retrieve status.')
        
        if got == '1':
            stat = f'Status is free and awake'
        elif got == '2':
            stat = f'Status is awake and currently running a stepper'
        elif got == '3':
            stat = f'Status is asleep'
        elif got == '4':
            stat = f'Status is registering'
        else:
            print(f'Got {got} from arduino.')
            stat = f'Status returned an unexpected value'
        
        print(stat)
        return got, stat
    
    def read_chars(self, num=None):
        rec = []
        
        start = monotonic()
        while self.arduino.in_waiting < (1 if num is None else num) and monotonic() - start < self.timeout:
            pass
        
        while self.arduino.in_waiting > 0 and (True if num is None else len(rec) <= num) and monotonic() - start < self.timeout:
            char = self.arduino.read(1)
            
            try:
                rec.append(char.decode())
            except UnicodeDecodeError:
                rec.append(char)
            
            start = monotonic()
        
        return rec
    
    def write_char(self, char):
        self.arduino.write(f'{char}'.encode())
    
    def write_num(self, num):
        self.arduino.write(num.to_bytes(4, 'little', signed=True))
    
    def wait_for_char(self, char):
        start = monotonic()
        
        while monotonic() - start < self.timeout and self.arduino.in_waiting == 0:
            pass
        
        if self.arduino.in_waiting > 0:
            rec = self.arduino.read(1).decode()
            
            return rec == char, rec
        
        return False, None
    
    def stop(self):
        self.arduino.close()
        
        raise SystemExit() # equivalent to sys.exit()

class MirrorInterface:
    '''
    Class which has methods for whole-mirror controls
    '''
    
    def __init__(self, mm_instance, axis):
        self.mm_instance = mm_instance
        self.axis = axis
        self.mirror = self.axis.mirror
        
        setattr(self, self.axis.axis, self.axis)
    
    def __getattr__(self, name):
        if name == 'undo':
            return self.undo
        elif name == 'redo':
            return self.redo
        elif name == 'status':
            return self.status
        else:
            raise AttributeError(f'Method {name}() doesn\'t exist.')
    
    '''
    Undo a move - 
      - Start by sending `U` until `1` is received
      - Send which mirror you're controlling ('A' or 'B'). If `3` is received then that mirror doesn't exist
      - If `3` is returned the undo failed, if `2` is returned it succeeded
    '''
    def undo(self):
        self.mm_instance.write_char('U')
        res, _ = self.axis.wait_for_char('1')
        if not res:
            if self.mm_instance.sleeping:
                u = f'Failed to undo move for axis {self.axis.axis} on mirror {self.mirror} while confirming communication (probably sleeping).'
                print(u)
                return u
            else:
                raise Exception(f'Failed to undo move for axis {self.axis.axis} on mirror {self.mirror} while confirming communication.')
        
        self.mm_instance.write_char(self.mirror)
        res, got = self.axis.wait_for_char('2')
        if got == '3':
            print(f'Got {got} from arduino.')
            raise Exception(f'Axis {self.axis.axis} or mirror {self.mirror} doesn\'t exist while undoing')
        
        if got != '2' or not res:
            print(f'Got {got} from arduino.')
            raise Exception(f'Failed to send mirror assignment to axis {self.axis.axis} on mirror {self.mirror}.')
    
    '''
    Redo an undone move - 
      - Start by sending `T` (R and Z are taken) until `1` is received
      - Send which mirror you're controlling ('A' or 'B'). If `3` is received then that mirror doesn't exist
      - If `3` is returned the redo failed, if `2` is returned it succeeded
    '''
    def redo(self):
        self.mm_instance.write_char('T')
        res, _ = self.axis.wait_for_char('1')
        if not res:
            if self.mm_instance.sleeping:
                u = f'Failed to redo move for axis {self.axis.axis} on mirror {self.mirror} while confirming communication (probably sleeping).'
                print(u)
                return u
            else:
                raise Exception(f'Failed to redo move for axis {self.axis.axis} on mirror {self.mirror} while confirming communication.')
        
        self.mm_instance.write_char(self.mirror)
        res, got = self.axis.wait_for_char('2')
        if got == '3':
            print(f'Got {got} from arduino.')
            raise Exception(f'Axis {self.axis.axis} or mirror {self.mirror} doesn\'t exist while redoing')
        
        if got != '2' or not res:
            print(f'Got {got} from arduino.')
            raise Exception(f'Failed to send mirror assignment to axis {self.axis.axis} on mirror {self.mirror}.')

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
        if not res:
           raise Exception(f'Failed to register axis {self.axis} while confirming connection.')
        
        self.mm_instance.write_char(self.mirror)
        self.mm_instance.write_char(self.axis)
        self.mm_instance.write_char('r')
        
        res, got = self.wait_for_char('2')
        if got != '2':
            print(f'Got {got} from arduino.')
            raise Exception(f'Axis {self.axis} has already been taken (on the arduino).')
        
        if not res:
            raise Exception(f'Failed to register axis {self.axis} while transmitting axis.')
    
    '''
    Command an axis to move - 
      - Start by sending `C`, waiting until `1` received
      - Send which mirror you're controlling (`A` or `B`) followed by which axis (`x`, `y`, `z`, or `a`)
      - Send which direction you want to go (`f` or `b`), wait until `1` received. If `3` is received then that mirror doesn't exist
      - Send number of steps (required to be 4 bytes) until `2` is received
    '''
    def move(self, direction, steps):
        if direction not in ['f', 'b']:
            raise ValueError(f'Direction must be "f" or "b", not {direction}.')
        
        self.mm_instance.write_char('C')
        res, _ = self.wait_for_char('1')
        if not res:
            raise Exception(f'Failed to move axis {self.axis} while confirming connection.')
        
        self.mm_instance.write_char(self.mirror)
        self.mm_instance.write_char(self.axis)
        self.mm_instance.write_char(direction)
        res, got = self.wait_for_char('1')
        if got != '1':
            print(f'Got {got} from arduino.')
            raise Exception(f'Axis {self.axis} on mirror {self.mirror} doesn\'t exist.')
        
        if not res:
            raise Exception(f'Failed to move axis {self.axis} on mirror {self.mirror} while confirming assignment.')
        
        self.mm_instance.write_num(steps)
        res, got = self.wait_for_char('2')
        if got != '2' or not res:
            print(f'Got {got} from arduino.')
            raise Exception(f'Failed to send {steps} steps to axis {self.axis} on mirror {self.mirror}.')
    
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

