; MAX Monitor program
;
; Simple monitor for 1802-based systems.
;
; This monitor makes use of the MAX BIOS for I/O, as well
; as to set up the RCA SCRT system for subroutine calls.
;
            INCL "1802.inc"
            INCL "max_bios.inc"

MAXLINE:    EQU     80
SCRATCHLEN: EQU     35

SCRATCHEND: EQU     CHARIN
SCRATCH:    EQU     SCRATCHEND - SCRATCHLEN

BUFEND:     EQU     SCRATCH
BUFFER:     EQU     BUFEND - MAXLINE

STKPTR:     EQU     BUFFER - 1

SAVED_R3:   EQU     SCRATCH + 8

BASIC3:     EQU     $9200

M_BPL:      EQU     8

            ORG     $8000

            DIS                 ; Disable interrupts
            DB      $00         ; on reset
            LBR     COLD_START

WARM_START: MARK                ; Save T
            SEX     R2
            STXD                ; Save D
            GHI     R3          ; Save R3
            STXD
            GLO     R3
            STR     R2
            RLDI    R3,.SAVE
            SEP     R3
.SAVE       ; Copy state to scratch area
            RLDI    R1,SAVED_R3
            SEX     R1
            LDA     R2
            STXD
            LDA     R2
            STXD
            RLDI    R1,SCRATCHEND - 1
            LDA     R2          ; Push D
            STXD
            LDN     R2          ; Push T
            STXD
            ; Push register contents
            GLO     RF
            STXD
            GHI     RF
            STXD
            GLO     RE
            STXD
            GHI     RE
            STXD
            GLO     RD
            STXD
            GHI     RD
            STXD
            GLO     RC
            STXD
            GHI     RC
            STXD
            GLO     RB
            STXD
            GHI     RB
            STXD
            GLO     RA
            STXD
            GHI     RA
            STXD
            GLO     R9
            STXD
            GHI     R9
            STXD
            GLO     R8
            STXD
            GHI     R8
            STXD
            GLO     R7
            STXD
            GHI     R7
            STXD
            GLO     R6
            STXD
            GHI     R6
            STXD
            GLO     R5
            STXD
            GHI     R5
            STXD
            GLO     R4
            STXD
            GHI     R4
            STXD
            DEC     R1          ; Skip R3, as it was
            DEC     R1          ; saved earlier
            GLO     R2
            STXD
            GHI     R2
            STXD
            GLO     R1
            STXD
            GHI     R1
            STXD
            GLO     R0
            STXD
            GHI     R0
            STXD
            ; Push DF state
            LDI     $00
            LSNF
            LDI     $01
            STXD

            RLDI    R0,COLD_START
            SEP     R0

DASMTBL:    LDA     R7
            ANI     $0F
            SHL
            STR     R2
            SHL
            ADD
            PLO     RA
            LDI     $00
            PHI     RA
            LDA     R6
            PHI     RF
            LDA     R6
            PLO     RF
            RADD    RF,RA
            LDA     RF
            BZ      NO_BYTES
            SMI     $01
            BZ      ONE_BYTE
            LDA     R7
            PLO     RB
            CALL    HEX2OUT
            LDI     ' '
            CALL    SEROUT
            LDN     R7
            PLO     RB
            CALL    HEX2OUT
            LDI     ' '
            CALL    SEROUT
            CALL    TYPEBUF
            CALL    TYPE
            DB      " $\0"
            DEC     R7
            LDA     R7
            PHI     RD
            LDA     R7
            PLO     RD
            CALL    HEX4OUT
            BR      TBL_DONE
NO_BYTES:   CALL    TYPE
            DB      "      \0"
            CALL    TYPEBUF
            BR      TBL_DONE
ONE_BYTE:   LDN     R7
            PLO     RB
            CALL    HEX2OUT
            CALL    TYPE
            DB      "    \0"
            CALL    TYPEBUF
            CALL    TYPE
            DB      " $\0"
            LDA     R7
            PLO     RB
            CALL    HEX2OUT
