Figure8:	;USING TURN AND GOTO
	LOAD 	Zero
	ADDI	45
	STORE	ANGLE
	CALL	turn
	LOAD	Four
	STORE	X
	STORE	Y
	CALL	GOTO
	LOAD	Zero
	ADDI	135
	STORE	ANGLE
	CALL	turn
	LOAD	Zero
	STORE	X
	STORE	ANGLE
	CALL	GOTO
	ADDI	135
	CALL	turn
	LOAD	Four
	STORE	X
	LOAD	Zero
	STORE	Y
	ADDI	225
	STORE	ANGLE
	CALL	GOTO
	CALL	turn
	LOAD	Zero
	STORE	X
	STORE	Y
	CALL	GOTO
	
		
Star:		;USING JUST GOTO
	LOAD	One
	STORE	X
	LOAD	Three
	STORE	Y
	CALL	GOTO
	LOAD	Two
	STORE 	X
	LOAD	Zero
	STORE	Y
	CALL	GOTO
	LOAD	Two
	STORE	Y
	LOAD	ZERO
	ADDI	-1
	STORE	X
	CALL	GOTO
	LOAD	Three
	STORE	X
	CALL	GOTO
	LOAD	ZERO
	STORE	X
	STORE	Y
	CALL	GOTO
