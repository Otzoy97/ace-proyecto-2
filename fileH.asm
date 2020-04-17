createFile MACRO fileName, fileHandler
LOCAL _1, _2
    PUSH AX
    PUSH CX
    xor ax, ax
    xor cx, cx
    MOV AH, 3CH
    MOV CX, 00H
    MOV DX, OFFSET fileName
    INT 21H
    JNC _1
    ;printStrln createFileFailed
    ;pauseAnyKey
    JMP _2
    _1:
    MOV fileHandler, AX
    _2:
    POP CX
    POP AX
ENDM

;--------------------------------------------------
getFileLength macro fileHandler
; recupera el largo del archivo
;--------------------------------------------------
    push cx
    push dx
    push bx
    mov ax, 4202h
    xor cx, cx
    xor dx, dx
    mov bx, fileHandler
    int 21h
    pop bx
    pop dx
    pop cx
endm

contarRep MACRO varOffset
    xor si, si
    mov bx, offset varOffset
    mov al, '$'
    .while ( [BX + SI] != AL)
        INC SI
    .endw
ENDM

writeFile MACRO fileHandler, fileContent, fileSize
LOCAL _1
    PUSH AX
    PUSH CX
    PUSH BX
    MOV AH, 40H
    MOV BX, fileHandler
    MOV CX, fileSize
    MOV DX, OFFSET fileContent
    INT 21H
    JNC _1
    ;printStrln writeFileFailed
    ;pauseAnyKey
    _1:
    POP BX
    POP CX
    POP AX
ENDM

openFile MACRO  fileName, fileHandler
LOCAL _1, _2
    PUSH AX
    MOV AH, 3DH
    MOV AL, 02H
    MOV DX, OFFSET fileName
    INT 21H
    JNC _1
    ;printStrln openFileFailed
    ;pauseAnyKey
    JMP _2
    _1:
    MOV fileHandler, AX
    _2:
    POP AX
ENDM

closeFile MACRO fileHandler
LOCAL _1
    PUSH AX
    PUSH BX
    MOV AH, 3EH
    MOV BX, fileHandler
    INT 21H
    JNC _1
    ;printStrln closeFileFailed
    _1:
    POP BX
    POP AX
ENDM

readFile MACRO fileHandler, fileContent, fileSize
LOCAL _1
    PUSH AX
    PUSH BX
    PUSH CX
    MOV AH, 3FH
    MOV BX, fileHandler
    MOV CX, fileSize
    MOV DX, OFFSET fileContent
    INT 21H
    JNC _1
    ;printStrln readFileFailed
    ;pauseAnyKey
    _1:
    POP CX
    POP BX
    POP AX
ENDM

