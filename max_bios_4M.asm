            INCL    "1802.inc"

ECHO:       EQU     1

STATE:      EQU     RC
DEST:       EQU     RD
SRC:        EQU     RD

HIMEM:      EQU     $7FFF

            SHARED  CHAROUT
CHAROUT     EQU     HIMEM - 2
            SHARED  CHARIN
CHARIN      EQU     CHAROUT - 3

            ORG     $8B00

;------------------------------------------------------------------------
;Routine to load a binary file from the serial port.
            SHARED  LOADBIN
LOADBIN:    GHI     STATE       ;Save registers used by
            STXD                ;binary loader.
            GLO     STATE
            STXD
            GHI     DEST
            STXD
            GLO     DEST
            STXD
            LDI     $0
            PHI     DEST
            PLO     DEST
            PLO     STATE
LDNEXT:     CALL    SERIN
            PHI     STATE       ;Save a copy
            STR     R2          ;Display it on the data display
            OUT     4
            DEC     R2
            GLO     STATE       ;Implement state machine
            BZ      STATE0
            SMI     $01
            BZ      STATE1
            SMI     $01
            BZ      STATE2
            SMI     $01
            BZ      STATE3
            SMI     $01
            BZ      STATE4
            SMI     $01
            BZ      STATE5
            LDI     $00
            PLO     STATE
            BR      LDNEXT
STATE0:     GHI     STATE       ;State 0 - Check if the byte is
            ANI     $FC         ;a special character ($7C-$7f)
            XRI     $7C         ;If it is, process it
            BZ      SPECIAL
            GHI     STATE       ;If not, copy it to destination
            STR     DEST        ;memory address
            INC     DEST        ;Update destination address
            BR      LDNEXT
STATE1:     GHI     STATE       ;State 1 - Load new high
            PHI     DEST        ;destination address
            LDI     $02         ;Go to state 2
            PLO     STATE
            BR      LDNEXT
STATE2:     GHI     STATE       ;State 2 - Load new low
            PLO     DEST        ;destination address
            LDI     $00         ;Return to state 0
            PLO     STATE
            BR      LDNEXT
STATE3:     GHI     STATE       ;State 3 - process escape
            XRI     $20         ;character by XORing next
            STR     DEST        ;byte with 0x20 before
            INC     DEST        ;storing
            LDI     $00         ;Return to state 0
            PLO     STATE
            BR      LDNEXT
STATE4:     GHI     STATE       ;State 4 - Load high run
            PHI     R0          ;address
            LDI     $05         ;Go to state 5
            PLO     STATE
            BR      LDNEXT
STATE5:     GHI     STATE       ;State 5 - Load low run
            PLO     R0          ;address and start program
            SEP     R0          ;with PC=R0
SPECIAL:    GHI     STATE       ;Process special character
            ANI     $03
            BZ      NEWADDR     ;$7C - new dest. address
            SMI     $01
            BZ      ESCAPE      ;$7D - escape next byte
            SMI     $01
            BZ      RUNADDR     ;$7E - run address
            BR      LDRETN      ;$7F - end of file
NEWADDR:    LDI     $01         ;Go to state 1
            PLO     STATE
            BR      LDNEXT
ESCAPE:     LDI     $03         ;Go to state 3
            PLO     STATE
            BR      LDNEXT
RUNADDR:    LDI     $04         ;Go to state 4
            PLO     STATE
            BR      LDNEXT
LDRETN:     IRX                 ;Restore registers
            LDXA
            PLO DEST
            LDXA
            PHI DEST
            LDXA
            PLO STATE
            LDX
            PHI STATE
            RETN

; **** convert binary number to ascii
; **** RD - number to convert
; **** RF - buffer to store
; **** Returns: RF - last postion+1
            SHARED  UINTOUT
            SHARED  INTOUT
UINTOUT:    BR      POSITIVE
INTOUT:     SEX     R2          ; point X to stack
            GHI     RD          ; get high of number
            ANI     128         ; mask all bit sign bit
            BZ      POSITIVE    ; jump if number is positive
            LDI     '-'         ; need a minus sign
            STR     RF          ; store into output
            INC     RF
            GLO     RD          ; get low byte
            STR     R2          ; store it
            LDI     0           ; need to subtract from 0
            SM
            PLO     RD          ; put back
            GHI     RD          ; get high byte
            STR     R2          ; place into memory
            LDI     0           ; still subtracting from zero
            SMB
            PHI     RD          ; and put back
POSITIVE:   GLO     R7          ; save consumed registers
            STXD
            GHI     R7
            STXD
            GLO     R8          ; save consumed registers
            STXD
            GHI     R8
            STXD
            GLO     R9          ; save consumed registers
            STXD
            GHI     R9
            STXD
            RLDI    R9,NUMBERS  ; point to numbers
            LDA     R9          ; get first division
            PHI     R7
            LDA     R9
            PLO     R7
            LDI     0           ; leading zero flag
            STXD                ; store onto stack
NXTITER:    LDI     0           ; star count at zero
            PLO     R8          ; place into low of r8
DIVLP:      GLO     R7          ; get low of number to subtrace
            STR     R2          ; place into memory
            GLO     RD          ; get low of number
            SM                  ; subtract
            PHI     R8          ; place into temp space
            GHI     R7          ; get high of subtraction
            STR     R2          ; place into memory
            GHI     RD          ; get high of number
            SMB                 ; perform subtract
            BNF     NOMORE      ; jump if subtraction was too large
            PHI     RD          ; store result
            GHI     R8
            PLO     RD
            INC     R8          ; increment count
            BR      DIVLP       ; and loop back
