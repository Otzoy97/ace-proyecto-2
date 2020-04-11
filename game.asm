.model small, c
.386
.stack 400h
include p2lib.inc
.data
    pointh dw 0
.code
initGame proc far c uses ecx
    ret
initGame endp

printFrame proc far c uses ecx
    mov cx, 70 ;; barras horizontales
    _printF1:
        cmp cx, 249
        jg _printF2
        invoke printPixel, 0fh, cx, 19
        invoke printPixel, 0fh, cx, 18
        invoke printPixel, 0fh, cx, 17
        invoke printPixel, 0fh, cx, 180
        invoke printPixel, 0fh, cx, 181
        invoke printPixel, 0fh, cx, 182
        inc cx
        jmp _printF1
    _printF2:
        mov cx, 17
        _printF3:
            cmp cx, 182
            jg _printF4
            invoke printPixel, 0fh, 69, cx
            invoke printPixel, 0fh, 68, cx
            invoke printPixel, 0fh, 67, cx
            invoke printPixel, 0fh, 250, cx
            invoke printPixel, 0fh, 251, cx
            invoke printPixel, 0fh, 252, cx
            inc cx
            jmp _printF3
    _printF4:
        ret
printFrame endp
end