TBL_DONE:   RETN

SAVECHR:    GLO     RB
            SMI     $20
            BL      NOTPRT
            GLO     RB
            SMI     $7E
            BGE     NOTPRT
            GLO     RB
            LSKP
NOTPRT:     LDI     $2E
            STR     RF
            INC     RF
            RETN

            PAGE

M_CMD:      CALL    SKIPWS
            LDN     RF          ;If no params,
            BZ      M_CONT      ;repeat last command
            CALL    GETHEX      ;Get the start address
            DB      $04
            LBDF    BAD_PARM
            GHI     RD          ;Store in R7
            PHI     R7
            GLO     RD
            PLO     R7
            CALL    SKIPWS
            CALL    ATOI        ;Get the length
            LBDF    BAD_PARM
            GHI     RD          ;Store in R8
            PHI     R8
            GLO     RD
            PLO     R8
            CALL    SKIPWS
            LDN     RF          ;Check for extra
            LBNZ    BAD_PARM    ;parameters
M_CONT:     RLD     R9,R8       ;Copy the byte count to R9
M_LOOP:     GHI     R9          ;Check if there are
            BNZ     M_FULL      ;more than a single
            GLO     R9          ;line of bytes remaining
            LBZ     M_DONE      ;Done if no bytes remaining
            SMI     M_BPL
            BGE     M_FULL
            XRI     $FF         ;Less than a full line
            ADI     $01
            PHI     RA          ;Keep the difference in RA.1
            GLO     R9          ;Set number of bytes to
            PLO     RA          ;remaining, or to
            BR      M_LINE
M_FULL:     LDI     M_BPL       ;the number of bytes per line
            PLO     RA
            LDI     $00
            PHI     RA
M_LINE:     RLDI    RF, BUFFER  ;Set buffer pointer for ASCII
            LDI     $20         ;Store leading space
            STR     RF
            INC     RF
            GHI     R7          ;Print the address of the line
            PHI     RD
            GLO     R7
            PLO     RD
            CALL    HEX4OUT
M_BYTE:     CALL    TYPE        ;Space before next byte
            DB      $20, $00
            LDA     R7          ;Print next byte
            PLO     RB
            CALL    HEX2OUT
            CALL    SAVECHR     ;Save ASCII in buffer
            DEC     R9          ;Decrement total count
            DEC     RA          ;Loop for the number of
            GLO     RA          ;bytes on the line
            BNZ     M_BYTE
            GHI     RA          ;Pad bytes necessary?
            BZ      M_EOL
            PLO     RA
M_FILL:     CALL    TYPE
            DB      $20, $20, $20, $00
            DEC     RA
            GLO     RA
            BNZ     M_FILL
M_EOL:      LDI     $00
            STR     RF
            RLDI    RF, BUFFER
            CALL    TYPEBUF
            CALL    TYPE
            DB      $0D, $0A, $00
            B4      M_DONE
            LBR     M_LOOP
M_DONE:     LBR     PROMPT

T_CMD:      CALL    SKIPWS
            CALL    GETHEX
            DB      $04
            LBDF    BAD_PARM
            GHI     RD
            PHI     R7
            GLO     RD
            PLO     R7
            CALL    SKIPWS
            CALL    GETHEX
            DB      $04
            LBDF    BAD_PARM
            GHI     RD
            PHI     R8
            GLO     RD
            PLO     R8
            CALL    SKIPWS
            CALL    ATOI
            LBDF    BAD_PARM
            CALL    SKIPWS
            LDN     RF
            LBNZ    BAD_PARM
            GHI     RD
            PHI     R9
            GLO     RD
            PLO     R9
            GLO     R8
            STR     R2
            GLO     R7
            SD
            GHI     R8
            STR     R2
            GHI     R7
            SDB
            BL      T_FWD
