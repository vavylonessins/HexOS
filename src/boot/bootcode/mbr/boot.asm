format binary as "bin"

relocated_org   equ 0600h
buildtime_org   equ 0100h
org_delta       equ (relocated_org - buildtime_org)

start:

        cli             ;no interrupts for now
        xor ax,ax
        mov ss,ax
        mov sp,7c00h    ;new stack at 0:7c00
        mov si,sp       ;where this boot record starts - 0:7c00
        push ax
        pop es          ;seg regs the same
        push ax
        pop ds
        sti             ;interrupts ok now
        cld
        mov di,relocated_org ;where to relocate this boot record to
        mov cx,100h
        rep movsw       ;relocate to 0:0600
;       jmp entry2 + org_delta
        db   0eah
        dw   $+4+org_delta,0
entry2:
        mov si,tab + org_delta  ;partition table
        mov bl,4        ;number of table entries
next:
        cmp byte [si],80h  ;is this a bootable entry?
        je boot         ;yes
        cmp byte [si],0    ;no, is boot indicator zero?
        jne bad         ;no, it must be x"00" or x"80" to be valid
        add si,16       ;yes, go to next entry
        dec bl
        jnz next
        int 18h         ;no bootable entries - go to rom basic
boot:
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
        mov si,m1 + org_delta ;oops - found a non-zero entry - the table is bad
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
        mov si,m2 + org_delta ;all retries done - permanent error - point to message,
        jmp msg          ;go display message and loop
goboot:
        mov si,m3 + org_delta ;prepare for invalid boot record
        mov di,07dfeh
        cmp word [di],0aa55h ;does the boot record have the
                                   ;    required signature?
        jne msg         ;no, display invalid system boot record message
        mov si,bp       ;yes, pass partition table entry address
        db 0eah
        dw 7c00h,0

m1: db    "Invalid partition table",0
m2: db    "Error loading operating system",0
m3: db    "Missing operating system",0
times 1beh-$+$$ db 0x00

tab:                    ;partition table
        db 80h
        db 3
        db 49
        db 0
        db 0bh
        db 0ffh
        db 0fh
        db 3fh
        dd 03fh
        dd 1024*1024*100/512

        dw 0,0          ;partition 2 begin
        dw 0,0          ;partition 2 end
        dw 0,0          ;partition 2 relative sector
        dw 0,0          ;partition 2 # of sectors
        dw 0,0          ;partition 3 begin
        dw 0,0          ;partition 3 end
        dw 0,0          ;partition 3 relative sector
        dw 0,0          ;partition 3 # of sectors
        dw 0,0          ;partition 4 begin
        dw 0,0          ;partition 4 end
        dw 0,0          ;partition 4 relative sector
        dw 0,0          ;partition 4 # of sectors


signa   db 55h,0aah     ;signature
