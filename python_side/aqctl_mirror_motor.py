#!/usr/bin/env python3
# idk if the shebang is necessary but the mini shutter server file has it so ¯\_(ツ)_/¯

from argparse import ArgumentParser
from sipyco.pc_rpc import simple_server_loop
from sipyco import common_args
from driver import MirrorMotor

def get_argparser():
    parser = ArgumentParser(
        description='ARTIQ controller for mirror motor',
    )
    
    common_args.simple_network_args(
        parser,
        3478,
    )
    
    common_args.verbosity_args(parser)
    
    parser.add_argument(
        '--serial-port',
        help='Which USB serial port the arduino is located at.',
        default='/dev/arduino1',
        type=str,
    )
    
    parser.add_argument(
        '--timeout',
        help='Timeout duration for communication.',
        default=0.1,
        type=float,
    )
    
    parser.add_argument(
        '--name',
        help='Name of the arduino/mirror motor you are addressing, for convinience.',
        default='test',
        type=str,
    )
    
    return parser

def main():
    args = get_argparser().parse_args()
    common_args.init_logger_from_args(args)
    
    dev = MirrorMotor(serial_port=args.serial_port, timeout=args.timeout)
    
    try:
        print('creating server loop')
        simple_server_loop(
            {'mirror_motor': dev},
            common_args.bind_address_from_args(args),
            args.port,
        )
    finally:
        dev.stop()
        print('device stopped')
    
    print('exiting main')

if __name__ == '__main__':
    main()