T_BACK:     GLO     R7          ;src += len
            STR     R2
            GLO     R9
            ADD
            PLO     R7
            GHI     R7
            STR     R2
            GHI     R9
            ADC
            PHI     R7
            GLO     R8          ;dest += len
            STR     R2
            GLO     R9
            ADD
            PLO     R8
            GHI     R8
            STR     R2
            GHI     R9
            ADC
            PHI     R8
T_BLOOP:    DEC     R7          ;dest >= src
            DEC     R8          ;Copy src to
            LDN     R7          ;dest starting
            STR     R8          ;from end of src
            DEC     R9
            GHI     R9
            BNZ     T_BLOOP
            GLO     R9
            BNZ     T_BLOOP
            BR      T_DONE
T_FWD:      LDN     R7          ;dest < src
            STR     R8          ;Copy src to
            INC     R7          ;dest starting from
            INC     R8          ;beginning of src
            DEC     R9
            GHI     R9
            BNZ     T_FWD
            GLO     R9
            BNZ     T_FWD
T_DONE:     LBR     PROMPT

            PAGE

R_CMD:      CALL    SKIPWS
            CALL    GETHEX
            DB      $04
            LBDF    BAD_PARM
            CALL    SKIPWS
            LDN     RF
            LBNZ    BAD_PARM
            ; Load run address into R0
            GHI     RD
            PHI     R0
            GLO     RD
            PLO     R0
            RLDI    R1,SCRATCH
            SEX     R1
            ; Set DF flag
            ADI     0           ; Set DF=0
            LDXA
            LSZ
            SMI     0           ; Set DF=1
            ; Load registers from scratch area
.LOADREG    LDXA                ; Skip R0
            LDXA
            LDXA                ; Skip R1
            LDXA
            LDXA
            PHI     R2
            LDXA
            PLO     R2
            LDXA                ; Skip R3
            LDXA
            LDXA
            PHI     R4
            LDXA
            PLO     R4
            LDXA
            PHI     R5
            LDXA
            PLO     R5
            LDXA
            PHI     R6
            LDXA
            PLO     R6
            LDXA
            PHI     R7
            LDXA
            PLO     R7
            LDXA
            PHI     R8
            LDXA
            PLO     R8
            LDXA
            PHI     R9
            LDXA
            PLO     R9
            LDXA
            PHI     RA
            LDXA
            PLO     RA
            LDXA
            PHI     RB
            LDXA
            PLO     RB
            LDXA
            PHI     RC
            LDXA
            PLO     RC
            LDXA
            PHI     RD
            LDXA
            PLO     RD
            LDXA
            PHI     RE
            LDXA
            PLO     RE
            LDXA
            PHI     RF
            LDXA
            PLO     RF
            ; Load monitor return address into R1
            RLDI    R1,WARM_START
            REQ
            SEX     R0
            ; Jump to new program
            SEP     R0
            LBR     PROMPT      ;Should never get here

C_CMD:      CALL    SKIPWS
            LDN     RF
            LBNZ    BAD_PARM    ;There should be no parameters
            RLDI    R0,.SETDF
            SEP     R0      
.SETDF      RLDI    R1,SCRATCH
            SEX     R1
            ; Set DF flag
            ADI     0           ; Set DF=0
            LDXA
            LSZ
            SMI     0           ; Set DF=1
            ; Load registers from scratch area
.LOADREG    LDXA                ; Skip R0
            LDXA
            LDXA                ; Skip R1
            LDXA
            LDXA
            PHI     R2
            LDXA
            PLO     R2
            LDXA
            PHI     R3
            LDXA
            PLO     R3
            LDXA
            PHI     R4
            LDXA
            PLO     R4
            LDXA
            PHI     R5
            LDXA
            PLO     R5
            LDXA
            PHI     R6
            LDXA
            PLO     R6
            LDXA
            PHI     R7
            LDXA
            PLO     R7
            LDXA
            PHI     R8
            LDXA
            PLO     R8
            LDXA
            PHI     R9
            LDXA
            PLO     R9
            LDXA
            PHI     RA
            LDXA
            PLO     RA
            LDXA
            PHI     RB
            LDXA
            PLO     RB
            LDXA
            PHI     RC
            LDXA
            PLO     RC
            LDXA
            PHI     RD
            LDXA
            PLO     RD
            LDXA
            PHI     RE
            LDXA
            PLO     RE
            LDXA
            PHI     RF
            LDXA
            PLO     RF
            ; Load monitor return address into R1
            RLDI    R1,WARM_START
            SEX     R2
            ; Jump to new program
            SEP     R3
            LBR     PROMPT      ;Should never get here