NOMORE:     IRX                 ; point back to leading zero flag
            GLO     R8
            BNZ     NONZERO     ; jump if not zero
            LDN     R2          ; get flag
            BNZ     ALLOW0      ; jump if no longer zero
            DEC     R2          ; keep leading zero flag
            BR      FINDNXT     ; skip output
ALLOW0:     LDI     0           ; recover the zero
NONZERO:    ADI     30H         ; convert to ascii
            STR     RF          ; store into buffer
            INC     RF
            LDI     1           ; need to set leading flag
            STXD                ; store it
FINDNXT:    DEC     R7          ; subtract 1 for zero check
            GLO     R7          ; check for end
            BZ      INTDONE     ; jump if done
            LDA     R9          ; get next number
            PHI     R7
            LDA     R9
            PLO     R7
            SMI     1           ; see if at last number
            BNZ     NXTITER     ; jump if not
            IRX                 ; set leading flag
            LDI     1
            STXD
            BR      NXTITER
INTDONE:    IRX                 ; put x back where it belongs
            IRX                 ; recover consumed registers
            LDXA
            PHI     R9
            LDXA
            PLO     R9
            LDXA
            PHI     R8
            LDXA
            PLO     R8
            LDXA
            PHI     R7
            LDX
            PLO     R7
            RETN                ; return to caller

            PAGE

;------------------------------------------------------------------------
;Routine to read a single character at 38400 baud from serial port.
;
;This routine is designed for a 4MHz system clock.
;
;On exit, D contains the character.
            SHARED  SERIN
SERIN:      BN3     SERIN       ;Wait for start bit.
            NOP
            NOP
            NOP
            NOP
            NOP
            SEX     R2
SI_B0:      BN3     SI_B0_1
            ANI     $7F
            LBR     SI_B1
SI_B0_1:    ORI     $80
            LBR     SI_B1
SI_B1:      SHR
            SEX     R2
            SEX     R2
            BN3     SI_B1_1
            ANI     $7F
            LBR     SI_B2
SI_B1_1:    ORI     $80
            LBR     SI_B2
SI_B2:      SHR
            SEX     R2
            SEX     R2
            BN3     SI_B2_1
            ANI     $7F
            LBR     SI_B3
SI_B2_1:    ORI     $80
            LBR     SI_B3
SI_B3:      SHR
            SEX     R2
            SEX     R2
            BN3     SI_B3_1
            ANI     $7F
            LBR     SI_B4
SI_B3_1:    ORI     $80
            LBR     SI_B4
SI_B4:      SHR
            SEX     R2
            SEX     R2
            BN3     SI_B4_1
            ANI     $7F
            LBR     SI_B5
SI_B4_1:    ORI     $80
            LBR     SI_B5
SI_B5:      SHR
            SEX     R2
            SEX     R2
            BN3     SI_B5_1
            ANI     $7F
            LBR     SI_B6
SI_B5_1:    ORI     $80
            LBR     SI_B6
SI_B6:      SHR
            SEX     R2
            SEX     R2
            BN3     SI_B6_1
            ANI     $7F
            LBR     SI_B7
SI_B6_1:    ORI     $80
            LBR     SI_B7
SI_B7:      SHR
            SEX     R2
            SEX     R2
            BN3     SI_B7_1
            ANI     $7F
            LBR     SI_STOP
SI_B7_1:    ORI     $80
            LBR     SI_STOP
SI_STOP:    NOP
            NOP
SI_WAIT:    B3      SI_WAIT

            RETN

;------------------------------------------------------------------------
;Routine to write a single character at 38400 baud to serial port.
;
;
;This routine is designed for a 4MHz system clock.
;
;On entry, D contains the character.
            SHARED  SEROUT
SEROUT:     SEQ                 ;Start bit.
            SEX     R2
            SEX     R2
SO_B0:      SHRC
            SEX     R2
            SEX     R2
            BDF     SO_B0_1
            SEQ
            LBR     SO_B1
SO_B0_1:    REQ
            LBR     SO_B1
SO_B1:      SHRC
            SEX     R2
            SEX     R2
            BDF     SO_B1_1
            SEQ
            LBR     SO_B2
SO_B1_1:    REQ
            LBR     SO_B2
SO_B2:      SHRC
            SEX     R2
            SEX     R2
            BDF     SO_B2_1
            SEQ
            LBR     SO_B3
SO_B2_1:    REQ
            LBR     SO_B3
SO_B3:      SHRC
            SEX     R2
            SEX     R2
            BDF     SO_B3_1
            SEQ
            LBR     SO_B4
SO_B3_1:    REQ
            LBR     SO_B4
SO_B4:      SHRC
            SEX     R2
            SEX     R2
            BDF     SO_B4_1
            SEQ
            LBR     SO_B5
SO_B4_1:    REQ
            LBR     SO_B5
SO_B5:      SHRC
            SEX     R2
            SEX     R2
            BDF     SO_B5_1
            SEQ
            LBR     SO_B6
SO_B5_1:    REQ
            LBR     SO_B6
SO_B6:      SHRC
            SEX     R2
            SEX     R2
            BDF     SO_B6_1
            SEQ
            LBR     SO_B7
SO_B6_1:    REQ
            LBR     SO_B7
SO_B7:      SHRC
            SEX     R2
            SEX     R2
            BDF     SO_B7_1
            SEQ
            LBR     SO_STOP
