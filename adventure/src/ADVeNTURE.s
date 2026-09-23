 .setcpu "6502"
 .include "vcs.inc"

;*******************************************************************************
;* Adventure for the Atari 2600, by Warren Robinett                            *
;* Copyright 1979 Atari, Inc.                                                  *
;*******************************************************************************
;* This disassembly was created by Joel D. Park in Jun 2002, based on an       *
;* earlier disassembly from Nov 1994.  This is a fairly straight conversion to *
;* SourceGen format; very little has been changed other than corrections to    *
;* spelling.                                                                   *
;*******************************************************************************
;* Project created by Andy McFadden, using 6502bench SourceGen v1.5.           *
;* Last updated 2020/01/17                                                     *
;*******************************************************************************
;* Ported to ca65 by Mike Murphy (mike@emu7800.net)                            *
;*******************************************************************************

; 2600 Memory Map
; ---------------
; 0000-007f TIA Mirrored every $100 [$000-$900]
; 0080-00ff PIA RAM Mirrored every $100 [$080-$980]
; 0180-01ff PIA Stack location, grows downward from $1ff, mapped into PIA RAM $80-$ff
; 0280-02ff PIA
; 0280      PIA SWCHA      RW Port A data register (joysticks...)
; 0281      PIA SWCHA DDR  0=input, 1=output (unused)
; 0282      PIA SWCHB      RW Port B data (console switches)
; 0283      PIA SWCHB DDR  0=input, 1=output (unused)
; 0284      PIA INTIM      R Timer output
; 0296      PIA TIM64T     W set 64 clock interval
; 1000-1fff ROM

.enum ColorType                         ; NTSC RGB Color
    black        = $00                  ; #000000
    darkgray     = $02                  ; #1a1a1a
    gray         = $06                  ; #5b5b5b
    lightgray    = $08                  ; #7e7e7e
    invisible    = ColorType::lightgray ; #7e7e7e
    lightergray  = $0a                  ; #a2a2a2
    lightestgray = $0c                  ; #c7c7c7
    white        = $0e                  ; #ededed
    yellow       = $1a                  ; #ccad00
    orange       = $28                  ; #cf6c00
    red          = $36                  ; #be3216
    purple       = $66                  ; #782df0
    blue         = $86                  ; #205efd
    lightblue    = $98                  ; #239dee
    turquoise    = $a8                  ; #1bb19e
    lightgreen   = $b8                  ; #28ba4c
    green        = $c8                  ; #49b509
    flash        = $cb                  ; #ffffff
    darkgreen    = $d8                  ; #76a300
    darkyellow   = $e8                  ; #a88800
.endenum

.enum RoomControlType   ; leftwall    rightwall   bl4 size    pfpriority  pfreflect
    leftthinwall_pfref  = %10000000             | %00100000             | %00000001
    rightthinwall_pfref =             %01000000 | %00100000             | %00000001
    pfref               =                         %00100000             | %00000001
    pfref_pfp           =                         %00100000 | %00000100 | %00000001
    pfp                 =                         %00100000 | %00000100
.endenum

; Values are offsets against RESP0 and HMP0
.enum SpriteType
    object1       = 0 ; RESxx/HMxx P0
    object2       = 1 ; RESxx/HMxx P1
    leftthinwall  = 2 ; RESxx/HMxx M0
    rightthinwall = 3 ; RESxx/HMxx M1
    man           = 4 ; RESxx/HMxx BL
.endenum

; Values are dependent upon RIOT SWCHB
.enum ConsoleSwitchType
    reset             = %00000001 ; 0=pressed
    select            = %00000010 ; 0=pressed
    select_and_reset  = %00000011
    bw                = %00001000 ; 0=bw 1=color
    leftdifficulty    = %01000000 ; 0=amateur (b) 1=pro (a)
    rightdifficulty   = %10000000 ; 0=amateur (b) 1=pro (a)
.endenum

.enum NoiseType
    game_over   = 0
    dragon_roar = 1
    man_eaten   = 2
    dragon_died = 3
    drop_item   = 4
    get_item    = 5
.endenum

.enum DragonState
    normal   = 0
    dead     = 1
    ateman   = 2
    roaring  = 255
.endenum

.enum PortState
    open           = 1
    closed         = 28
    wraparound_max = 56
.endenum

.enum MoveTypes
    none   = 0
    up     = %00010000
    down   = %00100000
    left   = %01000000
    right  = %10000000
.endenum

.struct RoomType
    gfx_ptr       .word
    color         .byte ; ColorType enum
    bw_color      .byte ; ColorType enum
    pf_control    .byte
    room_up       .byte
    room_right    .byte
    room_down     .byte
    room_left     .byte
.endstruct

.struct PlayerPosType
    xcoord        .byte
    ycoord        .byte
.endstruct

.struct DynamicType
    room          .byte
    xcoord        .byte
    ycoord        .byte
    move          .byte
    state         .byte
    carriedobject .byte
    fedup         .byte
.endstruct

.struct StateType
    state         .byte
    xcoord        .byte
    ycoord        .byte
.endstruct

.struct ObjectType
    dynamic_ptr   .word  ; pointer to a DynamicType
    currstate_ptr .word  ; pointer to a state byte
    states_ptr    .word  ; pointer to array of StateType
    color         .byte  ; ColorType
    bw_color      .byte  ; ColorType
    size          .byte
.endstruct


.zeropage   ; segment mapped to $80

roomgfx_base:                   .word 0
p0gfx_base:                     .word 0
p1gfx_base:                     .word 0
player0pos:                     .byte 0, 0
player1pos:                     .byte 0, 0
ManDynamic:                     .byte 0, 0, 0
man_y2:                         .byte 0     ; man's adjusted y coordinate?
scan_line:                      .byte 0     ; current scan line
roomgfx_offset:                 .byte 0     ; room graphics offset
p0gfx_offset:                   .byte 0     ; player00 graphics offset
p1gfx_offset:                   .byte 0     ; player01 graphics offset
cached_swchb:                   .byte 0     ; cached console switches
dr_ptr:                         .word 0     ; pointer for dereferencing
object1:                        .byte 0
object2:                        .byte 0
obj_collided_with:              .byte 0
unused1:                        .byte 0
cached_joystick:                .byte 0
portcullis_number:              .byte 0
direction_wanted:               .byte 0
obj_counter:                    .byte 0
object_carried:                 .byte 0     ; object carried by the man
objman_x_delta:                 .byte 0
objman_y_delta:                 .byte 0
curr_obj_number:                .byte 0

GameObjectsWorkingArea:
DotDynamic:                     .byte 0, 0, 0
RedDragonDynamic:               .byte 0, 0, 0, 0, 0
YellowDragonDynamic:            .byte 0, 0, 0, 0, 0
GreenDragonDynamic:             .byte 0, 0, 0, 0, 0
MagnetDynamic:                  .byte 0, 0, 0
SwordDynamic:                   .byte 0, 0, 0
ChaliceDynamic:                 .byte 0, 0, 0
BridgeDynamic:                  .byte 0, 0, 0
YellowKeyDynamic:               .byte 0, 0, 0
WhiteKeyDynamic:                .byte 0, 0, 0
BlackKeyDynamic:                .byte 0, 0, 0
PortCurrStateBase:              .byte 0, 0, 0
BlackBatDynamic:                .byte 0, 0, 0, 0, 0, 0, 0

objstore_ptr:                   .word 0
objdelta:                       .byte 0
MoveGameObjectArg_ObjNumber:    .byte 0      ; identifies the object to move (used by MoveGameObject)
MoveGameObjectArg_Difficulty:   .byte 0      ; difficulty for MoveGameObject to use (used by MoveGameObject)
joystick_record:                .byte 0
tmp1:                           .byte 0
SurroundDynamic:                .byte 0, 0, 0
GetObjectState_Arg:             .byte 0
NumberCurrState:                .byte 0      ; 0=lvl1, 2=lvl2, 4=lvl3
is_game_complete:               .byte 0      ; $ff=yes, 0=no
sound_duration_counter:         .byte 0
sound_type:                     .byte 0      ; NoiseType
linked_obj_index:               .byte 0
PrevManDynamic:                 .byte 0, 0, 0
input_counter:                  .word 0

stack_space:                    ; $e7-$ff (12 frames)

.code

;; Render visible portion of screen
PrintDisplay:
            sta HMCLR       ;clear horizontal motion
            lda player0pos+PlayerPosType::xcoord
            ldx #SpriteType::object1
            jsr PosSpriteX
            lda player1pos+PlayerPosType::xcoord
            ldx #SpriteType::object2
            jsr PosSpriteX
            lda ManDynamic+DynamicType::xcoord
            ldx #SpriteType::man
            jsr PosSpriteX
            sta WSYNC       ;wait for horizontal blank
            sta HMOVE       ;apply horizontal motion
            sta CXCLR       ;clear collision latches
            lda ManDynamic+DynamicType::ycoord
            sec
            sbc #4                    ;and adjust it by four scan lines
            sta man_y2                ; for printing (so Y coordinate specifies middle)

; Spin until middle of line offset 34 (64t timer previously set to 42, 35.4 lines)
:           lda INTIM
            bne :-

; Line offset 34, 162-174 color clocks
            lda #0
            sta p0gfx_offset          ;set Player0 definition index
            sta p1gfx_offset          ;set Player1 definition index
            sta roomgfx_offset        ;set room definition index
            sta GRP1                  ;clear any graphics for Player1
            lda #1
            sta VDELP1                ;vertically delay Player1
            lda #104                  ;(104-8)*2 = 192 visible scanlines
            sta scan_line

; Set top line of room, spills over to line offset 35
            ldy roomgfx_offset        ;get room definition index
            lda (roomgfx_base),y      ;get first room definition byte
            sta PF0                   ; and display
            iny
            lda (roomgfx_base),y      ;get next room definition byte
            sta PF1                   ; and display
            iny
            lda (roomgfx_base),y      ;get last room definition byte
            sta PF2                   ; and display
            iny
            sty roomgfx_offset        ;save for next time
            sta WSYNC                 ;wait for horizontal blank

; Picture start, line offset 36
            lda #0
            sta VBLANK                ;turn off VBLANK
            jmp @PrintPlayer0

; Print Player1 (Object2)
@PrintPlayer1:
            lda scan_line
            sec                       ;have we reached Object2's Y coordinate?
            sbc player1pos+PlayerPosType::ycoord
            sta WSYNC                 ;wait for horizontal blank
            bpl @PrintPlayer0         ;if not, branch
            ldy p1gfx_offset          ;get the Player1 definition index
            lda (p1gfx_base),y        ;get the next Player1 definition byte
            sta GRP1                  ; and display
            beq @PrintPlayer0         ;if zero then definition finished
            inc p1gfx_offset          ;goto next Player1 definition byte

; Print Player0 (Object1), Ball (Man), and Room
@PrintPlayer0:
            ldx #0
            lda scan_line
            sec                      ;have we reached the Object1's Y coordinate?
            sbc player0pos+PlayerPosType::ycoord
            bpl :+                   ;if not then branch
            ldy p0gfx_offset         ;get Player0 definition index
            lda (p0gfx_base),y       ;get the next Player0 definition byte
            tax
            beq :+                   ;if zero then definition finished
            inc p0gfx_offset         ;go to next Player0 definition byte
:           ldy #0                   ;disable Ball graphic
            lda scan_line
            sec                      ;have we reached the Man's
            sbc man_y2               ; Y coordinate?
            and #$fc                 ;mask value to four either side (getting depth of 8)
            bne :+                   ;if not, branch
            ldy #2                   ;enable Ball graphic
:           lda scan_line
            and #15                  ;have we reached a sixteenth scan line?
            bne :++                  ;if not, branch
            sta WSYNC                ;wait for horizontal blank
            sty ENABL                ;enable Ball (if wanted)
            stx GRP0                 ;display Player0 definition byte (if wanted)
            ldy roomgfx_offset       ;get room definition index
            lda (roomgfx_base),y     ;get first room definition byte
            sta PF0                  ; and display
            iny
            lda (roomgfx_base),y     ;get next room definition byte
            sta PF1                  ; and display
            iny
            lda (roomgfx_base),y     ;get last room definition byte
            sta PF2                  ; and display
            iny
            sty roomgfx_offset       ;save for next time
:           dec scan_line            ;goto next scan line
            lda scan_line
            cmp #8                   ;have we reached to within 8 scanlines of the bottom?
            bpl @PrintPlayer1        ;if not, branch

            sta WSYNC                ;added this here to cleanly end picture on line offset 230 in exchange for losing 52 CPU cycles
            sta VBLANK

            jmp @PrintDone

; Print Player0 (Object1) and Ball (Man)
:           sta WSYNC                ;wait for horizontal blank
            sty ENABL                ;enable ball (if wanted)
            stx GRP0                 ;display Player0 definition byte (if wanted)
            jmp :--

@PrintDone: lda #0
            sta GRP1                 ;clear any graphics for Player1
            sta GRP0                 ;clear any graphics for Player0
            lda #32                  ;set clock interval to 32*(64*3)/228 = 26.9 scanlines
            sta TIM64T
            rts

; Position Sprite Horizontally
; x=sprite, a=horizontal position
;                                      2
;         6       6       7            2
; 0       0       8       5            8
; |--...--|-------+-------|-------...--|
;
; 68 is the start of the visible scan line.
; Minimum delay possible is 75: 4*15 + RESxx(15) = 5*15 = 75
;
PosSpriteX: ldy #2              ;start with 2*15=30 color clocks
            sec
:           iny                 ;add another 15 color clocks (45 total so far)
            sbc #15             ;divide by 15 to get coarse position in a multiple of 15
            bcs :-
            eor #$ff            ;make remainder positive by flipping bits here
            ;   +1                and adding 1 here
            ;   -8               translate range [1,15] to hmove range [-7,7]
            ;  ===                by subtracting 8
            ;   -7
            ;   +1               already subtracting 1 with cleared carry bit
            ;  ===
            sbc #6
            asl a               ;move to high nybble for TIA horizontal motion
            asl a
            asl a
            asl a
            sty WSYNC           ;wait for horizontal blank
:           dey                 ;count down (y+1)*15 color clocks
            bpl :-
            .assert .hibyte (* - 1) = .hibyte (:-), error, "Last two instructions must be on same page."
            sta RESP0,x         ;reset sprite, positioning it coarsely (adds ~15 color clocks)
            sta HMP0,x          ;set horizontal (fine) motion of sprite
            rts

;; Handle vertical sync

DoVSYNC:

; Spin until middle of line offset 255 (64t timer previously set to 32, 26.9 lines)

            lda INTIM           ;get timer output
            bne DoVSYNC         ;wait for time-out

; Line offset 255, 159-165 color clocks

            lda #%10
            sta WSYNC           ;wait for horizontal blank
            sta VBLANK          ;turn on VBLANK, line offset 256
            sta WSYNC           ;line offset 257
            sta WSYNC           ;line offset 258
            sta WSYNC           ;line offset 259
            sta VSYNC           ;start vertical sync
            sta WSYNC           ;line offset 260
            sta WSYNC           ;line offset 261
            lda #0
            sta WSYNC           ;line offset 262
            sta VSYNC           ;end vertical sync, line offset 0
            lda #42             ;set clock interval to 42*(64*3)/228 = 35.4 scanlines
            sta TIM64T          ; count down next frame
            rts

