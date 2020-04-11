.code
bubbleSort proto far c startArr : ptr word, sizeArr : word
quickSort proto far c startArr : ptr word, arrLow : word, arrHigh : word
shellSort proto far c startArr : ptr word, arrLength : word
printPixel proto far c color : byte, column : word, row : word
externdef initPrint:far
externdef videoStart:far
externdef clearScreen:far
externdef videoStop:far
externdef syncBuffer:far
externdef initGame:far
externdef printFrame:far
@curseg ends