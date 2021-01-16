#! /usr/bin/env python3
import click
import serial
from enum import Enum, auto
from intelhex import IntelHex,IntelHexError
import constants

@click.command()
@click.argument(
    'file',
    required=True,
    type=click.Path(dir_okay=False, writable=True)
)
@click.option(
    '--append', '-a',
    help='append data to hex file',
    is_flag=True
)
@click.option(
    '--port', '-p',
    required=True,
    help='serial port where ELF is connected'
)
@click.option(
    '--baud', '-b',
    help='serial baud rate',
    type=int,
    default=9600
)
def main(file, append, port, baud):
    """
    Receive a code file from an attached ELF with MAX binary sender.

    The program reads a MAX-format binary file from the specified
    serial port and stores in the given file.
    """
    class State(Enum):
        DATA = auto()
        ESCAPE = auto()
        ADDR_HI = auto()
        ADDR_LO = auto()
        DONE = auto()

    state = State.DATA
    address = 0

    intel_hex = IntelHex()

    if append:
        intel_hex.loadhex(file)

    with serial.serial_for_url(port) as ser:
        ser.baudrate = baud
        ser.write(constants.START_RECV)
        while state != State.DONE:
            data = ser.read(ser.in_waiting)
            for byte in data:
                if state == State.DATA:
                    if byte == constants.ESCAPE:
                        state = State.ESCAPE
                    elif byte == constants.END_OF_FILE:
                        state = State.DONE
                    elif byte == constants.NEW_ADDRESS:
                        state = State.ADDR_HI
                    else:
                        intel_hex[address] = byte
                        address += 1
                elif state == State.ESCAPE:
                    intel_hex[address] = byte ^ 0x20
                    address += 1
                    state = State.DATA
                elif state == State.ADDR_HI:
                    address = byte << 8
                    state = State.ADDR_LO
                elif state == State.ADDR_LO:
                    address |= byte
                    state = State.DATA

    intel_hex.write_hex_file(file)

if __name__ == "__main__":
    main() # pylint: disable=no-value-for-parameter