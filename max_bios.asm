            INCL    "1802.inc"

RXINV       EQU     1
TXINV       EQU     0
ECHO        EQU     1

STATE       EQU     RC
DEST        EQU     RD
SRC         EQU     RD

            ORG $8400

;------------------------------------------------------------------------
;Routine to output a data byte as two hex digits.
            SHARED HEX2OUT
HEX2OUT:    GHI RB          ;Save registers
            STXD
            GLO RB
            STXD
            PHI RB          ;Save a copy of input byte in RB.1
            SHR             ;Get the high-order nybble
            SHR
            SHR
            SHR
            PLO RB          ;Output the high digit
            CALL HEXDIG
            CALL SEROUT
            GHI RB          ;Get the original byte back
            ANI $0F         ;Isolate the low nybble
            PLO RB          ;Output the low digit
            CALL HEXDIG
            CALL SEROUT
            IRX             ;Restore registers
            LDXA
            PLO RB
            LDX
            PHI RB
            RETN

;------------------------------------------------------------------------
;Routine to output a data word as four hex digits.
;
;RD = 16-bit value to be written
            SHARED HEX4OUT
HEX4OUT:    GLO RB
            STXD
            GHI RD
            PLO RB
            CALL HEX2OUT
            GLO RD
            PLO RB
            CALL HEX2OUT
            IRX
            LDX
            PLO RB
            RETN

;------------------------------------------------------------------------
;Routine to convert the low nybble of RB to an ascii hex digit.
HEXDIG:     GHI RC          ;Save registers
            STXD
            GLO RC
            STXD

            LOAD RC, HEXTAB ;Point to the start of the hex table
            GLO RB
            ANI $0F         ;Isolate the low nybble
            SHL             ;Multiply by 2
            STR R2
            GLO RC          ;Add to hex table pointer
            ADD
            PLO RC
            LDN RC          ;Get ascii value from table
            PLO RB

            IRX             ;Restore registers
            LDXA
            PLO RC
            LDX
            PHI RC

            RETN

;------------------------------------------------------------------------
;Routine to convert an ascii hex digit to its corresponding value.
            SHARED HEX1
HEX1:       GHI RC          ;Save registers
            STXD
            GLO RC
            STXD

            LOAD RC, HEXTAB ;Get a pointer to the hex table
            SEX RC          ;R(X) = hex table

HEX1NXT:    LDN RC          ;Search the hex table for the value
            BZ  NOHEX       ;$00 means we reached the end
            GLO RB
            SM
            BZ  ISHEX       ;Found it in the table, go load value
            INC RC          ;Otherwise check next table entry
            INC RC
            BR  HEX1NXT

ISHEX:      INC RC          ;Get value from table
            LDN RC
            PLO RB
            LDI $00         ;Set DF=0 for valid hex
            LSKP

NOHEX:      LDI $FF         ;Set DF=1 for invalid
            SHRC

            SEX R2          ;Restore X

            IRX             ;Restore registers
            LDXA
            PLO RC
            LDX
            PHI RC

            RETN

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
            SHARED GETHEX
GETHEX:     GLO RE          ;Save registers
            STXD
            GLO RB
            STXD

            LDA R6
            PLO RE
            DEC RE

            LDN RF          ;Get next character
            PLO RB
            CALL HEX1       ;Translate ascii to value
            BDF HEX2RET     ;If not valid, return with DF=1
            GLO RB
            PLO RD
            LDI $00
            PHI RD
HEXNXT:     INC RF
            LDN RF
            BZ  HEXTRM
            PLO RB
            CALL HEX1
            BDF HEXTRM
            CALL SHLD
            DB $04
            GLO RB
            STR R2
            GLO RD
            OR
            PLO RD
            DEC RE
            GLO RE
            BNZ HEXNXT
            INC RF          ;Point to next char
HEXTRM:     ADI $00         ;Clear DF
HEX2RET:    IRX             ;Restore registers
            LDXA
            PLO RB
            LDX
            PLO RE

            RETN

SHLD:       GLO RE
            STXD
            LDA R6
            PLO RE
DSHFT:      GLO RD
            SHL
            PLO RD
            GHI RD
            SHLC
            PHI RD
            DEC RE
            GLO RE
            BNZ DSHFT
            IRX
            LDX
            PLO RE
            RETN

