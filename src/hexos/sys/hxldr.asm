format binary

nl equ 0dh, 0ah

macro dictfs_load path, dest {
    local ..toload
    local ..finish
    mov ax, ..toload
    mov word [_file_to_load], ax
    mov ax, dest
    mov word [_dskbuf_dest], ax
    call _load_file_dictfs
    jmp ..finish
..toload db path, 0h
..finish:
}

include "boot.inc"

use16
org 2000h


;; start entry
start:
    ; save boot device
    mov byte [BOOTDEV], dl

    ; clear console
    mov ax, 3h
    int 10h

    ; hide cursor
    mov ax, 100h
    mov cx, 2607h
    ;int 10h

    print "HXLDR started", nl

    dictfs_load "/sys/hexos.hxe", 9000h

    jc failure

    print "Loaded successfully", nl

    jmp $

failure:

    print "Not loaded successfully", nl

    jmp $


;; screen filler
;fill_screen:
;    mov ecx, 0ffffh
;    push word 0a000h
;    pop es
;    xor di, di
;    rep stosb
;    mov ecx, 6f31h
;    push word 0afffh
;    pop es
;    mov di, 0fh
;    rep stosb
;    ret



_load_file_dictfs:
    printnep "N "
    printaznp word [_file_to_load]
    printaznsp NL
    ; load volume data
    load 1 sector from sector 2 device [BOOTDEV] to [dskbuf]
    jc ._errio
    print "SLA", nl ; FSINFO LOAD SUCCESS
    mov si, word [dskbuf]

._read_entry:
    printnep "ZT", nl ; ANALYZING ENTRY
    ; entry is a file?
    printnp "TO "
    putcnp [si]
    printaznsp NL
    cmp byte [si], 80h
    jne ._find_next_entry

    print "IF", nl

    ; yes, it is a file, let's check if it is what we want
    add si, 0dh
    printaznep
    printaznsp NL
    mov di, word [_file_to_load]
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
    load [si+9h] sectors from sector [si+1] device [BOOTDEV] to [_dskbuf_dest]
    jc ._badfs
    mov dl, byte [BOOTDEV]
    clc
    ret

._find_next_entry:
    print "IENF", nl
    ; this isn't our file, let's scan
    ; fsinfo for next file entry
    add si, 0bh
    mov ax, word [si]
    add si, ax
    add si, 2
    cmp byte [si], 0h
    ; it was last entry in fsinfo?
    ; oops, file doesn't exist!
    je ._missing
    jmp ._read_entry

._errio:
    print "E1", nl
    stc
    ret

._badfs:
    print "E2", nl
    stc
    ret

._missing:
    print "E3", nl
    stc
    ret

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

NL db 0dh, 0ah, 0h
BOOTDEV db ?
dskbuf dw 100h
_dskbuf_dest dw 5000h
_file_to_load dw ?

dap dap_t