;; Set up a room for print
SetupRoomPrint:
            lda ManDynamic+DynamicType::room
            jsr RoomNumToAddress  ;convert to room address in dr_ptr
            ldy #RoomType::gfx_ptr
            lda (dr_ptr),y
            sta roomgfx_base
            ldy #RoomType::gfx_ptr+1
            lda (dr_ptr),y        ;get high pointer to room graphics
            sta roomgfx_base+1
; check B&W switch for room graphics
            lda SWCHB             ;get console switches
            and #ConsoleSwitchType::bw
            beq :+
; use color
            ldy #RoomType::color
            lda (dr_ptr),y
            jsr ChangeColor       ;change if necessary
            sta COLUPF            ;put in playfield color register
            jmp :++
; use b&w
:           ldy #RoomType::bw_color
            lda (dr_ptr),y
            jsr ChangeColor       ;change if necessary
            sta COLUPF            ;put in the playfield color register
; color background
:           lda #ColorType::lightgray
            jsr ChangeColor       ;change if necessary
            sta COLUBK            ;background color register
; playfield control
            ldy #RoomType::pf_control
            lda (dr_ptr),y
            sta CTRLPF            ;playfield control register
            and #$c0              ;get the wall flags
            lsr a
            lsr a
            lsr a                 ;get the first bit into position
            lsr a
            lsr a
            sta ENAM1             ;enable right hand thin wall (if wanted - Missile01)
            lsr a
            sta ENAM0             ;enable left hand thin wall (if wanted - Missile00)
; get objects to display
            jsr CacheObjects      ;get next two objects to display
; sort out their order
            lda object1
            cmp #objoffset_InvisibleSurround
            beq SwapPrintObjects  ; then branch to swap (we want it was Player1)
            cmp #objoffset_Bridge
            bne SetupObjectPrint  ; swap the objects (we want it as Player1)
            lda object2
            cmp #objoffset_InvisibleSurround
            beq SetupObjectPrint  ; (we want it as Player1)
SwapPrintObjects:
            lda object1
            sta tmp1
            lda object2
            sta object1
            lda tmp1
            sta object2
; setup Object1 to print
SetupObjectPrint:
            ldx object1
            lda Objects+ObjectType::dynamic_ptr,x
            sta dr_ptr
            lda Objects+ObjectType::dynamic_ptr+1,x
            sta dr_ptr+1
            ldy #DynamicType::xcoord
            lda (dr_ptr),y        ;get Object1's X coordinate
            sta player0pos+PlayerPosType::xcoord  ; and store for print
            ldy #DynamicType::ycoord
            lda (dr_ptr),y        ;get Object1's Y coordinate
            sta player0pos+PlayerPosType::ycoord  ; and store for print
            lda Objects+ObjectType::currstate_ptr,x
            sta dr_ptr
            lda Objects+ObjectType::currstate_ptr+1,x
            sta dr_ptr+1
            ldy #0
            lda (dr_ptr),y        ;retrieve Object1's current state
            sta GetObjectState_Arg
            lda Objects+ObjectType::states_ptr,x
            sta dr_ptr
            lda Objects+ObjectType::states_ptr+1,x
            sta dr_ptr+1
            jsr GetObjectState    ;find current state in the state information
            iny                   ;index to the state's corresponding graphic pointer
            lda (dr_ptr),y        ;get Object1's low graphic address
            sta p0gfx_base        ; and store for print
            iny
            lda (dr_ptr),y        ;get Object1's high graphic address
            sta p0gfx_base+1      ; and store for print
; check B&W for Object1
            lda SWCHB             ;get console switches
            and #ConsoleSwitchType::bw
            beq :+
; color
            lda Objects+ObjectType::color,x
            jsr ChangeColor       ;change if necessary
            sta COLUP0            ; and set color luminance00
            jmp :++
; B&W
:           lda Objects+ObjectType::bw_color,x
            jsr ChangeColor       ;change if necessary
            sta COLUP0            ;set color luminance00
; Object1 resize
:           lda Objects+ObjectType::size,x
            ora #$10              ;and set to larger size if necessary
            sta NUSIZ0            ;(used by bridge and invisible surround)
; set up Object2 to print
            ldx object2
            lda Objects+ObjectType::dynamic_ptr,x
            sta dr_ptr
            lda Objects+ObjectType::dynamic_ptr+1,x
            sta dr_ptr+1
            ldy #DynamicType::xcoord
            lda (dr_ptr),y        ;get Object2's X coordinate
            sta player1pos+PlayerPosType::xcoord  ; and store for print
            ldy #DynamicType::ycoord
            lda (dr_ptr),y        ;get Object2's Y coordinate
            sta player1pos+PlayerPosType::ycoord  ; and store for print
            lda Objects+ObjectType::currstate_ptr,x
            sta dr_ptr
            lda Objects+ObjectType::currstate_ptr+1,x
            sta dr_ptr+1
            ldy #0
            lda (dr_ptr),y        ;retrieve Object2's current state
            sta GetObjectState_Arg
            lda Objects+ObjectType::states_ptr,x
            sta dr_ptr
            lda Objects+ObjectType::states_ptr+1,x
            sta dr_ptr+1
            jsr GetObjectState    ;find the current state in the state information
            iny                   ;index to the state's corresponding graphic pointer
            lda (dr_ptr),y
            sta p1gfx_base        ;get Object2's low graphic address
            iny
            lda (dr_ptr),y        ;get Object2's high graphic address
            sta p1gfx_base+1
; check B&W for Object2
            lda SWCHB             ;get console switches
            and #ConsoleSwitchType::bw
            beq :+
; color
            lda Objects+ObjectType::color,x
            jsr ChangeColor       ;change if necessary
            sta COLUP1            ;and set color luminance01
            jmp :++
; B&W
:           lda Objects+ObjectType::bw_color,x
            jsr ChangeColor       ;change if necessary
            sta COLUP1            ;and set color luminance01
; Object2 size
:           lda Objects+ObjectType::size,x
            ora #$10              ;and set to large size if necessary
            sta NUSIZ1            ;(used by bridge and invisible surround)
            rts

; fill cache with two objects in this room
CacheObjects:
            ldy obj_counter       ;get last object
            lda #objoffset_Null
            sta object1
            sta object2
MoveNextObject:
            tya
            clc                   ;goto the next object to check
            adc #.sizeof(ObjectType)
            cmp #objoffset_Null
            bcc GetObjectsInfo
            lda #0                ;if so, wrap to zero
GetObjectsInfo:
            tay
            lda Objects+ObjectType::dynamic_ptr,y
            sta dr_ptr
            lda Objects+ObjectType::dynamic_ptr+1,y
            sta dr_ptr+1
            ldx #0
            lda (dr_ptr,x)          ;get object's current room
            cmp ManDynamic+DynamicType::room  ; is it in this room?
            bne CheckForMoreObjects ;if not lets try next object (branch)
            lda object1             ;check first slot
            cmp #objoffset_Null
            bne StoreObjectToPrint  ; then branch
            sty object1             ;store this object's number to print
            jmp CheckForMoreObjects ; and try for more

StoreObjectToPrint:
            sty object2           ;store this object's number to print
            jmp StoreCount        ; and then give up - no slots free

CheckForMoreObjects:
            cpy obj_counter       ;have we done all the objects?
            bne MoveNextObject    ;if not, continue
StoreCount: sty obj_counter       ;if so, store current count
            rts                   ; for next time

; convert room number in accumulator to room address in dr_ptr
RoomNumToAddress:
            .assert .sizeof(RoomType) = 9, error, "This subroutine assumes RoomType is 9 bytes long."
            sta tmp1              ;store room number wanted
            sta dr_ptr
            lda #0                ;zero the high byte of the
            sta dr_ptr+1          ; offset
            clc
            rol dr_ptr
            rol dr_ptr+1          ;multiply room number by eight
            rol dr_ptr
            rol dr_ptr+1
            rol dr_ptr
            rol dr_ptr+1
            lda tmp1              ;get the original room number
            clc
            adc dr_ptr
            sta dr_ptr            ;and add it to the offset
            lda #0
            adc dr_ptr+1          ;in effect the room number is
            sta dr_ptr+1          ; multiplied by nine
            lda #<Rooms
            clc
            adc dr_ptr            ;add the room data base address
            sta dr_ptr            ; to the offset therefore getting
            lda #>Rooms           ; the final room data address
            adc dr_ptr+1
            sta dr_ptr+1
            rts

; Get pointer to current state
; input dr_ptr, returning offset in y
GetObjectState:
            ldy #0
            lda GetObjectState_Arg
:           cmp (dr_ptr),y        ;have we found it in the list of states?
            bcc :+                ;if nearing it then found it and return
            beq :+                ;if found it then return
            .assert .sizeof(StateType) = 3, error, "This subroutine assumes StateType is 3 bytes long."
            iny                   ;goto next state in list of states
            iny
            iny
            jmp :-
:           rts

;; Maintain input_counter, clearing high byte when input has been detected (captures randomness)
MaintainInputCounter:
            inc input_counter
            bne :+
            inc input_counter+1
            bne :+
            lda #$80              ;wrap the high input_counter (indicating timeout) if needed
            sta input_counter+1
:           lda SWCHA               ;get joystick values
            cmp #<~MoveTypes::none  ;if any movement then branch
            bne :+
            lda SWCHB               ;get the console switches
            and #ConsoleSwitchType::select_and_reset
            cmp #ConsoleSwitchType::select_and_reset ;have either of them been used?
            beq :++               ;if no usage then branch
:           lda #0                ;zero the high input_counter if the
            sta input_counter+1   ; switches or joystick have been used
:           rts

; change color if necessary
ChangeColor:
            .assert (ColorType::flash & 2) = 2, error, "Bad ColorType::flash value."
            lsr a                 ;if bit 0 of the color is set
            bcc :+                ; branch if clear, no flash
            lda input_counter     ;flash
:           ldy input_counter+1   ;get the high input counter
            bpl :+                ;if console/joystick moved recently then branch
            eor input_counter+1   ;vary colors after a period of inactivty to limit CRT burn in
            and #$fb              ; turn down the luminance
:           asl a                 ; and restore original color if necessary
            rts

; get the address of the dynamic information for an object
GetObjectAddress:
            lda Objects+ObjectType::dynamic_ptr,x
            sta dr_ptr            ;get and store the low address
            lda Objects+ObjectType::dynamic_ptr+1,x
            sta dr_ptr+1          ;get and store the high address
            rts

;; Game entry point
StartGame:  sei                   ;disable interrupts
            cld
            ldx #$28              ;clear TIA registers $04-$2c
            lda #0                ; i.e. blank
:           sta 4,x               ; everything and turn
            dex                   ; everything off
            bpl :-
            txs                   ;reset stack to $ff
:           sta 0,x               ;clear $80 to $ff user vars
            dex
            bmi :-
            jsr ThinWalls         ;position the thin walls (missiles)
            jsr SetupRoomObjects  ;set up objects rooms and positions

;; Top of game loop
MainGameLoop:
            jsr CheckGameStart
            jsr MakeSound
            jsr MaintainInputCounter
            lda is_game_complete  ;ff = yes
            bne NonActiveLoop
            lda ChaliceDynamic+DynamicType::room
            cmp #roomnum_YellowCastleEntry  ;is it inside the yellow castle?
            bne :+                ;if not branch
            lda #$ff
            sta sound_duration_counter  ;set the note count to maximum
            sta is_game_complete  ;complete the game since chalice is returned
            lda #NoiseType::game_over
            sta sound_type
:           ldy #0                ;allow joystick read - all movement
            jsr BallMovement      ;check ball collisions and move ball
            jsr MoveCarriedObject ;move the carried object
            jsr DoVSYNC           ;wait for VSYNC

            jsr SetupRoomPrint    ;set up the room and objects for display
            jsr PrintDisplay      ;display the room and objects
            jsr PickupPutdown     ;deal with object pickup and putdown
            ldy #1                ;disallow joystick read - move vertically only
            jsr BallMovement      ;check ball collisions and move ball
            jsr Surround          ;deal with invisible surround moving
            jsr DoVSYNC           ;wait for VSYNC

            jsr MoveBat           ;move and deal with bat
            jsr Portals           ;move and deal with portcullises
            jsr PrintDisplay      ;display the room and objects
            jsr MoveGreenDragon   ;move and deal with the green dragon
            jsr MoveYellowDragon  ;move and deal with the yellow dragon
            jsr DoVSYNC           ;wait for VSYNC

            ldy #2                ;disallow joystick read/bridge check - move horizontally only
            jsr BallMovement      ;check ball collisions and move ball
            jsr MoveRedDragon     ;move and deal with red dragon
            jsr Mag               ;deal with the magnet
            jsr PrintDisplay      ;display the room and objects
            jmp MainGameLoop

; non-active game loop
NonActiveLoop:
            jsr DoVSYNC           ;wait for VSYNC
            jsr PrintDisplay      ;display the room and objects
            jsr SetupRoomPrint    ;set up room and objects for display
            jmp MainGameLoop

ThinWalls:  lda #13
            ldx #SpriteType::leftthinwall
            jsr PosSpriteX
            lda #150
            ldx #SpriteType::rightthinwall
            jsr PosSpriteX
            sta WSYNC             ;wait for horizontal blank
            sta HMOVE             ;apply the horizontal move
            rts

;; Check console switches if game should be started
CheckGameStart:
            lda SWCHB             ;get the console switches
            eor #$ff              ;flip (as reset active low)
            and cached_swchb      ;compare with what was before
            and #ConsoleSwitchType::reset
            beq NotReset          ;if no reset then branch
            lda is_game_complete
            cmp #$ff
            beq SetupRoomObjects  ;branch since game has been completed

; Reincarnate player
            lda #roomnum_YellowCastle
            sta ManDynamic+DynamicType::room                    ;make it the current room
            sta PrevManDynamic+DynamicType::room                ;make it the previous room
            lda #80
            sta ManDynamic+DynamicType::xcoord                  ;make it the current man X coordinate
            sta PrevManDynamic+DynamicType::xcoord              ;make it the previous man X coordinate
            lda #32
            sta ManDynamic+DynamicType::ycoord                  ;make it the current man Y coordinate
            sta PrevManDynamic+DynamicType::ycoord              ;make it the previous man Y coordinate
            lda #0
            sta RedDragonDynamic+DynamicType::state             ;set the red dragon's state to OK
            sta YellowDragonDynamic+DynamicType::state          ;set the yellow dragon's state to OK
            sta GreenDragonDynamic+DynamicType::state           ;set the green dragon's state to OK
            sta sound_duration_counter  ;set the note count to zero
            lda #objoffset_Null
            sta object_carried

NotReset:   lda SWCHB             ;get the console switches
            eor #$ff              ;flip (as select active low)
            and cached_swchb      ;compare with what was before
            and #ConsoleSwitchType::select
            beq NotSelect         ;branch if select not being used
            lda ManDynamic+DynamicType::room  ;get the current room
            cmp #roomnum_NumberRoom
            bne SetupRoomObjects  ;branch if not
            lda NumberCurrState   ;increment the level
            clc                   ; number (by two)
            adc #2
            cmp #6                ;have we reached the maximum?
            bcc ResetSetup
            lda #0                ;if yep then set back to zero
