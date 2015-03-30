;this file is for testing arctangent
Main:
ADDI -2
STORE Y
ADDI 7
STORE X
CALL atan
here:
jump here
;subroutine
atan:
;initialize variables (for repeated calls)
LOAD ZERO
STORE INDEX
ADDI 1
STORE quadrant

;find quadrant
LOAD Mask
STORE signcheck

LOAD Y 
JPOS quadx
LOAD ZERO
SUB Y
STORE Y
LOAD THREE
STORE quadrant

quadx:
LOAD X
AND Mask
XOR signcheck
JZERO checkx
LOAD ONE
ADD quadrant 
STORE quadrant

checkx:
LOAD X
JPOS compxy
LOAD ZERO
SUB X
STORE X

;switch x and y if y is bigger
compxy:
LOAD Y
SUB X

JNEG findindex
LOAD ONE
STORE YBIG
LOAD X
STORE TEMP
LOAD Y
STORE X
LOAD TEMP
STORE Y

findindex:
LOAD Y
SHIFT 11
DIV X
STORE yoverx
;from division scaled up by 2048, find table index 
;gets the value at the index
load index
indexloop: 
;scale by 2048
SHIFT 5   ;shift 6 is multiply by scale (2048) and divide by n-1 (64)
SUB yoverx
;if yoverx bigger (AC negative) increment index and continue
JNEG cont
;if index is bigger then we've gone far enough
LOAD index
ADDI offset
STORE index
ILOAD index
STORE TEMP

LOAD YBIG
JZERO quadcalc

LOAD NINETY
SUB TEMP
STORE TEMP

quadcalc:
LOAD quadrant
ADDI -1
JPOS qtwo
LOAD TEMP
JUMP done

qtwo:
ADDI -1
JPOS qthree
LOAD OneEighty
SUB TEMP
JUMP done

qthree:
ADDI -1
JPOS qfour
LOAD OneEighty
ADD TEMP 
JUMP done

qfour:
LOAD ThreeSixty
SUB TEMP

done:
STORE ANGLE
RETURN
cont:
LOAD index
ADDI 1
STORE index
JUMP indexloop
;end atan
ZERO:     DW 0
THREE:    DW 3
NINETY:   DW 90
OneEighty: DW 180
ThreeSixty: DW 360
Mask:        DW &H8000 
ONE:      DW 1 
NegOne:   DW -1
X:        DW 0         ; change these to desired values before calling arctangent
Y:        DW 0
TEMP:     DW 0         ; Temp so arctan can switch x and y
ANGLE:    DW 0         ; Angle that should be turned to
yoverx:   DW 0         ;initialize y/x to zero
YBIG:          DW 0         ;
signcheck:     DW 1         ;

;these have to be initialized every time
index:         DW 0         ; initalize the index to zero
quadrant:      DW 1         ; default quadrant is 1


n:        EQU 64    ;n should be table length -1

offset:
DW 0  ;0
DW 1  ;1
DW 2  ;2
DW 3  ;3
DW 4  ;4
DW 4  ;5
DW 5  ;6
DW 6  ;7
DW 7  ;8
DW 8  ;9
DW 9  ;10
DW 10 ;11
DW 11 ;12
DW 11 ;13
DW 12 ;14
DW 13
DW 14
DW 15
DW 16
DW 17
DW 17
DW 18
DW 19
DW 20
DW 21
DW 21
DW 22
DW 23
DW 24
DW 24
DW 25
DW 26
DW 27
DW 27
DW 28
DW 29
DW 29
DW 30
DW 31
DW 31
DW 32
DW 33
DW 33
DW 34
DW 35
DW 35
DW 36
DW 36
DW 37
DW 37
DW 38
DW 39
DW 39
DW 40
DW 40
DW 41
DW 41
DW 42
DW 42
DW 43
DW 43
DW 44
DW 44
DW 45
DW 45
