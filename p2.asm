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
    call videoStart
    _1:
        call clearScreen
        call initPrint
        mov cx, 10
        ; .while (cx <= 189)
        ;     mov ax, 0
        ;     .while(ax <= 319)
        ;         invoke printPixel, 0fh, ax, cx
        ;         add ax, 10
        ;     .endw
        ;     inc cx
        ; .endw
        
        call printFrame
        call syncBuffer

        mov ah, 01h
        int 16h
        jnz _2
        jmp _1
    _2:
        call clearScreen
        call printFrame
        call videoStop
    ; mov cx, 7
    ; xor di, di
    ; _1:
    ;     xor bx, bx
    ;     mov bx, array[di]
    ;     add bx, '0'
    ;     printChar bl
    ;     add di, 2
    ;     loop _1
    ; printChar 0ah
    ; printChar 0dh
    ; invoke shellSort, offset array, 7
    ; mov cx, 7
    ; xor di, di
    ; _2:     
    ;     xor bx, bx
    ;     mov bx, array[di]
    ;     add bx, '0'
    ;     printChar bl
    ;     add di, 2
    ;     loop _2
    mov ax, 4c00h
    int 21h
main endp
end
