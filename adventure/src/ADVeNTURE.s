 .setcpu "6502"
 .include "vcs.inc"
 .include "enums.inc"
 .include "structs.inc"
 .include "gfx/gr/all.inc"
 .include "gfx/pf/all.inc"

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
;* Ported to cc65 by Mike Murphy (mike@emu7800.net)                            *
;*******************************************************************************

; 2600 Memory Map
; ---------------
; 0000-007f TIA     Mirrored every $100 [$000-$900]
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

.zeropage   ; segment mapped to $80

roomgfx_base:                   .word 0
p0gfx_base:                     .word 0
p1gfx_base:                     .word 0
player0pos:                     .tag ObjectPosType
player1pos:                     .tag ObjectPosType
ManInfo:                        .tag ObjectInfoType
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
unread1:                        .byte 0     ; unread byte
cached_joystick:                .byte 0
portcullis_number:              .byte 0
direction_wanted:               .byte 0
obj_counter:                    .byte 0
object_carried:                 .byte 0     ; object carried by the man
objman_x_delta:                 .byte 0
objman_y_delta:                 .byte 0
curr_obj_number:                .byte 0

GameObjectsWorkingArea:
DotInfo:                        .tag ObjectInfoType
RedDragonInfo:                  .tag LongObjectInfoType
RedDragonCurrBase:              .byte 0
YellowDragonInfo:               .tag LongObjectInfoType
YellowDragonCurrBase:           .byte 0
GreenDragonInfo:                .tag LongObjectInfoType
GreenDragonCurrBase:            .byte 0
MagnetInfo:                     .tag ObjectInfoType
SwordInfo:                      .tag ObjectInfoType
ChaliceInfo:                    .tag ObjectInfoType
BridgeInfo:                     .tag ObjectInfoType
YellowKeyInfo:                  .tag ObjectInfoType
WhiteKeyInfo:                   .tag ObjectInfoType
BlackKeyInfo:                   .tag ObjectInfoType
PortCurrBase:                   .byte 0, 0, 0
BlackBatInfo:                   .tag LongObjectInfoType
BlackBatCurrBase:               .byte 0
BlackBatCarriedObject:          .byte 0      ; object being carried by the Black Bat
BlackBatFedUp:                  .byte 0

objstore_ptr:                   .word 0
objdelta:                       .byte 0
MoveGameObjectArg_ObjNumber:    .byte 0      ; identifies the object to move (used by MoveGameObject)
MoveGameObjectArg_Difficulty:   .byte 0      ; difficulty for MoveGameObject to use (used by MoveGameObject)
joystick_record:                .byte 0
tmp1:                           .byte 0
SurroundInfo:                   .tag ObjectInfoType
GetObjectState_Arg:             .byte 0
NumberCurrState:                .byte 0      ; 0=lvl1, 2=lvl2, 4=lvl3
is_game_complete:               .byte 0      ; $ff=yes, 0=no
sound_duration_counter:         .byte 0
sound_type:                     .byte 0      ; NoiseType
linked_obj_index:               .byte 0
PrevManInfo:                    .tag ObjectInfoType
input_counter:                  .word 0

stack_space:                    ; $e7-$ff (12 frames)

.code

START:      jmp StartGame

            nop
            nop
            nop
            nop
            nop

PrintDisplay:
            sta HMCLR       ;clear horizontal motion
            lda player0pos+ObjectPosType::xcoord
            ldx #SpriteType::object1
            jsr PosSpriteX
            lda player1pos+ObjectPosType::xcoord
            ldx #SpriteType::object2
            jsr PosSpriteX
            lda ManInfo+ObjectInfoType::pos+ObjectPosType::xcoord
            ldx #SpriteType::man
            jsr PosSpriteX
            sta WSYNC       ;wait for horizontal blank
            sta HMOVE       ;apply horizontal motion
            sta CXCLR       ;clear collision latches
            lda ManInfo+ObjectInfoType::pos+ObjectPosType::ycoord
            sec
            sbc #4                    ;and adjust it by four scan lines
            sta man_y2                ; for printing (so Y coordinate specifies middle)

:           lda INTIM                 ;3  3   wait until middle of line 38, 0-based
            bne :-                    ;3  6
                                      ;   6*3=18 color clocks minimum, 36 max

            lda #0                    ;2  2
            sta p0gfx_offset          ;3  5   set Player0 definition index
            sta p1gfx_offset          ;3  8   set Player1 definition index
            sta roomgfx_offset        ;3 11   set room definition index
            sta GRP1                  ;3 14   clear any graphics for Player1
            lda #1                    ;2 16
            sta VDELP1                ;3 19   vertically delay Player1
            lda #104                  ;2 21   set counter (208 actual scanlines)
            sta scan_line             ;3 24
                                      ;  24*3=72 color clocks

            ; Good place for a WSYNC here, but spills over instead:
            ;  92 timer expiration occurs mid scanline (35.4 lines, .4*228=92)
            ; +36 max additional time needed to recognize expiration
            ; +72 initialing pxgfx_offsets and other stuff
            ; 200 < 228

; Print top line of room (line 39, 0-based)
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

; Picture start (line 40, 0-based)
            lda #0
            sta VBLANK                ;clear any vertical blank
            jmp PrintPlayer0

; Print Player1 (Object2)
PrintPlayer1:
            lda scan_line
            sec                       ;have we reached Object2's Y coordinate?
            sbc player1pos+ObjectPosType::ycoord
            sta WSYNC                 ;wait for horizontal blank
            bpl PrintPlayer0          ;if not, branch
            ldy p1gfx_offset          ;get the Player01 definition index
            lda (p1gfx_base),y        ;get the next Player01 definition byte
            sta GRP1                  ; and display
            beq PrintPlayer0          ;if zero then definition finished
            inc p1gfx_offset          ;goto next Player01 definition byte

; Print Player0 (Object1), Ball (Man), and Room
PrintPlayer0:
            ldx #0
            lda scan_line
            sec                      ;have we reached the Object1's Y coordinate?
            sbc player0pos+ObjectPosType::ycoord
            bpl :+                   ;if not then branch
            ldy p0gfx_offset         ;get Player00 definition index
            lda (p0gfx_base),y       ;get the next Player00 definition byte
            tax
            beq :+                   ;if zero then definition finished
            inc p0gfx_offset         ;go to next Player00 definition byte
:           ldy #0                   ;disable Ball graphic
            lda scan_line
            sec                      ;have we reached the Man's
            sbc man_y2               ; Y coordinate?
            and #$fc                 ;mask value to four either side (getting depth of 8)
            bne :+                   ;if not, branch
            ldy #2                   ;enable Ball graphic
:           lda scan_line
            and #15                  ;have we reached a sixteenth scan line?
            bne :++                 ;if not, branch
            sta WSYNC                ;wait for horizontal blank
            sty ENABL                ;enable Ball (if wanted)
            stx GRP0                 ;display Player00 definition byte (if wanted)
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
            bpl PrintPlayer1         ;if not, branch
            sta VBLANK               ;turn on VBLANK
            jmp :++

; Print Player0 (Object1) and Ball (Man)
:           sta WSYNC                ;wait for horizontal blank
            sty ENABL                ;enable ball (if wanted)
            stx GRP0                 ;display Player0 definition byte (if wanted)
            jmp :--

:           lda #0
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

DoVSYNC:    lda INTIM           ;get timer output
            bne DoVSYNC         ;wait for time-out
            lda #%10
            sta WSYNC           ;wait for horizontal blank
            sta VBLANK          ;start vertical blanking
            sta WSYNC
            sta WSYNC
            sta WSYNC
            sta VSYNC           ;start vertical sync
            sta WSYNC
            sta WSYNC
            lda #0
            sta WSYNC           ;wait for horizontal blank
            sta VSYNC           ;end vertical sync
            lda #42             ;set clock interval to 42*(64*3)/228 = 35.4 scanlines
            sta TIM64T          ; count down next frame
            rts

; set up a room for print
SetupRoomPrint:
            lda ManInfo+ObjectInfoType::room_num         ;get current room number
            jsr RoomNumToAddress  ;convert it to an address
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
            lda object1           ;if the Object1 is the
            cmp #0                ; invisible surround
            beq SwapPrintObjects  ; then branch to swap (we want it was Player01)
            cmp #$5a              ;if the first object is the bridge then
            bne SetupObjectPrint  ; swap the objects (we want it as Player01)
            lda object2           ;if the Object2 is the
            cmp #0                ; invisible surround then branch to leave
            beq SetupObjectPrint  ; it (we want it as Player01)
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
            lda a:Objects+ObjectType::info_ptr,x
            sta dr_ptr
            lda a:Objects+ObjectType::info_ptr+1,x
            sta dr_ptr+1
            ldy #ObjectInfoType::pos+ObjectPosType::xcoord
            lda (dr_ptr),y        ;get Object1's X coordinate
            sta player0pos+ObjectPosType::xcoord  ; and store for print
            ldy #ObjectInfoType::pos+ObjectPosType::ycoord
            lda (dr_ptr),y        ;get Object1's Y coordinate
            sta player0pos+ObjectPosType::ycoord  ; and store for print
            lda a:Objects+ObjectType::currstate_ptr,x
            sta dr_ptr
            lda a:Objects+ObjectType::currstate_ptr+1,x
            sta dr_ptr+1
            ldy #0
            lda (dr_ptr),y        ;retrieve Object1's current state
            sta GetObjectState_Arg
            lda a:Objects+ObjectType::states_ptr,x
            sta dr_ptr
            lda a:Objects+ObjectType::states_ptr+1,x
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
            lda a:Objects+ObjectType::color,x
            jsr ChangeColor       ;change if necessary
            sta COLUP0            ; and set color luminance00
            jmp :++