HEXTAB:     DB  $30, $00
            DB  $31, $01
            DB  $32, $02
            DB  $33, $03
            DB  $34, $04
            DB  $35, $05
            DB  $36, $06
            DB  $37, $07
            DB  $38, $08
            DB  $39, $09
            DB  $41, $0A
            DB  $42, $0B
            DB  $43, $0C
            DB  $44, $0D
            DB  $45, $0E
            DB  $46, $0F
            DB  $61, $0A
            DB  $62, $0B
            DB  $63, $0C
            DB  $64, $0D
            DB  $65, $0E
            DB  $66, $0F
            DB  $00

;------------------------------------------------------------------------
;Routine to type a string, passed as a pointer in RF, to the serial port.
            SHARED TYPEBUF
TYPEBUF:    GHI RF          ;Push RF onto the stack.
            STXD
            GLO RF
            STXD
            GLO RB          ;Save RB.0
            STXD
            GLO RE          ;Save RE.0
            STXD
TBNXT:      LDA RF          ;Get next character from buffer.
            BZ  TBRTN
            PLO RB
            CALL SEROUT
            BR  TBNXT
TBRTN:      IRX
            LDXA
            PLO RE
            LDXA
            PLO RB
            LDXA
            PLO RF
            LDX
            PHI RF
            RETN

            PAGE

;------------------------------------------------------------------------
;Routine to load a binary file from the serial port.
            SHARED LOADBIN
LOADBIN:    GLO RB          ;Save registers used by
            STXD            ;binary loader.
            GLO RE
            STXD
            GHI STATE
            STXD
            GLO STATE
            STXD
            GHI DEST
            STXD
            GLO DEST
            STXD
            LDI $0
            PHI DEST
            PLO DEST
            PLO STATE
LDNEXT:     CALL SERIN
            GLO RB
            PHI STATE       ;Save a copy
            STR R2          ;Display it on the data display
            OUT 4
            DEC R2
            GLO STATE       ;Implement state machine
            BZ  STATE0
            SMI $01
            BZ  STATE1
            SMI $01
            BZ  STATE2
            SMI $01
            BZ  STATE3
            SMI $01
            BZ  STATE4
            SMI $01
            BZ  STATE5
            LDI $00
            PLO STATE
            BR  LDNEXT
STATE0:     GHI STATE       ;State 0 - Check if the byte is
            ANI $FC         ;a special character ($7C-$7f)
            XRI $7C         ;If it is, process it
            BZ  SPECIAL
            GHI STATE       ;If not, copy it to destination
            STR DEST        ;memory address
            INC DEST        ;Update destination address
            BR  LDNEXT
STATE1:     GHI STATE       ;State 1 - Load new high
            PHI DEST        ;destination address
            LDI $02         ;Go to state 2
            PLO STATE
            BR  LDNEXT
STATE2:     GHI STATE       ;State 2 - Load new low
            PLO DEST        ;destination address
            LDI $00         ;Return to state 0
            PLO STATE
            BR  LDNEXT
STATE3:     GHI STATE       ;State 3 - process escape
            XRI $20         ;character by XORing next
            STR DEST        ;byte with 0x20 before
            INC DEST        ;storing
            LDI $00         ;Return to state 0
            PLO STATE
            BR  LDNEXT
STATE4:     GHI STATE       ;State 4 - Load high run
            PHI R0          ;address
            LDI $05         ;Go to state 5
            PLO STATE
            BR  LDNEXT
STATE5:     GHI STATE       ;State 5 - Load low run
            PLO R0          ;address and start program
            SEP R0          ;with PC=R0
SPECIAL:    GHI STATE       ;Process special character
            ANI $03
            BZ  NEWADDR     ;$7C - new dest. address
            SMI $01
            BZ  ESCAPE      ;$7D - escape next byte
            SMI $01
            BZ  RUNADDR     ;$7E - run address
            BR  LDRETN      ;$7F - end of file
NEWADDR:    LDI $01         ;Go to state 1
            PLO STATE
            BR  LDNEXT
ESCAPE:     LDI $03         ;Go to state 3
            PLO STATE
            BR  LDNEXT
RUNADDR:    LDI $04         ;Go to state 4
            PLO STATE
            BR  LDNEXT
LDRETN:     IRX             ;Restore registers
            LDXA
            PLO DEST
            LDXA
            PHI DEST
            LDXA
            PLO STATE
            LDXA
            PHI STATE
            LDXA
            PLO RE
            LDX
            PLO RB
            RETN