L_CMD:      CALL    SKIPWS
            LDN     RF
            LBNZ    BAD_PARM    ;There should be no parameters
            CALL    TYPE
            TEXT    "Start send...\0"
            CALL    LOADBIN
            CALL    TYPE
            TEXT    "done.\r\n\0"
            LBR     PROMPT

            PAGE

OP30:       DB      1,"BR  \0"
            DB      1,"BQ  \0"
            DB      1,"BZ  \0"
            DB      1,"BDF \0"
            DB      1,"B1  \0"
            DB      1,"B2  \0"
            DB      1,"B3  \0"
            DB      1,"B4  \0"
            DB      0,"SKP\0",0
            DB      1,"BNQ \0"
            DB      1,"BNZ \0"
            DB      1,"BNF \0"
            DB      1,"BN1 \0"
            DB      1,"BN2 \0"
            DB      1,"BN3 \0"
            DB      1,"BN4 \0"

OP70:       DB      0,"RET\0",0
            DB      0,"DIS\0",0
            DB      0,"LDXA\0"
            DB      0,"STXD\0"
            DB      0,"ADC\0",0
            DB      0,"SDB\0",0
            DB      0,"SHRC\0"
            DB      0,"SMB\0",0
            DB      0,"SAV\0",0
            DB      0,"MARK\0"
            DB      0,"REQ\0",0
            DB      0,"SEQ\0",0
            DB      1,"ADCI\0"
            DB      1,"SDBI\0"
            DB      0,"SHLC\0"
            DB      1,"SMBI\0"

COLD_START: LDI     HIGH SCINIT ; Initialize SCRT
            PHI     RF          ; and the stack
            LDI     LOW SCINIT
            PLO     RF
            SEP     RF
            DW      STKPTR

            ; Set console input and output to
            ; the serial port.
            RLDI    RD,SERIN
            CALL    SETINPUT

            RLDI    RD,SEROUT
            CALL    SETOUTPUT

            CALL    TYPE
            TEXT    "\rMAX Monitor V2.1\r\n\0"

PROMPT:     B4      $
            CALL    TYPE
            TEXT    "> \0"

            CALL    READLN
            DW      BUFFER
            DB      (BUFEND-BUFFER)
            LBNF    PROCESS
            CALL    TYPE
            DB      "^C\r\n\0"
            LBR     PROMPT

OPC0:       DB      2,"LBR \0"
            DB      2,"LBQ \0"
            DB      2,"LBZ \0"
            DB      2,"LBDF\0"
            DB      0,"NOP\0",0
            DB      0,"LSNQ\0"
            DB      0,"LSNZ\0"
            DB      0,"LSNF\0"
            DB      0,"LSKP\0"
            DB      2,"LBNQ\0"
            DB      2,"LBNZ\0"
            DB      2,"LBNF\0"
            DB      0,"LSIE\0"
            DB      0,"LSQ\0",0
            DB      0,"LSZ\0",0
            DB      0,"LSDF\0"

OPF0:       DB      0,"LDX\0",0
            DB      0,"OR\0",0,0
            DB      0,"AND\0",0
            DB      0,"XOR\0",0
            DB      0,"ADD\0",0
            DB      0,"SD\0",0,0
            DB      0,"SHR\0",0
            DB      0,"SM\0",0,0
            DB      1,"LDI \0"
            DB      1,"ORI \0"
            DB      1,"ANI \0"
            DB      1,"XRI \0"
            DB      1,"ADI \0"
            DB      1,"SDI \0"
            DB      0,"SHL\0",0
            DB      1,"SMI \0"

