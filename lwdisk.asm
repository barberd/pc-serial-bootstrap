; This code snippet outputs the letter K, then listens for three bytes:
; head, track, and sector. It then reads 512 bytes, and then writes those
; bytes to the head, track, and sector specified. It is used to write disk
; images received over serial to floppy disk.
; It should be accompanied with senddisk.py, a python script that sends the 
; disk image data as expected.

;Copyright 2022 Don Barber

;     This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

;    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

;    You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

BITS 16

org 0x7e00

	mov ah,0
	mov al,3
	int 0x10
	mov bx,0

	mov ah,0x0E	; output K
	mov al,0x4B
	int 0x10

rdblock:
	call readbyte	; read head
	mov dh,al
	mov dl,1	; write to drive B
	;mov dl,0	; write to drive A
	push dx		; store drive and head # on stack
	mov ah,0x0E	; output head to screen
	add al,0x30
	int 0x10
	call readbyte	; read track
	mov ah,al	; move track from al to ah
	push ax		; store track on stack
	mov ah,0x0E	; output track to screen
	add al,0x30
	int 0x10
	pop ax		; restore track from stack
	call readbyte	; read sector
	push ax		; store track and sector on stack
	mov ah,0x0E	; output sector to screen
	add al,0x30
	int 0x10

	mov bx,0x8000	; read 512 bytes data starting address 0x8000
rdblockloop:
	call readbyte
	mov [bx],al
	inc bx
	cmp bx,0x8200	; if reached 512 bytes (0x200) then exit loop
	jnz rdblockloop

	;write sector here
retry:	pop cx		; read track and sector off stack
	pop dx		; read head and drive off stack
	push dx
	push cx
	mov ax,0x0301	; write data to disk B with assigned track and sector
	mov bx,0x8000
	int 0x13
	jnc writenoerror
	call error
	jmp retry
writenoerror:
	pop cx
	pop dx	
	mov ah,0x0E	; output carriage return to screen
	mov al,0x0D
	int 0x10
	mov ah,0x0E	; output line feed to screen
	mov al,0x0A
	int 0x10
	jmp short rdblock	; loop to read next block

readbyte:
	mov dx,0x2fc	; set cts and dtr high for hw flow control
	mov al,0x0B
	out dx,al
	inc dx
rdloop:	in al,dx	; check serial uart buffer for byte available
	and al,0x1
	jz rdloop	; loop if not available
	sub dx,5	; read byte from serial uart buffer
	in al,dx
	out dx,al
	mov dx,0x2fc
	push ax		; store serial byte on stack
	mov al,0x00	; set cts and dtr low for hw flow control
	out dx,al
	pop ax		; restore serial byte from stack
	ret

error:
	mov bx,ax
	mov ah,0x0E	; output carriage return to screen
	mov al,0x45
	int 0x10

	mov ah,0x0E	; output first hex char
	mov al,bh
	shr al,1
	shr al,1
	shr al,1
	shr al,1
	add al,0x30
	cmp al,0x3A
	jc firsthex
	add al,8
firsthex:
	int 0x10

	mov ah,0x0E	; output second hex char
	mov al,bh
	and al,0x0F
	add al,0x30
	cmp al,0x3A
	jc secondhex
	add al,8
secondhex:
	int 0x10

	mov ax,0x0001
	int 0x13
	
	mov ah,0x0E	; output carriage return to screen
	mov al,0x0D
	int 0x10
	mov ah,0x0E	; output line feed to screen
	mov al,0x0A
	int 0x10

	ret


