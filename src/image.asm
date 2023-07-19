format binary as "hcf"

org 0

include "hcfs.inc"

file "boot/bootloader.bin"

hcfs!EPB "HexOS System Disk", 0x200, 8, 16, root, -1, -1
