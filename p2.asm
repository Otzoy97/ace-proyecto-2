.model small, c
.386
;--------------------------------------------------
.stack 400h
include p2lib.inc
include string.asm
include fileH.asm
include screen.asm
headerMain proto near c col : byte, row : byte, txtoff : ptr word, sizetxt : word
;--------------------------------------------------
.data
array           dw  6,8,4,0,1,9,7
ln              db  "$"
;--------------------------------------------------
; LOGIN
;--------------------------------------------------
mainmenu        db  "  (1) Ingresar", 0ah, 0dh
                db  "  (2) Registrar", 0ah, 0dh
                db  "  (3) Salir", 0ah, 0dh, 0ah, 0dh
                db  "  Elija una opci", 162,"n : $"
mainmenu1       db  "  Usuario : $"
mainmenu2       db  "  Contrase", 164,"a : $"
mainmenu3       db  "  Usuario registrado exitosamente$"
mainmenu4       db  "  Usuario/contrase", 164,"a no existe$"
mainmenu8       db  "  No se puede registrar usuario. Usuario ya existe$"
mainmenu5       db  "PROYECTO FINAL$"     ;; 14
mainmenu6       db  "INICIAR SESION$"     ;; 14
mainmenu7       db  "REGISTRAR  USUARIO$" ;; 18
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
header          db  " UNIVERSIDAD DE SAN CARLOS DE GUATEMALA", 0ah, 0dh
                db  " CIENCIAS Y SISTEMAS", 0ah, 0dh
                db  " ARQUITECTURA DE COMPUTADORES Y ENSAMBLADORES 1", 0ah, 0dh
                db  " ALUMNO:  SERGIO FERNANDO OTZOY GONZALEZ", 0ah, 0dh
                db  " CARNE:   201602782", 0ah, 0dh
                db  " SECCION: A", 0ah, 0ah, 0dh, '$'
userOp          db  "  1) Iniciar juego", 0ah, 0dh
                db  "  2) Cargar juego", 0ah, 0dh
                db  "  3) Salir", 0ah, 0dh, '$'
adminOp         db  "  1) Top 10 (punteo)", 0ah, 0dh
                db  "  2) Top 10 (tiempo)", 0ah, 0dh
                db  "  3) Salir", 0ah, 0dh, '$'
chooseOp        db  "  Elija una opci", 162,"n : $"
setFileName     db  "  Escriba el nombre del archivo .ply : $"
wrongExtFile    db  "  Archivo inv", 160,"lido. No coincide la extensi", 162, "n$"
strVar          db  80 dup(0)
cte1            db  "1$"
cte2            db  "2$"
cte3            db  "3$"
cte4            db  "4$"
cte5            db  "ply$"
pressanykey     db  "  Presione cualquier tecla para continuar...$"
wrongOpt        db  "  Opci",162,"n no v",160,"lida$"
strBuffer       db  80 dup(0)
userFile        db  "usr.tzy",00
fileHandler     dw  ?   
fileBuffChar    db  ? 
;--------------------------------------------------
.code
.startup
    mov ax, @data
    mov ds, ax
main proc near c
    _mainStart:
        clearScreen                             ;; limpia la pantalla
        invoke headerMain, 0, 9, offset mainmenu5, 33     ;; imprime en [9][0]
        printStr offset mainmenu                       ;; muestra las opciones disponibles
        flushStr strVar, 80, 0
        getLine strVar                          ;; recupera la opción del usuario
        compareStr strVar, cte1
        jz _mainLogin
        compareStr strVar, cte2
        jz _mainSignup                           
        compareStr strVar, cte3
        jz _endMain
        printStrln offset ln
        printStrln offset wrongOpt
        pauseAnyKey
        jmp _mainStart
    _mainLogin:
        clearScreen
        invoke headerMain, 0, 9, offset mainmenu6, 33
        printStr offset mainmenu1
        flushStr usernameTemp, 10, 0
        flushStr passwordTemp, 10, 0
        getLine usernameTemp
        printStrln offset ln
        printStr offset mainmenu2
        getLine passwordTemp
        compareStr userAdmin, usernameTemp
        jnz _mainLoginUsr
        compareStr userAdmin, usernameTemp
        jnz _mainLoginUsr
            ;call mainAdmin
        jmp _mainStart
        _mainLoginUsr:
            call validateLogin
            .if (ax == 1)                       ;; si es igual a 1, existe el usuario y contraseña
                call mainUser 
            .else
                printStrln offset ln
                printStrln offset mainmenu4
                pauseAnyKey                 
            .endif
            jmp _mainStart
    _mainSignup:
        clearScreen
        invoke headerMain,0,9,offset mainmenu7,31
        printStr offset mainmenu1
        flushStr usernameTemp, 10, 0
        flushStr passwordTemp, 10, 0
        getLine usernameTemp
        printStrln offset ln
        printStr offset mainmenu2
        getLine passwordTemp
        call validateLogin
        .if (ax == 0)                           ;; usuario no coincide == usuario disponible
            call signup
        .else 
            printStrln offset ln
            printStrln offset mainmenu8
        .endif
        pauseAnyKey
        jmp _mainStart
    _endMain:
        clearScreen
        mov ax, 4c00h
        int 21h
