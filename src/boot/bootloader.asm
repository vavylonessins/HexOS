;                     Copyright (C) Talisman's Productions 2020 - 2027
;
;Abstract:
;
; The ROM in the IBM PC starts the boot process by performing a hardware
; initialization and a verification of all external devices.  If all goes
; well, it will then load from the boot drive the sector from track 0, head 0,
; sector 1.  This sector is placed at physical address 07C00h.
;
; The code in this sector is responsible for locating NTLDR, loading the
; first sector of NTLDR into memory at 2000:0000, and branching to it.  The
; first sector of NTLDR is special code which knows enough about FAT and
; BIOS to load the rest of NTLDR into memory.
;
; There are only two errors possible during execution of this code.
;       1 - HEXLDR does not exist
;       2 - BIOS read error
;
; In both cases, a short message is printed, and the user is prompted to
; reboot the system.
;
; At the beginning of the boot sector, there is a table which describes the
; structure of the media.  This is equivalent to the BPB with some
; additional information describing the physical layout of the driver (heads,
; tracks, sectors)
;
;Environment:
;
;    Sector has been loaded at 7C0:0000 by BIOS.
;    Real mode
;    FAT file system
;

include "struct.inc"
include "sugar.inc"

jmp boot
nop

boot:
	mov ax, 3
	int 0x10
	mov ah, 0x0E
	mov al, "X"
	int 0x10

	xor ax, ax
	int 0x13

	mov ah, 0x02
	mov al, 2
	mov bx, 0x1000
	mov cx, 2
	push word 0
	pop es
	int 0x13
	jc error
	jmp 0:0x1000

error:
	mov ah, 0x0E
	mov si, msg
cycle:
	lodsb
	test al, al
	jz finish
	int 0x10
	jmp cycle
finish:
	cli
	hlt
	jmp $-2

msg db "Error loading Boot Trampoline,", 0x0D, 0x0A, "System halted.", 0

times 510-$+$$ db 0x00
dw 0xAA55
