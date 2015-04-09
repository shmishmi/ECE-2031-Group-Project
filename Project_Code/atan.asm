
ADDI 5
STORE X
ADDI 2
STORE Y
CALL atan
here:
JUMP here



atan:
;initialize variables (for repeated calls)
	LOAD Zero
	STORE INDEX
	STORE YBIG
	ADDI 1
	STORE quadrant
;we might want to add scaling in the hardware division, because we have more bits there (can scale up larger) then divide by number.

;change x and y so that they are relative to your current location
;IN XPOS
LOAD XPOS
DIV OneFoot      ;these divides are going to round down to the nearest foot, we might want to change and use robot units
STORE temp
LOAD X 
SUB temp
STORE xtemp

;IN YPOS
LOAD YPOS
DIV OneFoot

STORE temp
LOAD Y
SUB temp
STORE ytemp

;this isn't necessary once the relative position thing is working
;LOAD Y 
;STORE ytemp
;LOAD X 
;STORE xtemp


;find quadrant
	;Reset Sign Check
	LOAD MaskSign 
	AND  ytemp ; Get sign bit of y
	STORE signcheck
	;If y is positive go to x
	;If y is negative take abs. value,
	;and go to quad 3 (because y is negative in quad 3).
	LOAD ytemp  
	JPOS quadx
	LOAD Zero
	SUB ytemp
	STORE ytemp
	LOAD Three
	STORE quadrant

quadx:
	LOAD xtemp
	AND MaskSign ;Get sign of x
	XOR signcheck ;Check to see if sign of y and x are the same
	;Figure out quadrant
	JZERO checkx ; x and y are both the same sign
	LOAD One ; different signs add one to quadrant
	ADD quadrant 
	STORE quadrant
;Make x positive if not already
;Needed for actual function
checkx:
	LOAD xtemp
	JPOS compxy
	LOAD ZERO
	SUB xtemp
	STORE xtemp

;switch x and y if y is bigger
;
compxy:
	LOAD ytemp
	SUB xtemp
	
	JNEG findindex ;If x is bigger move to atan subroutine
	;Switch X and Y if Y is bigger
	;Need for 90 - atan(x/y)
	LOAD One
	STORE YBIG
	LOAD xtemp
	STORE TEMP
	LOAD ytemp
	STORE xtemp
	LOAD TEMP
	STORE ytemp

findindex:
	LOAD ytemp
	SHIFT 11
	DIV xtemp
	STORE yoverx   ;yoverx = floor(y*2048/x)
;from division scaled up by 2048, find table index 
;gets the value at the index
	load index
	
indexloop: 
	;scale by 2048
	SHIFT 5   ;shift 5 is multiply by scale (2048) and divide by n-1 (64)
	SUB yoverx
	;if yoverx bigger (AC negative) increment index and continue
	JNEG cont
	;if index is bigger then we've gone far enough
	;LOAD index   ;normal code
	;ADDI offset
	;STORE index
	;ILOAD index
	;STORE TEMP
	
	;interpolation
	LOAD index
	;SHIFT 5            ;this is scale / n , change the value accordingly
	STORE x2
	ADDI -1            ;use this value for delta x (this will change based on scale and n) 
	STORE x1
	
	ADDI offset
	STORE y1
	ILOAD y1
	STORE y1
	
	LOAD x2
	ADDI offset
	STORE y2
	ILOAD y2
	
	STORE y2       
	
	SUB y1
	STORE y2         ;using this for deltay
	
	LOAD x1
	SHIFT 5
	STORE x1      ;get x1 on same scale as yoverx 
	
	LOAD yoverx
	SUB x1
	MULT y2      ;using y2 so i don't have to use another memory location, this is just deltay
	SHIFT -5   ;this is the same as dividing by delta x since in this case it is 32
	ADD y1
	STORE TEMP
	
	
	
	;end interpolation
	
	
	;Check if Y was bigger
	LOAD YBIG
	JZERO quadcalc

	LOAD Deg90
	SUB TEMP
	STORE TEMP

