format binary

use16

org 0x7C00


BootSeg        = 0x7C00
DirSeg         = 0x1000
HxldrSeg       = 0x2000
StartCluster   = 26
sizeof.DIR_ENT = 32
sizeof.SHARED  = 12

struc xd dwrd {
.lsw equ $
.msw equ $+2
    dd dwrd
}

struc SHARED {
.ReadClusters      xd ?                           ; function pointer
.ReadSectors       xd ?                           ; function pointer
.SectorBase        xd ?                           ; starting sector
}


jmp boot
nop

BPB:
.Version           db "MSDOS5.0"
.BytesPerSector    dw 512
.SectorsPerCluster db 8
.ReservedSectors   dw 1
.Fats              db 2
.DirectoryEntries  dw 512
.Sectors           dw 4*17*305-1
.Media             db 0xF8 ; or 0xF0 :)
.FatSectors        dw 8
.SectorsPerTrack   dw 17
.Heads             dw 4
.HiddenSectors     xd 1
.SectorsLong       dd 0
.DriveNumber:      db 0x80
.CurrentHead       db ?
.Signature         db 41
.BootID            dd ?
.BootVolLabel      db "HEXOSFATDSK"
.BootSystemID      db "FAT     "


boot:
    ;; Setup the stack
    xor  word  ax,                           ax                          ;
    mov  word  ss,                           ax                          ;
    mov  word  sp,                           0x7c00                      ;
    push word  0                             ;                           ;
    pop  word  ds                            ;                           ;

    ;; Determine sector root directory starts on
    mov  byte  al,                           [BPB.Fats]                  ;
    mul  dword [BPB.FatSectors]              ;                           ;
    add  word  ax,                           [BPB.ReservedSectors]       ;
    push word  ax                            ;                           ;
    xchg word  ax,                           cx                          ;

    ;; Take into account size of directory (only know number of directory entries)
    mov  word  ax,                           sizeof.DIR_ENT              ;
    mul  word  [BPB.DirectoryEntries]        ;                           ; convert to bytes in directory
    mov  word  bx,                           [BPB.BytesPerSector]        ; add in sector size
    add  word  ax,                           bx                          ;
    dec  word  ax                            ;                           ; decrement so that we round up
    div  word  bx                            ;                           ; convert to sector number
    add  word  cx,                           ax                          ;
    mov  word  [ClusterBase],                cx                          ; save it for later

    ;; Load in the root directory.
    push word  DirSeg                        ;                           ;
    pop  word  es                            ;                           ;
    xor  word  bx,                           bx                          ;
    pop  word  [Arguments.SectorBase]        ;                           ;
    mov  word  [Arguments.SectorBase+2],     bx                          ;

    ;; DoRead does a RETF, but LINK pukes if we do a FAR call in a /tiny program.
    ; (al) = # of sectors to read
    push word  cs                            ;                           ;
    call word  do_read                       ;                           ;
    jc   word  err_he                        ;                           ;

    ;; Now we scan for the presence of HXLDR
    xor  word  bx,                           bx                          ;
    mov  word  bx,                           [BPB.DirectoryEntries]      ;

L10:
    mov  word  di,                           bx                          ;
    push word  cx                            ;                           ;
    mov  word  cx,                           11                          ;
    mov  word  si,                           LOADERNAME                  ;
    repe cmpsb ;                             ;                           ;
    pop  word  cx                            ;                           ;
    jz   word  L10_end                       ;                           ;
    ;    ;     ;                             ;                           ;
    add  word  bx,                           sizeof.DIR_ENT              ;
    loop word  L10                           ;                           ;

L10_end:
    push word  bx                            ;                           ;
    add  word  bx,                           StartCluster                ;
    mov  word  dx,                           [es:bx]                     ; (dx) -> starting cluster number
    pop  word  bx                            ;                           ;
    push word  dx                            ;                           ;
    mov  word  ax,                           1                           ; (al) -> sectors to read

    ;; Now, go read the file
    push word  HxldrSeg                      ;                           ;
    pop  word  es                            ;                           ;
    xor  word  bx,                           bx                          ; (es:bx) -> start of HXLDR

    ;; LINK barfs if we do a FAR call in a TINY program, so we have to fake it out by pushing CS.
    push word  cs                            ;                           ;
    call word cluster_read                   ;                           ;
    jc   word  err_he                        ;                           ;

    ;; HXLDR requires:
    ;   BX        -> Starting Cluster Number of HXLDR
    ;   DL        -> INT 13 drive number we booted from
    ;   DS:SI     -> the boot media's BPB
    ;   DS:DI     -> argument structure
    ;   1000:0000 -> entire FAT is loaded
    pop  word  bx                            ;                           ; (bx) -> Starting Cluster Number
    lea  word  si,                           [BPB]                       ; (ds:si) -> BPB
    lea  word  di,                           [Arguments]                 ; (ds:di) -> Arguments
    push word  ds                            ;                           ;
    pop  word  [Arguments.ReadClusters+2]    ;                           ;
    mov  word  [Arguments.ReadClusters],     cluster_read                ;
    pop  word  [Arguments.ReadSectors+2]     ;                           ;
    mov  word  [Arguments.ReadSectors],      do_read                     ;
    mov  byte  dl,                           [BPB.DriveNumber]           ;
    jmp        0x2000:0x0003                 ;                           ;

