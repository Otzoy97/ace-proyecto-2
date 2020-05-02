.model small, c
.386
.stack 400h
include p2lib.inc
include string.asm
.data
    blockWidth      dw      ?               ;; ancho del bloque
    maxHeigth       dw      ?               ;; valor máximo
    padding         dw      ?               ;; espacio entre bloques
    startPad        dw      ?               ;; offset al inicio
    col             dw      ?               ;; indica la columa en la que se debe pintar
    tempDWord       dd      ?
    vram            dw      ?
    sense           dw      ?               ;; ascendente = 0 descedente = 1
    velocity        dw      ?               ;; [0-9]
    veloStr0        db      "  Ordenamientos disponibles:",0ah, 0dh
                    db      "  (1) Ordenamiento por Bubblesort",0ah, 0dh
                    db      "  (2) Ordenamiento por Quicksort",0ah, 0dh
                    db      "  (3) Ordenamiento por Shellsort",0ah, 0dh,0ah, 0dh
                    db      "  Elija una opci", 162,"n : $"
    veloStr         db      "  Ingrese la velocidad del ordenamiento [0,9]: $"
    chooseOrd       dw      ?               ;; bubble = 0 ; quick = 1 ; shell = 2
    lineVar         db      50 dup(0)
    chooseOp0       db      "0$"
    chooseOp1       db      "1$"
    chooseOp2       db      "2$"
    chooseOp3       db      "3$"
    chooseOp4       db      "4$"
    chooseOp5       db      "5$"
    chooseOp6       db      "6$"
    chooseOp7       db      "7$"
    chooseOp8       db      "8$"
    chooseOp9       db      "9$"
    ;--------------------------------------------------
    ; Tiempo
    ;--------------------------------------------------
    headerSort      db      "ORD: "
    nameSort        db      "          "
                    db      "    TMP:  "
    minuG           db      "00:"
    segsG           db      "00"
                    db      "    VEL: "
    veloG           db      " "
    quickName       db      "QUICKSORT",0
    bubleName       db      "BUBBLESORT",0
    shellName       db      "SHELSORT",0
    numberChar      db      2 dup(0)
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
printBlock proc far c uses eax ebx ecx edx, value : word, startCol : word
;--------------------------------------------------
    local ratioAspect : word
    mov bx, value
    shl ebx, 4                      ;; x16
    mov eax, ebx
    shl ebx, 1                      ;; x32
    add eax, ebx
    shl ebx, 2                      ;; x128
    add eax, ebx
    mov tempDWord, eax
    mov ax, word ptr tempDWord[0]
    mov dx, word ptr tempDWord[2]
    mov bx, maxHeigth
    div bx                          ;; z*176/maxHeigth
    mov ratioAspect, ax             ;; almacena el número de pixeles a pintar
    invoke detColor, word           ;; determina el color de los pixeles
    
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
    mov cx, 14080                   ;; (176 * 320) / 4
    cld 
    rep stosd
    ret
cleanVram endp

;--------------------------------------------------
startVideo proc near c eax ebx
; Inicia el modo video e inicializa la memoria reservada
;--------------------------------------------------
    mov ah, 48h
    mov bx, 3520                        ;; (176 * 320) / 16
    int 21h
    mov vram, ax                        ;; indica la pos de mem
    call cleanVram
    mov ah, 00h
    mov al, 13h
    int 10h
    ret
startVideo endp 

;--------------------------------------------------
showUnsorted proc far c uses eax ebx ecx edx esi edi
;--------------------------------------------------
    local local_col : word
    mov ah, 00h
    mov al, 13h
    int 10h                             ;; inicia el modo video
    mov ax, startPad
    mov local_col, startPad             ;; inicializa local_col

    ret
showUnsorted endp

;--------------------------------------------------
initArray proc far c uses eax ebx ecx edx, arraytype : word
; Calcula el grosor de los bloques, el espaciado entre los bloques
; y el alto de los bloques
; arrayType = 0 -> Score
; arrayType = 1 -> Times
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
end