section .text
global scaledownhor

scaledownhor:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 48
    
    ; Rejestry:
    ; rdi - img
    ; rsi - new_img
    ; edx - width
    ; ecx - height
    ; r8d - scale
    ; r9d - stride
    ; [rbp + 16] - new_stride

    mov r10d, dword [rbp + 16] ; new_stride
    xor r11d, r11d          ; y = 0

.y_loop:
    cmp r11d, ecx           ; y >= height?
    jge .done

    xor r12d, r12d          ; x_new = 0
    mov eax, edx            ; eax = width
    mov r13d, edx
    xor edx, edx            ; clear edx for division
    div r8d                 ; eax = width / scale
    mov ebx, eax            ; ebx = max_x_new (width / scale)
    mov edx, r13d           ; restore original width to edx

.x_loop:
    cmp r12d, ebx           ; x_new >= (width / scale)?
    jge .next_row

    ; Oblicz orig_x = x_new * scale
    mov eax, r12d
    imul eax, r8d           ; eax = orig_x

    ; Inicjalizacja maksimów
    mov dword [rsp + 0], 0    ; max_b = 0
    mov dword [rsp + 4], 0    ; max_g = 0
    mov dword [rsp + 8], 0    ; max_r = 0

    ; Pętla po i = 0..scale-1
    xor eax, eax            ; i = 0

.max_loop:
    cmp eax, r8d            ; i >= scale?
    jge .store_pixel

    ; Oblicz x_old = orig_x + i
    mov r13d, r12d           ; edx = x_new
    imul r13d, r8d           ; edx = x_new * scale
    add r13d, eax            ; edx = x_old

    ; Oblicz offset w img: y * stride + x_old * 3
    mov r15d, r11d          ; r15d = y
    imul r15d, r9d          ; r15d = y * stride
    mov ebx, r13d            ; ebx = x_old
    imul ebx, 3             ; ebx = x_old * 3
    add r15d, ebx           ; r15d = offset (32-bit)
    movsxd r15, r15d        ; r15 = offset (64-bit)

    ; Porównaj B, G, R z maksimami
    movzx ebx, byte [rdi + r15]      ; B
    cmp ebx, [rsp + 0]
    mov r14d, [rsp + 0]
    cmova r14d, ebx
    mov [rsp + 0], r14d

    movzx ebx, byte [rdi + r15 + 1]  ; G
    cmp ebx, [rsp + 4]
    mov r14d, [rsp + 4]
    cmova r14d, ebx
    mov [rsp + 4], r14d

    movzx ebx, byte [rdi + r15 + 2]  ; R
    cmp ebx, [rsp + 8]
    mov r14d, [rsp + 8]
    cmova r14d, ebx
    mov [rsp + 8], r14d                 

    inc eax                  ; i++
    jmp .max_loop

.store_pixel:
    ; Oblicz offset w new_img: y * new_stride + x_new * 3
    mov eax, r11d           ; eax = y
    imul eax, r10d          ; eax = y * new_stride
    mov r14d, r12d           ; edx = x_new
    imul r14d, 3             ; edx = x_new * 3
    add eax, r14d            ; eax = offset (32-bit)
    movsxd rax, eax         ; rax = offset (64-bit)

    ; Zapisz piksel
    mov al, byte [rsp + 0]
    mov [rsi + rax], al       ; B

    mov al, byte [rsp + 4]
    mov [rsi + rax + 1], al   ; G

    mov al, byte [rsp + 8]
    mov [rsi + rax + 2], al   ; R

    inc r12d                ; x_new++
    jmp .x_loop

.next_row:
    inc r11d                ; y++
    jmp .y_loop

.done:
    add rsp, 48
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

section .note.GNU-stack noalloc noexec nowrite progbits