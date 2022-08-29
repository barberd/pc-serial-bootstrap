; This code is a serial bootloader that first outputs 'B" (for Boot)
; initializes the COM port and loads 256 bytes into memory in reverse,
; and then jumps to that location.
; Use this to bootstrap a program that is read in from the serial port.

;Copyright 2022 Don Barber

;     This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

;    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

;    You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.


org 0x7C00

	mov ah,0x0E
	mov al,0x42 		; 'B'
	int 0x10		; output char

	xor ax,ax   ; initialize data segment to 0 (same as code segment)
	mov ds,ax

; init UART here
	mov dx,0x2f9		; COM2
	;mov dx,0x3f9		; COM1
	out dx,al		; turn off all UART interrupts
	mov al,0x80
	add dx,2
	out dx,al		; turn on DLAB
	mov al,0x0c
	sub dx,3
	out dx,al		; set low byte divisor to 0xc (9600)
	xor al,al
	inc dx
	out dx,al		; set high byte divisor to 0
	mov al,0x03		
	add dx,2
	out dx,al		; disable DLAB and set 8N1
	mov ah,0x03
	inc dx
	out dx,al		; turn on DTR and RTS

	mov bx,0x7eff
    	inc dx

rdloop:
	in al,dx
	and al,0x1
	jz rdloop
	sub dx,5
	in al,dx
	add dx,5
	mov [bx],al
	dec bl
	jnz rdloop	
	jmp 0x7E00

; Use BASIC to poke the 0xAA55 into the correct spot in memory
; But uncomment this if you're testing something in an emulator
; and need to create a full boot record
;	times 512-($-$$)-2 db 0
;	dw 0AA55h

