.model small, c
.386
.stack 400h
include p2lib.inc
include fileH.asm
;include stringH.asm
.data
    pointc dw 137               ;; posición inicial 151
    car    db 1800 dup(0)       ;; el color que se deberá modificar es el 85
    carFN  db "car.otz"         ;; archivo que DEBE de existir
    carFH  dw ?                 ;; manejador de archivo
.code
;--------------------------------------------------
initGame proc far c
; Carga el archivo del carro
;--------------------------------------------------
    openFile carFN, carFH           ;; abre el archivo
    jc _initGame1
    readFile carFH, car, 1800       ;; lee el archivo
    jc _initGame1
    closeFile carFH                 ;; cierra el archivo
    _initGame1:
        ret
initGame endp

;--------------------------------------------------
printFrame proc far c
; Printa el marco del juego
;--------------------------------------------------
    ;; barras horizontales
    ;; comienza en 17 * 320 + 70 = 5510
    invoke printSquare, 0fh, 5510, 180, 3
    ;; comienza en 180 * 320 + 70 = 57670
    invoke printSquare, 0fh, 57670, 180, 3
    ;; barras verticales
    ;; comienza en 17 * 320 + 67 = 5509
    invoke printSquare, 0fh, 5507, 3, 166
    ;; comienza en 17 * 320 + 250 = 58490
    invoke printSquare, 0fh, 5690, 3, 166
    ret
printFrame endp

;--------------------------------------------------
printCar proc far c
; Printa el carro utilizando dw como posición
; inicial
;--------------------------------------------------
    ;; cuerpo del carro
    ;; comienza en 140 * 320 + pointc
    mov bx, 43840
    add bx, pointc
    invoke printPicture, offset car, bx, 45, 40
    ret
printCar endp

;--------------------------------------------------
printBackground proc far c
; Printa el interior del marco del juego
;--------------------------------------------------
    ;; cuadrado completo
    ;; comienza en 20 * 320 + 70 = 6470
    invoke printSquare, 7, 6470, 180, 160
    ret
printBackground endp
end