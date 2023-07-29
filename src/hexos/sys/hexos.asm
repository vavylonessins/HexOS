format binary as "hxe"
use32
org 0h

segments = 3

SCODE = 1h
SDATA = 2h
SSTACK = 4h
SREAD = 8h
SWRITE = 10h
SEXECUTE = 20h

db 0f1h ; byte "ё", noascii, should be > 7fh
db "HXE", 0h ; magic
db 0h dup (3) ; align by 2^2
dd total_mem
argvp dd ?
pathd dd ?
dd _start
dd segments
dd SCODE OR SREAD OR SEXECUTE
dd code_start
dd code_end
dd SDATA OR SREAD OR SWRITE
dd data_start
dd data_end
dd SSTACK OR SREAD OR SWRITE
dd stack_bottom
dd stack_top

code_start:
    _start:
        mov ah, 0eh
        mov al, 'X'
        int 10h
        mov eax, 0
        retf
code_end:

data_start:
data_end:

stack_bottom:
    rb 4096
stack_top:
total_mem:
