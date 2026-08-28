; TIA write registers

VSYNC  := $00 ; ---- --1- This address controls vertical sync time by writing D1 into the VSYNC latch.
VBLANK := $01 ; 76-- --1- 1=Start VBLANK, 6=Enable INPT4, INPT5 latches, 7=Dump INPT1,2,3,6 to ground
WSYNC  := $02 ; ---- ---- This address halts microprocessor by clearing RDY latch to zero. RDY is set true again by the leading edge of horizontal blank.
RSYNC  := $03 ; ---- ---- This address resets the horizontal sync counter to define the beginning of horizontal blank time, and is used in chip testing.
NUSIZ0 := $04 ; --54 -210 \ 0,1,2: player copys'n'size, 4,5: missile size: 2^x pixels
NUSIZ1 := $05 ; --54 -210 /
COLUP0 := $06 ; 7654 321- color player 0
COLUP1 := $07 ; 7654 321- color player 1
COLUPF := $08 ; 7654 321- color playfield
COLUBK := $09 ; 7654 321- color background
CTRLPF := $0a ; --54 -210 0=reflect playfield, 1=pf uses player colors, 2=playfield over sprites 4,5=ballsize:2^x
REFP0  := $0b ; ---- 3--- reflect player 0
REFP1  := $0c ; ---- 3--- reflect player 1
PF0    := $0d ; DCBA ---- \   Playfield bits: ABCDEFGHIJKLMNOPQRST
PF1    := $0e ; EFGH IJKL  >  normal:  ABCDEFGHIJKLMNOPQRSTABCDEFGHIJKLMNOPQRST
PF2    := $0f ; TSRQ PONM /   reflect: ABCDEFGHIJKLMNOPQRSTTSRQPONMLKJIHGFEDCBA
RESP0  := $10 ; ---- ---- \
RESP1  := $11 ; ---- ----  \
RESM0  := $12 ; ---- ----   > reset players, missiles and the ball. The object will begin its serial graphics at the time of a horizontal line at which the reset address occurs.
RESM1  := $13 ; ---- ----  /
RESBL  := $14 ; ---- ---- /
AUDC0  := $15 ; ---- 3210 audio control voice 0
AUDC1  := $16 ; ---- 3210 audio control voice 1
AUDF0  := $17 ; ---4 3210 frequency divider voice 0
AUDF1  := $18 ; ---4 3210 frequency divider voice 1
AUDV0  := $19 ; ---- 3210 audio volume voice 0
AUDV1  := $1a ; ---- 3210 audio volume voice 1
GRP0   := $1b ; 7654 3210 graphics player 0
GRP1   := $1c ; 7654 3210 graphics player 1
ENAM0  := $1d ; ---- --1- enable missile 0
ENAM1  := $1e ; ---- --1- enable missile 1
ENABL  := $1f ; ---- --1- enable ball
HMP0   := $20 ; 7654 ---- write data (horizontal motion values) into the horizontal motion registers
HMP1   := $21 ; 7654 ---- write data (horizontal motion values) into the horizontal motion registers
HMM0   := $22 ; 7654 ---- write data (horizontal motion values) into the horizontal motion registers
HMM1   := $23 ; 7654 ---- write data (horizontal motion values) into the horizontal motion registers
HMBL   := $24 ; 7654 ---- write data (horizontal motion values) into the horizontal motion registers
VDELP0 := $25 ; ---- ---0 delay player 0 by one vertical line
VDELP1 := $26 ; ---- ---0 delay player 1 by one vertical line
VDELBL := $27 ; ---- ---0 delay ball by one vertical line
RESMP0 := $28 ; ---- --1- keep missile 0 aligned with player 0
RESMP1 := $29 ; ---- --1- keep missile 1 aligned with player 1
HMOVE  := $2a ; ---- ---- This address causes the horizontal motion register values to be acted upon during the horizontal blank time in which it occurs.
HMCLR  := $2b ; ---- ---- This address clears all horizontal motion registers to zero (no motion).
CXCLR  := $2c ; ---- ---- clears all collision latches

; TIA read registers

CXM0P  := $30 ; xx00 0000    Read Collision  M0-P1   M0-P0
CXM1P  := $31 ; xx00 0000                    M1-P0   M1-P1
CXP0FB := $32 ; xx00 0000                    P0-PF   P0-BL
CXP1FB := $33 ; xx00 0000                    P1-PF   P1-BL
CXM0FB := $34 ; xx00 0000                    M0-PF   M0-BL
CXM1FB := $35 ; xx00 0000                    M1-PF   M1-BL
CXBLPF := $36 ; x000 0000                    BL-PF   -----
CXPPMM := $37 ; xx00 0000                    P0-P1   M0-M1
INPT0  := $38 ; x000 0000    Read Pot Port 0
INPT1  := $39 ; x000 0000    Read Pot Port 1
INPT2  := $3a ; x000 0000    Read Pot Port 2
INPT3  := $3b ; x000 0000    Read Pot Port 3
INPT4  := $3c ; x000 0000    Read Input (Trigger) 0
INPT5  := $3d ; x000 0000    Read Input (Trigger) 1

; RIOT

SWCHA  := $0280
SWACNT := $0281
SWCHB  := $0282
SWBCNT := $0283
INTIM  := $0284 ; Timer output
TIMINT := $0285

TIM1T    := $0294
TIM8T    := $0295
TIM64T   := $0296
TIM1024T := $0297
