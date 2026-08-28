.macro redmaze1_gfxpf_data original
        ; PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
    .byte $f0, $ff, $ff   ; 11111111111111111111 11111111111111111111
    .byte $00, $00, $00   ; .................... ....................
    .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
    .byte $00, $00, $0c   ; ..............11.... ....11..............
    .byte $f0, $ff, $0c   ; 111111111111..11.... ....11..111111111111
    .byte $f0, $03, $cc   ; 111111........11..11 11..11........111111
.ifblank original
    .byte $f0, $33, $cf   ; 111111..11..1111..11 11..1111..11..111111  ; also in redmazebottom_gfxpf_data
.else
    ; relies on the above line appearing in a subsequent gfxpf_data
.endif
.endmacro