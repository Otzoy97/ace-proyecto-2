printChar macro char:=<0>
    push ax
    push dx
    xor dx, dx
    mov ah, 02h
    mov dl, char
    int 21h
    pop dx 
    pop ax
endm