;------------------------------------------------------------------------
;Routine to send a single byte in MAX format.
;
;On entry:
;  Data byte in D and saved in RB.0
;
SENDBYTE:   ANI $FC         ;Is it a special character ($7D-$7f)
            XRI $7C         ;If so, escape it
            BZ  SNDSPEC
            CALL SEROUT     ;If not, output raw byte
            BR  SNDRET
SNDSPEC:    LDI $7D         ;Send escape code
            CALL SEROUT
            GLO RB          ;XOR next byte with $20
            XRI $20
            PLO RB
            CALL SEROUT     ;and send it
SNDRET:
            RETN

;------------------------------------------------------------------------
;Routine to save a binary file in MAX format.
;
;On entry:
;  R7 = start address of saved data
;  R8 = end address of saved data
;
            SHARED SAVEBIN
SAVEBIN:    GHI R9          ;Save registers
            STXD
            GLO R9
            STXD
            GLO RB
            STXD
            GLO R7          ;Calculate length
            STR R2          ;of transfer
            GLO R8          ;R9 = end - start + 1
            SM
            PLO R9
            GHI R7
            STR R2
            GHI R8
            SMB
            PHI R9
            BL  SNDERR      ;end < start
            INC R9
            CALL SERIN      ;Wait for receiver
            GLO RB
            XRI $7C         ;Check start char
            BNZ SNDERR
            LDI $7C         ;Send start address code
            PLO RB
            CALL SEROUT
            GHI R7          ;Send start address
            PLO RB
            CALL SENDBYTE
            GLO R7
            PLO RB
            CALL SENDBYTE
SNDNXT:     LDA R7          ;Get next byte to send
            STR R2          ;Show it on data display
            OUT 4
            DEC R2
            PLO RB
            CALL SENDBYTE   ;Send it
            DEC R9          ;Keep going until
            GHI R9          ;we've sent the specified
            BNZ SNDNXT      ;number of bytes
            GLO R9
            BNZ SNDNXT
            LDI $7F
            PLO RB
            CALL SEROUT
            LDI $00         ;Set DF=0 for success
            LSKP
SNDERR:     LDI $FF         ;Set DF=1 for error
            SHRC
            IRX             ;Restore registers
            LDXA
            PLO RB
            LDXA
            PLO R9
            LDX
            PHI R9
            RETN

;------------------------------------------------------------------------
;Routine to skip whitespace in the input buffer.
            SHARED SKIPWS
SKIPWS:     LDA RF
            XRI $20
            BZ  SKIPWS
            DEC RF
            RETN

            PAGE

;------------------------------------------------------------------------
;This is an implementation of the call and return
;routines for the Standard Call and Return
;Technique (SCRT), as described in the User Manual
;for the CDP1802 COSMAC Microprocessor (MPM-201A).
EXITA:      SEP R3          ;R3 is pointing to the first
                            ;instruction in subroutine.
SCALL:      SEX R2          ;Point to stack.
            GHI R6          ;Push R6 onto stack to
            STXD            ;prepare it for pointing
            GLO R6          ;to arguments, and decrement
            STXD            ;to free location.
            GHI R3          ;Copy R3 into R6 to
            PHI R6          ;save the return address.
            GLO R3
            PLO R6
            LDA R6          ;Load the address of subroutine
            PHI R3          ;into R3.
            LDA R6
            PLO R3
            BR  EXITA       ;Branch to entry point of CALL
                            ;minus one byte. This leaves R4
                            ;pointing to CALL, allowing for
                            ;repeated calls.

EXITR:      SEP R3          ;Return to "MAIN" program.

SRET:       GHI R6          ;Copy R6 into R3
            PHI R3          ;R3 contains the return
            GLO R6          ;address
            PLO R3
            SEX 2           ;Point to stack.
            IRX             ;Point to saved old R6
            LDXA            ;Restore the contents
            PLO R6          ;of R6.
            LDX
            PHI R6
            BR  EXITR       ;Branch to entry point of RETPGM
                            ;minus one byte. This leaves R5
                            ;pointing to RETPGM for
                            ;following repeated calls.

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
SCINIT:     SEX R0          ;Point to location of init
            LDXA            ;stack pointer and copy
            PHI R2          ;to R2
            LDXA
            PLO R2
            SEX R2          ;Set stack pointer
            LDI HIGH SCALL  ;Set R4 = SCRT call
            PHI R4
            LDI LOW SCALL
            PLO R4
            LDI HIGH SRET   ;Set R5 = SCRT return
            PHI R5
            LDI LOW SRET
            PLO R5
            GHI R0          ;Copy old PC to R3
            PHI R3
            GLO R0
            PLO R3
            SEP 3           ;return with R3 as PC

