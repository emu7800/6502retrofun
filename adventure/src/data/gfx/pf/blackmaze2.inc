.macro blackmaze2_gfxpf_data original
        ; PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
    .byte $f0, $ff, $ff   ; 11111111111111111111 11111111111111111111
    .byte $00, $00, $c0   ; ..................11 11..................
    .byte $f0, $ff, $cf   ; 1111111111111111..11 11..1111111111111111
    .byte $00, $00, $0c   ; ..............11.... ....11..............
    .byte $f0, $0f, $ff   ; 11111111....11111111 11111111....11111111
    .byte $00, $0f, $c0   ; ........1111......11 11......1111........
.ifblank original
    .byte $30, $cf, $cc   ; 11..1111..11..11..11 11..11..11..1111..11  ; also in blackmazeentry_gfxpf_data
.else
    ; relies on the above line appearing in a subsequent gfxpf_data
.endif
.endmacro