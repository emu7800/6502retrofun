.macro leftofname_gfxpf_data orig
        ; PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
    .byte $f0, $ff, $ff   ; 11111111111111111111 11111111111111111111
    .byte $00, $00, $00   ; 11.................. ..................11
    .byte $00, $00, $00   ; 11.................. ..................11
    .byte $00, $00, $00   ; 11.................. ..................11
    .byte $00, $00, $00   ; 11.................. ..................11
    .byte $00, $00, $00   ; 11.................. ..................11
.ifblank orig
    .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111  ; also in belowyellowcastle_gfxpf_data
.else
    ; relies on the above line appearing in a subsequent gfxpf_data
.endif
.endmacro