.model small, c
.386
;--------------------------------------------------
.stack 400h
include p2lib.inc
include string.asm
;--------------------------------------------------
.data
array   dw  6,8,4,0,1,9,7
;--------------------------------------------------
.code
.startup
    mov ax, @data
    mov ds, ax
main proc
    mov cx, 7
    xor di, di
    _1:
        xor bx, bx
        mov bx, array[di]
        add bx, '0'
        printChar bl
        add di, 2
        loop _1
    printChar 0ah
    printChar 0dh
    invoke shellSort, offset array, 6
    mov cx, 7
    xor di, di
    _2:     
        xor bx, bx
        mov bx, array[di]
        add bx, '0'
        printChar bl
        add di, 2
        loop _2
    mov ax, 4c00h
    int 21h
main endp
end
