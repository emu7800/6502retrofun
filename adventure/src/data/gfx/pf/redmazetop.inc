.macro redmazetop_gfxpf_data orig
        ; PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
    .byte $f0, $ff, $ff   ; 11111111111111111111 11111111111111111111
    .byte $00, $00, $c0   ; 1111..............11 11..............1111
    .byte $f0, $ff, $cf   ; 1111111111111111..11 11..1111111111111111
    .byte $00, $00, $cc   ; ..............11..11 11..11..............
    .byte $f0, $33, $ff   ; 111111..11..11111111 11111111..11..111111
    .byte $f0, $33, $00   ; 111111..11.......... ..........11..111111
.ifblank orig
    .byte $f0, $3f, $0c   ; 1111111111....11.... ....11....1111111111  ; also in whitecastleentry_gfxpf_data
.else
    ; relies on the above line appearing in a subsequent gfxpf_data
.endif
.endmacro