; B&W
:           lda a:Objects+ObjectType::bw_color,x
            jsr ChangeColor       ;change if necessary
            sta COLUP0            ;set color luminance00
; Object1 resize
:           lda a:Objects+ObjectType::size,x
            ora #$10              ;and set to larger size if necessary
            sta NUSIZ0            ;(used by bridge and invisible surround)
; set up Object2 to print
            ldx object2
            lda a:Objects+ObjectType::info_ptr,x
            sta dr_ptr
            lda a:Objects+ObjectType::info_ptr+1,x
            sta dr_ptr+1
            ldy #ObjectInfoType::pos+ObjectPosType::xcoord
            lda (dr_ptr),y        ;get Object2's X coordinate
            sta player1pos+ObjectPosType::xcoord  ; and store for print
            ldy #ObjectInfoType::pos+ObjectPosType::ycoord
            lda (dr_ptr),y        ;get Object2's Y coordinate
            sta player1pos+ObjectPosType::ycoord  ; and store for print
            lda a:Objects+ObjectType::currstate_ptr,x
            sta dr_ptr
            lda a:Objects+ObjectType::currstate_ptr+1,x
            sta dr_ptr+1
            ldy #0
            lda (dr_ptr),y        ;retrieve Object2's current state
            sta GetObjectState_Arg
            lda a:Objects+ObjectType::states_ptr,x
            sta dr_ptr
            lda a:Objects+ObjectType::states_ptr+1,x
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
            lda a:Objects+ObjectType::color,x
            jsr ChangeColor       ;change if necessary
            sta COLUP1            ;and set color luminance01
            jmp :++
; B&W
:           lda a:Objects+ObjectType::bw_color,x
            jsr ChangeColor       ;change if necessary
            sta COLUP1            ;and set color luminance01
; Object2 size
:           lda a:Objects+ObjectType::size,x
            ora #$10              ;and set to large size if necessary
            sta NUSIZ1            ;(used by bridge and invisible surround)
            rts

; fill cache with two objects in this room
CacheObjects:
            ldy obj_counter       ;get last object
            lda #$a2              ;set cache to no-objects
            sta object1
            sta object2
MoveNextObject:
            tya
            clc                   ;goto the next object to
            adc #9                ; check (add nine)
            cmp #162              ;check if over maximum (9*18)
            bcc GetObjectsInfo
            lda #0                ;if so, wrap to zero
GetObjectsInfo:
            tay
            lda Objects+ObjectType::info_ptr,y
            sta dr_ptr
            lda Objects+ObjectType::info_ptr+1,y
            sta dr_ptr+1
            ldx #0
            lda (dr_ptr,x)          ;get object's current room
            cmp ManInfo+ObjectInfoType::room_num           ; is it in this room?
            bne CheckForMoreObjects ;if not lets try next object (branch)
            lda object1             ;check first slot
            cmp #$a2                ;if not default (no-object)
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

; convert room number to address
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

; Get pointer to current state, setting y
GetObjectState:
            ldy #0
            lda GetObjectState_Arg
:           cmp (dr_ptr),y        ;have we found it in the list of states?
            bcc :+                ;if nearing it then found it and return
            beq :+                ;if found it then return
            iny
            iny                   ;goto next state in list of states
            iny
            jmp :-
:           rts

CheckInput: inc input_counter
            bne :+
            inc input_counter+1
            bne :+
            lda #$80              ;wrap the high count (indicating timeout) if needed
            sta input_counter+1
:           lda SWCHA             ;get joystick values
            cmp #$ff              ;if any movement then branch
            bne :+
            lda SWCHB             ;get the console switches
            and #ConsoleSwitchType::select_and_reset
            cmp #ConsoleSwitchType::select_and_reset ;have either of them been used?
            beq :++               ;if not branch
:           lda #0                ;zero the high count of the
            sta input_counter+1   ; switches or joystick have been used
:           rts

; change color if necessary
ChangeColor:
.assert $80 + (ColorType::flash >> 1) = input_counter && (ColorType::flash & 2) = 2, error, "ColorType::flash value and input_counter address invariant broken"
            lsr a                 ;if bit 0 of the color is set
            bcc :+                ; then the room is to flash
            tay                   ;these two instructions could be
            lda $0080,y           ; replaced with lda input_counter
:           ldy input_counter+1   ;get the input counter
            bpl :+                ;if console/joystick moved recently then branch
            eor input_counter+1   ;vary colors after a period of inactivty to limit CRT burn in
            and #$fb              ; turn down the luminance
:           asl a                 ; and restore original color if necessary
            rts

; get the address of the dynamic information for an object
GetObjectAddress:
            lda a:Objects+ObjectType::info_ptr,x
            sta dr_ptr            ;get and store the low address
            lda a:Objects+ObjectType::info_ptr+1,x
            sta dr_ptr+1          ;get and store the high address
            rts

; game start entry point
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

MainGameLoop:
            jsr CheckGameStart    ;check for game start
            jsr MakeSound         ;make noise if necessary
            jsr CheckInput        ;check for input
            lda is_game_complete  ;ff = yes
            bne NonActiveLoop
            lda ChaliceInfo+ObjectInfoType::room_num  ;get the room the chalice is in
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

CheckGameStart:
            lda SWCHB             ;get the console switches
            eor #$ff              ;flip (as reset active low)
            and cached_swchb      ;compare with what was before
            and #ConsoleSwitchType::reset
            beq NotReset          ;if no reset then branch
            lda is_game_complete
            cmp #$ff
            beq SetupRoomObjects  ;branch since game has been completed

ReincarnatePlayer:
            lda #roomnum_YellowCastle
            sta ManInfo+ObjectInfoType::room_num         ;make it the current room
            sta PrevManInfo+ObjectInfoType::room_num     ;make it the previous room
            lda #$50              ;get the X coordinate
            sta ManInfo+ObjectInfoType::pos+ObjectPosType::xcoord           ;make it the current man X coordinate
            sta PrevManInfo+ObjectInfoType::pos+ObjectPosType::xcoord       ;make it the previous man X coordinate
            lda #$20              ;get the Y coordinate
            sta ManInfo+ObjectInfoType::pos+ObjectPosType::ycoord           ;make it the current man Y coordinate
            sta PrevManInfo+ObjectInfoType::pos+ObjectPosType::ycoord       ;make it the previous man Y coordinate
            lda #0
            sta RedDragonCurrBase       ;set the red dragon's state to OK
            sta YellowDragonCurrBase    ;set the yellow dragon's state to OK
            sta GreenDragonCurrBase     ;set the green dragon's state to OK
            sta sound_duration_counter  ;set the note count to zero
            lda #$a2
            sta object_carried    ;set no object being carried
NotReset:   lda SWCHB             ;get the console switches
            eor #$ff              ;flip (as select active low)
            and cached_swchb      ;compare with what was before
            and #ConsoleSwitchType::select
            beq NotSelect         ;branch if select not being used
            lda ManInfo+ObjectInfoType::room_num  ;get the current room
            cmp #roomnum_NumberRoom
            bne SetupRoomObjects  ;branch if not
            lda NumberCurrState   ;increment the level
            clc                   ; number (by two)
            adc #2
            cmp #6                ;have we reached the maximum?
            bcc ResetSetup
            lda #0                ;if yep then set back to zero
ResetSetup: sta NumberCurrState    ;store the new level number
SetupRoomObjects:
            lda #roomnum_NumberRoom
            sta ManInfo+ObjectInfoType::room_num
            sta PrevManInfo+ObjectInfoType::room_num
            lda #0                ;set man ycoord to 0 so can't be seen
            sta ManInfo+ObjectInfoType::pos+ObjectPosType::ycoord
            sta PrevManInfo+ObjectInfoType::pos+ObjectPosType::ycoord
            ldy NumberCurrState    ;get the level number
            lda GameObjectLocations,y     ;get the low pointer to object locations
            sta dr_ptr
            lda GameObjectLocations+1,y   ;get the high pointer to object locations
            sta dr_ptr+1
            ldy #(Game1ObjectLocationsEnd - Game1ObjectLocations)  ;copy all the objects dynamic information
:           lda (dr_ptr),y                ; (the rooms and positions) into the working area
            sta a:GameObjectsWorkingArea,y
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
            lda #$a2              ;set no object being carried
            sta object_carried
NotSelect:
            lda SWCHB             ;store the current console switches
            sta cached_swchb
            rts

; put objects in random rooms for level 3
RandomizeLevel3:
            ldy #30                    ;for each of the eleven objects
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
            sta $00,x                  ;store the new room value
            dey
            dey                        ;goto the next object
            dey
            bpl :--                    ;until all done
            rts

; Object randomization room bounds data for level 3.
Lvl3ObjRoomBounds:
            .byte ChaliceInfo,      roomrange_chalice_start,      roomrange_chalice_end
            .byte RedDragonInfo,    roomrange_reddragon_start,    roomrange_reddragon_end
            .byte YellowDragonInfo, roomrange_yellowdragon_start, roomrange_yellowdragon_end
            .byte GreenDragonInfo,  roomrange_greendragon_start,  roomrange_greendragon_end
            .byte SwordInfo,        roomrange_sword_start,        roomrange_sword_end
            .byte BridgeInfo,       roomrange_bridge_start,       roomrange_bridge_end
            .byte YellowKeyInfo,    roomrange_yellowkey_start,    roomrange_yellowkey_end
            .byte WhiteKeyInfo,     roomrange_whitekey_start,     roomrange_whitekey_end
            .byte BlackKeyInfo,     roomrange_blackkey_start,     roomrange_blackkey_end
            .byte BlackBatInfo,     roomrange_bat_start,          roomrange_bat_end
            .byte MagnetInfo,       roomrange_magnet_start,       roomrange_magnet_end

