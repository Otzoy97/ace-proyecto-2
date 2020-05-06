.model small, c
.386
.stack 400h
include p2lib.inc
include string.asm
include screen.asm
.data
    ln              db      "$"
    pressanykey     db      "  Presione cualquier tecla para continuar...$"
    blockWidth      dw      ?               ;; ancho del bloque
    maxHeigth       dw      ?               ;; valor máximo
    padding         dw      ?               ;; espacio entre bloques
    startPad        dw      ?               ;; offset al inicio
    col             dw      ?               ;; indica la columa en la que se debe pintar
    vram            dw      ?
    velocity        dw      ?               ;; [0-9]
    veloStr0        db      "  Ordenamientos disponibles:",0ah, 0dh
                    db      "  (1) Ordenamiento por Bubblesort",0ah, 0dh
                    db      "  (2) Ordenamiento por Quicksort",0ah, 0dh
                    db      "  (3) Ordenamiento por Shellsort",0ah, 0dh
                    db      "  (4) Regresar al men",163 ," del administrador",0ah, 0dh,0ah, 0dh
                    db      "  Elija una opci", 162,"n : $"
    veloStr         db      "  Ingrese la velocidad del ordenamiento [0,9]: $"
    veloSense       db      "  Especifique el sentido del ordenamiento:",0ah, 0dh
                    db      "  (1) Ascendente",0ah, 0dh
                    db      "  (2) Descendente",0ah, 0dh,0ah, 0dh
                    db      "  Elija una opci", 162,"n : $"
    wrongOpt        db      "  Opci",162,"n no v",160,"lida$"
    topScoreHeader  db      "               TOP  PUNTOS$"
    topTimesHeader  db      "               TOP TIEMPOS$"
    chooseOrd       dw      ?               ;; bubble = 0 ; quick = 1 ; shell = 2
    lineVar         db      50 dup(0)
    chooseOp1       db      "1$"
    chooseOp2       db      "2$"
    chooseOp3       db      "3$"
    chooseOp4       db      "4$"
    sortArray       dw      20 dup(?)       ;; alojará una copia del arreglo ha ordenar
    typeArrayG      dw      ?               ;; determina el tipo de arreglo 0 - score | 1 - times
    ;--------------------------------------------------
    ; Tiempo
    ;--------------------------------------------------
    headerSort      db      " ORD: "
    nameSort        db      "          "
                    db      "   TMP:  "
    minuG           db      "00:"
    segsG           db      "00"
                    db      "   VEL: "
    veloG           db      " $"
    actualVel       dw      ?               ;; aloja la velocidad del ordenamiento 
    quickName       db      "QUICKSORT",0
    bubleName       db      "BUBBLESORT",0
    shellName       db      "SHELLSORT",0
    numberChar      db      0,0,0,0,0,'$'
    actualTime      dw      0               ;; aloja el número de segundos transcurridos
    actualTicks     dw      ?               ;; aloja los ticks de reloj actual
    ;--------------------------------------------------
    ; Ordenamiento
    ;--------------------------------------------------
    sortType        dw      ?               ;; aloja el tiepo de ordenamiento ha realizar
    sense           dw      ?               ;; ascendente = 0 descedente = 1
    ;--------------------------------------------------
    ; QuickSort
    ;--------------------------------------------------
    quickDelay      dw      ?
.code

;--------------------------------------------------
; Convierte un número de 2 bytes a ascii
toAsciiA proc far c uses eax ebx ecx edx esi , number : word, off : ptr word
;--------------------------------------------------
    xor cx, cx
    xor dx, dx
    mov ax, number
    .if (ax == 0)
        mov bx, off
        mov al, '0'
        mov [bx], al
        ret
    .endif
    mov bx, 10
    .while( ax != 0)
        cwd
        div bx
        push dx
        xor dx, dx
        inc cx
    .endw
    mov bx, off
    xor si, si
    .while (cx != 0)
        pop ax
        add ax, '0'
        mov [bx + si], al
        inc si
        dec cx
    .endw
    ret
toAsciiA endp

