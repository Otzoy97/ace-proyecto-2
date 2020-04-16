.code
;; array functions
bubbleSort proto far c startArr : ptr word, sizeArr : word
quickSort proto far c startArr : ptr word, arrLow : word, arrHigh : word
shellSort proto far c startArr : ptr word, arrLength : word
;; video functions
syncBuffer proto far c videoPos : word, startPos : word, base : word, heigth : word, offPos : word
;; game functions
externdef initGame:far
externdef playGame:far
;; global variables
externdef levelsInfo:byte
externdef penaltyScore:word
externdef rewardScore:word
externdef actualUser:byte
externdef userStr:byte
externdef lvlStr:byte
@curseg ends