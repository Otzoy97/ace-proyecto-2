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
    pointc          dw 137               ;; posición inicial 137 (columna)
    vram            dw ?                 ;; almacena el offset del doble buffer para el fondo del juego
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
    actualVel       dw ?                 ;; número
.code

;--------------------------------------------------
initGame proc far c
; Carga lor modelos desde los archivos .otz
; Reserva la memoria para el doble buffer del escenario
;--------------------------------------------------
    ; Carga el archivo del carro
    openFile carFN, fileHandler           ;; abre el archivo
    jc _initGameFailed
    readFile fileHandler, car, 1800       ;; lee el archivo
    jc _initGameFailed
    closeFile fileHandler                 ;; cierra el archivo
    ; Carga el archivo del bloque amarillo
    openFile goodFN, fileHandler          ;; abre el archivo
    jc _initGameFailed
    readFile fileHandler, good, 900       ;; lee el archivo
    jc _initGameFailed
    closeFile fileHandler                 ;; cierra el archivo
    ; Carga el archivo del bloque verde
    openFile badFN, fileHandler           ;; abre el archivo
    jc _initGameFailed
    readFile fileHandler, bad, 900        ;; lee el archivo
    jc _initGameFailed
    closeFile fileHandler                 ;; cierra el archivo
    mov ah, 48h
    mov bx, 2025
    int 21h                               ;; reserva la memoria para la pista
    jc _initGameFailed
    mov vram, ax
    mov ax, 13h
    int 10h                               ;; inicia el modo video
    mov ax, 1
    jmp _initGame1
    _initGameFailed:
        mov ax, 0
    _initGame1:
        cmp ax, 1
        ret
initGame endp

;--------------------------------------------------
printHeader proc far c uses eax ebx ecx edx esi edi
; Escribe una línea de texto al inicio de la pantalla
; El largo de texto es 40 bytes
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
; Esta función NO utiliza el doble buffer
;--------------------------------------------------
    mov ah, 0ch
    mov al, 0fh     ;; pixel blanco
    ;; barras horizontales
    mov cx, 70  ;; columna 70
    _printF1:
        cmp cx, 250
        jge _printF6  
        mov dx, 17
        _printF2:
            cmp dx, 20
            jge _printF3
            int 10h
            inc dx
            jmp _printF2
        _printF3:
            mov dx, 180
        _printF4:
            cmp dx, 183
            jge _printF5
            int 10h
            inc dx
            jmp _printF4
        _printF5:
            inc cx
            jmp _printF1
    _printF6:
        mov dx, 17  ;; fila 17
    _printF7:
        cmp dx, 183
        jge printF12
        mov cx, 67
        _printF8:
            cmp cx, 70
            jge _printF9
            int 10h
            inc cx
            jmp _printF8
        _printF9:
            mov cx, 250
        _printF10:
            cmp cx, 253
            jge _printF11
            int 10h
            inc cx
            jmp _printF10
        _printF11:
            inc dx
            jmp _printF7
    _printF12:
    ret
printFrame endp

;--------------------------------------------------
printCar proc far c uses edi esi
; Printa la capa del carro
; Utiliza la variabla que almacena el modelo como doble buffer
;--------------------------------------------------
    ;; cuerpo del carro
    ;; comienza en 137 * 320 + pointc
    mov bx, 43840
    add bx, pointc
    ;; sincronizar video con la imagen de carro
    ;; en la posición de memoria de video = bx
    ;; la figura tiene una base de 45
    ;; se pintará 40 posiciones
    ;; la figura se leerá desde la posición 0
    invoke syncBuffer, offset car, bx, 45, 40, 0
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
printBackground proc far c uses edi esi
; Pinta el interior del marco del juego
;--------------------------------------------------
    ;; cuadrado completo
    ;; comienza en 20 * 320 + 70 = 6470
    ;; sincronizar video con el fondo gris
    ;; en la posición de memoria 6470
    ;; la figura tiene una base de 180
    ;; se pintará 160 posiciones
    ;; la figura se leerá desde la posición 3600
    invoke syncBuffer, vram, 6470, 180, 160, 3600
    ret
printBackground endp

;--------------------------------------------------
playGame proc far c
; Controla las mecánicas del juego
;--------------------------------------------------
    mov al, 7                            ;; codigo asignado al color gris
    mov dx, vram
    mov es, dx                           ;; carga la dirección de memoria para el doble buffer
    xor di, di
    mov cx, 32400
    cld                                  ;; limpia el registro de flags
    rep stosb                            ;; pinta de gris el escenario
    ret
playGame endp
end