DASMREG:    CALL    TYPE
            TEXT    "      \0"
            RLD     RF,R6
            CALL    TYPEBUF
            RLD     R6,RF
            LDA     R7
            ANI     $0F
            PLO     RB
            CALL    HEXDIG
            GLO     RB
            CALL    SEROUT
            RETN

            PAGE

V_CMD:      CALL    SKIPWS
            LDN     RF
            LBNZ    BAD_PARM    ;There should be no parameters
            RLDI    R1,SCRATCH
            CALL    TYPE
            TEXT    "DF=\0"
            LDA     R1
            BZ      .DF0
            CALL    TYPE
            TEXT    "1\r\n\0"
            BR      .REGS
.DF0        CALL    TYPE
            TEXT    "0\r\n\0"
.REGS       CALL    TYPE
            TEXT    "R0=\0"
            LDA     R1
            PHI     RD
            LDA     R1
            PLO     RD
            CALL    HEX4OUT
            CALL    TYPE
            TEXT    " R1=\0"
            LDA     R1
            PHI     RD
            LDA     R1
            PLO     RD
            CALL    HEX4OUT
            CALL    TYPE
            TEXT    "\r\nR2=\0"
            LDA     R1
            PHI     RD
            LDA     R1
            PLO     RD
            CALL    HEX4OUT
            CALL    TYPE
            TEXT    " R3=\0"
            LDA     R1
            PHI     RD
            LDA     R1
            PLO     RD
            CALL    HEX4OUT
            CALL    TYPE
            TEXT    "\r\nR4=\0"
            LDA     R1
            PHI     RD
            LDA     R1
            PLO     RD
            CALL    HEX4OUT
            CALL    TYPE
            TEXT    " R5=\0"
            LDA     R1
            PHI     RD
            LDA     R1
            PLO     RD
            CALL    HEX4OUT
            CALL    TYPE
            TEXT    "\r\nR6=\0"
            LDA     R1
            PHI     RD
            LDA     R1
            PLO     RD
            CALL    HEX4OUT
            CALL    TYPE
            TEXT    " R7=\0"
            LDA     R1
            PHI     RD
            LDA     R1
            PLO     RD
            CALL    HEX4OUT
            CALL    TYPE
            TEXT    "\r\nR8=\0"
            LDA     R1
            PHI     RD
            LDA     R1
            PLO     RD
            CALL    HEX4OUT
            CALL    TYPE
            TEXT    " R9=\0"
            LDA     R1
            PHI     RD
            LDA     R1
            PLO     RD
            CALL    HEX4OUT
            CALL    TYPE
            TEXT    "\r\nRA=\0"
            LDA     R1
            PHI     RD
            LDA     R1
            PLO     RD
            CALL    HEX4OUT
            CALL    TYPE
            TEXT    " RB=\0"
            LDA     R1
            PHI     RD
            LDA     R1
            PLO     RD
            CALL    HEX4OUT
            CALL    TYPE
            TEXT    "\r\nRC=\0"
            LDA     R1
            PHI     RD
            LDA     R1
            PLO     RD
            CALL    HEX4OUT
            CALL    TYPE
            TEXT    " RD=\0"
            LDA     R1
            PHI     RD
            LDA     R1
            PLO     RD
            CALL    HEX4OUT
            CALL    TYPE
            TEXT    "\r\nRE=\0"
            LDA     R1
            PHI     RD
            LDA     R1
            PLO     RD
            CALL    HEX4OUT
            CALL    TYPE
            TEXT    " RF=\0"
            LDA     R1
            PHI     RD
            LDA     R1
            PLO     RD
            CALL    HEX4OUT
            CALL    TYPE
            TEXT    "\r\nP=\0"
            LDA     R1
            PHI     RB
            PLO     RB
            CALL    HEXDIG
            GLO     RB
            CALL    SEROUT
            CALL    TYPE
            TEXT    " X=\0"
            GHI     RB
            SHR
            SHR
            SHR
            SHR
            PLO     RB
            CALL    HEXDIG
            GLO     RB
            CALL    SEROUT
            CALL    TYPE
            TEXT    "\r\nD=\0"
            LDN     R1
            PLO     RB
            CALL    HEX2OUT
            CALL    TYPE
            TEXT    "\r\n\0"
            LBR     PROMPT