ResetSetup: sta NumberCurrState   ;store the new level number
SetupRoomObjects:
            lda #roomnum_NumberRoom
            sta ManDynamic+DynamicType::room
            sta PrevManDynamic+DynamicType::room
            lda #0                ;set man ycoord to 0 so can't be seen
            sta ManDynamic+DynamicType::ycoord
            sta PrevManDynamic+DynamicType::ycoord
            ldy NumberCurrState    ;get the level number
            lda GameObjectLocations,y     ;get the low pointer to object locations
            sta dr_ptr
            lda GameObjectLocations+1,y   ;get the high pointer to object locations
            sta dr_ptr+1
            ldy #(Game1ObjectLocationsEnd - Game1ObjectLocations)  ;copy all the objects dynamic information
:           lda (dr_ptr),y                ; (the rooms and positions) into the working area
            sta GameObjectsWorkingArea,y
            dey
            bpl :-
            lda NumberCurrState   ;get the level number
            cmp #4                ;branch if level one
            bcc :+                ;or two (where all objects are in defined areas)
            jsr RandomizeLevel3   ;put some objects in random rooms
            jsr DoVSYNC           ;wait for VSYNC
            jsr PrintDisplay      ;display rooms and objects
:           lda #0                ;signal that the game has started
            sta is_game_complete
            lda #objoffset_Null
            sta object_carried
NotSelect:
            lda SWCHB             ;store the current console switches
            sta cached_swchb
            rts

; put objects in random rooms for level 3
RandomizeLevel3:
            ldy #3*((Lvl3ObjRoomBoundsEnd-Lvl3ObjRoomBounds)/3 - 1)
:           lda input_counter          ;  get the low input counter as seed
            lsr a
            lsr a
            lsr a                      ;generate a pseudo-random
            lsr a                      ; room number
            lsr a
            sec
            adc input_counter          ;store the low input counter
            sta input_counter
            and #$1f                   ;trim so represents a room value
            cmp Lvl3ObjRoomBounds+1,y  ;if it is less than the
            bcc :-                     ; lower bound for object then get another
            cmp Lvl3ObjRoomBounds+2,y  ;if it equals or is
            beq :+                     ; less than the higher bound for object
            bcs :-                     ; then continue (branch if higher)
:           ldx Lvl3ObjRoomBounds,y    ;get the object-room index value
            sta DynamicType::room,x    ;store the new room value
            dey
            dey                        ;goto the next object
            dey
            bpl :--                    ;until all done
            rts

; Object randomization room bounds data for level 3.
Lvl3ObjRoomBounds:
            .byte ChaliceDynamic,      roomrange_chalice_start,      roomrange_chalice_end
            .byte RedDragonDynamic,    roomrange_reddragon_start,    roomrange_reddragon_end
            .byte YellowDragonDynamic, roomrange_yellowdragon_start, roomrange_yellowdragon_end
            .byte GreenDragonDynamic,  roomrange_greendragon_start,  roomrange_greendragon_end
            .byte SwordDynamic,        roomrange_sword_start,        roomrange_sword_end
            .byte BridgeDynamic,       roomrange_bridge_start,       roomrange_bridge_end
            .byte YellowKeyDynamic,    roomrange_yellowkey_start,    roomrange_yellowkey_end
            .byte WhiteKeyDynamic,     roomrange_whitekey_start,     roomrange_whitekey_end
            .byte BlackKeyDynamic,     roomrange_blackkey_start,     roomrange_blackkey_end
            .byte BlackBatDynamic,     roomrange_bat_start,          roomrange_bat_end
            .byte MagnetDynamic,       roomrange_magnet_start,       roomrange_magnet_end
Lvl3ObjRoomBoundsEnd:

GameObjectLocations:
            .word Game1ObjectLocations
            .word Game2ObjectLocations
            .word Game2ObjectLocations

.assert (Game1ObjectLocationsEnd - Game1ObjectLocations) = (Game2ObjectLocationsEnd - Game2ObjectLocations), error, "Game object locations sizes not equal"

; object locations (room and coordinates) for game 1
Game1ObjectLocations:
;                 Location                                X    Y    Mvt   State   Object
            .byte roomnum_BlackMaze3,                    81,  18                  ;black dot
            .byte roomnum_TopEntryRoom1,                 80,  32,    0,   0       ;red dragon
            .byte roomnum_BelowYellowCastleLeftThinWall, 80,  32,    0,   0       ;yellow dragon
            .byte roomnum_TopEntryRoom2,                 80,  32,    0,   0       ;green dragon
            .byte roomnum_BlackCastleEntry,             128,  32                  ;magnet
            .byte roomnum_YellowCastleEntry,             32,  32                  ;sword
            .byte roomnum_OtherPurpleRoom,               48,  32                  ;chalice
            .byte roomnum_BlueMazeTop,                   41,  55                  ;bridge
            .byte roomnum_YellowCastle,                  32,  64                  ;yellow key
            .byte roomnum_TopEntryRoom1,                 32,  64                  ;white key
            .byte roomnum_TopEntryRoom2,                 32,  64                  ;black key
            .byte roomnum_OtherPurpleRoom                                         ;portcullis state
            .byte roomnum_OtherPurpleRoom                                         ;portcullis state
            .byte roomnum_OtherPurpleRoom                                         ;portcullis state
            .byte roomnum_WhiteCastleEntry,              32,  32,    0,   0       ;bat
            .byte $78                                                             ;bat (carrying, fed-up)
Game1ObjectLocationsEnd:
Game2ObjectLocations:
;                 Location                                X    Y   Mvt    State   Object
            .byte roomnum_BlackMaze3,                    81,  18                  ;black dot
            .byte roomnum_BlackMaze2,                    80,  32,  $a0,   0       ;red dragon
            .byte roomnum_RedMazeBottom,                 80,  32,  $a0,   0       ;yellow dragon
            .byte roomnum_BlueMazeTop,                   80,  32,  $a0,   0       ;green dragon
            .byte roomnum_TopEntryRoom1,                128,  32                  ;magnet
            .byte roomnum_YellowCastle,                  32,  32                  ;sword
            .byte roomnum_BlackMaze2,                    48,  32                  ;chalice
            .byte roomnum_MazeSide,                      64,  64                  ;bridge
            .byte roomnum_MazeMiddle,                    32,  64                  ;yellow key
            .byte roomnum_BlueMazeBottom,                32,  64                  ;white key
            .byte roomnum_RedMazeBottom,                 32,  64                  ;black key
            .byte roomnum_OtherPurpleRoom                                         ;portcullis state
            .byte roomnum_OtherPurpleRoom                                         ;portcullis state
            .byte roomnum_OtherPurpleRoom                                         ;portcullis state
            .byte roomnum_BelowYellowCastle,             32,  32,  $90,   0       ;bat
            .byte $78                                                             ;bat (carrying, fed-up)
Game2ObjectLocationsEnd:

;; Check ball (man) collisions and move ball
BallMovement:
            lda CXBLPF
            and #%10000000        ;get ball-playfield collision
            bne PlayerCollision   ;branch if collision (player-wall)
            lda CXM0FB
            and #%01000000        ;get ball-missile0 collision
            bne PlayerCollision   ;branch if collision (player-left thin)
            lda CXM1FB
            and #%01000000        ;get ball-missile1 collision
            beq :+                ;branch if no collision
            lda object2           ;if Object2 (to print) is
            cmp #$87              ; not the black dot then collide
            bne PlayerCollision
:           lda CXP0FB
            and #%01000000        ;get ball-player0 collision
            beq :+                ;if no collision then branch
            lda object1           ;if Object1 (to print is)
            cmp #0                ; not the invisible surround then
            bne PlayerCollision   ; branch (collision)
:           lda CXP1FB
            and #%01000000        ;get ball-player1 collision
            beq NoCollision       ;if no collision then branch
            lda object2           ;if player 01 to print is
            cmp #0                ; not the invisible surround then
            bne PlayerCollision   ; branch (collision)
            jmp NoCollision

; player collided (with something)
PlayerCollision:
            cpy #2                ;are we checking for the bridge?
            bne ReadStick         ;if not, branch
            lda object_carried
            cmp #objoffset_Bridge
            beq ReadStick
            lda ManDynamic+DynamicType::room
            cmp BridgeDynamic     ;is the bridge in this room?
            bne ReadStick         ;if not branch
; check going through the bridge
            lda ManDynamic+DynamicType::xcoord
            sec
            sbc BridgeDynamic+DynamicType::xcoord
            cmp #10               ;if < 10 or > 23 then forget it
            bcc ReadStick
            cmp #23
            bcs ReadStick
            lda z:BridgeDynamic+DynamicType::ycoord
            sec
            sbc ManDynamic+DynamicType::ycoord
            cmp #252
            bcs NoCollision       ;if < -4 then going through bridge
            cmp #25               ;if > 25 then forget it
            bcs ReadStick
; no collision (and going through bridge)
NoCollision:
            lda #<~MoveTypes::none ;reset the joystick input
            sta cached_joystick
            lda ManDynamic+DynamicType::room
            sta PrevManDynamic+DynamicType::room
            lda ManDynamic+DynamicType::xcoord
            sta PrevManDynamic+DynamicType::xcoord
            lda ManDynamic+DynamicType::ycoord
            sta PrevManDynamic+DynamicType::ycoord
ReadStick:  cpy #0                ;allow joystick read - all movement
            bne :+                ;if not, don't bother with joystick read
            lda SWCHA             ;read joysticks
            sta cached_joystick
:           lda PrevManDynamic+DynamicType::room
            sta ManDynamic+DynamicType::room
            lda PrevManDynamic+DynamicType::xcoord
            sta ManDynamic+DynamicType::xcoord
            lda PrevManDynamic+DynamicType::ycoord
            sta ManDynamic+DynamicType::ycoord
            lda cached_joystick        ;get the joystick position
            ora JoystickMergeValues,y  ;merge out movement not allowed in this phase
            sta direction_wanted       ;and store cooked movement
            ldy #3                     ;set the delta for the man
            ldx #ManDynamic            ;point to man's coordinates
            jmp MoveGroundObject

JoystickMergeValues:
            ;     no change,  no horizontal, no vertical
            .byte 0,          %11000000,     %00110000

;; Deal with object pickup and putdown
PickupPutdown:
            rol INPT4             ;get joystick trigger
            ror joystick_record   ;merge into joystick record
            lda joystick_record   ;get joystick record
            and #$c0              ;merge out previous presses
            cmp #$40              ;was it previously pressed?
            bne :+                ;if not branch
            lda #objoffset_Null
            cmp object_carried
            beq :+                ;branch if nothing is carried
            sta object_carried    ;drop object
            lda #NoiseType::drop_item
            sta sound_type
            lda #4
            sta sound_duration_counter
; check for collision
:           lda CXP0FB
            and #%01000000        ;get Ball-Player0 collision
            beq :+                ;if nothing occurred then branch
; with Player0
            lda object1           ;get type of Player0
            sta obj_collided_with
            jmp CollisionDetected ;deal with collision

:           lda CXP1FB
            and #%01000000        ;get Ball-Player01 collision
            beq :+                ;if nothing has happened, branch
            lda object2           ;get type of Player01
            sta obj_collided_with
            jmp CollisionDetected ;deal with collision

:           jmp NoObject          ;deal with no collision (return)

CollisionDetected:
            ldx obj_collided_with
            jsr GetObjectAddress  ;get its roompos information in dr_ptr using x
            lda obj_collided_with
            cmp #$51              ;is it carriable?
            bcc NoObject          ;if not, branch
            ldy #DynamicType::room
            lda (dr_ptr),y        ;get the object's room
            cmp ManDynamic+DynamicType::room
            bne NoObject          ;if not, branch
            lda obj_collided_with
            cmp object_carried
            beq PickupObject      ;if so, branch (and actually pick it up)
            lda #NoiseType::get_item
            sta sound_type
            lda #4
            sta sound_duration_counter
PickupObject:
            lda obj_collided_with ;set the object as being carried
            sta object_carried
            ldx dr_ptr            ;get the dynamic address low byte
            ldy #6                ;move 6 steps in the direction specified
            lda cached_joystick   ; by joystick
            jsr MoveObjectDelta
            ldy #DynamicType::xcoord
            lda (dr_ptr),y        ;get the object's X coordinate
            sec
            sbc ManDynamic+DynamicType::xcoord
            sta objman_x_delta    ; and store the difference
            ldy #DynamicType::ycoord
            lda (dr_ptr),y        ;get the object's Y coordinate
            sec
            sbc ManDynamic+DynamicType::ycoord
            sta objman_y_delta    ; and store the difference
NoObject:   rts                   ; no collision

;; Move the carried object
MoveCarriedObject:
            ldx object_carried
            cpx #objoffset_Null
            beq :+
            jsr GetObjectAddress  ;get its roompos information in dr_ptr using x
            ldy #DynamicType::room
            lda ManDynamic+DynamicType::room  ;get the current room
            sta (dr_ptr),y        ; and store the object's current room
            ldy #DynamicType::xcoord
            lda ManDynamic+DynamicType::xcoord
            clc
            adc objman_x_delta    ;add the X difference
            sta (dr_ptr),y        ; and store as the object's X coordinate
            ldy #DynamicType::ycoord
            lda ManDynamic+DynamicType::ycoord
            clc
            adc objman_y_delta    ;add the Y difference
            sta (dr_ptr),y        ; and store as the object's Y coordinate
            ldy #0                  ;set no delta
            lda #<~MoveTypes::none  ;set no movement
            ldx dr_ptr            ;get the object's dynamic address
            jsr MoveGroundObject
:           rts

MoveGroundObject:
            jsr MoveObjectDelta     ;move the object by delta
            ldy #2                  ;set to do the three
@HandlePortal:
            sty portcullis_number
            lda PortCurrStateBase,y ;get the portal state
            cmp #PortState::closed
            beq @NextPortal         ;if not, next portal
; deal with object moving out of a castle
            ldy portcullis_number
            lda DynamicType::room,x
            cmp EntryRoomOffsets,y  ;is it in a castle entry room?
            bne @NextPortal         ;if not, next portal
            lda DynamicType::ycoord,x
            cmp #13                 ;is > 13 (at the bottom?)
            bpl @NextPortal         ;if so then branch
            lda CastleRoomOffsets,y ;get the castle room
            sta DynamicType::room,x  ;and put the object in the castle room
            lda #80
            sta DynamicType::xcoord,x
            lda #44
            sta DynamicType::ycoord,x
            lda #1
            sta PortCurrStateBase,y        ;set the portcullis state to 1
            rts
@NextPortal:
            ldy portcullis_number
            dey                     ;goto next,
            bpl @HandlePortal       ; and continue

@DealWithUp:
            lda DynamicType::ycoord,x
            cmp #106              ;has it reached above the top?
            bmi @DealWithLeft       ;if not, branch
            lda #13                 ;set new Y coordinate to bottom
            sta DynamicType::ycoord,x
            ldy #RoomType::room_up
            jmp @GetNewRoom

@DealWithLeft:
            lda DynamicType::xcoord,x
            cmp #3                  ;is it < 3?
            bcc :+                  ;if so, branch (off to left)
            cmp #240              ;is it > 240 ?
            bcs :+                  ;if so, branch (off to right)
            jmp @DealWithDown
:           cpx #ManDynamic         ;are we dealing with the man?
            beq :+                  ;if so, branch
            lda #154              ;set new X coordinate for the others
            jmp :++
:           lda #158              ;set new X coordinate for the ball
:           sta DynamicType::xcoord,x
            ldy #RoomType::room_left
            jmp @GetNewRoom