SO_B7_1:    REQ
            LBR     SO_STOP
SO_STOP:    NOP
            NOP
            SEX     R2
            REQ                 ;Stop bit.
            SHRC                ;Restore D.

            RETN

; **** memcpy copies R[C] bytes from R[F] to R[D]
            SHARED  MEMCPY
MEMCPY:     GLO     RC          ; get low count byte
            BNZ     MEMCPY1     ; jump if not zero
            GHI     RC          ; get high count byte
            LBZ     RETURN      ; return if zero
MEMCPY1:    LDA     RF          ; get byte from source
            STR     RD          ; store into destination
            INC     RD          ; point to next destination position
            DEC     RC          ; decrement count
            BR      MEMCPY      ; and continue copy

; *** RB = RF/RD
; *** RF = REMAINDER
; *** USES R8 AND R9
            SHARED  DIV16
DIV16:      LDI     0           ; clear answer
            PHI     RB
            PLO     RB
            PHI     R8          ; set additive
            PLO     R8
            INC     R8
            GLO     RD          ; check for divide by 0
            BNZ     D16LP1
            GHI     RD
            BNZ     D16LP1
            LDI     0FFH        ; return 0ffffh as div/0 error
            PHI     RB
            PLO     RB
            RETN
D16LP1:     GHI     RD          ; get high byte from r7
            ANI     128         ; check high bit
            BNZ     DIVST       ; jump if set
            GLO     RD          ; lo byte of divisor
            SHL                 ; multiply by 2
            PLO     RD          ; and put back
            GHI     RD          ; get high byte of divisor
            SHLC                ; continue multiply by 2
            PHI     RD          ; and put back
            GLO     R8          ; multiply additive by 2
            SHL
            PLO     R8
            GHI     R8
            SHLC
            PHI     R8
            BR      D16LP1      ; loop until high bit set in divisor
DIVST:      GLO     R8          ; get low of divisor
            BNZ     DIVGO       ; jump if still nonzero
            GHI     R8          ; check hi byte too
            LBZ     RETURN      ; jump if done
DIVGO:      GHI     RF          ; copy dividend
            PHI     R9
            GLO     RF
            PLO     R9
            GLO     RD          ; get lo of divisor
            STXD                ; place into memory
            IRX                 ; point to memory
            GLO     RF          ; get low byte of dividend
            SM                  ; subtract
            PLO     RF          ; put back into r6
            GHI     RD          ; get hi of divisor
            STXD                ; place into memory
            IRX                 ; point to byte
            GHI     RF          ; get hi of dividend
            SMB                 ; subtract
            PHI     RF          ; and put back
            BDF     DIVYES      ; branch if no borrow happened
            GHI     R9          ; recover copy
            PHI     RF          ; put back into dividend
            GLO     R9
            PLO     RF
            BR      DIVNO       ; jump to next iteration
DIVYES:     GLO     R8          ; get lo of additive
            STXD                ; place in memory
            IRX                 ; point to byte
            GLO     RB          ; get lo of answer
            ADD                 ; and add
            PLO     RB          ; put back
            GHI     R8          ; get hi of additive
            STXD                ; place into memory
            IRX                 ; point to byte
            GHI     RB          ; get hi byte of answer
            ADC                 ; and continue addition
            PHI     RB          ; put back
DIVNO:      GHI     RD          ; get hi of divisor
            SHR                 ; divide by 2
            PHI     RD          ; put back
            GLO     RD          ; get lo of divisor
            SHRC                ; continue divide by 2
            PLO     RD
            GHI     R8          ; get hi of divisor
            SHR                 ; divide by 2
            PHI     R8          ; put back
            GLO     R8          ; get lo of divisor
            SHRC                ; continue divide by 2
            PLO     R8
            BR      DIVST       ; next iteration

;------------------------------------------------------------------------
;Routine to read a string from the serial port.
;Pointer to buffer passed in RF.
;Max chars to read passed in RC.
            SHARED INPUT
INPUT:      GLO     RA          ; save RA
            STXD
            GHI     RA
            STXD
            LDI     0           ; byte count
            PLO     RA          ; store into counter
INPLP:      CALL    CHARIN       ; call input function
            PLO     RE          ; save char
            SMI     3           ; check for <CTRL><C>
            BZ      INPTERM     ; terminate input
            SMI     5           ; check for <BS>
            BZ      ISBS        ; jump if so
            SMI     5           ; check for <CR>
            BZ      INPDONE     ; jump if so
            GLO     RC          ; check count
            BNZ     INPCNT      ; jump if can continue
            GHI     RC          ; check high of count
            BNZ     INPCNT
            LDI     8           ; perform a backspace
            CALL    CHAROUT
            BR      BS2         ; remove char from screen
INPCNT:     GLO     RE
            STR     RF          ; store into output
            IF      ECHO
            CALL    CHAROUT      ; echo to terminal
            ENDI
            INC     RF          ; point to next position
            SMI     08          ; look for backspace
            BNZ     NOBS        ; jump if not a backspace
ISBS:       GLO     RA          ; get input count
            BZ      INPLP       ; disregard if string is empty
            DEC     RA          ; decrement the count
            DEC     RF          ; decrement buffer position
            INC     RC          ; increment allowed characters
BS2:        LDI     8
            CALL    CHAROUT      ; display a backspace
            LDI     32          ; display a space
            CALL    CHAROUT
            LDI     8           ; then backspace again
            CALL    CHAROUT
            BR      INPLP       ; and loop back for more
