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
OUT RESETPOS
;***************************************************************
;* Turns code
;***************************************************************
          ;test code
LOADI 60
STORE ANGLE
CALL TURN
LOADI 270
STORE ANGLE 
CALL TURN
LOADI 170
STORE ANGLE
CALL TURN
LOADI 0
STORE ANGLE
CALL TURN
CALL HOLD

;***************************************************************
;* Figure 8 code
;***************************************************************\

;;Figure 8 Code
Figure8:
    ;; First Dest. (0,0)
    
    ;;Second Dest (1,1)
    LOADI   100
 	STORE	X
 	STORE	Y
 	CALL	goto
 	
 	
  ;;Third Dest (0,1)
 	LOAD    Zero
 	STORE   X
 	CALL    goto
 	
 	
 	;; Fourth Dest (1,0)
 	LOAD    Zero
 	STORE   Y
 	ADDI    100
 	STORE   X
 	CALL    goto
 	
 	
 	
 	
 	LOAD    Zero
 	STORE   X
 	CALL    goto
        CALL    HOLD
        ; Need code to reorient the robot
;***************************************************************
;* Star code
;***************************************************************
star:
;First Destination (1,2)
	LOADI 50
	STORE X
	LOADI 150
	STORE Y
	CALL goto
    
	
    ;Second Dest. (1, 0)
	LOADI 100
	STORE X
	LOADI 0
	STORE Y
	CALL goto

	
	;Third Dest. (0, 1)
	LOADI -25
	STORE X
	ADDI 100
	STORE Y
	CALL goto

	;Fourth Dest. (2, 1)
	LOADI 125
	STORE X
	LOADI 100
	STORE Y
	CALL goto
	
	
	
	;Go Home (0,0)
	LOAD Zero
	STORE X
	STORE Y
	CALL goto

	CALL HOLD

;***************************************************************
;* Circle code
;***************************************************************
LOADI 180
STORE ANGLE
CALL turn
CALL Circle
CALL HOLD
CALL Circle


LOADI 0
STORE X
STORE Y
CALL goto

CALL SHAPES
;;CAll DIE
	
	
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

;change x and y so that they are relative to your current location
IN XPOS
;LOAD XPOS       ; use this if you want to test with pretermined values for XPOS  (also YPOS below)
SHIFT 1
DIV Twocm     ;these divides are going to round down to the nearest cm
STORE temp
LOAD X 
SUB temp
STORE xtemp

IN YPOS
;LOAD YPOS       ;used for testing
SHIFT 1
DIV Twocm

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
    JZERO quadx             
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
	SHIFT 7
	DIV xtemp
	STORE yoverx   ;yoverx = floor(y*2^7/x)
;from division scaled up by 2^7, find table index 
;gets the value at the index
	load index
	
indexloop: 
	;scale by 2048
	SHIFT 4   ;shift 4 is multiply by scale (2^7) and divide by n-1 (8)
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
	JZERO firstpoint        ;this takes care of the case when than angle is 0 deg
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
	SHIFT 4
	STORE x1      ;get x1 on same scale as yoverx 
	
	LOAD yoverx
	SUB x1
	MULT y2      ;using y2 so i don't have to use another memory location, this is just deltay
	SHIFT -4   ;this is the same as dividing by delta x since in this case it is 16
	ADD y1
	
	
	firstpoint:           ;jump here if first point is 0 and just put zero in angle
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
	LOAD ANGLE
	ADDI 4
	STORE ANGLE
	JUMP anglemod
CCW:       ;wheel speeds for turning CCW
	LOAD FSLOW
	STORE right
	LOAD RSLOW
	STORE left
	LOAD ANGLE
	ADDI -4
	STORE ANGLE

anglemod: 
    JPOS overcheck
    ADD Deg360
    STORE ANGLE
    JUMP turnloop

overcheck:
    SUB Deg360
    JNEG turnloop
    STORE ANGLE

turnloop:
	LOAD right
	OUT RVELCMD
	LOAD left
	OUT LVELCMD
	IN THETA
	OUT SSEG2
	SUB ANGLE
	JZERO at_angle
	JUMP turnloop
at_angle:
    LOAD Zero
    OUT RVELCMD
    OUT LVELCMD
    CALL WAIT1
	RETURN



goto:
	CALL atan
	CALL turn
	
    
    
gotonoturn:

	
   

	LOAD Zero
	STORE temp   ;temp is initialized to zero (must be after atan and turn since they use it)  
    STORE y2
	;for moving
	LOAD X         ;convert to odometer units
	MULT Twocm
	SHIFT -1
	STORE xtemp	
	
	LOAD Y            ;only need if we're also checking y as an end condition  
	MULT Twocm
	SHIFT -1
	STORE ytemp

	IN XPOS
	SUB xtemp
	JNEG ydirection
	LOADI 1
	STORE temp       ;use temp to indicate if xpos was bigger
ydirection:
    IN YPOS
    SUB ytemp
    JNEG ybuffer
    LOADI 1
	STORE y2                   ;use y2 to indicate if y destination is bigger or not
    LOAD ytemp
    ADDI -15
    JUMP storebuffer
