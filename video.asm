.model small, c
.386
.stack 400h
include p2lib.inc
.data
vram dw ?
.code
;--------------------------------------------------
videoStart proc far c uses eax ebx
; Inicia el modo video
;--------------------------------------------------
    ;reserva memoria para el doble buffer
    mov ah, 48h
    mov bx, 4000
    int 21h
    jc _videoStartEnd
    mov vram, ax
    ;configura modo video
    mov ax, 13h
    int 10h
    _videoStartEnd:
        ret
videoStart endp 

;--------------------------------------------------
clearScreen proc far c uses eax edi ecx
;--------------------------------------------------
    mov ax, vram
    mov es, ax          ;; carga vram a ES
    xor edi, edi        ;; comienza desde 0
    xor eax, eax        ;; <cadena> a almacenar en es:edi
    mov cx, 16000       ;; moverá 16000 dd = 64000 bytes
    cld                 ;; limpia el registro flags
    rep stosd           ;;escribe 16000 doubleword
    ret
clearScreen endp

;--------------------------------------------------
videoStop proc far c uses eax
; Termina el modo video y regresa al modo texto
;--------------------------------------------------
    push es
    mov ax, 0003h
    int 10h
    ;libera la memoria del doble buffer
    mov ax, vram
    mov es, ax
    mov ah, 49h
    int 21h
    pop es
    ret
videoStop endp

;--------------------------------------------------
syncBuffer proc far c uses edi esi
; Copia la imagen almacenada en vram a la memoria de
; video
;--------------------------------------------------
    pushad
    push es
    push ds
    ;--------------------
    mov ds, vram
    xor si, si
    mov dx, 0A000h
    mov es, dx
    xor di, di
    mov cx, 64000
    rep movsb
    ;--------------------
    pop ds
    pop es
    popad
    ret
syncBuffer endp

;--------------------------------------------------
initPrint proc far c uses eax
; Mueve la posición de memoria reservada al 
; segmento de dato extra
;--------------------------------------------------
    mov ax, vram
    mov es, ax
    ret
initPrint endp

;--------------------------------------------------
printSquare proc far c uses eax ebx ecx edx edi, color : byte, start : word, base : word, heigth : word
; Pinta un cuadrado de un color desde la posición
; de inicio.
; El tamaño del cuadrado está dado por la base
; y la altura
; La posición de inicio indica la esquina superior
; izquierda desde donde se empezará a pintar
;--------------------------------------------------
    local i : word
    mov i, 0                ;; inicializa el contador de filas
    mov ax, vram
    mov es, ax              ;; inicializa el extra data segment
    _printSq1:
        mov bx, i
        cmp bx, heigth
        jge _printSq2       ;; terminó de pintar el cuadrado
        mov ax, 140h        ;; 320
        xor dx, dx
        mul bx              ;; 320*i
        add ax, start       ;; compone la nueva posición 
        mov di, ax          ;; di = start + 320*i
        mov al, color       ;; mueve el color que se deberá copiar
        mov cx, base        ;; mueve el ancho del cuarado
        cld                 ;; limpia el registro de flags
        rep stosb           ;; copia al a es:di, cx veces
        inc i
        jmp _printSq1
    _printSq2:
        ret
printSquare endp

;--------------------------------------------------
printPixel proc far c uses eax edi ebx edx, color : byte, column :  word, row : word
; Pina un pixel del color especificado en la posición
; dada por la columna y fila
;--------------------------------------------------
    ; mov ax, vram
    ; mov es, ax          ;; prepara el lugar a donde se deberá copiar
    mov ax, row           ;; ax = fila
    mov bx, 140h          ;; multiplica por 320
    xor dx, dx
    mul bx                ;; multiplica por 320
    add ax, column        ;; suma la columna
    mov di, ax            ;; di = ax
    mov al, color
    mov es:[di], al
    ret
printPixel endp 

end