        .ORIG x3000

        AND R0 R0 0 ; Set all registers to known state
        ADD R1 R0 0 ; X is starting player
        ADD R2 R0 0
        ADD R3 R0 0
        ADD R4 R0 0
        ADD R5 R0 0
        ADD R6 R0 0
        ADD R7 R0 0

        JSR CLEAR ; Clear screen

        LD R0 K30
        JSR DRAWH ; Horizontal at 30
        JSR DRAWV ; Vertical at 30
        LD R0 K60
        JSR DRAWH ; Horizontal at 60
        JSR DRAWV ; Vertical at 60
        
        MAIN_LOOP
            JSR PLAYERDATA ; R0 = STR, R2 = BLOCK, R3 = COLOR
            PUTS ; Print prompt
            JSR GETMOV ; Get input

            ADD R7 R0 -9 ; Quit if q pressed
            BRz QUIT

            ADD R7 R0 1 ; Ignore if input is bad
            BRz MAIN_LOOP

            LEA R4 BLOCK_FILLS ; Check if space filled
            ADD R4 R4 R0
            LDR R7 R4 0
            BRp MAIN_LOOP ; Ignore if space filled
            ADD R7 R7 1 ; Set value to true
            STR R7 R4 0 ; Store true value

            LEA R4 BLOCKS ; Load appropriate screen pointer
            ADD R0 R0 R4
            LDR R0 R0 0

            ADD R4 R1 0 ; R4 = PLAYER
            ADD R1 R2 0 ; R1 = BLOCK
            ADD R2 R3 0 ; R2 = COLOR
            JSR DRAWB ; Draw symbol

            ADD R1 R4 1 ; R1 = (PLAYER + 1) % 2
            AND R1 R1 1
            BR MAIN_LOOP

QUIT    HALT

; Data section

X_STR       .STRINGZ "X move: "
O_STR       .STRINGZ "O move: "

SCREEN      .FILL xC000

LINE_END    .FILL 91

NUM_PIXELS  .FILL x3E00

SKIP_ROW    .FILL 108 ; 128 - 20

WHITE       .FILL x7FFF
XCOLOR      .FILL x7FED ; Yellow
OCOLOR      .FILL x03E0 ; Green

XBLOCK      .FILL xA000
OBLOCK      .FILL xA200

BLOCKS      .FILL xC285 ; Top left
            .FILL xC2A3 ; Top middle
            .FILL xC2C1 ; Top right

            .FILL xD185 ; Middle left
            .FILL xD1A3 ; Middle
            .FILL xD1C1 ; Middle right

            .FILL xE085 ; Bottom left
            .FILL xE0A3 ; Bottom middle
            .FILL xE0C1 ; Bottom right

BLOCK_FILLS .BLKW 9

K20         .FILL 20
K30         .FILL 30
K60         .FILL 60

ASCII_0     .FILL -48
ASCII_Q     .FILL -113
ASCII_ENTER .FILL -10

; Subroutine section

; Draw a white horizontal line at the row indicated by R0
DRAWH   ST R1 DRAWH1 ; Stash registers
        ST R2 DRAWH2
        ST R7 DRAWH7

        LD R1 LINE_END ; x = LINE_END
        ADD R2 R0 0   ; y = row
        LD R0 WHITE   ; color = white

        DRAWH_LOOP ; Draw line
            JSR DRAWP
            ADD R1 R1 -1 ; x -= 1
            BRzp DRAWH_LOOP
        
        ADD R0 R2 0 ; Restore registers and return
        LD R1 DRAWH1
        LD R2 DRAWH2
        LD R7 DRAWH7
        RET
DRAWH1  .FILL 0
DRAWH2  .FILL 0
DRAWH7  .FILL 0

; Draw a white vertical line at the col indicated by R0
DRAWV   ST R1 DRAWV1 ; Stash registers
        ST R2 DRAWV2
        ST R7 DRAWV7

        ADD R1 R0 0   ; x = col
        LD R2 LINE_END ; y = LINE_END
        LD R0 WHITE   ; color = white

        DRAWV_LOOP ; Draw line
            JSR DRAWP
            ADD R2 R2 -1 ; y -= 1
            BRzp DRAWV_LOOP
        
        ADD R0 R1 0 ; Restore registers and return
        LD R1 DRAWV1
        LD R2 DRAWV2
        LD R7 DRAWV7
        RET
DRAWV1  .FILL 0
DRAWV2  .FILL 0
DRAWV7  .FILL 0

; Sets a single pixel to a specific color
; R0 is the color
; R1 is the x position
; R2 is the y position
DRAWP   ST R2 DRAWP2 ; Stash registers
        ST R3 DRAWP3
        ST R4 DRAWP4

        LD R3 SCREEN ; Load screen pointer
        AND R4 R4 0
        ADD R4 R4 7 ; Load 7 into R4

        DRAWP_SHIFT ; R2 <<= 7 multiplies R2 by x80
            ADD R2 R2 R2
            ADD R4 R4 -1
            BRp DRAWP_SHIFT
        
        ADD R3 R3 R1 ; index = x80 * y + x
        ADD R3 R3 R2

        STR R0 R3 0 ; Set pixel

        LD R2 DRAWP2 ; Restore registers and return
        LD R3 DRAWP3
        LD R4 DRAWP4
        RET
DRAWP2  .FILL 0
DRAWP3  .FILL 0
DRAWP4  .FILL 0

