; Author: Olive Prichard
; This program displays my initials: OP
; They are displayed on a black background.
; When the user presses the r, g, b, or y keys,
; the color changes to red, green, blue, or yellow, respectively.
; When space is pressed, the initials turn white.
; When q is pressed, the program thanks the user and stops.

        .ORIG x3000

        AND R0 R0 0 ; Clear registers
        ADD R1 R0 0
        ADD R2 R0 0
        ADD R3 R0 0
        ADD R4 R0 0
        ADD R5 R0 0
        ADD R6 R0 0
        ADD R7 R0 0

; Clear screen
        LD R1 SCREEN_START
        LD R2 SCREEN_END
        NOT R2 R2 ; Invert address
        ADD R2 R2 1
        CLEAR_LOOP
                STR R0 R1 0 ; Clear pixel
                ADD R1 R1 1
                ADD R3 R1 R2 ; Stop at end of screen
                BRn CLEAR_LOOP
        ADD R1 R0 0 ; Clear used registers
        ADD R2 R0 0
        ADD R3 R0 0

; Decompress encoded image
        LD R2 IMAGE_PTR
        LEA R3 IMAGE
        LD R4 K32
        ADD R4 R4 -1 ; x1F
        NOT R5 R4 ; -32
        LDR R0 R2 0
        DECODE_LOOP
                BRp RUN_LENGTH ; Check which decode we do
                PACKED_LOOP
                        AND R1 R0 R4 ; Get 5 LSBs and convert to RGB
                        JSR CONVERT
                        STR R1 R3 0 ; Store pixel and increment pointer
                        ADD R3 R3 1
                        JSR SHR5 ; Shift to next pixel
                        ADD R0 R0 0 ; Loop if register still has pixel data
                        BRp PACKED_LOOP ; TODO: fix this bug, when larger pixels are zero it ends early
                ADD R2 R2 1 ; Increment encoded data pointer and read next word
                LDR R0 R2 0
                BR DECODE_LOOP
        RUN_LENGTH
                AND R1 R0 R4 ; Get 5 LSBs and convert to RGB
                JSR CONVERT
                RUN_LENGTH_LOOP
                        STR R1 R3 0 ; Store pixel and increment counter
                        ADD R3 R3 1
                        ADD R0 R0 R5 ; Decrement counter and loop
                        BRzp RUN_LENGTH_LOOP
                ADD R2 R2 1 ; Increment encoded data pointer and read next word
                LDR R0 R2 0
                BRnp DECODE_LOOP

; Display initials with correct color
        LD R0 RED ; Red is the default color
DRAW_INITIALS
        LD R1 CORNER
        LD R2 STOP
        LEA R3 IMAGE
        NOT R2 R2 ; Invert address
        ADD R2 R2 1
        DISPLAY_LOOP
                LDR R4 R3 0 ; Fetch pixel and convert to RGB
                AND R4 R4 R0
                STR R4 R1 0 ; Set pixel to correct color
                ADD R1 R1 1
                ADD R3 R3 1
                ADD R4 R1 R2 ; Stop at end of screen
                BRn DISPLAY_LOOP

END     LD R0 EXIT_MSG
        PUTS
        HALT

; Converts the pixel from 5 bit grayscale to LC3 RGB format
CONVERT ST R0 CONVERT_R0 ; Stash register

        ADD R0 R1 R1 ; SHL by 5
        ADD R0 R0 R0
        ADD R0 R0 R0
        ADD R0 R0 R0
        ADD R0 R0 R0

        ADD R1 R0 R1 ; Combine

        ADD R0 R0 R0 ; SHL by 5
        ADD R0 R0 R0
        ADD R0 R0 R0
        ADD R0 R0 R0
        ADD R0 R0 R0

        ADD R1 R0 R0 ; Combine

        LD R0 CONVERT_R0 ; Load register
        RET
CONVERT_R0
        .FILL 0

