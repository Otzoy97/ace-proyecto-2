.model small, c
.386
.stack 400h
include p2lib.inc
.data
vram  dw ?      ;; almacena el offset de la memoria reservada que se utiliza como doble buffer
vramS dw 0      ;; almacena el tamaño el número doble words utilizados para el doble buffer
.code
;--------------------------------------------------
clearVideo proc far c uses eax ecx edx edi
; Limpia la memoria de video
;--------------------------------------------------
    push es
    xor eax, eax
    mov dx, 0A000h
    mov es, dx
    xor di, di
    mov cx, 16000
    cld
    rep stosd
    pop es
clearVideo endp

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

end