; Draw a 20x20 block of pixels to the display
; R0 is the top left pixel of the display area to draw in
; R1 is a pointer to the buffer with the sprite
; R2 is the color to draw with
DRAWB   ST R0 DRAWB0 ; Stash registers
        ST R1 DRAWB1
        ST R3 DRAWB3
        ST R4 DRAWB4
        ST R5 DRAWB5
        ST R6 DRAWB6
        
        LD R3 K20
        LD R5 SKIP_ROW
        DRAWB_ROW_LOOP ; Move rows to the display
            LD R4 K20
            DRAWB_COL_LOOP ; Move single row of pixels to display
                LDR R6 R1 0 ; Test pixel
                BRz DRAWB_SKIP
                STR R2 R0 0 ; Write color to display if pixel is true
                DRAWB_SKIP
                ADD R0 R0 1 ; Increment both pointers
                ADD R1 R1 1
                ADD R4 R4 -1 ; Decrement counter
                BRp DRAWB_COL_LOOP
            ADD R0 R0 R5 ; Move display pointer down 1 and back 20
            ADD R3 R3 -1 ; Decrement counter
            BRp DRAWB_ROW_LOOP

        LD R0 DRAWB0 ; Restore registers and return
        LD R1 DRAWB1
        LD R3 DRAWB3
        LD R4 DRAWB4
        LD R5 DRAWB5
        LD R6 DRAWB6
        RET
DRAWB0  .FILL 0
DRAWB1  .FILL 0
DRAWB3  .FILL 0
DRAWB4  .FILL 0
DRAWB5  .FILL 0
DRAWB6  .FILL 0

; Gets the next move from the player
; Returns 0-8 in R0 if move entered
; Returns 9 in R0 if quit requested
; Returns -1 in R0 if anything else happened
GETMOV  ST R1 GETMOV1 ; Stash registers
        ST R2 GETMOV2
        ST R3 GETMOV3
        ST R4 GETMOV4
        ST R7 GETMOV7

        LD R1 ASCII_0 ; Load ASCII values
        LD R2 ASCII_Q
        LD R3 ASCII_ENTER
        GETC ; Get first character
        OUT
        ADD R4 R0 R3 ; Test if enter
        BRnp GETMOV_ENTER_SKIP
            AND R1 R1 0 ; If so, return -1
            ADD R1 R1 -1
            BR GETMOV_RET
        GETMOV_ENTER_SKIP
        ADD R4 R0 R2 ; Test if q
        BRnp GETMOV_Q_SKIP
            AND R0 R0 0 ; If so, get ready to return 9
            ADD R0 R0 9
            BR GETMOV_CHAR2
        GETMOV_Q_SKIP
        ADD R0 R0 R1 ; Test if less than '0'
        BRzp GETMOV_LESS_CHECK
            AND R0 R0 0 ; If so, get ready to return -1
            ADD R0 R0 -1
            BR GETMOV_CHAR2
        GETMOV_LESS_CHECK
        ADD R4 R0 -8 ; Test if greater than '8'
        BRnz GETMOV_CHAR2 ; If not, get ready to return digit
        AND R0 R0 0 ; If so, get ready to return -1
        ADD R0 R0 -1

        GETMOV_CHAR2
            ADD R1 R0 0 ; Stash return value in R1
            GETC ; Get second character
            OUT
            ADD R0 R0 R3 ; Check if char is enter and return if so
            BRz GETMOV_RET
            AND R0 R0 0 ; Otherwise, get ready to return -1
            ADD R0 R0 -1
            BR GETMOV_CHAR2
        
        GETMOV_RET
        ADD R0 R1 0 ; Return R1
        LD R1 GETMOV1 ; Restore registers and return
        LD R2 GETMOV2
        LD R3 GETMOV3
        LD R4 GETMOV4
        LD R7 GETMOV7
        RET
GETMOV1 .FILL 0
GETMOV2 .FILL 0
GETMOV3 .FILL 0
GETMOV4 .FILL 0
GETMOV7 .FILL 0

; Clears the screen
CLEAR   ST R0 CLEAR0 ; Stash registers
        ST R1 CLEAR1
        ST R2 CLEAR2
        
        LD R0 SCREEN ; Load screen pointer and number of pixels
        LD R1 NUM_PIXELS
        AND R2 R2 0

        CLEAR_LOOP
            STR R2 R0 0 ; Clear pixel
            ADD R0 R0 1 ; Next pixel
            ADD R1 R1 -1 ; Stop at end of screen
            BRp CLEAR_LOOP
        
        LD R0 CLEAR0 ; Restore registers and return
        LD R1 CLEAR1
        LD R2 CLEAR2
        RET
CLEAR0  .FILL 0
CLEAR1  .FILL 0
CLEAR2  .FILL 0

; Gets player relevant stuff
; R1 is the current player
; Returns player string pointer in R0
; Returns player display pointer in R2
; Returns player color in R3
PLAYERDATA
        ADD R1 R1 0 ; Test whos turn it is
        BRp PLAYERDATA_O

        LD R2 XBLOCK ; Load relevant data
        LD R3 XCOLOR
        LEA R0 X_STR
        RET

        PLAYERDATA_O
        LD R2 OBLOCK ; Load relevant data
        LD R3 OCOLOR
        LEA R0 O_STR
        RET

        .END
