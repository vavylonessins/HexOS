nl equ 0dh, 0ah
sector fix
sectors fix
to fix ,
from fix ,
device fix ,
macro print string& {
    local ..toprint
    local ..finish
    push si ax
    mov si, ..toprint
    call _printaz
    jmp ..finish
..toprint db string, 0
..finish:
    pop ax si
}
macro printnp string& {
    local ..toprint
    local ..finish
    mov si, ..toprint
    call _printaz
    jmp ..finish
..toprint db string, 0
..finish:
}
macro printnsp string& {
    local ..toprint
    local ..finish
    mov si, ..toprint
    call _printaz
    jmp ..finish
..toprint db string, 0
..finish:
    pop ax si
}
macro printnep string& {
    local ..toprint
    local ..finish
    push si ax
    mov si, ..toprint
    call _printaz
    jmp ..finish
..toprint db string, 0
..finish:
}
macro printaz string {
    push si ax
    if ~string eq
        mov si, string
    end if
    call _printaz
    pop ax si
}
macro printaznep string {
    push si ax
    if ~string eq
        mov si, string
    end if
    call _printaz
}

macro printaznp string {
    if ~string eq
        mov si, string
    end if
    call _printaz
}
macro printaznsp string {
    if ~string eq
        mov si, string
    end if
    call _printaz
    pop ax si
}
macro putc char {
    push ax
    mov al, char
    mov ah, 0eh
    int 10h
    pop ax
}
macro load count, lba, dev, buff {
    push si ax
    push word count
    pop word [dap.number_of_sectors]
    push dword lba
    pop dword [dap.lba_low]
    ;mov dl, dev
    mov si, dap
    mov ah, 0x42
    int 13h
    pop ax si
}
struc xd d_or_l, h: {
    .low equ $
    .high equ $+2
    if h eq
        dd d_or_l
    else
        dw d_or_l
        dw h
    end if
}
struc xw w_or_l, h: {
    .low equ $
    .high equ $+1
    if h eq
        dw w_or_l
    else
        db w_or_l
        db h
    end if
}
struc dap_t {
    .size db 10h
    .zero db 0h
    .number_of_sectors xw -1
    .offset dw 2000h
    .segment dw 0h
    .lba_low dd -1
    .lba_high dw 0h
    .dzero dw 0
}