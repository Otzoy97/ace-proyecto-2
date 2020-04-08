.model small, c
.386
.stack 400h
include p2lib.inc
include string.asm
.data
.code
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

partition proc c uses ebx ecx esi edi, startArr : ptr word, arrLow : word, arrHigh : word
    local pivote : word
    mov ax, arrLow
    cmp ax, arrHigh
    jz _partEnd
    xor si, si                      ;;limpiar si
    xor bx, bx                      ;;limpiar bx
    xor di, di                      ;;limpia di
    mov bx, startArr                ;;especifica el inicio del array
    mov di, arrHigh                 ;;especifica el indice para el pivote
    shl di, 1                       ;;multiplica por dos el limite superior
    mov ax, [bx + di]               ;;obtiene el pivote
    mov pivote, ax
    mov di, arrLow
    sub di, 2                       ;;especifica el indice del elemento menor 'i'
    mov cx, arrHigh
    sub cx, arrLow                  ;;especifica el número de iteraciones a realizar
    _1partition:
        mov ax, pivote
        cmp [bx + si], ax
        jge _2partition
            add di, 2               ;;avanza a la siguiente posición en 'i'
            push [bx + di]
            push [bx + si]
            pop [bx + di]
            pop [bx + si]
            ;mov ax, [bx + di]
            ;xchg ax, [bx + si]
            ;mov [bx + di], ax
        _2partition:
            add si, 2               ;;avanza a la siguiente posición en 'j'
            loop _1partition
    add di, 2                       ;;avanza a la siguiente posición en 'i'
    mov si, arrHigh
    shl si, 1                       ;;recupera el limite superior
    push [bx + di]
    push [bx + si]
    pop [bx + di]
    pop [bx + si]
    ;;mueve a ax el retorno de (i + 1) <=> di
    mov ax, di
    _partEnd:
    ret
partition endp

quickSort proc far c uses eax ebx, startArr:ptr word, arrLow: word, arrHigh: word
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
    
    mov cx, 9
    xor di, di
    _1:
        xor bx, bx
        mov bx, startArr
        mov bx, [bx + di]
        add bx, '0'
        printChar bl
        add di, 2
        loop _1
    printChar 0ah
    printChar 0dh

        invoke quickSort, startArr, arrLow, pidx
        add pidx, 2         ;;reestablece y aumenta el indice
        invoke quickSort, startArr, pidx, arrHigh
    qSEnd:
    ret
quickSort endp
end