NOBS:       INC     RA          ; increment input count
            DEC     RC          ; decrement character count
            BR      INPLP       ; and then loop back
INPDONE:    LDI     0           ; need a zero terminator
            SHR                 ; reset DF flag, to show valid input
INPDONE2:   STR     RF          ; store into buffer
            IRX                 ; recover RA
            LDXA
            PHI     RA
            LDX
            PLO     RA
            RETN                ; return to caller
INPTERM:    SMI     0           ; signal <CTRL><C> exit
            LDI     0           ; finish
            BR      INPDONE2

; ***************************************************************
; *** Function to convert hex input characters to binary      ***
; *** RF - Pointer to characters                              ***
; *** Returns - RF - First character that is not alphanumeric ***
; ***           RD - Converted number                         ***
; ***************************************************************
            SHARED  HEXIN
HEXIN:      LDI     0           ; set initial total
            PHI     RD
            PLO     RD
TOBINLP:    LDA     RF          ; get input character
            SMI     '0'         ; convert to binary
            BNF     TOBINDN     ; jump if termination
            STXD
            ANI     0F0H        ; check for alpha
            IRX                 ; point back
            BZ      ISNUMERIC
            LDX                 ; recover byte
            SMI     49          ; see if lowercase
            BNF     HEXGO
            LDX                 ; get byte
            SMI     32          ; convert to uppercase
            BR      HEXGO2      ; and continue
HEXGO:      LDX                 ; recover byte
HEXGO2:     SMI     7           ; offset
            BR      TOBINGO     ; and continue
ISNUMERIC:  LDX                 ; recover byte
            SMI     10          ; check for end of numbers
            BDF     TOBINDN     ; jump if end
            LDX                 ; recover byte
TOBINGO:    STXD                ; save number
            SMI     16          ; check for valid range
            BNF     TOBINGD     ; jump if good
            IRX                 ; remove number from stack
            BR      TOBINDN
TOBINGD:    LDI     4           ; need to multiply by 16
TOBINGLP:   STXD
            GLO     RD          ; multiply by 2
            SHL
            PLO     RD
            GHI     RD
            SHLC
            PHI     RD
            IRX
            LDI     1
            SD
            BNZ     TOBINGLP
            IRX                 ; point to new number
            GLO     RD          ; and add to total
            ADD
            PLO     RD
            GHI     RD
            ADCI    0
            PHI     RD
            BR      TOBINLP     ; loop back for next character
TOBINDN:    DEC     RF          ; move back to terminating character
            RETN                ; return to caller

            PAGE

; *** rf - pointer to ascii string
; *** returns: rf - first non-numeric character
; ***          RD - number
; ***          DF = 1 if first character non-numeric
            SHARED  ATOI
ATOI:       LDI     0                   ; clear answer
            PHI     RD
            PLO     RD
            PLO     RE                  ; signify positive number
            LDN     RF                  ; get first value
            CALL    ISNUM               ; check if numeric
            BDF     ATOICNT             ; jump if so
            XRI     '-'                 ; check for minus
            BZ      ATOICNT             ; jump if so
            SMI     0                   ; signal number error
            RETN                        ; return to caller
ATOICNT:    LDN     RF                  ; get first bytr
            XRI     '-'                 ; check for negative
            BNZ     ATOILP              ; jump if not negative
            LDI     1                   ; signify negative number
            PLO     RE
            INC     RF                  ; move past - sign
ATOILP:     LDN     RF                  ; get byte from input
            CALL    ISNUM               ; check for number
            LBNF    ATOIDN              ; jump if not
            GHI     RD                  ; make a copy for add
            STXD
            GLO     RD                  ; multiply by 2
            STXD                        ; TOS now has copy of number
            CALL    MUL2                ; multiply by 2
            CALL    MUL2                ; multiply by 4
            IRX                         ; point to adds
            GLO     RD                  ; multiply by 5 (add TOS)
            ADD
            PLO     RD
            IRX                         ; point to msb
            GHI     RD
            ADC
            PHI     RD
            CALL    MUL2                ; multiply by 10
            LDA     RF                  ; get byte from buffer
            SMI     '0'                 ; convert to binary
            STR     R2                  ; prepare for addition
            GLO     RD                  ; add in new digit
            ADD
            PLO     RD
            GHI     RD
            ADCI    0
            PHI     RD
            BR      ATOILP              ; loop back for next character
ATOIDN:     ADI     0                   ; signal valid number
            RETN                        ; return to caller
MUL2:       GLO     RD                  ; multiply number by 2
            SHL
            PLO     RD
            GHI     RD
            SHLC
            PHI     RD
            RETN                        ; and return

;------------------------------------------------------------------------
;Routine to read a two-digit hex number from an input buffer.
;
;On entry:
;  RF = pointer to ascii input buffer
;  1-byte parameter = max number of hex digits
;
;On exit:
;  If DF = 1, first char is not a valid hex char.
;  If DF = 0, RF points to char at end of hex string.
;
            SHARED  GETHEX
GETHEX:     GLO     RE          ;Save registers
            STXD
            GLO     RB
            STXD

            LDA     R6
            PLO     RE
            DEC     RE

            LDN     RF          ;Get next character
            PLO     RB
            CALL    HEX1        ;Translate ascii to value
            BDF     HEX2RET     ;If not valid, return with DF=1
            GLO     RB
            PLO     RD
            LDI     $00
            PHI     RD
