.code
;; --------------------------------------------------
;; array functions
;; --------------------------------------------------
initArray proto far c arraytype : word, maxValue : word
externdef playArray:far
externdef usrScore1:word
externdef usrTime1:word
externdef noUsers:word
;; --------------------------------------------------
;; video functions
;; --------------------------------------------------
syncBuffer proto far c videoPos : word, startPos : word, base : word, heigth : word, offPos : word
;; --------------------------------------------------
;; game functions
;; --------------------------------------------------
loadLine proto far c nameFile : word
externdef initGame:far          ;; inicializa variables para el juego
externdef loadGameFiles:far      ;; carga modelos
externdef playGame:far          ;; otorga el control al juego
externdef gameloaded:byte       ;; var : juego cargado?
externdef userStr:byte          ;, var : nombre usuario
@curseg ends