; Shifts the 15 least significant bits of R0 right 5 bits
; Clears the MSB
SHR5    ST R1 SHR5_R1 ; Stash registers
        ST R2 SHR5_R2
        ST R3 SHR5_R3
        ST R4 SHR5_R4

        LD R1 K32 ; Load masks
        AND R3 R3 0
        ADD R2 R3 1
SHR5_LOOP       AND R4 R0 R1 ; Check if bit is set and skip setting the corresponding bit if it's not
                BRz SHR5_SKIP
                ADD R3 R3 R2
SHR5_SKIP       ADD R2 R2 R2 ; Shift both bitmasks left
                ADD R1 R1 R1
                BRp SHR5_LOOP
        ADD R0 R3 0

        LD R1 SHR5_R1 ; Restore registers
        LD R2 SHR5_R2
        LD R3 SHR5_R3
        LD R4 SHR5_R4
        RET
SHR5_R1 .FILL 0 ; Space to push registers
SHR5_R2 .FILL 0
SHR5_R3 .FILL 0
SHR5_R4 .FILL 0

; Constants
RED     .FILL x7C00
GREEN   .FILL x03E0
BLUE    .FILL x001F
YELLOW  .FILL x7FED
WHITE   .FILL x7FFF
BLACK   .FILL x0000

R       .FILL -114
G       .FILL -103
B       .FILL -98
Y       .FILL -121
SPACE   .FILL -32
Q       .FILL -113

CORNER  .FILL xCB00 ; xC000 + 22 * 128
STOP    .FILL xF300 ; Last index of the display area

K32     .FILL 32
K127    .FILL 127
IMAGE_PTR
        .FILL COMPRESSED_IMAGE
SCREEN_START
        .FILL xC000
SCREEN_END
        .FILL xFE00

EXIT_MSG
        .STRINGZ "Thank you for playing\n"
        
IMAGE   .BLKW x2800 ; 128x80 px

