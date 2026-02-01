; "newmodem.src"
;
; From "Toward 2400: RS-232 revitied"
; by George Hug
; Transactor, Vol 9, Issue 3
; https://archive.org/details/transactor-magazines-v9-i03/page/n63/mode/2up
;

            .setcpu "6502"

            .export rs232_userport_newmodem_funcs_setup   := rssetup
            .export rs232_userport_newmodem_funcs_disable := disabl

ribuf   = $f7       ; RS-232: recv buffer ptr
robuf   = $f9
baudof  = $0299
ridbe   = $029b     ; RS-232: index to end of recv buffer
ridbs   = $029c     ; RS-232: index to start of recv buffer
rodbs   = $029d     ; RS-232: index to start of xmit buffer
rodbe   = $029e     ; RS-232: index to end of xmit buffer
enabl   = $02a1     ; RS-232: NMI interrupts enabled from ci2icr (bit4=wait for rcv edge, bit1=rcving data, bit0=xmiting data)
palnts  = $02a6     ; RS-232: PAL/NTSC switch, for selecting baud rate tables: 0=NTSC, 1=PAL
rstkey  = $fe56
norest  = $fe72
return  = $febc
oldout  = $f1ca
oldchk  = $f21b
ochrin  = $f157
ogetin  = $f13e
findfn  = $f30f
devnum  = $f31f
nofile  = $f701

; CIA 2
cia2_pra   = $dd00  ; Data port A
cia2_prb   = $dd01  ; Data port B
cia2_ta_lo = $dd04  ; Timer A low byte
cia2_ta_hi = $dd05  ; Timer A high byte
cia2_tb_lo = $dd06  ; Timer B low byte
cia2_tb_hi = $dd07  ; Timer B high byte
cia2_icr   = $dd0d  ; Interrupt Control and status register
cia2_cra   = $dd0e  ; Control timer A
cia2_crb   = $dd0f  ; Control timer B

;xx00 jmp rssetup
;xx03 jmp inable
;xx06 jmp disabl
;xx09 jmp rsget
;xx0c jmp rsout
;     nop


            .rodata

bloc:
bntsc:
; start-bit times for ntsc
            .word   4915    ;  300
            .word   1090    ; 1200
            .word   459     ; 2400
; full-bit times for ntsc
            .word   3410    ;  300
            .word   845     ; 1200
            .word   421     ; 2400
bpal:
; start-bit times for pal
            .word   4718    ;  300
            .word   1047    ; 1200
            .word   441     ; 2400
; full-bit times for pal
            .word   3274    ;  300
            .word   811     ; 1200
            .word   404     ; 2400
bpaloffset = bpal - bntsc


            .code

;-----------------------------------------------------
rssetup:
            jsr     setbaud
            lda     #<nmi64
            ldy     #>nmi64
            sta     $0318
            sty     $0319
            lda     #<nchkin
            ldy     #>nchkin
            sta     $031e
            sty     $031f
            lda     #<nbsout
            ldy     #>nbsout
            sta     $0326
            sty     $0327
            lda     #<nchrin
            ldy     #>nchrin
            sta     $0324
            sty     $0325
            lda     #<ngetin
            ldy     #>ngetin
            sta     $032a
            sty     $032b
            rts
;-----------------------------------------------------
setbaud:    asl a                ; a: baud_rate: 0=300, 1=1200, 2=2400
            ldy palnts           ; NTSC or PAL?
            beq :+
            clc
            adc #bpaloffset
:           tay
            lda bloc,y
            sta strtlo+1
            lda bloc+1,y
            sta strthi+1
            lda bloc+6,y
            sta fulllo+1
            lda bloc+7,y
            sta fullhi+1
            rts
;-----------------------------------------------------
nmi64:      pha                  ; new nmi handler
            txa
            pha
            tya
            pha
nmi128:     cld
            ldx     cia2_tb_hi   ; sample timer B high byte
            lda     #$7f         ; disable CIA NMI's
            sta     cia2_icr
            lda     cia2_icr     ; read/clear flags
            bpl     notcia       ; (restore key)
            cpx     cia2_tb_hi   ; timer B timeout since ldx cia2_tb_hi above?
            ldy     cia2_prb     ; (sample pin C)
            bcs     mask         ; no
            ora     #$02         ; yes, set flag in acc.
            ora     cia2_icr     ; read/clear flags again
mask:       and     enabl        ; mask out non-enabled
            tax                  ; these must be serviced
            lsr                  ; timer A? (bit 0)
            bcc     ckflag       ; no
            lda     cia2_pra     ; yes, put bit on pin M
            and     #$fb
            ora     $b5
            sta     cia2_pra
ckflag:     txa
            and     #$10         ; *flag nmi? (bit 4)
            beq     nmion        ; no
strtlo:     lda     #$42         ; yes, start-bit to timer B
            sta     cia2_tb_lo
strthi:     lda     #$04
            sta     cia2_tb_hi
            lda     #$11         ; start timer B counting
            sta     cia2_crb
            lda     #$12         ; *flag nmi off, timer B on
            eor     enabl        ; update mask
            sta     enabl
            sta     cia2_icr     ; enable new config.
fulllo:     lda     #$4d         ; change reload latch
            sta     cia2_tb_lo   ;  to full-bit time
fullhi:     lda     #$03
            sta     cia2_tb_hi
            lda     #$08         ; # of bits to receive
            sta     $a8
            bne     chktxd       ; branch always