@DealWithDown:
            lda DynamicType::ycoord,x
            cmp #13                 ;if it's > 13 then branch
            bcs @DealWithRight
            lda #105              ;set new Y coordinate
            sta DynamicType::ycoord,x
            ldy #RoomType::room_down
            jmp @GetNewRoom

@DealWithRight:
            lda DynamicType::xcoord,x
            cpx #ManDynamic         ;are we dealing with the man?
            bne @CheckX             ;branch if not
            cmp #159                ;is x >= 159?
            bcc @MovementReturn     ;branch if not
            lda DynamicType::room,x  ;get the man's room
            cmp #roomnum_BelowYellowCastleRightThinWall  ; left of secret room
            bne @WrapX              ;branch if not
            lda DotDynamic+DynamicType::room  ;check the room of the black dot
            cmp #roomnum_BlackMaze3 ;is it in the hidden room area?
            beq @WrapX              ;if so, branch
; change to secret room
            lda #roomnum_SecretRoom
            sta DynamicType::room,x  ;and make it current
            lda #3                         ;set the X coordinate
            sta DynamicType::xcoord,x
            jmp @MovementReturn            ;and exit
@CheckX:    cmp #155                ;is x >= 155?
            bcc @MovementReturn     ;branch if not (no room change)
@WrapX:     lda #3                  ;set the next X coordinate
            sta DynamicType::xcoord,x
            ldy #RoomType::room_right
@GetNewRoom:
            lda DynamicType::room,x
            jsr RoomNumToAddress            ;convert to room address in dr_ptr
            lda (dr_ptr),y                  ;get the adjacent room
            jsr AdjustRoomLevel             ;deal with the level differences
            sta DynamicType::room,x  ; and store as new object's room
@MovementReturn:
            rts

; move the object in direction by delta
; input a=MoveTypes, x=object to move, y=delta
MoveObjectDelta:
            sta direction_wanted
@MoveObjectOneStep:
            dey                     ;count down the delta
            bmi @MoveObjectDone
            lda direction_wanted
            and #MoveTypes::right
            bne :+                  ;if no move then branch
            inc DynamicType::xcoord,x
:           lda direction_wanted
            and #MoveTypes::left
            bne :+                  ;if no move then branch
            dec DynamicType::xcoord,x
:           lda direction_wanted
            and #MoveTypes::up
            bne :+                  ;if no move then branch
            inc DynamicType::ycoord,x
:           lda direction_wanted
            and #MoveTypes::down
            bne :+                  ;if no move then branch
            dec DynamicType::ycoord,x
:           jmp @MoveObjectOneStep  ;keep going until delta finished
@MoveObjectDone:
            rts

; adjust room for different levels
; input a=original room
; returns a=possibly different room
AdjustRoomLevel:
            cmp #$80                ;does room number have
            bcc :+                  ; the hi bit set?
            sec                     ;yes
            sbc #$80                ;remove the $80 flag and
            sta tmp1                ; store the room number
            lda NumberCurrState     ;get the level number
            lsr a                   ;divide it by two
            clc
            adc tmp1                ;add to the original room
            tay
            lda RoomDiffs,y         ;use as an offset to get the next room
:           rts

; get player-ball collision
; input a=object number
; returns a=0 if no collision, a<>0 if collision
PBCollision:
            cmp object1             ;is it the first object?
            beq :+                  ; branch if yes
            cmp object2             ;is it the second object?
            beq :++                 ; branch if yes
            lda #0                  ;otherwise nothing
            rts
:           lda CXP0FB              ;get player0-ball collision
            and #%01000000
            rts
:           lda CXP1FB              ;get player1-ball collision
            and #%01000000
            rts

; find which object has hit object wanted
; input x=object number
; returns hit object number in a
FindObjHit: lda CXPPMM              ;get player0-player1
            and #%10000000          ; collision
            beq :+                  ;if nothing, branch
            cpx object1             ;is object 1 the one being hit?
            beq :++                 ;if so, branch
            cpx object2             ;is object 2 the one being hit?
            beq :+++                ;if so, branch
:           lda #objoffset_Null
            rts
:           lda object2             ;therefore select the other
            rts
:           lda object1             ;therefore select the other
            rts

; move object (Dragon or BlackBat)
MoveGameObject:
            jsr GetLinkedObject     ;get linked object and movement
            ldx MoveGameObjectArg_ObjNumber
            lda direction_wanted
            bne :+                  ;if movement then branch
            lda DynamicType::move,x ;use old movement
:           sta DynamicType::move,x ;store the new movement
            ldy objdelta            ;get the object's delta
            jmp MoveGroundObject

; find linked object and get movement
; input objstore_ptr, MoveGameObjectArg_Difficulty
; returns direction_wanted
GetLinkedObject:
            lda #0
            sta linked_obj_index
:           ldy linked_obj_index
            lda (objstore_ptr),y
            tax                     ;x is Object1
            iny
            lda (objstore_ptr),y
            tay                     ;y is Object2
            lda z:DynamicType::room,x   ;compare Object1's room
            cmp DynamicType::room,y     ; w/Object2's room
            bne :+                            ;if not the same room then branch
            cpy MoveGameObjectArg_Difficulty  ;have we matched Object2 for difficulty?
            beq :+                            ; branch if yes
            cpx MoveGameObjectArg_Difficulty  ;have we matched Object1 for difficulty?
            beq :+                            ; branch if yes
            bne @DetermineDirectionWanted
:           inc linked_obj_index
            inc linked_obj_index
            ldy linked_obj_index
            lda (objstore_ptr),y    ;check for end of sequence
            bne :--                 ;if not branch
            lda #MoveTypes::none
            sta direction_wanted
            rts
@DetermineDirectionWanted:
            lda #<~MoveTypes::none
            sta direction_wanted
            lda DynamicType::room,y      ;compare Object2's room
            cmp z:DynamicType::room,x    ; w/ Object1's room
            bne @Exit                          ;if not the same, forget it
            lda DynamicType::xcoord,y    ;compare Object2's X coordinate
            cmp z:DynamicType::xcoord,x  ; w/ Object1's X coordinate
            bcc @SetLeft            ;if Object2 X < Object1 X then branch
            beq @CmpY               ;if Object2 X = Object1 X then branch
            lda direction_wanted
            and #<~MoveTypes::right ;move Object1 right
            sta direction_wanted
            jmp @CmpY
@SetLeft:   lda direction_wanted
            and #<~MoveTypes::left  ;move Object1 left
            sta direction_wanted
@CmpY:      lda DynamicType::ycoord,y    ;compare Object2's Y coordinate
            cmp z:DynamicType::ycoord,x  ; w/ Object1's Y coordinate
            bcc @SetDown            ;if Object2 Y < Object1 Y then branch
            beq @Exit               ;if Object2 Y = Object1 Y then branch
            lda direction_wanted
            and #<~MoveTypes::up    ;move Object1 up
            sta direction_wanted
            jmp @Exit
@SetDown:   lda direction_wanted
            and #<~MoveTypes::down  ;move Object1 down
            sta direction_wanted
@Exit:      lda direction_wanted
            rts

;; Move the red dragon "Rhindle"
MoveRedDragon:
            lda #<RedDragMatrix
            sta objstore_ptr
            lda #>RedDragMatrix
            sta objstore_ptr+1
            lda #3
            sta objdelta
            ldx #objoffset_DragonRhindle
            jmp MoveDragon

RedDragMatrix:
            .byte SwordDynamic,     RedDragonDynamic
            .byte RedDragonDynamic, ManDynamic
            .byte RedDragonDynamic, ChaliceDynamic
            .byte RedDragonDynamic, WhiteKeyDynamic
            .byte 0

;; Move the yellow dragon "Yorgle"
MoveYellowDragon:
            lda #<YelDragMatrix
            sta objstore_ptr
            lda #>YelDragMatrix
            sta objstore_ptr+1
            lda #2
            sta objdelta
            ldx #objoffset_DragonYorgle
            jmp MoveDragon

YelDragMatrix:
            .byte SwordDynamic,        YellowDragonDynamic
            .byte YellowKeyDynamic,    YellowDragonDynamic
            .byte YellowDragonDynamic, ManDynamic
            .byte YellowDragonDynamic, ChaliceDynamic
            .byte 0

;; Move the green dragon "Grundle"
MoveGreenDragon:
            lda #<GreenDragMatrix
            sta objstore_ptr
            lda #>GreenDragMatrix
            sta objstore_ptr+1
            lda #2
            sta objdelta
            ldx #objoffset_DragonGrundle
            jmp MoveDragon

GreenDragMatrix:
            .byte SwordDynamic,       GreenDragonDynamic
            .byte GreenDragonDynamic, ManDynamic
            .byte GreenDragonDynamic, ChaliceDynamic
            .byte GreenDragonDynamic, BridgeDynamic
            .byte GreenDragonDynamic, MagnetDynamic
            .byte GreenDragonDynamic, BlackKeyDynamic
            .byte 0

; Move a dragon
; x            = dragon object (objoffset_DragonRhindle, objoffset_DragonYorgle, objoffset_DragonGrundle)
; objstore_ptr = dragon matrix
; objdelta     = move speed
MoveDragon: stx curr_obj_number   ;save which dragon we're dealing with
            lda Objects+ObjectType::dynamic_ptr,x
            tax
            lda z:DynamicType::state,x
            cmp #DragonState::normal
            bne @DragonStateNotNormal  ;branch if not normal
@DragonStateNormal:
            lda SWCHB             ;read console switches
            and #ConsoleSwitchType::rightdifficulty ;check for P1 difficulty
            beq :+                ;if Amateur (B) branch
            lda #0                ;set hard - ignore nothing
            beq :++
:           lda #SwordDynamic     ;set easy - ignore sword
:           sta MoveGameObjectArg_Difficulty
            stx MoveGameObjectArg_ObjNumber
            jsr MoveGameObject
            lda curr_obj_number   ;get which dragon
            jsr PBCollision       ; and check player-ball collision
            beq @CheckSwordContact;branch if no collision
            lda SWCHB             ;get console switches
            rol a                 ;move P0 difficulty to
            rol a                 ; bit 0 position
            rol a
            and #1                ;mask out everything else
            ora NumberCurrState   ;merge in the level number
            tay                   ;create lookup
            lda DragonDiff,y      ;get new state
            sta z:DynamicType::state,x   ;store as dragon's state (roaring)
            lda PrevManDynamic+DynamicType::xcoord
            sta z:DynamicType::xcoord,x  ;get temp ball X coord and store as dragon's
            lda PrevManDynamic+DynamicType::ycoord
            sta z:DynamicType::ycoord,x  ;get temp ball Y coord and store as dragon's
            lda #NoiseType::dragon_roar
            sta sound_type
            lda #16
            sta sound_duration_counter
@CheckSwordContact:
            stx portcullis_number
            ldx curr_obj_number   ;get which dragon
            jsr FindObjHit        ;set if another object has hit the dragon
            ldx portcullis_number
            cmp #objoffset_Sword  ;has the sword hit the dragon?
            bne :+                ;if not, branch
            lda #DragonState::dead
            sta z:DynamicType::state,x
            lda #NoiseType::dragon_died
            sta sound_type
            lda #16
            sta sound_duration_counter
:           jmp @DoneWithDragon   ;jump to finish
@DragonStateNotNormal:
            cmp #DragonState::dead
            beq @DoneWithDragon   ;branch if so
            cmp #DragonState::ateman
            bne @DragonRoaring    ;branch if not
@DragonStateAteMan:
            lda z:DynamicType::room,x
            sta ManDynamic+DynamicType::room
            sta PrevManDynamic+DynamicType::room
            lda z:DynamicType::xcoord,x
            clc
            adc #3                ;adjust +3x
            sta ManDynamic+DynamicType::xcoord
            sta PrevManDynamic+DynamicType::xcoord
            lda z:DynamicType::ycoord,x
            sec
            sbc #10               ;adjust -10y
            sta ManDynamic+DynamicType::ycoord
            sta PrevManDynamic+DynamicType::ycoord
            jmp @DoneWithDragon
@DragonRoaring:
            inc z:DynamicType::state,x  ;increment the dragon's state
            lda z:DynamicType::state,x  ;get its state
            cmp #$fc              ;is it near the end?
            bcc @DoneWithDragon   ;if not, branch
            lda curr_obj_number   ;get which dragon
            jsr PBCollision       ;check if the ball is colliding
            beq @DoneWithDragon   ;if not, branch
            lda #DragonState::ateman
            sta z:DynamicType::state,x
            lda #NoiseType::man_eaten
            sta sound_type
            lda #16
            sta sound_duration_counter
            lda #155              ;get the maximum X coordinate
            cmp z:DynamicType::xcoord,x  ;compare with the dragon's X coordinate
            beq :+
            bcs :+
            sta z:DynamicType::xcoord,x  ;cap it at max X coordinate
:           lda #23               ;set minimum Y coordinate
            cmp z:DynamicType::ycoord,x  ;compare with the dragon's Y coordinate
            bcc @DoneWithDragon
            sta z:DynamicType::ycoord,x  ;cap it at min Y coordinate
@DoneWithDragon:
            rts

; dragon difficulty: index = NumberCurrentState + p0 difficulty
DragonDiff: .byte $d0, $e8       ;level 1: Amateur (B), Pro (A)
            .byte $f0, $f6       ;level 2: Amateur (B), Pro (A)
            .byte $f0, $f6       ;level 3: Amateur (B), Pro (A)

;; Move the bat
MoveBat:    inc BlackBatDynamic+DynamicType::state ;put bat in the next state
            lda BlackBatDynamic+DynamicType::state
            cmp #8                 ;has it reached the maximum?
            bne :+
            lda #0                 ;if so, reset the bat state
            sta BlackBatDynamic+DynamicType::state
:           lda BlackBatDynamic+DynamicType::fedup
            beq @BatFedup          ;if bat fed-up then branch
            inc BlackBatDynamic+DynamicType::fedup
            lda z:BlackBatDynamic+DynamicType::move
            ldx #BlackBatDynamic
            ldy #3                 ;get the bat's delta
            jsr MoveGroundObject   ;move the bat
            jmp @MoveCarriedObject ;update the bat's object
@BatFedup:  lda #BlackBatDynamic   ;store the bat's dynamic data address
            sta MoveGameObjectArg_ObjNumber
            lda #3                 ;set the bat's delta
            sta objdelta
            lda #<BatMatrix
            sta objstore_ptr
            lda #>BatMatrix
            sta objstore_ptr+1
            lda BlackBatDynamic+DynamicType::carriedobject
            sta MoveGameObjectArg_Difficulty
            jsr MoveGameObject
            ldy linked_obj_index
            lda (objstore_ptr),y   ;look up the object found in the table
            beq @MoveCarriedObject ;if nothing found then forget it
            iny
            lda (objstore_ptr),y   ;get the object wanted
            tax
            lda z:DynamicType::room,x
            cmp BlackBatDynamic+DynamicType::room  ;is it the same as the Bat's?
            bne @MoveCarriedObject ;if not forget it
; see if bat can pick up an object
            lda z:DynamicType::xcoord,x
            sec
            sbc z:BlackBatDynamic+DynamicType::xcoord  ;find the difference with the Bat's X coordinate
            clc
            adc #4                 ;adjust so Bat in middle of object
            and #%11111000         ;is Bat within seven pixels?
            bne @MoveCarriedObject ;if not, no pickup possible
            lda z:DynamicType::ycoord,x
            sec
            sbc z:BlackBatDynamic+DynamicType::ycoord  ;find the difference with the Bat's Y coordinate
            clc
            adc #4                 ;adjust so Bat in middle of object
            and #%11111000         ;is the Bat within seven pixels?
            bne @MoveCarriedObject ;if not, no pickup possible