GameObjectLocations:
            .word Game1ObjectLocations
            .word Game2ObjectLocations
            .word Game2ObjectLocations

.assert (Game1ObjectLocationsEnd - Game1ObjectLocations) = (Game2ObjectLocationsEnd - Game2ObjectLocations), error, "Game object locations sizes not equal"

; object locations (room and coordinates) for game 1
Game1ObjectLocations:
;                 Room                                   X    Y    Mvt  State
            .byte roomnum_BlackMaze3,                    $51, $12           ;black dot
            .byte roomnum_TopEntryRoom1,                 $50, $20, $00, $00 ;red dragon
            .byte roomnum_BelowYellowCastleLeftThinWall, $50, $20, $00, $00 ;yellow dragon
            .byte roomnum_TopEntryRoom2,                 $50, $20, $00, $00 ;green dragon
            .byte roomnum_BlackCastleEntry,              $80, $20           ;magnet
            .byte roomnum_YellowCastleEntry,             $20, $20           ;sword
            .byte roomnum_OtherPurpleRoom,               $30, $20           ;chalice
            .byte roomnum_BlueMazeTop,                   $29, $37           ;bridge
            .byte roomnum_YellowCastle,                  $20, $40           ;yellow key
            .byte roomnum_TopEntryRoom1,                 $20, $40           ;white key
            .byte roomnum_TopEntryRoom2,                 $20, $40           ;black key
            .byte roomnum_OtherPurpleRoom                                   ;portcullis state
            .byte roomnum_OtherPurpleRoom                                   ;portcullis state
            .byte roomnum_OtherPurpleRoom                                   ;portcullis state
            .byte roomnum_WhiteCastleEntry,              $20, $20, $00, $00 ;bat
            .byte $78                                                       ;bat (carrying, fed-up)
Game1ObjectLocationsEnd:
            .byte 0 ; not needed

Game2ObjectLocations:
;                 Room                                   X    Y    Mvt  State
            .byte roomnum_BlackMaze3,                    $51, $12           ;black dot
            .byte roomnum_BlackMaze2,                    $50, $20, $a0, $00 ;red dragon
            .byte roomnum_RedMazeBottom,                 $50, $20, $a0, $00 ;yellow dragon
            .byte roomnum_BlueMazeTop,                   $50, $20, $a0, $00 ;green dragon
            .byte roomnum_TopEntryRoom1,                 $80, $20           ;magnet
            .byte roomnum_YellowCastle,                  $20, $20           ;sword
            .byte roomnum_BlackMaze2,                    $30, $20           ;chalice
            .byte roomnum_MazeSide,                      $40, $40           ;bridge
            .byte roomnum_MazeMiddle,                    $20, $40           ;yellow key
            .byte roomnum_BlueMazeBottom,                $20, $40           ;white key
            .byte roomnum_RedMazeBottom,                 $20, $40           ;black key
            .byte roomnum_OtherPurpleRoom                                   ;portcullis state
            .byte roomnum_OtherPurpleRoom                                   ;portcullis state
            .byte roomnum_OtherPurpleRoom                                   ;portcullis state
            .byte roomnum_BelowYellowCastle,             $20, $20, $90, $00 ;bat
            .byte $78                                                       ;bat (carrying, fed-up)
Game2ObjectLocationsEnd:
            .byte 0 ; not needed

; check ball collisions and move ball
BallMovement:
            lda CXBLPF
            and #$80              ;get ball-playfield collision
            bne PlayerCollision   ;branch if collision (player-wall)
            lda CXM0FB
            and #$40              ;get ball-missile00 collision
            bne PlayerCollision   ;branch if collision (player-left thin)
            lda CXM1FB
            and #$40              ;get ball-missile01 collision
            beq @BallMove_1       ;branch if no collision
            lda object2           ;if Object2 (to print) is
            cmp #$87              ; not the black dot then collide
            bne PlayerCollision
@BallMove_1:
            lda CXP0FB
            and #$40              ;get ball-player00 collision
            beq @BallMove_2       ;if no collision then branch
            lda object1           ;if Object1 (to print is)
            cmp #0                ; not the invisible surround then
            bne PlayerCollision   ; branch (collision)
@BallMove_2:
            lda CXP1FB
            and #$40              ;get ball-player01 collision
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
            cmp #$5a              ;branch if it is the bridge
            beq ReadStick
            lda ManInfo+ObjectInfoType::room_num
            cmp BridgeInfo        ;is the bridge in this room?
            bne ReadStick         ;if not branch
; check going through the bridge
            lda ManInfo+ObjectInfoType::pos+ObjectPosType::xcoord
            sec
            sbc BridgeInfo+1      ;subtract the bridge's X coordinate
            cmp #$0a              ;if less than $0A then forget it
            bcc ReadStick
            cmp #$17              ;if more than $17 then forget it
            bcs ReadStick
            lda z:BridgeInfo+ObjectInfoType::pos+ObjectPosType::ycoord
            sec
            sbc ManInfo+ObjectInfoType::pos+ObjectPosType::ycoord
            cmp #$fc
            bcs NoCollision       ;if more than $FC then going through bridge
            cmp #$19              ;if more than $19 then forget it
            bcs ReadStick
; no collision (and going through bridge)
NoCollision:
            lda #$ff              ;reset the joystick input
            sta cached_joystick
            lda ManInfo+ObjectInfoType::room_num
            sta PrevManInfo+ObjectInfoType::room_num
            lda ManInfo+ObjectInfoType::pos+ObjectPosType::xcoord
            sta PrevManInfo+ObjectInfoType::pos+ObjectPosType::xcoord
            lda ManInfo+ObjectInfoType::pos+ObjectPosType::ycoord
            sta PrevManInfo+ObjectInfoType::pos+ObjectPosType::ycoord
; read sticks
ReadStick:  cpy #0                ;???is game in first phase?
            bne @ReadStick_2      ;if not, don't bother with joystick read
            lda SWCHA             ;read joysticks
            sta cached_joystick
@ReadStick_2:
            lda PrevManInfo+ObjectInfoType::room_num
            sta ManInfo+ObjectInfoType::room_num
            lda PrevManInfo+ObjectInfoType::pos+ObjectPosType::xcoord
            sta ManInfo+ObjectInfoType::pos+ObjectPosType::xcoord
            lda PrevManInfo+ObjectInfoType::pos+ObjectPosType::ycoord
            sta ManInfo+ObjectInfoType::pos+ObjectPosType::ycoord
            lda cached_joystick        ;get the joystick position
            ora JoystickMergeValues,y  ;merge out movement not allowed in this phase
            sta direction_wanted       ;and store cooked movement
            ldy #3                     ;set the delta for the ball
            ldx #ManInfo               ;point to man's coordinates
            jsr MoveGroundObject       ;move the man
            rts

JoystickMergeValues:
            .byte $00, $c0, $30  ;no change, no horizontal, no vertical

; deal with object pickup and putdown
PickupPutdown:
            rol INPT4             ;get joystick trigger
            ror joystick_record   ;merge into joystick record
            lda joystick_record   ;get joystick record
            and #$c0              ;merge out previous presses
            cmp #$40              ;was it previously pressed?
            bne :+                ;if not branch
            lda #$a2
            cmp object_carried    ;if nothing is being carried
            beq :+                ; then branch
            sta object_carried    ;drop object
            lda #NoiseType::drop_item
            sta sound_type
            lda #4
            sta sound_duration_counter
:           lda #$ff      ;these two instructions inject 15 clocks of critical delay
            sta unread1   ; (need to learn exactly why)
; check for collision
            lda CXP0FB
            and #$40              ;get Ball-Player0 collision
            beq :+                ;if nothing occurred then branch
; with Player0
            lda object1           ;get type of Player0
            sta obj_collided_with
            jmp CollisionDetected ;deal with collision

:           lda CXP1FB
            and #$40              ;get Ball-Player01 collision
            beq :+                ;if nothing has happened, branch
            lda object2           ;get type of Player01
            sta obj_collided_with
            jmp CollisionDetected ;deal with collision

:           jmp NoObject          ;deal with no collision (return)

CollisionDetected:
            ldx obj_collided_with
            jsr GetObjectAddress  ;get its dynamic information
            lda obj_collided_with
            cmp #$51              ;is it carriable?
            bcc NoObject          ;if not, branch
            ldy #0
            lda (dr_ptr),y        ;get the object's room
            cmp ManInfo+ObjectInfoType::room_num
            bne NoObject          ;if not, branch
            lda obj_collided_with
            cmp object_carried    ;is it the object being carried?
            beq PickupObject      ;if so, branch (and actually pick it up)
            lda #NoiseType::get_item
            sta sound_type
            lda #4
            sta sound_duration_counter
PickupObject:
            lda obj_collided_with ;set the object as being carried
            sta object_carried
            ldx dr_ptr            ;get the dynamic address low byte
            ldy #6
            lda cached_joystick   ;????
            jsr MoveObjectDelta   ;????
            ldy #1
            lda (dr_ptr),y        ;get the object's X coordinate
            sec
            sbc ManInfo+ObjectInfoType::pos+ObjectPosType::xcoord
            sta objman_x_delta    ; and store the difference
            ldy #2
            lda (dr_ptr),y        ;get the object's Y coordinate
            sec
            sbc ManInfo+ObjectInfoType::pos+ObjectPosType::ycoord
            sta objman_y_delta    ; and store the difference
