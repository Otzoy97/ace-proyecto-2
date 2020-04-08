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
end