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

; Decompress encoded image
        LD R2 IMAGE_PTR
        LD R3 IMAGE
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
                        BRp PACKED_LOOP
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

        LD R0 RED ; Red is the default color
        LD R3 INC
        LD R4 RESET
        LD R5 K127
        LD R6 STOP
LOOP    ADD R0 R0 0 ; Check if color is black (q was pressed)
        BRz END
        LD R1 IMAGE
        LD R2 CORNER
        DISPLAY_LOOP
                LDR R7 R1 0 ; Load pixel, set hue, push to display
                AND R7 R7 R0
                STR R7 R2 0

                ADD R1 R1 R3 ; Increment image pointer
                ADD R2 R2 1 ; Increment display pointer
                AND R7 R2 R5 ; Check if end of row
                BRp DISPLAY_LOOP
                ADD R1 R1 R4 ; Reset to start of next row
                ADD R7 R2 R6 ; Check if end of display area
                BRp DISPLAY_LOOP
        INPUT_LOOP
                IN
                ADD R1 R0 0
                LEA R2 RED
                COLOR_LOOP
                        LDR R0 R2 0 ; Load color and check if we've exceded bounds
                        BRn INPUT_LOOP
                        LDR R7 R2 6 ; Load letter and test against it
                        ADD R7 R7 R1
                        BRz LOOP

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
INC     .FILL 80
RESET   .FILL -10239 ; 1 - 80 * 128
STOP    .FILL -62208 ; Last index of the display area

K32     .FILL 32
K127    .FILL 127
IMAGE_PTR
        .FILL COMPRESSED_IMAGE

EXIT_MSG
        .STRINGZ "Thank you for playing\n"
        
IMAGE   .BLKW 10960 ; 137x80 px

