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
adminOp         db  "  1) Top 10 (punteo)", 0ah, 0dh
                db  "  2) Top 10 (tiempo)", 0ah, 0dh
                db  "  3) Salir", 0ah, 0dh, '$'
scoresFN        db "scores.tzy", 00         ;; archivo que DEBE de existir
puntosFN        db "puntos.rep", 00         ;; archivo que DEBE de existir
tiempoFN        db "tiempos.rep", 00        ;; archivo que DEBE de existir
usrName         db  200 dup(0)              ;; TopScores
usrName1        db  200 dup(0)              ;; TopTime

usrScore        dw  20  dup(0)              ;; TopScores
usrScore1       dw  20  dup(0)              ;; Ordenamiento
usrScore2       dw  20  dup(0)              ;; Referencia

usrLevel        db  20  dup(0)              ;; TopScores
usrLevel1       db  20  dup(0)              ;; TopTime

usrTime         dw  20  dup(0)              ;; TopTime
usrTime1        dw  20  dup(0)              ;; Ordenamiento
usrTime2        dw  20  dup(0)              ;; Referencia

noUsers         dw  ?                       ;; especifica el número de usuario
byte2Number     db  0,0,0,0,0,0,'$'         ;; auxiliar para alojar numeros ascii

topScoreHeader  db  "                                 TOP 10  PUNTOS                                 "
topTimesHeader  db  "                                 TOP 10 TIEMPOS                                 "
lateral1        db  "                      "
lateral2        db  "                      "
NoData          db  "  No hay datos para mostrar$"
pressSpaceKey   db  "  Presione la barra espaciadora para continuar...$"
vram            dw  ?                       ;; guardará la pos de mem de video
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
chooseOp        db  "  Elija una opci", 162,"n : $"
setFileName     db  "  Escriba el nombre del archivo .ply : $"
wrongExtFile    db  "  Archivo inv", 160,"lido. No coincide la extensi", 162, "n$"
playFailed      db  "  No hay juego cargado. No se puede iniciar juego$"
openFileFailed  db  "  No se puede abrir el archivo.$"
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
fileBuffWord    dw  ? 
;--------------------------------------------------
.code
.startup
    mov ax, @data
    mov ds, ax
main proc near c
    call loadGameFiles                                  ;; carga los archivos del juego
    _mainStart:
        clearScreen                                     ;; limpia la pantalla
        invoke headerMain, 0, 9, offset mainmenu5, 33   ;; imprime en [9][0]
        printStr offset mainmenu                        ;; muestra las opciones disponibles
        flushStr strVar, 80, 0
        getLine strVar                                  ;; recupera la opción del usuario
        compareStr strVar, cte1
        jz _mainLogin                                   ;; iniciar sesión
        compareStr strVar, cte2
        jz _mainSignup                                  ;; nuevo usuario
        compareStr strVar, cte3
        jz _endMain                                     ;; termina el programa
        printStrln offset ln
        printStrln offset wrongOpt
        pauseAnyKey
        jmp _mainStart
    _mainLogin:
        clearScreen
        invoke headerMain, 0, 9, offset mainmenu6, 33   ;; imprime un pequeño encabezado
        printStr offset mainmenu1
        flushStr usernameTemp, 10, 0
        flushStr passwordTemp, 10, 0
        getLine usernameTemp
        printStrln offset ln
        printStr offset mainmenu2
        getLine passwordTemp                            ;; recupera la opción del usuario
        compareStr userAdmin, usernameTemp
        jnz _mainLoginUsr                               ;; es igual a 'admin'?
        compareStr passAdmin, passwordTemp              
        jnz _mainLoginUsr                               ;; es igual a '1234'?
            call mainAdmin                             ;; ir a modulo administrador
        jmp _mainStart
        _mainLoginUsr:
            call validateLogin
            .if (ax == 1)                               ;; si es igual a 1, existe el usuario y contraseña
                call mainUser                           ;; ir a modulo de usuario
            .else
                printStrln offset ln
                printStrln offset mainmenu4
                pauseAnyKey                 
            .endif
            jmp _mainStart
    _mainSignup:
        clearScreen
        invoke headerMain,0,9,offset mainmenu7,31       ;; imprime un encabezado
        printStr offset mainmenu1
        flushStr usernameTemp, 10, 0
        flushStr passwordTemp, 10, 0
        getLine usernameTemp                            ;; recupera el usuario
        printStrln offset ln
        printStr offset mainmenu2
        getLine passwordTemp                            ;; recupera la contraseña
        call validateLogin
        .if (ax == 0)                                   ;; usuario no coincide == usuario disponible
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
    flushStr userStr, 10, 32
    mov cx, 10
    xor si, si
    _setUserName:
        mov al, usernameTemp[si]
        cmp al, 0
        jz _mainUser1
        mov userStr[si], al
        inc si
        loop _setUserName
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
        mov al, gameloaded
        cmp al, 1
        jz _mainUser21
        printStrln offset ln
        printStrln offset playFailed
        pauseAnyKey
        jmp _mainUser1
        _mainUser21:
            call initGame
            call playGame
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
            .if (carry?)
                printStrln offset ln
                printStrln offset openFileFailed
            .else
                push ds
                invoke loadLine, fileHandler        ;; carga el archivo
                pop ds
                closeFile fileHandler               ;; cierra el archivo
            .endif
            pauseAnyKey
            jmp _mainUser1
    _mainUser4:
    ret