;--------------------------------------------------
detHz proc near c, value : word
; Devuelve en ax el valor hz para producir un sonido
;--------------------------------------------------
    mov ax, value
    cmp ax, 20                      ;; hasta 20 
    jg _detHz1
        mov ax, 11931               ;; 100 Hz
    jmp _detHz5
    _detHz1:
    cmp ax, 40                      ;; hasta 40
    jg _detHz2
        mov ax, 3977                ;; 300 Hz
        jmp _detHz5
    _detHz2:
    cmp ax, 60                      ;; hasta 60
    jg _detHz3
        mov ax, 2386                ;; 500 Hz
        jmp _detHz5
    _detHz3:
    cmp ax, 80                      ;; hasta 80
    jg _detHz4
        mov ax, 1704                ;; 700 Hz
        jmp _detHz5
    _detHz4:                        ;; desde 81 en adelante
        mov ax, 1325                ;; 900 Hz
    _detHz5:
        ret
detHz endp

;--------------------------------------------------
mkSound proc near c uses eax ebx edx, value : word
; Realiza un pequeño pitido
;--------------------------------------------------
    local delaylocal : word
    mov ah, 0
    int 1ah
    mov delaylocal, dx              ;; actualiza los ticks
    mov al, 86h
    out 43h, al
    invoke detHz, value
    out 42h, al
    mov al, ah
    out 42h, al
    in al, 61h
    or al, 00000011b
    out 61h, al
    push ax
    _mkSound0:
        mov bx, delaylocal
        add bx, 1
        mov ah, 0
        int 1ah
        cmp dx, bx
        jg _mkSound1
        jmp _mkSound0
    _mkSound1:
        pop ax
        in al, 61h
        and al, 11111100b
        out 61h, al
    ret
mkSound endp

;--------------------------------------------------
detColor proc near c, value : word
; Devuelve en al el byte que representa el color con el 
; que se pintará un bloque
;--------------------------------------------------
    mov ax, value
    cmp ax, 20                      ;; hasta 20 
    jg _detColor1
        mov al, 40                  ;; color rojo
    jmp _detColor5
    _detColor1:
    cmp ax, 40                      ;; hasta 40
    jg _detColor2
        mov al, 1                   ;; color azul
        jmp _detColor5
    _detColor2:
    cmp ax, 60                      ;; hasta 60
    jg _detColor3
        mov al, 44                  ;; color amarillo
        jmp _detColor5
    _detColor3:
    cmp ax, 80                      ;; hasta 80
    jg _detColor4
        mov al, 2                   ;; color verde
        jmp _detColor5
    _detColor4:                     ;; desde 81 en adelante
        mov al, 15                  ;; color blanco
    _detColor5:
    ret
detcolor endp

;--------------------------------------------------
printBlock proc near c uses eax ebx ecx edx edi, value : word
; Escribe un bloque de color variable (según ::value::)
;--------------------------------------------------
    local startRow : word, i : word, colorl : byte
    mov startRow, 168
    mov i, 0
    xor ebx, ebx
    mov bx, value
    shl ebx, 3                      ;; x8
    mov eax, ebx
    shl ebx, 2                      ;; x32
    add eax, ebx
    shl ebx, 2                      ;; x128
    add eax, ebx
    xor edx, edx
    xor ebx, ebx
    mov bx, maxHeigth
    div ebx                         ;; z*168/maxHeigth
    mov i, ax
    dec i
    sub startRow, ax                ;; determina el offset para empezar a pintar
    mov ax, startRow
    shl ax, 6                       ;; x64
    mov bx, ax
    shl ax, 2                       ;; x256
    add bx, ax
    mov startRow, bx                ;; starRow * 320
    invoke detColor, value          ;; determina el color de los pixeles
    mov colorl, al
    mov dx, vram 
    mov es, dx
    _printBlock1:
        cmp i, 0                    ;; se sale cuando sea igual
        jle _printBlock2
        mov ax, i
        shl ax, 6                   ;; x64
        mov di, ax
        shl ax, 2
        add di, ax                  ;; x256
        add di, startRow
        add di, col
        mov al, colorl
        mov cx, blockWidth
        cld
        rep stosb
        dec i
        jmp _printBlock1
    _printBlock2:
        mov ax, blockWidth
        add col, ax
        mov ax, padding
        add col, ax
    ret
