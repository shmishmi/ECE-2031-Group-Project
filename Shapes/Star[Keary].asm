 ;First Destination (100,100)
	ADDI 100
	STORE X
	STORE Y
	CALL goto
    IN THETA
    OUT SSEG1
	
    ;Second Dest. (200, 0)
	LOAD Zero
	ADDI 200
	STORE X
	LOAD Zero
	STORE Y
	CALL goto
	IN THETA
	OUT SSEG1
	
	;Third Dest. (0, 50)
	LOAD Zero
	STORE X
	ADDI 50
	STORE Y
	CALL goto
	IN THETA
	OUT SSEG1
	
	;Fourth Dest. (200, 50)
	LOAD Zero
	ADDI 200
	STORE X
	ADDI -150
	STORE Y
	CALL goto
	IN THETA
	OUT SSEG1
	
	
	;Go Home (0,0)
	LOAD Zero
	STORE X
	STORE Y
	CALL goto
	IN THETA
	OUT SSEG1
	CALL Die