mainUser endp

;--------------------------------------------------
; Convierte un número de 2 bytes a ascii
toAsciiP2 proc near c uses eax ebx ecx edx esi , number : word, off : ptr word
;--------------------------------------------------
    xor cx, cx
    xor dx, dx
    mov ax, number
    .if (ax == 0)
        mov bx, off
        mov al, '0'
        mov [bx], al
    .endif
    mov bx, 10
    .while( ax != 0)
        cwd
        div bx
        push dx
        xor dx, dx
        inc cx
    .endw
    mov bx, off
    xor si, si
    .while (cx != 0)
        pop ax
        add ax, '0'
        mov [bx + si], al
        inc si
        dec cx
    .endw
    ret
toAsciiP2 endp

;--------------------------------------------------
loadScores proc near c uses eax esi
; Abre el archivo puntos.rep y carga los punteos a 
; las variables respectivas
;--------------------------------------------------
    local i : word
    mov i, 0
    xor si, si
    flushStr usrName, 200, 0
    flushStr usrName1, 200, 0
    flushStr usrScore, 40, 0
    flushStr usrScore1, 40, 0
    flushStr usrScore2, 40, 0
    flushStr usrLevel, 20, 0
    flushStr usrLevel1, 20, 0
    flushStr usrTime, 40, 0
    flushStr usrTime1, 40, 0
    flushStr usrTime2, 40, 0
    mov noUsers, 0
    openFile scoresFN, fileHandler
    jc _getLine6
    _getLine1:
        readFile fileHandler, fileBuffChar, 1               ;; lee un caracter
        cmp ax, 0                                           ;; se leyó algo?
        jz _getLine5                                        ;; termina el proceso
        mov ax, i
        cmp ax, 20
        jae _getLine5                                       ;; termina el proceso
        shl ax, 1                                           ;; i * 2
        mov si, ax                                          ;; i * 2
        shl ax, 2                                           ;; i * 2 * 4
        add si, ax                                          ;; i * 2 + i *8
        mov al, fileBuffChar
        mov usrName[si], al
        mov usrName1[si], al
        inc si
        _getLine3:
            readFile fileHandler, fileBuffChar, 1
            mov al, fileBuffChar
            cmp al, 59                                      ;; es igual a punto y coma
            jz _getLine4
            mov usrName[si], al
            mov usrName1[si], al
            inc si
            jmp _getLine3
        _getLine4:
            readFile fileHandler, fileBuffWord, 2
            mov ax, fileBuffWord
            mov si, i
            shl si, 1                                       ;; i * 2
            mov usrScore[si], ax                            ;; guarda punteo
            mov usrScore1[si], ax                           ;; guarda punteo
            mov usrScore2[si], ax                           ;; guarda punteo
            readFile fileHandler, fileBuffChar, 1           ;; lee un punto y coma
            readFile fileHandler, fileBuffWord, 2       
            mov ax, fileBuffWord
            mov usrTime[si], ax                             ;; guarda segundos
            mov usrTime1[si], ax                            ;; guarda segundos
            mov usrTime2[si], ax                            ;; guarda segundos
            readFile fileHandler, fileBuffChar, 1           ;; lee un punto y coma
            readFile fileHandler, fileBuffChar, 1
            mov si, i
            mov al, fileBuffChar
            mov usrLevel[si], al                            ;; guarda nivel
            mov usrLevel1[si], al                           ;; guarda nivel
            readFile fileHandler, fileBuffChar, 1           ;; lee final de línea
            inc i
            jmp _getLine1
    _getLine5:
        mov ax, i
        mov noUsers, ax                                     ;; guarda el número de usuarios guardados
        closeFile fileHandler
        ret
    _getLine6:
    pauseAnyKey
    ret
