; "Knubberrub"

.macro bat1_gfxgr_data
    .byte $81  ; 1......1
    .byte $81  ; 1......1
    .byte $c3  ; 11....11
    .byte $c3  ; 11....11
    .byte $ff  ; 11111111
    .byte $5a  ; .1.11.1.
    .byte $66  ; .11..11.
    .byte 0
.endmacro

.macro bat2_gfxgr_data
    .byte $01  ; .......1
    .byte $80  ; 1.......
    .byte $01  ; .......1
    .byte $80  ; 1.......
    .byte $3c  ; ..1111..
    .byte $5a  ; .1.11.1.
    .byte $66  ; .11..11.
    .byte $c3  ; 11....11
    .byte $81  ; 1......1
    .byte $81  ; 1......1
    .byte $81  ; 1......1
    .byte 0
.endmacro