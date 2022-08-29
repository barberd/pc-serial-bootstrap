#!/usr/bin/env python3

'''
Senddisk.py. A program for sending bootstrap code to an IBM PC and then a disk image that is written to the floppy drive.

Copyright 2022 Don Barber

     This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

'''


import serial
import sys
import struct
import time
import os

TRACKS=40
SECTRK=9
SECLEN=512

bytedelay=.05
bytedelay=0

readbyte=True

if __name__ == '__main__':  # noqa
    import argparse

    parser = argparse.ArgumentParser(
        description='Send disk over serial for writing on IBM PC')

    parser.add_argument(
        'SERIALPORT',
        help="serial port name")

    parser.add_argument(
        'BAUDRATE',
        type=int,
        nargs='?',
        help='set baud rate, default: %(default)s',
        default=19200)

    parser.add_argument(
        'DSKIMAGE',
        nargs='?',
        help='disk image file, default: %(default)s',
        default='disk.img')

    parser.add_argument(
        '-q', '--quiet',
        action='store_true',
        help='suppress non error messages',
        default=False)

    parser.add_argument(
        '-l', '--localecho',
        action='store_true',
        help='Enable Local Echo',
        default=False)

    group = parser.add_argument_group('serial port')

    group.add_argument(
        "--bytesize",
        choices=[5, 6, 7, 8],
        type=int,
        help="set bytesize, one of {5 6 7 8}, default: 8",
        default=8)

    group.add_argument(
        "--parity",
        choices=['N', 'E', 'O', 'S', 'M'],
        type=lambda c: c.upper(),
        help="set parity, one of {N E O S M}, default: N",
        default='N')

    group.add_argument(
        "--stopbits",
        choices=[1, 1.5, 2],
        type=float,
        help="set stopbits, one of {1 1.5 2}, default: 1",
        default=1)

    group.add_argument(
        '--rtscts',
        action='store_true',
        help='enable RTS/CTS flow control (default off)',
        default=True)

    group.add_argument(
        '--xonxoff',
        action='store_true',
        help='enable software flow control (default off)',
        default=False)

    group.add_argument(
        '--rts',
        type=int,
        help='set initial RTS line state (possible values: 0, 1)',
        default=None)

    group.add_argument(
        '--dtr',
        type=int,
        help='set initial DTR line state (possible values: 0, 1)',
        default=None)

    group = parser.add_argument_group('network settings')

    exclusive_group = group.add_mutually_exclusive_group()

    args = parser.parse_args()

    ser = serial.serial_for_url(args.SERIALPORT, do_not_open=True)
    ser.baudrate = args.BAUDRATE
    ser.bytesize = args.bytesize
    ser.parity = args.parity
    ser.stopbits = args.stopbits
    ser.rtscts = args.rtscts
    ser.xonxoff = args.xonxoff

    ser.dsrdtr = True

    if args.rts is not None:
        ser.rts = args.rts

    if args.dtr is not None:
        ser.dtr = args.dtr

    if not args.quiet:
        sys.stderr.write(
            '--- send disk for writing on {p.name}  {p.baudrate},{p.bytesize},{p.parity},{p.stopbits} ---\n'
            '--- \n'.format(p=ser))


    try:
        ser.open()
    except serial.SerialException as e:
        sys.stderr.write('Could not open serial port {}: {}\n'.format(ser.name, e))
        sys.exit()


    buf=open("lwdisk.bin","rb").read()
    buf=buf+bytes((255-len(buf))*[0])
    cl=buf[::-1]
    print(len(buf))

    ser.write(cl)

    #sys.exit()
    #time.sleep(3)

    fh=open(args.DSKIMAGE,"rb")

    #If you get an error and need to restart somewhere, just update
    #these variables. This program will autoseek to the correct location in
    #the image file.

    track=0
    sector=1
    head=0

    fh.seek(head*512*9*40+track*9*512+(sector-1)*512)
    while True:
        buf=fh.read(512)
        if len(buf)==0:
            break
        print(head)
        ser.write(head.to_bytes(1,'big'))
        if readbyte:
            ser.read(1)
        time.sleep(bytedelay)
        print(track)
        ser.write(track.to_bytes(1,'big'))
        if readbyte:
            ser.read(1)
        time.sleep(bytedelay)
        print(sector)
        ser.write(sector.to_bytes(1,'big'))
        if readbyte:
            ser.read(1)
        time.sleep(bytedelay)
        print("Writing bytes.")
        if len(buf)<512:
            buf=buf+bytes((512-len(buf))*[0])
            for b in buf:
                ser.write(b.to_bytes(1,'big'))
                if readbyte:
                    ser.read(1)
                print(b)
                time.sleep(bytedelay)
            #ser.write(buf)
            break
        else:
            for b in buf:
                ser.write(b.to_bytes(1,'big'))
                if readbyte:
                    ser.read(1)
                print(b)
                time.sleep(bytedelay)
        print("Done with sector.")
        time.sleep(3)
        sector+=1
        if sector>SECTRK:
            track+=1
            sector=1
        if track>=TRACKS:
            head+=1
            track=0
    print("Exiting.")
    fh.close()