HEXNXT:     INC     RF
            LDN     RF
            BZ      HEXTRM
            PLO     RB
            CALL    HEX1
            BDF     HEXTRM
            CALL    SHLD
            DB      $04
            GLO     RB
            STR     R2
            GLO     RD
            OR
            PLO     RD
            DEC     RE
            GLO     RE
            BNZ     HEXNXT
            INC     RF          ;Point to next char
HEXTRM:     ADI     $00         ;Clear DF
HEX2RET:    IRX                 ;Restore registers
            LDXA
            PLO     RB
            LDX
            PLO     RE

            RETN

SHLD:       GLO     RE
            STXD
            LDA     R6
            PLO     RE
DSHFT:      GLO     RD
            SHL
            PLO     RD
            GHI     RD
            SHLC
            PHI     RD
            DEC     RE
            GLO     RE
            BNZ     DSHFT
            IRX
            LDX
            PLO     RE
            RETN

; *********************************************
; *** Convert a binary number to hex output ***
; *** RD - Number to convert                ***
; *** RF - Buffer for output                ***
; *** Returns: RF - next buffer position    ***
; ***          RD - consumed                ***
; *********************************************
            SHARED  HEXOUT2
            SHARED  HEXOUT4
HEXOUT2:    GLO     RD          ; move low byte to high
            PHI     RD
            LDI     2           ; 2 nybbles to display
            LSKP                ; skip over the 4
HEXOUT4:    LDI     4           ; 4 nybbles to display
HEXOUTLP:   STXD                ; save the count
            LDI     0           ; zero the temp var
            PLO     RE
            LDI     4           ; perform 4 shift
HEXOUTL2:   STXD                ; save count
            GLO     RD          ; perform shift
            SHL
            PLO     RD
            GHI     RD
            SHLC
            PHI     RD
            GLO     RE
            SHLC
            PLO     RE
            IRX                 ; point back to count
            LDI     1           ; need to decrement it
            SD
            BNZ     HEXOUTL2    ; jump if more shifts needed
            GLO     RE          ; get nybble
            SMI     10          ; compare to 10
            BDF     HEXOUTAL    ; jump if alpha
            GLO     RE          ; get value
            ADI     30H         ; convert to ascii
HEXOUTL3:   STR     RF          ; store value into buffer
            INC     RF
            IRX                 ; point to count
            LDI     1           ; need to subtract 1 from it
            SD
            BNZ     HEXOUTLP    ; loop if not done
            RETN                ; return to caller
HEXOUTAL:   GLO     RE          ; get value
            ADI     55          ; convert to ascii
            BR      HEXOUTL3    ; and continue

;------------------------------------------------------------------------
;Routine to save a binary file in MAX format.
;
;On entry:
;  RA = start address of saved data
;  RC = count of bytes to save
;
            SHARED  SAVEBIN
SAVEBIN:    GLO     RB
            STXD
            CALL    SERIN       ;Wait for receiver
            XRI     $7C         ;Check start char
            BNZ     SNDERR
            LDI     $7C         ;Send start address code
            CALL    SEROUT
            GHI     RA          ;Send start address
            CALL    SENDBYTE
            GLO     RA
            CALL    SENDBYTE
SNDNXT:     LDA     RA          ;Get next byte to send
            STR     R2          ;Show it on data display
            OUT     4
            DEC     R2
            CALL    SENDBYTE    ;Send it
            DEC     RC          ;Keep going until
            GHI     RC          ;we've sent the specified
            BNZ     SNDNXT      ;number of bytes
            GLO     RC
            BNZ     SNDNXT
            LDI     $7F
            CALL    SEROUT
            ADI     $00         ;Set DF=0 for success
            LSKP
SNDERR:     SMI     $00         ;Set DF=1 for error
            IRX
            LDX
            PLO     RB
            RETN

; **** strcpy copies string pointed to by R[F] to R[D]
            SHARED  STRCPY
STRCPY:     LDA     RF          ; get byte from source string
            STR     RD          ; store into destination
            LBZ     RETURN      ; return if copied terminator
            INC     RD          ; increment destination pointer
            BR      STRCPY      ; continue looping

; *** RC:RB = RF * RD (RB is low word)
; *** R(X) must point to suitable stack
            SHARED  MUL16
MUL16:      LDI     0           ; zero out total
            PHI     RB
            PLO     RB
            PHI     RC
            PLO     RC
            SEX     R2          ; make sure X points to stack
MULLOOP:    GLO     RD          ; get low of multiplier
            BNZ     MULCONT     ; continue multiplying if nonzero
            GHI     RD          ; check hi byte as well
            BNZ     MULCONT
            RETN                ; return to caller
MULCONT:    GHI     RD          ; shift multiplier
            SHR
            PHI     RD
            GLO     RD
            SHRC
            PLO     RD
            BNF     MULCONT2    ; loop if no addition needed
            GLO     RF          ; add F to C:B
            STR     R2
            GLO     RB
            ADD
            PLO     RB
            GHI     RF
            STR     R2
            GHI     RB
            ADC
            PHI     RB
            GLO     RC          ; carry into high word
            ADCI    0
            PLO     RC
            GHI     RC
            ADCI    0
            PHI     RC
MULCONT2:   GLO     RF          ; shift first number
            SHL
            PLO     RF
            GHI     RF
            SHLC
            PHI     RF
            BR      MULLOOP     ; loop until done

