; MAX Monitor program
;
; Simple monitor for 1802-based systems.
;
; This monitor makes use of the MAX BIOS for I/O, as well
; as to set up the RCA SCRT system for subroutine calls.
;
            INCL "1802.inc"
            INCL "max_bios.inc"

M_BPL       EQU     8
SCRATCH     EQU     $BF00

            ORG $8000

            LDI HIGH SCINIT ; Initialize SCRT
            PHI RF          ; and the stack
            LDI LOW SCINIT
            PLO RF
            SEP RF
            DW  STKPTR

            CALL TYPE
            TEXT "\rMAX Monitor V1.0\r\n\0"

PROMPT:     CALL TYPE
            TEXT "> \0"

            CALL READLN
            DW BUFFER
            DB (BUFEND-BUFFER)

            CALL TYPE
            TEXT "\r\n\0"

            LOAD RF, BUFFER

            CALL SKIPWS     ; Skip leading spaces
            LDA RF
            BZ  PROMPT      ; Reached end-of-line
            ANI $DF         ; Decode command
            SMI $44
            LBZ D_CMD
            SMI $04
            LBZ H_CMD
            SMI $04
            LBZ L_CMD
            SMI $01
            LBZ M_CMD
            SMI $05
            LBZ R_CMD
            SMI $01
            LBZ S_CMD
            SMI $01
            LBZ T_CMD
            SMI $02
            LBZ V_CMD
            SMI $01
            LBZ W_CMD
            CALL TYPE
            TEXT "Bad command.\r\n\0"
            BR  PROMPT

D_CMD:      LBR PROMPT      ;Placeholder for 'D' command

H_CMD:      CALL TYPE
            TEXT "Commands:\r\n"
            TEXT "(M)EMORY, (W)RITE\r\n"
            TEXT "(T)RANSFER, (V)IEW\r\n"
            TEXT "(L)OAD, (S)AVE\r\n\0"
            LBR PROMPT

L_CMD:      CALL SKIPWS
            LDN RF
            LBNZ BAD_PARM   ;There should be no parameters
            CALL TYPE
            TEXT "Start send...\0"
            CALL LOADBIN
            CALL TYPE
            TEXT "Done.\r\n\0"
            LBR PROMPT

            PAGE

M_CMD:      CALL SKIPWS
            LDN RF          ;If no params,
            BZ  M_CONT      ;repeat last command
            CALL GETHEX     ;Get the start address
            DB  $04
            LBDF BAD_PARM
            GHI RD          ;Store in R7
            PHI R7
            GLO RD
            PLO R7
            CALL SKIPWS
            CALL GETHEX     ;Get the length
            DB  $04
            LBDF BAD_PARM
            GHI RD          ;Store in R8
            PHI R8
            GLO RD
            PLO R8
            CALL SKIPWS
            LDN RF          ;Check for extra
            LBNZ BAD_PARM   ;parameters
M_CONT:     GHI R8          ;Copy the byte count
            PHI R9          ;from R8 to R9
            GLO R8
            PLO R9
M_LOOP:     GHI R9          ;Check if there are          
            BNZ M_FULL      ;more than a single
            GLO R9          ;line of bytes remaining
            BZ  M_DONE      ;Done if no bytes remaining
            SMI M_BPL
            BGE M_FULL
            XRI $FF         ;Less than a full line
            ADI $01
            PHI RA          ;Keep the difference in RA.1
            GLO R9          ;Set number of bytes to
            PLO RA          ;remaining, or to
            BR  M_LINE
M_FULL:     LDI M_BPL       ;the number of bytes per line
            PLO RA
            LDI $00
            PHI RA
M_LINE:     LOAD RF, BUFFER ;Set buffer pointer for ASCII
            LDI $20         ;Store leading space
            STR RF
            INC RF
            GHI R7          ;Print the address of the line
            PHI RD
            GLO R7
            PLO RD
            CALL HEX4OUT
M_BYTE:     CALL TYPE       ;Space before next byte
            DB  $20, $00
            LDA R7          ;Print next byte
            PLO RB
            CALL HEX2OUT
            CALL SAVECHR    ;Save ASCII in buffer
            DEC R9          ;Decrement total count
            DEC RA          ;Loop for the number of
            GLO RA          ;bytes on the line
            BNZ M_BYTE
            GHI RA          ;Pad bytes necessary?
            BZ  M_EOL
            PLO RA
M_FILL:     CALL TYPE
            DB  $20, $20, $20, $00
            DEC RA
            GLO RA
            BNZ M_FILL
M_EOL:      LDI $00
            STR RF
            LOAD RF, BUFFER
            CALL TYPEBUF
            CALL TYPE
            DB  $0D, $0A, $00
            BR  M_LOOP
