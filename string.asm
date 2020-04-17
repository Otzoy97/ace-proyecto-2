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

compareStr MACRO charAC, charAR
LOCAL _1, _2, _3, _4, _5, _6, _7, _8, _9
    PUSH SI
    PUSH CX
    PUSH AX
    XOR SI, SI
    XOR CX, CX
    MOV AL, 01H
    _1:
        CMP charAC[SI], 24H
        JE _2
        CMP charAC[SI], 00H
        JE _2
        INC SI
        INC CL
        JMP _1
    _2:
        XOR SI, SI
    _3:
        CMP charAR[SI], 24H
        JE _4
        CMP charAR[SI], 00H
        JE _4
        INC SI
        INC CH
        JMP _3
    _4:
        XOR SI, SI
    _5:
        CMP CL, CH
        JNE _8
    _6:
        CMP CL, 00H
        JE _9
    _7:
        MOV AH, charAC[SI]
        CMP AH, charAR[SI]
        JNE _8
        INC SI
        DEC CL
        JMP _6
    _8:
        MOV AL, 00H
    _9:
        CMP AL, 01H
        POP AX
        POP CX
        POP SI
ENDM

toLower MACRO charAC
LOCAL _1, _2, _3, _4
    PUSH SI
    XOR SI, SI
    _1:
        CMP charAC[SI], 24H ;ES IGUAL A '$'   
        JE _4               
        CMP charAC[SI], 00H ;ES IGUAL A NULL
        JE _4
    _2:
        CMP charAC[SI], 61h ;
        JAE _3              ;SI ES MAYOR O IGUAL A 
        ADD charAC[SI], 20h
    _3:
        INC SI
        JMP _1
    _4:
        POP SI
ENDM