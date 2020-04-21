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
    headerG         db " "
    userStr         db "user1     "
    levelStr        db "n1        "
    scoreStr        db "          "
    horaG           db "00:"
    minuG           db "00:"
    segsG           db "00 "
    bottomP         db "                  PLAY                  "
    bottomU         db "                  PAUSE                 "
    bottomG         db "                GAME OVER               "
    lvlStr          db "          " ;; nivel 1
                    db "          " ;; nivel 2
                    db "          " ;; nivel 3
                    db "          " ;; nivel 4
                    db "          " ;; nivel 5
                    db "          " ;; nivel 6
    randomSeed      dw ?
    gameloaded      db 0
    lvlsName        db 60 dup(0)    ;; almacenará el nombre de los niveles
    lvlsDur         db 6 dup(0)     ;; almacenará la duración de cada nivel
    lvlsPenalty     db 6 dup(0)      ;; almacenará los puntos negativos
    lvlsScore       db 6 dup(0)     ;; almacenará los puntos positivos
    lvlsPenDur      db 6 dup(0)     ;; almacenará el temporizador para los bloque negativos
    lvlsScoDur      db 6 dup(0)     ;; almacenará el temporizador para los bloques positivos
    tempNumber      dw ?            ;; var auxiliar para el manejo de numeros
    strBuff         db 10 dup(0)    ;; var auxiliar para el manejo de números
    ;--------------------------------------------------
    ; Datos del nivel actual
    ;--------------------------------------------------
    penaltyScore    dw ?            ;; indicará cuantos pts perderá por bloque enemigo
    rewardScore     dw ?            ;; indicará cuantos pts ganará por bloque amigo
    penaltyScoreDur dw ?            ;; indicará el temporizador para el bloque enemigo
    rewardScoreDur  dw ?            ;; indicará el temporizador para el bloque enemigo
    actualLevel     db 1            ;; número <-> nivel actual 
    ;--------------------------------------------------
    ; Datos del juego actual
    ;--------------------------------------------------
    actualScore     dw 3            ;; número <-> punteo actual
    actualTime      dw 0            ;; número <-> seg jugando
    actualLvlDur    dw ?            ;; número <-> duración nivel actual
    playState       db ?            ;; indica el estado actual del juego
.code

;--------------------------------------------------
toAsciiT macro fromVar, toVar
; Comvierte a ascii la hora dada por la variables con offset toVar
;--------------------------------------------------
    pushad
    mov ax, fromVar
    mov bx, 10
    xor dx, dx
    xor si, si
    _toAscii1:
        cmp ax, 0
        jz _toAscii2
        cwd
        div bx
        push dx
        xor dx, dx
        inc cx
        jmp _toAscii1
    _toAscii2:
        cmp cx, 2
        jz _toAscii3
        mov bx, fromVar
        mov [bx], '0'
        mov si, 1
    _toAscii3:
        pop ax
        add ax, '0'
        mov [bx + si], ax
        inc si
        loop _toAscii3
    popad
endm

;--------------------------------------------------
validateNumber proc near c uses eax ebx, charrOff : word
; Convierte un número ascci en un número real
;--------------------------------------------------
    local temp : word
    mov temp, 0                     ;; inicializa la variable local
    mov si, charrOff                ;; establece el offset para es
    .while (es:[si] >= '0' && es:[si]  <= '9')
        mov ax, temp                ;; recupera el valor de temp
        shl ax, 1                   ;; multiplica por dos
        mov bx, ax                  ;; almacena el valor anterior
        shl ax, 2                   ;; multiplica por ocho
        add ax, bx                  ;; suma ax y bx -> temp * 10
        xor bx, bx                  ;; limpia bx
        mov bl, es:[si]             ;; mueve el valor en es:[si]  a bl
        sub bl, '0'                 ;; le resta el valor ascii de '0'
        add ax, bx                  ;; y se le suma al valor alojado en ax
        mov temp, ax                ;; guarda el valor en temp
        inc si                      ;; incrementa el indice de origen
    .endw
    mov dx, temp
    ret
validateNumber endp

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
loadGame proc far c uses eax ebx ecx edx esi edi, namefile : word
; nameFile : fileHandler
; Solicita la ruta de un archivo que deberá contener
; la información del juego
;--------------------------------------------------
    local char : byte, charAux : word
    mov ah, 48h
    mov bx, 
    _loadGame1:
        getLine namefile, bufferLine      ;; recupera una línea de info
        cmp ax, 0                   ;; determina si ya es fin de archivo
        jz                          ;; terminó de leer el archivo
        mov al, char                ;; recupera el caracter leído
        cmp al, 0ah                 ;; determina si es final de línea
    getLine nameFile                ;; recupera una linea
    ret
loadGame endp

