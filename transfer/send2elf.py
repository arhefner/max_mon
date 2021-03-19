#! /usr/bin/env python3
"""Send a code file to an ELF computer using MAX binary loader."""
import time
import click
import serial
from intelhex import IntelHex,IntelHexError
import constants

def cb_validate_address(ctx, param, value):
    """Validate hex address parameter."""
    try:
        if value is not None:
            address = int(value, 16)
            if address not in range(0, 0x10000):
                raise click.BadParameter(
                    'address must be between 0x0000 and 0xFFFF')
            return address
    except ValueError as address_error:
        raise click.BadParameter(
            'address must be hex value') from address_error

def send_byte(ser, data, delay, escape):
    """Send byte to loader."""
    if escape and constants.SPECIAL_CHARS.find(data) != -1:
        ser.write(bytes([constants.ESCAPE]))
        time.sleep(delay)
        escaped = data ^ 0x20
        ser.write(bytes([escaped]))
        time.sleep(delay)
    else:
        ser.write(bytes([data]))
        time.sleep(delay)

def send_segments(intel_hex, ser, delay, compact):
    """Send segments from Intel hex file to loader."""
    segments = intel_hex.segments()
    i = 1
    for segment in segments:
        send_byte(ser, constants.NEW_ADDRESS, delay, False)
        for data in segment[0].to_bytes(2, byteorder='big'):
            send_byte(ser, data, delay, True)

        with click.progressbar(
            range(*segment),
            label=None if compact else f'[{segment[0]:04X}:{segment[1]:04X}]',
#            show_eta=not compact,
            width=20 if compact else 0
        ) as progress:
            for addr in progress:
                send_byte(ser, intel_hex[addr], delay, True)
        i += 1

def run_program(ser, entry, delay):
    """Send command to run loaded program."""
    send_byte(ser, constants.RUN_ADDRESS, delay, False)
    for data in entry.to_bytes(2, byteorder='big'):
        send_byte(ser, data, delay, True)

def end_transfer(ser):
    """Send end of transfer flag."""
    ser.write(bytes([constants.END_OF_FILE]))

@click.command()
@click.argument(
    'file',
    required=True,
     type=click.Path(exists=True, dir_okay=False, readable=True)
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
@click.option(
    '--start', '-s',
    help='start address for binary file',
    callback=cb_validate_address,
    default='0'
)
@click.option(
    '--delay', '-d',
    help='delay in ms between bytes sent',
    type=float,
    default=1.5
)
@click.option(
    '--run', '-r',
    help='auto-run program after loading',
    is_flag=True,
    default=False
)
@click.option(
    '--entry', '-e',
    help='program entry point for auto-run',
    callback=cb_validate_address,
    default=None
)
@click.option(
    '--compact', '-c',
    help='use compact format for progress bar',
    is_flag=True,
    default=False
)
def main(file, port, baud, start, delay, run, entry, compact):
    """
    Send a code file to an ELF computer with MAX binary loader.

    The specified file is sent to an attached ELF computer over
    the named serial port. The input file can be an Intel 8-bit
    HEX file or a binary file. For a binary file, the starting
    address may be specified by the 'start' option.
    """
    intel_hex = IntelHex()
    try:
        intel_hex.loadhex(file)
    except (IntelHexError,UnicodeDecodeError):
        intel_hex.loadbin(file, offset=start)

    delay /= 1000

    with serial.serial_for_url(port) as ser:
        ser.baudrate = baud

        send_segments(intel_hex, ser, delay, compact)

        if run:
            if entry is None:
                entry = intel_hex.segments()[0][0]
            run_program(ser, entry, delay)
        else:
            end_transfer(ser)

if __name__ == "__main__":
    main() # pylint: disable=no-value-for-parameter