main endp

;--------------------------------------------------
headerMain proc near c uses eax ecx edx, col : byte, row : byte, txtoff : ptr word, sizetxt : word
; Imprime un encabezado para las primeras pantallas 
;--------------------------------------------------
    clearScreen
    mov ah, 02h
    xor bx, bx
    mov dh, row
    mov dl, col
    int 10h                 ;; posiciona el cursor
    mov cx, sizetxt         ;; imprime la parte inicial del borde
    _headerM1:
        printChar 205
        loop _headerM1
    printStr txtoff         ;; imprime el texto 
    mov cx, sizetxt         ;; imprime la parte final del borde
    _headerM2:
        printChar 205
        loop _headerM2
    ret
headerMain endp

;--------------------------------------------------
mainUser proc near c
; Menú principal para el usuario normal
;--------------------------------------------------
    mov cx, 10
    xor si, si
    ;_setUserName:
        ;mov al, usernameTemp[si]
        ;cmp al, 0
        ;jz _mainUser1
        ;mov userStr[si], al
        ;_setUserNameIncSi:
        ;    inc si
        ;loop _setUserName
    _mainUser1:
        clearScreen
        printStr offset header
        printStrln offset userOp
        printStr offset chooseOp
        flushStr strVar, 80, 0
        getLine strVar
        compareStr cte1, strVar
        jz _mainUser2                           ;; jugar
        compareStr cte2, strVar
        jz _mainUser3                           ;; cargar
        compareStr cte3, strVar
        jz _mainUser4                           ;; salir
        printStrln offset ln
        printStrln offset wrongOpt              ;; opción inválida
        pauseAnyKey
        jmp _mainUser1
    _mainUser2:                                 ;; jugar
        jmp _mainUser1
    _mainUser3:                                 ;; cargar
        printStrln offset ln
        printStr offset setFileName
        flushStr strVar, 80, 0
        getLine strVar
        call validateFile
        compareStr strBuffer, cte5              ;; compara la extensión
        jz _mainUser31
        printStrln offset ln
        printStrln offset wrongExtFile          ;; extensión inválida
        pauseAnyKey
        jmp _mainUser1
        _mainUser31:
            openFile strVar, fileHandler        ;; abre el archivo
            
            pauseAnyKey
            jmp _mainUser1
    _mainUser4:
    ret
mainUser endp

