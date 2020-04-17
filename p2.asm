.model small, c
.386
;--------------------------------------------------
.stack 400h
include p2lib.inc
include string.asm
clearScreen macro
    push ax
    push cx
    mov ah, 2
    mov dx, 0
    int 10h
    mov ah, 9
    mov al, 0
    mov bl, 7
    mov cx, 0fa0h
    int 10h
    pop cx
    pop ax
endm
pauseAnyKey macro
    push ax
    printStr pressanykey
    mov ah, 08h
    int 21h 
    pop ax
endm
;--------------------------------------------------
.data
array   dw  6,8,4,0,1,9,7
ln              db  "$"
;--------------------------------------------------
; LOGIN
;--------------------------------------------------
mainmenu        db  "  (1) Ingresar", 0ah, 0dh
                db  "  (2) Registrar", 0ah, 0dh
                db  "  (3) Salir", 0ah, 0dh, 0ah, 0dh
                db  "  Elija una opción : $"
mainmenu1       db  "  Usuario : "
mainmenu2       db  "  Contrase", 164,"a : "
mainmenu3       db  "  Usuario registrado exitosamente"
mainmenu3       db  "  Usuario/contrase", 164,"a no existe"
usernameTemp    db  80 dup(?)
passwordTemp    db  80 dup(?)
;--------------------------------------------------
; ADMIN
;--------------------------------------------------
userAdmin       db  "admin", 00 
passAdmin       db  "1234", 00
;--------------------------------------------------
; USUARIO
;--------------------------------------------------
header          db  "UNIVERSIDAD DE SAN CARLOS DE GUATEMALA", 0ah, 0dh
                db  "CIENCIAS Y SISTEMAS", 0ah, 0dh
                db  "ARQUITECTURA DE COMPUTADORES Y ENSAMBLADORES 1", 0ah, 0dh
                db  "ALUMNO: SERGIO FERNANDO OTZOY GONZALEZ", 0ah, 0dh
                db  "CARNÉ: 201602782", 0ah, 0dh
                db  "SECCIÓN: A", 0ah, 0ah, 0dh, '$'
userOp          db  " 1) Iniciar juego", 0ah, 0dh
                db  " 2) Cargar juego", 0ah, 0dh
                db  " 3) Salir", 0ah, 0dh, '$'
adminOp         db  " 1) Top 10 (punteo)", 0ah, 0dh
                db  " 2) Top 10 (tiempo)", 0ah, 0dh
                db  " 3) Salir", 0ah, 0dh, '$'
chooseOp        db  " Elija una opción : $"
strVar          db  80 dup(0)
cte1            db  "1$"
cte2            db  "2$"
cte3            db  "3$"
cte4            db  "4$"
pressanykey     db  " Presione cualquier tecla para continuar...$"
strBuffer       db  80 dup(0)
userFile        db  "usr.tzy"
fileHandler     dw  ?   
fileBuffChar    db  ? 
;--------------------------------------------------
.code
.startup
    mov ax, @data
    mov ds, ax
main proc
    _mainStart:
        clearScreen                             ;; limpia la pantalla
        printStr mainmenu                       ;; muestra las opciones disponibles
        flushStr strVar, 80, 0
        getLine strVar                          ;; recupera la opción del usuario
        compareStr strVar, cte1
        jz _mainLogin
        compareStr strVar, cte2
        jz _mainSignup                           
        compareStr strVar, cte3
        jz _endMain
        pauseAnyKey
        jmp _mainStart
    _mainLogin:
        clearScreen
        printStrln ln
        printStr mainmenu1
        flushStr usernameTemp, 10, 0
        flushStr passwordTemp, 10, 0
        getLine usernameTemp
        printStrln ln
        printStr mainmenu2
        getLine passwordTemp
        compareStr userAdmin, usernameTemp
        jnz _mainLoginUsr
        compareStr userAdmin, usernameTemp
        jnz _mainLoginUsr
            call mainAdmin
        jmp _mainStart
        _mainLoginUsr:
            call validateLogin
            .if (ax == 1)                       ;; si es igual a 1, existe el usuario y contraseña
                call mainUser 
            .else
                printStrln mainmenu3
                pauseAnyKey                    
            .endif
            jmp _mainLogin
    _mainSignup
        clearScreen
        printStrln
        printStrln mainmenu1
        flushStr usernameTemp, 10, 0
        flushStr passwordTemp, 10, 0
        getLine usernameTemp
        printStrln
        printStr mainmenu2
        getLine passwordTemp
        call validateLogin
        .if (ax == 0)                           ;; usuario no coincide == usuario disponible
            ;; call signUp
        .endif
        jmp _mainStart
    _endMain:
        mov ax, 4c00h
        int 21h