NoObject:   rts                   ; no collision

; move the carried object
MoveCarriedObject:
            ldx object_carried
            cpx #$a2              ;if nothing then branch (return)
            beq :+
            jsr GetObjectAddress  ;get its dynamic information
            ldy #0
            lda ManInfo+ObjectInfoType::room_num         ;get the current room
            sta (dr_ptr),y        ; and store the object's current room
            ldy #1
            lda ManInfo+ObjectInfoType::pos+ObjectPosType::xcoord
            clc
            adc objman_x_delta    ;add the X difference
            sta (dr_ptr),y        ; and store as the object's X coordinate
            ldy #2
            lda ManInfo+ObjectInfoType::pos+ObjectPosType::ycoord
            clc
            adc objman_y_delta    ;add the Y difference
            sta (dr_ptr),y        ; and store as the object's Y coordinate
            ldy #0                ;set no delta
            lda #$ff              ;set no movement
            ldx dr_ptr            ;get the object's dynamic address
            jsr MoveGroundObject  ;move the object
:           rts

; move the object
MoveGroundObject:
            jsr MoveObjectDelta     ;move the object by delta
            ldy #2                  ;set to do the three
MoveGroundObject_2:
            sty portcullis_number
            lda a:PortCurrBase,y    ;get the portal state
            cmp #$1c                ;is it in a closed state?
            beq GetPortal           ;if not, next portal
; deal with object moving out of a castle
            ldy portcullis_number
            lda $00,x               ;get object's room number
            cmp EntryRoomOffsets,y  ;is it in a castle entry room?
            bne GetPortal           ;if not, next portal
            lda $02,x               ;get the object's Y coordinate
            cmp #$0d                ;is it above $0D i.e. at the bottom?
            bpl GetPortal           ;if so then branch
            lda CastleRoomOffsets,y ;get the castle room
            sta $00,x               ;and put the object in the castle room
            lda #$50
            sta $01,x               ;set the object's new X coordinate
            lda #$2c
            sta $02,x               ;set the new object's Y coordinate
            lda #1
            sta a:PortCurrBase,y    ;set the portcullis state to 01
            rts

GetPortal:  ldy portcullis_number
            dey                     ; goto next,
            bpl MoveGroundObject_2  ; and continue
; check and deal with Up
            lda $02,x               ;get the object's Y coordinate
            cmp #$6a                ;has it reached above the top?
            bmi DealWithLeft        ;if not, branch
            lda #$0d                ;set new Y coordinate to bottom
            sta $02,x
            ldy #5                  ;get the direction wanted
            jmp GetNewRoom          ;go and get new room

; check and deal with left
DealWithLeft:
            lda $01,x               ;get the object's X coordinate
            cmp #3                  ;is it three or less?
            bcc @DealWithLeft_2     ;if so, branch (off to left)
            cmp #$f0                ;is it $F0 or more?
            bcs @DealWithLeft_2     ;if so, branch (off to right)
            jmp DealWithDown

@DealWithLeft_2:
            cpx #ManInfo            ;are we dealing with the man?
            beq @DealWithLeft_3     ;if so, branch
            lda #$9a                ;set new X coordinate for the others
            jmp @DealWithLeft_4

@DealWithLeft_3:
            lda #$9e                ;set new X coordinate for the ball
@DealWithLeft_4:
            sta $01,x               ;store the next X coordinate
            ldy #RoomType::room_left
            jmp GetNewRoom

; check and deal with Down
DealWithDown:
            lda $02,x               ;get object's Y coordinate
            cmp #$0d                ;if it's greater than $0D then
            bcs DealWithRight       ; branch
            lda #$69                ;set new Y coordinate
            sta $02,x
            ldy #RoomType::room_down
            jmp GetNewRoom

; check and deal with right
DealWithRight:
            lda $01,x               ;get the object's X coordinate
            cpx #ManInfo            ;are we dealing with the man?
            bne @DealWithRight_2    ;branch if not
            cmp #$9f                ;has the object reached the right?
            bcc MovementReturn      ;branch if not
            lda $00,x               ;get the Ball's room
            cmp #3                  ;is it room #3 (right to secret room)
            bne @DealWithRight_3    ;branch if not
            lda DotInfo+ObjectInfoType::room_num  ;check the room of the black dot
            cmp #$15                ;is it in the hidden room area?
            beq @DealWithRight_3    ;if so, branch
; manually change to secret room
            lda #roomnum_SecretRoom
            sta $00,x               ;and make it current
            lda #3                  ;set the X coordinate
            sta $01,x
            jmp MovementReturn      ;and exit

@DealWithRight_2:
            cmp #direction_wanted   ;has the object reached the right of the screen?
            bcc MovementReturn      ;branch if not (no room change)
@DealWithRight_3:
            lda #3                  ;set the next X coordinate
            sta $01,x
            ldy #RoomType::room_right
            jmp GetNewRoom

; get new room
GetNewRoom: lda $00,x               ;get the object's room
            jsr RoomNumToAddress    ;convert it to an address
            lda (dr_ptr),y          ;get the adjacent room
            jsr AdjustRoomLevel     ;deal with the level differences
            sta $00,x               ; and store as new object's room
MovementReturn:
            rts

; move the object in direction by delta
MoveObjectDelta:
            sta direction_wanted
@MoveObject_2:
            dey                     ;count down the delta
            bmi @MoveObject_7
            lda direction_wanted
            and #$80                ;check for right move
            bne @MoveObject_3       ;if no move right then branch
            inc $01,x               ;increment the X coordinate
@MoveObject_3:
            lda direction_wanted
            and #$40                ;check for left move
            bne @MoveObject_4       ;if no move left then branch
            dec $01,x               ;decrement the X coordinate
@MoveObject_4:
            lda direction_wanted
            and #$10                ;check for move up
            bne @MoveObject_5       ;if no move up then branch
            inc $02,x
@MoveObject_5:
            lda direction_wanted
            and #$20                ;check for move down
            bne @MoveObject_6       ;if no move down then branch
            dec $02,x               ;decrement the Y coordinate
@MoveObject_6:
            jmp @MoveObject_2       ;keep going until delta finished

@MoveObject_7:
            rts

; adjust room for different levels
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
PBCollision:
            cmp object1             ;is it the first object?
            beq @PBCollision_2      ;yes, then branch
            cmp object2             ;is it the second object?
            beq @PBCollision_3      ;yes, then branch
            lda #0                  ;otherwise nothing
            rts

@PBCollision_2:
            lda CXP0FB              ;get player00-ball collision
            and #$40
            rts

@PBCollision_3:
            lda CXP1FB              ;get player01-ball collision
            and #$40
            rts

; find which object has hit object wanted
; input x=object number, returns hit object number in a
FindObjHit: lda CXPPMM              ;get player00-player01
            and #$80                ; collision
            beq :+                  ;if nothing, branch
            cpx object1             ;is object 1 the one being hit?
            beq :++                 ;if so, branch
            cpx object2             ;is object 2 the one being hit?
            beq :+++                ;if so, branch
:           lda #$a2                ;therefore select the other
            rts
:           lda object2             ;therefore select the other
            rts
:           lda object1             ;therefore select the other
            rts

; move object
MoveGameObject:
            jsr GetLinkedObject     ;get linked object and movement
            ldx MoveGameObjectArg_ObjNumber
            lda direction_wanted
            bne @MoveGameObject_2   ;if movement then branch
            lda $03,x               ;use old movement
@MoveGameObject_2:
            sta $03,x               ;store the new movement
            ldy objdelta            ;get the object's delta
            jsr MoveGroundObject    ;move the object
            rts

; find linked object and get movement
GetLinkedObject:
            lda #0                  ;set index to zero
            sta linked_obj_index
@GetLinkedObj_2:
            ldy linked_obj_index
            lda (objstore_ptr),y    ;get first object
            tax
            iny
            lda (objstore_ptr),y    ;get second object
            tay
            lda $00,x               ;get Object1's room
            cmp $0000,y             ;compare the Object2's room
            bne @GetLinkedObj_3     ;if not the same room then branch
            cpy MoveGameObjectArg_Difficulty  ;have we matched the second object
            beq @GetLinkedObj_3     ; for difficulty (if so, carry on)
            cpx MoveGameObjectArg_Difficulty  ;have we matched the first object
            beq @GetLinkedObj_3     ; for difficulty (if so, carry on)
            jsr @GetLinkedObj_4     ;get object's movement
            rts

@GetLinkedObj_3:
            inc linked_obj_index
            inc linked_obj_index
            ldy linked_obj_index
            lda (objstore_ptr),y    ;check for end of sequence
            bne @GetLinkedObj_2     ;if not branch
            lda #0                  ;set no move if no
            sta direction_wanted
            rts

; work out object's movement
@GetLinkedObj_4:
            lda #$ff                ;set object movement to none
            sta direction_wanted
            lda $0000,y             ;get Object2's room
            cmp $00,x               ;compare it with object's room
            bne @GetLinkedObject_8  ;if not the same, forget it
            lda $0001,y             ;get Object2's X coordinate
            cmp $01,x               ;get Object1's X coordinate
            bcc @GetLinkedObject_5  ;if Object2 to left of Object1 then branch
            beq @GetLinkedObject_6  ;if Object2 on Object1 then branch
            lda direction_wanted
            and #$7f                ;signal a move right
            sta direction_wanted
            jmp @GetLinkedObject_6  ;now try vertical

