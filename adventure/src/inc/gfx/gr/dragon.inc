; "Rhindle, Yorgle, and Grundle"

.macro dragonnormal_gfxgr_data invert
.if invert
    .byte $60     ; .11.....
    .byte $f0     ; 1111....
    .byte $cf     ; 11..1111
    .byte $7f     ; .1111111
    .byte $70     ; .111....
    .byte $20     ; ..1.....
    .byte $20     ; ..1.....
    .byte $78     ; .1111...
    .byte $fc     ; 111111..
    .byte $fe     ; 1111111.
    .byte $c7     ; 11...111
    .byte $c3     ; 11....11
    .byte $c3     ; 11....11
    .byte $e3     ; 111...11
    .byte $ff     ; 11111111
    .byte $3c     ; ..1111..
    .byte $10     ; ...1....
    .byte $f1     ; 1111...1
    .byte $87     ; 1....111
    .byte $fc     ; 111111..
.else
    .byte $06     ; .....11.
    .byte $0f     ; ....1111
    .byte $f3     ; 1111..11
    .byte $fe     ; 1111111.
    .byte $0e     ; ....111.
    .byte $04     ; .....1..
    .byte $04     ; .....1..
    .byte $1e     ; ...1111.
    .byte $3f     ; ..111111
    .byte $7f     ; .1111111
    .byte $e3     ; 111...11
    .byte $c3     ; 11....11
    .byte $c3     ; 11....11
    .byte $c7     ; 11...111
    .byte $ff     ; 11111111
    .byte $3c     ; ..1111..
    .byte $08     ; ....1...
    .byte $8f     ; 1...1111
    .byte $e1     ; 111....1
    .byte $3f     ; ..111111
.endif
    .byte 0
.endmacro

.macro dragonroar_gfxgr_data invert
.if invert
    .byte $01     ; .......1
    .byte $02     ; ......1.
    .byte $64     ; .11..1..
    .byte $f8     ; 11111...
    .byte $d0     ; 11.1....
    .byte $70     ; .111....
    .byte $78     ; .1111...
    .byte $24     ; ..1..1..
    .byte $22     ; ..1...1.
    .byte $71     ; .111...1
    .byte $78     ; .1111...
    .byte $fc     ; 111111..
    .byte $fe     ; 1111111.
    .byte $fe     ; 1111111.
    .byte $fe     ; 1111111.
    .byte $fe     ; 1111111.
    .byte $7c     ; .11111..
    .byte $38     ; ..111...
    .byte $10     ; ...1....
    .byte $1f     ; ...11111
    .byte $01     ; .......1
    .byte $07     ; .....111
.else
    .byte $80     ; 1.......
    .byte $40     ; .1......
    .byte $26     ; ..1..11.
    .byte $1f     ; ...11111
    .byte $0b     ; ....1.11
    .byte $0e     ; ....111.
    .byte $1e     ; ...1111.
    .byte $24     ; ..1..1..
    .byte $44     ; .1...1..
    .byte $8e     ; 1...111.
    .byte $1e     ; ...1111.
    .byte $3f     ; ..111111
    .byte $7f     ; .1111111
    .byte $7f     ; .1111111
    .byte $7f     ; .1111111
    .byte $7f     ; .1111111
    .byte $3e     ; ..11111.
    .byte $1c     ; ...111..
    .byte $08     ; ....1...
    .byte $f8     ; 11111...
    .byte $80     ; 1.......
    .byte $e0     ; 111.....
.endif
    .byte 0
.endmacro

.macro dragondead_gfxgr_data invert
.if invert
    .byte $30     ; ..11....
    .byte $30     ; ..11....
    .byte $30     ; ..11....
    .byte $70     ; .111....
    .byte $d8     ; 11.11...
    .byte $fe     ; 1111111.
    .byte $73     ; .111..11
    .byte $01     ; .......1
    .byte $3f     ; ..111111
    .byte $7f     ; .1111111
    .byte $7f     ; .1111111
    .byte $7e     ; .111111.
    .byte $1e     ; ...1111.
    .byte $04     ; .....1..
    .byte $76     ; .111.11.
    .byte $42     ; .1....1.
    .byte $7e     ; .111111.
.else
    .byte $0c     ; ....11..
    .byte $0c     ; ....11..
    .byte $0c     ; ....11..
    .byte $0e     ; ....111.
    .byte $1b     ; ...11.11
    .byte $7f     ; .1111111
    .byte $ce     ; 11..111.
    .byte $80     ; 1.......
    .byte $fc     ; 111111..
    .byte $fe     ; 1111111.
    .byte $fe     ; 1111111.
    .byte $7e     ; .111111.
    .byte $78     ; .1111...
    .byte $20     ; ..1.....
    .byte $6e     ; .11.111.
    .byte $42     ; .1....1.
    .byte $7e     ; .111111.
.endif
    .byte 0
.endmacro