;--------------------------------------------------
validateLogin proc near c uses ecx edx esi edi
; Abre el archivo de usuarios y busca una coincidencia
; con el nombre de usuario dado
; El resultado se almacena en ax = 0 usuario no coincide, 1 coincide; 2 contraseña no coincide y usuario coincide
;--------------------------------------------------
    local flag : byte
    mov flag, 0
    openFile userFile, fileHandler
    mov fileBuffChar, 0
    flushStr strBuffer, 80, 0                   ;; servirá para almacenar la info leída desde el archivo
    _validateLogin1:                            ;; buscará coincidencia con el nombre de usuario
        readFile fileHandler, fileBuffChar, 1   ;; recupera un caracter del archivo
        cmp ax, 0                               ;; determina cuántos bytes se transfirieron
        jz _validateLogin5
        mov al, fileBuffChar
        _validateLogin2:
            cmp al, 59                          ;; es separación de contraseña
            jnz _validateLogin3
            compareStr strBuffer, usernameTemp  ;; compara las cadenas
            jnz _validateLogin1                 ;; continúa con el ciclo
            mov flag, 1                         ;; usuario coincide
            flushStr strBuffer, 80, 0           ;; limpia el buffer auxiliar
            xor si, si
            jmp _validateLogin5                 ;; termina el ciclo
        _validateLogin3:
            cmp al, 10                          ;; es final de linea
            jnz _validateLogin4                 ;; continúa con el ciclo
            flushStr strbuffer, 80, 0           ;; limpia el buffer auxiliar
            xor si, si
            jmp _validateLogin1                 ;; continua con el ciclo
        _validateLogin4:                        
            mov strBuffer[si], al               ;; guarda el caracter leído
            inc si                              ;; incrementa el indice
            jmp _validateLogin1                 ;; continua con el ciclo
    _validateLogin5:
        xor si, si
        flushStr strbuffer, 80, 0               ;; limpia el buffer auxiliar
    movsx ax, flag
    cmp ax, 1
    jnz _validateLogin9                         ;; termina el procedimiento
    mov flag, 2                                 ;; usuario coincide , contraseña no coincide
    _validateLogin6:
        readFile fileHandler, fileBuffChar, 1   ;; recupera un caracter del archivo
        mov al, fileBuffChar
        _validateLogin7:
            cmp al, 10                          ;; es final de linea
            jnz _validateLogin8                 ;; continúa el ciclo
            compareStr strBuffer, passwordTemp  ;; compara las cadenas
            jnz _validateLogin9                 ;; termina el ciclo
            mov flag, 1                         ;; ambas cadenas son iguales
            jmp _validateLogin9                  ;; termina el ciclo
        _validateLogin8:
            mov strBuffer[si], al               ;; guarda el caracter leído
            inc si                              ;; incrementa el indice
            jmp _validateLogin6                 ;; continúa con el ciclo
    _validateLogin9:
        closeFile fileHandler
        movsx ax, flag                          ;; mueve el resultado de flag a ax
    ret
validateLogin endp

;--------------------------------------------------
signup proc near c uses ebx ecx edx esi edi
; Abre el archivo de usuario y busca una coincidencia
; con el nombre de usuario dado
; el resultado se almacena en ax, 0 no coincide, 1 si coincide
;-------------------------------------------------- 
    local lenFile : word
    mov lenFile, 0
    openFile userFile, fileHandler
    getFileLength fileHandler
    mov cx, 10
    xor si, si
    _writeUser:                             ;; escribe el nombre de usuario
        mov al, usernameTemp[si]
        cmp al, 32                          ;; si es un espacio, no lo escribe
        jz _writeUserIncSi
        cmp al, 0                           ;; si es un nulo, no lo escribe
        jz _writeUserIncSi
        mov fileBuffChar, al
        writeFile fileHandler, fileBuffChar, 1
        _writeUserIncSi:
            inc si
            loop _writeUser
    mov fileBuffChar, 59
    writeFile fileHandler, fileBuffChar, 1  ;; escribe un punto y coma
    mov cx, 10
    xor si, si
    _writePass:                             ;; escribe la contraseña del usuario
        mov al, passwordTemp[si]
        cmp al, 32                          ;; si es un espacio, no lo escribe
        jz _writePassIncSi
        cmp al, 0                           ;; si es un nulo, no lo escribe
        jz _writePassIncSi
        mov fileBuffChar, al
        writeFile fileHandler, fileBuffChar, 1
        _writePassIncSi:
            inc si
            loop _writePass
    mov fileBuffChar, 0ah
    writeFile fileHandler, fileBuffChar, 1  ;; escribe un nueva línea
    closeFile fileHandler
    printStrln offset ln
    printStrln offset mainmenu3
    ret
signup endp

;--------------------------------------------------
validateFile proc near c uses eax ebx ecx edx esi edi
; Recupera la extensión del nombre del archivo alojado en
; la variable strVar y la copia a strBuffer. 
;--------------------------------------------------
    xor cx, cx
    xor si, si
    xor di, di
    flushStr strBuffer, 80, 0
    mov cx, 10
    _validateFile1:
        mov al, strVar[si]
        cmp al, '.'                       ;; termina el proceso
        jz _validateFile2
        inc si
        loop _validateFile1
    _validateFile2:
        inc si
    _validateFile3:
        mov al, strVar[si]
        cmp al, 0   
        jz _validateFile4                 ;; termina el proceso
        mov strBuffer[di], al
        inc si
        inc di
        jmp _validateFile3               ;; copia la extensión
    _validateFile4:
    ret
validateFile endp

end


    ; call videoStart
    ; call initGame
    ;_1:
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
    ;_2:
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