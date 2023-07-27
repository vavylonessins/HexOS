format binary as "bin"
use16
org 7c00h
nl equ 0dh, 0ah
macro print string& {
    local ..toprint
    local ..finish
    pusha
    mov si, ..toprint
    call _printaz
    jmp ..finish
..toprint db string, 0
..finish:
    popa
}


start:
    push word 0 word 0
    pop ds es
    mov byte [BOOTDEV], dl

    call _load_file_dictfs
    jmp $

_load_file_dictfs:
    print "Required: "
    mov si, word [_file_to_load]
    call _printaz
    print nl
    ; load volume data
    mov ah, 2h
    mov al, 1h
    mov bx, word [dskbuf]
    mov dh, 0h
    mov dl, byte [BOOTDEV]
    mov ch, 0h
    mov cl, 3h
    push word 0h
    pop es
    int 13h
    print "FSINFO loaded to RAM", nl
    jc ._errio
    mov si, bx

._read_entry:
    pusha
    print "Analyzing entry...", nl
    popa
    ; entry is a file?
    cmp byte [si], 80h
    jne ._find_next_entry

    pusha
    print "It is a file", nl
    popa

    ; yes, it is a file, let's check if it is what we want
    add si, 0ah
    pusha
    call _printaz
    print nl
    popa
    mov di, word [_file_to_load]
    call cmpaz
    jnz ._find_next_entry
    sub si, 0ah

    pusha
    print "It is required file", nl
    popa

    ; it is our file, let's load it
    mov ah, 2h
    mov al, byte [si+9h]
    mov bx, word [_dskbuf_dest]
    mov cl, byte [si+1h]
    mov ch, byte [si+2h]
    mov dh, byte [si+3h]
    mov dl, byte [BOOTDEV]
    push word 0h
    pop es
    int 13h
    jc ._badfs
    mov dl, [BOOTDEV]
    clc
    ret

._find_next_entry:
    pusha
    print "It isn't required file", nl
    ; this isn't our file, let's scan
    ; fsinfo for next file entry
    add si, 0ah
    call endaz
    inc si
    cmp byte [si], 0h
    ; it was last entry in fsinfo?
    ; oops, file doesn't exist!
    je ._missing
    jmp ._read_entry

._errio:
    print "IO error", nl
    stc
    ret

._badfs:
    print "FS error", nl
    stc
    ret

._missing:
    print "file is missing", nl
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

endaz:
    lodsb
    test al, al
    jz ._e
    jmp lenaz
._e:
    inc si
    ret

cmpaz:
    xor cx, cx
    push si
    call lenaz
    pop si
    repz cmpsb
    ret

BOOTDEV db ?
dskbuf dw 100h
_dskbuf_dest dw 2000h
_file_to_load dw loader_path

loader_path db "/sys/hxldr.bin", 0

times 1feh-$+$$ db 0x00
dw 0aa55h