PROCESS:    CALL    TYPE
            TEXT    "\r\n\0"

            RLDI    RF,BUFFER

            CALL    SKIPWS      ; Skip leading spaces
            LDA     RF
            LBZ     PROMPT      ; Reached end-of-line
            ANI     $DF         ; Decode command
            SMI     $42
            LBZ     B_CMD
            SMI     $01
            LBZ     C_CMD
            SMI     $01
            LBZ     D_CMD
            SMI     $04
            LBZ     H_CMD
            SMI     $01
            LBZ     I_CMD
            SMI     $03
            LBZ     L_CMD
            SMI     $01
            LBZ     M_CMD
            SMI     $02
            LBZ     O_CMD
            SMI     $03
            LBZ     R_CMD
            SMI     $01
            LBZ     S_CMD
            SMI     $01
            LBZ     T_CMD
            SMI     $02
            LBZ     V_CMD
            SMI     $01
            LBZ     W_CMD
            SMI     $03
            LBZ     Z_CMD
            CALL    TYPE
            TEXT    "Bad command.\r\n\0"
            LBR     PROMPT

H_CMD:      CALL    TYPE
            TEXT    "Commands:\r\n"
            TEXT    "(M)EMORY, (W)RITE\r\n"
            TEXT    "(T)RANSFER, (V)IEW\r\n"
            TEXT    "(L)OAD, (S)AVE\r\n"
            TEXT    "(R)UN, (C)CONTINUE\r\n"
            TEXT    "(D)ISASSEMBLE\r\n"
            TEXT    "(Z)ERO (B)ASIC\r\n\0"
            LBR     PROMPT

D_CMD:      CALL    SKIPWS
            LDN     RF          ;If no params,
            BZ      D_CONT      ;repeat last command
            CALL    GETHEX      ;Get the start address
            DB      $04
            LBDF    BAD_PARM
            GHI     RD          ;Store in R7
            PHI     R7
            GLO     RD
            PLO     R7
            CALL    SKIPWS
            CALL    ATOI        ;Get the length
            LBDF    BAD_PARM
            GHI     RD          ;Store in R8
            PHI     R8
            GLO     RD
            PLO     R8
            CALL    SKIPWS
            LDN     RF          ;Check for extra
            LBNZ    BAD_PARM    ;parameters
D_CONT:     RLD     R9,R8       ;Copy the byte count to R9
D_LINE:     RLD     RD,R7
            CALL    HEX4OUT
            LDI     ' '
            CALL    SEROUT
            LDN     R7
            PLO     RB
            CALL    HEX2OUT
            LDI     ' '
            CALL    SEROUT
            LDN     R7
            SHR
            SHR
            SHR
            SHR
            LBZ     OP_0x
            SMI     $01
            LBZ     OP_1x
            SMI     $01
            LBZ     OP_2x
            SMI     $01
            LBZ     OP_3x
            SMI     $01
            LBZ     OP_4x
            SMI     $01
            LBZ     OP_5x
            SMI     $01
            LBZ     OP_6x
            SMI     $01
            LBZ     OP_7x
            SMI     $01
            LBZ     OP_8x
            SMI     $01
            LBZ     OP_9x
            SMI     $01
            LBZ     OP_Ax
            SMI     $01
            LBZ     OP_Bx
            SMI     $01
            LBZ     OP_Cx
            SMI     $01
            LBZ     OP_Dx
            SMI     $01
            LBZ     OP_Ex
