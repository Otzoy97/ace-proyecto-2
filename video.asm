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

initPrint proc far c uses eax
    mov ax, vram
    mov es, ax
    ret
initPrint endp

;--------------------------------------------------
printPixel proc far c uses eax edi ebx, color : byte, column :  word, row : word
;--------------------------------------------------
    ; mov ax, vram
    ; mov es, ax          ;; prepara el lugar a donde se deberá copiar
    mov ax, row           ;; ax = fila
    mov bl, 140h          ;; multiplica por 320
    mul bl                ;; ax = ax * 5
    add ax, column        ;; ax = ax + columna
    mov di, ax            ;; di = ax
    mov al, color
    mov es:[di], al
    ret
printPixel endp 

end