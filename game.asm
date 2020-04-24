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
    car             db 1800 dup(0)       ;; almacena el modelo del carro
    good            db 900 dup(0)        ;; almacena el modelo del bloque bueno
    bad             db 900 dup(0)        ;; almacena el modelo del bloque malo
    carFN           db "car.otz", 00     ;; archivo que DEBE de existir
    goodFN          db "good.otz", 00    ;; archivo que DEBE de existir
    badFN           db "bad.otz", 00     ;; archivo que DEBE de existir
    fileHandler     dw ?                 ;; manejador de archivo
    headerG         db " "
    userStr         db "user1     "
    levelStr        db "n1          "
    scoreStr        db "        "
    horaG           db "00:"
    minuG           db "00:"
    segsG           db "00 "
    bottomP         db "                  PLAY                  "
    bottomU         db "                  PAUSE                 "
    bottomG         db "                GAME OVER               "
    randomSeed      dd ?
    gameloaded      db 0            ;; determina si ya se ha cargado el juego
    lvlStr          db 60 dup(0)    ;; almacenará el nombre de los niveles
    lvlsDur         db 6 dup(0)     ;; almacenará la duración de cada nivel
    lvlsPenalty     db 6 dup(0)     ;; almacenará los puntos negativos
    lvlsScore       db 6 dup(0)     ;; almacenará los puntos positivos
    lvlsPenDur      db 6 dup(0)     ;; almacenará el temporizador para los bloque negativos
    lvlsScoDur      db 6 dup(0)     ;; almacenará el temporizador para los bloques positivos
    lvlsColor       db 6 dup(0)     ;; almacena el literal que especifica el color del carro
    charBuffer      db 1            ;; var auxiliar para almacenar un byte
    ;--------------------------------------------------
    ; Datos del nivel actual
    ;--------------------------------------------------
    penaltyScore    db ?            ;; indicará cuantos pts perderá por bloque enemigo
    rewardScore     db ?            ;; indicará cuantos pts ganará por bloque amigo
    penaltyScoreDur db ?            ;; indicará el temporizador para el bloque enemigo
    rewardScoreDur  db ?            ;; indicará el temporizador para el bloque enemigo
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
toAsciiT proc near c uses eax ebx ecx edx esi edi, toVar : ptr word
; Debe existir un valor previamente cargado en ax
; Comvierte a ascii la hora dada por la variables con offset toVar
;--------------------------------------------------
    xor cx, cx                      ;; limpia el conteo
    mov bx, 10
    xor dx, dx
    xor si, si
    _toAscii1:                      ;; convierte a decimal
        cmp ax, 0                   ;; el dividendo es 0?
        jz _toAscii2                ;; salta a mostrarlo en la variable toVar
        cwd
        div bx                      ;; dividen dentro de 10
        push dx                     ;; guarda el residuo
        xor dx, dx
        inc cx
        jmp _toAscii1
    _toAscii2:
        mov bx, toVar               ;; especifica la variable en dónde se alojará
        cmp cx, 2
        jz _toAscii3                ;; hay dos digitos
        mov al, '0'
        mov [bx], al                ;; solo hay un digito, coloca un 0
        mov si, 1                   ;; se mueve a la pos de unidad
    _toAscii3:
        pop ax                      ;; recupera el valor
        add ax, '0'                 ;; le suma '0'
        mov [bx + si], al
        inc si
        dec cx
        jnz _toAscii3
    ret
toAsciiT endp

;--------------------------------------------------
copyLevelName macro idx
; Dado el valor de idx, copia el el nombre alojado en 
; lvlStr a levelStr
;--------------------------------------------------
    local _cLN1, _cLN2
    push cx
    push di
    push si
    push ax
    push bx
    mov cx, 10
    mov bx, idx
    shl bx, 1
    mov si, bx
    shl bx, 2
    add si, bx
    xor di, di
    _cLN1:
        mov al, lvlStr[si]      ;; recupera un caracter del nombre del nivel
        cmp al, 0               ;; el valor es nulo
        jz _cLN2
        mov levelStr[di], al    ;; lo copia al encabezado
        inc si
        inc di
        loop _cLN1
    _cLN2:
    mov ah, ':'
    mov levelStr[di], ah
    mov ax, idx
    xor ah, ah
    add al, '0'
    mov levelStr[di + 1], al
    pop bx
    pop ax
    pop si
    pop di
    pop cx
