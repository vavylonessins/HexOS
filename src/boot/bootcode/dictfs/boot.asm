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
    mov ah, 2h
    mov al, 1
    mov bx, word [dskbuf]
    mov dh, 0
    mov dl, byte [BOOTDEV]
    mov ch, 0
    mov cl, 3
    push word 0
    pop es
    int 13h
    jc errio
    mov si, word [dskbuf]

read_entry:
    cmp byte [si], 80h
    jne find_next_entry

cmp_path:
    add si, 0ah
    mov di, loader_path
    call cmpaz
    jne find_next_entry
    sub si, 0ah

load_file:
    mov word [dskbuf], 2000h
    mov ah, 2h
    mov al, byte [si+9h]
    mov bx, 2000h
    mov cl, byte [si+1h]
    mov ch, byte [si+2h]
    mov dh, byte [si+3h]
    mov dl, byte [BOOTDEV]
    push word 0
    pop es
    int 13h
    jc badfs
    mov dl, [BOOTDEV]
    jmp 0h:2000h

find_next_entry:
    add si, 0ah
    call endaz
    inc si
    cmp byte [si], 0h
    je missingloader
    jmp read_entry

errio:
    print "IO error", nl
    jmp $

badfs:
    print "FS error", nl
    jmp $

missingloader:
    print "/sys/hxldr.bin is missing", nl
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

_lenaz:
    lodsb
    test al, al
    jz ._e
    inc cx
    jmp _lenaz
._e:
    ret

endaz:
    lodsb
    test al, al
    jz ._e
    jmp _lenaz
._e:
    inc si
    ret

; ASSUME: SI - asciiz 1, DI - asciiz 2
cmpaz:
    repnz cmpsb
    ret

BOOTDEV db ?
spt db 12h
hpc db 2
dskbuf dw 100h
loader_path db "/sys/hxldr.bin", 0

times 1feh-$+$$ db 0x00
dw 0aa55h
