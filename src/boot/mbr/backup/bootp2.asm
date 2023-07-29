format binary as "bin"


cr equ 0x0D
lf equ 0x0A
nu equ 0x00
nl equ cr, lf

macro putc c {
    mov ah, 0Eh
    if ~c eq al
    mov al, c
    end if
    int 0x10
}

macro print tosi {
    pusha
    mov si, tosi
    call _print
    popa
}

org 7e00h

print a_HelloWorld

mov al, 0
mov di, 7c00h
mov cx, 446
rep stosb


        mov si, 7dbeh                     ;partition table
        ;jmp $
        mov bl,4                        ;number of table entries
next:
        push ax
        mov al, '5'
        sub al, bl
        mov byte [pnum], al
        print a_LookingForEntryNum
        pop ax
        mov al, byte [si]
        call _print_hex_byte
        cmp byte [si],80h  ;is this a bootable entry?
        je boot         ;yes
        print a_NotBootable
        cmp byte [si],0    ;no, is boot indicator zero?
        jne bad         ;no, it must be x"00" or x"80" to be valid
        add si,16       ;yes, go to next entry
        dec bl
        jnz next
        print a_NotOneBootable
        jmp $                           ; TODO: Remove this line
        int 18h         ;no bootable entries - go to rom basic
boot:
        print a_Bootable
        mov dx,[si]     ;head and drive to boot from
        mov cx,[si+2]   ;cyl, sector to boot from
        mov bp,si       ;save table entry address to pass to partition boot record
next1:
        add si,16       ;next table entry
        dec bl          ;# entries left
        jz tabok        ;all entries look ok
        cmp byte [si],0    ;all remaining entries should begin with zero
        je next1        ;this one is ok
bad:
        mov si, a_InvalidPartitions ;oops - found a non-zero entry - the table is bad
msg:
        lodsb           ;get a message character
        cmp al,0
        je  hold
        push si
        mov bx,7
        mov ah,14
        int 10h         ;and display it
        pop si
        jmp msg         ;do the entire message
;
hold:   jmp hold        ;spin here - nothing more to do
tabok:
        mov di,5        ;retry count
rdboot:
        push word 0
        pop es
        mov bx,7c00h    ;where to read system boot record
        mov ax,0201h    ;read 1 sector
        push di
        int 13h         ;get the boot record
        pop di
        jnc goboot      ;successful - now give it control
        xor ax,ax       ;had an error, so
        int 13h         ;recalibrate
        dec di          ;reduce retry count
        jnz rdboot      ;if retry count above zero, go retry
        mov si, a_ErrorLoadingOS ;all retries done - permanent error - point to message,
        jmp msg          ;go display message and loop
goboot:
        mov si,a_MissingOS ;prepare for invalid boot record
        mov di,07dfeh
        cmp word [di],0aa55h ;does the boot record have the
                                   ;    required signature?
        jne msg         ;no, display invalid system boot record message
        mov si,bp       ;yes, pass partition table entry address
        jmp 0:7c00h

_print:
        mov ah, 14
._cycle:
        lodsb
        test al, al
        jz ._end
        int 0x10
        jmp ._cycle
._end:
        ret

_print_hex_digit:
    cmp al, 10
    jl .less
    add al, 'A'-10
    jmp .putchar
.less:
    add al, '0'
.putchar:
    mov ah, 0eh
    int 0x10
    ret

_print_hex_byte:
    push ax
    shr al, 4
    call _print_hex_digit
    pop ax
    call _print_hex_digit
    putc "h"
    putc " "
    ret

a_InvalidPartitions db    "Invalid partition table",nu
a_ErrorLoadingOS db    "Error loading operating system",nu
a_MissingOS db    "Missing operating system",nu

a_HelloWorld db "Hello from HexOS community!", nl, nu
a_LookingForEntryNum db "Looking for partition "
pnum: db '0', nl, nu
a_NotBootable db "Not a bootable", nl, nu
a_Bootable db "Is bootable", nl, nu
a_NotOneBootable db "There isn't any bootable partitions", nl, nu
a_error db "Error while booting", 0

times 510-$+$$ db 0x00


signa   db 55h,0aah     ;signature