endm

;--------------------------------------------------
setColor proc near c uses eax ebx ecx edx esi edi, idx : word
; Modifica la paleta de colores dada el color
; que se especifica en lvlsColor
;--------------------------------------------------
    local green : byte, red : byte, blue : byte
    mov green, 0
    mov red, 0
    mov blue, 0
    mov dx, 3c8h
    mov al, 25
    out dx, al
    inc dx
    mov si, idx
    mov al, lvlsColor[si]           ;; recupera la literal
    cmp al, 'r'
    jz _rojo
    cmp al, 'b'
    jz _blanco
    cmp al, 'v'
    jz _verde
    cmp al, 'a'
    jz _azul
    jmp _setColorEnd
    _rojo:
        mov red, 60
        jmp _setColor1
    _blanco:
        mov green, 255
        mov red, 255
        mov blue, 255
        jmp _setColor1
    _azul:
        mov blue, 60
        jmp _setColor1
    _verde:
        mov green, 60
    _setColor1:
        mov al, red
        out dx, al
        mov al, green
        out dx, al
        mov al, blue
        out dx, al
    _setColorEnd:
    ret
setColor endp

;--------------------------------------------------
validateNumber proc near c uses eax ebx, charrOff : word
; Convierte un número ascci en un número real
;--------------------------------------------------
    local temp : word
    mov temp, 0                     ;; inicializa la variable local
    mov dh, '0'
    mov dl, '9'
    mov si, charrOff                ;; establece el offset para es
    .while (es:[si] >= dh && es:[si]  <= dl)
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
    ; Carga info y reinicia variables
    mov di, 0
    mov actualLevel, 1                    ;; comienza en nivel 1
    mov al, lvlsPenalty[di]
    mov penaltyScore, al                  ;; punteo menos para nivel 1
    mov al, lvlsScore[di]
    mov rewardScore, al                   ;; punteo más para nivel 1
    mov al, lvlsPenDur[di] 
    mov penaltyScoreDur, al               ;; temporizador para bloque enemigo
    mov al, lvlsScoDur[di] 
    mov rewardScoreDur, al                ;; temporizador para bloque amigo
    xor ax, ax
    mov al, lvlsDur[di]
    mov actualLvlDur, ax                  ;; temporizador para el nivel actual
    invoke setColor, 0                    ;; coloca el color según la pos 0
    copyLevelName 0                       ;; copia el valor para el nivel uno
    ; reserva la memoria para la pista
    mov ah, 48h
    mov bx, 2025
    int 21h
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
loadLine proc far c uses eax ebx ecx edx esi edi, nameFile : word
; nameFile : fileHandler
; Solicita la ruta de un archivo que deberá contener
; la información del juego
;--------------------------------------------------
    local i : word, charAux : word , j : word
    mov i, 0
    mov j, 0
    mov charAux, 0
    flushStr lvlsDur, 6, 0 
    flushStr lvlsPenalty, 6, 0 
    flushStr lvlsScore, 6, 0 
    flushStr lvlsPenDur, 6, 0 
    flushStr lvlsScoDur, 6, 0 
    flushStr lvlsColor, 6, 0 
    flushStr lvlStr, 60, 0 
    mov ah, 48h
    mov bx, 5                       ;; 5 * 16 = 80 bytes
    int 21h
    mov charAux, ax                 ;; almacena dram
    mov es, ax                      ;; inicializa data extra
    mov cx, 80                      ;; establece el número de repeticiones para el loop
    xor di, di
    xor ax, ax
    _getLine0:                      ;; llena de 0 la memoria alojada
        mov es:[di], al
        inc di
        loop _getLine0
    xor di, di
    _getLine1:                      ;; recupera una línea de información
        readFile nameFile, charBuffer, 1  ;; lee un caracter
        mov dx, j                   ;; determina si se ha reiniciado el indice (i)
        cmp dx, 6               
        jge _getLine6               ;; lee hasta 6 líneas
        cmp ax, 0                   ;; se leyó algo?
        jnz _getLine11
        mov dx, i
        cmp dx, 0
        jz _getLine6                ;; termina el procedimiento
        jnz _getLine3               ;; i != 0, hay info en charAux
    _getLine11:                     ;; copia en data extra la linea de info del nivel
        mov al, charBuffer          ;; recupera el caracter leído
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
    _getLine3:                      ;; llena las variables con la info recuperada
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
            mov dl, 'r'
            mov dh, 'R'
            cmp es:[70], dl
            jnz _esVerde
            cmp es:[70], dh
            jnz _esVerde
            mov al, 'r'
            mov lvlsColor[di], al       ;; guarda el color del auto
        _esVerde:
            mov dl, 'v'
            mov dh, 'V'
            cmp es:[70], dl
            jnz _esAzul
            cmp es:[70], dh
            jnz _esAzul
            mov al, 'v'
            mov lvlsColor[di], al       ;; guarda el color del auto
        _esAzul:
            mov dl, 'a'
            mov dh, 'A'
            cmp es:[70], dl
            jnz _esBlanco
            cmp es:[70], dh
            jnz _esBlanco
            mov al, 'a'
            mov lvlsColor[di], al       ;; guarda el color del auto
        _esBlanco:
            mov dl, 'b'
            mov dh, 'B'
            cmp es:[70], dl
            jnz _getLine7
            cmp es:[70], dh
            jnz _getLine7
            mov al, 'b'
            mov lvlsColor[di], al       ;; guarda el color del auto
        _getLine7:
            shl di, 1                   ;; multiplica por dos
            mov bx, di                  ;; guarda el valor di*2
            shl di, 2                   ;; multiplica por ocho
            add bx, di                  ;; obtiene di*10
            mov di, bx                  ;; determina el registro index
            mov cx, 10
            xor si, si                  ;; la pos 0 contiene el nombre del nivel
            _getLine4:                  ;; copia el nombre del nivel
                mov al, es:[si]         ;; recupera un caracter
                cmp al, 0               ;; es nulo?
                jz _getLine5            ;; termina el ciclo
                mov lvlStr[di], al      ;; almacena un caracter desde di
                inc di
                inc si
                loop _getLine4          ;; repetir = 10
            _getLine5:                  ;; repite el proceso
                xor di, di
                mov cx, 80              ;; establece el número de repeticiones para el loop
                inc j                   ;; aumenta j
                jmp _getLine0
    _getLine6:
        mov gameloaded, 1
        mov ax, charAux
        mov es, ax
        mov ah, 49h
        int 21h
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
    int 10h                 ;; coloca el cursor en [0][0]
    mov cx, 40
    xor si, si
    mov bx, offset headerG
    _printHeader1:
        printChar [bx + si] ;; imprime el encabezado
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
    int 10h                 ;; coloca el cursor en [24][0]
    mov cx, 40
    xor si, si
    movsx bx, playState
    .if (bx == 0)           ;; jugando
        mov bx, offset bottomP
    .elseif (bx == 1)      ;; pausado
        mov bx, offset bottomU
    .elseif (bx == 2)      ;; game over
        mov bx, offset bottomG
    .endif
    _printFooter1:
        printChar [bx + si]
        inc si
        loop _printFooter1  ;; imprime el estado del juego
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
        jge _printF12
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
; Utiliza la variable que almacena el modelo como doble buffer
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
    shl ax, 2               ;; ax * 4
    mov bx, ax
    shl ax, 1               ;; ax * 4 * 2
    add bx, ax
    mov offPos, ax
    cmp bType, 1
    jz  _printEnemy         ;; es un enemigo
        mov si, offset good
    jmp _printOEnd
    _printEnemy:
        mov si, offset bad
    _printOEnd:
        mov dx, vram
        mov es, dx          ;; indica la pos de mem destino
        _printObsSync:
            mov bx, i
            cmp bx, 20
            jge _printObsSync1
            shl bx, 2       ;; i * 4
            mov ax, bx      ;; i * 4
            shl bx, 2       ;; i * 4 * 4
            add ax, bx      ;; i * 4 + i * 16
            shl bx, 1       ;; i * 4 * 4 * 2
            add ax, bx      ;; i * 4 + i * 16 + i * 32
            shl bx, 2       ;; i * 4 * 4 * 2 * 4
            add ax, bx      ;; i * 4 + i * 16 + i * 32 + i * 128
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
timeComposing proc near c uses eax ebx ecx edx
; Compone el tiempo transcurrido en hh:mm:ss
;--------------------------------------------------
    mov ax, actualTime
    mov bx, 60
    xor dx, dx
    .while (ax != 0)
        cwd
        div bx
        push dx
        xor dx, dx
        inc cx
    .endw
    .if (cx == 3)               ;; recupera horas
        pop ax
        invoke toAsciiT, offset horaG
        dec cx
    .endif
    .if (cx == 2)               ;; recupera minutos
        pop ax
        invoke toAsciiT, offset minuG
        dec cx
    .endif
    .if (cx == 1)               ;; recupera segundos
        pop ax
        invoke toAsciiT, offset segsG
        dec cx
    .endif
    ret