OP_Fx:      CALL    DASMTBL
            DW      OPF0
            LBR     DASMNEXT
OP_1x:      CALL    DASMREG
            DB      "INC  R\0"
            LBR     DASMNEXT
OP_2x:      CALL    DASMREG
            DB      "DEC  R\0"
            LBR     DASMNEXT
OP_3x:      CALL    DASMTBL
            DW      OP30
            LBR     DASMNEXT
OP_4x:      CALL    DASMREG
            DB      "LDA  R\0"
            LBR     DASMNEXT
OP_0x:      LDN     R7
            BZ      OP_IDL
            CALL    DASMREG
            DB      "LDN  R\0"
            LBR     DASMNEXT
OP_IDL:     CALL    TYPE
            DB      "      IDL\0"
            INC     R7
            LBR     DASMNEXT
OP_5x:      CALL    DASMREG
            DB      "STR  R\0"
            LBR     DASMNEXT
OP_6x:      LDN     R7
            ANI     $0F
            BZ      OP_IRX
            ANI     $08
            BNZ     OP_INP
            CALL    DASMREG
            DB      "OUT \0"
            LBR     DASMNEXT
OP_INP:     CALL    TYPE
            TEXT    "      INP \0"
            LDA     R7
            ANI     $07
            PLO     RB
            CALL    HEXDIG
            GLO     RB
            CALL    SEROUT
            LBR     DASMNEXT
OP_IRX:     CALL    TYPE
            DB      "      IRX\0"
            INC     R7
            LBR     DASMNEXT
OP_7x:      CALL    DASMTBL
            DW      OP70
            LBR     DASMNEXT
OP_8x:      CALL    DASMREG
            DB      "GLO  R\0"
            LBR     DASMNEXT
OP_9x:      CALL    DASMREG
            DB      "GHI  R\0"
            LBR     DASMNEXT
OP_Ax:      CALL    DASMREG
            DB      "PLO  R\0"
            LBR     DASMNEXT
OP_Bx:      CALL    DASMREG
            DB      "PHI  R\0"
            LBR     DASMNEXT
OP_Cx:      CALL    DASMTBL
            DW      OPC0
            LBR     DASMNEXT
OP_Dx:      LDN     R7
            ANI     $0F
            SMI     $04
            BZ      OP_CALL
            SMI     $01
            BZ      OP_RETN
            CALL    DASMREG
            DB      "SEP  R\0"
            LBR     DASMNEXT
OP_CALL:    INC     R7   
            LDA     R7
            PLO     RB
            CALL    HEX2OUT
            LDI     ' '
            CALL    SEROUT
            LDN     R7
            PLO     RB
            CALL    HEX2OUT
            LDI     ' '
            CALL    SEROUT
            CALL    TYPE
            DB      "CALL $\0"
            DEC     R7
            LDA     R7
            PHI     RD
            LDA     R7
            PLO     RD
            CALL    HEX4OUT
            LBR     DASMNEXT
OP_RETN:    CALL    TYPE
            DB      "      RETN\0"
            INC     R7
            LBR     DASMNEXT
OP_Ex:      CALL    DASMREG
            DB      "SEX  R\0"
DASMNEXT:   CALL    TYPE
            TEXT    "\r\n\0"
            B4      .DONE
            DEC     R9
            LBRNZ   R9,D_LINE
.DONE       LBR     PROMPT

S_CMD:      CALL    SKIPWS
            CALL    GETHEX
            DB      $04
            LBDF    BAD_PARM
            GHI     RD
            PHI     RA
            GLO     RD
            PLO     RA
            CALL    SKIPWS
            CALL    GETHEX
            DB      $04
            LBDF    BAD_PARM
            CALL    SKIPWS
            LDN     RF
            LBNZ    BAD_PARM
            GLO     RD
            STR     R2
            GLO     RA
            SD
            PLO     RC
            GHI     RD
            STR     R2
            GHI     RA
            SDB
            PHI     RC
            BGE     S_START
            CALL    TYPE
            TEXT    "End must be >= start.\r\n\0"
            BR      S_RET