;------------------------------------------------------------------------
;Routine that types a number of characters to the serial port.
;The first parameter is a byte containing the number of
;characters. Subsequent parameter bytes contain the characters
;to be written.
            SHARED TYPECNT
TYPECNT:    GLO RF          ;Save RF.0
            STXD
            GLO RB          ;Save RB.0
            STXD
            GLO RE          ;Save RE.0
            STXD
            LDA R6          ;Get the count
            PLO RF          ;and put it in RF.0
TCNXT:      LDA R6          ;Get next character
            PLO RB
            CALL SEROUT     ;Write it to serial port
            DEC RF
            GLO RF
            BNZ TCNXT       ;If not done, goto next
            IRX             ;Restore registers
            LDXA
            PLO RE
            LDXA
            PLO RB
            LDX
            PLO RF
            RETN

;------------------------------------------------------------------------
;Routine that repeats a character a specified number of times to
;the serial port.
;The first parameter byte specifies the number of characters.
;The second byte specifies the character to be written.
            SHARED TYPERPT
TYPERPT:    GHI RF          ;Save RF to the stack.
            STXD
            GLO RF
            STXD
            GLO RB          ;Save RB.0
            STXD
            GLO RE          ;Save RE.0
            STXD
            LDA R6          ;Get the character count
            PLO RF
            LDA R6          ;Get the character to be repeated
            PHI RF
TRNXT:      GHI RF          ;Get the character
            PLO RB
            CALL SEROUT     ;Write it to serial port
            DEC RF
            GLO RF
            BNZ TRNXT       ;If not done, do it again.
            IRX             ;Restore registers
            LDXA
            PLO RE
            LDXA
            PLO RB
            LDXA
            PLO RF
            LDX
            PHI RF
            RETN

;------------------------------------------------------------------------
;Routine to type a string, passed as a parameter, to the serial port.
;The string is terminated with a 0 byte.
            SHARED TYPE
TYPE:       GLO RB          ;Save RB.0
            STXD
            GLO RE          ;Save RE.0
            STXD
TPNXT:      LDA R6          ;Get next character from parameter.
            BZ  TPRTN
            PLO RB
            CALL SEROUT
            BR  TPNXT
TPRTN:
            IRX             ;Restore registers
            LDXA
            PLO RE
            LDX
            PLO RB
            RETN

;------------------------------------------------------------------------
;Routine to read a string from the serial port.
;Pointer to buffer passed as parameter.
;On output, RD.0 = number of chars read
            SHARED READLN
READLN:     GHI RF          ;Push RF onto the stack.
            STXD
            GLO RF
            STXD
            GHI RD          ;Save RD
            STXD
            GLO RD
            STXD
            GLO RB          ;Save RB.0
            STXD
            LDA R6          ;Get pointer to buffer.
            PHI RF
            LDA R6
            PLO RF
            LDA R6          ;Get size of buffer
            PHI RD          ;Save it in RD.1 and RD.0
            PLO RD
RDNXT:      CALL SERIN      ;Get input character.
            GLO RB
            XRI $08         ;Is it backspace?
            BZ  RDBSP
            GLO RB          ;If not, save char in buffer.
            XRI $0D         ;Is it CR?
            BZ  RDDONE      ;If yes, then we're done.
            DEC RD          ;If buffer is full,
            GLO RD
            BZ  RDDONE      ;handle overflow.
            GLO RB
            STR RF
            INC RF          ;Point to next char in buffer,
            IF ECHO
            CALL SEROUT
            ENDI
            BR  RDNXT       ;and go read it.
RDBSP:      GHI RD          ;RD.1 is size of buffer
            STR RF
            SEX RF
            GLO RD          ;RD.0 is remaining chars
            SD              ;If they're equal, we're at
            SEX R2
            BZ RDNXT        ;the start of the line, so do nothing.
            LDI $08
            PLO RB          ;Send <BS><SP><BS> to
            CALL SEROUT     ;erase the character and
            LDI $20         ;move the cursor back.
            PLO RB
            CALL SEROUT
            LDI $08
            PLO RB
            CALL SEROUT
            DEC RF          ;Set the buffer back one char.
            INC RD
            BR RDNXT
