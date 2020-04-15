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
    headerG         db " user1     n1        000       00:00:00 "
    bottomP         db "                  play                  "
    bottomU         db "                  pause                 "
    bottomG         db "                game over               "
    ;--------------------------------------------------
    ; Datos del juego actual
    ;--------------------------------------------------
    levelsInfo      db 12 dup(0)
    penaltyScore    dw ?                 ;; indicará cuantos pts perderá por bloque enemigo
    rewardScore     dw ?                 ;; indicará cuantos pts ganará por bloque amigo
    actualUser      db dup(7)            ;; cadena <-> usuario que juega
    actualLevel     db 1                 ;; número <-> nivel actual 
    actualScore     dw 3                 ;; número <-> punteo actual
    actualTime      dw 0                 ;; número <-> seg jugando
    actualLvlDur    dw ?                 ;; número <-> duración nivel actual
.code

;--------------------------------------------------
initGame proc far c
; Carga lor modelos desde los archivos .otz
; Reserva la memoria para el doble buffer del escenario
; Carga la información del primer nivel
; Reinicia todas las variables globales del juego
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
    ; Carga info reinicia variables
    mov ax, levelsInfo                    ;; número de nivel
    mov actualLevel, ax
    mov ax, levelsInfo[1]                 ;; duración de nivel
    mov actualLvlDur, ax        
    mov actualScore, 0
    mov actalTime, 0
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
printHeader proc near c uses eax ebx ecx edx esi edi
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
printFooter proc near c uses eax ebx ecx edx es edi
; Pinta el pie de página que indica si el estado del juego
;--------------------------------------------------
printFooter endp

;--------------------------------------------------
printFrame proc near c
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
syncCar proc near c uses edi esi
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
syncCar endp

;--------------------------------------------------
printObs proc near c, pos : word, bType : byte
; POS :   BYTE indica la posición a donde pintar [0 - 8]
; BTYPE : BYTE indica el tipo de obstacula a pintar
;         0 - amigo 1 - enemigo
; Pinta un obstaculo puede ser pintado en 0, 20, 40, 60, 80, 100, 120, 140, 160
;--------------------------------------------------
    local i : word, offPos : word
    pushad
    push es
    push ds
    mov i, 0                ;; i = 0
    mov offPos, 0
    mov ax, pos
    mov bl, 20
    xor dx, dx              ;; limpia dx
    mul bl                  ;; pos * 20
    mov offPos, ax
    cmp bType, 1
    jz  _printEnemy         ;; es un enemigo
        mov dx, offset good
    jmp _printOEnd
    _printEnemy:
        mov dx, offset bad
    _printOEnd:
        mov ds, dx          ;; indica la pos de mem origen
        xor si, si
        mov dx, vram
        mov es, dx          ;; indica la pos de mem destino
        _printObsSync:
            mov bx, i
            cmp bx, 20
            jge _printObsSync1
            mov ax, 180     ;; 180
            xor dx, dx
            mul bx          ;; 180 * i
            add ax, offPos  ;; 180 * i + pos * 20
            mov di, ax
            mov cx, 20
            cld
            rep movsb
            inc i
            jmp _printObsSync
    _printObsSync1:
        pop ds
        pop es
        popad
        ret
printObs endp

;--------------------------------------------------
syncBackground proc near c uses edi esi
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
syncBackground endp

;--------------------------------------------------
scrollBackground proc near c 
; Actualiza la pantalla principal.
; Reemplaza los pixeles inferiores con los superiores
;--------------------------------------------------
    local i : word
    pushad
    push es
    push ds
    mov i, 0
    mov dx, vram
    mov ds, dx          ;; determina el origen
    mov es, dx          ;; determina el destino
    mov si, 32219       ;; indica el origen de la información 178 * 180 + 179
    mov di, 32399       ;; indica el destino de la información 179 * 180 + 179
    mov cx, 32220       ;; 180 * 179
    std                 ;; los indices se decrementeran
    rep movsb
    mov al, 7
    mov cx, 180
    std                 ;; el indice di se debe decrementar
    rep stosb           ;; la primera línea se pinta de color gris
    pop es
    pop es
    popad
    ret
scrollBackground endp

;--------------------------------------------------
playGame proc far c use eax ebx ecx edx esi edi 
; Controla las mecánicas del juego
;--------------------------------------------------
    local dRef : word, dKey : word, dCtTime : word, playState : byte
    mov dRef, 0
    mov playState, 0                     ;; estado actual  = 0 <-> jugando
    mov al, 7                            ;; codigo asignado al color gris
    mov dx, vram
    mov es, dx                           ;; carga la dirección de memoria para el doble buffer
    xor di, di
    mov cx, 32400
    cld                                  ;; limpia el registro de flags
    rep stosb                            ;; pinta de gris el escenario
    call printFrame                      ;; pinra el marco del juego
    _playThread:
        ;--------------------------------------------------
        ; Actualiza el contador de tiempo
        ;--------------------------------------------------
        mov bx, dCtTime
        add bx, 18                      ;; se ejecuta cada 18 ticks
        mov ah, 0
        int 1ah
        cmp dx, bx
        jle 
        mov dCtTime, dx                 ;; actualiza el número de ticks
        ;--------------------------------------------------
        ; Actualiza el nivel
        ;--------------------------------------------------
        _levelRef:
            mov bx, actualTime
        ;--------------------------------------------------
        ; Coloca un nuevo obstaculo
        ;--------------------------------------------------
        ;--------------------------------------------------
        ; Lee el teclado
        ;--------------------------------------------------
        _checkKeyBoard:
            mov ah, 01h
            int 16h
            jz _screenRefresh           ;; salta a la sig acción
        _readKeyBoard:
            mov ah, 0h
            int 16h
            mov bl, playState           ;; carga el estado del juego
            .if (ah == 1h)              ;; tecla ESC
                .if (bl == 1)           ;; esta pausado
                    mov playState, 0    ;; jugando
                .else                   ;; no está pausado
                    mov playState, 1    ;; pausado
                .endif
            .else if (ah == 4dh && bl == 0)        ;; flecha derecha
                mov bx, pointc
                .if (bx != 249)         ;; limite derecho
                    inc pointc          ;; incrementa la posicion en columna
                .endif
            .else if (ah == 4bh && bl == 0)        ;; flecha izquierda
                mov bx, pointc
                .if (bx != 70)          ;; limite izquierdo
                    dec pointc          ;; decrementa la posicion en columna
                .endif
            .else if (ah == 39h)        ;; barra espaciadora
                ;; escribirá la infoe en 
                ;; el archivo de informes
            .endif
        ;--------------------------------------------------
        ; Refresca la pantalla
        ;--------------------------------------------------
        _screenRefresh:
            mov bx, dRef
            add bx, 1                        ;; se ejecuta cada tick
            mov ah, 0
            int 1ah                          ;; recupera el contador del sistema
            cmp dx, bx                       ;; dx > bx
            jle _screenRefresh1              ;; no ha pasado los ticks suficientes
            mov dRef, dx                     ;; actualiza el dRef
            call scrollBackground            ;; actualiza el tablero
            call printHeader                 ;; imprime el texto
        _screenRefresh1:
            call syncBackground              ;; copia el tablero a la mem de video
            call syncCar                     ;; copia el carro a la mem de video
            jmp _playThread
    ret
playGame endp
end