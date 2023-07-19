; blkadr - block device addr
macro blkadr cluster, offset
{
	dd cluster
	dw offset
}


; HCFS entry. all is file. directories too. directory is a file contains list of included entries
; type - 0x00 if corrupted, 0x01 if lost or found, 0x02 if data block
; type2 - subtype of descriptor
; for corrupted: 0x00 not restorable, 0x01 restorable, 0x02 not too corrupted, 0x03 not corrupted
; for lost+found: 0x00 not restorable, 0x01 restorable, 0x02 not lost (immediately found), 0x03 not found
; for data block: 0x15 - EPB, 0x16 - file descriptor, 0x17 - datablock descriptor, 0x18 - indexing descriptor
macro hcfs!entry type, type2, data
{
	db 0x16
	db type
	db type2
	db data
}


; Extended Parameters Block (64 bytes)
; volname (ascii) - name of volume
; sector_size (unsigned short int) - sector size in bytes
; cluster_size (unsigned short int) - cluster size in sectors
; size (uint) - size of volume in clusters
; root (blkadr) - root entry descriptor address
; index_XXXX (int) - indexing data (-1 if not indexed yet)
macro hcfs!EPB volname, sector_size, cluster_size, size, root, index_used, index_free
{
	local ..name_start
	db 0x02         ; 1
	db 0x15         ; 2
	db "HCFS10"     ; 8
	dw sector_size  ; 10
	dw cluster_size ; 12
	dd size         ; 16
	blkadr root     ; 22
	dd index_used   ; 26
	dd index_free   ; 30
..name_start:
	db volname, 0
	db 0 times 34-$+..name_start ; 64
}


; <file> alias for hcfs!entry
; filname (ascii) - filename
; flags (char) - flags
; dtsg (blkadr) - data block address
; prev (blkadr) - previous fs descriptor address
; next (blkadr) - next fs descriptor address
; parent (blkadr) - reserved so far
; for every blkadr we need to save backup version.
; it's useless for now, but you MUST fill this fields
macro hcfs!file filname, flags, dtsg, prev, next, parent
{
	local ..name_start
	db 0x02                      ; 1
	db 0x16                      ; 2
	db flags                     ; 3
	blkadr dtsg                  ; 8
	blkadr dtsg                  ; 13
	blkadr prev                  ; 18
	blkadr prev                  ; 22
	blkadr next                  ; 27
	blkadr next                  ; 32
	blkadr parent                ; 37
..name_start:
	db volname, 0
	db 0 times 27-$+..name_start ; 64
}


; <dataseg> alias for hcfs!entry
; dtad (blkadr) - address of start of segment
; prev (blkadr) - address of previous segment of file
; next (blkadr) - anologic
; size (uint) - size of segment in bytes
; flags (char) - flags
macro hcfs!seg dtad, prev, next, size, flags
{
	db 0x02
	db 0x17
	blkadr dtad
	blkadr dtad
	blkadr prev
	blkadr prev
	blkadr next
	blkadr next
	dd size
	db flags
}


hcfs!END = 0xFFFF
hcfs!FRE = 0x0000
hcfs!COR = 0xFFF7
hcfs!ALC = 0x0002
hcfs!DCL = 0xFFF2
hcfs!BGY = 0xFFF5
hcfs!BSY = 0xFFFA
hcfs!HSH = 0xFFF1

hcfs!FIL = 0x01
hcfs!DIR = 0x02
hcfs!LNK = 0x03
hcfs!NUL = 0x04
hcfs!VOL = 0x05

hcfs!RO = 00000001b
hcfs!EX = 00000010b
hcfs!SH = 00000100b
hcfs!SY = 00001000b
hcfs!OS = 00010000b