notcia:     ldy     #$00
            jmp     rstkey       ; or jmp norest
nmion:      lda     enabl        ; re-enable nmi's
            sta     cia2_icr
            txa
            and     #$02         ; timer B? (bit 1)
            beq     chktxd       ; no
            tya                  ; yes, sample from (sample pin C) above
            lsr
            ror     $aa          ; rs232 is LSB first
            dec     $a8          ; byte finished?
            bne     txd          ; no
            ldy     ridbe        ; yes, byte to buffer
            lda     $aa
            sta     (ribuf),y    ; (no over-run test)
            inc     ridbe
            lda     #$00         ; stop timer B
            sta     cia2_crb
            lda     #$12         ; timer B NMI off, *flag on
switch:     ldy     #$7f         ; disable NMI's
            sty     cia2_icr     ; twice
            sty     cia2_icr
            eor     enabl        ; update mask
            sta     enabl
            sta     cia2_icr     ; enable new config.
txd:        txa
            lsr                  ; timer A?
chktxd:     bcc     exit         ; no
            dec     $b4          ; yes, byte finished?
            bmi     char         ; yes
            lda     #$04         ; no, prep next bit
            ror     $b6          ; (fill with stop bits)
            bcs     store
low:        lda     #$00
store:      sta     $b5
exit:       jmp     return       ; restore regs, rti
char:       ldy     rodbs
            cpy     rodbe        ; buffer empty?
            beq     txoff        ; yes
getbuf:     lda     (robuf),y    ; no, prep next byte
            inc     rodbs
            sta     $b6
            lda     #$09         ; # bits to send
            sta     $b4
            bne     low          ; always - do start bit
txoff:      ldx     #$00         ; stop timer A
            stx     cia2_cra
            lda     #$01         ; disable timer A nmi
            bne     switch       ; always
;-----------------------------------------------------
disabl:     pha                  ; turns off modem port
test:       lda     enabl
            and     #$03         ; any current activity?
            bne     test         ; yes, test again
            lda     #$10         ; no, disable *flag nmi
            sta     cia2_icr
            lda     #$02
            and     enabl        ; currently receiving?
            bne     test         ; yes, start over
            sta     enabl        ; all off, update mask
            pla
            rts
;-----------------------------------------------------
nbsout:     pha                  ; new bsout
            lda     $9a
            cmp     #$02
            bne     notmod
            pla
rsout:      sta     $9e          ; output to modem
            sty     $97
point:      ldy     rodbe
            lda     $9e
            sta     (robuf),y    ; not official 'til sty rodbe below
            iny
            cpy     rodbs        ; buffer full?
            beq     fulbuf       ; yes
            sty     rodbe        ; no, bump pointer
strtup:     lda     enabl
            and     #$01         ; transmitting now?
            bne     ret3         ; yes
            sta     $b5          ; no, prep start bit
            lda     #$09
            sta     $b4          ;  # bits to send
            ldy     rodbs
            lda     (robuf),y
            sta     $b6          ;  and next byte
            inc     rodbs
            lda     baudof       ; full TX bit time to timer A
            sta     cia2_ta_lo
            lda     baudof+1
            sta     cia2_ta_hi
            lda     #$11         ; start timer A
            sta     cia2_cra
            lda     #$81         ; enable timer A nmi
change:     sta     cia2_icr     ; nmi clears flag if set
            php                  ; save irq status.
            sei                  ; disable irq's
            ldy     #$7f         ; disable nmi's
            sty     cia2_icr     ; twice
            sty     cia2_icr
            ora     enabl        ; update mask
            sta     enabl
            sta     cia2_icr     ; enable new config.
            plp                  ; restore irq status
ret3:       clc
            ldy     $97
            lda     $9e
            rts
fulbuf:     jsr     strtup
            jmp     point
notmod:     pla                  ; back to old bsout.
            jmp     oldout
;-----------------------------------------------------
nchkin:     jsr     findfn       ; new chkin
            bne     nosuch
            jsr     devnum
            lda     $ba
            cmp     #$02
            bne     back
            sta     $99
inable:     sta     $9e          ; enable rs232 input
            sty     $97
;bauds:     lda     baudof+1     ; set receive to same
;           and     #$06         ;  baud rate as xmit
;           tay
;           lda     strt24,y
;           sta     strtlo+1     ; overwrite code setting timer B (self mod)
;           lda     strt24+1,y
;           sta     strthi+1
;           lda     full24,y
;           sta     fulllo+1
;           lda     full24+1,y
;           sta     fullhi+1
            lda     enabl
            and     #$12        ; flag or timer B on?
            bne     ret1        ; yes
            sta     cia2_crb    ; no, stop timer B
            lda     #$90        ; turn on flag nmi
            jmp     change
nosuch:     jmp     nofile
back:       lda     $ba
            jmp     oldchk
;-----------------------------------------------------
nchrin:     lda     $99         ; new chrin
            cmp     #$02
            beq     rsget
            jmp     ochrin
ngetin:     ldx     $99         ; new getin
            lda     #$00
            cpx     #$02
            beq     rsget
            jmp     ogetin

rsget:      sta     $9e         ; input from modem
            sty     $97
            ldy     ridbs
            cpy     ridbe       ; buffer empty?
            beq     ret2        ; yes.
            lda     (ribuf),y   ; no, fetch character
            sta     $9e
            inc     ridbs
ret1:       clc                 ; cc = char in acc.
ret2:       ldy     $97
            lda     $9e
last:       rts                 ; cs = buffer was empty