loadScores endp

;--------------------------------------------------
sortTime proc near c uses eax ecx esi edi ebx 
; Ordena de forma ascendente un arreglo que inicia 
; en statArr y de tamaño sizeArr
;--------------------------------------------------
    xor cx, cx
    xor si, si
    mov cx, noUsers                         ;; especifica el tamaño del arreglo
    dec cx                                  ;; disminiuye el tamaño del arreglo
    .if (cx == 0)
        jmp _4bS
    .endif
    _1bS:
        push cx                             ;; almacena al contador principal
        xor si, si                          ;; especifica el inicio del arreglo
        xor di, di
    _2bS:
        mov ax, usrTime[si]
        mov bh, usrLevel1[di]
        cmp ax, usrTime[si + 2]             ;; compara el valor actual con el valor siguiente
        jl _3bS                             ;; si es menor no hace nada
        xchg ax, usrTime[si + 2]            ;; intercambia los valores
        xchg bh, usrLevel1[di + 1]
        mov usrTime[si], ax    
        mov usrLevel1[di], bh
        push di
            mov ax, di
            shl ax, 1                       ;; ax*2
            mov di, ax
            shl ax, 2                       ;; ax*8
            add di, ax
            mov ax, di
            add ax, 10
            _2bS1:
                cmp di, ax                  ;; di < ax
                jae _2bS2
                mov bl, usrName1[di]
                push di
                add di, 10                  ;; di + 10 (siguiente posición)
                xchg bl, usrName1[di]       ;; intercambia los bytes
                pop di
                mov usrName1[di], bl        ;; intercambia los bytes
                inc di
                jmp _2bS1
        _2bS2:
        pop di
    _3bS:  
        add si, 2                           ;; el apuntador avanza
        inc di
        loop _2bS
        pop cx                              ;; reestablece el contador anterior
        loop _1bS
    _4bS:
    ret 
sortTime endp

;--------------------------------------------------
sortScore proc near c uses eax ecx esi edi ebx 
; Ordena de forma ascendente un arreglo que inicia 
; en statArr y de tamaño sizeArr
;--------------------------------------------------
    xor cx, cx
    xor si, si
    mov cx, noUsers                         ;; especifica el tamaño del arreglo
    dec cx                                  ;; disminiuye el tamaño del arreglo
    .if (cx == 0)
        jmp _4bS
    .endif
    _1bS:
        push cx                             ;; almacena al contador principal
        xor si, si
        xor di, di
    _2bS:
        mov ax, usrScore[si]
        mov bh, usrLevel[di]
        cmp ax, usrScore[si + 2]            ;; compara el valor actual con el valor siguiente
        jl _3bS                             ;; si es menor no hace nada
        xchg ax, usrScore[si + 2]           ;; intercambia los valores
        xchg bh, usrLevel[di + 1]
        mov usrScore[si], ax
        mov usrLevel[di], bh
        push di
            mov ax, di
            shl ax, 1                       ;; ax*2
            mov di, ax
            shl ax, 2                       ;; ax*8
            add di, ax
            mov ax, di
            add ax, 10
            _2bS1:
                cmp di, ax                  ;; di < ax
                jae _2bS2
                mov bl, usrName[di]
                push di
                add di, 10                  ;; di + 10 (siguiente posición)
                xchg bl, usrName[di]       ;; intercambia los bytes
                pop di
                mov usrName[di], bl        ;; intercambia los bytes
                inc di
                jmp _2bS1
        _2bS2:
        pop di
    _3bS:  
        add si, 2                           ;; el apuntador avanza
        inc di
        loop _2bS
        pop cx                              ;; reestablece el contador anterior
        loop _1bS
    _4bS:
    ret 
sortScore endp