@GetLinkedObject_5:
            lda direction_wanted
            and #$bf                ;signal a move left
            sta direction_wanted
@GetLinkedObject_6:
            lda $0002,y             ;get Object2's Y coordinate
            cmp $02,x               ;get Object1's X coordinate
            bcc @GetLinkedObject_7  ;if Object2 below Object1 then branch
            beq @GetLinkedObject_8  ;if Object2 on Object1 then branch
            lda direction_wanted
            and #$ef                ;signal a move up
            sta direction_wanted
            jmp @GetLinkedObject_8  ;jump to finish

@GetLinkedObject_7:
            lda direction_wanted
            and #sound_duration_counter  ;signal a move down
            sta direction_wanted
@GetLinkedObject_8:
            lda direction_wanted
            rts

; move the red dragon
MoveRedDragon:
            lda #<RedDragMatrix
            sta objstore_ptr
            lda #>RedDragMatrix
            sta objstore_ptr+1
            lda #3
            sta objdelta          ;set the dragon's delta
            ldx #$36              ;select dragon #1: red
            jsr MoveDragon
            rts

; red dragon's object matrix
RedDragMatrix:
            .byte SwordInfo,     RedDragonInfo
            .byte RedDragonInfo, ManInfo
            .byte RedDragonInfo, ChaliceInfo
            .byte RedDragonInfo, WhiteKeyInfo
            .byte 0

; move the yellow dragon
MoveYellowDragon:
            lda #<YelDragMatrix
            sta objstore_ptr
            lda #>YelDragMatrix
            sta objstore_ptr+1
            lda #2
            sta objdelta          ;set the dragon's delta
            ldx #$3f              ;select dragon #2: yellow
            jsr MoveDragon
            rts

; yellow dragon's object matrix
YelDragMatrix:
            .byte SwordInfo,        YellowDragonInfo
            .byte YellowKeyInfo,    YellowDragonInfo
            .byte YellowDragonInfo, ManInfo
            .byte YellowDragonInfo, ChaliceInfo
            .byte 0

; move the green dragon
MoveGreenDragon:
            lda #<GreenDragMatrix
            sta objstore_ptr
            lda #>GreenDragMatrix
            sta objstore_ptr+1
            lda #2
            sta objdelta          ;set the green dragon's delta
            ldx #$48              ;select dragon #3: green
            jsr MoveDragon
            rts

GreenDragMatrix:
            .byte SwordInfo,       GreenDragonInfo
            .byte GreenDragonInfo, ManInfo
            .byte GreenDragonInfo, ChaliceInfo
            .byte GreenDragonInfo, BridgeInfo
            .byte GreenDragonInfo, MagnetInfo
            .byte GreenDragonInfo, BlackKeyInfo
            .byte 0

; move a dragon
MoveDragon: stx curr_obj_number   ;save object we're dealing with
            lda a:Objects+ObjectType::info_ptr,x
            tax
            lda z:ObjectType::states_ptr,x   ;get the object's state
            cmp #0                ;is it in state 00 (normal #1)
            bne @MoveDragon_6     ;branch if not
; dragon normal (state 1)
            lda SWCHB             ;read console switches
            and #ConsoleSwitchType::rightdifficulty ;check for P1 difficulty
            beq @MoveDragon_2     ;if amateur branch
            lda #0                ;set hard - ignore nothing
            jmp @MoveDragon_3

@MoveDragon_2:
            lda #SwordInfo        ;set easy - ignore sword
@MoveDragon_3:
            sta MoveGameObjectArg_Difficulty
            stx MoveGameObjectArg_ObjNumber
            jsr MoveGameObject
            lda curr_obj_number   ;get object
            jsr PBCollision       ; and get the player-ball collision
            beq @MoveDragon_4     ;if none then branch
            lda SWCHB             ;get console switches
            rol a                 ;move P0 difficulty to
            rol a                 ; bit 01 position
            rol a
            and #1                ;mask it out
            ora NumberCurrState   ;merge in the level number
            tay                   ;create lookup
            lda DragonDiff,y      ;get new state
            sta $04,x             ;store as dragon's state (open mouthed)
            lda PrevManInfo+ObjectInfoType::pos+ObjectPosType::xcoord
            sta $01,x             ;get temp ball X coord and store as dragon's
            lda PrevManInfo+ObjectInfoType::pos+ObjectPosType::ycoord
            sta $02,x             ;get temp ball Y coord and store as dragon's
            lda #NoiseType::dragon_roar
            sta sound_type
            lda #16
            sta sound_duration_counter
@MoveDragon_4:
            stx portcullis_number
            ldx curr_obj_number   ;get the object number
            jsr FindObjHit        ;set if another object has hit the dragon
            ldx portcullis_number
            cmp #$51              ;has the sword hit the dragon?
            bne @MoveDragon_5     ;if not, branch
            lda #1                ;set the state to 01 (dead)
            sta $04,x
            lda #NoiseType::dragon_died
            sta sound_type
            lda #16
            sta sound_duration_counter
@MoveDragon_5:
            jmp @MoveDragon_9     ;jump to finish

@MoveDragon_6:
            cmp #1                ;is it in state 01 (dead)
            beq @MoveDragon_9     ;branch if so (return)
            cmp #2                ;is it in state 02 (normal #2)
            bne @MoveDragon_7     ;branch if not
; normal dragon state 2 (eaten ball)
            lda $00,x             ;get the dragon's current room
            sta ManInfo+ObjectInfoType::room_num
            sta PrevManInfo+ObjectInfoType::room_num
            lda $01,x             ;get the dragon's X coordinate
            clc
            adc #3                ;adjust
            sta ManInfo+ObjectInfoType::pos+ObjectPosType::xcoord
            sta PrevManInfo+ObjectInfoType::pos+ObjectPosType::xcoord
            lda $02,x             ;get the dragon's Y coordinate
            sec
            sbc #$0a              ;adjust
            sta ManInfo+ObjectInfoType::pos+ObjectPosType::ycoord
            sta PrevManInfo+ObjectInfoType::pos+ObjectPosType::ycoord
            jmp @MoveDragon_9

; dragon roaring
@MoveDragon_7:
            inc $04,x             ;increment the dragon's state
            lda $04,x             ;get its state
            cmp #$fc              ;is it near the end?
            bcc @MoveDragon_9     ;if not, branch
            lda curr_obj_number   ;get the dragon's number
            jsr PBCollision       ;check if the ball is colliding
            beq @MoveDragon_9     ;if not, branch
            lda #2                ;set the state to state 02: eaten
            sta $04,x
            lda #NoiseType::man_eaten
            sta sound_type
            lda #$10
            sta sound_duration_counter
            lda #$9b              ;get the maximum X coordinate
            cmp $01,x             ;compare with the dragon's X coordinate
            beq @MoveDragon_8
            bcs @MoveDragon_8
            sta $01,x             ;if too large then use it
@MoveDragon_8:
            lda #$17              ;set minimum Y coordinate
            cmp $02,x             ;compare with the dragon's Y coordinate
            bcc @MoveDragon_9
            sta $02,x             ;if too small, set as dragon's Y coordinate
@MoveDragon_9:
            rts

; dragon difficulty
DragonDiff: .byte $d0, $e8       ;level 1: Am, Pro
            .byte $f0, $f6       ;level 2: Am, Pro
            .byte $f0, $f6       ;level 3: Am, Pro

; move bat
MoveBat:    inc BlackBatCurrBase  ;put bat in the next state
            lda BlackBatCurrBase  ;get the bat state
            cmp #8                ;has it reached the maximum?
            bne @MoveBat_2
            lda #0                ;if so, reset the bat state
            sta BlackBatCurrBase
@MoveBat_2: lda BlackBatFedUp     ;get the bat fed-up value
            beq @MoveBat_3        ;if bat fed-up then branch
            inc BlackBatFedUp     ;increment its value for next time
            lda z:BlackBatInfo+LongObjectInfoType::move
            ldx #BlackBatInfo     ;position to bat
            ldy #3                ;get the bat's deltas
            jsr MoveGroundObject  ;move the bat
            jmp @MoveBat_4        ;update the bat's object

; bat fed-up
@MoveBat_3: lda #BlackBatInfo     ;store the bat's dynamic data address
            sta MoveGameObjectArg_ObjNumber
            lda #3                ;set the bat's delta
            sta objdelta
            lda #<BatMatrix       ;set the low address of object store
            sta objstore_ptr
            lda #>BatMatrix       ;set the high address of object store
            sta objstore_ptr+1
            lda BlackBatCarriedObject        ;get object being carried by Bat,
            sta MoveGameObjectArg_Difficulty  ; and copy
            jsr MoveGameObject    ;move the Bat
            ldy linked_obj_index
            lda (objstore_ptr),y  ;look up the object found in the table
            beq @MoveBat_4        ;if nothing found then forget it
            iny
            lda (objstore_ptr),y  ;get the object wanted
            tax
            lda $00,x             ;get the object's room
            cmp BlackBatInfo      ;is it the same as the Bat's?
            bne @MoveBat_4        ;if not forget it
