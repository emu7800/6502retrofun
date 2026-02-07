.macro sword_gfxgr_data invert
.if invert
    .byte $04  ; .....1..
    .byte $02  ; ......1.
    .byte $ff  ; 11111111
    .byte $02  ; ......1.
    .byte $04  ; .....1..
.else
    .byte $20  ; ..1.....
    .byte $40  ; .1......
    .byte $ff  ; 11111111
    .byte $40  ; .1......
    .byte $20  ; ..1.....
.endif
    .byte 0
.endmacro