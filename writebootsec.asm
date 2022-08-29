; This code snippet will write the 512 bytes located at 0x1200 out to
; the first sector of the first floppy drive, then return to IBM PC Cassette
; BASIC. Conceptually, if those 512 bytes contain a valid bootrecord, this
; creates a boot floppy

;Copyright 2022 Don Barber

;     This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

;    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

;    You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.


BITS 16

org 0x1100

	push es
	push bp
	mov bp,sp
	xor dx,dx
	mov es,dx
	;mov bx,07c00h
	mov bx,01200h
	mov ax,0301h
	mov cx,0001h
	int 13h
	mov di,[bp+8]
	mov [di],ax
	pop bp
	pop es
	retf 2