; get object
            stx BlackBatDynamic+DynamicType::carriedobject  ;store object as being carried
            lda #16                ;reset the bat fed-up time
            sta BlackBatDynamic+DynamicType::fedup
; move object being carried by bat
@MoveCarriedObject:
            ldx BlackBatDynamic+DynamicType::carriedobject  ;get object being carried by Bat
            lda BlackBatDynamic+DynamicType::room
            sta z:DynamicType::room,x
            lda z:BlackBatDynamic+DynamicType::xcoord
            clc
            adc #8                ;adjust to the right +8x
            sta z:DynamicType::xcoord,x
            lda z:BlackBatDynamic+DynamicType::ycoord
            sta z:DynamicType::ycoord,x
            lda BlackBatDynamic+DynamicType::carriedobject  ;get the object being carried by the bat
            ldy object_carried
            cmp Objects+ObjectType::dynamic_ptr,y  ;are they the same?
            bne :+               ;if not branch to exit
            lda #objoffset_Null
            sta object_carried
:           rts

BatMatrix:  .byte  BlackBatDynamic, ChaliceDynamic
            .byte  BlackBatDynamic, SwordDynamic
            .byte  BlackBatDynamic, BridgeDynamic
            .byte  BlackBatDynamic, YellowKeyDynamic
            .byte  BlackBatDynamic, WhiteKeyDynamic
            .byte  BlackBatDynamic, BlackKeyDynamic
            .byte  BlackBatDynamic, RedDragonDynamic
            .byte  BlackBatDynamic, YellowDragonDynamic
            .byte  BlackBatDynamic, GreenDragonDynamic
            .byte  BlackBatDynamic, MagnetDynamic
            .byte  0

;; Deal with portcullis and collisions
Portals:    ldy #2                ;for each portcullis
@DoNext:    ldx PortOffsets,y     ;get the portcullis' offset number
            jsr FindObjHit        ;see if an object collided with it
            sta obj_collided_with
            cmp KeyOffsets,y      ;is it the associated key?
            bne :+                ;if not then branch
            tya                   ;get the portcullis number
            tax
            inc PortCurrStateBase,x  ;change its state to open it
:           tya                   ;get the portcullis number
            tax
            lda PortCurrStateBase,x  ;get the state
            cmp #PortState::closed
            beq @IncPortState     ;yes - then branch
            lda PortOffsets,y     ;get portcullis number
            jsr PBCollision       ;get the player-ball collision
            beq :+                ;if not then branch
            lda #PortState::open
            sta PortCurrStateBase,x
            ldx #ManDynamic
            jmp @PutManInCastle
:           lda obj_collided_with ;get the object that hit the portcullis
            cmp #objoffset_Null
            beq :+                ;if so, branch
            ldx obj_collided_with
            sty portcullis_number
            jsr GetObjectAddress  ;get its dynamic information in dr_ptr using x
            ldy portcullis_number
            ldx dr_ptr            ;get object's address
            jmp @PutManInCastle
:           jmp @IncPortState
@PutManInCastle:
            lda EntryRoomOffsets,y ;look up castle entry room for this port
            sta DynamicType::room,x  ;make it the object's room
            lda #16               ;give the object a new Y coordinate
            sta DynamicType::ycoord,x
@IncPortState:
            tya                   ;get the portcullis number
            tax
            lda PortCurrStateBase,x
            cmp #PortState::open
            beq :+                ; branch if yes
            cmp #PortState::closed
            beq :+                ; branch if yes
            inc PortCurrStateBase,x
            lda PortCurrStateBase,x
            cmp #PortState::wraparound_max
            bne :+                ; branch if not
            lda #PortState::open  ;wrap around
            sta PortCurrStateBase,x
:           dey                   ;go to the next portcullis
            bmi @PortalsDone      ;branch if finished
            jmp @DoNext           ;do next portcullis
@PortalsDone:
            rts

PortOffsets:       .byte  objoffset_PortCullis1,     objoffset_PortCullis2,    objoffset_PortCullis3
KeyOffsets:        .byte  objoffset_YellowKey,       objoffset_WhiteKey,       objoffset_BlackKey
EntryRoomOffsets:  .byte  roomnum_YellowCastleEntry, roomnum_WhiteCastleEntry, roomnum_BlackCastleEntry
CastleRoomOffsets: .byte  roomnum_YellowCastle,      roomnum_WhiteCastle,      roomnum_BlackCastle

;; Deal with magnet
Mag:        lda z:MagnetDynamic+DynamicType::ycoord
            sec
            sbc #8                ;adjust to its "poles"
            sta z:MagnetDynamic+DynamicType::ycoord
            lda #0                ;con difficulty!
            sta MoveGameObjectArg_Difficulty
            lda #<MagnetMatrix    ;set low address of object store
            sta objstore_ptr
            lda #>MagnetMatrix    ;set high address of object store
            sta objstore_ptr+1
            jsr GetLinkedObject   ;get linked object and set movement
            lda direction_wanted
            beq :+                ;if none, then forget it
            ldy #1                ;set delta to one
            jsr MoveGroundObject  ;move object
:           lda z:MagnetDynamic+DynamicType::ycoord  ;reset the magnet's Y coordinate
            clc
            adc #8
            sta z:MagnetDynamic+DynamicType::ycoord
            rts

MagnetMatrix:
            .byte YellowKeyDynamic, MagnetDynamic
            .byte WhiteKeyDynamic,  MagnetDynamic
            .byte BlackKeyDynamic,  MagnetDynamic
            .byte SwordDynamic,     MagnetDynamic
            .byte BridgeDynamic,    MagnetDynamic
            .byte ChaliceDynamic,   MagnetDynamic
            .byte 0

;; Deal with invisible surround moving
Surround:   lda ManDynamic+DynamicType::room
            jsr RoomNumToAddress  ;convert to room address in dr_ptr
            ldy #RoomType::color
            lda (dr_ptr),y
            cmp #ColorType::invisible
            beq :+                ;branch if invisible
            lda #0                ;if not, signal the invisible surround not wanted
            sta z:SurroundDynamic+DynamicType::ycoord
            jmp :+++
:           lda ManDynamic+DynamicType::room
            sta SurroundDynamic
            lda ManDynamic+DynamicType::xcoord
            sec
            sbc #14               ;adjust for surround
            sta z:SurroundDynamic+DynamicType::xcoord
            lda ManDynamic+DynamicType::ycoord
            clc
            adc #14               ;adjust for surround
            sta z:SurroundDynamic+DynamicType::ycoord
            lda z:SurroundDynamic+DynamicType::xcoord
            cmp #240              ;is it close to the right edge?
            bcc :+                ;branch if not
            lda #1                ;flick surround to the other side of the screen
            sta z:SurroundDynamic+DynamicType::xcoord
            jmp :++
:           cmp #130              ;keep x < 130
            bcc :+
            lda #129
            sta z:SurroundDynamic+DynamicType::xcoord
:           rts

;; Make a sound
MakeSound:  lda sound_duration_counter  ;check noise count
            bne :+                      ;branch if noise to be made
            sta AUDV0                   ;turn off the volume
            sta AUDV1
            rts

:           dec sound_duration_counter  ;go to the next note
            lda sound_type
            beq GameOverNoise
            cmp #NoiseType::dragon_roar
            beq RoarNoise
            cmp #NoiseType::man_eaten
            beq EatenNoise
            cmp #NoiseType::dragon_died
            beq DragDieNoise
            cmp #NoiseType::drop_item
            beq DropObjectNoise
            cmp #NoiseType::get_item
            beq GetObjectNoise
            rts

GameOverNoise:
            lda sound_duration_counter
            sta COLUPF            ;color-luminance playfield
            sta AUDC0             ;audio-control 0
            lsr a
            sta AUDV0             ;audio-volume 0
            lsr a
            lsr a
            sta AUDF0             ;audio-frequency 0
            rts

RoarNoise:  lda sound_duration_counter
            lsr a
            lda #3                ;if it was even then
            bcs :+                ; branch
            lda #8                ;get a different audio control value
:           sta AUDC0             ;set audio control 0
            lda sound_duration_counter  ;set the volume to the noise count
            sta AUDV0
            lsr a                 ;divide by four
            lsr a
            clc
            adc #28               ;set the frequency
            sta AUDF0
            rts

EatenNoise:
            lda #6
            sta AUDC0             ;audio-control 0
            lda sound_duration_counter
            eor #%00001111
            sta AUDF0             ;audio-frequency 0
            lda sound_duration_counter
            lsr a
            clc
            adc #8
            sta AUDV0             ;audio-volume 0
            rts

DragDieNoise:
            lda #4                ;set the audio control
            sta AUDC0
            lda sound_duration_counter  ;put the note count in
            sta AUDV0             ; the volume
            eor #%00011111
            sta AUDF0             ;flip the count as store
            rts                   ; as the frequency

DropObjectNoise:
            lda sound_duration_counter
            eor #3                ;reverse it as noise does up
:           sta AUDF0             ;store in frequency for channel 0
            lda #5
            sta AUDV0             ;set volume on channel 0
            lda #6
            sta AUDC0             ;set a noise on channel 0
            rts

GetObjectNoise:
            lda sound_duration_counter
            jmp :-                ;make same noise as drop

.res 25, 0 ; Padding may be needed to satisfy the following invariant.

; The alignment of sprites is carefully done to prevent crossing of page boundaries.
.assert (* & $fff) = $aa0, error, "Sprite area does not start at the expected offset."

LeftOfName:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $ff, $ff   ; 11111111111111111111 11111111111111111111
 .byte $00, $00, $00   ; 11.................. ..................11
 .byte $00, $00, $00   ; 11.................. ..................11
 .byte $00, $00, $00   ; 11.................. ..................11
 .byte $00, $00, $00   ; 11.................. ..................11
 .byte $00, $00, $00   ; 11.................. ..................11
 ;byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111 ; uses next room's line
 .assert >(*-1) = >(LeftOfName), error, "Sprite spans page."
BelowYellowCastle:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
 .byte $00, $00, $00   ; .................... ....................
 .byte $00, $00, $00   ; .................... ....................
 .byte $00, $00, $00   ; .................... ....................
 .byte $00, $00, $00   ; .................... ....................
 .byte $00, $00, $00   ; .................... ....................
 .byte $f0, $ff, $ff   ; 11111111111111111111 11111111111111111111
 .assert >(*-1) = >(BelowYellowCastle), error, "Sprite spans page."
SideCorridor:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
 .byte $00, $00, $00   ; .................... ....................
 .byte $00, $00, $00   ; .................... ....................
 .byte $00, $00, $00   ; .................... ....................
 .byte $00, $00, $00   ; .................... ....................
 .byte $00, $00, $00   ; .................... ....................
 .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
 .assert >(*-1) = >(SideCorridor), error, "Sprite spans page."
NumberRoom:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $ff, $ff   ; 11111111111111111111 11111111111111111111
 .byte $30, $00, $00   ; 11.................. ..................11
 .byte $30, $00, $00   ; 11.................. ..................11
 .byte $30, $00, $00   ; 11.................. ..................11
 .byte $30, $00, $00   ; 11.................. ..................11
 .byte $30, $00, $00   ; 11.................. ..................11
 .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
 .assert >(*-1) = >(NumberRoom), error, "Sprite spans page."

PortStates:         .byte 4                 ; open
                    .word PortGfx+12
                    .byte 8
                    .word PortGfx+10
                    .byte 12
                    .word PortGfx+8
                    .byte 16
                    .word PortGfx+6
                    .byte 20
                    .word PortGfx+4
                    .byte 24
                    .word PortGfx+2
                    .byte 28                ; closed
                    .word PortGfx
                    .byte 32
                    .word PortGfx+2
                    .byte 36
                    .word PortGfx+4
                    .byte 40
                    .word PortGfx+6
                    .byte 44
                    .word PortGfx+8
                    .byte 48
                    .word PortGfx+10
                    .byte $ff               ; open
                    .word PortGfx+12
PortGfx:
 .byte %11111110 ; XXXXXXX
 .byte %10101010 ; X X X X
 .byte %11111110 ; XXXXXXX
 .byte %10101010 ; X X X X
 .byte %11111110 ; XXXXXXX
 .byte %10101010 ; X X X X
 .byte %11111110 ; XXXXXXX
 .byte %10101010 ; X X X X
 .byte %11111110 ; XXXXXXX
 .byte %10101010 ; X X X X
 .byte %11111110 ; XXXXXXX
 .byte %10101010 ; X X X X
 .byte %11111110 ; XXXXXXX
 .byte %10101010 ; X X X X
 .byte %11111110 ; XXXXXXX
 .byte %10101010 ; X X X X
 .byte 0
 .assert >(*-1) = >(PortGfx), error, "Sprite spans page."

TwoExitRoom:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
 .byte $30, $00, $00   ; 11.................. ..................11
 .byte $30, $00, $00   ; 11.................. ..................11
 .byte $30, $00, $00   ; 11.................. ..................11
 .byte $30, $00, $00   ; 11.................. ..................11
 .byte $30, $00, $00   ; 11.................. ..................11
 .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
 .assert >(*-1) = >(TwoExitRoom), error, "Sprite spans page."
BlueMazeTop:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
 .byte $00, $0c, $0c   ; ......11......11.... ....11......11......
 .byte $f0, $0c, $3c   ; 1111..11......1111.. ..1111......11..1111
 .byte $f0, $0c, $00   ; 1111..11............ ............11..1111
 .byte $f0, $ff, $3f   ; 111111111111111111.. ..111111111111111111
 .byte $00, $30, $30   ; ........11......11.. ..11......11........
 .byte $f0, $33, $3f   ; 111111..11..111111.. ..111111..11..111111
 .assert >(*-1) = >(BlueMazeTop), error, "Sprite spans page."
BlueMaze1:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $ff, $ff   ; 11111111111111111111 11111111111111111111
 .byte $00, $00, $00   ; .................... ....................
 .byte $f0, $fc, $ff   ; 1111..11111111111111 11111111111111..1111
 .byte $f0, $00, $c0   ; 1111..............11 11..............1111
 .byte $f0, $3f, $cf   ; 1111111111..1111..11 11..1111..1111111111
 .byte $00, $30, $cc   ; ........11....11..11 11..11....11........
 .byte $f0, $f3, $cc   ; 111111..1111..11..11 11..11..1111..111111
 .assert >(*-1) = >(BlueMaze1), error, "Sprite spans page."
BlueMazeBottom:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $f3, $0c   ; 111111..1111..11.... ....11..1111..111111
 .byte $00, $30, $0c   ; ........11....11.... ....11....11........
 .byte $f0, $3f, $0f   ; 1111111111..1111.... ....1111..1111111111
 .byte $f0, $00, $00   ; 1111................ ................1111
 .byte $f0, $f0, $00   ; 1111....1111........ ........1111....1111
 .byte $00, $30, $00   ; ........11.......... ..........11........
 .byte $f0, $ff, $ff   ; 111111..1111..11..11 11..11..1111..111111
 .assert >(*-1) = >(BlueMazeBottom), error, "Sprite spans page."
