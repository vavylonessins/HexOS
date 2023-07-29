format binary as "bin"
use16
org 7c00h

include "boot.inc"

; log alphabet:
; I - it
; N - needed
; F - file
; E - error, not
; S - FSINFO
; L - load
; A - success
; T - entry
; Z - analyzing
; O - type

; entry types:
; C,- type::file
; E`- type::folder

; errors:
; 1 - disk r/w error
; 2 - corrupted FS
; 3 - file doesn't exist

start:
    mov byte [BOOTDEV], dl

load_fsinfo:
    printnep "N "
    printaznp loader_path
    printaznsp NL
    ; load volume data
    load 1 sector from sector 2 device [BOOTDEV] to 2000h
    jc ._errio
    print "SLA", nl ; FSINFO LOAD SUCCESS
    mov si, 2000h

._read_entry:
    print "ZT", nl ; ANALYZING ENTRY
    ; entry is a file?
    print "TO "
    putc [si]
    printaz NL
    call key_wait
    cmp byte [si], 80h
    jne ._find_next_entry

    print "IF", nl

    ; yes, it is a file, let's check if it is what we want
    add si, 0dh
    printaznep
    printaznsp NL
    mov di, loader_path
    xor cx, cx
    push si
    call lenaz
    pop si
    repz cmpsb
    jnz ._find_next_entry
    sub si, 0dh

    print "INF", nl

    ; it is our file, let's load it
    sub si, 0eh
    load [si+9h] sectors from sector [si+1] device [BOOTDEV] to 2000h
    jc ._badfs
    mov dl, byte [BOOTDEV]
    jmp 0h:2000h

._find_next_entry:
    print "IENF", nl
    ; this isn't our file, let's scan
    ; fsinfo for next file entry
    add si, 0bh
    mov ax, word [si]
    add si, ax
    add si, 2h
    cmp byte [si], 0h
    ; it was last entry in fsinfo?
    ; oops, file doesn't exist!
    je ._missing
    jmp ._read_entry

._errio:
    print "E1", nl
    jmp $

._badfs:
    print "E2", nl
    mov di, dap
    jmp $

._missing:
    print "E3", nl
    jmp $


_printaz:
    mov ah, 0eh
._c:
    lodsb
    test al, al
    jz ._e
    int 10h
    jmp ._c
._e:
    ret

lenaz:
    lodsb
    test al, al
    jz ._e
    inc cx
    jmp lenaz
._e:
    ret

key_wait:
	in al, 64h
	and al, 1
	jz key_wait
 
	;in al, 60h
    ret

BOOTDEV db ?

dap dap_t

NL db 0dh, 0ah, 0h

loader_path db "/sys/hxldr.bin", 0

times 1feh-$+$$ db 0x00
dw 0aa55h
