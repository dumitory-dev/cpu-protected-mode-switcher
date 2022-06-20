use16
.switch_to_protected_mode:  
    ; Fast method of enabling A20 may not work on all x86 BIOSes
    ; It is good enough for emulators and most modern BIOSes
    ; See: https://wiki.osdev.org/A20_Line
    cli          ; Disable interrupts
    in al, 0x92
    or al, 2
    out 0x92, al ; Enable A20 using Fast Method

    lgdt [.gdt_descriptor]            ; 2. load the GDT descriptor
    mov eax, cr0
    or eax, 0x1                       ; 3. set 32-bit mode bit in cr0
    mov cr0, eax
    jmp CODE_SEG:.init_protected_mode ; 4. far jump by using a different segment

use32
.init_protected_mode:
    mov ax, DATA_SEG ; 5. update the segment registers
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov ebp, 0x90000 ; 6.  Set the stack to grow down from area under
                     ;     EBDA/Video memory

    mov esp, ebp     ; 7. set the stack pointer to the top of the free space

    call .main_protected_mode ; 8. call the main function