BlueMazeCenter:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $33, $3f   ; 111111..11..111111.. ..111111..11..111111
 .byte $00, $30, $3c   ; ........11....1111.. ..1111....11........
 .byte $f0, $ff, $3c   ; 111111111111..1111.. ..1111..111111111111
 .byte $00, $03, $3c   ; ....11........1111.. ..1111........11....
 .byte $f0, $33, $3c   ; 111111..11....1111.. ..1111....11..111111
 .byte $00, $33, $0c   ; ....11..11....11.... ....11....11..11....
 .byte $f0, $f3, $0c   ; 111111..1111..11.... ....11..1111..111111
 .assert >(*-1) = >(BlueMazeCenter), error, "Sprite spans page."
BlueMazeEntry:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $f3, $cc   ; 111111..1111..11..11 11..11..1111..111111
 .byte $00, $33, $0c   ; ....11..11....11.... ....11....11..11....
 .byte $f0, $33, $fc   ; 111111..11....111111 111111....11..111111
 .byte $00, $33, $00   ; ....11..11.......... ..........11..11....
 .byte $f0, $f3, $ff   ; 111111..111111111111 111111111111..111111
 .byte $00, $00, $00   ; .................... ....................
 .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
 .assert >(*-1) = >(BlueMazeEntry), error, "Sprite spans page."
MazeMiddle:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $ff, $cc   ; 111111111111..11..11 11..11..111111111111
 .byte $00, $00, $cc   ; ..............11.11. 11..11..............
 .byte $f0, $03, $cf   ; 111111......1111..11 11..1111......111111
 .byte $00, $03, $00   ; ....11.............. ..............11....
 .byte $f0, $f3, $fc   ; 111111..1111..111111 111111..1111..111111
 .byte $00, $33, $0c   ; ....11..11....11.... ....11....11..11....
 ;byte $f0, $33, $cc   ; 111111..11....11..11 11..11....11..111111 ; uses next room's line
 .assert >(*-1) = >(MazeMiddle), error, "Sprite spans page."
MazeSide:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $33, $cc   ; 111111..11....11..11 11..11....11..111111
 .byte $00, $30, $cc   ; ........11....11..11 11..11....11........
 .byte $00, $3f, $cf   ; ....111111..1111..11 11..1111..111111....
 .byte $00, $00, $c0   ; ..................11 11..................
 .byte $00, $3f, $c3   ; ....111111..11....11 11....11..111111....
 .byte $00, $30, $c0   ; ........11........11 11........11........
 .byte $f0, $ff, $ff   ; 11111111111111111111 11111111111111111111
 .assert >(*-1) = >(MazeSide), error, "Sprite spans page."
MazeEntry:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
 .byte $00, $30, $00   ; ........11.......... ..........11........
 .byte $f0, $30, $ff   ; 1111....11..11111111 11111111..11....1111
 .byte $00, $30, $c0   ; ........11........11 11........11........
 .byte $f0, $f3, $c0   ; 111111..1111......11 11......1111..111111
 .byte $00, $03, $c0   ; ....11............11 11............11....
 .byte $f0, $ff, $cc   ; 11111111111111111111 11111111111111111111
 .assert >(*-1) = >(MazeEntry), error, "Sprite spans page."
CastleDef:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $fe, $15   ; 11111111111....1.1.1 1.1.1....11111111111
 .byte $30, $03, $1f   ; 11........11...11111 11111...11........11
 .byte $30, $03, $ff   ; 11........1111111111 1111111111........11
 .byte $30, $00, $ff   ; 11..........11111111 11111111..........11
 .byte $30, $00, $3f   ; 11......... 111111.. ..111111..........11
 .byte $30, $00, $00   ; 11.................. ..................11
 .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
 .assert >(*-1) = >(CastleDef), error, "Sprite spans page."

PortDynamic1:       .byte roomnum_YellowCastle, 77, 49
PortDynamic2:       .byte roomnum_WhiteCastle,  77, 49
PortDynamic3:       .byte roomnum_BlackCastle,  77, 49

SurroundCurrState:  .byte 0
SurroundStates:     .byte $ff
                    .word SurroundGfx
SurroundGfx:
 .byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
 .byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
 .byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
 .byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
 .byte 0
 .assert >(*-1) = >(SurroundGfx), error, "Sprite spans page."

RedMaze1:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $ff, $ff   ; 11111111111111111111 11111111111111111111
 .byte $00, $00, $00   ; .................... ....................
 .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
 .byte $00, $00, $0c   ; ..............11.... ....11..............
 .byte $f0, $ff, $0c   ; 111111111111..11.... ....11..111111111111
 .byte $f0, $03, $cc   ; 111111........11..11 11..11........111111
 ;byte $f0, $33, $cf   ; 111111..11..1111..11 11..1111..11..111111 ; uses next room's line
 .assert >(*-1) = >(RedMaze1), error, "Sprite spans page."
RedMazeBottom:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $33, $cf   ; 111111..11..1111..11 11..1111..11..111111
 .byte $f0, $30, $00   ; 1111....11.......... ..........11....1111
 .byte $f0, $33, $ff   ; 111111..11..11111111 11111111..11..111111
 .byte $00, $33, $00   ; ....11..11.......... ..........11..11....
 .byte $f0, $ff, $00   ; 111111111111........ ........111111111111
 .byte $00, $00, $00   ; 11.................. ..................11
 .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
 .assert >(*-1) = >(RedMazeBottom), error, "Sprite spans page."
RedMazeTop:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $ff, $ff   ; 11111111111111111111 11111111111111111111
 .byte $00, $00, $c0   ; 1111..............11 11..............1111
 .byte $f0, $ff, $cf   ; 1111111111111111..11 11..1111111111111111
 .byte $00, $00, $cc   ; ..............11..11 11..11..............
 .byte $f0, $33, $ff   ; 111111..11..11111111 11111111..11..111111
 .byte $f0, $33, $00   ; 111111..11.......... ..........11..111111
 ;byte $f0, $3f, $0c   ; 1111111111....11.... ....11....1111111111 ; uses next room's line
 .assert >(*-1) = >(RedMazeTop), error, "Sprite spans page."
WhiteCastleEntry:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $3f, $0c   ; 1111111111....11.... ....11....1111111111
 .byte $f0, $00, $0c   ; 1111..........11.... ....11..........1111
 .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
 .byte $00, $30, $00   ; 1111....11.......... ..........11....1111
 .byte $f0, $30, $00   ; 1111....11.......... ..........11....1111
 .byte $00, $30, $00   ; ........11.......... ..........11........
 .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
 .assert >(*-1) = >(WhiteCastleEntry), error, "Sprite spans page."
TopEntryRoom:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
 .byte $30, $00, $00   ; 11.................. ..................11
 .byte $30, $00, $00   ; 11.................. ..................11
 .byte $30, $00, $00   ; 11.................. ..................11
 .byte $30, $00, $00   ; 11.................. ..................11
 .byte $30, $00, $00   ; 11.................. ..................11
 .byte $f0, $ff, $ff   ; 11111111111111111111 11111111111111111111
 .assert >(*-1) = >(TopEntryRoom), error, "Sprite spans page."
BlackMaze1:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $f0, $ff   ; 1111....111111111111 111111111111....1111
 .byte $00, $00, $03   ; ............11...... ......11............
 .byte $f0, $ff, $03   ; 11111111111111...... ......11111111111111
 .byte $00, $00, $00   ; .................... ....................
 .byte $30, $3f, $ff   ; 11..111111..11111111 11111111..111111..11
 .byte $00, $30, $00   ; ........11.......... ..........11........
 ;byte $f0, $f0, $ff   ; 1111....111111111111 111111111111....1111 ; uses next room's line
 .assert >(*-1) = >(BlackMaze1), error, "Sprite spans page."
BlackMaze3:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF0hPF1-----PF2-----
 .byte $f0, $f0, $ff   ; 11111111....11111111 11111111....11111111
 .byte $30, $00, $00   ; 11.................. 11..................
 .byte $30, $3f, $ff   ; 11....11111111111111 11....11111111111111
 .byte $00, $30, $00   ; ......11............ ......11............
 .byte $f0, $f0, $ff   ; 11111111....11111111 11111111....11111111
 .byte $30, $00, $03   ; 11................11 11................11
 .byte $f0, $f0, $ff   ; 11111111....11111111 11111111....11111111
 .assert >(*-1) = >(BlackMaze3), error, "Sprite spans page."
BlackMaze2:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF0hPF1-----PF2-----
 .byte $f0, $ff, $ff   ; 11111111111111111111 11111111111111111111
 .byte $00, $00, $c0   ; ............11...... ............11......
 .byte $f0, $ff, $cf   ; 11111111111111..1111 11111111111111..1111
 .byte $00, $00, $0c   ; ..................11 ..................11
 .byte $f0, $0f, $ff   ; 1111....111111111111 1111....111111111111
 .byte $00, $0f, $c0   ; ........111111...... ........111111......
 ;byte $30, $cf, $cc   ; 11..11..111111..11.. 11..11..111111..11.. ; uses next room's line
 .assert >(*-1) = >(BlackMaze2), error, "Sprite spans page."
BlackMazeEntry:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $30, $cf, $cc   ; 11..1111..11..11..11 11..11..11..1111..11
 .byte $00, $c0, $cc   ; ..........11..11..11 11..11..11..........
 .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
 .byte $00, $00, $00   ; .................... ....................
 .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
 .byte $00, $00, $00   ; .................... ....................
 .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
 .assert >(*-1) = >(BlackMazeEntry), error, "Sprite spans page."

BridgeCurrState:    .byte 0
BridgeStates:       .byte $ff
                    .word BridgeGfx
BridgeGfx:
 .byte %11000011 ; XX    XX
 .byte %11000011 ; XX    XX
 .byte %11000011 ; XX    XX
 .byte %11000011 ; XX    XX
 .byte %01000010 ;  X    X
 .byte %01000010 ;  X    X
 .byte %01000010 ;  X    X
 .byte %01000010 ;  X    X
 .byte %01000010 ;  X    X
 .byte %01000010 ;  X    X
 .byte %01000010 ;  X    X
 .byte %01000010 ;  X    X
 .byte %01000010 ;  X    X
 .byte %01000010 ;  X    X
 .byte %01000010 ;  X    X
 .byte %01000010 ;  X    X
 .byte %01000010 ;  X    X
 .byte %01000010 ;  X    X
 .byte %01000010 ;  X    X
 .byte %01000010 ;  X    X
 .byte %11000011 ; XX    XX
 .byte %11000011 ; XX    XX
 .byte %11000011 ; XX    XX
 .byte %11000011 ; XX    XX
 .byte 0
 .assert >(*-1) = >(BridgeGfx), error, "Sprite spans page."

Number1Gfx:
 .byte %00000100 ;     X
 .byte %00001100 ;    XX
 .byte %00000100 ;     X
 .byte %00000100 ;     X
 .byte %00000100 ;     X
 .byte %00000100 ;     X
 .byte %00001110 ;    XXX
 .byte 0
 .assert >(*-1) = >(Number1Gfx), error, "Sprite spans page."

KeyCurrState:       .byte 0
KeyStates:          .byte $ff
                    .word KeyGfx
KeyGfx:
 .byte %00000111 ;      XXX
 .byte %11111101 ; XXXXXX X
 .byte %10100111 ; X X  XXX
 .byte 0
 .assert >(*-1) = >(KeyGfx), error, "Sprite spans page."

Number2Gfx:
 .byte %00001110 ;     XXX
 .byte %00010001 ;    X   X
 .byte %00000001 ;        X
 .byte %00000010 ;       X
 .byte %00000100 ;      X
 .byte %00001000 ;     X
 .byte %00011111 ;    XXXXX
 .byte 0
 .assert >(*-1) = >(Number2Gfx), error, "Sprite spans page."
Number3Gfx:
 .byte %00001110 ;     XXX
 .byte %00010001 ;    X   X
 .byte %00000001 ;        X
 .byte %00000110 ;      XX
 .byte %00000001 ;        X
 .byte %00010001 ;    X   X
 .byte %00001110 ;     XXX
 .byte 0
 .assert >(*-1) = >(Number3Gfx), error, "Sprite spans page."

BatStates:          .byte 3
                    .word Bat1Gfx
                    .byte $ff
                    .word Bat2Gfx
Bat1Gfx:
 .byte %10000001 ; X      X
 .byte %10000001 ; X      X
 .byte %11000011 ; XX    XX
 .byte %11000011 ; XX    XX
 .byte %11111111 ; XXXXXXXX
 .byte %01011010 ;  X XX X
 .byte %01100110 ;  XX  XX
 .byte 0
 .assert >(*-1) = >(Bat1Gfx), error, "Sprite spans page."
Bat2Gfx:
 .byte %00000001 ;        X
 .byte %10000000 ; X
 .byte %00000001 ;        X
 .byte %10000000 ; X
 .byte %00111100 ;   XXXX
 .byte %01011010 ;  X XX X
 .byte %01100110 ;  XX  XX
 .byte %11000011 ; XX    XX
 .byte %10000001 ; X      X
 .byte %10000001 ; X      X
 .byte %10000001 ; X      X
 .byte 0
 .assert >(*-1) = >(Bat2Gfx), error, "Sprite spans page."

DragonStates:       .byte DragonState::normal
                    .word DragonNormLeftGfx
                    .byte DragonState::dead
                    .word DragonDeadLeftGfx
                    .byte DragonState::ateman
                    .word DragonNormLeftGfx
                    .byte DragonState::roaring
                    .word DragonRoarLeftGfx
DragonNormLeftGfx:
 .byte %00000110 ;      XX
 .byte %00001111 ;     XXXX
 .byte %11110011 ; XXXX  XX
 .byte %11111110 ; XXXXXXX
 .byte %00001110 ;     XXX
 .byte %00000100 ;      X
 .byte %00000100 ;      X
 .byte %00011110 ;    XXXX
 .byte %00111111 ;   XXXXXX
 .byte %01111111 ;  XXXXXXX
 .byte %11100011 ; XXX   XX
 .byte %11000011 ; XX    XX
 .byte %11000011 ; XX    XX
 .byte %11000111 ; XX   XXX
 .byte %11111111 ; XXXXXXXX
 .byte %00111100 ;   XXXX
 .byte %00001000 ;     X
 .byte %10001111 ; X   XXXX
 .byte %11100001 ; XXX    X
 .byte %00111111 ;   XXXXXX
 .byte 0
 .assert >(*-1) = >(DragonNormLeftGfx), error, "Sprite spans page."
DragonRoarLeftGfx:
 .byte %10000000 ; X
 .byte %01000000 ;  X
 .byte %00100110 ;   X  XX
 .byte %00011111 ;    XXXXX
 .byte %00001011 ;     X XX
 .byte %00001110 ;     XXX
 .byte %00011110 ;    XXXX
 .byte %00100100 ;   X  X
 .byte %01000100 ;  X   X
 .byte %10001110 ; X   XXX
 .byte %00011110 ;    XXXX
 .byte %00111111 ;   XXXXXX
 .byte %01111111 ;  XXXXXXX
 .byte %01111111 ;  XXXXXXX
 .byte %01111111 ;  XXXXXXX
 .byte %01111111 ;  XXXXXXX
 .byte %00111110 ;   XXXXX
 .byte %00011100 ;    XXX
 .byte %00001000 ;     X
 .byte %11111000 ; XXXXX
 .byte %10000000 ; X
 .byte %11100000 ; XXX
 .byte 0
 .assert >(*-1) = >(DragonRoarLeftGfx), error, "Sprite spans page."
