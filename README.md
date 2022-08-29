# pc-serial-bootstrap

Code to bootstrap a PC over serial starting with IBM Cassette BASIC. I used this to write operating system and communications software floppy images to physical diskette on an IBM PC 5150 when I had no software to get started but did have a serial connection and blank floppy disks.

### Use

Just type the loader.bas into IBM Cassette BASIC, put a blank floppy in drive 0, then enter 'run'. This will write the bootloader to the floppy's boot sector. Then reboot to run this bootloader. By default, this bootloader is configured for COM2, 9600 Baud, 8-N-1.

Next you'll need to assemble lwdisk.asm to lwdisk.bin; this is the second stage loader. On Linux:

     nasm -f bin lwdisk.asm -o lwdisk.bin

Send the disk writing code to the bootloader from another workstation connected via serial by:

    ./senddisk.py /dev/ttyS0 9600 Disk01.img

Substitute your serial port and disk image appropriately.

### Modifications

Modify serialboot.asm and writebootsec.asm as needed (perhaps modifying the COM port) and assemble to bin format. Then modify the bytes in the loader.bas program's DATA statements to match. If you change the size of the code you may need to modify lines 30 and 110 to match as well. For example, to reassemble serialboot.asm:

     nasm -f bin serialboot.asm -o serialboot.bin

To make it easy to create the DATA statements, convert the .bin files to decimal bytes using a tool such as od:

     od -t u1 filename.bin


