            INCL    'max_bios.inc'

BASE:       EQU     $f000

            ORG     BASE+0f00h
f_boot:     LBR     NOTIMP
f_type:     LBR     SEROUT
f_read:     LBR     SERIN
f_msg:      LBR     TYPEBUF
f_typex:    LBR     NOTIMP
f_input:    LBR     INPUT256
f_strcmp:   LBR     STRCMP
f_ltrim:    LBR     LTRIM
f_strcpy:   LBR     STRCPY
f_memcpy:   LBR     MEMCPY
f_wrtsec:   LBR     NOTIMP
f_rdsec:    LBR     NOTIMP
f_seek0:    LBR     NOTIMP
f_seek:     LBR     NOTIMP
f_drive:    LBR     NOTIMP
f_setbd:    LBR     NOTIMP
f_mul16:    LBR     MUL16
f_div16:    LBR     DIV16
f_iderst:   LBR     NOTIMP
f_idewrt:   LBR     NOTIMP
f_ideread:  LBR     NOTIMP
f_initcall: LBR     INITCALL
f_ideboot:  LBR     NOTIMP
f_hexin:    LBR     HEXIN
f_hexout2:  LBR     HEXOUT2
f_hexout4:  LBR     HEXOUT4
f_tty:      LBR     SEROUT
f_mover:    LBR     NOTIMP
f_minimon:  LBR     NOTIMP
f_freemem:  LBR     FREEMEM
f_isnum:    LBR     ISNUM
f_atoi:     LBR     ATOI
f_uintout:  LBR     UINTOUT
f_intout:   LBR     INTOUT
f_inmsg:    LBR     TYPE
f_inputl:   LBR     INPUT
f_brktest:  LBR     NOTIMP
f_findtkn:  LBR     NOTIMP
f_isalpha:  LBR     ISALPHA
f_ishex:    LBR     ISHEX
f_isalnum:  LBR     ISALNUM
f_idnum:    LBR     NOTIMP
f_isterm:   LBR     ISTERM
f_getdev:   LBR     NOTIMP

NOTIMP:     RETN

            END