err_bnf:
    mov  word  si,                           msg_no_hxldr                ;
    jmp  word  err_2                         ;                           ;

err_he:
    mov  word  si,                           msg_read_error              ;

err_2:
    call word  err_print                     ;                           ;
    mov  word  si,                           msg_reboot_error            ;
    call word  err_print                     ;                           ;
    sti  ;     ;                             ;                           ;
    jmp  word  $                             ;                           ;

err_print:
    lodsb;     ;                             ;                           ;
    or   byte  al,                           al                          ;
    jz   word  print_done                    ;                           ;
    mov  byte  ah,                           14                          ;
    mov  word  bx,                           7                           ;
    int  byte  0x10                          ;                           ;
    jmp  word  err_print                     ;                           :

print_done:
    ret  ;     ;                             ;                           ;

cluster_read:
    push word  ax                            ;                           ; (TOS) = # of sectors to read
    sub  word  dx,                           2                           ; adjust for reserved clusters 0 and 1
    mov  byte  al,                           [BPB.SectorsPerCluster]     ;
    xor  byte  ah,                           ah                          ;
    mul  word  dx                            ;                           ; (dx:ax) = starting sector number
    add  word  ax,                           [ClusterBase]               ; adjust for FATs, root dir, boot sec.
    adc  word  dx,                           0                           ;
    mov  word  [Arguments.SectorBase],       ax                          ;
    mov  word  [Arguments.SectorBase+2],     dx                          ;
    pop  word  ax                            ;                           ; (al) = # of sectors to read
    ; Now we've converted the cluster number to a SectorBase, so just fall through into DoRead

do_read:
    mov  byte  [SectorCount],                al                          ;

dr_loop:
    mov  word  ax,                           [Arguments.SectorBase]      ; Starting sector
    mov  word  dx,                           [Arguments.SectorBase+2]    ; Starting sector

    ;; DoDiv - convert logical sector number in AX to physical Head/Track/Sector in CurrentHead/CurrentTrack/CurrentSector.
    add  word  ax,                           [BPB.HiddenSectors]         ; adjust for partition's base sector
    adc  word  dx,                           [BPB.HiddenSectors+2]       ;
    div  word  [BPB.SectorsPerTrack]         ;                           ;
    inc  byte  dl                            ;                           ; sector numbers are 1-based
    mov  byte  [CurrentSector],              dl                          ;
    xor  word  dx,                           dx                          ;
    div  word  [BPB.Heads]                   ;                           ;
    mov  byte  [BPB.CurrentHead],            dl                          ;
    mov  word  [CurrentTrack],               ax                          ;

    ; CurrentHead is the head for this next disk request
    ; CurrentTrack is the track for this next request
    ; CurrentSector is the beginning sector number for this request

    ;; Compute the number of sectors that we may be able to read in a single ROM request.
    mov  word  ax,                           [BPB.SectorsPerTrack]       ;
    sub  byte  al,                           [CurrentSector]             ;
    inc  word  ax                            ;                           ;
    cmp  byte  al,                           [SectorCount]               ;
    jbe  word  do_call                       ;                           ;
    mov  byte  al,                           [SectorCount]               ;
    xor  byte  ah,                           ah                          ;

do_call:
    ;; do_call - call ROM BIOS to read AL sectors into ES:BX.
    push word  ax                            ;                           ;
    mov  byte  ah,                           2                           ;
    mov  word  cx,                           [CurrentTrack]              ;
    xchg byte  ch,                           cl                          ;
    mov  word  dx,                           [BPB.DriveNumber]           ;
    int  byte  0x13                          ;                           ;
    jnc  word  dc_noerr                      ;                           ;
    add  word  sp,                           2                           ;
    stc  ;     ;                             ;                           ;
    retf ;     ;                             ;                           ;

dc_noerr:
    pop  word  ax                            ;                           ;
    sub  byte  [SectorCount],                al                          ;
    jbe  word  dr_done                       ;                           ;
    add  word  [Arguments.SectorBase],       ax                          ; increment logical sector position
    adc  word  [Arguments.SectorBase+2],     0                           ;
    mul  word  [BPB.BytesPerSector]          ;                           ; determine next offset for read
    add  word  bx,                           ax                          ; (BX)=(BX)+(SI)*(Bytes per sector)
    jmp  word  dr_loop                       ;                           ;

dr_done:
    mov  byte  [SectorCount],                al                          ;
    clc  ;     ;                             ;                           ;
    retf ;     ;                             ;                           ;

msg_no_hxldr       db "BOOT: Couldn't find HXLDR",    0x0D, 0x0A, 0x00
msg_read_error     db "BOOT: I/O error reading disk", 0x0D, 0x0A, 0x00
msg_reboot_error   db "Please insert another disk",   0x0D, 0x0A, 0x00

LOADERNAME         db "HXLDR   BIN"

times 510-$+$$     db 0
signature          dw 0xAA55

space              rb 4
CurrentTrack       dw ?
CurrentSector      db ?
SectorCount        db ?
ClusterBase        dw ?
Retries            db ?
Arguments          SHARED