RDDONE:     LDI $00         ;Terminate the string.
            STR RF
            IRX
            LDXA            ;Restore registers.
            PLO RB
            LDXA
            PLO RD
            LDXA
            PHI RD
            LDXA
            PLO RF
            LDX
            PHI RF
            RETN

            PAGE

;------------------------------------------------------------------------
;Routine to read a single character at 19200/38400 baud from serial port.
;
;The baud rate is dependent on the clock speed of the system. If the
;system clock is ~1.8MHz, the baud rate is 19200. If the system clock
;is 3.6864MHz, the baud rate is 38400.
;
;On exit, RB.0 contains the character.
SERIN:      BN3 SERIN       ;Wait for start bit.
            NOP
            NOP
            NOP
            NOP
            SEX R2
            SEX R2
SI_B0:      BN3 SI_B0_1
            ANI $7F
            LBR SI_B1
SI_B0_1:    ORI $80
            LBR SI_B1
SI_B1:      SHR
            NOP
            BN3 SI_B1_1
            ANI $7F
            LBR SI_B2
SI_B1_1:    ORI $80
            LBR SI_B2
SI_B2:      SHR
            NOP
            BN3 SI_B2_1
            ANI $7F
            LBR SI_B3
SI_B2_1:    ORI $80
            LBR SI_B3
SI_B3:      SHR
            NOP
            BN3 SI_B3_1
            ANI $7F
            LBR SI_B4
SI_B3_1:    ORI $80
            LBR SI_B4
SI_B4:      SHR
            NOP
            BN3 SI_B4_1
            ANI $7F
            LBR SI_B5
SI_B4_1:    ORI $80
            LBR SI_B5
SI_B5:      SHR
            NOP
            BN3 SI_B5_1
            ANI $7F
            LBR SI_B6
SI_B5_1:    ORI $80
            LBR SI_B6
SI_B6:      SHR
            NOP
            BN3 SI_B6_1
            ANI $7F
            LBR SI_B7
SI_B6_1:    ORI $80
            LBR SI_B7
SI_B7:      SHR
            NOP
            BN3 SI_B7_1
            ANI $7F
            LBR SI_STOP
SI_B7_1:    ORI $80
            LBR SI_STOP
SI_STOP:    NOP
            SEX R2
SI_WAIT:    B3  SI_WAIT
            PLO RB

            RETN

;------------------------------------------------------------------------
;Routine to write a single character at 19200/38400 baud to serial port.
;
;The baud rate is dependent on the clock speed of the system. If the
;system clock is ~1.8MHz, the baud rate is 19200. If the system clock
;is 3.6864MHz, the baud rate is 38400.
;
;On entry, RB.0 contains the character.
SEROUT:     GLO RB
            SEQ             ;Start bit.
            NOP
SO_B0:      SHRC
            NOP
            BDF SO_B0_1
            SEQ
            LBR  SO_B1
SO_B0_1:    REQ
            LBR  SO_B1
SO_B1:      SHRC
            NOP
            BDF SO_B1_1
            SEQ
            LBR  SO_B2
SO_B1_1:    REQ
            LBR  SO_B2
SO_B2:      SHRC
            NOP
            BDF SO_B2_1
            SEQ
            LBR  SO_B3
SO_B2_1:    REQ
            LBR  SO_B3
SO_B3:      SHRC
            NOP
            BDF SO_B3_1
            SEQ
            LBR  SO_B4
SO_B3_1:    REQ
            LBR  SO_B4
SO_B4:      SHRC
            NOP
            BDF SO_B4_1
            SEQ
            LBR  SO_B5
SO_B4_1:    REQ
            LBR  SO_B5
SO_B5:      SHRC
            NOP
            BDF SO_B5_1
            SEQ
            LBR  SO_B6
SO_B5_1:    REQ
            LBR  SO_B6
SO_B6:      SHRC
            NOP
            BDF SO_B6_1
            SEQ
            LBR  SO_B7
SO_B6_1:    REQ
            LBR  SO_B7
SO_B7:      SHRC
            NOP
            BDF SO_B7_1
            SEQ
            LBR  SO_STOP
SO_B7_1:    REQ
            LBR  SO_STOP
SO_STOP:    NOP
            SEX R2
            SEX R2
            REQ             ;Stop bit.

            RETN

            END
