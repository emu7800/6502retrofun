.setcpu "6502"
.include "vcs.inc"


.segment "CODE0"
PrintDisplayR:
            rts

.segment "CODE1"
StartGame:
            jmp StartGame

.segment "VECTORS0"
;PrintDisplay:
            sta Bank+0
            jsr PrintDisplayR
            sta Bank+1
            rts
;Reset:
            sta Bank+1
            jmp StartGame
;Bank:
            .word 0
            .word Reset
            .word Reset
            .word Reset

.segment "VECTORS1"
PrintDisplay:
            sta Bank+0
            jsr PrintDisplayR
            sta Bank+1
            rts
Reset:
            sta Bank+1
            jmp StartGame
Bank:
            .word 0
            .word Reset
            .word Reset
            .word Reset