;--------------------------------------------------
topScores proc near c uses eax ecx edi
; Imprime el top 10 de puntos
;--------------------------------------------------
    local i : word, noUsersTemp : word
    mov ax, noUsers
    mov noUsersTemp, 1
    mov i, ax
    createFile puntosFN, fileHandler
    mov fileBuffChar, 32
    mov cx, 80
    _topScores1:
        writeFile fileHandler, fileBuffChar, 1
        loop _topScores1
    mov fileBuffChar, 0ah                               ;; termina la parte sup del marco
    writeFile fileHandler, fileBuffChar, 1
    writeFile fileHandler, topScoreHeader, 80
    mov fileBuffChar, 0ah                               ;; termina la parte sup del marco
    writeFile fileHandler, fileBuffChar, 1
    _topScores2:
        cmp noUsersTemp, 10
        jg _topScores8
        cmp i, 0
        je _topScores8
        writeFile fileHandler, lateral1, 22
        invoke toAsciiP2, noUsersTemp, offset byte2Number
        .if (noUsersTemp < 10)
            writeFile fileHandler, byte2Number, 1
            mov cx, 7
        .else
            writeFile fileHandler, byte2Number, 2
            mov cx, 6
        .endif
        mov al, '.'
        mov fileBuffChar, al
        writeFile fileHandler, fileBuffChar, 1          ;; escribe un lateral
        mov al, 32
        mov fileBuffChar, al
        _topScores3:
            writeFile fileHandler, fileBuffChar, 1      ;; escribe 6 o 7 espacios
            loop _topScores3
        mov ax, i
        dec ax
        shl ax, 1                                       ;; i * 2
        mov di, ax
        shl ax, 2                                       ;; i * 8
        add di, ax
        mov cx, 10
        _topScores4:
            mov al, usrName[di]
            .if (al == 0)
                mov al, 32
            .endif
            mov fileBuffChar, al
            writeFile fileHandler, fileBuffChar, 1      ;; escribe el nombre
            inc di
            loop _topScores4
        mov cx, 5
        mov al, 32
        mov fileBuffChar, al
        _topScores5:
            writeFile fileHandler, fileBuffChar, 1      ;; escribe 5 espacios
            loop _topScores5
        mov ax, i
        dec ax
        mov di, ax
        movzx ax, usrLevel[di]
        invoke toAsciiP2, ax, offset byte2Number
        writeFile fileHandler, byte2Number, 1           ;; escribe el nivel
        mov cx, 5
        mov al, 32
        mov fileBuffChar, al
        _topScores6:
            writeFile fileHandler, fileBuffChar, 1      ;; escribe 5 espacios
            loop _topScores6
        flushStr byte2Number, 6, 0
        mov ax, i
        dec ax
        shl ax, 1                                       ;; lo multiplica por 2
        mov di, ax
        mov ax, usrScore[di]
        invoke toAsciiP2, ax, offset byte2Number
        xor di, di
        mov cx, 6
        _topScores7:
            mov al, byte2Number[di]
            .if (al == 0)
                mov al, 32
            .endif
            mov fileBuffChar, al
            writeFile fileHandler, fileBuffChar, 1      ;; escribe el punteo
            inc di
            loop _topScores7
        writeFile fileHandler, lateral2, 22
        mov fileBuffChar, 0ah                           ;; termina la parte sup del marco
        writeFile fileHandler, fileBuffChar, 1
        dec i
        inc noUsersTemp
        jmp _topScores2
    _topScores8:
        closeFile fileHandler
    ret
topScores endp

;-------------------------------------------------- 
topTime proc near c uses eax ebx ecx edx esi edi
; Imprime el top 10 tiempos
;--------------------------------------------------
    local i : word, noUsersTemp : word
    mov ax, noUsers
    mov noUsersTemp, 1
    mov i, ax
    createFile tiempoFN, fileHandler
    mov fileBuffChar, 32
    mov cx, 80
    _topScores1:
        writeFile fileHandler, fileBuffChar, 1
        loop _topScores1
    mov fileBuffChar, 0ah                               ;; termina la parte sup del marco
    writeFile fileHandler, fileBuffChar, 1
    writeFile fileHandler, topTimesHeader, 80
    mov fileBuffChar, 0ah                               ;; termina la parte sup del marco
    writeFile fileHandler, fileBuffChar, 1
    _topScores2:
        cmp noUsersTemp, 10
        jg _topScores8
        cmp i, 0
        je _topScores8
        writeFile fileHandler, lateral1, 22
        invoke toAsciiP2, noUsersTemp, offset byte2Number
        .if (noUsersTemp < 10)
            writeFile fileHandler, byte2Number, 1
            mov cx, 7
        .else
            writeFile fileHandler, byte2Number, 2
            mov cx, 6
        .endif
        mov al, '.'
        mov fileBuffChar, al
        writeFile fileHandler, fileBuffChar, 1          ;; escribe un lateral
        mov al, 32
        mov fileBuffChar, al
        _topScores3:
            writeFile fileHandler, fileBuffChar, 1      ;; escribe 6 o 7 espacios
            loop _topScores3
        mov ax, i
        dec ax
        shl ax, 1                                       ;; i * 2
        mov di, ax
        shl ax, 2                                       ;; i * 8
        add di, ax
        mov cx, 10
        _topScores4:
            mov al, usrName1[di]
            .if (al == 0)
                mov al, 32
            .endif
            mov fileBuffChar, al
            writeFile fileHandler, fileBuffChar, 1      ;; escribe el nombre
            inc di
            loop _topScores4
        mov cx, 5
        mov al, 32
        mov fileBuffChar, al
        _topScores5:
            writeFile fileHandler, fileBuffChar, 1      ;; escribe 5 espacios
            loop _topScores5
        mov ax, i
        dec ax
        mov di, ax
        movzx ax, usrLevel1[di]
        invoke toAsciiP2, ax, offset byte2Number
        writeFile fileHandler, byte2Number, 1           ;; escribe el nivel
        mov cx, 5
        mov al, 32
        mov fileBuffChar, al
        _topScores6:
            writeFile fileHandler, fileBuffChar, 1      ;; escribe 5 espacios
            loop _topScores6
        flushStr byte2Number, 6, 0
        mov ax, i
        dec ax
        shl ax, 1                                       ;; lo multiplica por 2
        mov di, ax
        mov ax, usrTime[di]
        invoke toAsciiP2, ax, offset byte2Number
        xor di, di
        mov cx, 6
        _topScores7:
            mov al, byte2Number[di]
            .if (al == 0)
                mov al, 32
            .endif
            mov fileBuffChar, al
            writeFile fileHandler, fileBuffChar, 1      ;; escribe el punteo
            inc di
            loop _topScores7
        writeFile fileHandler, lateral2, 22
        mov fileBuffChar, 0ah                           ;; termina la parte sup del marco
        writeFile fileHandler, fileBuffChar, 1
        dec i
        inc noUsersTemp
        jmp _topScores2
    _topScores8:
        closeFile fileHandler
    ret
