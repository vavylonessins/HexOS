format binary

org 0x2000

mov ah, 0x0E
mov al, "X"
int 0x10
cli
hlt
jmp 0x2000
