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
    ;; barras horizontales
    ;; comienza en 17 * 320 + 70 = 5510
    invoke printSquare, 0fh, 5510, 180, 3
    ;; comienza en 180 * 320 + 70 = 57670
    invoke printSquare, 0fh, 57670, 180, 3
    ;; barras verticales
    ;; comienza en 17 * 320 + 67 = 5509
    invoke printSquare, 0fh, 5509, 3, 166
    ;; comienza en 17 * 320 + 250 = 58490
    invoke printSquare, 0fh, 5690, 3, 166
        ret
printFrame endp
end