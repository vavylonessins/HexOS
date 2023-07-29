format binary as "bin"


org 7c00h

;mov si, tab
;jmp $

mov ax, 201h
mov bx, 7e00h
mov cx, 2
mov dh, 0
push word 0
pop es
int 0x13
jc @f
jmp 0:7e00h
@@:
mov ah, 0x0E
mov si, a_error
c:
lodsb
test al, al
jz e
int 0x10
jmp c
e:
jmp $

a_error db "Error loading VBR", 0

times 446-$+$$ db 0x00

tab:                    ;partition table
        db 80h
        db 0
        db 7
        db 0
        db 0
        db 0
        db 0
        db 0
        dd 0
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
