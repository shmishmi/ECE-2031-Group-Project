Circle: LOAD ZERO ;Might not be necessary

UI:		IN SWITCHES
		AND MASK0
		OUT LEDS
		JPOS DISTANCE
		IN SWITCHES
		AND MASK1
		OUT LEDS
		JPOS DISTANCE2
		IN SWITCHES
		AND MASK2
		OUT LEDS
		JPOS DISTANCE3
		IN SWITCHES
		AND MASK3
		OUT LEDS
		JPOS DISTANCE4
		JUMP UI    

		;Distance needs to be Changed
DISTANCE:  ADDI 145
           JUMP NEXT
DISTANCE2: ADDI 2 
           MULT OneFoot
           JUMP NEXT
DISTANCE3: ADDI 440 
           JUMP NEXT
DISTANCE4: ADDI 2
		   MULT OneFoot
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
		LOAD FSLOW
		OUT LVELCMD
		LOAD OUTVEL
		OUT RVELCMD
		CALL Wait1

GO:		LOAD FSLOW
		OUT LVELCMD
		LOAD OUTVEL
		OUT RVELCMD	
		IN THETA
		OUT SSEG1
		SUB INTHETA
		JZERO STOP ; Move until it gets back to where it started
		JUMP GO
		
		
STOP: 	LOAD ZERO		
		OUT LVELCMD
		OUT RVELCMD 
		
		
;Circle Variables
RADIUS: DW 0
OUTVEL: DW 0
INTHETA: DW 0
SCALE:  DW 256
