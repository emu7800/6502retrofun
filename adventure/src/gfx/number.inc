.macro number1_gfx_data
    .byte $04  ; .....1..
    .byte $0c  ; ....11..
    .byte $04  ; .....1..
    .byte $04  ; .....1..
    .byte $04  ; .....1..
    .byte $04  ; .....1..
    .byte $0e  ; ....111.
    .byte 0
.endmacro

.macro number2_gfx_data
    .byte $0e  ; ....111.
    .byte $11  ; ...1...1
    .byte $01  ; .......1
    .byte $02  ; ......1.
    .byte $04  ; .....1..
    .byte $08  ; ....1...
    .byte $1f  ; ...11111
    .byte 0
.endmacro

.macro number3_gfx_data
    .byte $0e  ; ....111.
    .byte $11  ; ...1...1
    .byte $01  ; .......1
    .byte $06  ; .....11.
    .byte $01  ; .......1
    .byte $11  ; ...1...1
    .byte $0e  ; ....111.
    .byte 0
.endmacro