HEXTAB:     DB      $30, $00
            DB      $31, $01
            DB      $32, $02
            DB      $33, $03
            DB      $34, $04
            DB      $35, $05
            DB      $36, $06
            DB      $37, $07
            DB      $38, $08
            DB      $39, $09
            DB      $41, $0A
            DB      $42, $0B
            DB      $43, $0C
            DB      $44, $0D
            DB      $45, $0E
            DB      $46, $0F
            DB      $61, $0A
            DB      $62, $0B
            DB      $63, $0C
            DB      $64, $0D
            DB      $65, $0E
            DB      $66, $0F
            DB      $00

;------------------------------------------------------------------------
;Routine to convert an ascii hex digit to its corresponding value.
            SHARED  HEX1
HEX1:       GHI     RC          ;Save registers
            STXD
            GLO     RC
            STXD

            LOAD    RC,HEXTAB   ;Get a pointer to the hex table
            SEX     RC          ;R(X) = hex table

HEX1NXT:    LDN     RC          ;Search the hex table for the value
            BZ      NOHEX       ;$00 means we reached the end
            GLO     RB
            SM
            BZ      HEX         ;Found it in the table, go load value
            INC     RC          ;Otherwise check next table entry
            INC     RC
            BR      HEX1NXT

HEX:        INC     RC          ;Get value from table
            LDN     RC
            PLO     RB
            LDI     $00         ;Set DF=0 for valid hex
            LSKP

NOHEX:      LDI     $FF         ;Set DF=1 for invalid
            SHRC

            SEX     R2          ;Restore X

            IRX                 ;Restore registers
            LDXA
            PLO RC
            LDX
            PHI RC

            RETN

;------------------------------------------------------------------------
;Routine to output a data byte as two hex digits.
;
;RB.0 = 8-bit value to be written.
            SHARED  HEX2OUT
HEX2OUT:    GHI     RB          ;Save registers
            STXD
            GLO     RB
            STXD
            PHI     RB          ;Save a copy of input byte in RB.1
            SHR                 ;Get the high-order nybble
            SHR
            SHR
            SHR
            PLO     RB          ;Output the high digit
            CALL    HEXDIG
            GLO     RB
            CALL    CHAROUT
            GHI     RB          ;Get the original byte back
            ANI     $0F         ;Isolate the low nybble
            PLO     RB          ;Output the low digit
            CALL    HEXDIG
            GLO     RB
            CALL    CHAROUT
            IRX                 ;Restore registers
            LDXA
            PLO     RB
            LDX
            PHI     RB
            RETN

; **** Find last available memory address
; **** Returns: RF - last writable address
            SHARED  FREEMEM
FREEMEM:    LDI     000H        ; start from beginning of memory
            PHI     RF          ; place into register
            LDI     0FFH
            PLO     RF
            SEX     R2          ; be sure x points to stack
FMEMLP:     LDN     RF          ; get byte
            PLO     RE          ; save a copy
            XRI     255         ; flip the bits
            STR     RF          ; place into memory
            LDN     RF          ; retrieve from memory
            STXD                ; place into memory
            IRX                 ; point to previous value
            GLO     RE
            SM                  ; and compare
            BZ      FMEMDN      ; jump if not different
            GLO     RE          ; recover byte
            STR     RF          ; write back into memory
            GHI     RF
            ADI     1
            PHI     RF
            BNZ     FMEMLP
FMEMDN:     GHI     RF          ; point back to last writable memory
            SMI     1
            PHI     RF
            RETN                ; and return to caller

; **********************************
; *** check D if hex             ***
; *** Returns DF=1 - hex         ***
; ***         DF=0 - non-hex     ***
; **********************************
            SHARED  ISHEX
ISHEX:      CALL    ISNUM       ; see if it is numeric
            PLO     RE          ; keep a copy
            LBDF    PASSES      ; jump if it is numeric
            SMI     'A'         ; check for below uppercase a
            LBNF    FAILS       ; value is not hex
            SMI     6           ; check for less then 'G'
            LBNF    PASSES      ; jump if so
            GLO     RE          ; recover value
            SMI     'A'         ; check for lowercase a
            LBNF    FAILS       ; jump if not
            SMI     6           ; check for less than 'g'
            LBNF    PASSES      ; jump if so
            LBR     FAILS

; **** Strcmp compares the strings pointing to by R(D) and R(F)
; **** Returns:
; ****    R(F) = R(D)     0
; ****    R(F) < R(D)     -1 (255)
; ****    R(F) > R(D)     1
            SHARED  STRCMP
STRCMP:     LDA     RD          ; get next byte in string
            ANI     0FFH        ; check for zero
            BZ      STRCMPE     ; found end of first string
            STXD                ; store into memory
            IRX
            LDA     RF          ; get byte from first string
            SM                  ; subtract 2nd byte from it
            BZ      STRCMP      ; so far a match, keep looking
            BNF     STRCMP1     ; jump if first string is smaller
            LDI     1           ; indicate first string is larger
            LSKP                ; and return to caller
STRCMP1:    LDI     255         ; return -1, first string is smaller
            RETN                ; return to calelr
STRCMPE:    LDA     RF          ; get byte from second string
            BZ      STRCMPM     ; jump if also zero
            LDI     1           ; first string is smaller (returns -1)
            RETN                ; return to caller
STRCMPM:    LDI     0           ; strings are a match
RETURN:     RETN                ; return to caller

;------------------------------------------------------------------------
;Routine to read a string from the serial port.
;Pointer to buffer and buffer size passed as parameters.
            SHARED  READLN
