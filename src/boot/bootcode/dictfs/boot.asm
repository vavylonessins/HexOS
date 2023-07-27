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
macro printaz az {
    push ax si
    mov si, az
    call _printaz
    pop si ax
}
macro fastload c, h, s, sz, errcallb {
    pusha
    mov ah, 2h
    mov al, sz
    mov bx, word [dskbuf]
    mov dh, h
    mov dl, byte [BOOTDEV]
    mov ch, c
    mov cl, s
    push word 0
    pop es
    int 13h
    popa
    jc errcallb
}
macro shortload sz, errcallb {
    pusha
    mov ah, 2h
    mov al, sz
    mov bx, word [dskbuf]
    mov dl, byte [BOOTDEV]
    push word 0
    pop es
    int 13h
    popa
    jc errcallb
}
macro lba2chs lba {
    mov eax, lba
    call _lba_to_chs
}
macro cmpaz a, b {
    mov si, a
    mov di, b
    call _cmpaz
}
macro endaz az {
    mov si, az
    call _endaz
}


start:
    print "FS reading", nl
    mov byte [BOOTDEV], dl
    fastload 0h, 0h, 3h, 1h, errio
    mov si, word [dskbuf]

read_entry:
    print "entry reading", nl
    cmp byte [si], 80h
    jne find_next_entry
    print "is file", nl

cmp_path:
    add si, 0ah
    printaz si
    print nl
    cmpaz si, loader_path
    jne find_next_entry
    print "is loader", nl
    sub si, 9h

load_file:
    lba2chs dword [si+1h]
    mov word [dskbuf], 2000h
    shortload byte [si+9h], badfs
    print "starting HXLDR", nl
    jmp $
    jmp 0h:2000h

find_next_entry:
    print "not a loader", nl
    add si, 0ah
    endaz si
    inc si
    jmp read_entry

errio:
    print "IO error", nl
    jmp $

badfs:
    print "FS error", nl
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

_endaz:
    lodsb
    test al, al
    jz ._e
    jmp _lenaz
._e:
    inc si
    ret

; deprecated
;_cmpaz:
    xor cx, cx
    call _lenaz
    mov dx, cx
    xor cx, cx
    xchg si, di
    call _lenaz
    cmp cx, dx
    ;jne ._ne
    repnz cmpsb
    ;jne ._ne
    mov al, 0h
    cmp al, al
    ret
;._ne:
    mov al, 0h
    cmp al, 1h
    ret

_cmpaz:
    xor al, al
    mov cx, -1
    repne scasb
    ret

_lba_to_chs:
	xor dx, dx
	div byte [spt]
	inc dl
	mov cl, dl
	xor dx, dx
	div byte [hpc]
	mov dh, dl
	mov ch, al
	ret

BOOTDEV db ?
spt db 12h
hpc db 2
dskbuf dw 100h
loader_path db "/sys/hxldr.bin", 0

times 1feh-$+$$ db 0x00
dw 0aa55h
