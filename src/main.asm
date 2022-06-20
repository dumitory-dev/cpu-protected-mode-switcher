
use16 
org 0x7c00 ; bootloader offset
.main:
    xor ax, ax     ; DS=SS=0. Real mode code below doesn't use ES
    mov ds, ax
    mov ss, ax                 
    mov sp, 0x7c00 ; Stack at 0x0000:0x7c00 below bootloader
    cld            ; Set string instructions to use forward movement

    lea si, [MSG_REAL_MODE]
    call .println
    call .switch_to_protected_mode

.end_loop:
    hlt
    jmp .end_loop

include 'utils.asm'
include 'gdt32.asm'
include "switch.asm"

use32
.main_protected_mode:
    call .prepare_screen
    lea esi, [MSG_PROT_MODE] ; set the message to display in protected mode
    call .println32          ; display the message
    jmp $

MSG_REAL_MODE db "Started in 16-bit real mode", 0
MSG_PROT_MODE db "Loaded 32-bit protected mode", 0

; bootsector
times 510-($-$$) db 0
dw 0xaa55 ; Magic number for boot sector