; see if bat can pick up an object
            lda $01,x             ;get the object's X coordinate
            sec
            sbc z:BlackBatInfo+ObjectInfoType::pos+ObjectPosType::xcoord  ;find the difference with the Bat's X coordinate
            clc
            adc #4                ;adjust so Bat in middle of object
            and #$f8              ;is Bat within seven pixels?
            bne @MoveBat_4        ;if not, no pickup possible
            lda $02,x             ;get the object's Y coordinate
            sec
            sbc z:BlackBatInfo+ObjectInfoType::pos+ObjectPosType::ycoord  ;find the difference with the Bat's
            clc                   ; Y coordinate
            adc #4                ;adjust
            and #$f8              ;is the Bat within seven pixels?
            bne @MoveBat_4        ;if not, no pickup possible
; get object
            stx BlackBatCarriedObject  ;store object as being carried
            lda #$10              ;reset the bat fed-up time
            sta BlackBatFedUp
; move object being carried by bat
@MoveBat_4: ldx BlackBatCarriedObject  ;get object being carried by Bat
            lda BlackBatInfo      ;get the Bat's room
            sta $00,x             ;store this as the object's room
            lda z:BlackBatInfo+ObjectInfoType::pos+ObjectPosType::xcoord
            clc
            adc #8                ;adjust to the right
            sta $01,x             ;make it the object's X coordinate
            lda z:BlackBatInfo+ObjectInfoType::pos+ObjectPosType::ycoord
            sta $02,x             ;store is as the object's Y coordinate
            lda BlackBatCarriedObject  ;get the object being carried by the bat
            ldy object_carried
            cmp Objects+ObjectType::info_ptr,y  ;are they the same?
            bne @MoveBat_5        ;if not branch
            lda #$a2              ;set nothing being carried
            sta object_carried
@MoveBat_5: rts

; bat object matrix
BatMatrix:  .byte  BlackBatInfo, ChaliceInfo
            .byte  BlackBatInfo, SwordInfo
            .byte  BlackBatInfo, BridgeInfo
            .byte  BlackBatInfo, YellowKeyInfo
            .byte  BlackBatInfo, WhiteKeyInfo
            .byte  BlackBatInfo, BlackKeyInfo
            .byte  BlackBatInfo, RedDragonInfo
            .byte  BlackBatInfo, YellowDragonInfo
            .byte  BlackBatInfo, GreenDragonInfo
            .byte  BlackBatInfo, MagnetInfo
            .byte  0

; deal with portcullis and collisions
Portals:    ldy #2                ;for each portcullis
@Portals_2: ldx PortOffsets,y     ;get the portcullis' offset number
            jsr FindObjHit        ;see if an object collided with it
            sta obj_collided_with
            cmp KeyOffsets,y      ;is it the associated key?
            bne @Portals_3        ;if not then branch
            tya                   ;get the portcullis number
            tax
            inc PortCurrBase,x    ;change its state to open it
@Portals_3: tya                   ;get the portcullis number
            tax
            lda PortCurrBase,x    ;get the state
            cmp #$1c              ;is it closed?
            beq @Portals_7        ;yes - then branch
            lda PortOffsets,y     ;get portcullis number
            jsr PBCollision       ;get the player-ball collision
            beq @Portals_4        ;if not then branch
            lda #1                ;set the portcullis to closed
            sta PortCurrBase,x
            ldx #ManInfo
            jmp @Portals_6        ;put the man in the castle

@Portals_4: lda obj_collided_with ;get the object that hit the portcullis
            cmp #$a2              ;is it nothing?
            beq @Portals_5        ;if so, branch
            ldx obj_collided_with
            sty portcullis_number
            jsr GetObjectAddress  ;and find its dynamic address
            ldy portcullis_number
            ldx dr_ptr            ;get object's address
            jmp @Portals_6        ;put object in the castle

@Portals_5: jmp @Portals_7
@Portals_6: lda EntryRoomOffsets,y ;look up castle entry room for this port
            sta $00,x             ;make it the object's room
            lda #$10              ;give the object a new Y coordinate
            sta $02,x
@Portals_7: tya                   ;get the portcullis number
            tax
            lda PortCurrBase,x    ;get its state
            cmp #1                ;is it open?
            beq @Portals_8        ; branch if yes
            cmp #$1c              ;is it closed?
            beq @Portals_8        ; branch if yes
            inc PortCurrBase,x    ;increment its state
            lda PortCurrBase,x    ;get the state
            cmp #$38              ;has it reached the maximum state?
            bne @Portals_8        ; branch if not
            lda #1                ;set to closed state
            sta PortCurrBase,x
@Portals_8: dey                   ;go to the next portcullis
            bmi @Portals_Done     ;branch if finished
            jmp @Portals_2        ;do next portcullis

@Portals_Done:
            rts

PortOffsets:
            .byte  $09, $12, $1b       ;portcullis #1, #2, #3

KeyOffsets: .byte  $63, $6c, $75       ;keys (yellow, white, black)
EntryRoomOffsets:
            .byte  roomnum_YellowCastleEntry, roomnum_WhiteCastleEntry, roomnum_BlackCastleEntry
CastleRoomOffsets:
            .byte  roomnum_YellowCastle, roomnum_WhiteCastle, roomnum_BlackCastle

; deal with magnet
Mag:        lda z:MagnetInfo+ObjectInfoType::pos+ObjectPosType::ycoord
            sec
            sbc #8                ;adjust to its "poles"
            sta z:MagnetInfo+ObjectInfoType::pos+ObjectPosType::ycoord
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
:           lda z:MagnetInfo+ObjectInfoType::pos+ObjectPosType::ycoord  ;reset the magnet's Y coordinate
            clc
            adc #8
            sta z:MagnetInfo+ObjectInfoType::pos+ObjectPosType::ycoord
            rts

; magnet object matrix
MagnetMatrix:
            .byte YellowKeyInfo, MagnetInfo   ;yellow key, magnet
            .byte WhiteKeyInfo,  MagnetInfo   ;white key, magnet
            .byte BlackKeyInfo,  MagnetInfo   ;black key, magnet
            .byte SwordInfo,     MagnetInfo   ;sword, magnet
            .byte BridgeInfo,    MagnetInfo   ;bridge, magnet
            .byte ChaliceInfo,   MagnetInfo   ;chalice, magnet
            .byte 0

; deal with invisible surround moving
Surround:   lda ManInfo+ObjectInfoType::room_num         ;set the current room
            jsr RoomNumToAddress  ;convert it to an address
            ldy #RoomType::color
            lda (dr_ptr),y
            cmp #8                ;is it invisible?
            beq @Surround_2       ;if so branch
            lda #0                ;if not, signal the invisible surround not wanted
            sta z:SurroundInfo+ObjectInfoType::pos+ObjectPosType::ycoord
            jmp @Surround_Done

@Surround_2:
            lda ManInfo+ObjectInfoType::room_num         ;get the current room
            sta SurroundInfo      ;and store as the invisible surround
            lda ManInfo+ObjectInfoType::pos+ObjectPosType::xcoord           ;get the man's X coordinate
            sec
            sbc #$0e              ;adjust for surround,
            sta z:SurroundInfo+ObjectInfoType::pos+ObjectPosType::xcoord
            lda ManInfo+ObjectInfoType::pos+ObjectPosType::ycoord           ;get the man's Y coordinate
            clc
            adc #$0e              ;adjust for surround
            sta z:SurroundInfo+ObjectInfoType::pos+ObjectPosType::ycoord
            lda z:SurroundInfo+ObjectInfoType::pos+ObjectPosType::xcoord
            cmp #$f0              ;is it close to the right edge?
            bcc @Surround_3       ;branch if not
            lda #1                ;flick surround to the other side of the screen
            sta z:SurroundInfo+ObjectInfoType::pos+ObjectPosType::xcoord
            jmp @Surround_Done

@Surround_3:
            cmp #$82              ;???
            bcc @Surround_Done    ;???
            lda #$81              ;???
            sta z:SurroundInfo+ObjectInfoType::pos+ObjectPosType::xcoord ;???
@Surround_Done:
            rts

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
            sta AUDC0             ;audio-control 00
            lsr a
            sta AUDV0             ;audio-volume 00
            lsr a
            lsr a
            sta AUDF0             ;audio-frequency 00
            rts

RoarNoise:  lda sound_duration_counter
            lsr a
            lda #3                ;if it was even then
            bcs :+                ; branch
            lda #8                ;get a different audio control value
:           sta AUDC0             ;set audio control 00
            lda sound_duration_counter  ;set the volume to the noise count
            sta AUDV0
            lsr a                 ;divide by four
            lsr a
            clc
            adc #$1c              ;set the frequency
            sta AUDF0
            rts

EatenNoise:
            lda #6
            sta AUDC0             ;audio-control 00
            lda sound_duration_counter
            eor #$0f
            sta AUDF0             ;audio-frequency 00
            lda sound_duration_counter
            lsr a
            clc
            adc #8
            sta AUDV0             ;audio-volume 00
            rts

DragDieNoise:
            lda #4                ;set the audio control
            sta AUDC0
            lda sound_duration_counter  ;put the note count in
            sta AUDV0             ; the volume
            eor #$1f
            sta AUDF0             ;flip the count as store
            rts                   ; as the frequency

DropObjectNoise:
            lda sound_duration_counter
            eor #3                ;reverse it as noise does up
:           sta AUDF0             ;store in frequency for channel 00
            lda #5
            sta AUDV0             ;set volume on channel 00
            lda #6
            sta AUDC0             ;set a noise on channel 00
            rts

GetObjectNoise:
            lda sound_duration_counter
            jmp :-                ; and make same noise as drop

LeftOfName:         leftofname_gfxpf_data original
BelowYellowCastle:  belowyellowcastle_gfxpf_data    ;line shared with above room
SideCorridor:       sidecorridor_gfxpf_data
NumberRoom:         numberroom_gfxpf_data