DragonDeadLeftGfx:
 .byte %00001100 ;     XX
 .byte %00001100 ;     XX
 .byte %00001100 ;     XX
 .byte %00001110 ;     XXX
 .byte %00011011 ;    XX XX
 .byte %01111111 ;  XXXXXXX
 .byte %11001110 ; XX  XXX
 .byte %10000000 ; X
 .byte %11111100 ; XXXXXX
 .byte %11111110 ; XXXXXXX
 .byte %11111110 ; XXXXXXX
 .byte %01111110 ;  XXXXXX
 .byte %01111000 ;  XXXX
 .byte %00100000 ;   X
 .byte %01101110 ;  XX XXX
 .byte %01000010 ;  X    X
 .byte %01111110 ;  XXXXXX
 .byte 0
 .assert >(*-1) = >(DragonDeadLeftGfx), error, "Sprite spans page."
.if 0=1
DragonNormRightGfx:
 .byte %01100000 ;  XX
 .byte %11110000 ; XXXX
 .byte %11001111 ; XX  XXXX
 .byte %01111111 ;  XXXXXXX
 .byte %01110000 ;  XXX
 .byte %00100000 ;   X
 .byte %00100000 ;   X
 .byte %01111000 ;  XXXX
 .byte %11111100 ; XXXXXX
 .byte %11111110 ; XXXXXXX
 .byte %11000111 ; XX   XXX
 .byte %11000011 ; XX    XX
 .byte %11000011 ; XX    XX
 .byte %11100011 ; XXX   XX
 .byte %11111111 ; XXXXXXXX
 .byte %00111100 ;   XXXX
 .byte %00010000 ;    X
 .byte %11110001 ; XXXX   X
 .byte %10000111 ; X    XXX
 .byte %11111100 ; XXXXXX
 .byte 0
 .assert >(*-1) = >(DragonNormRightGfx), error, "Sprite spans page."
DragonRoarRightGfx:
 .byte %00000001 ;        X
 .byte %00000010 ;       X
 .byte %01100100 ;  XX  X
 .byte %11111000 ; XXXXX
 .byte %11010000 ; XX X
 .byte %01110000 ;  XXX
 .byte %01111000 ;  XXXX
 .byte %00100100 ;   X  X
 .byte %00100010 ;   X   X
 .byte %01110001 ;  XXX   X
 .byte %01111000 ;  XXXX
 .byte %11111100 ; XXXXXX
 .byte %11111110 ; XXXXXXX
 .byte %11111110 ; XXXXXXX
 .byte %11111110 ; XXXXXXX
 .byte %11111110 ; XXXXXXX
 .byte %01111100 ;  XXXXX
 .byte %00111000 ;   XXX
 .byte %00010000 ;    X
 .byte %00011111 ;    XXXXX
 .byte %00000001 ;        X
 .byte %00000111 ;      XXX
 .byte 0
 .assert >(*-1) = >(DragonRoarRightGfx), error, "Sprite spans page."
DragonDeadRightGfx:
 .byte %00110000 ;   XX
 .byte %00110000 ;   XX
 .byte %00110000 ;   XX
 .byte %01110000 ;  XXX
 .byte %11011000 ; XX XX
 .byte %11111110 ; XXXXXXX
 .byte %01110011 ;  XXX  XX
 .byte %00000001 ;        X
 .byte %00111111 ;   XXXXXX
 .byte %01111111 ;  XXXXXXX
 .byte %01111111 ;  XXXXXXX
 .byte %01111110 ;  XXXXXX
 .byte %00011110 ;    XXXX
 .byte %00000100 ;      X
 .byte %01110110 ;  XXX XX
 .byte %01000010 ;  X    X
 .byte %01111110 ;  XXXXXX
 .byte 0
 .assert >(*-1) = >(DragonDeadRightGfx), error, "Sprite spans page."
.endif

SwordCurrState:     .byte 0
SwordStates:        .byte $ff
                    .word SwordLeftGfx
SwordLeftGfx:
 .byte %00100000 ;   X
 .byte %01000000 ;  X
 .byte %11111111 ; XXXXXXXX
 .byte %01000000 ;  X
 .byte %00100000 ;   X
 .byte 0
 .assert >(*-1) = >(SwordLeftGfx), error, "Sprite spans page."
.if 0=1
SwordRightGfx:
 .byte %00000100 ;      X
 .byte %00000010 ;       X
 .byte %11111111 ; XXXXXXXX
 .byte %00000010 ;       X
 .byte %00000100 ;      X
 .byte 0
 .assert >(*-1) = >(SwordRightGfx), error, "Sprite spans page."
.endif

DotCurrState:       .byte 0
DotStates:          .byte $ff
                    .word DotGfx
DotGfx:
 .byte %10000000 ; X
 .byte 0

EasterEggGfx:
 .byte %11110000 ; XXXX
 .byte %10000000 ; X
 .byte %10000000 ; X
 .byte %10000000 ; X
 .byte %11110100 ; XXXX X
 .byte %00000100 ;      X
 .byte %10000111 ; X    XXX
 .byte %11100101 ; XXX  X X
 .byte %10000111 ; X    XXX
 .byte %10000000 ; X
 .byte %00000101 ;      X X
 .byte %11100101 ; XXX  X X
 .byte %10100111 ; X X  XXX
 .byte %11100001 ; XXX    X
 .byte %10000111 ; X    XXX
 .byte %11100000 ; XXX
 .byte %00000001 ;        X
 .byte %11100000 ; XXX
 .byte %10100000 ; X X
 .byte %11110000 ; XXXX
 .byte %00000001 ;        X
 .byte %01000000 ;  X
 .byte %11100000 ; XXX
 .byte %01000000 ;  X
 .byte %01000000 ;  X
 .byte %01000000 ;  X
 .byte %00000001 ;        X
 .byte %11100000 ; XXX
 .byte %10100000 ; X X
 .byte %11100000 ; XXX
 .byte %10000000 ; X
 .byte %11100000 ; XXX
 .byte %00000001 ;        X
 .byte %00100000 ;   X
 .byte %00100000 ;   X
 .byte %11100000 ; XXX
 .byte %10100000 ; X X
 .byte %11100000 ; XXX
 .byte %00000001 ;        X
 .byte %00000001 ;        X
 .byte %00000001 ;        X
 .byte %10001000 ; X   X
 .byte %10101000 ; X X X
 .byte %10101000 ; X X X
 .byte %10101000 ; X X X
 .byte %11111000 ; XXXXX
 .byte %00000001 ;        X
 .byte %11100000 ; XXX
 .byte %10100000 ; X X
 .byte %11110000 ; XXXX
 .byte %00000001 ;        X
 .byte %10000000 ; X
 .byte %11100000 ; XXX
 .byte %10001111 ; X   XXXX
 .byte %10001001 ; X   X  X
 .byte %00001111 ;     XXXX
 .byte %10001010 ; X   X X
 .byte %11101001 ; XXX X  X
 .byte %10000000 ; X
 .byte %10001110 ; X   XXX
 .byte %00001010 ;     X X
 .byte %11101110 ; XXX XXX
 .byte %10100000 ; X X
 .byte %11101000 ; XXX X
 .byte %10001000 ; X   X
 .byte %11101110 ; XXX XXX
 .byte %00001010 ;     X X
 .byte %10001110 ; X   XXX
 .byte %11100000 ; XXX
 .byte %10100100 ; X X  X
 .byte %10100100 ; X X  X
 .byte %00000100 ;      X
 .byte %10000000 ; X
 .byte %00001000 ;     X
 .byte %00001110 ;     XXX
 .byte %00001010 ;     X X
 .byte %00001010 ;     X X
 .byte %10000000 ; X
 .byte %00001110 ;     XXX
 .byte %00001010 ;     X X
 .byte %00001110 ;     XXX
 .byte %00001000 ;     X
 .byte %00001110 ;     XXX
 .byte %10000000 ; X
 .byte %00000100 ;      X
 .byte %00001110 ;     XXX
 .byte %00000100 ;      X
 .byte %00000100 ;      X
 .byte %00000100 ;      X
 .byte %10000000 ; X
 .byte %00000100 ;      X
 .byte %00001110 ;     XXX
 .byte %00000100 ;      X
 .byte %00000100 ;      X
 .byte %00000100 ;      X
 .byte 0
 .assert >(*-1) = >(EasterEggGfx), error, "Sprite spans page."
.if 0=1
EasterEggGfx2:
 .byte %01000100 ;  X   X
 .byte %01101100 ;  XX XX
 .byte %01010100 ;  X X X
 .byte %01000100 ;  X   X
 .byte %01000100 ;  X   X
 .byte %00000001 ;        X
 .byte %00010000 ;    X
 .byte %00010000 ;    X
 .byte %00010000 ;    X
 .byte %00010000 ;    X
 .byte %00000001 ;        X
 .byte %01001000 ;  X  X
 .byte %01010000 ;  X X
 .byte %01100000 ;  XX
 .byte %01010000 ;  X X
 .byte %01001000 ;  X  X
 .byte %00000001 ;        X
 .byte %01111000 ;  XXXX
 .byte %01000000 ;  X
 .byte %01111000 ;  XXXX
 .byte %01000000 ;  X
 .byte %01111000 ;  XXXX
 .byte %00000001 ;        X
 .byte %01000100 ;  X   X
 .byte %01101100 ;  XX XX
 .byte %01010100 ;  X X X
 .byte %01000100 ;  X   X
 .byte %01000100 ;  X   X
 .byte %00000001 ;        X
 .byte %01001000 ;  X  X
 .byte %01001000 ;  X  X
 .byte %01111000 ;  XXXX
 .byte %00000001 ;        X
 .byte %01000000 ;  X
 .byte %01110000 ;  XXX
 .byte %01000000 ;  X
 .byte %01000000 ;  X
 .byte %00000001 ;        X
 .byte %01111000 ;  XXXX
 .byte %01001000 ;  X  X
 .byte %01111000 ;  XXXX
 .byte %01000000 ;  X
 .byte %01000000 ;  X
 .byte %00000001 ;        X
 .byte %01000000 ;  X
 .byte %01000000 ;  X
 .byte %01111000 ;  XXXX
 .byte %01001000 ;  X  X
 .byte %01001000 ;  X  X
 .byte %00000001 ;        X
 .byte %01001000 ;  X  X
 .byte %01001000 ;  X  X
 .byte %01111000 ;  XXXX
 .byte %00001000 ;     X
 .byte %01111000 ;  XXXX
 .byte %00000001 ;        X
 .byte %01000100 ;  X   X
 .byte %01000100 ;  X   X
 .byte %01010100 ;  X X X
 .byte %01101100 ;  XX XX
 .byte %01000100 ;  X   X
 .byte %00000001 ;        X
 .byte %01111000 ;  XXXX
 .byte %01001000 ;  X  X
 .byte %01111100 ;  XXXXX
 .byte %00000001 ;        X
 .byte %01111000 ;  XXXX
 .byte %01000000 ;  X
 .byte %01111000 ;  XXXX
 .byte %00001000 ;     X
 .byte %01111000 ;  XXXX
 .byte %00000001 ;        X
 .byte %01001000 ;  X  X
 .byte %01001000 ;  X  X
 .byte %01111000 ;  XXXX
 .byte %01001000 ;  X  X
 .byte %01001000 ;  X  X
 .byte %00000001 ;        X
 .byte %01111000 ;  XXXX
 .byte %01001000 ;  X  X
 .byte %01111000 ;  XXXX
 .byte %01000000 ;  X
 .byte %01111000 ;  XXXX
 .byte %00000001 ;        X
 .byte %01000000 ;  X
 .byte %01110000 ;  XXX
 .byte %01000000 ;  X
 .byte %01000000 ;  X
 .byte %00000001 ;        X
 .byte %01111000 ;  XXXX
 .byte %01001000 ;  X  X
 .byte %01111000 ;  XXXX
 .byte %01000000 ;  X
 .byte %01111000 ; .XXXX
 .byte %00000001 ;        X
 .byte 0
 .assert >(*-1) = >(EasterEggGfx2), error, "Sprite spans page."
.endif
EasterEggDynamic:   .byte roomnum_SecretRoom, 80, 105
EasterEggCurrState: .byte 0
EasterEggStates:    .byte $ff
                    .word EasterEggGfx

ChaliceCurrState:   .byte 0
ChaliceStates:      .byte $ff
                    .word ChaliceGfx
ChaliceGfx:
 .byte %10000001 ; X      X
 .byte %10000001 ; X      X
 .byte %11000011 ; XX    XX
 .byte %01111110 ;  XXXXXX
 .byte %01111110 ;  XXXXXX
 .byte %00111100 ;   XXXX
 .byte %00011000 ;    XX
 .byte %00011000 ;    XX
 .byte %01111110 ;  XXXXXX
 .byte 0
 .assert >(*-1) = >(ChaliceGfx), error, "Sprite spans page."

NullCurrState:      .byte 0
NullStates:         .byte $ff
                    .word NullGfx
NullGfx:            .byte 0

NumberDynamic:      .byte roomnum_NumberRoom, 80, 64
NumberStates:       .byte 1
                    .word Number1Gfx
                    .byte 3
                    .word Number2Gfx
                    .byte $ff
                    .word Number3Gfx

MagnetCurrState:    .byte 0
MagnetStates:       .byte $ff
                    .word MagnetGfx1
MagnetGfx1:
 .byte %00111100 ;   XXXX
 .byte %01111110 ;  XXXXXX
 .byte %11100111 ; XXX  XXX
 .byte %11000011 ; XX    XX
 .byte %11000011 ; XX    XX
 .byte %11000011 ; XX    XX
 .byte %11000011 ; XX    XX
 .byte %11000011 ; XX    XX
 .byte 0
 .assert >(*-1) = >(MagnetGfx1), error, "Sprite spans page."


Rooms:
roomnum_NumberRoom = (* - Rooms) / .sizeof(RoomType)
    .word NumberRoom
    .byte ColorType::purple, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_NumberRoom, roomnum_NumberRoom, roomnum_NumberRoom, roomnum_NumberRoom

roomnum_BelowYellowCastleLeftThinWall = (* - Rooms) / .sizeof(RoomType)
roomrange_reddragon_start    = roomnum_BelowYellowCastleLeftThinWall
roomrange_yellowdragon_start = roomnum_BelowYellowCastleLeftThinWall
roomrange_greendragon_start  = roomnum_BelowYellowCastleLeftThinWall
roomrange_sword_start        = roomnum_BelowYellowCastleLeftThinWall
roomrange_bridge_start       = roomnum_BelowYellowCastleLeftThinWall
roomrange_yellowkey_start    = roomnum_BelowYellowCastleLeftThinWall
roomrange_whitekey_start     = roomnum_BelowYellowCastleLeftThinWall
roomrange_blackkey_start     = roomnum_BelowYellowCastleLeftThinWall
roomrange_bat_start          = roomnum_BelowYellowCastleLeftThinWall
roomrange_magnet_start       = roomnum_BelowYellowCastleLeftThinWall
    .word BelowYellowCastle
    .byte ColorType::darkgreen, ColorType::lightergray
    .byte RoomControlType::leftthinwall_pfref
    .byte roomnum_BlueMazeEntry, roomnum_BelowYellowCastle, roomnum_downfrom_BelowYellowCastleLeftThinWall, roomnum_BelowYellowCastleRightThinWall

