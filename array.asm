.model small, c
.386
.stack 400h
include p2lib.inc
include string.asm
.data
    ln              db      "$"
    pressanykey     db      "  Presione cualquier tecla para continuar...$"
    blockWidth      dw      ?               ;; ancho del bloque
    maxHeigth       dw      ?               ;; valor máximo
    padding         dw      ?               ;; espacio entre bloques
    startPad        dw      ?               ;; offset al inicio
    col             dw      ?               ;; indica la columa en la que se debe pintar
    tempDWord       dd      ?
    vram            dw      ?
    velocity        dw      ?               ;; [0-9]
    veloStr0        db      "  Ordenamientos disponibles:",0ah, 0dh
                    db      "  (1) Ordenamiento por Bubblesort",0ah, 0dh
                    db      "  (2) Ordenamiento por Quicksort",0ah, 0dh
                    db      "  (3) Ordenamiento por Shellsort",0ah, 0dh,0ah, 0dh
                    db      "  Elija una opci", 162,"n : $"
    veloStr         db      "  Ingrese la velocidad del ordenamiento [0,9]: $"
    veloSense       db      "  Especifique el sentido del ordenamiento:",0ah, 0dh
                    db      "  (1) Ascendente",0ah, 0dh
                    db      "  (2) Descendente",0ah, 0dh,0ah, 0dh
                    db      "  Elija una opci", 162,"n : $"
    wwtd_int        db      "  ",168,"Qu", 130,"desea hacer?: ", 0ah, 0dh
                    db      "  (1) Regresar al menú principal del administrador", 0ah, 0dh
                    db      "  (2) Regresar al menú de ordenamientos", 0ah, 0dh, 0ah, 0dh
                    db      "  Elija una opci", 162,"n : $"
    wrongOpt        db      "  Opci",162,"n no v",160,"lida$"
    topScoreHeader  db      "               TOP  PUNTOS$"
    topTimesHeader  db      "               TOP TIEMPOS$"
    chooseOrd       dw      ?               ;; bubble = 0 ; quick = 1 ; shell = 2
    lineVar         db      50 dup(0)
    chooseOp1       db      "1$"
    chooseOp2       db      "2$"
    chooseOp3       db      "3$"
    gArrayType      dw      ?
    ;--------------------------------------------------
    ; Tiempo
    ;--------------------------------------------------
    headerSort      db      " ORD: "
    nameSort        db      "          "
                    db      "    TMP:  "
    minuG           db      "00:"
    segsG           db      "00"
                    db      "   VEL: "
    veloG           db      " "
    actualVel       dw      ?               ;; aloja la velocidad del ordenamiento [0,9]
    quickName       db      "QUICKSORT",0
    bubleName       db      "BUBBLESORT",0
    shellName       db      "SHELLSORT",0
    numberChar      db      0,0,0,0,0,'$'
    ;--------------------------------------------------
    ; Ordenamiento
    ;--------------------------------------------------
    sortType        dw      ?               ;; aloja el tiepo de ordenamiento ha realizar
    sense           dw      ?               ;; ascendente = 0 descedente = 1
.code
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
    _detColor2:
    cmp ax, 60                      ;; hasta 60
    jg _detColor3
        mov al, 44                  ;; color amarillo
    _detColor3:
    cmp ax, 80                      ;; hasta 80
    jg _detColor4
        mov al, 3                   ;; color verde
    _detColor4:                     ;; desde 81 en adelante
        mov al, 15                  ;; color blanco
    _detColor5:
    ret
detcolor endp