printBlock endp

;--------------------------------------------------
cleanVram proc near c uses eax ebx ecx edx esi esi
; Limpia la memoria de doble buffer
;--------------------------------------------------
    mov dx, vram
    mov es, dx
    xor di, di
    xor eax, eax
    mov cx, 13440                   ;; (168 * 320) / 4
    cld 
    rep stosd
    ret
cleanVram endp

;--------------------------------------------------
startVideo proc near c uses eax ebx
; Inicia el modo video e inicializa la memoria reservada
;--------------------------------------------------
    mov ah, 48h
    mov bx, 3360                        ;; (168 * 320) / 16
    int 21h
    mov vram, ax                        ;; indica la pos de mem
    call cleanVram
    mov ah, 00h
    mov al, 13h
    int 10h
    ret
startVideo endp 

;--------------------------------------------------
showUnsorted proc far c uses eax ebx ecx edx esi, arraytype : word
; Muestra una gráfica de barras que contiene todos
; los registros de usuarios
;--------------------------------------------------
    call startVideo                          ;; inicia el modo video
    mov ax, startPad
    mov col, ax                              ;; inicializa local_col
    xor si, si
    mov cx, noUsers
    mov bx, offset sortArray
    _showUnsorted2:
        mov ax, word ptr [bx + si]
        invoke printBlock, ax               ;; pinta las barras
        add si, 2
        loop _showUnsorted2
    ;; imprime en la memoria de video
    ;; imprime lo que está almacenado en vram
    ;; escribirá a la mem de video en pos 5120
    ;; se escribirán 320 bytes horizontalmente
    ;; y esos bytes se deberan escrbir 168 veces verticalmente
    ;; la vram se leerá desde la pos 0
    invoke syncBuffer, vram, 5120, 320, 168, 0
    mov ah, 02h
    xor bx, bx
    xor dx, dx
    int 10h                                 ;; coloca el cursor en la linea y columna 0
    mov ax, arraytype
    cmp ax, 0
    jnz _showUnsorted3
        printStr offset topScoreHeader      ;; pinta encabezado puntos
        jmp _showUnsorted4
    _showUnsorted3:
        printStr offset topTimesHeader      ;; pinta encabezado tiempo
    _showUnsorted4: 
    mov ax, blockWidth
    shr ax, 1                               ;; divide por 2
    add ax, startPad
    shr ax, 3                               ;; divide por 8
    cmp ax, 2
    jge _showUnsorted41 
        mov ax, 0                           ;; es menor a 2, pone 0
        jmp _showUnsorted42
    _showUnsorted41:
        sub ax, 2                           ;; es mayor o igual a 2, le resta 2
    _showUnsorted42:
    mov dh, 23                              ;; especifica la columna
    mov dl, al                              ;; escribe en la penúltima línea
    xor bx, bx
    mov ah, 02h
    int 10h                                 ;; mueve el cursor a [23][(startPad + blockWidth/2)/8 - 2]
    mov cx, noUsers
    mov bx, offset sortArray
    xor si, si                              ;; reinicia el indice
    _showUnsorted6:
        flushStr numberChar, 5, '$'
        mov ax, [bx + si]
        invoke toAsciiA, ax, offset numberChar
        printStr offset numberChar
        printChar 32
        add si, 2
        loop _showUnsorted6
    pauseSpaceKey
    ;call cleanVram
    clearScreen                             ;; regresa al modo texto
    ret
showUnsorted endp

;--------------------------------------------------
printHeaderA proc near c uses eax ebx edx
; Imprime el nombre del ordenamiento el tiempo transcurrido
; y la velocidad del ordenamiento
;--------------------------------------------------
    mov ah, 02h
    xor bx, bx
    xor dx, dx
    int 10h                                 ;; reposiciona el cursor
    printStr offset headerSort
    ret
printHeaderA endp