main endp

;--------------------------------------------------
validateLogin proc near c uses ecx edx esi edi
; Abre el archivo de usuarios y busca una coincidencia
; con el nombre de usuario dado
; El resultado se almacena en ax ax = 0 usuario no coincide, 1 coincide, 2 contraseña y usuario no coincide
;--------------------------------------------------
    local lenFile : word, i : word, flag : byte
    mov i, 0
    mov lenFile, 0
    mov flag, 0
    openFile userFile, fileHandler
    getFileLength fileHandler
    mov lenFile, ax                             ;; recupera el largo del archivo
    mov cx, i
    mov ax, 4200h
    xor cx, cx
    xor dx, dx
    int 21h                                     ;; reestablece el puntero del archivo
    xor di, di
    xor si, si
    mov fileBuffChar, 0
    flushStr strBuffer, 80, 0                   ;; servirá para almacenar la info leída desde el archivo
    .while (cx < lenFile)                       ;; mientras haya caracter para leer
        readFile fileHandler, fileBuffChar, 1   ;; recupera un caracter del archivo
        mov al, fileBuffChar
        .if ( al == 59 )                        ;; punto y coma
            compareStr strBuffer, usernameTemp
            .if (zero?)                         ;; si son iguales
                mov flag, 1                     ;; flag = 1 // true
                xor si, si                      ;; reinicia el indice para el buffer
                .break                          ;; termina el loop
            .else                               ;; no son iguales
                flushStr strBuffer, 80, 0       ;; limpia el buffer
                xor si, si                      ;; reinicia el indice para el buffer
            .endif
        .elseif ( al == 0ah || al == 0dh )      ;; es salto de linea/retorno de carro
            flushStr strBuffer, 80, 0           ;; limpia el buffer
            xor si, si                          ;; reinicia el indice para el buffer
        .else 
            mov strBuffer[si], al               ;; mueve el caracter recuperado al buffer
            inc si                              ;; aumenta el indice del buffer
        .endif
        inc i                                   ;; aumenta el contador
        mov cx, i
    .endw
    mov ax, flag                                ;; recupera el valor en flag
    .if (ax == 1)                               ;; se encontró una coincidencia
        .while (cx < lenFile)                       ;; mientras haya caracter para leer
            readFile fileHandler, fileBuffChar, 1   ;; recupera un caracter del archivo
            mov bl, fileBuffChar
            .if ( bl == 0ah || bl == 0dh )          ;; llegó al final de la línea
                compareStr strBuffer, passwordTemp  ;; compara la contraseña
                .if (zero?)     
                    mov flag, 1                     ;; es igual
                .else
                    mov flag, 2                       ;; no es igual
                .endif
                .break
            .else 
                mov strBuffer[si], bl               ;; mueve el caracter recuperado al buffer
                inc si                              ;; aumenta el indice del buffer
            .endif
            inc i                                   ;; aumenta el contador
            mov cx, i
        .endw
    .endif                                      ;; no se encontró coincidencia
    closeFile fileHandler
    ret
validateLogin endp

;--------------------------------------------------
singup proc near c uses ebx ecx edx esi edi
; Abre el archivo de usuario y busca una coincidencia
; con el nombre de usuario dado
; el resultado se almacena en ax, 0 no coincide, 1 si coincide
;-------------------------------------------------- 
    local lenFile : word
    mov lenFile, 0
    openFile userFile, fileHandler
    getFileLength fileHandler
    ;; colocar cursor al final del archivo
    ;; escribir username y password (de forma que no existe espacios o que no exceda 10 caracteres)
    ;; colocar en medio de username y password una coma
    ret
signup endp

end


    ; call videoStart
    ; call initGame
    _1:
        ; call clearScreen
        ; call initPrint        
        ; call printFrame
        ; call printBackground
        ; invoke printObs, 1, 0
        ; invoke printObs, 3, 1
        ; call printCar
        ; call syncBuffer
        ; call printHeader
        ; mov ah, 01h
        ; int 16h
        ; jnz _2
        ; jmp _1
    _2:
        ; call clearScreen
        ; call syncBuffer
        ; call videoStop
    ; mov cx, 7
    ; xor di, di
    ; _1:
    ;     xor bx, bx
    ;     mov bx, array[di]
    ;     add bx, '0'
    ;     printChar bl
    ;     add di, 2
    ;     loop _1
    ; printChar 0ah
    ; printChar 0dh
    ; invoke shellSort, offset array, 7
    ; mov cx, 7
    ; xor di, di
    ; _2:     
    ;     xor bx, bx
    ;     mov bx, array[di]
    ;     add bx, '0'
    ;     printChar bl
    ;     add di, 2
    ;     loop _2