;AC max is 65536
ORG        &H000       ;Begin program at x000

atan:
;divide y by x

;for testing while I don't have divide

LOAD index
ADD num

STORE yoverx

;from division scaled up by 4096, find table index 


;gets the value at the index
load index
findindex: 
;scale by 4096
;DIV n

SHIFT 6   ;shift 6 is multiply by scale (4096) and divide by n-1 (64)

SUB yoverx

;if yoverx bigger (AC negative) increment index and continue
JNEG cont

;if index is bigger then we've gone far enough
LOAD index
ADDI offset
STORE index
ILOAD index
here:
jump here   ;this is here so i can tell when it finishes, replace with return when added to code
;RETURN

cont:
LOAD index
ADDI 1
STORE index
JUMP findindex



index:  DW 0  ;initalize the index to zero
yoverx: DW 0 ;initialize y/x to zero
num:    DW 896 ;this is a test input y/x 
;n should be table length -1
n: EQU 64

;place in memory where the table starts
offset: EQU 50 

;include table here
ORG        &H032
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