READLN:     PUSH    RF          ;Save registers.
            PUSH    RC
            LDA     R6          ;Get pointer to buffer.
            PHI     RF
            LDA     R6
            PLO     RF
            LDI     $00
            PHI     RC
            LDA     R6          ;Get size of buffer
            PLO     RC          ;Save it in RC.
            CALL    INPUT
            POP     RC
            POP     RF
            RETN


;------------------------------------------------------------------------
;Routine to convert the low nybble of RB to an ascii hex digit.
            SHARED  HEXDIG
HEXDIG:     GHI     RC          ;Save registers
            STXD
            GLO     RC
            STXD

            LOAD    RC,HEXTAB   ;Point to the start of the hex table
            GLO     RB
            ANI     $0F         ;Isolate the low nybble
            SHL                 ;Multiply by 2
            STR     R2
            GLO     RC          ;Add to hex table pointer
            ADD
            PLO     RC
            LDN     RC          ;Get ascii value from table
            PLO     RB

            IRX                 ;Restore registers
            LDXA
            PLO RC
            LDX
            PHI RC

            RETN

; ********************************
; *** See if D is alphabetic   ***
; *** Returns DF=0 - not alpha ***
; ***         DF=1 - is alpha  ***
; ********************************
            SHARED  ISALPHA
ISALPHA:    PLO     RE          ; save copy of do
            SMI     'A'         ; check uc letters
            LBNF    FAILS       ; jump if below A
            SMI     27          ; check upper range
            LBNF    PASSES      ; jump if valid
            GLO     RE          ; recover character
            SMI     'A'         ; check lc letters
            LBNF    FAILS       ; jump if below A
            SMI     27          ; check upper range
            LBNF    PASSES      ; jump if valid
            LBR     FAILS

;------------------------------------------------------------------------
;Routine to send a single byte in MAX format.
;
;On entry:
;  Data byte in D
;
SENDBYTE:   PLO     RB
            ANI     $FC         ;Is it a special character ($7D-$7f)
            XRI     $7C         ;If so, escape it
            BZ      SNDSPEC
            GLO     RB
            CALL    SEROUT      ;If not, output raw byte
            BR      SNDRET
SNDSPEC:    LDI     $7D         ;Send escape code
            CALL    SEROUT
            GLO     RB          ;XOR next byte with $20
            XRI     $20
            CALL    SEROUT      ;and send it
SNDRET:
            RETN

            SHARED  SETINPUT
SETINPUT:   PUSH    RA
            RLDI    RA,CHARIN
            LDI     $C0         ; Save CHARIN vector
            STR     RA
            INC     RA
            GHI     RD
            STR     RA
            INC     RA
            GLO     RD
            STR     RA
            POP     RA
            RETN

            SHARED  SETOUTPUT
SETOUTPUT:  PUSH    RA
            RLDI    RA,CHAROUT
            LDI     $C0         ; Save CHAROUT vector
            STR     RA
            INC     RA
            GHI     RD
            STR     RA
            INC     RA
            GLO     RD
            STR     RA
            POP     RA
            RETN

;------------------------------------------------------------------------
;This routine can be used to initialize the SCRT/BIOS interface at the
;start of a program. It assumes the PC starts as R0. Place the address
;of this routine into any register and do a SEP to that register,
;followed by the initial value for the stack pointer, e.g:
;
;           LDI HIGH SCINIT
;           PHI RF
;           LDI LOW SCINIT
;           PLO RF
;           SEP RF
;           DW  STACKPTR
; START:    ;Control will return here with R3 = PC,
;           ;R4 = stdcall, R5 = stdret, R2 = stack ptr,
;           ;P = 3, X = 2
;
            SHARED SCINIT
SCINIT:     SEX     R0          ;Point to location of init
            LDXA                ;stack pointer and copy
            PHI     R2          ;to R2
            LDXA
            PLO     R2
            SEX     R2          ;Set stack pointer
            RLDI    R4,SCALL    ;Set R4 = SCRT call
            RLDI    R5,SRET     ;Set R5 = SCRT return
            RLD     R3,R0       ;Copy old PC to R3
            SEP     3           ;return with R3 as PC

;------------------------------------------------------------------------
;Routine that repeats a character a specified number of times to
;the serial port.
;The first parameter byte specifies the number of characters.
;The second byte specifies the character to be written.
            SHARED  TYPERPT
TYPERPT:    GHI     RF          ;Save RF to the stack.
            STXD
            GLO     RF
            STXD
            LDA     R6          ;Get the character count
            PLO     RF
            LDA     R6          ;Get the character to be repeated
            PHI     RF
TRNXT:      GHI     RF          ;Get the character
            CALL    CHAROUT      ;Write it to serial port
            DEC     RF
            GLO     RF
            BNZ     TRNXT       ;If not done, do it again.
            IRX                 ;Restore registers
            LDXA
            PLO     RF
            LDX
            PHI     RF
            RETN

; *************************************
; *** Check if character is numeric ***
; *** D - char to check             ***
; *** Returns DF=1 if numeric       ***
; ***         DF=0 if not           ***
; *************************************
            SHARED  ISNUM
ISNUM:      PLO     RE          ; save a copy
            SMI     '0'         ; check for below zero
            BNF     FAILS       ; jump if below
            SMI     10          ; see if above
            BDF     FAILS       ; fails if so
PASSES:     SMI     0           ; signal success
            LSKP
FAILS:      ADI     0           ; signal failure
            GLO     RE          ; recover character
            RETN                ; and return

ERR:        SMI     0           ; signal an error
            RETN                ; and return