;Find the correct quadrant
;Adjust value accordingly
quadcalc:
	;Angle = temp
	LOAD quadrant
	ADDI -1
	JPOS qtwo
	LOAD TEMP
	JUMP done

qtwo:
	;Angle = 180 - atan(y/x)
	ADDI -1
	JPOS qthree
	LOAD Deg180
	SUB TEMP
	JUMP done

qthree:
	;Angle = 180 + temp
	ADDI -1
	JPOS qfour
	LOAD Deg180
	ADD TEMP 
	JUMP done

qfour:
	;Angle = 360 - temp
	LOAD Deg360
	SUB TEMP

done:
	;OUT SSEG1
	STORE ANGLE
	RETURN
cont:
	LOAD index
	ADDI 1
	STORE index
	JUMP indexloop
	;end atan
	
;***************************************************************
;* Variables
;***************************************************************
Temp:     DW 0 ; "Temp" is not a great name, but can be useful

;***************************************************************
;* Constants
;* (though there is nothing stopping you from writing to these)
;***************************************************************
NegOne:   DW -1
Zero:     DW 0
One:      DW 1
Two:      DW 2
Three:    DW 3
Four:     DW 4
Five:     DW 5
Six:      DW 6
Seven:    DW 7
Eight:    DW 8
Nine:     DW 9
Ten:      DW 10


; Some bit masks.
; Masks of multiple bits can be constructed by ORing these
; 1-bit masks together.
Mask0:    DW &B00000001
Mask1:    DW &B00000010
Mask2:    DW &B00000100
Mask3:    DW &B00001000
Mask4:    DW &B00010000
Mask5:    DW &B00100000
Mask6:    DW &B01000000
Mask7:    DW &B10000000
MaskSign: DW &H8000
LowByte:  DW &HFF      ; binary 00000000 1111111
LowNibl:  DW &HF       ; 0000 0000 0000 1111
; some useful movement values
OneMeter: DW 961       ; ~1m in 1.05mm units
HalfMeter: DW 481      ; ~0.5m in 1.05mm units
TwoFeet:  DW 586       ; ~2ft in 1.05mm units
OneFoot:  DW 293       ; 1 foot (using math, I get 290?) used for converting in goto
Deg90:    DW 90        ; 90 degrees in odometer units
Deg180:   DW 180       ; 180
Deg270:   DW 270       ; 270
Deg360:   DW 360       ; can never actually happen; for math only
FSlow:    DW 100       ; 100 is about the lowest velocity value that will move
RSlow:    DW -100
FMid:     DW 350       ; 350 is a medium speed
RMid:     DW -350
FFast:    DW 500       ; 500 is almost max speed (511 is max)
RFast:    DW -500

MinBatt:  DW 130       ; 13.0V - minimum safe battery voltage
I2CWCmd:  DW &H1190    ; write one i2c byte, read one byte, addr 0x90
I2CRCmd:  DW &H0190    ; write nothing, read one byte, addr 0x90


X:        DW 0         ; change these to desired values before calling arctangent
Y:        DW 0
ANGLE:    DW 0         ; Angle that should be turned to
YBIG:     DW 0         ;
yoverx:   DW 0         ;initialize y/x to zero
signcheck:     DW 1         ;
right:    DW 0
left:     DW 0
sum:      DW 0         ;currently assuming X/Y are in feet
xtemp:    DW 0
ytemp:    DW 0
slowdown: DW 440       ;this is where we should switch to fslow. 440 is ~1.5 feet, which is roughly 2/sqrt(2)

;stuff for interpolation
y1: DW 0
y2: DW 0
x1: DW 0
x2: DW 0


;must be defined at start of atan
index:    DW 0         ; initalize the index to zero
quadrant:      DW 1         ; default quadrant is 1


;extra things for testing (remove)
XPOS: DW 0
YPOS: DW 0


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
