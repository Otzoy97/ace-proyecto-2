clearScreen macro
    push ax
    mov ah, 00
    mov al, 03h
    int 10h
    pop ax
endm

pauseAnyKey macro
    push ax
    printStr offset pressanykey
    mov ah, 08h
    int 21h
    pop ax
endm

