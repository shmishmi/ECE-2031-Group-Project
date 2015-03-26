;Team Donuts
;ECE 2031 L08
;Code to Test SCOMP Multiply



		ORG     &H000
Start:  CALL    Calc
		JUMP	START        
		ORG		&H010
Calc:	LOAD	A
		MULT	B
		STORE	D
		OUT		SEVENSEG
		OUT		TIMER
TCheck: 	IN		TIMER
			ADDI	-20
        	JNEG	TCheck
        LOAD 	D
		MULT	C
		OUT 	SEVENSEG	
		JUMP 	Calc

A:      DW      &H0002
B:      DW      &H0005
C:      DW      &H0002	
D:		DW		&H0000
SWITCHES:   EQU     &H00
LEDS:      	EQU     &H01
TIMER:      EQU     &H02	
SEVENSEG:	EQU		&H04
INDATA:		DW		&H00
