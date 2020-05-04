.model small, c
.386
.stack 100h
include fileH.asm
include string.asm
.data
    str1            db  "Escriba el numero de usuarios: $"
    randomSeed      dd  ?
    nameFile        db  "scores.tzy", 0
    number          db  4 dup(0)
    fileH           dw  ?
    buffchar        db  ?
    buffword        dw  ?
    nameusr         db  "usrs"
.code
.startup
    mov ax, @data
    mov ds, ax
main proc near c
    local i : word
    xor ecx, ecx
    xor edx, edx
    mov ah, 0
    int 1ah
    shl ecx, 16                          ;; ahora cx, está en la parte alta de ecx
    add ecx, edx                         ;; suma la parte baja de ecx
    mov randomSeed, ecx                  ;; para números aleatorios
    printStrln offset str1
    flushStr number, 4, 0
    getLine number
    call getNumber
    .if  (ax > 20)
        mov ax, 20
    .endif
    mov i, ax
    createFile nameFile, fileH
    .while (i != 0)
        writeFile fileH, nameusr, 4
        
        mov buffchar, 59
        writeFile fileH, buffchar, 1

        call rand
        mov eax, randomSeed
        mov ebx, 99
        xor edx, edx
        cdq
        div ebx
        add edx, 3                      ;; [3, 101]
        mov buffword, dx
        writeFile fileH, buffword, 2

        mov buffchar, 59
        writeFile fileH, buffchar, 1

        call rand
        mov eax, randomSeed
        mov ebx, 250
        xor edx, edx
        cdq
        div ebx
        add edx, 1                      ;; [1, 250]
        mov buffword, dx
        writeFile fileH, buffword, 2

        mov buffchar, 59
        writeFile fileH, buffchar, 1

        call rand
        mov eax, randomSeed
        mov ebx, 6
        xor edx, edx
        cdq
        div ebx
        add edx, 1                      ;; [1, 6]
        mov buffchar, dl
        writeFile fileH, buffchar, 1

        mov buffchar, 0ah
        writeFile fileH, buffchar, 1    ;; salto de línea

        dec i
    .endw
    mov ax, 4c00h
    int 21h
main endp

getNumber proc near c
    local tempN : word
    mov tempN, 0
    mov bx, offset number
    xor si, si
    _getNumber1:
        mov al, number[si]
        cmp al, 0
        jz _getNumber2
        mov ax, tempN
        shl ax, 1           ;; x2
        mov bx, ax
        shl ax, 2           ;; x8
        add bx, ax
        mov tempN, bx
        xor ax, ax
        mov al, number[si]
        sub al, '0'
        add tempN, ax 
        inc si
        jmp _getNumber1
    _getNumber2:
    mov ax, tempN
    ret
getNumber endp

;--------------------------------------------------
rand proc near c uses eax ebx edx
; Genera un número aleatorio utilizando 
; el algoritmo de generador lineal congruencial (GLC)
; Xn+1 = (aXn + c) % m
; randomSeedn+1 = (randomSeed*48271 + 1) % (2^31)
;--------------------------------------------------
    xor edx, edx
    mov eax, randomSeed
    mov ebx, 48271
    mul ebx
    add eax, 1
    mov ebx, eax                ;; obtiene el modulo de la forma:
    and ebx, 080000000h          ;; dividendo - (divisor * cociente) = residuo
    sub eax, ebx
    mov randomSeed, eax
    ret
rand endp

end