timeComposing endp

;--------------------------------------------------
rand proc near c uses eax ebx ecx edx
; Genera un número aleatorio utilizando 
; el algoritmo de generador lineal congruencial (GLC)
; Xn+1 = (aXn + c) % m
; randomSeedn+1 = (randomSeed*48271 + 1) % (2^31)
;--------------------------------------------------
    xor edx, edx
    mov eax, randomSeed
    mov ebx, 48271
    mul ebx
    add eax, 1
    mov ebx, eax                ;; obtiene el modulo de la forma:
    and ebx, 080000000h          ;; dividendo - (divisor * cociente) = residuo
    sub eax, ebx
    mov randomSeed, eax
    ret
rand endp

carCollision proc near c uses eax ebx ecx edx

    ret
carCollision endp

;--------------------------------------------------
playGame proc far c uses eax ebx ecx edx esi edi 
; Controla las mecánicas del juego
;--------------------------------------------------
    local dRef : word, dKey : word, dCtTime : word, tempPos : word
    mov dRef, 0
    mov playState, 0                     ;; estado actual  = 0 <-> jugando
    mov tempPos, 0
    xor ecx, ecx
    xor edx, edx
    mov ah, 0
    int 1ah
    shl ecx, 16                          ;; ahora cx, está en la parte alta de ecx
    add ecx, edx                         ;; suma la parte baja de ecx
    mov randomSeed, ecx                  ;; para números aleatorios
    mov al, 7                            ;; codigo asignado al color gris
    mov dx, vram
    mov es, dx                           ;; carga la dirección de memoria para el doble buffer
    xor di, di
    mov cx, 32400
    cld                                  ;; limpia el registro de flags
    rep stosb                            ;; pinta de gris el escenario
    call printFrame                      ;; pinta el marco del juego
    _playGame1:
        ;--------------------------------------------------
        ; Actualiza el contador de tiempo
        ;--------------------------------------------------
            mov bx, dCtTime
            add bx, 18                      ;; se ejecuta cada 18 ticks
            mov ah, 0
            int 1ah                         ;; recupera el número de ticks 
            cmp dx, bx
            jle _playGame1                  ;; dx <= bx --> _playGame1
            mov dCtTime, dx                 ;; actualiza el número de ticks
            inc actualTime                  ;; aumenta el numero de segundos
            call timeComposing              ;; compone el contador a la forma hh:mm:ss
            call printHeader                ;; actualiza el encabezado
        ;--------------------------------------------------
        ; Actualiza el nivel
        ;--------------------------------------------------
            _playGame1:
                mov bx, actualTime
                cmp bx, actualLvlDur
                jl _playGame2               ;; bx < actualLvlDur --> 
                movsx di, actualLevel
                cmp di, 6
                jz                          ;; si es igual a 6, se salta a game over
                xor ax, ax
                mov al, lvlsDur[di]
                cmp al, 0
                jz                          ;; si es 0, se salta a game over
                add actualLvlDur, ax        ;; temporizador para el nivel actual
                mov al, lvlsPenalty[di]
                mov penaltyScore, al        ;; punteo menos para nivel di
                mov al, lvlsScore[di]
                mov rewardScore, al         ;; punteo más para nivel di
                mov al, lvlsPenDur[di] 
                mov penaltyScoreDur, al     ;; temporizador para bloque enemigo
                mov al, lvlsScoDur[di] 
                mov rewardScoreDur, al      ;; temporizador para bloque amigo
                invoke setColor, di         ;; coloca el color según la pos 0
                copyLevelName, di           ;; indica el nombre de nivel
                call printHeader
                inc actualLevel             ;; incrementa el nivel
        ;--------------------------------------------------
        ; Colocar nuevo obstáculo
        ;--------------------------------------------------
            _playGame2:
                mov ax, actualTime
                xor dx, dx
                movsx bx, penaltyScoreDur
                cwd
                div bx
                cmp dx, 0
                jnz _playGame4              ;; si el residuo no es 0, salta
            _playGame3:
                call rand                   ;; actualiza randomSeed
                mov eax, randomSeed
                xor edx, edx
                mov ebx, 9
                cdq
                div ebx                     ;; divide dentro de nueve
                cmp dx, tempPos
                jz _playGame3               ;; si es igual, calculará otro número
                mov tempPos, dx             ;; aloja el reusltado
                invoke printObs, dx, 1      ;; pinta un enemigo 
            _playGame4:
                mov ax, actualTime
                xor dx, dx
                movsx bx, rewardScoreDur
                cwd
                div bx
                cmp dx, 0
                jnz _playGame6              ;; si el residuo no es 0, salta
            _playGame5:
                call rand                   ;; actualiza randomSeed
                mov eax, randomSeed
                xor edx, edx
                mov ebx, 9
                cdq
                div ebx                     ;; divide dentro de nueve
                cmp dx, tempPos
                jz _playGame5               ;; si es igual, calculará otro número
                mov tempPos, dx             ;; aloja el reusltado
                invoke printObs, dx, 0      ;; pinta un amigo
        ;--------------------------------------------------
        ; Actualiza la pista
        ;--------------------------------------------------
            _playGame6:
                call scrollBackground
        ;--------------------------------------------------
        ; Lee el teclado
        ;--------------------------------------------------
            _playGame4:
                mov ah, 01h
                int 16h
                jz _screenRefresh           ;; salta a la sig acción
            _playGame5:
                mov ah, 0h
                int 16h
                mov bl, playState           ;; carga el estado del juego
                .if (ah == 1h)              ;; tecla ESC
                    .if (bl == 1)           ;; esta pausado
                        mov playState, 0    ;; jugando
                    .else                   ;; no está pausado
                        mov playState, 1    ;; pausado
                    .endif
                .elseif (ah == 4dh && bl == 0)        ;; flecha derecha
                    mov bx, pointc
                    .if (bx != 249)         ;; limite derecho
                        inc pointc          ;; incrementa la posicion en columna
                    .endif
                .elseif (ah == 4bh && bl == 0)        ;; flecha izquierda
                    mov bx, pointc
                    .if (bx != 70)          ;; limite izquierdo
                        dec pointc          ;; decrementa la posicion en columna
                    .endif
                .elseif (ah == 39h)        ;; barra espaciadora
                    jmp                    ;; game over
                .endif
        ;--------------------------------------------------
        ; Determina colisión
        ;--------------------------------------------------












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