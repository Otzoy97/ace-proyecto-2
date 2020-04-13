.model small, c
.386
.stack 400h
include p2lib.inc
include fileH.asm
include string.asm
.data
    ;--------------------------------------------------
    ; Elementos generales
    ;--------------------------------------------------
    pointc          dw 137               ;; posición inicial 151
    car             db 1800 dup(0)       ;; 
    good            db 900 dup(0)        ;; 
    bad             db 900 dup(0)        ;; 
    carFN           db "car.otz", 00     ;; archivo que DEBE de existir
    goodFN          db "good.otz", 00    ;; archivo que DEBE de existir
    badFN           db "bad.otz", 00     ;; archivo que DEBE de existir
    fileHandler     dw ?                 ;; manejador de archivo
    ;--------------------------------------------------
    ; Datos de punteo
    ;--------------------------------------------------
    headerG         db " user1     n1        000       00:00:00 "
    actualUser      db dup(7)            ;; cadena
    actualLevel     db 0                 ;; número
    actualScore     dw 3                 ;; número
    actualTime      dw 0                 ;; número
.code

;--------------------------------------------------
initGame proc far c
; Carga el archivo del carro
;--------------------------------------------------
    ; Carga el archivo del carro
    openFile carFN, fileHandler           ;; abre el archivo
    jc _initGame1
    readFile fileHandler, car, 1800       ;; lee el archivo
    jc _initGame1
    closeFile fileHandler                 ;; cierra el archivo
    ; Carga el archivo del bloque amarillo
    openFile goodFN, fileHandler          ;; abre el archivo
    jc _initGame1
    readFile fileHandler, good, 900       ;; lee el archivo
    jc _initGame1
    closeFile fileHandler                 ;; cierra el archivo
    ; Carga el archivo del bloque verde
    openFile badFN, fileHandler           ;; abre el archivo
    jc _initGame1
    readFile fileHandler, bad, 900        ;; lee el archivo
    jc _initGame1
    closeFile fileHandler                 ;; cierra el archivo
    _initGame1:
        ret
initGame endp

;--------------------------------------------------
printHeader proc far c uses eax ebx ecx edx esi edi
; Printa el texto que indica el nombre del jugador,
; el punte
;--------------------------------------------------
    mov ah, 02h
    mov bh, 0
    mov dx, 0
    int 10h
    mov cx, 40
    xor si, si
    _printHeader1:
        printChar headerG[si]
        inc si
        loop _printHeader1
    ret
printHeader endp

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
printObs proc far c uses eax ebx ecx edx, pos : byte, bType : byte
; POS :   BYTE indica la posición a donde pintar [0 - 5]
; BTYPE : BYTE indica el tipo de obstacula a pintar
;         0 - amigo 1 - enemigo
; Pinta un obstaculo puede ser pintado en 70, 100, 130, 160, 190 y 220
;--------------------------------------------------
    movsx ax, pos
    mov bl, 30
    xor dx, dx          ;; limpia dx
    mul bl              ;; pos * 30
    add ax, 6470        ;; 20 * 320 + 70 + pos*30
    cmp bType, 1
    jz  _printEnemy     ;; es un enemigo
        mov dx, offset good
    jmp _printOEnd
    _printEnemy:
        mov dx, offset bad
    _printOEnd:
        invoke printPicture, dx, ax, 30, 30
    ret
printObs endp

;--------------------------------------------------
printBackground proc far c
; Printa el interior del marco del juego
;--------------------------------------------------
    ;; cuadrado completo
    ;; comienza en 20 * 320 + 70 = 6470
    invoke printSquare, 7, 6470, 180, 160
    ret
printBackground endp

;--------------------------------------------------
playGame proc far c
; Controla las mecánicas del juego
;--------------------------------------------------
    ret
playGame endp
end