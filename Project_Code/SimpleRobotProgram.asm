; SimpleRobotProgram.asm
; Created by Kevin Johnson
; (no copyright applied; edit freely, no attribution necessary)
; This program does basic initialization of the DE2Bot
; and provides an example of some robot control.

; Section labels are for clarity only.


ORG        &H000       ;Begin program at x000
;***************************************************************
;* Initialization
;***************************************************************
Init:
	; Always a good idea to make sure the robot
	; stops in the event of a reset.
	LOAD   Zero
	OUT    LVELCMD     ; Stop motors
	OUT    RVELCMD
	OUT    SONAREN     ; Disable sonar (optional)
	
	CALL   SetupI2C    ; Configure the I2C to read the battery voltage
	CALL   BattCheck   ; Get battery voltage (and end if too low).
	OUT    LCD         ; Display batt voltage on LCD

WaitForSafety:
	; Wait for safety switch to be toggled
	IN     XIO         ; XIO contains SAFETY signal
	AND    Mask4       ; SAFETY signal is bit 4
	JPOS   WaitForUser ; If ready, jump to wait for PB3
	IN     TIMER       ; We'll use the timer value to
	AND    Mask1       ;  blink LED17 as a reminder to toggle SW17
	SHIFT  8           ; Shift over to LED17
	OUT    XLEDS       ; LED17 blinks at 2.5Hz (10Hz/4)
	JUMP   WaitForSafety
	