;--------------------------------------------------
toAsciiTA proc near c uses eax ebx ecx edx esi, toVar : ptr word
; Debe existir un valor previamente cargado en ax
; Comvierte a ascii la hora dada por la variables con offset toVar
;--------------------------------------------------
    xor cx, cx                      ;; limpia el conteo
    mov bx, 10
    xor dx, dx
    xor si, si
    .while (ax != 0)
        cwd
        div bx
        push dx
        xor dx, dx
        inc cx
    .endw
    mov bx, toVar
    .if (cx == 1)
        mov si, 1
    .endif
    .while (cx != 0)
        pop ax
        add ax, '0'
        mov [bx + si], al
        inc si
        dec cx
    .endw
    ret
toAsciiTA endp

;--------------------------------------------------
timeComposingA proc near c uses eax ebx ecx edx
; Compone el tiempo transcurrido en hh:mm:ss
;--------------------------------------------------
    flushStr minuG, 2, '0'
    flushStr segsG, 2, '0'
    mov ax, actualTime
    mov bx, 60
    xor dx, dx
    xor cx, cx
    .while (ax != 0)
        cwd
        div bx
        push dx
        xor dx, dx
        inc cx
    .endw
    .if (cx == 2)               ;; recupera minutos
        pop ax
        invoke toAsciiTA, offset minuG
        dec cx
    .endif
    .if (cx == 1)               ;; recupera segundos
        pop ax
        invoke toAsciiTA, offset segsG
        dec cx
    .endif
    ret
timeComposingA endp

;--------------------------------------------------
checkTimer proc near c uses eax ebx edx
; Actualiza el contador de actualTime y actualTicks
; Recupera el contador del sistemas y lo cambia cada
; 18 ticks
;--------------------------------------------------
    mov bx, actualTicks                     ;; recupera el número de ticks alojados
    add bx, 18                              ;; espera 18 ticks
    mov ah, 00h
    int 1ah 
    cmp dx, bx                              ;; dx > bx
    jle _checkTimer1
        mov actualTicks, dx                 ;; actualiza el número de ticks
        inc actualTime                      ;; incrementa en un segundo el contador
        mov ax, actualTime                  ;; carga el número de segundos
        call timeComposingA                 ;; actualiza el contador de min y seg
        call printHeaderA
    _checkTimer1:
    ret
checkTimer endp

;--------------------------------------------------
printFooterA proc near c uses eax ebx ecx edx esi
; Imprime los números que contiene el arreglo
;--------------------------------------------------
    mov ax, blockWidth
    shr ax, 1                               ;; divide por dos
    add ax, startPad
    shr ax, 3                               ;; divide por ocho
    cmp ax, 2
    jge _printFooter1
        mov ax, 0
        jmp _printFooter2
    _printFooter1:
        sub ax, 2
    _printFooter2:
    mov dh, 23                              ;; indica la columna
    mov dl, al
    xor bx, bx
    mov ah, 02h
    int 10h                                 ;; reposiciona el cursor
    mov cx, noUsers
    xor si, si
    mov bx, offset sortArray
    _printFooter3:
        flushStr numberChar, 5, '$'
        mov ax, word ptr [bx + si]
        invoke toAsciiA, ax, offset numberChar
        printStr offset numberChar
        printChar 32
        add si, 2
        loop _printFooter3
    ret
printFooterA endp

;--------------------------------------------------
graphSorted proc near c uses eax ebx ecx esi
; Grafica las barras del arreglo global
;--------------------------------------------------
    call cleanVram
    mov ax, startPad
    mov col, ax                                     ;; reinicia la columna
    xor si, si
    mov cx, noUsers
    mov bx, offset sortArray
    _graphSorted2:
        invoke printBlock, [bx + si]
        add si, 2
        loop _graphSorted2
    ;; imprime en la memoria de video
    ;; imprime lo que está almacenado en vram
    ;; escribirá a la mem de video en pos 5120
    ;; se escribirán 320 bytes horizontalmente
    ;; y esos bytes se deberan escrbir 168 veces verticalmente
    ;; la vram se leerá desde la pos 0
    invoke syncBuffer, vram, 5120, 320, 168, 0
    ret
graphSorted endp

