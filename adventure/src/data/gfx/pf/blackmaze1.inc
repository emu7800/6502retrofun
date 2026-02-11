.macro blackmaze1_gfxpf_data original
        ; PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
    .byte $f0, $f0, $ff   ; 1111....111111111111 111111111111....1111
    .byte $00, $00, $03   ; ............11...... ......11............
    .byte $f0, $ff, $03   ; 11111111111111...... ......11111111111111
    .byte $00, $00, $00   ; .................... ....................
    .byte $30, $3f, $ff   ; 11..111111..11111111 11111111..111111..11
    .byte $00, $30, $00   ; ........11.......... ..........11........
.ifblank original
    .byte $f0, $f0, $ff   ; 1111....111111111111 111111111111....1111  ; also in blackmaze3_gfxpf_data
.else
    ; relies on the above line appearing in a subsequent gfxpf_data
.endif
.endmacro