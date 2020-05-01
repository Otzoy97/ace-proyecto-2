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

pauseSpaceKey macro
    local _pause1
    push ax
    _pause1:
        mov ah, 01h
        int 16h
        jz _pause1
        mov ah, 00h
        int 16h
        cmp ah, 39h
        jnz _pause1
    pop ax
endm