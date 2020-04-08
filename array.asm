.model small, c
.386
.stack 400h
include p2lib.inc
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
    _1:
        push cx         ;almacena al contador principal
        mov si, startArr    ;especifica el inicio del arreglo
    _2:
        mov ax, [si]
        cmp ax, [si + 2]  ;compara el valor actual con el valor siguiente
        jl _3               ;si es menor no hace nada
        xchg ax, [si + 2] ;intercambia los valores
        mov [si], ax    
    _3:  
        add si, 2       ;el apuntador avanza
        loop _2
        pop cx          ;reestablece el contador anterior
        loop _1
    ret 
bubbleSort endp

quickSort proc far c uses eax, ecx, esi, startArr:ptr word, arrLow: word, arrHigh: word
    local pidx : word
    mov pidx, 0             ;;inicializa la variable
    mov ax, arrLow          
    cmp ax, arrHigh         ;;compara el limite superior con el inferior
    jge qSEnd               ;;si es mayor o igual termina el procedimiento
        xor ax, ax          ;;ax contendrá el valor de retorno, se limpia
        invoke partition, startArr, arrLow, arrHigh
        mov pidx, ax        ;;almacena el pivote
        dec pidx            ;;decrementa el pivote
        invoke quickSort, startArr, arrLow, pidx
        inc pidx            ;;restablece y aumenta el pivote
        inc pidx
        invoke quickSort, startArr, pidx, arrHigh
    qSEnd:
quickSort endp

partition proc c uses ecx, esi, edi, startArr : ptr word, arrLow : word, arrHigh : word
    local pivote : word
    xor si, si                      ;;limpiar si
    xor bx, bx                      ;;limpiar bx
    xor di, di                      ;;limpia di
    mov bx, startArr                ;;especifica el inicio del array
    mov di, arrHigh                 ;;especifica el indice para el pivote
    shl di, 1                       ;;multiplica por dos el limite superior
    mov pivote, [bx + di]           ;;obtiene el pivote
    mov di, arrLow
    sub di, 2                       ;;especifica el indice del elemento menor 'i'
    mov cx, arrHigh
    sub cx, arrLow                  ;;especifica el número de iteraciones a realizar
    _1partition:
        cmp [bx + si], pivote
        jge _2partition
            add di, 2               ;;avanza a la siguiente posición en 'i'
            mov ax, [bx + di]
            xchg ax, [bx + si]
            mov [bx + si], ax
        _2partition:
            add si, 2               ;;avanza a la siguiente posición en 'j'
            loop _1partition
    add di, 2                       ;;avanza a la siguiente posición en 'i'
    mov ax, [bx + di]
    mov si, arrHigh
    shl si, 1                       ;;recupera el limite superior
    xchg ax, [bx + si]              ;;intercambia 
    mov [bx+ si], ax
    ;;mueve a ax el retorno de (i + 1) <=> di
    mov ax, di
partition endp
end