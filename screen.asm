clearScreen macro
    push ax
    push cx
    push dx
    mov al, 02h
    mov dx, 0000h
    int 10h
    mov ax, 0900h
    mov bl, 07h
    mov cx, 0fa0h
    int 10h
    pop dx
    pop cx
    pop ax
endm

pressAnyKey macro
    push ax
    mov ah, 10h
    int 16h
    pop ax
endm