; Custom compression format:
; If MSB is 0:
;     lower 5 bits are the grayscale color
;     upper 11 bits are the run length of that color - 1
; else:
;     lower 15 bits contain next 3 pixels grayscale colors packed together,
;     next pixel is lowest 5 bits
; The entire image is transposed
; The sequence is NULL terminated
COMPRESSED_IMAGE ; initials encoded in custom compression format
        .FILL x0440
        .FILL xA4E1
        .FILL xB5AB
        .FILL x9D2B
        .FILL x8002
        .FILL x0780
        .FILL xDA28
        .FILL xF379
        .FILL xFFFE
        .FILL x00FF
        .FILL xEFBE
        .FILL xC6D9
        .FILL x800A
        .FILL x0620
        .FILL xEA8A
        .FILL xFFFE
        .FILL x02BF
        .FILL xD75E
        .FILL x800C
        .FILL x0540
        .FILL xF6CB
        .FILL x03FF
        .FILL xB2FD
        .FILL x04C0
        .FILL xEE41
        .FILL x04BF
        .FILL x929C
        .FILL x0420
        .FILL xF661
        .FILL x053F
        .FILL x929D
        .FILL x03C0
        .FILL xFFB0
        .FILL x059F
        .FILL x825D
        .FILL x0340
        .FILL xFF29
        .FILL x061F
        .FILL x815A
        .FILL x02E0
        .FILL xFFD1
        .FILL x065F
        .FILL x825E
        .FILL x02A0
        .FILL xFFF6
        .FILL x06BF
        .FILL x8037
        .FILL x0220
        .FILL xFF44
        .FILL x071F
        .FILL x809A
        .FILL x01E0
        .FILL xFF44
        .FILL x029F
        .FILL xE35C
        .FILL xD2B7
        .FILL xCA53
        .FILL xD693
        .FILL xEB16
        .FILL xFFFC
        .FILL x027F
        .FILL x809A
        .FILL x01A0
        .FILL xFF43
        .FILL x021F
        .FILL xCB1C
        .FILL x800B
        .FILL x01E0
        .FILL xE24B
        .FILL xFFFC
        .FILL x01FF
        .FILL x807A
        .FILL x0180
        .FILL xFFF8
        .FILL x01BF
        .FILL xA6BB
        .FILL x0320
        .FILL xEE88
        .FILL x01FF
        .FILL x8018
        .FILL x0140
        .FILL xFFF3
        .FILL x019F
        .FILL x81B8
        .FILL x03C0
        .FILL xFF0C
        .FILL x01BF
        .FILL x8013
        .FILL x0100
        .FILL xFFED
        .FILL x017F
        .FILL x8159
        .FILL x0440
        .FILL xFF29
        .FILL x019F
        .FILL x800C
        .FILL x00E0
        .FILL xFFFB
        .FILL x013F
        .FILL x81DD
        .FILL x04C0
        .FILL xFFAF
        .FILL x015F
        .FILL x801B
        .FILL x00C0
        .FILL xFFF3
        .FILL x013F
        .FILL x80B8
        .FILL x0500
        .FILL xFF26
        .FILL x015F
        .FILL x8013
        .FILL x0080
        .FILL xFFC5
        .FILL x013F
        .FILL x8015
        .FILL x0560
        .FILL xFFF6
        .FILL x011F
        .FILL x80BE
        .FILL x0080
        .FILL xFFF4
        .FILL x011F
        .FILL x8013
        .FILL x05A0
        .FILL xFFF4
        .FILL x011F
        .FILL x8015
        .FILL x8000
        .FILL xFFA1
        .FILL x011F
        .FILL x8015
        .FILL x05E0
        .FILL xFFF6
        .FILL x00FF
        .FILL x807E
        .FILL x8000
        .FILL xFFF2
        .FILL x00FF
        .FILL x8018
        .FILL x0620
        .FILL xFFF9
        .FILL x00FF
        .FILL x8013
        .FILL xE800
        .FILL x011F
        .FILL x80BD
        .FILL x0640
        .FILL xFFA7
        .FILL x00FF
        .FILL x801B
        .FILL xFCE0
        .FILL x011F
        .FILL x800F
        .FILL x0660
        .FILL xFFF0
        .FILL x00FF
        .FILL x8009
        .FILL xFFF4
        .FILL x00DF
        .FILL x801A
        .FILL x06A0
        .FILL xFFFA
        .FILL x00DF
        .FILL x8015
        .FILL xFFFA
        .FILL x00DF
        .FILL x800D
        .FILL x06A0
        .FILL xFFEE
        .FILL x00DF
        .FILL x801A
        .FILL xFFFE
        .FILL x00BF
        .FILL x801B
        .FILL x06E0
        .FILL xFFFC
        .FILL x00BF
        .FILL xAC1E
        .FILL x011F
        .FILL x8013
        .FILL x06E0
        .FILL xFFF4
        .FILL x00DF
        .FILL xFE6D
        .FILL x00FF
        .FILL x8007
        .FILL x06E0
        .FILL xFFE8
        .FILL x00DF
        .FILL xFED3
        .FILL x00DF
        .FILL x801C
        .FILL x0720
        .FILL xFFFC
        .FILL x00BF
        .FILL xFF37
        .FILL x00DF
        .FILL x8018
        .FILL x0720
        .FILL xFFF8
        .FILL x00BF
        .FILL xFF9A
        .FILL x00DF
        .FILL x8014
        .FILL x0720
        .FILL xFFF4
        .FILL x00BF
        .FILL xFFBC
        .FILL x00DF
        .FILL x8010
        .FILL x0720
        .FILL xFFF0
        .FILL x00BF
        .FILL xFFDD
        .FILL x00DF
        .FILL x800B
        .FILL x0720
        .FILL xFFEB
        .FILL x00BF
        .FILL xFFFE
        .FILL x00DF
        .FILL x8009
        .FILL x0720
        .FILL xFFE8
        .FILL x01FF
        .FILL x8004
        .FILL x0720
        .FILL xFFE4
        .FILL x01FF
        .FILL x8005
        .FILL x0720
        .FILL xFFE4
        .FILL x00DF
        .FILL xFFFE
        .FILL x00BF
        .FILL x8009
        .FILL x0720
        .FILL xFFE8
        .FILL x00DF
        .FILL xFFFE
        .FILL x00BF
        .FILL x800C
        .FILL x0720
        .FILL xFFEB
        .FILL x00BF
        .FILL xFFBE
        .FILL x00DF
        .FILL x8010
        .FILL x0720
        .FILL xFFF0
        .FILL x00BF
        .FILL xFF9D
        .FILL x00DF
        .FILL x8014
        .FILL x0720
        .FILL xFFF4
        .FILL x00BF
        .FILL xFF3C
        .FILL x00DF
        .FILL x8018
        .FILL x0720
        .FILL xFFF8
        .FILL x00BF
        .FILL xFEDA
        .FILL x00DF
        .FILL x801C
        .FILL x0720
        .FILL xFFFC
        .FILL x00BF
        .FILL xFE77
        .FILL x00FF
        .FILL x8008
        .FILL x06E0
        .FILL xFFE8
        .FILL x00DF
        .FILL xFD74
        .FILL x00FF
        .FILL x8014
        .FILL x06E0
        .FILL xFFF4
        .FILL x00DF
        .FILL xF80D
        .FILL x00FF
        .FILL x801C
        .FILL x06E0
        .FILL xFFFC
        .FILL x00BF
        .FILL x801E
        .FILL xFFFA
        .FILL x00DF
        .FILL x800E
        .FILL x06A0
        .FILL xFFEF
        .FILL x00DF
        .FILL x801B
        .FILL xFFF4
        .FILL x00DF
        .FILL x801B
        .FILL x06A0
        .FILL xFFFB
        .FILL x00DF
        .FILL x8015
        .FILL xFFE7
        .FILL x00FF
        .FILL x8011
        .FILL x0660
        .FILL xFFF1
        .FILL x00FF
        .FILL x800A
        .FILL xFF40
        .FILL x00FF
        .FILL x811E
        .FILL x0640
        .FILL xFFC8
        .FILL x00FF
        .FILL x801B
        .FILL xC800
        .FILL x013F
        .FILL x801A
        .FILL x0600
        .FILL xFF41
        .FILL x011F
        .FILL x8014
        .FILL x8000
        .FILL xFFFD
        .FILL x00FF
        .FILL x8017
        .FILL x05E0
        .FILL xFFF7
        .FILL x00FF
        .FILL x809E
        .FILL x0060
        .FILL xFFF3
        .FILL x011F
        .FILL x8016
        .FILL x05A0
        .FILL xFFF6
        .FILL x011F
        .FILL x8015
        .FILL x0060
        .FILL xFFA2
        .FILL x013F
        .FILL x8018
        .FILL x0560
        .FILL xFFF7
        .FILL x011F
        .FILL x80BE
        .FILL x00A0
        .FILL xFFF1
        .FILL x013F
        .FILL x813B
        .FILL x0500
        .FILL xFF48
        .FILL x015F
        .FILL x8012
        .FILL x00C0
        .FILL xFFFA
        .FILL x013F
        .FILL x825E
        .FILL x04C0
        .FILL xFFD1
        .FILL x015F
        .FILL x801A
        .FILL x00E0
        .FILL xFFCA
        .FILL x017F
        .FILL x81BB
        .FILL x0440
        .FILL xFF4C
        .FILL x017F
        .FILL x817E
        .FILL x0120
        .FILL xFFF1
        .FILL x019F
        .FILL x821B
        .FILL x03C0
        .FILL xFF4F
        .FILL x01BF
        .FILL x8011
        .FILL x0140
        .FILL xFFF6
        .FILL x01BF
        .FILL xBAFD
        .FILL x0320
        .FILL xF6ED
        .FILL x01FF
        .FILL x8016
        .FILL x0180
        .FILL xFFF9
        .FILL x01FF
        .FILL xD75E
        .FILL x8110
        .FILL x01C0
        .FILL xD1E7
        .FILL xFFDA
        .FILL x021F
        .FILL x8018
        .FILL x01A0
        .FILL xFF21
        .FILL x029F
        .FILL xEB9E
        .FILL xDAF9
        .FILL xD6B6
        .FILL xDED6
        .FILL xF358
        .FILL xFFFE
        .FILL x027F
        .FILL x8018
        .FILL x01E0
        .FILL xFF01
        .FILL x071F
        .FILL x8018
        .FILL x0240
        .FILL xFFF4
        .FILL x06BF
        .FILL x8014
        .FILL x0280
        .FILL xFFD0
        .FILL x065F
        .FILL x81FD
        .FILL x02E0
        .FILL xFF07
        .FILL x061F
        .FILL x80D8
        .FILL x0340
        .FILL xFF8F
        .FILL x059F
        .FILL x81DC
        .FILL x03C0
        .FILL xFF91
        .FILL x051F
        .FILL x821C
        .FILL x0440
        .FILL xFF50
        .FILL x049F
        .FILL x8219
        .FILL x04C0
        .FILL xEEA8
        .FILL x03FF
        .FILL x9E9B
        .FILL x0580
        .FILL xE247
        .FILL xFFFC
        .FILL x02BF
        .FILL xCB1C
        .FILL x8006
        .FILL x0620
        .FILL xD1C3
        .FILL xEF37
        .FILL xFFDD
        .FILL x00DF
        .FILL xEFBE
        .FILL xD2F9
        .FILL x806E
        .FILL x0800
        .FILL xA105
        .FILL x8005
        .FILL x7FE0
        .FILL x1AA0
        .FILL x097D
        .FILL x0060
        .FILL x097F
        .FILL x0060
        .FILL x097F
        .FILL x0060
        .FILL x097F
        .FILL x0060
        .FILL x097F
        .FILL x0060
        .FILL x097F
        .FILL x0060
        .FILL x097F
        .FILL x0060
        .FILL x097F
        .FILL x0060
        .FILL x097F
        .FILL x0060
        .FILL x097F
        .FILL x0060
        .FILL x011F
        .FILL x03B0
        .FILL x011F
        .FILL x0370
        .FILL x0060
        .FILL x011F
        .FILL x03A0
        .FILL x011F
        .FILL x03E0
        .FILL x011F
        .FILL x03A0
        .FILL x011F
        .FILL x03E0
        .FILL x011F
        .FILL x03A0
        .FILL x011F
        .FILL x03E0
        .FILL x011F
        .FILL x03A0
        .FILL x011F
        .FILL x03E0
        .FILL x011F
        .FILL x03A0
        .FILL x011F
        .FILL x03E0
        .FILL x011F
        .FILL x03A0
        .FILL x011F
        .FILL x03E0
        .FILL x011F
        .FILL x03A0
        .FILL x011F
        .FILL x03E0
        .FILL x011F
        .FILL x03A0
        .FILL x011F
        .FILL x03E0
        .FILL x011F
        .FILL x0380
        .FILL xFFE4
        .FILL x00DF
        .FILL x03E0
        .FILL x011F
        .FILL x8002
        .FILL x0320
        .FILL xFFE7
        .FILL x00DF
        .FILL x03E0
        .FILL x011F
        .FILL x8005
        .FILL x0320
        .FILL xFFE9
        .FILL x00DF
        .FILL x03E0
        .FILL x011F
        .FILL x8008
        .FILL x0320
        .FILL xFFEC
        .FILL x00DF
        .FILL x03E0
        .FILL x011F
        .FILL x800B
        .FILL x0320
        .FILL xFFEF
        .FILL x00BF
        .FILL x801E
        .FILL x03A0
        .FILL xFFFE
        .FILL x00BF
        .FILL x800E
        .FILL x0320
        .FILL xFFF2
        .FILL x00BF
        .FILL x801D
        .FILL x03A0
        .FILL xFFFD
        .FILL x00BF
        .FILL x8012
        .FILL x0320
        .FILL xFFF6
        .FILL x00BF
        .FILL x801B
        .FILL x03A0
        .FILL xFFFC
        .FILL x00BF
        .FILL x8015
        .FILL x0320
        .FILL xFFF9
        .FILL x00BF
        .FILL x801A
        .FILL x03A0
        .FILL xFFFA
        .FILL x00BF
        .FILL x8019
        .FILL x0320
        .FILL xFFFD
        .FILL x00BF
        .FILL x8018
        .FILL x03A0
        .FILL xFFF7
        .FILL x00BF
        .FILL x801D
        .FILL x0300
        .FILL xFFE9
        .FILL x00DF
        .FILL x8014
        .FILL x03A0
        .FILL xFFF4
        .FILL x00DF
        .FILL x800C
        .FILL x02E0
        .FILL xFFF4
        .FILL x00DF
        .FILL x800E
        .FILL x03A0
        .FILL xFFEF
        .FILL x00DF
        .FILL x8015
        .FILL x02E0
        .FILL xFFFC
        .FILL x00DF
        .FILL x8003
        .FILL x03A0
        .FILL xFFE4
        .FILL x00DF
        .FILL x803D
        .FILL x02C0
        .FILL xFFF0
        .FILL x00DF
        .FILL x801B
        .FILL x03E0
        .FILL xFFFC
        .FILL x00DF
        .FILL x8013
        .FILL x0280
        .FILL xFF81
        .FILL x00FF
        .FILL x8015
        .FILL x03E0
        .FILL xFFF6
        .FILL x00DF
        .FILL x80BD
        .FILL x0280
        .FILL xFFF6
        .FILL x00FF
        .FILL x800B
        .FILL x03E0
        .FILL xFFEE
        .FILL x00FF
        .FILL x8018
        .FILL x0240
        .FILL xFFF2
        .FILL x00FF
        .FILL x801B
        .FILL x0420
        .FILL xFFFC
        .FILL x00FF
        .FILL x8016
        .FILL x0200
        .FILL xFFF3
        .FILL x011F
        .FILL x8011
        .FILL x0420
        .FILL xFFF5
        .FILL x011F
        .FILL x8098
        .FILL x01A0
        .FILL xFF05
        .FILL x013F
        .FILL x801C
        .FILL x0440
        .FILL xFFC6
        .FILL x013F
        .FILL x865D
        .FILL x0140
        .FILL xF664
        .FILL x017F
        .FILL x8010
        .FILL x0460
        .FILL xFFF6
        .FILL x015F
        .FILL xC6FD
        .FILL x8009
        .FILL x9000
        .FILL xE66B
        .FILL xFFFE
        .FILL x015F
        .FILL x801A
        .FILL x0480
        .FILL xFFA5
        .FILL x01FF
        .FILL xFFBE
        .FILL x021F
        .FILL x813E
        .FILL x04C0
        .FILL xFFF1
        .FILL x045F
        .FILL x8011
        .FILL x04E0
        .FILL xFFF7
        .FILL x041F
        .FILL x8015
        .FILL x0500
        .FILL xFF62
        .FILL x03FF
        .FILL x8017
        .FILL x0540
        .FILL xFF87
        .FILL x03BF
        .FILL x8017
        .FILL x0580
        .FILL xFF88
        .FILL x037F
        .FILL x8014
        .FILL x05C0
        .FILL xFF04
        .FILL x031F
        .FILL x81DD
        .FILL x0640
        .FILL xFFD2
        .FILL x029F
        .FILL x8EBE
        .FILL x06A0
        .FILL xFAC6
        .FILL x023F
        .FILL x9EDE
        .FILL x0720
        .FILL xE643
        .FILL xFFFE
        .FILL x013F
        .FILL xC33D
        .FILL x8001
        .FILL x07A0
        .FILL xD62B
        .FILL xE717
        .FILL xDF19
        .FILL xA635
        .FILL x0600

        .FILL x0000 ; NULL termination
        
        .END