; Custom compression format:
; If MSB is 0:
;     lower 5 bits are the grayscale color
;     upper 11 bits are the run length of that color - 1
; else:
;     lower 15 bits contain next 3 pixels grayscale colors packed together,
;     next pixel is lowest 5 bits
; The sequence is NULL terminated
COMPRESSED_IMAGE ; initials encoded in custom compression format
        .FILL x4340
        .FILL xDA28
        .FILL xF779
        .FILL xFFFE
        .FILL xF7DF
        .FILL xDF5C
        .FILL xA257
        .FILL x8112
        .FILL x8008
        .FILL x0D60
        .FILL xF70F
        .FILL x021F
        .FILL xB6FC
        .FILL x81B7
        .FILL x800D
        .FILL x0340
        .FILL xFFF7
        .FILL x031F
        .FILL xF7DE
        .FILL xE35C
        .FILL xA635
        .FILL x8131
        .FILL x8009
        .FILL x04A0
        .FILL xFAC9
        .FILL x02DF
        .FILL x929C
        .FILL x8094
        .FILL x8004
        .FILL x02E0
        .FILL xFFF7
        .FILL x043F
        .FILL xCF3E
        .FILL x80F3
        .FILL x8007
        .FILL x03E0
        .FILL xFF2A
        .FILL x013F
        .FILL xF3BE
        .FILL xFBBC
        .FILL x015F
        .FILL x929E
        .FILL x8094
        .FILL x8004
        .FILL x0300
        .FILL xC966
        .FILL xFFF9
        .FILL x03FF
        .FILL x8198
        .FILL x800C
        .FILL x0360
        .FILL xFEE6
        .FILL x00FF
        .FILL xBABB
        .FILL x80AE
        .FILL x8005
        .FILL x00A0
        .FILL xD9E7
        .FILL xFFFB
        .FILL x00DF
        .FILL x821D
        .FILL x8010
        .FILL x0360
        .FILL xFF8B
        .FILL x041F
        .FILL x8119
        .FILL x8008
        .FILL x0300
        .FILL xFFB0
        .FILL x00BF
        .FILL xA6DE
        .FILL x8136
        .FILL x8009
        .FILL x01A0
        .FILL xFAA9
        .FILL x00FF
        .FILL x80F9
        .FILL x8007
        .FILL x0340
        .FILL xFFA7
        .FILL x011F
        .FILL xDB5E
        .FILL xA1D2
        .FILL xACE3
        .FILL xEED1
        .FILL x017F
        .FILL x825E
        .FILL x8012
        .FILL x02A0
        .FILL xFEE4
        .FILL x00DF
        .FILL x80F8
        .FILL x8007
        .FILL x0220
        .FILL xFEC5
        .FILL x00DF
        .FILL x81BD
        .FILL x800D
        .FILL x0340
        .FILL xFFF5
        .FILL x00FF
        .FILL x8009
        .FILL x0140
        .FILL xFEE9
        .FILL x015F
        .FILL x8016
        .FILL x0260
        .FILL xFF68
        .FILL x00BF
        .FILL x821E
        .FILL x8010
        .FILL x02A0
        .FILL xFFAD
        .FILL x00DF
        .FILL x8012
        .FILL x0320
        .FILL xFFEC
        .FILL x00FF
        .FILL x8009
        .FILL x0180
        .FILL xFF6B
        .FILL x013F
        .FILL x8019
        .FILL x0220
        .FILL xFFAD
        .FILL x00BF
        .FILL x817D
        .FILL x800B

        .FILL x02E0
        .FILL xFF67
        .FILL x00DF
        .FILL x8014
        .FILL x0320
        .FILL x013F
        .FILL x8009
        .FILL x01C0
        .FILL xFFF8
        .FILL x011F
        .FILL x8017
        .FILL x01E0
        .FILL xFFCD
        .FILL x00BF
        .FILL x813D
        .FILL x8009
        .FILL x0320
        .FILL xFF64
        .FILL x00DF
        .FILL x8016
        .FILL x0300
        .FILL xFFFD
        .FILL x00DF
        .FILL x8009
        .FILL x01E0
        .FILL xFFF8
        .FILL x011F
        .FILL x8014
        .FILL x01A0
        .FILL xFFCD
        .FILL x00BF
        .FILL x817E
        .FILL x800B
        .FILL x0360
        .FILL xFF86
        .FILL x00DF
        .FILL x8015
        .FILL x02E0
        .FILL xFFFC
        .FILL x00DF
        .FILL x8009
        .FILL x01E0
        .FILL xFF84
        .FILL x013F
        .FILL x800C
        .FILL x0160
        .FILL xFFCC
        .FILL x00DF
        .FILL x8011
        .FILL x03A0
        .FILL xFFEC
        .FILL x00DF
        .FILL x8013
        .FILL x02C0
        .FILL xFFFB
        .FILL x00DF
        .FILL x8009
        .FILL x0200
        .FILL xFFED
        .FILL x011F
        .FILL x801B
        .FILL x0140
        .FILL xFFA6
        .FILL x00DF
        .FILL x8018
        .FILL x03E0
        .FILL xFFF3
        .FILL x00DF
        .FILL x8010
        .FILL x02A0
        .FILL xFFFB
        .FILL x00DF
        .FILL x8009
        .FILL x0220
        .FILL xFFF9
        .FILL x011F
        .FILL x8010
        .FILL x0120
        .FILL xFFFA
        .FILL x00BF
        .FILL x80DE
        .FILL x8006
        .FILL x0400
        .FILL xFFFB
        .FILL x00BF
        .FILL x811E
        .FILL x8008
        .FILL x0280
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0220
        .FILL xFFED
        .FILL x011F
        .FILL x801B
        .FILL x0100
        .FILL xFFF5
        .FILL x00DF
        .FILL x8013
        .FILL x0420
        .FILL xFFEF
        .FILL x00DF
        .FILL x801A
        .FILL x0280
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0240
        .FILL xFFFB
        .FILL x011F
        .FILL x800A
        .FILL x00C0
        .FILL xFFEB
        .FILL x00DF
        .FILL x801D
        .FILL x0460
        .FILL xFFFA
        .FILL x00DF
        .FILL x8014
        .FILL x0260
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0240
        .FILL xFFF6
        .FILL x011F
        .FILL x8013
        .FILL x00C0

        .FILL xFFFB
        .FILL x00DF
        .FILL x8014
        .FILL x0460
        .FILL xFFF0
        .FILL x00DF
        .FILL x811E
        .FILL x8008
        .FILL x0240
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0240
        .FILL xFFED
        .FILL x011F
        .FILL x8018
        .FILL x00A0
        .FILL xFFF2
        .FILL x00DF
        .FILL x80BE
        .FILL x8005
        .FILL x0480
        .FILL xFFFD
        .FILL x00DF
        .FILL x8018
        .FILL x0240
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0240
        .FILL xFFE1
        .FILL x011F
        .FILL x801B
        .FILL x00A0
        .FILL xFFFC
        .FILL x00DF
        .FILL x8018
        .FILL x04A0
        .FILL xFFF5
        .FILL x00FF
        .FILL x800C
        .FILL x0220
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0260
        .FILL xFFFD
        .FILL x00FF
        .FILL x801D
        .FILL x0080
        .FILL xFFF2
        .FILL x00FF
        .FILL x8010
        .FILL x04A0
        .FILL xFFEB
        .FILL x00FF
        .FILL x8018
        .FILL x0220
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0260
        .FILL xFFFB
        .FILL x00FF
        .FILL x801E
        .FILL x0080
        .FILL xFFFC
        .FILL x00DF
        .FILL x803E
        .FILL x8001
        .FILL x04C0
        .FILL xFFFC
        .FILL x00FF
        .FILL x8008
        .FILL x0200
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0260
        .FILL xFFFA
        .FILL x00FF
        .FILL x801E
        .FILL xB400
        .FILL x013F
        .FILL x8019
        .FILL x04E0
        .FILL xFFF7
        .FILL x00FF
        .FILL x8016
        .FILL x0200
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0260
        .FILL xFFFA
        .FILL x00FF
        .FILL x801E
        .FILL xDC00
        .FILL x013F
        .FILL x8014
        .FILL x04E0
        .FILL xFFF1
        .FILL x00FF
        .FILL x801C
        .FILL x0200
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0260
        .FILL xFFFC
        .FILL x00FF
        .FILL x801C
        .FILL xF400
        .FILL x013F
        .FILL x800D
        .FILL x04E0
        .FILL xFFE7
        .FILL x011F
        .FILL x800C
        .FILL x01E0
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0260
        .FILL xFFFD
        .FILL x00FF
        .FILL x801A
        .FILL xFDA0

        .FILL x013F
        .FILL x0520
        .FILL xFFFD
        .FILL x00FF
        .FILL x8016
        .FILL x01E0
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0240
        .FILL xFFE4
        .FILL x011F
        .FILL x8017
        .FILL xFEA0
        .FILL x011F
        .FILL x801C
        .FILL x0520
        .FILL xFFFA
        .FILL x00FF
        .FILL x801A
        .FILL x01E0
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0240
        .FILL xFFF0
        .FILL x011F
        .FILL x8011
        .FILL xFF40
        .FILL x011F
        .FILL x8019
        .FILL x0520
        .FILL xFFF7
        .FILL x00FF
        .FILL x801E
        .FILL x01E0
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0240
        .FILL xFFF7
        .FILL x00FF
        .FILL x809E
        .FILL xF800
        .FILL x013F
        .FILL x8016
        .FILL x0520
        .FILL xFFF4
        .FILL x011F
        .FILL x800C
        .FILL x01C0
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0220
        .FILL xFFA3
        .FILL x011F
        .FILL x8019
        .FILL xFCC0
        .FILL x013F
        .FILL x8014
        .FILL x0520
        .FILL xFFEF
        .FILL x011F
        .FILL x8012
        .FILL x01C0
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0220
        .FILL xFFF3
        .FILL x011F
        .FILL x800D
        .FILL xFDC0
        .FILL x013F
        .FILL x8012
        .FILL x0520
        .FILL xFFEC
        .FILL x011F
        .FILL x8016
        .FILL x01C0
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0200
        .FILL xFFA6
        .FILL x011F
        .FILL x801A
        .FILL xCC00
        .FILL x015F
        .FILL x800F
        .FILL x0520
        .FILL xFFE7
        .FILL x011F
        .FILL x8018
        .FILL x01C0
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0200
        .FILL xFFF9
        .FILL x011F
        .FILL x800B
        .FILL xD400
        .FILL x015F
        .FILL x800C
        .FILL x0540
        .FILL x015F
        .FILL x801A
        .FILL x01C0
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x01E0
        .FILL xFFF4
        .FILL x011F
        .FILL x8013
        .FILL x0080
        .FILL xFFF6
        .FILL x011F
        .FILL x800B
        .FILL x0540
        .FILL xFFFE
        .FILL x00FF
        .FILL x801B
        .FILL x01C0
        .FILL xFFFA
        .FILL x00DF

        .FILL x8009
        .FILL x01C0
        .FILL xFFF4
        .FILL x011F
        .FILL x8018
        .FILL x00A0
        .FILL xFFF7
        .FILL x011F
        .FILL x8009
        .FILL x0540
        .FILL xFFFD
        .FILL x00FF
        .FILL x801C
        .FILL x01C0
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0180
        .FILL xFF06
        .FILL x013F
        .FILL x8019
        .FILL x00C0
        .FILL xFFF8
        .FILL x011F
        .FILL x8007
        .FILL x0540
        .FILL xFFFD
        .FILL x00FF
        .FILL x801D
        .FILL x01C0
        .FILL xFFFA
        .FILL x00DF
        .FILL x80B1
        .FILL x8005
        .FILL x0120
        .FILL xF685
        .FILL x015F
        .FILL x8016
        .FILL x00E0
        .FILL xFFF9
        .FILL x011F
        .FILL x8007
        .FILL x0540
        .FILL xFFFD
        .FILL x00FF
        .FILL x801D
        .FILL x01C0
        .FILL xFFFA
        .FILL x011F
        .FILL xE37D
        .FILL xCA76
        .FILL xD651
        .FILL xFFDA
        .FILL x013F
        .FILL x823D
        .FILL x8011
        .FILL x0100
        .FILL xFFF8
        .FILL x011F
        .FILL x8009
        .FILL x0540
        .FILL xFFFC
        .FILL x00FF
        .FILL x801C
        .FILL x01C0
        .FILL xFFFA
        .FILL x039F
        .FILL x9ADE
        .FILL x80D6
        .FILL x8006
        .FILL x0120
        .FILL xFFF7
        .FILL x011F
        .FILL x800A
        .FILL x0540
        .FILL xFFFD
        .FILL x00FF
        .FILL x801C
        .FILL x01C0
        .FILL xFFFA
        .FILL x00DF
        .FILL xFFBB
        .FILL x021F
        .FILL x9A9B
        .FILL x80D4
        .FILL x8006
        .FILL x0160
        .FILL xFFF6
        .FILL x011F
        .FILL x800C
        .FILL x0540
        .FILL xFFFD
        .FILL x00FF
        .FILL x801B
        .FILL x01C0
        .FILL xFFFA
        .FILL x00DF
        .FILL xA009
        .FILL xE2B0
        .FILL xF79A
        .FILL xFFFE
        .FILL xFBFF
        .FILL xDF5C
        .FILL x9E57
        .FILL x80F2
        .FILL x8007
        .FILL x01C0
        .FILL xFFF5
        .FILL x011F
        .FILL x800E
        .FILL x0540
        .FILL xFFFD
        .FILL x00FF
        .FILL x8019
        .FILL x01C0
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0420
        .FILL xFFF2
        .FILL x011F
        .FILL x8011
        .FILL x0540
        .FILL xFFFE
        .FILL x00FF
        .FILL x8017
        .FILL x01C0
        .FILL xFFFA

        .FILL x00DF
        .FILL x8009
        .FILL x0420
        .FILL xFFED
        .FILL x011F
        .FILL x8013
        .FILL x0540
        .FILL x015F
        .FILL x8013
        .FILL x01C0
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0420
        .FILL xFFE6
        .FILL x011F
        .FILL x8016
        .FILL x0520
        .FILL xFFE8
        .FILL x011F
        .FILL x800F
        .FILL x01C0
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0440
        .FILL xFFFD
        .FILL x00FF
        .FILL x8018
        .FILL x0520
        .FILL xFFED
        .FILL x011F
        .FILL x8005
        .FILL x01C0
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0440
        .FILL xFFFA
        .FILL x00FF
        .FILL x801B
        .FILL x0520
        .FILL xFFF1
        .FILL x00FF
        .FILL x801C
        .FILL x01E0
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0440
        .FILL xFFF5
        .FILL x00FF
        .FILL x801E
        .FILL x0520
        .FILL xFFF5
        .FILL x00FF
        .FILL x8018
        .FILL x01E0
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0440
        .FILL xFFEE
        .FILL x011F
        .FILL x8008
        .FILL x0500
        .FILL xFFF8
        .FILL x00FF
        .FILL x8011
        .FILL x01E0
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0460
        .FILL xFFFD
        .FILL x00FF
        .FILL x8012
        .FILL x0500
        .FILL xFFFB
        .FILL x00DF
        .FILL x809E
        .FILL x8004
        .FILL x01E0
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0460
        .FILL xFFF8
        .FILL x00FF
        .FILL x8017
        .FILL x0500
        .FILL xFFFE
        .FILL x00DF
        .FILL x8019
        .FILL x0200
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0460
        .FILL xFFEF
        .FILL x00FF
        .FILL x801C
        .FILL x04E0
        .FILL xFFED
        .FILL x00FF
        .FILL x8011
        .FILL x0200
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0480
        .FILL xFFFC
        .FILL x00FF
        .FILL x8009
        .FILL x04C0
        .FILL xFFF5
        .FILL x00DF
        .FILL x801D
        .FILL x0220
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0480
        .FILL xFFF4
        .FILL x00FF
        .FILL x8014
        .FILL x04C0
        .FILL xFFFB

        .FILL x00DF
        .FILL x8014
        .FILL x0220
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0480
        .FILL xFFC5
        .FILL x00FF
        .FILL x801B
        .FILL x04A0
        .FILL xFFE7
        .FILL x00DF
        .FILL x80BE
        .FILL x8005
        .FILL x0220
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x04A0
        .FILL xFFF5
        .FILL x00FF
        .FILL x800C
        .FILL x0480
        .FILL xFFF4
        .FILL x00DF
        .FILL x8013
        .FILL x0240
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x04A0
        .FILL xFFA2
        .FILL x00FF
        .FILL x8018
        .FILL x0480
        .FILL xFFFC
        .FILL x00BF
        .FILL x801C
        .FILL x0260
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x04C0
        .FILL xFFF1
        .FILL x00FF
        .FILL x8008
        .FILL x0440
        .FILL xFFF0
        .FILL x00DF
        .FILL x800E
        .FILL x0260
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x04E0
        .FILL xFFF9
        .FILL x00DF
        .FILL x8017
        .FILL x0440
        .FILL xFFFC
        .FILL x00BF
        .FILL x8016
        .FILL x0280
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x04E0
        .FILL xFFA6
        .FILL x00FF
        .FILL x800C
        .FILL x0400
        .FILL xFFF3
        .FILL x00BF
        .FILL x803B
        .FILL x8001
        .FILL x0280
        .FILL xFFFA
        .FILL x00DF
        .FILL x8009
        .FILL x0500
        .FILL xFFEE
        .FILL x00DF
        .FILL x801A
        .FILL x03E0
        .FILL xFFC9
        .FILL x00BF
        .FILL x815E
        .FILL x800A
        .FILL x02A0
        .FILL xFFFB
        .FILL x00DF
        .FILL x800A
        .FILL x0520
        .FILL xFFF2
        .FILL x00DF
        .FILL x8015
        .FILL x03C0
        .FILL xFFFB
        .FILL x009F
        .FILL x81BE
        .FILL x800D
        .FILL x02C0
        .FILL xFFFB
        .FILL x00DF
        .FILL x800B
        .FILL x0540
        .FILL xFFF5
        .FILL x00DF
        .FILL x800E
        .FILL x0380
        .FILL xFFF8
        .FILL x00BF
        .FILL x8010
        .FILL x02E0
        .FILL xFFFC
        .FILL x00DF
        .FILL x800E
        .FILL x0560
        .FILL xFFF6
        .FILL x00BF
        .FILL x817E
        .FILL x800B
        .FILL x0340
        .FILL xFFF6
        .FILL x00BF
        .FILL x8010
        .FILL x0300

        .FILL xFFFD
        .FILL x00DF
        .FILL x8010
        .FILL x0580
        .FILL xFFF4
        .FILL x00BF
        .FILL x817D
        .FILL x800B
        .FILL x02E0
        .FILL xFF01
        .FILL x00BF
        .FILL x81FE
        .FILL x800F
        .FILL x0320
        .FILL xFFFE
        .FILL x00DF
        .FILL x8014
        .FILL x05A0
        .FILL xFFF3
        .FILL x00BF
        .FILL x81DE
        .FILL x800E
        .FILL x02A0
        .FILL xFF69
        .FILL x00BF
        .FILL x81BD
        .FILL x800D
        .FILL x0320
        .FILL xFFEB
        .FILL x00FF
        .FILL x8018
        .FILL x05C0
        .FILL xFFAD
        .FILL x00DF
        .FILL x8056
        .FILL x8002
        .FILL x0240
        .FILL xFFD3
        .FILL x00BF
        .FILL x80FA
        .FILL x8007
        .FILL x0340
        .FILL xFFF5
        .FILL x00FF
        .FILL x801D
        .FILL x05E0
        .FILL xFF27
        .FILL x00DF
        .FILL x865D
        .FILL x8032
        .FILL x8001
        .FILL x01A0
        .FILL xF221
        .FILL x00FF
        .FILL x8015
        .FILL x0360
        .FILL xFFCB
        .FILL x013F
        .FILL x8013
        .FILL x0600
        .FILL xFFB0
        .FILL x00DF
        .FILL xBEFE
        .FILL x804F
        .FILL x8002
        .FILL x00E0
        .FILL xDE04
        .FILL xFFFE
        .FILL x00BF
        .FILL x815A
        .FILL x800A
        .FILL x0360
        .FILL xFFAE
        .FILL x017F
        .FILL x8014
        .FILL x0600
        .FILL xF683
        .FILL x013F
        .FILL xE35C
        .FILL xE717
        .FILL xFFBA
        .FILL x011F
        .FILL x821B
        .FILL x8010
        .FILL x0320
        .FILL xC986
        .FILL xFFF9
        .FILL x01BF
        .FILL xBABC
        .FILL x850E
        .FILL x8028
        .FILL x8001
        .FILL x05A0
        .FILL xEE62
        .FILL x02FF
        .FILL x81FA
        .FILL x800F
        .FILL x0300
        .FILL xFFF7
        .FILL x035F
        .FILL x05C0
        .FILL xEECB
        .FILL x021F
        .FILL xD35E
        .FILL x80F4
        .FILL x8007
        .FILL x0340
        .FILL xFFF7
        .FILL x035F
        .FILL x0620
        .FILL xD604
        .FILL xF778
        .FILL xFFFE
        .FILL xFBFF
        .FILL xE37D
        .FILL x85D5
        .FILL x802E
        .FILL x8001
        .FILL x5A60
        
        .FILL x0000 ; NULL termination
        
        .END