roomnum_BelowYellowCastle = (* - Rooms) / .sizeof(RoomType)
    .word BelowYellowCastle
    .byte ColorType::green, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_YellowCastle, roomnum_BelowYellowCastleRightThinWall, roomnum_downfrom_BelowYellowCastleGreen, roomnum_BelowYellowCastleLeftThinWall

roomnum_BelowYellowCastleRightThinWall = (* - Rooms) / .sizeof(RoomType)
    .word LeftOfName
    .byte ColorType::darkyellow, ColorType::lightergray
    .byte RoomControlType::rightthinwall_pfref
    .byte roomnum_BlueMazeBottom, roomnum_BelowYellowCastleLeftThinWall, roomnum_downfrom_BelowYellowCastleRightThinWall, roomnum_BelowYellowCastle

roomnum_BlueMazeTop = (* - Rooms) / .sizeof(RoomType)
    .word BlueMazeTop
    .byte ColorType::blue, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_BlackCastle, roomnum_BlueMaze1, roomnum_BlueMazeCenter, roomnum_BlueMazeBottom

roomnum_BlueMaze1 = (* - Rooms) / .sizeof(RoomType)
    .word BlueMaze1
    .byte ColorType::blue, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_TopEntryRoom2, roomnum_BlueMazeBottom, roomnum_BlueMazeEntry, roomnum_BlueMazeTop

roomnum_BlueMazeBottom = (* - Rooms) / .sizeof(RoomType)
    .word BlueMazeBottom
    .byte ColorType::blue, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_BlueMazeCenter, roomnum_BlueMazeTop, roomnum_BelowYellowCastleRightThinWall, roomnum_BlueMaze1

roomnum_BlueMazeCenter = (* - Rooms) / .sizeof(RoomType)
    .word BlueMazeCenter
    .byte ColorType::blue, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_BlueMazeTop, roomnum_BlueMazeEntry, roomnum_BlueMazeBottom, roomnum_BlueMazeEntry

roomnum_BlueMazeEntry = (* - Rooms) / .sizeof(RoomType)
    .word BlueMazeEntry
    .byte ColorType::blue, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_BlueMaze1, roomnum_BlueMazeCenter, roomnum_BelowYellowCastleLeftThinWall, roomnum_BlueMazeCenter

roomnum_MazeMiddle = (* - Rooms) / .sizeof(RoomType)
    .word MazeMiddle
    .byte ColorType::invisible, ColorType::invisible
    .byte RoomControlType::pfref_pfp
    .byte roomnum_MazeEntry, roomnum_MazeEntry, roomnum_MazeSide, roomnum_MazeEntry

roomnum_MazeEntry = (* - Rooms) / .sizeof(RoomType)
    .word MazeEntry
    .byte ColorType::invisible, ColorType::invisible
    .byte RoomControlType::pfref_pfp
    .byte roomnum_BelowYellowCastleRightThinWall, roomnum_MazeMiddle, roomnum_MazeMiddle, roomnum_MazeMiddle

roomnum_MazeSide = (* - Rooms) / .sizeof(RoomType)
    .word MazeSide
    .byte ColorType::invisible, ColorType::invisible
    .byte RoomControlType::pfref_pfp
    .byte roomnum_MazeMiddle, roomnum_SideCorridor1, roomnum_OtherPurpleRoom, roomnum_SideCorridor2

roomnum_SideCorridor1 = (* - Rooms) / .sizeof(RoomType)
    .word SideCorridor
    .byte ColorType::lightblue, ColorType::lightergray
    .byte RoomControlType::rightthinwall_pfref
    .byte roomnum_OtherPurpleRoom, roomnum_SideCorridor2, roomnum_TopEntryRoom2, roomnum_MazeSide

roomnum_SideCorridor2 = (* - Rooms) / .sizeof(RoomType)
    .word SideCorridor
    .byte ColorType::lightgreen, ColorType::lightergray
    .byte RoomControlType::leftthinwall_pfref
    .byte roomnum_WhiteCastle, roomnum_MazeSide, roomnum_TopEntryRoom1, roomnum_SideCorridor1

roomnum_TopEntryRoom1 = (* - Rooms) / .sizeof(RoomType)
    .word TopEntryRoom
    .byte ColorType::turquoise, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_SideCorridor2, roomnum_BlackCastle, roomnum_WhiteCastle, roomnum_BlackCastle

roomnum_WhiteCastle = (* - Rooms) / .sizeof(RoomType)
    .word CastleDef
    .byte ColorType::lightestgray, ColorType::lightestgray
    .byte RoomControlType::pfref
    .byte roomnum_TopEntryRoom1, roomnum_WhiteCastle, roomnum_SideCorridor2, roomnum_WhiteCastle

roomnum_BlackCastle = (* - Rooms) / .sizeof(RoomType)
    .word CastleDef
    .byte ColorType::black, ColorType::darkgray
    .byte RoomControlType::pfref
    .byte roomnum_BelowYellowCastleLeftThinWall, roomnum_OtherPurpleRoom, roomnum_BlueMazeTop, roomnum_OtherPurpleRoom

roomnum_YellowCastle = (* - Rooms) / .sizeof(RoomType)
    .word CastleDef
    .byte ColorType::yellow, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_BlueMazeBottom, roomnum_BelowYellowCastleRightThinWall, roomnum_BelowYellowCastle, roomnum_BelowYellowCastleLeftThinWall

roomnum_YellowCastleEntry = (* - Rooms) / .sizeof(RoomType)
roomrange_blackkey_end = roomnum_YellowCastleEntry
    .word NumberRoom
    .byte ColorType::yellow, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_YellowCastleEntry, roomnum_YellowCastleEntry, roomnum_YellowCastleEntry, roomnum_YellowCastleEntry

roomnum_BlackMaze1 = (* - Rooms) / .sizeof(RoomType)
roomrange_chalice_start = roomnum_BlackMaze1
    .word BlackMaze1
    .byte ColorType::invisible, ColorType::invisible
    .byte RoomControlType::pfref_pfp
    .byte roomnum_BlackMaze3, roomnum_BlackMaze2, roomnum_BlackMaze3, roomnum_BlackMazeEntry

roomnum_BlackMaze2 = (* - Rooms) / .sizeof(RoomType)
    .word BlackMaze2
    .byte ColorType::invisible, ColorType::invisible
    .byte RoomControlType::pfp
    .byte roomnum_BlackMazeEntry, roomnum_BlackMaze3, roomnum_BlackMazeEntry, roomnum_BlackMaze1

roomnum_BlackMaze3 = (* - Rooms) / .sizeof(RoomType)
    .word BlackMaze3
    .byte ColorType::invisible, ColorType::invisible
    .byte RoomControlType::pfp
    .byte roomnum_BlackMaze1, roomnum_BlackMazeEntry, roomnum_BlackMaze1, roomnum_BlackMaze2

roomnum_BlackMazeEntry = (* - Rooms) / .sizeof(RoomType)
roomrange_whitekey_end = roomnum_BlackMazeEntry
    .word BlackMazeEntry
    .byte ColorType::invisible, ColorType::invisible
    .byte RoomControlType::pfref_pfp
    .byte roomnum_BlackMaze2, roomnum_BlackMaze1, roomnum_BlackCastleEntry, roomnum_BlackMaze3

roomnum_RedMaze1 = (* - Rooms) / .sizeof(RoomType)
    .word RedMaze1
    .byte ColorType::red, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_RedMazeBottom, roomnum_RedMazeTop, roomnum_RedMazeBottom, roomnum_RedMazeTop

roomnum_RedMazeTop = (* - Rooms) / .sizeof(RoomType)
    .word RedMazeTop
    .byte ColorType::red, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_WhiteCastleEntry, roomnum_RedMaze1, roomnum_WhiteCastleEntry, roomnum_RedMaze1

roomnum_RedMazeBottom = (* - Rooms) / .sizeof(RoomType)
    .word RedMazeBottom
    .byte ColorType::red, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_RedMaze1, roomnum_WhiteCastleEntry, roomnum_RedMaze1, roomnum_WhiteCastleEntry

roomnum_WhiteCastleEntry = (* - Rooms) / .sizeof(RoomType)
roomrange_chalice_end = roomnum_WhiteCastleEntry
    .word WhiteCastleEntry
    .byte ColorType::red, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_RedMazeTop, roomnum_RedMazeBottom, roomnum_RedMazeTop, roomnum_RedMazeBottom

roomnum_BlackCastleEntry = (* - Rooms) / .sizeof(RoomType)
    .word TwoExitRoom
    .byte ColorType::red, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_uprightdownleftfrom_BlackCastleEntry, roomnum_uprightdownleftfrom_BlackCastleEntry, roomnum_uprightdownleftfrom_BlackCastleEntry, roomnum_uprightdownleftfrom_BlackCastleEntry

roomnum_OtherPurpleRoom = (* - Rooms) / .sizeof(RoomType)
    .word NumberRoom
    .byte ColorType::purple, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_TopEntryRoom2, roomnum_BlueMazeCenter, roomnum_downfrom_OtherPurpleRoom, roomnum_BlueMazeEntry

roomnum_TopEntryRoom2 = (* - Rooms) / .sizeof(RoomType)
roomrange_reddragon_end    = roomnum_TopEntryRoom2
roomrange_yellowdragon_end = roomnum_TopEntryRoom2
roomrange_greendragon_end  = roomnum_TopEntryRoom2
roomrange_sword_end        = roomnum_TopEntryRoom2
roomrange_bridge_end       = roomnum_TopEntryRoom2
roomrange_yellowkey_end    = roomnum_TopEntryRoom2
roomrange_bat_end          = roomnum_TopEntryRoom2
roomrange_magnet_end       = roomnum_TopEntryRoom2
    .word TopEntryRoom
    .byte ColorType::red, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_upfrom_TopEntryRoom, roomnum_BelowYellowCastleLeftThinWall, roomnum_BlackCastle, roomnum_BelowYellowCastleRightThinWall

roomnum_SecretRoom = (* - Rooms) / .sizeof(RoomType)
    .word BelowYellowCastle
    .byte ColorType::purple, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_BlueMazeBottom, roomnum_BelowYellowCastleLeftThinWall, roomnum_BlueMazeBottom, roomnum_BelowYellowCastleRightThinWall


RoomDiffs:
; room differences for different levels
; level 1                                     level 2                 level 3

roomnum_downfrom_BelowYellowCastleLeftThinWall = (* - RoomDiffs) | $80
.byte roomnum_BlackCastle,                    roomnum_WhiteCastle,    roomnum_WhiteCastle

roomnum_downfrom_BelowYellowCastleGreen = (* - RoomDiffs) | $80
.byte roomnum_BlueMaze1,                      roomnum_YellowCastle,   roomnum_YellowCastle

roomnum_downfrom_BelowYellowCastleRightThinWall = (* - RoomDiffs) | $80
.byte roomnum_TopEntryRoom2,                  roomnum_MazeEntry,      roomnum_MazeEntry

roomnum_uprightdownleftfrom_BlackCastleEntry = (* - RoomDiffs) | $80
.byte roomnum_OtherPurpleRoom,                roomnum_BlackMazeEntry, roomnum_BlackMazeEntry

roomnum_downfrom_OtherPurpleRoom = (* - RoomDiffs) | $80
.byte roomnum_BlackCastleEntry,               roomnum_SideCorridor1,  roomnum_SideCorridor1

roomnum_upfrom_TopEntryRoom = (* - RoomDiffs) | $80
.byte roomnum_BelowYellowCastleRightThinWall, roomnum_SideCorridor1,  roomnum_SideCorridor1


Objects:
objoffset_InvisibleSurround = (* - Objects)
    .word SurroundDynamic
    .word SurroundCurrState
    .word SurroundStates
    .byte ColorType::orange, ColorType::lightestgray
    .byte 7

objoffset_PortCullis1 = (* - Objects)
    .word PortDynamic1
    .word PortCurrStateBase+0
    .word PortStates
    .byte ColorType::black, ColorType::black
    .byte 0

objoffset_PortCullis2 = (* - Objects)
    .word PortDynamic2
    .word PortCurrStateBase+1
    .word PortStates
    .byte ColorType::black, ColorType::black
    .byte 0

objoffset_PortCullis3 = (* - Objects)
    .word PortDynamic3
    .word PortCurrStateBase+2
    .word PortStates
    .byte ColorType::black, ColorType::black
    .byte 0

objoffset_EasterEgg = (* - Objects)
    .word EasterEggDynamic
    .word EasterEggCurrState
    .word EasterEggStates
    .byte ColorType::flash, ColorType::black
    .byte 0

objoffset_Number = (* - Objects)
    .word NumberDynamic
    .word NumberCurrState
    .word NumberStates
    .byte ColorType::green, ColorType::black
    .byte 0

objoffset_DragonRhindle = (* - Objects)
    .word RedDragonDynamic
    .word RedDragonDynamic+DynamicType::state
    .word DragonStates
    .byte ColorType::red, ColorType::white
    .byte 0

objoffset_DragonYorgle = (* - Objects)
    .word YellowDragonDynamic
    .word YellowDragonDynamic+DynamicType::state
    .word DragonStates
    .byte ColorType::yellow, ColorType::gray
    .byte 0

objoffset_DragonGrundle = (* - Objects)
    .word GreenDragonDynamic
    .word GreenDragonDynamic+DynamicType::state
    .word DragonStates
    .byte ColorType::green, ColorType::black
    .byte 0

objoffset_Sword = (* - Objects)
    .word SwordDynamic
    .word SwordCurrState
    .word SwordStates
    .byte ColorType::yellow, ColorType::gray
    .byte 0

objoffset_Bridge = (* - Objects)
    .word BridgeDynamic
    .word BridgeCurrState
    .word BridgeStates
    .byte ColorType::purple, ColorType::darkgray
    .byte 7

objoffset_YellowKey = (* - Objects)
    .word YellowKeyDynamic
    .word KeyCurrState
    .word KeyStates
    .byte ColorType::yellow, ColorType::gray
    .byte 0

objoffset_WhiteKey = (* - Objects)
    .word WhiteKeyDynamic
    .word KeyCurrState
    .word KeyStates
    .byte ColorType::white, ColorType::white
    .byte 0

objoffset_BlackKey = (* - Objects)
    .word BlackKeyDynamic
    .word KeyCurrState
    .word KeyStates
    .byte ColorType::black, ColorType::black
    .byte 0

objoffset_BlackBatKnubberrub = (* - Objects)
    .word BlackBatDynamic
    .word BlackBatDynamic+DynamicType::state
    .word BatStates
    .byte ColorType::black, ColorType::black
    .byte 0

objoffset_BlackDot = (* - Objects)
    .word DotDynamic
    .word DotCurrState
    .word DotStates
    .byte ColorType::invisible, ColorType::invisible
    .byte 0

objoffset_EnchantedChalice = (* - Objects)
    .word ChaliceDynamic
    .word ChaliceCurrState
    .word ChaliceStates
    .byte ColorType::flash, ColorType::gray
    .byte 0

objoffset_Magnet = (* - Objects)
    .word MagnetDynamic
    .word MagnetCurrState
    .word MagnetStates
    .byte ColorType::black, ColorType::gray
    .byte 0

objoffset_Null = (* - Objects)
    .word BridgeDynamic
    .word NullCurrState
    .word NullStates
    .byte ColorType::black, ColorType::black
    .byte 0

; 6502 startup vectors
.segment "VECTORS"
    .word StartGame
    .word StartGame
    .word StartGame