ybuffer: 
LOAD ytemp
ADDI 15
storebuffer:
STORE ytemp
goloop:
;deceleration code - finding hypotenuse doesn't work because of overflow. 
	; should test the other code without this, it hould work now
	IN XPOS
	STORE x1       ;x1 is used as a temporary variable
	SUB xtemp
	JPOS xispositive
	MULT NegOne
	xispositive:
	STORE sum
	
	IN YPOS
	STORE y1      ;y1 is used as a temporary variable
	SUB ytemp
	JPOS yispositive
	MULT NegOne
	yispositive:
	ADD sum
	
	SUB slowdown
    JPOS normalspeed

    LOAD FSLOW            ;this puts slow to the wheels once you're 1-1.5 feet away from the destination
    OUT LVELCMD
    ;ADDI 5                  ;adjusting for differences in wheel speeds
    OUT RVELCMD
	
    JUMP choosedirection

    normalspeed:
	LOAD FMID
	
	OUT LVELCMD
	;ADDI 5              ;adjusting for differences in wheel speeds
    OUT RVELCMD
    choosedirection:
	LOAD temp
	JZERO destinationbiggerx
	
	destinationsmallerx:
	IN XPOS
	SUB xtemp
	JPOS checky
	JUMP stopmoving
	
	destinationbiggerx:
	IN XPOS 
	SUB xtemp
	JNEG checky
	JPOS stopmoving
	
checky:      
    LOAD y2
	JZERO destinationbiggery
	
	destinationsmallery:
	IN YPOS
	SUB ytemp
	JPOS goloop
	JUMP stopmoving
	
	destinationbiggery:
	IN YPOS 
	SUB ytemp
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
	
	LOADI 0
	OUT RVELCMD
	OUT LVELCMD
	RETURN
	
	
Circle:

UI:		IN SWITCHES
		AND MASK0
		JPOS DISTANCE
		IN SWITCHES
		AND MASK1
		JPOS DISTANCE2
		IN SWITCHES
		AND MASK2
		JPOS DISTANCE3
		IN SWITCHES
		AND MASK3
		JPOS DISTANCE4
		JUMP UI    

		;Distance needs to be Changed
DISTANCE:  LOADI 10
           MULT Twocm
           SHIFT -1
           JUMP NEXT
DISTANCE2: LOADI 13 
           MULT Twocm
           SHIFT -1
           JUMP NEXT
DISTANCE3: LOADI 15
           MULT Twocm
           SHIFT -1
           JUMP NEXT
DISTANCE4: LOADI 18
           MULT Twocm
           SHIFT -1
           JUMP NEXT
			
NEXT:	STORE RADIUS

		LOAD FSLOW ;Load speed of inner wheel
		MULT SCALE
		DIV RADIUS ;Divide By a scaled version of the inner wheel speed
		STORE Temp
		LOAD RADIUS 
		ADDI 240   ;Radius of the outer wheel's circle is radius + 240, distance between wheels
		DIV SCALE
		MULT Temp  ;  Velocity of inner wheel
		STORE OUTVEL ;Increased velocity of outer wheel
		IN THETA
		STORE INTHETA
		LOAD OUTVEL
		OUT LVELCMD
		LOAD FSLOW
		OUT RVELCMD
		CALL Wait1
        LOADI 0
        STORE Temp
        
GO:		LOAD OUTVEL
		OUT LVELCMD
		LOAD FSLOW
		OUT RVELCMD	
		IN THETA
		OUT SSEG2
		SUB INTHETA
		JZERO testtemp ; Move until it gets back to where it started
		LOADI 1
		STORE Temp
		JUMP GO
testtemp: 
        LOAD Temp
        JZERO GO
		
		
STOP: 	LOAD ZERO		
		OUT LVELCMD
		OUT RVELCMD

		
HOLD:   CALL stopmoving
        IN   XIO         ; XIO contains KEYs
	AND  Mask1       ; KEY3 mask (KEY0 is reset and can't be read)
	JPOS HOLD
        RETURN
        
SHAPES:
IN XIO
AND MASK1
JZERO keepshapin

IN XIO
AND MASK0
JPOS SHAPES
RETURN


keepshapin:
IN SWITCHES
JZERO keepshapin
AND MASK2
JPOS Triangle

IN SWITCHES
AND MASK3
JPOS Rhombus

IN SWITCHES
AND MASK4
JPOS Pentagon
JUMP SHAPES

Triangle: 

LOADI -50
STORE X
STORE Y
CALL goto

LOADI -100
STORE X
LOADI 0
STORE Y
CALL goto
LOADI 0
STORE X
STORE Y
CALL goto
JUMP SHAPES

Rhombus:

LOADI 10
STORE X
LOADI 100
STORE Y
CALL goto
LOADI 110
STORE X
CALL goto
LOADI 100
STORE X
LOAD ZERO
STORE Y
CALL goto
LOAD ZERO
STORE X
STORE Y
CALL goto
JUMP turn0

Pentagon: 

LOADI -20
STORE X
LOADI 40
STORE Y
CALL goto
LOADI 0
STORE X
LOADI 80
STORE Y
CALL goto
LOADI 40
STORE X
LOADI 80
STORE Y
CALL goto
LOADI 60
STORE X
LOADI 40
STORE Y
CALL goto
LOADI 40
STORE X
LOADI 0
STORE Y
CALL goto
LOADI 0 
STORE X
STORE Y
CALL goto
JUMP turn0

turn0:
LOADI 0
STORE ANGLE
CALL turn
JUMP SHAPES


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
OneFoot:  DW 293       ; 1 foot 
Twocm:    DW 19        ; there are ~ 19 robot units in twocm 
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
sum:      DW 0         ;currently assuming X/Y are in centimeters
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

;Circle Variables
RADIUS: DW 0
OUTVEL: DW 0
INTHETA: DW 0
SCALE:  DW 256

;include table here
offset:
DW  0
DW  7
DW  14
DW  21
DW  27
DW  32
DW  37
DW  41
DW  45      ;this is entry 9