topTime endp

;--------------------------------------------------
printRep proc near c uses eax ebx ecx edx esi edi, opt : word
; 0 - PUNTOS
; 1 - TIEMPOS
;--------------------------------------------------
    cmp opt, 1
    jz _printRep0
    openFile puntosFN, fileHandler
    jmp _printRep1
    _printRep0:
    openFile tiempoFN, fileHandler
    _printRep1:
        readFile fileHandler, fileBuffChar, 1
        cmp ax, 0
        jz _printRep2
        printChar fileBuffChar
        jmp _printRep1
    _printRep2:
    ret
printRep endp

;--------------------------------------------------
mainAdmin proc near c
; Menú principal para el usuario administrador
;--------------------------------------------------
    call loadScores                                 ;; carga la info de scores.ply
    mov ax, noUsers
    cmp ax, 0
    jz _mainAdmin1
        call sortTime                                   ;; ordena la info para el top 10 de tiempo
        call sortScore                                  ;; ordena la info para el top 10 de puntos
    _mainAdmin1:
        clearScreen
        printStr offset header
        printStrln offset adminOp
        printStr offset chooseOp
        flushStr strVar, 80, 0
        getLine strVar
        compareStr cte1, strVar                     ;; top 10 puntos
        jz _mainAdmin2
        compareStr cte2, strVar                     ;; top 10 tiempo
        jz _mainAdmin3
        compareStr cte3, strVar                     ;; salir
        jz _mainAdmin4
        printStrln offset ln
        printStrln offset wrongOpt
        pauseAnyKey
        jmp _mainAdmin1
    _mainAdmin2:
        mov ax, noUsers
        cmp ax, 0
        jz _mainAdmin21
        call topScores
        clearScreen
        invoke printRep, 0
        printStr offset pressSpaceKey
        pauseSpaceKey
        mov di, noUsers
        dec di
        sal di, 1                                   ;; multiplica por dos
        mov ax, usrScore[di]
        invoke initArray, 0, ax
        call playArray
        jmp _mainAdmin22
        _mainAdmin21:
            printStrln offset ln
            printStrln offset NoData
            pauseAnyKey
        _mainAdmin22:
        jmp _mainAdmin1
    _mainAdmin3:
        mov ax, noUsers
        cmp ax, 0
        jz _mainAdmin31
        call topTime
        clearScreen
        invoke printRep, 1
        printStr offset pressSpaceKey
        pauseSpaceKey
        mov di, noUsers
        dec di
        sal di, 1                                   ;; multiplica por dos
        mov ax, usrTime[di]
        invoke initArray, 1, ax
        call playArray
        jmp _mainAdmin32
        _mainAdmin31:
            printStrln offset ln
            printStrln offset NoData
            pauseAnyKey
        _mainAdmin32:
        jmp _mainAdmin1
    _mainAdmin4:
    ret
mainAdmin endp
end