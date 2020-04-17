;--------------------------------------------------
printChar macro char:=<0>
; Imprime un caracter 
;--------------------------------------------------
    push ax
    push dx
    xor dx, dx
    mov ah, 02h
    mov dl, char
    int 21h
    pop dx 
    pop ax
endm

;--------------------------------------------------
printStr macro charArray
; Imprime una cadena de caracteres almacenados en 
; charArray. La cadena debe terminar con el símbolo
; '$'
;--------------------------------------------------
    push ax
    push dx
    mov ah, 09h
    mov dx, offset charArray
    int 21h
    pop dx
    pop ax
endm

;--------------------------------------------------
printStrln macro charArray
; Realiza la misma acción que printStr y realiza un
; salto de línea y retorno de carro
;--------------------------------------------------
    push ax
    push dx
    mov ah, 09h
    mov dx, offset charArray
    int 21h
    mov dx, 0ah
    mov ah, 2
    int 21h
    mov dx, 0dh
    int 21h
    pop dx
    pop ax
endm

;--------------------------------------------------
getLine macro charArray
; Recupera la cadena que el usuario ingrese a través del 
; teclado. La macro termina hasta que el usuario presione
; la tecla enter
;--------------------------------------------------
    local _1, _2, _3
    push si
    push ax
    xor si, si
    _1:
        mov ah, 01h
        int 21h
        cmp al, 0dh
        jz _2
        cmp al, 08h
        jz _3
        mov charArray[si], al
        inc si
        jmp _1
    _3:
        mov charArray[si], 0
        cmp si, 0
        je _1
        dec si
        jmp _1
    _2:
        mov al, 0
        mov charArray[si], al
    pop ax
    pop si
endm

;--------------------------------------------------
flushStr macro  char_cte, size_cte, char
; Llena de un mismo caracter 'char' la cadena de caracteres
; especificada en 'char_cte'
;--------------------------------------------------
    local _1:
    push si
    push cx
    xor si, si
    mov cx, size_cte
    _1:
        mov char_cte[si], char
        inc si
        loop _1
    pop cx
    pop si
endm