;--------------------------------------------------
printBlock proc far c uses eax ebx ecx edx, value : word
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
    mov tempDWord, eax
    mov ax, word ptr tempDWord[0]
    mov dx, word ptr tempDWord[2]
    mov bx, maxHeigth
    div bx                          ;; z*168/maxHeigth
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
startVideo proc near c eax ebx
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
    mov ax, arraytype
    cmp ax, 0
    jnz _showUnsorted1
        mov bx, offset usrScore1
        jmp _showUnsorted2
    _showUnsorted1:
        mov bx, offset usrTime1
    _showUnsorted2:
        invoke printBlock, [bx + si]        ;; pinta las barras
        add si, 2
        loop _showUnsorted
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
    mov cx, 26
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
    mov dh, al                              ;; especifica la columna
    mov dl, 23                              ;; escribe en la penúltima línea
    xor bx, bx
    mov ah, 02h
    int 10h                                 ;; mueve el cursor a [23][(startPad + blockWidth/2)/8 - 2]
    mov cx, noUsers
    mov ax, arraytype
    xor si, si                              ;; reinicia el indice
    cmp ax, 0
    jnz _showUnsorted5
        mov bx, offset usrScore1            ;; determina cuál array utilizar
        jmp _showUnsorted6
    _showUnsorted5:
        mov bx, offset usrTime1
    _showUnsorted6:
        flushStr numberChar, 5, '$'
        mov ax, word ptr [bx + si]
        invoke toAsciiP2, ax, offset numberChar
        printStr offset numberChar
        add si, 2
        loop _showUnsorted6
    pauseSpaceKey
    call cleanVram
    mov ax, 3
    int 10h                                 ;; regresa al modo texto
    ret
showUnsorted endp

;--------------------------------------------------
initArray proc far c uses eax ebx ecx edx, arraytype : word
; Calcula el grosor de los bloques, el espaciado entre los bloques
; y el alto de los bloques
; arraytype = 0 -> Score
; arraytype = 1 -> Times
;--------------------------------------------------
    mov di, noUsers
    dec di                              ;; recupera un indice válido
    shl di, 1                           ;; multiplica por 2
    mov ax, arraytype
    cmp ax, 0
    jnz _initArray1
        mov ax, word ptr usrScore1[di]  ;; recupera el valor más grande
        jmp _initArray2
    _initArray1:
        mov ax, word ptr usrTime1[di]   ;; recupera el valor más grande
    _initArray2:
        mov maxHeigth, ax               ;; indica el valor máximo
    mov ax, 40
    mov bx, noUsers
    cmp bx, 1
    jz _initArray3
        cwd
        div bx
        mov startPad, ax                ;; indica el espacio al inicio
        mov ax, 220
        cwd
        div bx
        mov blockWidth, ax              ;; indica el ancho de las barras
        mov ax, 76
        dec bx 
        cwd 
        div bx
        mov padding, ax                 ;; indica el espacio entre barras
        jmp _initArray4
    _initArray3:
        mov blockWidth, 240
        mov padding, 0
        mov startPad, 40
    _initArray4:
    ret
initArray endp

;--------------------------------------------------
bubbleSort proc far c uses eax ecx esi, startArr:ptr word, sizeArr: word
; Ordena de forma ascendente un arreglo que inicia 
; en statArr y de tamaño sizeArr
;--------------------------------------------------
    xor cx, cx
    xor si, si
    mov cx, sizeArr     ;especifica el tamaño del arreglo
    dec cx              ;disminiuye el tamaño del arreglo
    _1bS:
        push cx         ;almacena al contador principal
        mov si, startArr    ;especifica el inicio del arreglo
    _2bS:
        mov ax, [si]
        cmp ax, [si + 2]  ;compara el valor actual con el valor siguiente
        jl _3bS               ;si es menor no hace nada
        xchg ax, [si + 2] ;intercambia los valores
        mov [si], ax    
    _3bS:  
        add si, 2       ;el apuntador avanza
        loop _2bS
        pop cx          ;reestablece el contador anterior
        loop _1bS
    ret 
bubbleSort endp

