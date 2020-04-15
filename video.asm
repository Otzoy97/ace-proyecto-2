.model small, c
.386
.stack 400h
include p2lib.inc
.data
vram  dw ?      ;; almacena el offset de la memoria reservada que se utiliza como doble buffer
vramS dw 0      ;; almacena el tamaño el número doble words utilizados para el doble buffer
.code

;--------------------------------------------------
videoStart proc far c uses eax ebx ecx, videoSize : word
; Inicia el modo video
;--------------------------------------------------
    mov cx, videoSize
    shl cx, 2                   ;; lo multiplica por 4
    mov vramS, cx               ;; almacena el tamaño
    mov ah, 48h
    mov bx, videoSize
    int 21h                     ;; reserva memoria para el doble buffer
    jc _videoStartEnd
    mov vram, ax
    mov ax, 13h
    int 10h                     ;; configura modo video
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
    mov cx, vramS       ;; moverá 16000 dd = 64000 bytes
    cld                 ;; limpia el registro flags
    rep stosd           ;;escribe 16000 doubleword
    ret
clearScreen endp

;--------------------------------------------------
videoStop proc far c uses eax
; Termina el modo video y regresa al modo texto
; Libera la memoria resservada del doble buffer|
;--------------------------------------------------
    push es
    mov ax, 0003h
    int 10h         ;; regresa al modo texto
    mov ax, vram
    mov es, ax
    mov ah, 49h
    int 21h         ;; libera la memoria del doble buffer
    mov vramS, 0    ;; reinicia el valor del tamaño
    pop es
    ret
videoStop endp

;--------------------------------------------------
syncBuffer proc far c videoPos : word, startPos : word, base : word, heigth : word, offPos : word
; STARTPOS : indica el offset de la memoria de video
; BASE     : largo de "línea" de información a copiar en una sola iteración
; HEIGTH   : número de iteraciones a realizar
; OFFPOS   : indica el offset desde donde se deberá copiar la infomración
; Copia la imagen almacenada en el doble buffer a la memoria de video
;--------------------------------------------------
    local i : word 
    pushad
    push es
    push ds
    mov i, 0            ;; inicializa i = 0
    mov ds, videoPos    ;; indica la pos de mem
    mov si, offPos
    mov dx, 0A000h
    mov es, dx          ;; indica la pos de mem de video
    _syncBuff1:
        mov bx, i
        cmp bx, heigth
        jge _syncBuff2
        mov ax, 140h    ;; 320
        xor dx, dx
        mul bx          ;; 320 * i
        add ax, startPos;; startPos + 320 * i
        mov di, ax      ;; indica el offset de la mem de video
        mov cx, base
        cld             ;; limpia el registro de flags
        rep movsb
        inc i
        jmp _syncBuff1
    _syncBuff2:
        pop ds
        pop es
        popad
        ret
syncBuffer endp

;--------------------------------------------------
initPrint proc far c uses eax
; Mueve la posición de memoria reservada al segmento de dato extra
;--------------------------------------------------
    mov ax, vram
    mov es, ax
    ret
initPrint endp

;--------------------------------------------------
printSquare proc far c uses eax ebx ecx edx edi, color : byte, start : word, base : word, heigth : word
; COLOR     : INDICA EL COLOR DEL CUADRILATERO
; START     : INDICA LA POS DE INICIO DESDE DONDE SE DEBERÁ PINTAR LA FIGURA 
; BASE      : INDICA EL NÚMERO DE BYTES A COPIAR EN UNA SOLA ITERACIÓN
; HEIGTH    : INDICA EL NÚMERO DE ITERACIONES A REALIZAR
; Pinta un cuadrado en el doble buffer
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
printPicture proc far c uses eax ebx ecx esi edi edx, picOff : ptr word, start : word, base : word, heigth : word
; PICOFF        : INDICA EL PUNTERO DEL ARRAY QUE CONTIENE LA IMAGEN
; START         : INDICA LA POS DE INICIO DESDE DONDE SE DEBERÁ PINTAR LA FIGURA
; BASE          : INDICA EL NÚMERO DE BYTES A COPIAR EN UNA SOLA ITERACIÓN
; HEIGTH        : INDICA EL NÚMERO DE ITERACIONES A REALIZAR
; Pinta una imagen con plantilla cuadrada en el doble buffer
;--------------------------------------------------
    local i : word
    mov i, 0                ;; inicializa el contador de filas
    mov si, picOff          ;; especifica desde donde deberá leer la sección ds:si
    mov ax, vram
    mov es, ax              ;; inicializa el doble buffer
    _printPic1:
        mov bx, i
        cmp bx, heigth
        jge _printPic2      ;; terminó de pintar la figura
        mov ax, 140h        ;; 320
        xor dx, dx          
        mul bx              ;; 320 * i
        add ax, start       
        mov di, ax          ;; di = start + 320*i
        mov cx, base        ;; mueve el ancho de la imagen
        cld                 ;; limpia el registro flags|
        rep movsb           ;; copia ds:si a es:di
        inc i
        jmp _printPic1
    _printPic2:
        ret
printPicture endp

;--------------------------------------------------
printPixel proc far c uses eax edi ebx edx, color : byte, column :  word, row : word
; COLOR         : INDICA EL COLOR DEL PIXEL A PINTAR
; COLUMN        : INDICA LA COLUMNA EN DONDE DEBERÁ PINTARSE EL PIXEL
; ROW           : INDICA LA FILA EN DONDE DEBERÁ PITNARSE EL PIXEL
; Pinta un pixel en el doble buffer
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