;--------------------------------------------------
copyArray proc near c uses eax esi ecx
; Dado el tipo de array que especifica arrayType
; realiza una copia hacia sortArray
;--------------------------------------------------
    xor si, si
    mov cx, noUsers
    mov ax, typeArrayG                  ;; recupera el tipo de array
    cmp ax, 0
    jnz _copyArray0                     ;; realiza una copia exacta del arreglo de score
        _copyArray0_1:
            mov ax, usrScore1[si]
            mov sortArray[si], ax
            add si, 2
            loop _copyArray0_1
        jmp _copyArray1
    _copyArray0:                        ;; realiza una copia exacta del arreglo de time
        _copyArray0_2:
            mov ax, usrTime1[si]
            mov sortArray[si], ax
            add si, 2
            loop _copyArray0_2
    _copyArray1:
    ret
copyArray endp

;--------------------------------------------------
initArray proc far c uses eax ebx ecx edx, arraytype : word, maxValue : word
; Calcula el grosor de los bloques, el espaciado entre los bloques
; y el alto de los bloques
; arraytype = 0 -> Score
; arraytype = 1 -> Times
;--------------------------------------------------
    mov ax, maxValue
    mov maxHeigth, ax                   ;; establece el valor máximo para un bloque
    mov ax, arraytype
    mov typeArrayG, ax
    call copyArray                      ;; realiza una copia del arreglo deseado
    mov ax, 40                          ;; 2x20
    mov bx, noUsers
    cmp bx, 1
    jz _initArray3
        xor dx, dx
        div bx
        mov startPad, ax                ;; indica el espacio al inicio
        mov ax, 220                     ;; 11x20
        xor dx, dx
        div bx
        mov blockWidth, ax              ;; indica el ancho de las barras
        mov ax, 76                      ;; 4x19
        dec bx 
        xor dx, dx
        div bx
        mov padding, ax                 ;; indica el espacio entre barras
        jmp _initArray4
    _initArray3:
        mov blockWidth, 240
        mov padding, 0
        mov startPad, 40
    _initArray4:
    mov ax, arraytype
    invoke showUnsorted, ax             ;; muestra la grafica de barras
    ret
initArray endp

;--------------------------------------------------
bubbleSort proc far c uses eax ebx ecx edx esi
; Ordena de forma ascendente un arreglo que inicia 
; en statArr y de tamaño sizeArr
;--------------------------------------------------
    local loc_sense : word, localDelay : word, i : word, j : word
    mov ax, sense
    mov loc_sense, ax                       ;; especifica el sentido de ordenamiento
    mov ah, 00h
    int 1ah
    mov actualTicks, dx                     ;; inicializa el número de ticks
    mov localDelay, dx
    xor cx, cx
    xor si, si
    mov cx, noUsers                         ;; especifica el tamaño del arreglo
    dec cx                                  ;; disminiuye el tamaño del arreglo
    mov i, cx
    _bubbleSort0:
        cmp i, 0
        jz _bubbleSort8                     ;; termina el procedimiento
        xor si, si
        mov cx, i
        mov j, cx
        _bubbleSort1:
            cmp j, 0
            jz _bubbleSort7                 ;; continúa con la siguiente iteración
            _bubbleSort2:
                call checkTimer
                mov bx, localDelay
                add bx, actualVel
                mov ah, 0h
                int 1ah
                cmp dx, bx
                jg _bubbleSort3
            jmp _bubbleSort2
            _bubbleSort3:
                mov localDelay, dx
                mov ax, sortArray[si]
                cmp loc_sense, 0
                jnz _bubbleSort4                ;; es ascendente
                    cmp ax, sortArray[si + 2]
                    jl _bubbleSort6             ;; si es menor no hace nada
                    jmp _bubbleSort5
                _bubbleSort4:                   ;; es descendente
                    cmp ax, sortArray[si + 2]
                    jg _bubbleSort6             ;; si es mayor no hace nada
                _bubbleSort5:
                    xchg ax, sortArray[si + 2]
                    invoke mkSound, ax
                    mov sortArray[si], ax
                    call graphSorted
                    call printFooterA
            _bubbleSort6:
                add si, 2
                dec j
                jmp _bubbleSort1
        _bubbleSort7:
            dec i
            jmp _bubbleSort0
    _bubbleSort8:
    ret 