M_DONE:     LBR PROMPT

SAVECHR:    GLO RB
            SMI $20
            BL NOTPRT
            GLO RB
            SMI $7E
            BGE NOTPRT
            GLO RB
            LSKP
NOTPRT:     LDI $2E
            STR RF
            INC RF
            RETN

R_CMD:      CALL SKIPWS
            CALL GETHEX
            DB $04
            LBDF BAD_PARM
            CALL SKIPWS
            LDN RF
            LBNZ BAD_PARM
            GHI RD
            PHI R0
            GLO RD
            PLO R0
            SEP 0
            LBR PROMPT      ;Should never get here

            PAGE

S_CMD:      CALL SKIPWS
            CALL GETHEX
            DB $04
            LBDF BAD_PARM
            GHI RD
            PHI R7
            GLO RD
            PLO R7
            CALL SKIPWS
            CALL GETHEX
            DB $04
            LBDF BAD_PARM
            CALL SKIPWS
            LDN RF
            LBNZ BAD_PARM
            GHI RD
            PHI R8
            GLO RD
            PLO R8
            CALL TYPE
            TEXT "Start receive...\r\n\0"
            CALL SAVEBIN
            BNF S_RET
            CALL TYPE
            TEXT "Save error.\r\n\0"
S_RET:      LBR PROMPT

T_CMD:      CALL SKIPWS
            CALL GETHEX
            DB $04
            LBDF BAD_PARM
            GHI RD
            PHI R7
            GLO RD
            PLO R7
            CALL SKIPWS
            CALL GETHEX
            DB $04
            LBDF BAD_PARM
            GHI RD
            PHI R8
            GLO RD
            PLO R8
            CALL SKIPWS
            CALL GETHEX
            DB $04
            LBDF BAD_PARM
            CALL SKIPWS
            LDN RF
            LBNZ BAD_PARM
            GHI RD
            PHI R9
            GLO RD
            PLO R9
            GLO R8
            STR R2
            GLO R7
            SD
            GHI R8
            STR R2
            GHI R7
            SDB
            BL  T_FWD
T_BACK:     GLO R7          ;src += len
            STR R2
            GLO R9
            ADD
            PLO R7
            GHI R7
            STR R2
            GHI R9
            ADC
            PHI R7
            GLO R8          ;dest += len
            STR R2
            GLO R9
            ADD
            PLO R8
            GHI R8
            STR R2
            GHI R9
            ADC
            PHI R8
T_BLOOP:    DEC R7          ;dest >= src
            DEC R8          ;Copy src to
            LDN R7          ;dest starting
            STR R8          ;from end of src
            DEC R9
            GHI R9
            BNZ T_BLOOP
            GLO R9
            BNZ T_BLOOP
            BR  T_DONE
T_FWD:      LDN R7          ;dest < src
            STR R8          ;Copy src to
            INC R7          ;dest starting from
            INC R8          ;beginning of src
            DEC R9
            GHI R9
            BNZ T_FWD
            GLO R9
            BNZ T_FWD
T_DONE:     LBR PROMPT

V_CMD:      LBR PROMPT      ;Placeholder for 'V' command

            PAGE

W_CMD:      CALL SKIPWS
            CALL GETHEX     ;Get the address for writing
            DB $04
            LBDF BAD_PARM
            GHI RD          ;Store it in R7
            PHI R7
            GLO RD
            PLO R7
W_NEXT:     CALL SKIPWS     ;Look for hex byte
            CALL GETHEX
            DB $02
            BNF W_STORE     ;If we got one, store it
            LDN RF          ;End of line?
            BZ  W_END
            XRI $22         ;Start of string?
            LBNZ  BAD_PARM  ;Neither, bad parameter
            INC RF
            BR  W_STRING
W_STORE:    GLO RD
            STR R7
            INC R7
            BR  W_NEXT
W_STRING:   LDN RF          ;Get next char of string
            BZ  W_END       ;End of line?
            XRI $22         ;Ending quote
            BNZ W_STR       ;No, store character
            INC RF          ;Yes, skip the '"'
            BR W_NEXT       ;and look for more input
W_STR:      LDN RF
            STR R7
            INC R7
            INC RF
            BR  W_STRING
W_END:      CALL SKIPWS
            LDN RF
            LBNZ BAD_PARM
            LBR PROMPT

BAD_PARM:   CALL TYPE
            TEXT "Bad parameter: '\0"
            CALL TYPEBUF
            CALL TYPE
            TEXT "'\r\n\0"
            LBR PROMPT

            ORG SCRATCH

; Define a buffer to hold user input line.
BUFFER:     DS  80
BUFEND:     EQU $

; Define the stack.
STACK:      DS  256 - 80
STKPTR:     EQU $ - 1

            END
