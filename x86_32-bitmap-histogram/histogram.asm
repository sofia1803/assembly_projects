section .text
global histogram

; Function: histogram
;   [ebp+8]  - img pointer
;   [ebp+12] - width
;   [ebp+16] - height
;   [ebp+20] - hist pointer

histogram:
    push    ebp
    mov     ebp, esp
    push    esi        
    push    edi
    push    ebx
    push    ecx
    push    edx
    
    mov     esi, [ebp+8]    ; esi = img pointer
    mov     eax, [ebp+12]   ; eax = width
    mov     ebx, [ebp+16]   ; ebx = height
    mov     edi, [ebp+20]   ; edi = hist pointer
    
    mov     edx, eax        ; edx = width
    add     edx, 3          ; edx = width + 3
    and     edx, 0xFFFFFFFC ; edx = (width + 3) & (~3) = padded row size
    
    mov     ecx, ebx        ; ecx = height (number of rows to process)
    
    ;check if any rows to process
    test    ecx, ecx
    jz      .done
    
.row_loop:
    push    ecx            ; Save row counter
    push    esi            ; Save current row start position
    
    ;process pixels in current row
    mov     ecx, eax        ; ecx = width (number of pixels in row)
    
.pixel_loop:
    ;load pixel value
    movzx   ebx, byte [esi]
    
    ;increment corresponding histogram bin
    ;each histogram entry is 4 bytes (uint32_t)
    inc     dword [edi + ebx*4]
    
    ;next pixel in current row
    inc     esi
    
    ;decrement pixel counter and continue if not zero
    dec     ecx
    jnz     .pixel_loop
    
    ;restore row start position and move to next row
    pop     esi
    add     esi, edx        ;move to start of next row (add padded row size)
    
    ;restore and decrement row counter
    pop     ecx
    dec     ecx
    jnz     .row_loop
    
.done:
    pop     edx
    pop     ecx
    pop     ebx
    pop     edi
    pop     esi
    pop     ebp
    ret