bubbleSort endp

;--------------------------------------------------
partition proc c uses ebx ecx edx esi edi, arrLow : word, arrHigh : word
;--------------------------------------------------
    local pivote : word, i : word, loc_sense : word, j : word
    mov ax, arrLow
    mov i, ax
    inc i                           ;; i = start + 1
    mov ax, sense
    mov loc_sense, ax    
    mov di, arrLow                  ;;especifica el indice para el pivote
    shl di, 1                       ;;multiplica por dos el limite inferior
    mov ax, sortArray[di]
    mov pivote, ax                  ;; piv = a[start]
    mov di, i
    mov j, di                       ;; j = start + 1
    _partition0:
        mov cx, j
        cmp cx, arrHigh             ;; j <= arrHigh
        jg _partition6
        _partition4:
            call checkTimer         ;; intentará actualizar el tiempo
            mov bx, quickDelay      ;; recupera el delay
            add bx, actualVel
            mov ah, 0h
            int 1ah                 ;; recupera los ticks del sistema
            cmp dx, bx
            jg _partition5          ;; ya transcurrió el tiempo suficiente
            jmp _partition4
        _partition5:
            mov quickDelay, dx      ;; actualiza los ticks
            mov si, j
            shl si, 1               ;; multiplica por dos
            mov ax, sortArray[si]
            cmp loc_sense, 0
            jnz _partition1
                cmp ax, pivote      ;; ascendente
                jge _partition3
                jmp _partition2
            _partition1:
                cmp ax, pivote      ;; descedente
                jle _partition3
        _partition2:
            mov si, j               ;; recupera los indices
            mov di, i
            shl si, 1               ;; multiplica por dos
            shl di, 1
            mov ax, sortArray[di]   ;; intercambia sortArray[di], sortArray[si]
            invoke mkSound, ax
            xchg sortArray[si], ax
            mov sortArray[di], ax
            inc i                   ;; i++
            call graphSorted
            call printFooterA
        _partition3:
            inc j                   ;; j++
            jmp _partition0
    _partition6:
        call checkTimer
        mov bx, quickDelay
        add bx, actualVel
        mov ah, 0h
        int 1ah
        cmp dx, bx
        jg _partition7
        jmp _partition6
    _partition7:
        mov quickDelay, dx          ;; actualiza los ticks
        mov di, i                   ;; recupera el indice
        shl di, 1                   ;; multiplica por dos
        sub di, 2                   ;; i = i - 1
        mov si, arrLow              ;; start
        shl si, 1                   ;; start
        mov ax, sortArray[si]
        invoke mkSound, ax
        xchg sortArray[di], ax
        mov sortArray[si], ax
        call graphSorted
        call printFooterA
        mov ax, i                   ;; mueve a ax el retorno de (i - 1)
        dec ax
        ret
partition endp

;--------------------------------------------------
quickSort proc far c uses eax, arrLow: word, arrHigh: word
; Ordena de forma ascendente el arreglo de startArr
; y que comienza en arrLow y termina en arrHigh
;--------------------------------------------------
    local pidx : word
    mov pidx, 0             ;; inicializa la variable
    mov ax, arrLow          
    cmp ax, arrHigh         ;; compara el limite superior con el inferior
    jge qSEnd               ;; si es mayor o igual termina el procedimiento
        xor ax, ax          ;; ax contendrá el valor de retorno, se limpia
        invoke partition, arrLow, arrHigh
        mov pidx, ax        ;; almacena el pivote
        dec pidx            ;; decrementa el contador
        invoke quickSort, arrLow, pidx
        add pidx, 2         ;; reestablece y aumenta el indice
        invoke quickSort, pidx, arrHigh
    qSEnd:
    ret
quickSort endp