S_START:    INC     RC
            CALL    TYPE
            TEXT    "Start receive...\0"
            CALL    SAVEBIN
            BNF     S_DONE
            CALL    TYPE
            TEXT    "Save error.\r\n\0"
S_DONE:     CALL    SERIN
            CALL    TYPE
            TEXT    "done.\r\n\0"
S_RET:      LBR     PROMPT

W_CMD:      CALL    SKIPWS
            CALL    GETHEX     ;Get the address for writing
            DB      $04
            LBDF    BAD_PARM
            GHI     RD          ;Store it in R7
            PHI     R7
            GLO     RD
            PLO     R7
W_NEXT:     CALL    SKIPWS      ;Look for hex byte
            CALL    GETHEX
            DB      $02
            BNF     W_STORE     ;If we got one, store it
            LDN     RF          ;End of line?
            BZ      W_END
            XRI     $22         ;Start of string?
            LBNZ    BAD_PARM    ;Neither, bad parameter
            INC     RF
            BR      W_STRING
W_STORE:    GLO     RD
            STR     R7
            INC     R7
            BR      W_NEXT
W_STRING:   LDN     RF          ;Get next char of string
            BZ      W_END       ;End of line?
            XRI     $22         ;Ending quote
            BNZ     W_STR       ;No, store character
            INC     RF          ;Yes, skip the '"'
            BR      W_NEXT      ;and look for more input
W_STR:      LDN     RF
            STR     R7
            INC     R7
            INC     RF
            BR      W_STRING
W_END:      CALL    SKIPWS
            LDN     RF
            LBNZ    BAD_PARM
            LBR     PROMPT

BAD_PARM:   CALL    TYPE
            TEXT    "Bad parameter: '\0"
            CALL    TYPEBUF
            CALL    TYPE
            TEXT    "'\r\n\0"
            LBR     PROMPT

B_CMD:      LDI     HIGH BASIC3
            PHI     R0
            LDI     LOW BASIC3
            PLO     R0
            SEX     R0
            SEP     R0

Z_CMD:      CALL    SKIPWS
            CALL    GETHEX      ;Get the start address
            DB      $04
            LBDF    BAD_PARM
            GHI     RD          ;Store in R7
            PHI     R7
            GLO     RD
            PLO     R7
            CALL    SKIPWS
            CALL    ATOI        ;Get the length
            LBDF    BAD_PARM
            GHI     RD          ;Store in R8
            PHI     R8
            GLO     RD
            PLO     R8
            CALL    SKIPWS
            LDN     RF          ;Check for extra
            LBNZ    BAD_PARM    ;parameters
            LDI     $00
            PLO     RD
.LOOP:      GLO     RD
            STR     R7
            INC     R7
            DEC     R8
            LBRNZ   R8,.LOOP
            LBR     PROMPT

I_CMD:      CALL    SKIPWS
            LDN     RF          ;If no params,
            BZ      I_DFLT      ;set default serial
            CALL    GETHEX
            DB      $04
            LBDF    BAD_PARM
            CALL    SKIPWS
            LDN     RF
            LBNZ    BAD_PARM
            BR      I_SET
I_DFLT:     RLDI    RD,SERIN
I_SET:      CALL    SETINPUT
            LBR     PROMPT

O_CMD:      CALL    SKIPWS
            LDN     RF          ;If no params,
            BZ      O_DFLT      ;set default serial
            CALL    GETHEX
            DB      $04
            LBDF    BAD_PARM
            CALL    SKIPWS
            LDN     RF
            LBNZ    BAD_PARM
            BR      O_SET
O_DFLT:     RLDI    RD,SEROUT
O_SET:      CALL    SETOUTPUT
            LBR     PROMPT

            END