; object #1 states (portcullis)
PortStates:         .byte $04                ;state 04 - open
                    .word :+++++++
                    .byte $08
                    .word :++++++
                    .byte $0c
                    .word :+++++
                    .byte $10
                    .word :++++
                    .byte $14
                    .word :+++
                    .byte $18
                    .word :++
                    .byte $1c                ;state 1C - closed
                    .word :+
                    .byte $20
                    .word :++
                    .byte $24
                    .word :+++
                    .byte $28
                    .word :++++
                    .byte $2c
                    .word :+++++
                    .byte $30
                    .word :++++++
                    .byte $ff                ;state FF - open
                    .word :+++++++
:                   port_gfxgr_data
:                   port_gfxgr_data
:                   port_gfxgr_data
:                   port_gfxgr_data
:                   port_gfxgr_data
:                   port_gfxgr_data
:                   port_gfxgr_data
                    port_gfxgr_data
                    .byte 0

TwoExitRoom:        twoexitroom_gfxpf_data
BlueMazeTop:        bluemazetop_gfxpf_data
BlueMaze1:          bluemaze1_gfxpf_data
BlueMazeBottom:     bluemazebottom_gfxpf_data
BlueMazeCenter:     bluemazecenter_gfxpf_data
BlueMazeEntry:      bluemazeentry_gfxpf_data
MazeMiddle:         mazemiddle_gfxpf_data original
MazeSide:           mazeside_gfxpf_data             ;line shared with above room
MazeEntry:          mazeentry_gfxpf_data
CastleDef:          castle_gfxpf_data

PortInfo1:          .byte roomnum_YellowCastle, $4d, $31
PortInfo2:          .byte roomnum_WhiteCastle,  $4d, $31
PortInfo3:          .byte roomnum_BlackCastle,  $4d, $31

SurroundCurrState:  .byte 0
SurroundStates:     .byte $ff
                    .word :+
:                   surround_gfxgr_data

RedMaze1:           redmaze1_gfxpf_data original
RedMazeBottom:      redmazebottom_gfxpf_data        ;line shared with room above
RedMazeTop:         redmazetop_gfxpf_data original
WhiteCastleEntry:   whitecastleentry_gfxpf_data     ;line shared with room above
TopEntryRoom:       topentryroom_gfxpf_data
BlackMaze1:         blackmaze1_gfxpf_data original
BlackMaze3:         blackmaze3_gfxpf_data           ;line shared with room above
BlackMaze2:         blackmaze2_gfxpf_data original
BlackMazeEntry:     blackmazeentry_gfxpf_data       ;line shared with room above

BridgeCurr:         .byte 0
BridgeStates:       .byte $ff
                    .word :+
:                   bridge_gfxgr_data

GfxNum1:            number1_gfxgr_data

KeyCurr:            .byte 0
KeyStates:          .byte $ff
                    .word :+
:                   key_gfxgr_data

GfxNum2:            number2_gfxgr_data
GfxNum3:            number3_gfxgr_data

BatStates:          .byte $03
                    .word :+
                    .byte $ff
                    .word :++
:                   bat1_gfxgr_data
:                   bat2_gfxgr_data

DragonStates:       .byte $00
                    .word :+
                    .byte $01
                    .word :+++
                    .byte $02
                    .word :+
                    .byte $ff
                    .word :++
:                   dragonnormal_gfxgr_data 0
:                   dragonroar_gfxgr_data   0
:                   dragondead_gfxgr_data   0

SwordCurr:          .byte 0
SwordStates:        .byte $ff
                    .word :+
:                   sword_gfxgr_data 0

DotCurr:            .byte 0
DotStates:          .byte $ff
                    .word :+
:                   dot_gfxgr_data

:                   easteregg_gfxgr_data norm
EasterEggInfo:      .byte roomnum_SecretRoom, $50, $69
EasterEggCurrState: .byte 0
EasterEggStates:    .byte $ff
                    .word :-

ChaliceCurr:        .byte 0
ChaliceStates:      .byte $ff
                    .word :+
:                   chalice_gfxgr_data

NullCurr:           .byte 0
NullStates:         .byte $ff
                    .word :+
:                   null_gfxgr_data

NumberInfo:         .byte roomnum_NumberRoom, 80, 64
NumberStates:       .byte $01
                    .word GfxNum1
                    .byte $03
                    .word GfxNum2
                    .byte $ff
                    .word GfxNum3

MagnetCurr:         .byte 0
MagnetStates:       .byte $ff
                    .word :+
:                   magnet_gfxgr_data


Rooms:
roomnum_NumberRoom = (* - Rooms) / .sizeof(RoomType)
    .word NumberRoom
    .byte ColorType::purple, BWColorType::lightgray
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
    .byte ColorType::darkgreen, BWColorType::lightgray
    .byte RoomControlType::leftthinwall_pfref
    .byte roomnum_BlueMazeEntry, roomnum_BelowYellowCastle, roomnum_downfrom_BelowYellowCastleLeftThinWall, roomnum_BelowYellowCastleRightThinWall

roomnum_BelowYellowCastle = (* - Rooms) / .sizeof(RoomType)
    .word BelowYellowCastle
    .byte ColorType::green, BWColorType::lightgray
    .byte RoomControlType::pfref
    .byte roomnum_YellowCastle, roomnum_BelowYellowCastleRightThinWall, roomnum_downfrom_BelowYellowCastleGreen, roomnum_BelowYellowCastleLeftThinWall

roomnum_BelowYellowCastleRightThinWall = (* - Rooms) / .sizeof(RoomType)
    .word LeftOfName
    .byte ColorType::darkyellow, BWColorType::lightgray
    .byte RoomControlType::rightthinwall_pfref
    .byte roomnum_BlueMazeBottom, roomnum_BelowYellowCastleLeftThinWall, roomnum_downfrom_BelowYellowCastleRightThinWall, roomnum_BelowYellowCastle

roomnum_BlueMazeTop = (* - Rooms) / .sizeof(RoomType)
    .word BlueMazeTop
    .byte ColorType::blue, BWColorType::lightgray
    .byte RoomControlType::pfref
    .byte roomnum_BlackCastle, roomnum_BlueMaze1, roomnum_BlueMazeCenter, roomnum_BlueMazeBottom

roomnum_BlueMaze1 = (* - Rooms) / .sizeof(RoomType)
    .word BlueMaze1
    .byte ColorType::blue, BWColorType::lightgray
    .byte RoomControlType::pfref
    .byte roomnum_TopEntryRoom2, roomnum_BlueMazeBottom, roomnum_BlueMazeEntry, roomnum_BlueMazeTop

roomnum_BlueMazeBottom = (* - Rooms) / .sizeof(RoomType)
    .word BlueMazeBottom
    .byte ColorType::blue, BWColorType::lightgray
    .byte RoomControlType::pfref
    .byte roomnum_BlueMazeCenter, roomnum_BlueMazeTop, roomnum_BelowYellowCastleRightThinWall, roomnum_BlueMaze1

roomnum_BlueMazeCenter = (* - Rooms) / .sizeof(RoomType)
    .word BlueMazeCenter
    .byte ColorType::blue, BWColorType::lightgray
    .byte RoomControlType::pfref
    .byte roomnum_BlueMazeTop, roomnum_BlueMazeEntry, roomnum_BlueMazeBottom, roomnum_BlueMazeEntry

roomnum_BlueMazeEntry = (* - Rooms) / .sizeof(RoomType)
    .word BlueMazeEntry
    .byte ColorType::blue, BWColorType::lightgray
    .byte RoomControlType::pfref
    .byte roomnum_BlueMaze1, roomnum_BlueMazeCenter, roomnum_BelowYellowCastleLeftThinWall, roomnum_BlueMazeCenter

roomnum_MazeMiddle = (* - Rooms) / .sizeof(RoomType)
    .word MazeMiddle
    .byte ColorType::invisible, BWColorType::invisible
    .byte RoomControlType::pfref_pfp
    .byte roomnum_MazeEntry, roomnum_MazeEntry, roomnum_MazeSide, roomnum_MazeEntry

roomnum_MazeEntry = (* - Rooms) / .sizeof(RoomType)
    .word MazeEntry
    .byte ColorType::invisible, BWColorType::invisible
    .byte RoomControlType::pfref_pfp
    .byte roomnum_BelowYellowCastleRightThinWall, roomnum_MazeMiddle, roomnum_MazeMiddle, roomnum_MazeMiddle

roomnum_MazeSide = (* - Rooms) / .sizeof(RoomType)
    .word MazeSide
    .byte ColorType::invisible, BWColorType::invisible
    .byte RoomControlType::pfref_pfp
    .byte roomnum_MazeMiddle, roomnum_SideCorridor1, roomnum_OtherPurpleRoom, roomnum_SideCorridor2

roomnum_SideCorridor1 = (* - Rooms) / .sizeof(RoomType)
    .word SideCorridor
    .byte ColorType::lightblue, BWColorType::lightgray
    .byte RoomControlType::rightthinwall_pfref
    .byte roomnum_OtherPurpleRoom, roomnum_SideCorridor2, roomnum_TopEntryRoom2, roomnum_MazeSide

roomnum_SideCorridor2 = (* - Rooms) / .sizeof(RoomType)
    .word SideCorridor
    .byte ColorType::lightgreen, BWColorType::lightgray
    .byte RoomControlType::leftthinwall_pfref
    .byte roomnum_WhiteCastle, roomnum_MazeSide, roomnum_TopEntryRoom1, roomnum_SideCorridor1