;--------------------------------------------------
shellSort proc far c uses eax ebx ecx edx esi edi, arrLength : word
; Ordena de forma ascendente el arreglo de starArr
; utilizando el algoritmo de shellsort
;--------------------------------------------------
    local temp : word, j : word, gap : word, i: word, localDelay : word
    mov temp, 0
    mov j, 0
    mov ax, arrLength
    shr ax, 1                           ;; divide dentro de dos
    mov gap, ax  
    mov i, 0
    ;--------------------
    mov ah, 0
    int 1ah
    mov localDelay, dx                  ;; inicializa los tiks
    mov actualTicks, dx
    _shell1:
        call checkTimer
        mov cx, gap             
        cmp cx, 0                       ;; gap > 0
        jle _shell6                     ;; termina _shell1
        mov i, cx                       ;; i = gap
        _shell2:
            mov cx, i                   ;; i
            cmp cx, arrLength           ;; i < n
            jge _shell5                 ;; termina _shell2
            mov di, cx                  ;; di = cx = i
            shl di, 1                   ;; multiplica por dos
            mov bx, sortArray[di]
            mov temp, bx
            ;--------------------
            mov ax, i
            mov j, ax
            _shell3:
                mov cx, j
                cmp cx, gap             ;; j >= gap
                jl _shell4              ;; termina shell3
                mov di, gap
                mov si, j
                shl di, 1       
                shl si, 1               ;; lo multiplica por dos
                sub si, di              ;; j - gap
                mov ax, sortArray[si]   ;; arr[j -gap]
                mov cx, temp            ;; temp
                mov dx, sense   
                    cmp dx, 0                   ;; es ascendente        
                    jnz _shellSort4
                        cmp ax, cx              ;; arr[j - gap] > temp
                        jle _shell4             ;; termina shell3
                        jmp _shellSort5
                    _shellSort4:                ;; es descendente
                        cmp ax, cx              ;; arr[j - gap] < temp
                        jge _shell4
                    _shellSort5:
                mov di, j
                shl di, 1               ;; lo multiplica por dos
                mov ax, sortArray[si]
                push ax
                mov sortArray[di], ax
                _shellSort0:
                    call checkTimer
                    mov bx, localDelay
                    add bx, actualVel
                    mov ah, 0h
                    int 1ah
                    cmp dx, bx
                    jg _shellSort1
                    jmp _shellSort0
                _shellSort1:
                    mov localDelay, dx
                    pop ax
                    invoke mkSound, ax
                    call graphSorted
                    call printFooterA
                ;--------------------
                mov di, gap             ;; gap
                mov si, j               ;; j
                sub si, di              ;; j = j - gap
                mov j, si
                jmp _shell3
            _shell4:
            mov si, j
            shl si, 1                   ;; multiplica por dos
            mov ax, temp
            push ax
            mov sortArray[si], ax
            _shellSort2:
                call checkTimer
                mov bx, localDelay
                add bx, actualVel
                mov ah, 0h
                int 1ah
                cmp dx, bx
                jg _shellSort3
                jmp _shellSort2
            _shellSort3:
                mov localDelay, dx
                pop ax
                invoke mkSound, ax
                call graphSorted
                call printFooterA
            ;--------------------
            inc i                       ;; i++
            jmp _shell2         
        _shell5:
            mov ax, gap
            shr ax, 1                   ;; lo divide dentro de 2
            mov gap, ax
            jmp _shell1
    _shell6:
        ret
shellSort endp

;--------------------------------------------------
showSorted proc near c uses eax ebx ecx edx
; Realiza el mismo procedimiento que showUnsorted
;--------------------------------------------------
    flushStr minuG, 2, '0'                      ;; reinicia
    flushStr segsG, 2, '0'                      ;; reinicia
    mov actualTime, 0                           ;; reinicia
    mov ax, 13h
    int 10h                                     ;; entra al modo video
    call graphSorted
    call printHeaderA                            ;; imprime el encabezado
    call printFooterA                            ;; imprime el pie de página 
    pauseSpaceKey                               ;; espera por presionar tecla espaciadora
    mov bx, sortType                            ;; carga el tipo de ordenamiento
    cmp bx, 0                                   ;; es bubblesort
    jnz _showSorted71
        call bubbleSort
    jmp _showSorted8
    _showSorted71:
    cmp bx, 1                                   ;; es quicksort
    jnz _showSorted72
        mov ah, 00h
        int 1ah
        mov actualTicks, dx     ;; inicializa los ticks :v
        mov quickDelay, dx
        mov dx, noUsers
        dec dx
        invoke quickSort, 0, dx
    jmp _showSorted8
    _showSorted72:                              ;; es shellsort
        mov bx, noUsers
        invoke shellSort, bx
    _showSorted8:
    ret
