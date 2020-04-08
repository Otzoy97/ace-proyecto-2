.model small, c
.386
.stack 400h
include p2lib.inc
.data
.code
;--------------------------------------------------
bubbleSort proc near c uses eax ecx esi, startArr:ptr word, sizeArr: word
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

; quickSort proc near c uses eax, ecx, esi, startArr:ptr word, arrLow: word, arrHigh: word
;     local pidx : word
;     mov pidx, 0             ;;inicializa la variable
;     mov ax, arrLow          
;     cmp ax, arrHigh         ;;compara el limite superior con el inferior
;     jge qSEnd               ;si es mayor o igual termina el procedimiento

;     qSEnd:
; quickSort endp

; partition proc uses eax, ecx, esi, edi, startArr : ptr word, arrLow : word, arrHigh : word
;     local pivot: word, iterator: word
;     mov pivot, 0
;     mov iterator, 0
;     xor si, si
;     xor bx, bx
;     mov bx, startArr
;     mov pivot, [si + arrHigh]       ;;inicializa el pivote
;     mov ax, arrLow
;     dec ax
;     mov iterator, ax                ;;inicializa el iterator (index)
;     mov cx, arrHigh
;     dec cx
;     sub cx, arrLow
;     mov si, arrLow
;     _1partition:
;         cmp [bx + si], pivot
;         jge _2partition
;             add iterator, 2
;             mov ax, 
;         _2partition:
;             loop _1partition
; partition endp
end