.code
bubbleSort proto far c startArr : ptr word, sizeArr : word
quickSort proto far c startArr : ptr word, arrLow : word, arrHigh : word
shellSort proto far c startArr : ptr word, arrLength : word
printPixel proto far c color : byte, column : word, row : word
printSquare proto far c color : byte, start : word, base : word, height : word
printPicture proto far c picOff : ptr word, start : word, base : word, height : word
printObs proto far c pos : byte, bType : byte
externdef initPrint:far
externdef videoStart:far
externdef clearScreen:far
externdef videoStop:far
externdef syncBuffer:far
externdef initGame:far
externdef printFrame:far
externdef printBackground:far
externdef printCar:far
externdef printHeader:far
@curseg ends