;------------------------------------------------------------------------
;This is an implementation of the call and return
;routines for the Standard Call and Return
;Technique (SCRT), as described in the User Manual
;for the CDP1802 COSMAC Microprocessor (MPM-201A).
;RE.0 is used to preserve the contents of D.
EXITA:      SEP     R3          ;R3 is pointing to the first
                                ;instruction in subroutine.
SCALL:      PLO     RE          ;Save D.
            SEX     R2          ;Point to stack.
            GHI     R6          ;Push R6 onto stack to
            STXD                ;prepare it for pointing
            GLO     R6          ;to arguments, and decrement
            STXD                ;to free location.
            RLD     R6,R3       ;Copy R3 into R6
            LDA     R6          ;Load the address of subroutine
            PHI     R3          ;into R3.
            LDA     R6
            PLO     R3
            GLO     RE          ;Restore D.
            BR      EXITA       ;Branch to entry point of CALL
                                ;minus one byte. This leaves R4
                                ;pointing to SCALL, allowing for
                                ;repeated calls.

; *****************************************
; *** See if D is alphanumeric          ***
; *** Returns: DF=0 - not valid         ***
; ***          DF=1 - is valid          ***
; *****************************************
            SHARED  ISALNUM
ISALNUM:    PLO     RE          ; keep copy of D
            CALL    ISNUM       ; check if numeric
            LBDF    PASSES      ; jump if numeric
            CALL    ISALPHA     ; check for alpha
            LBDF    PASSES      ; jump if alpha
            LBR     FAILS       ; otherwise fails

            PAGE

;------------------------------------------------------------------------
;Routine to output a data word as four hex digits.
;
;RD = 16-bit value to be written
            SHARED  HEX4OUT
HEX4OUT:    GLO     RB
            STXD
            GHI     RD
            PLO     RB
            CALL    HEX2OUT
            GLO     RD
            PLO     RB
            CALL    HEX2OUT
            IRX
            LDX
            PLO     RB
            RETN

;------------------------------------------------------------------------
;Routine that types a number of characters to the serial port.
;The first parameter is a byte containing the number of
;characters. Subsequent parameter bytes contain the characters
;to be written.
            SHARED  TYPECNT
TYPECNT:    GLO     RF          ;Save RF.0
            STXD
            LDA     R6          ;Get the count
            PLO     RF          ;and put it in RF.0
TCNXT:      LDA     R6          ;Get next character
            CALL    CHAROUT      ;Write it to serial port
            DEC     RF
            GLO     RF
            BNZ     TCNXT       ;If not done, goto next
            IRX                 ;Restore registers
            LDX
            PLO     RF
            RETN

EXITR:      SEP     R3          ;Return to "MAIN" program.

SRET:       PLO     RE          ;Save D.
            RLD     R3,R6       ;Copy R6 into R3
            SEX     2           ;Point to stack.
            IRX                 ;Point to saved old R6
            LDXA                ;Restore the contents
            PLO     R6          ;of R6.
            LDX
            PHI     R6
            GLO     RE          ;Restore D.
            BR      EXITR       ;Branch to entry point of SRET
                                ;minus one byte. This leaves R5
                                ;pointing to SRET for
                                ;following repeated calls.

            SHARED  INITCALL
INITCALL:   RLDI    R4,SCALL
            RLDI    R5,SRET
            DEC     R2
            DEC     R2
            RETN

; **** ltrim trims leading white space from string pointed to by R[F]
; **** Returns:
; ****    R(F) pointing to non-whitespace portion of string
            SHARED  LTRIM
LTRIM:      LDN     RF          ; get next byte from string
            LBZ     RETURN      ; return if at end of string
            SMI     ' '+1       ; looking for anthing <= space
            LBDF    RETURN      ; found first non white-space
            INC     RF          ; point to next character
            BR      LTRIM       ; keep looking

; **** strlen puts the length of string pointed to by R[F] in R[D]
            SHARED  STRLEN
STRLEN:     LDI     $00
            PHI     RD
            PLO     RD
.NEXT:      LDA     RF
            BZ      .DONE
            INC     RD
            BR      .NEXT
.DONE       RETN

NUMBERS:    DB      027H,010H,3,0E8H,0,100,0,10,0,1

            SHARED  INPUT256
INPUT256:   LDI     1           ; allow 256 input bytes
            PHI     RC
            LDI     0
            PLO     RC
            LBR     INPUT

;------------------------------------------------------------------------
;Routine to type a string, passed as a parameter, to the serial port.
;The string is terminated with a 0 byte.
            SHARED  TYPE
TYPE:       LDA     R6          ;Get next character from parameter.
            BZ      TPRTN
            CALL    CHAROUT
            BR      TYPE
TPRTN:      RETN

;------------------------------------------------------------------------
;Routine to type a string, passed as a pointer in RF, to the serial port.
            SHARED  TYPEBUF
TYPEBUF:    LDA     RF          ;Get next character from buffer.
            BZ      TBRTN
            CALL    CHAROUT
            BR      TYPEBUF
TBRTN:      RETN

; ***********************************
; *** Check for symbol terminator ***
; *** Returns: DF=1 - terminator  ***
; ***********************************
            SHARED  ISTERM
ISTERM:     CALL    ISALNUM     ; see if alphanumeric
            LBDF    FAILS       ; fails if so
            LBR     PASSES

;------------------------------------------------------------------------
;Routine to skip whitespace in the input buffer.
            SHARED  SKIPWS
SKIPWS:     LDA     RF
            XRI     $20
            BZ      SKIPWS
            DEC     RF
            RETN

            END
