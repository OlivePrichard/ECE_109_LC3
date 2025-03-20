; LC3 Program that take in 2 binary numbers and then outputs
; the result of bitwise ORing them together
        .ORIG x3000

; clear all registers to start from a known state
        AND R0, R0, 0
        AND R1, R1, 0
        AND R2, R2, 0
        AND R3, R3, 0
        AND R4, R4, 0
        AND R5, R5, 0

        ADD R3, R3, 1

        LEA R0, PROMPT_A
        PUTS ; print out the first message

        LD R2, Q
        LD R1, ASCII_1
LOOP    GETC ; read in a character and test what it is

        ADD R7, R0, R2 ; test for a q
        BRz EXIT

        ADD R0, R0, R1 ; test whether the value is valid
        BRp LOOP
        ADD R0, R0, 1
        BRn LOOP

; value is valid
        NOT R1, R1 ; negate
        ADD R0, R0, R1 ; convert to ascii and print
        OUT
        NOT R1, R1 ; negate

        ADD R3, R3, R3 ; shift left
        ADD R0, R0, R1 ; set flags
        BRn ZERO
        ADD R3, R3, 1 ; set a one

ZERO    ADD R7, R3, -16 ; check if we've looped 4 times
        BRn LOOP

        ADD R5, R4, 0 ; store possible last value
        ADD R4, R3, 0 ; store our input value
        AND R3, R3, 0 ; reset R3
        ADD R3, R3, 1

        ADD R5, R5, 0 ; test if we've got 2 values
        BRp BREAK
        LEA R0, PROMPT_B
        PUTS ; print second message
        BR LOOP
        
BREAK   LEA R0, RESULT ; print result message
        PUTS

; OR both values together
        NOT R4, R4
        NOT R5, R5
        AND R2, R4, R5
        NOT R2, R2

        NOT R1, R1 ; digit to ascii
        LEA R4, MASKS
        LDR R5, R4, 1 ; loop counter
LOOP2   LDR R0, R4, 0 ; load mask
        AND R0, R0, R2
        BRz ZERO2
        ADD R0, R3, 0 ; set R0 to 1
ZERO2   ADD R0, R0, R1 ; convert to ascii and print
        OUT
        ADD R4, R4, 1 ; update mask and loop counter
        ADD R5, R5, -1
        BRp LOOP2
        HALT
        
; print exit message and halt
EXIT    LEA R0, EXIT_STR
        PUTS
        HALT

PROMPT_A    .STRINGZ "\nEnter First Number (4 binary digits): "
PROMPT_B    .STRINGZ "\nEnter Second Number (4 binary digits): "
RESULT      .STRINGZ "\nThe OR function of the two numbers is: "
EXIT_STR    .STRINGZ "\nThank you for playing!"

ASCII_1 .FILL -49
Q       .FILL -113

MASKS   .FILL 8
        .FILL 4
        .FILL 2
        .FILL 1

        .END