showSorted endp

;--------------------------------------------------
playArray proc far c uses eax ebx ecx edx esi edi
; A través de este procedimiento se realiza cualquier ordenamiento
; Despliega un menú desde donde se podrá elegir el ordenamiento
; que se realizará sobre el array del que hace referencia arrayType
;--------------------------------------------------
    _playArray1:
        clearScreen
        flushStr nameSort, 10, 32
        printStr offset veloStr0
        flushStr lineVar, 50, 0
        getLine lineVar
        compareStr lineVar, chooseOp1               ;; es bubblesort = 0
        jnz _playArray2
            mov sortType, 0
            mov cx, 10
            xor si, si
            _playArray1_0:
                mov al, bubleName[si]
                mov nameSort[si], al
                inc si
                loop _playArray1_0 
        jmp _playArray5
        _playArray2:
        compareStr lineVar, chooseOp2               ;; es quicksort = 1
        jnz _playArray3
            mov sortType, 1
            mov cx, 9
            xor si, si
            _playArray1_1:
                mov al, quickName[si]
                mov nameSort[si], al
                inc si
                loop _playArray1_1
        jmp _playArray5
        _playArray3:
        compareStr lineVar, chooseOp3               ;; es shellsort = 2
        jnz _playArray4
            mov sortType, 2
            mov cx, 9
            xor si, si
            _playArray1_2:
                mov al, shellName[si]
                mov nameSort[si], al
                inc si
                loop _playArray1_2
        jmp _playArray5
        _playArray4:
        compareStr lineVar, chooseOp4               ;; regresar al menú del administrador
        jnz _playArray5_1
            jmp _playArray_13
        _playArray5_1:
        printStrln offset wrongOpt
        pauseAnykey
        jmp _playArray1
    _playArray5:
        clearScreen
        printStrln offset ln
        printStr offset veloStr
        flushStr lineVar, 50, 0
        getLine lineVar
        mov al, lineVar                             ;; recupera el primer byte
        cmp al, '0'
        jb _playArray6
        cmp al, '9'
        ja _playArray6
        mov veloG, al                               ;; especifica la velocidad (en el encabezado)
        sub al, 48                                  ;; recupera el digito
        xor ah, ah
        mov bx, 9
        sub bx, ax
        sal bx, 2                                   ;; x4
        add bx, 2                                   ;; x4 + 2
        mov actualVel, bx
        jmp _playArray7                             ;; salta a solicitar el sentido de impresión
        _playArray6:
            printStrln offset wrongOpt
            pauseAnykey
            jmp _playArray5
    _playArray7:
        clearScreen
        printStrln offset ln
        printStr offset veloSense
        flushStr lineVar, 50, 0
        getLine lineVar
        compareStr lineVar, chooseOp1               ;; ascendente
            jnz _playArray8
            mov sense, 0
            jmp _playArray_10
        _playArray8:
        compareStr lineVar, chooseOp2               ;; descendente
            jnz _playArray9
            mov sense, 1
            jmp _playArray_10 
        _playArray9:
            printStrln offset wrongOpt
            pauseAnykey
            jmp _playArray7
    _playArray_10:
        call showSorted
        pauseSpaceKey                               ;; espera la tecla espaciadora
        clearScreen                                 ;; regresa al modo texto
        call cleanVram                              ;; limpia el doble buffer
        call copyArray                              ;; reestablece el arreglo
        jmp _playArray1                             ;; regresa al flujo normal
    _playArray_13: 
        mov ah, 49h
        mov es, vram
        int 21h                                     ;; libera la memoria ram
    ret
playArray endp
end