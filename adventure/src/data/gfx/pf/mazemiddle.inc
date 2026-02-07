.macro mazemiddle_gfxpf_data orig
        ; PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
    .byte $f0, $ff, $cc   ; 111111111111..11..11 11..11..111111111111
    .byte $00, $00, $cc   ; ..............11.11. 11..11..............
    .byte $f0, $03, $cf   ; 111111......1111..11 11..1111......111111
    .byte $00, $03, $00   ; ....11.............. ..............11....
    .byte $f0, $f3, $fc   ; 111111..1111..111111 111111..1111..111111
    .byte $00, $33, $0c   ; ....11..11....11.... ....11....11..11....
.ifblank orig
    .byte $f0, $33, $cc   ; 111111..11....11..11 11..11....11..111111  ; also in mazeside_gfxpf_data
.else
    ; relies on the above line appearing in a subsequent gfxpf_data
.endif
.endmacro