loadLine proc near c uses ebx ecx edx esi edi, nameFile : word
    local i : word, charAux : word, char : byte
    mov char, 0
    mov i, 0
    mov charAux, 0
    mov ah, 48h
    mov bx, 5                       ;; 5 * 16 = 80 bytes
    int 21h
    mov charAux, ax                 ;; almacena dram
    mov es, ax                      ;; inicializa data extra
    mov cx, 80
    xor di, di
    _getLine0:
        mov es:[di], 0
        inc di
        loop _getLine0
    xor si, si
    xor di, di
    _getLine1:
        readFile nameFile, char, 1  ;; lee un caracter
        cmp ax, 0                   ;; se leyó algo?
        jz _getLine                 ;; termina el procedimiento
        mov al, char                ;; recupera el caracter leído
        cmp al, 0ah                 ;; es final de línea?
        jz _getLine3                ;; termina el ciclo actual
        cmp al, 59                  ;; es un punto y coma
        jnz _getLine2               ;; realiza un salto en dram
        inc i                       ;; aumenta el contador
        mov ax, i
        shl ax, 1                   ;; lo multiplica por dos
        mov bx, ax
        shl ax, 2                   ;; los multiplica por ocho
        add bx, ax                  ;; recupera el valor por 10
        mov di, bx                  ;; especifica el nuevo indice
        jmp _getLine1               ;; continua con el ciclo
        _getLine2:
        stosb                       ;; almacena el contenido de al en es:di
        jmp _getLine1               ;; continúa el ciclo
    _getLine3:
        xor ax, ax
        mov al, es:[10]             ;; recupera el nivel 
        sub al, '0'                 ;; recupera el número
        dec al                      ;; lo decrementa para obtener un índice válido
        mov di, ax                  ;; establece el indice
        invoke validateNumber, 20   ;; duración nivel
        mov lvlsDur[di], dl
        invoke validateNumber, 30   ;; tiempo obstáculos
        mov lvlsPenDur[di], dl
        invoke validateNumber, 40   ;; tiempo premio
        mov lvlsScoDur[di], dl
        invoke validateNumber, 50   ;; punteo obstáculos
        mov lvlsPenalty[di], dl
        invoke validateNumber, 60   ;; punteo premio
        mov lvlsScore[di], dl

    ret
loadLine endp

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
    mov bx, offset headerG
    _printHeader1:
        printChar [bx + si]
        inc si
        loop _printHeader1
    ret
printHeader endp

;--------------------------------------------------
printFooter proc near c uses eax ebx ecx edx es edi
; Pinta el pie de página que indica el estado del juego
;--------------------------------------------------
    mov ah, 02h
    mov bh, 0
    mov dx, 1800h
    int 10h
    mov cx, 40
    xor si, si
    mov bx, playState
    .if (bx == 0)           ;; jugando
        mov bx, offset bottomP
    .else if (bx == 1)      ;; pausado
        mov bx, offset bottomU
    .else if (bx == 2)      ;; game over
        mov bx, offset bottomG
    .endif
    _printFooter1:
        printChar [bx + si]
        inc si
        loop _printFooter1
    ret
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
timeComposing proc near c use eax ebx ecx edx
; Compone el tiempo transcurrido en hh:mm:ss
;--------------------------------------------------
    local sec : word, min : word, hrs : word
    mov sec, 0
    mov min, 0
    mov hrs, 0
    mov ax, actualTime
    mov bx, 60
    xor dx, dx
    .while(ax != 0)
        cwd
        div bx
        push dx
        xor dx, dx
        inc cx
    .endw
    .if (cx == 3) ;; recupera horas
        pop ax
        toAsciiT ax, offset horaG
        dec cx
    .endif
    .if (cx == 2) ;; recupera minutos
        pop ax
        toAsciiT min, offset minuG
        dec cx
    .endif
    .if (cx == 1) ;; recupera segundos
        pop ax
        toAsciiT hrs, offset segsG
        dec cx
    .endif
    ret
timeComposing endp

;--------------------------------------------------
playGame proc far c use eax ebx ecx edx esi edi 
; Controla las mecánicas del juego
;--------------------------------------------------
    local dRef : word, dKey : word, dCtTime : word
    mov dRef, 0
    mov playState, 0                     ;; estado actual  = 0 <-> jugando
    mov al, 7                            ;; codigo asignado al color gris
    mov dx, vram
    mov es, dx                           ;; carga la dirección de memoria para el doble buffer
    xor di, di
    mov cx, 32400
    cld                                  ;; limpia el registro de flags
    rep stosb                            ;; pinta de gris el escenario
    call printFrame                      ;; pinta el marco del juego
    _playThread:
        ;--------------------------------------------------
        ; Actualiza el contador de tiempo
        ;--------------------------------------------------
        mov bx, dCtTime
        add bx, 18                      ;; se ejecuta cada 18 ticks
        mov ah, 0
        int 1ah
        cmp dx, bx
        jle _levelRef
        mov dCtTime, dx                 ;; actualiza el número de ticks
        inc actualTime                  ;; aumenta el numero de segundos
        call timeComposing              ;; compone el contador a la forma hh:mm:ss
        ;--------------------------------------------------
        ; Actualiza el nivel
        ;--------------------------------------------------
        _levelRef:
            mov bx, actualTime
            cmp bx, actualLvlDur
            jl _putNewObs               ;; salta a la sig acción
            mov si, actualLevel
            cmp si, 6
            jz                          ;; si es igual a 6, se salta a game over
            shl si, 1                   ;; lo multiplica por dos
            inc si                      ;; obtiene el idx para levelsInfo
            mov ax, levelsInfo[si]      ;; obtiene el valor para la dur del sig nivel
            add bx, ax
            mov actualLvlDur, bx        ;; actualiza la duración de nivel
            inc actualLevel             ;; incrementa el nivel
        ;--------------------------------------------------
        ; Coloca un nuevo obstaculo
        ;--------------------------------------------------
        _putNewObs:

        ;--------------------------------------------------
        ; Check score
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