roomnum_TopEntryRoom1 = (* - Rooms) / .sizeof(RoomType)
    .word TopEntryRoom
    .byte ColorType::turquoise, BWColorType::lightgray
    .byte RoomControlType::pfref
    .byte roomnum_SideCorridor2, roomnum_BlackCastle, roomnum_WhiteCastle, roomnum_BlackCastle

roomnum_WhiteCastle = (* - Rooms) / .sizeof(RoomType)
    .word CastleDef
    .byte ColorType::darkwhite, BWColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_TopEntryRoom1, roomnum_WhiteCastle, roomnum_SideCorridor2, roomnum_WhiteCastle

roomnum_BlackCastle = (* - Rooms) / .sizeof(RoomType)
    .word CastleDef
    .byte ColorType::black, BWColorType::darkergray
    .byte RoomControlType::pfref
    .byte roomnum_BelowYellowCastleLeftThinWall, roomnum_OtherPurpleRoom, roomnum_BlueMazeTop, roomnum_OtherPurpleRoom

roomnum_YellowCastle = (* - Rooms) / .sizeof(RoomType)
    .word CastleDef
    .byte ColorType::yellow, BWColorType::lightgray
    .byte RoomControlType::pfref
    .byte roomnum_BlueMazeBottom, roomnum_BelowYellowCastleRightThinWall, roomnum_BelowYellowCastle, roomnum_BelowYellowCastleLeftThinWall

roomnum_YellowCastleEntry = (* - Rooms) / .sizeof(RoomType)
roomrange_blackkey_end = roomnum_YellowCastleEntry
    .word NumberRoom
    .byte ColorType::yellow, BWColorType::lightgray
    .byte RoomControlType::pfref
    .byte roomnum_YellowCastleEntry, roomnum_YellowCastleEntry, roomnum_YellowCastleEntry, roomnum_YellowCastleEntry

roomnum_BlackMaze1 = (* - Rooms) / .sizeof(RoomType)
roomrange_chalice_start = roomnum_BlackMaze1
    .word BlackMaze1
    .byte ColorType::invisible, BWColorType::invisible
    .byte RoomControlType::pfref_pfp
    .byte roomnum_BlackMaze3, roomnum_BlackMaze2, roomnum_BlackMaze3, roomnum_BlackMazeEntry

roomnum_BlackMaze2 = (* - Rooms) / .sizeof(RoomType)
    .word BlackMaze2
    .byte ColorType::invisible, BWColorType::invisible
    .byte RoomControlType::pfp
    .byte roomnum_BlackMazeEntry, roomnum_BlackMaze3, roomnum_BlackMazeEntry, roomnum_BlackMaze1

roomnum_BlackMaze3 = (* - Rooms) / .sizeof(RoomType)
    .word BlackMaze3
    .byte ColorType::invisible, BWColorType::invisible
    .byte RoomControlType::pfp
    .byte roomnum_BlackMaze1, roomnum_BlackMazeEntry, roomnum_BlackMaze1, roomnum_BlackMaze2

roomnum_BlackMazeEntry = (* - Rooms) / .sizeof(RoomType)
roomrange_whitekey_end = roomnum_BlackMazeEntry
    .word BlackMazeEntry
    .byte ColorType::invisible, BWColorType::invisible
    .byte RoomControlType::pfref_pfp
    .byte roomnum_BlackMaze2, roomnum_BlackMaze1, roomnum_BlackCastleEntry, roomnum_BlackMaze3

roomnum_RedMaze1 = (* - Rooms) / .sizeof(RoomType)
    .word RedMaze1
    .byte ColorType::red, BWColorType::lightgray
    .byte RoomControlType::pfref
    .byte roomnum_RedMazeBottom, roomnum_RedMazeTop, roomnum_RedMazeBottom, roomnum_RedMazeTop

roomnum_RedMazeTop = (* - Rooms) / .sizeof(RoomType)
    .word RedMazeTop
    .byte ColorType::red, BWColorType::lightgray
    .byte RoomControlType::pfref
    .byte roomnum_WhiteCastleEntry, roomnum_RedMaze1, roomnum_WhiteCastleEntry, roomnum_RedMaze1

roomnum_RedMazeBottom = (* - Rooms) / .sizeof(RoomType)
    .word RedMazeBottom
    .byte ColorType::red, BWColorType::lightgray
    .byte RoomControlType::pfref
    .byte roomnum_RedMaze1, roomnum_WhiteCastleEntry, roomnum_RedMaze1, roomnum_WhiteCastleEntry

roomnum_WhiteCastleEntry = (* - Rooms) / .sizeof(RoomType)
roomrange_chalice_end = roomnum_WhiteCastleEntry
    .word WhiteCastleEntry
    .byte ColorType::red, BWColorType::lightgray
    .byte RoomControlType::pfref
    .byte roomnum_RedMazeTop, roomnum_RedMazeBottom, roomnum_RedMazeTop, roomnum_RedMazeBottom

roomnum_BlackCastleEntry = (* - Rooms) / .sizeof(RoomType)
    .word TwoExitRoom
    .byte ColorType::red, BWColorType::lightgray
    .byte RoomControlType::pfref
    .byte roomnum_uprightdownleftfrom_BlackCastleEntry, roomnum_uprightdownleftfrom_BlackCastleEntry, roomnum_uprightdownleftfrom_BlackCastleEntry, roomnum_uprightdownleftfrom_BlackCastleEntry

roomnum_OtherPurpleRoom = (* - Rooms) / .sizeof(RoomType)
    .word NumberRoom
    .byte ColorType::purple, BWColorType::lightgray
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
    .byte ColorType::red, BWColorType::lightgray
    .byte RoomControlType::pfref
    .byte roomnum_upfrom_TopEntryRoom, roomnum_BelowYellowCastleLeftThinWall, roomnum_BlackCastle, roomnum_BelowYellowCastleRightThinWall

roomnum_SecretRoom = (* - Rooms) / .sizeof(RoomType)
    .word BelowYellowCastle
    .byte ColorType::purple, BWColorType::lightgray
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
; 00 invisible surround offsets
    .word SurroundInfo
    .word SurroundCurrState
    .word SurroundStates
    .byte ColorType::orange, BWColorType::lightergray
    .byte 7

; 01 portcullis #1
    .word PortInfo1
    .word PortCurrBase+0
    .word PortStates
    .byte ColorType::black, BWColorType::black
    .byte 0

; 02 portcullis #2
    .word PortInfo2
    .word PortCurrBase+1
    .word PortStates
    .byte ColorType::black, BWColorType::black
    .byte 0

; 03 portcullis #3
    .word PortInfo3
    .word PortCurrBase+2
    .word PortStates
    .byte ColorType::black, BWColorType::black
    .byte 0

; 04 name
    .word EasterEggInfo
    .word EasterEggCurrState
    .word EasterEggStates
    .byte ColorType::flash, BWColorType::black
    .byte 0

; 05 number
    .word NumberInfo
    .word NumberCurrState
    .word NumberStates
    .byte ColorType::green, BWColorType::black
    .byte 0

; 06 dragon #1 (aka, "Rhindle")
    .word RedDragonInfo
    .word RedDragonCurrBase
    .word DragonStates
    .byte ColorType::red, BWColorType::white
    .byte 0

; 07 dragon #2 (aka, "Yorgle")
    .word YellowDragonInfo
    .word YellowDragonCurrBase
    .word DragonStates
    .byte ColorType::yellow, BWColorType::darkgray
    .byte 0

; 08 dragon #3 (aka,"Grundle")
    .word GreenDragonInfo
    .word GreenDragonCurrBase
    .word DragonStates
    .byte ColorType::green, BWColorType::black
    .byte 0

; 09 sword
    .word SwordInfo
    .word SwordCurr
    .word SwordStates
    .byte ColorType::yellow, BWColorType::darkgray
    .byte 0

; 0a bridge
    .word BridgeInfo
    .word BridgeCurr
    .word BridgeStates
    .byte ColorType::purple, BWColorType::darkergray
    .byte $07

; 0b key #01
    .word YellowKeyInfo
    .word KeyCurr
    .word KeyStates
    .byte ColorType::yellow, BWColorType::darkgray
    .byte 0

; 0c key #02
    .word WhiteKeyInfo
    .word KeyCurr
    .word KeyStates
    .byte ColorType::white, BWColorType::white
    .byte 0

; 0d key #03
    .word BlackKeyInfo
    .word KeyCurr
    .word KeyStates
    .byte ColorType::black, BWColorType::black
    .byte 0

; 0e black bat (aka, "Knubberrub")
    .word BlackBatInfo
    .word BlackBatCurrBase
    .word BatStates
    .byte ColorType::black, BWColorType::black
    .byte 0

; 0f black dot
    .word DotInfo
    .word DotCurr
    .word DotStates
    .byte ColorType::invisible, BWColorType::invisible
    .byte 0

; 10 enchanted chalice (aka, "Holy Grail")
    .word ChaliceInfo
    .word ChaliceCurr
    .word ChaliceStates
    .byte ColorType::flash, BWColorType::darkgray
    .byte 0

; 11 magnet
    .word MagnetInfo
    .word MagnetCurr
    .word MagnetStates
    .byte ColorType::black, BWColorType::darkgray
    .byte 0

; 12 null
    .word BridgeInfo
    .word NullCurr
    .word NullStates
    .byte ColorType::black, BWColorType::black
    .byte 0

; 6502 vectors
.segment "VECTORS"
    .word START
    .word START
    .word START
