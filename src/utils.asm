;  ---- 16-bit utils ----
use16
.println:
    ; keep this in mind:
    ; while (string[i] != 0) { print string[i]; i++ }
    lodsb ; load byte from string (DS:SI register)
    test al, al
    jz   .exit_println
    mov  ah, 0xE
    int  0x10
    jmp  .println
.exit_println:
    mov  al, 0xA ; newline
    int  0x10 
    mov al, 0x0d ; carriage return
    int 0x10
    ret


; ---- 32-bit utils ----

use32

.cur_row:      dd 0x00
.cur_col:      dd 0x00
.screen_width: dd 0x00

CR                  EQU 0x0d     ; Carriage return
LF                  EQU 0x0a     ; Line feed
VIDEO_TEXT_ADDR equ 0xb8000
ATTR_WHITE_ON_BLACK equ 0x0f     ; the color byte for each character

; ---- video utils ---- 32-bit
; Based on https://stackoverflow.com/questions/53861895/assembly-32-bit-print-to-display-code-runs-on-qemu-fails-to-work-on-real-hardwa

; Function for prepare cursor settings to write a character
; 1. Clear the current column and row position variables
; 2. Get the current column and row position from the BIOS
; 3. Get the screen width from the BIOS
; 4. Return to the caller
.prepare_screen:
    xor eax, eax                 ; Clear EAX for the instructions below
    mov al, [0x450]              ; Byte at address 0x450 = last BIOS column position
    mov [.cur_col], eax          ; Copy to current column
    mov al, [0x451]              ; Byte at address 0x451 = last BIOS row position
    mov [.cur_row], eax          ; Copy to current row

    mov ax, [0x44a]              ; Word at address 0x44a = # of columns (screen width)
    mov [.screen_width], eax     ; Copy to screen width
    ret

; Function for setting the current column and row position
.set_cursor:
    mov ecx, [.cur_row]          ; EAX = cur_row
    imul ecx, [.screen_width]    ; ECX = cur_row * screen_width
    add ecx, [.cur_col]          ; ECX = cur_row * screen_width + cur_col

    ; Send low byte of cursor position to video card
    mov edx, 0x3d4
    mov al, 0x0f
    out dx, al                   ; Output 0x0f to 0x3d4
    inc edx
    mov al, cl
    out dx, al                   ; Output lower byte of cursor pos to 0x3d5

    ; Send high byte of cursor position to video card
    dec edx
    mov al, 0x0e
    out dx, al                   ; Output 0x0e to 0x3d4
    inc edx
    mov al, ch
    out dx, al                   ; Output higher byte of cursor pos to 0x3d5
 
    ret

; Function: println32
;           Display a string to the console on display page 0 in protected mode.
;           Handles carriage return and line feed.
;           Doesn't handle tabs, backspace, wrapping and scrolling.
;
; Inputs:   EAX = Offset of address to print
; Clobbers: EAX, ECX, EDX

.println32:
    pushad ; Save registers

    ; Assume base of text video memory is ALWAYS 0xb8000
    mov ebx, VIDEO_TEXT_ADDR     ; EBX = beginning of video memory

    mov eax, [.cur_row]          ; EAX = cur_row
    mul dword [.screen_width]    ; EAX = cur_row * screen_width
    mov edx, eax                 ; EDX = copy of offset to beginning of line
    add eax, [.cur_col]          ; EAX = cur_row * screen_width + cur_col
    lea edi, [ebx + eax * 2]     ; EDI = memory location of current screen cell

    mov ah, ATTR_WHITE_ON_BLACK ; Set attribute
    jmp .getch
.repeat:
    cmp al, CR                   ; Is the character a carriage return?
    jne .chk_lf                  ; If not skip and check for line feed
    lea edi, [ebx + edx * 2]     ; Set current video memory pointer to beginning of line
    mov dword [.cur_col], 0      ; Set current column to 0
    jmp .getch                   ; Process next character
.chk_lf:
    cmp al, LF                   ; Is the character a line feed?
    jne .write_chr               ; If not then write character
    mov eax, [.screen_width]
    lea edi, [edi + eax * 2]     ; Set current video memory ptr to same pos on next line
    inc dword [.cur_row]         ; Set current row to next line
    mov ah, ATTR_WHITE_ON_BLACK  ; Reset attribute
    jmp .getch                   ; Process next character

.write_chr:
    inc dword [.cur_col]         ; Update current column
    stosw

.getch:
    lodsb                        ; Get character from string
    test al, al                  ; Have we reached end of string?
    jnz .repeat                  ; if not process next character

.end:
    call .set_cursor             ; Update hardware cursor position

    popad
    ret