;--------------------------------------------------
partition proc c uses ebx ecx esi edi, startArr : ptr word, arrLow : word, arrHigh : word
;--------------------------------------------------
    local pivote : word
    xor si, si
    mov bx, startArr                ;;especifica el inicio del array
    mov di, arrLow                  ;;especifica el indice para el pivote
    shl di, 1                       ;;multiplica por dos el limite inferior
    mov ax, [bx + di]               ;;obtiene el pivote
    mov pivote, ax
    mov di, arrLow                  ;; i
    inc di                          
    shl di, 1                       ;; i = start + 1
    mov si, di                      ;; j = i
    mov cx, arrLow                  
    inc cx                          ;; for j = arrLow + 1
    _1partition:
        cmp cx, arrHigh             ;; j <= arrHigh
        jg _partPreEnd              
        mov ax, pivote  
        cmp [bx + si], ax           ;;arr[j] < pivote
        jge _2partition
            push [bx + di]          ;; arr[i]
            push [bx + si]          ;; arr[j]
            pop [bx + di]           ;; arr[i] = arr[j]
            pop [bx + si]           ;; arr[j] = arr[i]
            add di, 2               ;; i++
    ;------------------------------------------------------
        ; push cx
        ; push bx
        ; push di
        ; mov cx, 7
        ; xor di, di
        ; _1:
        ;     xor bx, bx
        ;     mov bx, startArr
        ;     mov bx, [bx + di]
        ;     add bx, '0'
        ;     printChar bl
        ;     add di, 2
        ;     loop _1
        ; printChar 0ah
        ; printChar 0dh
        ; pop di
        ; pop bx
        ; pop cx
    ;------------------------------------------------------
        _2partition:
            add si, 2               ;; j++
            inc cx                  ;; j++
            jmp _1partition
    _partPreEnd:            
        sub di, 2                       ;; i = i - 1
        mov si, arrLow                  ;; start
        shl si, 1                       ;; start
        push [bx + si]                  ;; arr[start]
        push [bx + di]                  ;; arr[i]
        pop [bx + si]                   ;; arr[start] = arr[i]
        pop [bx + di]                   ;; arr[i] = arr[start]
    ;------------------------------------------------------
        ; push cx
        ; push bx
        ; push di
        ; mov cx, 7
        ; xor di, di
        ; _2:
        ;     xor bx, bx
        ;     mov bx, startArr
        ;     mov bx, [bx + di]
        ;     add bx, '0'
        ;     printChar bl
        ;     add di, 2
        ;     loop _2
        ; printChar 0ah
        ; printChar 0dh
        ; pop di
        ; pop bx
        ; pop cx
    ;------------------------------------------------------
        mov ax, di                      ;;mueve a ax el retorno de (i + 1) <=> di
        ret
partition endp

;--------------------------------------------------
quickSort proc far c uses eax ebx, startArr:ptr word, arrLow: word, arrHigh: word
; Ordena de forma ascendente el arreglo de startArr
; y que comienza en arrLow y termina en arrHigh
;--------------------------------------------------
    local pidx : word
    mov pidx, 0             ;;inicializa la variable
    mov ax, arrLow          
    cmp ax, arrHigh         ;;compara el limite superior con el inferior
    jge qSEnd               ;;si es mayor o igual termina el procedimiento
        xor ax, ax          ;;ax contendrá el valor de retorno, se limpia
        invoke partition, startArr, arrLow, arrHigh
        shr ax, 1           ;;divide dentro de dos
        mov pidx, ax        ;;almacena el pivote
        dec pidx            ;;decrementa el contador
        invoke quickSort, startArr, arrLow, pidx
        add pidx, 2         ;;reestablece y aumenta el indice
        invoke quickSort, startArr, pidx, arrHigh
    qSEnd:
    ret
quickSort endp