WaitForUser:
	; Wait for user to press PB3
	IN     TIMER       ; We'll blink the LEDs above PB3
	AND    Mask1
	SHIFT  5           ; Both LEDG6 and LEDG7
	STORE  Temp        ; (overkill, but looks nice)
	SHIFT  1
	OR     Temp
	OUT    XLEDS
	IN     XIO         ; XIO contains KEYs
	AND    Mask2       ; KEY3 mask (KEY0 is reset and can't be read)
	JPOS   WaitForUser ; not ready (KEYs are active-low, hence JPOS)
	LOAD   Zero
	OUT    XLEDS       ; clear LEDs once ready to continue

;***************************************************************
;* Main code
;***************************************************************
Main:
	ADDI 2
	STORE X
	STORE Y
	CALL goto
	;LOAD Angle
	;OUT SSEG2
	;LOAD Zero
	;STORE X
	;STORE Y
	;CALL goto
	;IN THETA
	;OUT SSEG1
	CALL Die

Star:		;USING JUST GOTO
	LOAD	One
	STORE	X
	LOAD	Three
	STORE	Y
	CALL	goto
	LOAD	Two
	STORE 	X
	LOAD	Zero
	STORE	Y
	CALL	goto
	LOAD	Two
	STORE	Y
	LOAD	ZERO
	ADDI	-1
	STORE	X
	CALL	goto
	LOAD	Three
	STORE	X
	CALL	goto
	LOAD	ZERO
	STORE	X
	STORE	Y
	CALL	goto

	
	
Die:
; Sometimes it's useful to permanently stop execution.
; This will also catch the execution if it accidentally
; falls through from above.
	LOAD   Zero         ; Stop everything.
	OUT    LVELCMD
	OUT    RVELCMD
	OUT    SONAREN
	LOAD   DEAD         ; An indication that we are dead
	OUT    SSEG2
Forever:
	JUMP   Forever      ; Do this forever.
	DEAD:  DW &HDEAD    ; Example of a "global variable"

	
;***************************************************************
;* Subroutines
;***************************************************************
atan:
;initialize variables (for repeated calls)
    LOAD Zero
    STORE INDEX
    STORE YBIG
    ADDI 1
    STORE quadrant
;we might want to add scaling in the hardware division, because we have more bits there (can scale up larger) then divide by number.

;change x and y so that they are relative to your current location
IN XPOS
;LOAD XPOS        use this if you want to test with pretermined values for XPOS  (also YPOS below)
DIV OneFoot      ;these divides are going to round down to the nearest foot, we might want to change and use robot units
STORE temp
LOAD X 
SUB temp
STORE xtemp

IN YPOS
;LOAD YPOS       ;used for testing
DIV OneFoot

STORE temp
LOAD Y
SUB temp
STORE ytemp

;this isn't necessary once the relative position thing is working (should be working now)
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
	;LOAD index   ;normal code, not needed if interpolation is being used
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

turn:
	IN THETA
	SUB ANGLE	
	JPOS CWorCCW
	ADD Deg360  ;degrees for a CW turn
CWorCCW:
	SUB Deg180  
	JPOS CCW  
CW:       ;wheel speeds if you're turning CW
	LOAD FSLOW
	STORE left
	LOAD RSLOW
	STORE right
	JUMP turnloop
CCW:       ;wheel speeds for turning CCW
	LOAD FSLOW
	STORE right
	LOAD RSLOW
	STORE left
turnloop:
	LOAD right
	OUT RVELCMD
	LOAD left
	OUT LVELCMD
	IN THETA
	;OUT SSEG1
	SUB ANGLE
	JZERO at_angle
	JUMP turnloop
at_angle:
    LOAD Zero
    OUT RVELCMD
    OUT LVELCMD
	RETURN



goto:
	CALL atan
	CALL turn
	CALL WAIT1  ;wheels need to be stopped completely before the robot stops moving or it curves off
	


	LOAD Zero
	STORE temp   ;temp is initialized to zero (must be after atan and turn since they use it)  

	;for moving
	LOAD X         ;convert to odometer units
	MULT OneFoot
	STORE xtemp
	IN XPOS
	SUB xtemp
	JNEG goloop 
	LOAD One
	STORE temp       ;use temp to indicate if xpos was bigger
	
	
	;LOAD Y            ;only need if we're also checking y as an end condition  
	;MULT OneFoot
	;STORE ytemp
goloop:
;deceleration code - finding hypotenuse doesn't work because of overflow. 
	; should test the other code without this, it hould work now
	IN XPOS
	STORE sum
	IN YPOS
	ADD sum
	SUB slowdown
    JPOS normalspeed

    LOAD FSLOW            ;this puts slow to the wheels once you're 1-1.5 feet away from the destination
    OUT RVELCMD
	OUT LVELCMD
    JUMP choosedirection

    normalspeed:
	LOAD FMID
	OUT RVELCMD
	OUT LVELCMD

    choosedirection:
	LOAD temp
	JZERO destinationbigger
	
	destinationsmaller:
	IN XPOS
	SUB xtemp
	JPOS goloop
	JUMP stopmoving
	
	destinationbigger:
	IN XPOS 
	SUB xtemp
	JNEG goloop         
	
	;IN YPOS
	;SUB ytemp
	;JPOS goloop
stopmoving:            ;if we get here we know that the x coordinate is correct
	;LOAD RFAST
	;OUT RVELCMD
	;OUT LVELCMD
	;LOAD ONE
	;CALL Wait1
	
	LOAD Zero
	OUT RVELCMD
	OUT LVELCMD
	RETURN


; Subroutine to wait (block) for 1 second
Wait1:
	OUT    TIMER
Wloop:
	IN     TIMER
	OUT    XLEDS       ; User-feedback that a pause is occurring.
	ADDI   -10         ; 1 second in 10Hz.
	JNEG   Wloop
	RETURN

; Subroutine to wait the number of timer counts currently in AC
WaitAC:
	STORE  WaitTime
	OUT    Timer
WACLoop:
	IN     Timer
	OUT    XLEDS       ; User-feedback that a pause is occurring.
	SUB    WaitTime
	JNEG   WACLoop
	RETURN
	WaitTime: DW 0     ; "local" variable.
	
; This subroutine will get the battery voltage,
; and stop program execution if it is too low.
; SetupI2C must be executed prior to this.
BattCheck:
	CALL   GetBattLvl
	JZERO  BattCheck   ; A/D hasn't had time to initialize
	SUB    MinBatt
	JNEG   DeadBatt
	ADD    MinBatt     ; get original value back
	RETURN
; If the battery is too low, we want to make
; sure that the user realizes it...
DeadBatt:
	LOAD   Four
	OUT    BEEP        ; start beep sound
	CALL   GetBattLvl  ; get the battery level
	OUT    SSEG1       ; display it everywhere
	OUT    SSEG2
	OUT    LCD
	LOAD   Zero
	ADDI   -1          ; 0xFFFF
	OUT    LEDS        ; all LEDs on
	OUT    XLEDS
	CALL   Wait1       ; 1 second
	Load   Zero
	OUT    BEEP        ; stop beeping
	LOAD   Zero
	OUT    LEDS        ; LEDs off
	OUT    XLEDS
	CALL   Wait1       ; 1 second
	JUMP   DeadBatt    ; repeat forever
	
; Subroutine to read the A/D (battery voltage)
; Assumes that SetupI2C has been run
GetBattLvl:
	LOAD   I2CRCmd     ; 0x0190 (write 0B, read 1B, addr 0x90)
	OUT    I2C_CMD     ; to I2C_CMD
	OUT    I2C_RDY     ; start the communication
	CALL   BlockI2C    ; wait for it to finish
	IN     I2C_DATA    ; get the returned data
	RETURN

; Subroutine to configure the I2C for reading batt voltage
; Only needs to be done once after each reset.
SetupI2C:
	CALL   BlockI2C    ; wait for idle
	LOAD   I2CWCmd     ; 0x1190 (write 1B, read 1B, addr 0x90)
	OUT    I2C_CMD     ; to I2C_CMD register
	LOAD   Zero        ; 0x0000 (A/D port 0, no increment)
	OUT    I2C_DATA    ; to I2C_DATA register
	OUT    I2C_RDY     ; start the communication
	CALL   BlockI2C    ; wait for it to finish
	RETURN
	
; Subroutine to block until I2C device is idle
BlockI2C:
	LOAD   Zero
	STORE  Temp        ; Used to check for timeout
BI2CL:
	LOAD   Temp
	ADDI   1           ; this will result in ~0.1s timeout
	STORE  Temp
	JZERO  I2CError    ; Timeout occurred; error
	IN     I2C_RDY     ; Read busy signal
	JPOS   BI2CL       ; If not 0, try again
	RETURN             ; Else return
I2CError:
	LOAD   Zero
	ADDI   &H12C       ; "I2C"
	OUT    SSEG1
	OUT    SSEG2       ; display error message
	JUMP   I2CError

; Subroutine to send AC value through the UART,
; formatted for default base station code:
; [ AC(15..8) | AC(7..0)]
; Note that special characters such as \lf are
; escaped with the value 0x1B, thus the literal
; value 0x1B must be sent as 0x1B1B, should it occur.
UARTSend:
	STORE  UARTTemp
	SHIFT  -8
	ADDI   -27   ; escape character
	JZERO  UEsc1
	ADDI   27
	OUT    UART_DAT
	JUMP   USend2
UEsc1:
	ADDI   27
	OUT    UART_DAT
	OUT    UART_DAT
USend2:
	LOAD   UARTTemp
	AND    LowByte
	ADDI   -27   ; escape character
	JZERO  UEsc2
	ADDI   27
	OUT    UART_DAT
	RETURN
UEsc2:
	ADDI   27
	OUT    UART_DAT
	OUT    UART_DAT
	RETURN
	UARTTemp: DW 0

; Subroutine to send a newline to the computer log
UARTNL:
	LOAD   NL
	OUT    UART_DAT
	SHIFT  -8
	OUT    UART_DAT
	RETURN
	NL: DW &H0A1B

; Subroutine to clear the internal UART receive FIFO.
UARTClear:
	IN     UART_DAT
	JNEG   UARTClear
	RETURN
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
;***************************************************************
;* IO address space map
;***************************************************************
SWITCHES: EQU &H00  ; slide switches
LEDS:     EQU &H01  ; red LEDs
TIMER:    EQU &H02  ; timer, usually running at 10 Hz
XIO:      EQU &H03  ; pushbuttons and some misc. inputs
SSEG1:    EQU &H04  ; seven-segment display (4-digits only)
SSEG2:    EQU &H05  ; seven-segment display (4-digits only)
LCD:      EQU &H06  ; primitive 4-digit LCD display
XLEDS:    EQU &H07  ; Green LEDs (and Red LED16+17)
BEEP:     EQU &H0A  ; Control the beep
CTIMER:   EQU &H0C  ; Configurable timer for interrupts
LPOS:     EQU &H80  ; left wheel encoder position (read only)
LVEL:     EQU &H82  ; current left wheel velocity (read only)
LVELCMD:  EQU &H83  ; left wheel velocity command (write only)
RPOS:     EQU &H88  ; same values for right wheel...
RVEL:     EQU &H8A  ; ...
RVELCMD:  EQU &H8B  ; ...
I2C_CMD:  EQU &H90  ; I2C module's CMD register,
I2C_DATA: EQU &H91  ; ... DATA register,
I2C_RDY:  EQU &H92  ; ... and BUSY register
UART_DAT: EQU &H98  ; UART data
UART_RDY: EQU &H98  ; UART status
SONAR:    EQU &HA0  ; base address for more than 16 registers....
DIST0:    EQU &HA8  ; the eight sonar distance readings
DIST1:    EQU &HA9  ; ...
DIST2:    EQU &HAA  ; ...
DIST3:    EQU &HAB  ; ...
DIST4:    EQU &HAC  ; ...
DIST5:    EQU &HAD  ; ...
DIST6:    EQU &HAE  ; ...
DIST7:    EQU &HAF  ; ...
SONALARM: EQU &HB0  ; Write alarm distance; read alarm register
SONARINT: EQU &HB1  ; Write mask for sonar interrupts
SONAREN:  EQU &HB2  ; register to control which sonars are enabled
XPOS:     EQU &HC0  ; Current X-position (read only)
YPOS:     EQU &HC1  ; Y-position
THETA:    EQU &HC2  ; Current rotational position of robot (0-359)
RESETPOS: EQU &HC3  ; write anything here to reset odometry to 0
n:        EQU 64    ;n should be table length -1

;include table here
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