;--------------------------------------------------
shellSort proc far c uses eax ebx ecx esi edi, startArr : ptr word, arrLength : word
; Ordena de forma ascendente el arreglo de starArr
; utilizando el algoritmo de shellsort
;--------------------------------------------------
    local temp : word, j : word, gap : word, i: word
    mov temp, 0
    mov j, 0
    mov gap, 0
    mov i, 0
    ;--------------------
    mov bx, startArr
    ;--------------------
    mov ax, arrLength
    shr ax, 1                   ;; divide dentro de dos
    mov gap, ax                 
    _shell1:
        mov cx, gap             
        cmp cx, 0               ;; gap > 0
        jle _shell6             ;; termina _shell1
        mov i, cx               ;; i = gap
        _shell2:
            mov cx, i           ;; i
            cmp cx, arrLength   ;; i < n
            jge _shell5         ;; termina _shell2
            mov di, cx          ;; di = cx = i
            shl di, 1           ;; multiplica por dos
            push [bx + di]      ;; arr[i]
            pop temp            ;; temp = arr[i]
            ;--------------------
            push i
            pop j               ;; j = i
            _shell3:
                mov cx, j       ;; 
                cmp cx, gap     ;; j >= gap
                jl _shell4      ;; termina shell3
                mov di, gap
                mov si, j
                shl di, 1       
                shl si, 1       ;; lo multiplica por dos
                sub si, di      ;; j - gap
                mov ax, [bx + si] ;; arr[j -gap]
                mov cx, temp    ;; temp
                cmp ax, cx      ;; arr[j - gap] > temp
                jle _shell4     ;; termina shell3
                mov di, j
                shl di, 1       ;; lo multiplica por dos
                push [bx + si]  ;; arr[j - gap]
                pop [bx + di]   ;; arr[j]

    ;------------------------------------------------------
        ; push cx
        ; push bx
        ; push di
        ; mov cx, 7
        ; xor di, di
        ; _1:
        ;     xor bx, bx
        ;     mov bx, startArr
        ;     mov bx, [bx + di]
        ;     add bx, '0'
        ;     printChar bl
        ;     add di, 2
        ;     loop _1
        ; printChar 0ah
        ; printChar 0dh
        ; pop di
        ; pop bx
        ; pop cx
    ;------------------------------------------------------

                ;--------------------
                mov di, gap     ;; gap
                mov si, j       ;; j
                sub si, di      ;; j = j - gap
                mov j, si
                jmp _shell3
            _shell4:
            mov si, j
            shl si, 1           ;; multiplica por dos
            push temp           ;; temp
            pop [bx + si]       ;; arr[j] = temp


    ;------------------------------------------------------
        ; push cx
        ; push bx
        ; push di
        ; mov cx, 7
        ; xor di, di
        ; _2:
        ;     xor bx, bx
        ;     mov bx, startArr
        ;     mov bx, [bx + di]
        ;     add bx, '0'
        ;     printChar bl
        ;     add di, 2
        ;     loop _2
        ; printChar 0ah
        ; printChar 0dh
        ; pop di
        ; pop bx
        ; pop cx
    ;------------------------------------------------------


            ;--------------------
            inc i               ;; i++
            jmp _shell2         
        _shell5:
            mov ax, gap
            shr ax, 1           ;; lo divide dentro de 2
            mov gap, ax
            jmp _shell1
    _shell6:
        ret
shellSort endp

;--------------------------------------------------
playArray proc far c uses eax ebx ecx edx esi edi, arraytype : word
; A través de este procedimiento se realiza cualquier ordenamiento
;--------------------------------------------------
    mov ax, arraytype
    invoke initArray, ax                            ;; inicializa el ordenamiento
    invoke showUnsorted, ax                         ;; pinta las barras sin ordenar
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
            _playArray10:
                mov al, bubleName[si]
                mov nameSort[si], al
                inc si
                loop _playArray10 
        jmp _playArray5
        _playArray2:
        compareStr lineVar, chooseOp2               ;; es quicksort = 1
        jnz _playArray3
            mov sortType, 1
            mov cx, 9
            xor si, si
            _playArray11:
                mov al, quickName[si]
                mov nameSort[si], al
                inc si
                loop _playArray11
        jmp _playArray5
        _playArray3:
        compareStr lineVar, chooseOp3               ;; es shellsort = 2
        jnz _playArray4
            mov sortType, 2
            mov cx, 9
            xor si, si
            _playArray11:
                mov al, shellName[si]
                mov nameSort[si], al
                inc si
                loop _playArray11
        jmp _playArray5
        _playArray4:
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
        mov actualVel, al                           ;; especifica la velocidad
        sub al, 48                                  ;; recupera el digito
        xor ah, ah
        mov actualVel, ax
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
        mov ax, sortType
        cmp ax, 0                                   ;; es bubblesort
        jnz _playArray_11

        jmp _playArray_13
        _playArray_11:
        cmp ax, 1                                   ;; es quicksort
        jnz _playArray_12

        jmp _playArray_13
        _playArray_12:                              ;; es shellsort
        
    _playArray_13 
    ret
playArray endp
end