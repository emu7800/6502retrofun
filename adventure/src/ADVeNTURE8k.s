            .include "data/gfx/all.inc"
            .include "data/objects.inc"
            .include "data/rooms.inc"

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


            .setcpu "6502"
VSYNC       = $00       ; W 0000 00x0  Vertical Sync Set-Clear
VBLANK      = $01       ; W xx00 00x0  Vertical Blank Set-Clear
WSYNC       = $02       ; W ---- ----  Wait for Horizontal Blank
NUSIZ0      = $04       ; W 00xx 0xxx  Number-Size player/missile 0
NUSIZ1      = $05       ; W 00xx 0xxx  Number-Size player/missile 1
COLUP0      = $06       ; W xxxx xxx0  Color-Luminance Player 0
COLUP1      = $07       ; W xxxx xxx0  Color-Luminance Player 1
COLUPF      = $08       ; W xxxx xxx0  Color-Luminance Playfield
COLUBK      = $09       ; W xxxx xxx0  Color-Luminance Background
CTRLPF      = $0a       ; W 00xx 0xxx  Control Playfield, Ball, Collisions
PF0         = $0d       ; W xxxx 0000  Playfield Register Byte 0
PF1         = $0e       ; W xxxx xxxx  Playfield Register Byte 1
PF2         = $0f       ; W xxxx xxxx  Playfield Register Byte 2
RESP0       = $10       ; W ---- ----  Reset Player 0
AUDC0       = $15       ; W 0000 xxxx  Audio Control 0
AUDF0       = $17       ; W 000x xxxx  Audio Frequency 0
AUDV0       = $19       ; W 0000 xxxx  Audio Volume 0
AUDV1       = $1a       ; W 0000 xxxx  Audio Volume 1
GRP0        = $1b       ; W xxxx xxxx  Graphics Register Player 0
GRP1        = $1c       ; W xxxx xxxx  Graphics Register Player 1
ENAM0       = $1d       ; W 0000 00x0  Graphics Enable Missile 0
ENAM1       = $1e       ; W 0000 00x0  Graphics Enable Missile 1
ENABL       = $1f       ; W 0000 00x0  Graphics Enable Ball
HMP0        = $20       ; W xxxx 0000  Horizontal Motion Player 0
VDELP1      = $26       ; W 0000 000x  Vertical Delay Player 1
HMOVE       = $2a       ; W ---- ----  Apply Horizontal Motion
HMCLR       = $2b       ; W ---- ----  Clear Horizontal Move Registers
CXCLR       = $2c       ; W ---- ----  Clear Collision Latches

                        ;                             D7    D6
CXM0P       = $30       ; R xx00 0000  Read collision M0-P1 M0-P0 (unused)
CXM1P       = $31       ; R xx00 0000  Read collision M1-P0 M1-P1 (unused)
CXP0FB      = $32       ; R xx00 0000  Read Collision P0-PF P0-BL
CXP1FB      = $33       ; R xx00 0000  Read Collision P1-PF P1-BL
CXM0FB      = $34       ; R xx00 0000  Read Collision M0-PF M0-BL
CXM1FB      = $35       ; R xx00 0000  Read Collision M1-PF M1-BL
CXBLPF      = $36       ; R x000 0000  Read Collision BL-PF -----
CXPPMM      = $37       ; R xx00 0000  Read Collision P0-P1 M0-M1

INPT4       = $3c       ; R x000 0000  Read Input (Trigger) 0

SWCHA       = $0280     ; RW Port A data register (joysticks...)
SWCHB       = $0282     ; RW Port B data (console switches)
INTIM       = $0284     ; R Timer output
TIM64T      = $0296     ; W set 64 clock interval


            .zeropage   ; segment mapped to $80

roomgfx_base:                   .word 0
print_ptr:                      .word 0
print2_ptr:                     .word 0
print3_ptr:                     .word 0
print4_ptr:                     .word 0
curr_room:                      .byte 0     ; current room number
man_x:                          .byte 0     ; man's x coordinate
man_y:                          .byte 0     ; man's y coordinate
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
                                .byte 0     ; unused byte
cached_joystick:                .byte 0
portcullis_number:              .byte 0
direction_wanted:               .byte 0
obj_counter:                    .byte 0
object_carried:                 .byte 0     ; object carried by the man
objman_x_delta:                 .byte 0
objman_y_delta:                 .byte 0
curr_obj_number:                .byte 0
DotMacro zp
Dragon1Macro
Dragon2Macro
Dragon3Macro
MagnetMacro zp
SwordMacro zp
ChaliceMacro zp
BridgeMacro zp
YellowKeyMacro zp
WhiteKeyMacro zp
BlackKeyMacro zp
PortMacro zp
BlackBatMacro zp
objstore_ptr:                   .word 0
objdelta:                       .byte 0
MoveGameObjectArg_ObjNumber:    .byte 0      ; identifies the object to move (used by MoveGameObject)
MoveGameObjectArg_Difficulty:   .byte 0      ; difficulty for MoveGameObject to use (used by MoveGameObject)
joystick_record:                .byte 0
tmp1:                           .byte 0
SurroundMacro zp
GetObjectState_Arg:             .byte 0
NumberMacro zp
is_game_active:                 .byte 0      ; $ff=no, 0=yes
sound_duration_counter:         .byte 0
sound_type:                     .byte 0
linked_obj_index:               .byte 0
prev_room:                      .byte 0
prev_man_x:                     .byte 0
prev_man_y:                     .byte 0
input_counter:                  .word 0

stack_space:                    ; $e7-$ff (12 frames)

man_object  = $8a

            .code
START:      jmp StartGame

PrintDisplay:
            sta HMCLR       ;clear horizontal motion
            lda print3_ptr  ;position Player00 sprite to
            ldx #0          ; the X coordinate of Object1
            jsr PosSpriteX
            lda print4_ptr  ;position Player01 sprite to
            ldx #1          ; the X coordinate of Object2
            jsr PosSpriteX
            lda man_x       ;position ball sprite to
            ldx #4          ; the X coordinate of the Man
            jsr PosSpriteX
            sta WSYNC       ;wait for horizontal blank
            sta HMOVE       ;apply horizontal motion
            sta CXCLR       ;clear collision latches
            lda man_y       ;get the Y coordinate of the Man
            sec
            sbc #4          ;and adjust it (by four scan lines)
            sta man_y2      ; for printing (so Y coordinate specifies middle)
@PrintDisplay_1:
            lda INTIM                 ;wait for end of the
            bne @PrintDisplay_1       ; current frame
            lda #0
            sta p0gfx_offset          ;set Player00 definition index
            sta p1gfx_offset          ;set Player01 definition index
            sta roomgfx_offset        ;set room definition index
            sta GRP1                  ;clear any graphics for Player01
            lda #1
            sta VDELP1                ;vertically delay Player01
            lda #$68
            sta scan_line             ;set scan line count
; print top line of room
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
            lda #0
            sta VBLANK                ;clear any vertical blank
            jmp PrintPlayer00

; print Player01 (Object2)
PrintPlayer01:
            lda scan_line             ;get current scan line
            sec                       ;have we reached Object2's
            sbc print4_ptr+1          ; Y coordinate?
            sta WSYNC                 ;wait for horizontal blank
            bpl PrintPlayer00         ;if not, branch
            ldy p1gfx_offset          ;get the Player01 definition index
            lda (print2_ptr),y        ;get the next Player01 definition byte
            sta GRP1                  ; and display
            beq PrintPlayer00         ;if zero then definition finished
            inc p1gfx_offset          ;goto next Player01 definition byte
; print Player00 (Object1), Ball (Man), and Room
PrintPlayer00:
            ldx #0
            lda scan_line            ;get the current scan line
            sec                      ;have we reached the Object1's
            sbc print3_ptr+1         ; Y coordinate?
            bpl @PrintPlayer00_1     ;if not then branch
            ldy p0gfx_offset         ;get Player00 definition index
            lda (print_ptr),y        ;get the next Player00 definition byte
            tax
            beq @PrintPlayer00_1     ;if zero then definition finished
            inc p0gfx_offset         ;go to next Player00 definition byte
@PrintPlayer00_1:
            ldy #0                   ;disable Ball graphic
            lda scan_line            ;get scan line count
            sec                      ;have we reached the Man's
            sbc man_y2               ; Y coordinate?
            and #$fc                 ;mask value to four either side (getting depth of 8)
            bne @PrintPlayer00_2     ;if not, branch
            ldy #2                   ;enable Ball graphic
@PrintPlayer00_2:
            lda scan_line            ;get scan line count
            and #$0f                 ;have we reached a sixteenth scan line?
            bne @PrintPlayer00_4     ;if not, branch
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
            sty roomgfx_offset        ;save for next time
@PrintPlayer00_3:
            dec scan_line            ;goto next scan line
            lda scan_line            ;get the scan line
            cmp #8                   ;have we reached to within 8 scanlines of the bottom?
            bpl PrintPlayer01        ;if not, branch
            sta VBLANK               ;turn on VBLANK
            jmp TidyUp

; print Player00 (Object1) and Ball (Man)
@PrintPlayer00_4:
            sta WSYNC                ;wait for horizontal blank
            sty ENABL                ;enable ball (if wanted)
            stx GRP0                 ;display Player00 definition byte (if wanted)
            jmp @PrintPlayer00_3

TidyUp:     lda #0
            sta GRP1                 ;clear any graphics for Player01
            sta GRP0                 ;clear any graphics for Player00
            lda #$20
            sta TIM64T               ;start timing this frame using
            rts                      ; the 64-bit counter

; position sprite X horizontally
PosSpriteX: ldy #2              ;start with 10 clock cycles (to avoid HBLANK)
            sec                 ;divide the coordinate wanted
:           iny                 ; by fifteen, i.e. get coarse horizontal
            sbc #$0f            ; value (in multiples of 5 clock cycles
            bcs :-              ; therefore giving 15 color cycles)
            eor #$ff            ;flip remainder to positive value (inverted)
            sbc #6              ;convert to left or right of current position
            asl a
            asl a
            asl a               ;move to high nybble for TIA
            asl a               ; horizontal motion
            sty WSYNC           ;wait for horizontal blank
:           dey                 ;count down the color cycles
            bpl :-              ; (these are 5 machine / 15 color cycles)
            sta RESP0,x         ;reset the sprite, thus positioning it coarsely
            sta HMP0,x          ;set horizontal (fine) motion of sprite
            rts

DoVSYNC:    lda INTIM           ;get timer output
            bne DoVSYNC         ;wait for time-out
            lda #2
            sta WSYNC           ;wait for horizontal blank
            sta VBLANK          ;start vertical blanking
            sta WSYNC
            sta WSYNC
            sta WSYNC
            sta VSYNC
            sta WSYNC
            sta WSYNC
            lda #0
            sta WSYNC           ;wait for horizontal blank
            sta VSYNC           ;end vertical sync
            lda #$2a            ;set clock interval to
            sta TIM64T          ; count down next frame
            rts

; set up a room for print
SetupRoomPrint:
            lda curr_room         ;get current room number
            jsr RoomNumToAddress  ;convert it to an address
            ldy #0
            lda (dr_ptr),y        ;get low pointer to room graphics
            sta roomgfx_base
            ldy #1
            lda (dr_ptr),y        ;get high pointer to room graphics
            sta roomgfx_base+1
; checdk B&W switch for room graphics
            lda SWCHB             ;get console switches
            and #8                ;check black and white switch
            beq UseBW             ;branch if B&W
; use color
            ldy #2
            lda (dr_ptr),y        ;get room color
            jsr ChangeColor       ;change if necessary
            sta COLUPF            ;put in playfield color register
            jmp UseColor

UseBW:      ldy #3
            lda (dr_ptr),y        ;get B&W color
            jsr ChangeColor       ;change if necessary
            sta COLUPF            ;put in the playfield color registerg
; color background
UseColor:   lda #8                ;get light grey background
            jsr ChangeColor       ;change if necessary
            sta COLUBK            ;put it in the background color register
; playfield control
            ldy #4
            lda (dr_ptr),y        ;get the playfield control value
            sta CTRLPF            ; and put in the playfield control register
            and #$c0              ;get the "this wall" flag
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
            ldy #1
            lda (dr_ptr),y        ;get Object1's X coordinate
            sta print3_ptr        ; and store for print
            ldy #2
            lda (dr_ptr),y        ;get Object1's Y coordinate
            sta print3_ptr+1      ; and store for print
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
            sta print_ptr         ; and store for print
            iny
            lda (dr_ptr),y        ;get Object1's high graphic address
            sta print_ptr+1       ; and store for print
; check B&W for Object01
            lda SWCHB             ;get console switches
            and #8                ;check B&W switches
            beq MakeObjectBW      ;branch if B&W
; color
            lda a:Objects+ObjectType::color,x
            jsr ChangeColor       ;change if necessary
            sta COLUP0            ; and set color luminance00
            jmp ResizeObject

; B&W
MakeObjectBW:
            lda a:Objects+ObjectType::bw,x
            jsr ChangeColor       ;change if necessary
            sta COLUP0            ;set color luminance00
; Object1 size
ResizeObject:
            lda a:Objects+ObjectType::size,x
            ora #$10              ;and set to larger size if necessary
            sta NUSIZ0            ;(used by bridge and invisible surround)
; set up Object2 to print
            ldx object2
            lda a:Objects+ObjectType::info_ptr,x
            sta dr_ptr
            lda a:Objects+ObjectType::info_ptr+1,x
            sta dr_ptr+1
            ldy #1
            lda (dr_ptr),y        ;get Object2's X coordinate
            sta print4_ptr        ; and store for print
            ldy #2
            lda (dr_ptr),y        ;get Object2's Y coordinate
            sta print4_ptr+1      ; and store for print
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
            sta print2_ptr        ;get Object2's low graphic address
            iny
            lda (dr_ptr),y        ;get Object2's high graphic address
            sta print2_ptr+1
; check B&W for Object2
            lda SWCHB             ;get console switches
            and #8                ;check B&W switch
            beq MakeObject2BW     ;if B&W then branch
; color
            lda a:Objects+ObjectType::color,x
            jsr ChangeColor       ;change if necessary
            sta COLUP1            ;and set color luminance01
            jmp ResizeObject2

; B&W
MakeObject2BW:
            lda a:Objects+ObjectType::bw,x
            jsr ChangeColor       ;change if necessary
            sta COLUP1            ;and set color luminance01
; Object2 size
ResizeObject2:
            lda a:Objects+ObjectType::size,x
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
            cmp #162            ;check if over maximum (9*18)
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
            cmp curr_room           ; is it in this room?
            bne CheckForMoreObjects ;if not lets try next object (branch)
            lda object1             ;check first slot
            cmp #162              ;if not default (no-object)
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

; get pointer to current state
GetObjectState:
            ldy #0
            lda GetObjectState_Arg
@GetObjectState_1:
            cmp (dr_ptr),y        ;have we found it in the list of states?
            bcc @GetObjectState_2 ;if nearing it then found it and return
            beq @GetObjectState_2 ;if found it then return
            iny
            iny                   ;goto next state in list of states
            iny
            jmp @GetObjectState_1

@GetObjectState_2:
            rts


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
            and #3                ;mask for the reset/select switches
            cmp #3                ;have either of them been used?
            beq :++               ;if not branch
:           lda #0                ;zero the high count of the
            sta input_counter+1   ; switches or joystick have been used
:           rts

; change color if necessary
ChangeColor:
            lsr a                 ;if bit 0 of the color is set
            bcc @ChangeColor2     ; then the room is to flash
            tay                   ;use color as an index (usually E5 - the low counter)
            lda $0080,y           ;get flash color (usually the low counter)
@ChangeColor2:
            ldy input_counter+1   ;get the input counter
            bpl @ChangeColor3     ;if console/joystick moved recently then branch
            eor input_counter+1   ;merge the high counter with the color wanted
            and #$fb              ;keep this color bug merge down the luminance
@ChangeColor3:
            asl a                 ;and restore original color if necessary
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
            ldx #$28              ;clear TIA registers
            lda #0                ; $04-$2c i.e. blank
ResetAll:   sta NUSIZ0,x          ; everything and turn
            dex                   ; everything off
            bpl ResetAll
            txs                   ;reset stack to $ff
SetupVars:  sta $00,x             ;clear $80 to $ff user vars
            dex
            bmi SetupVars
            jsr ThinWalls         ;position the thin walls (missiles)
            jsr SetupRoomObjects  ;set up objects rooms and positions

MainGameLoop:
            jsr CheckGameStart    ;check for game start
            jsr MakeSound         ;make noise if necessary
            jsr CheckInput        ;check for input
            lda is_game_active    ;is the game active?
            bne NonActiveLoop     ;if not branch
            lda ChaliceInfo       ;get the room the chalice is in
            cmp #$12              ;is it in the yellow castle?
            bne @MainGameLoop_2   ;if not branch
            lda #$ff
            sta sound_duration_counter  ;set the note count to maximum
            sta is_game_active    ;set the game to inactive
            lda #0                ;set the noise type to end-noise
            sta sound_type
@MainGameLoop_2:
            ldy #0                ;allow joystick read - all movement
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

; position missiles to "thin wall" areas
ThinWalls:  lda #$0d              ;position missile 00 to
            ldx #2                ; (0d,00) - left thin wall
            jsr PosSpriteX
            lda #$96              ;position missile 01 to
            ldx #3                ; (96,00) - right thin wall
            jsr PosSpriteX
            sta WSYNC             ;wait for horizontal blank
            sta HMOVE             ;apply the horizontal move
            rts

CheckGameStart:
            lda SWCHB             ;get the console switches
            eor #$ff              ;flip (as reset active low)
            and cached_swchb      ;compare with what was before
            and #1                ;and check only the reset switch
            beq CheckReset        ;if no reset then branch
            lda is_game_active    ;has the game started?
            cmp #$ff              ;if not then branch
            beq SetupRoomObjects
            lda #$11              ;get the yellow castle room
            sta curr_room         ;make it the current room
            sta prev_room         ;make it the previous room
            lda #$50              ;get the X coordinate
            sta man_x             ;make it the current man X coordinate
            sta prev_man_x        ;make it the previous man X coordinate
            lda #$20              ;get the Y coordinate
            sta man_y             ;make it the current man Y coordinate
            sta prev_man_y        ;make it the previous man Y coordinate
            lda #0
            sta Dragon1CurrBase   ;set the red dragon's state to OK
            sta Dragon2CurrBase   ;set the yellow dragon's state to OK
            sta Dragon3CurrBase   ;set the green dragon's state to OK
            sta sound_duration_counter  ;set the note count to zero
            lda #$a2
            sta object_carried    ;set no object being carried
CheckReset: lda SWCHB             ;get the console switches
            eor #$ff              ;flip (as select active low)
            and cached_swchb      ;compare with what was before
            and #2                ;and check only the select switch
            beq StoreSwitches     ;branch if select not being used
            lda curr_room         ;get the current room
            cmp #0                ;is it the "number" room?
            bne SetupRoomObjects  ;branch if not
            lda NumberCurrBase    ;increment the level
            clc                   ; number (by two)
            adc #2
            cmp #6                ;have we reached the maximum?
            bcc ResetSetup
            lda #0                ;if yep then set back to zero
ResetSetup: sta NumberCurrBase    ;store the new level number
SetupRoomObjects:
            lda #0                ;set the current room to the
            sta curr_room         ; "number" room
            sta prev_room         ;and the previous room
            lda #0                ;set the man's Y coordinate to zero
            sta man_y             ;and the previous Y coordinate
            sta prev_man_y        ;(so can't be seen)
            ldy NumberCurrBase    ;get the level number
            lda GameObjects,y     ;get the low pointer to object locations
            sta dr_ptr
            lda GameObjects+1,y   ;get the high pointer to object locations
            sta dr_ptr+1
            ldy #$30              ;copy all the objects dynamic information
:           lda (dr_ptr),y        ; (the rooms and positions) into
            sta $00a1,y           ; the working area
            dey
            bpl :-
            lda NumberCurrBase    ;get the level number
            cmp #4                ;branch if level one
            bcc SignalGameStart   ;or two (where all objects are in defined areas)
            jsr RandomizeLevel3   ;put some objects in random rooms
            jsr DoVSYNC           ;wait for VSYNC
            jsr PrintDisplay      ;display rooms and objects
SignalGameStart:
            lda #0                ;signal that the game has started
            sta is_game_active
            lda #$a2              ;set no object being carried
            sta object_carried
StoreSwitches:
            lda SWCHB             ;store the current console switches
            sta cached_swchb
            rts

; put objects in random rooms for level 3
RandomizeLevel3:
            ldy #30               ;for each of the eleven objects...
:           lda input_counter     ;get the low input counter as seed
            lsr a
            lsr a
            lsr a                 ;generate a pseudo-random
            lsr a                 ; room number
            lsr a
            sec
            adc input_counter     ;store the low input counter
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
            lda curr_room         ;get the current room
            cmp BridgeInfo        ;is the bridge in this room?
            bne ReadStick         ;if not branch
; check going through the bridge
            lda man_x             ;get the man's X coordinate
            sec
            sbc $bd               ;subtract the bridge's X coordinate
            cmp #$0a              ;if less than $0A then forget it
            bcc ReadStick
            cmp #$17              ;if more than $17 then forget it
            bcs ReadStick
            lda z:BridgeInfo+ObjectInfoType::ycoord
            sec
            sbc man_y             ;subtract the man's Y coordinate
            cmp #$fc
            bcs NoCollision       ;if more than $FC then going through bridge
            cmp #$19              ;if more than $19 then forget it
            bcs ReadStick
; no collision (and going through bridge)
NoCollision:
            lda #$ff              ;reset the joystick input
            sta cached_joystick
            lda curr_room         ;get the current room
            sta prev_room         ; and store temporarily
            lda man_x             ;get the man's X coordinate
            sta prev_man_x        ; and store temporarily
            lda man_y             ;get the man's Y coordinate
            sta prev_man_y        ; and store temporarily
; read sticks
ReadStick:  cpy #0                ;???is game in first phase?
            bne @ReadStick_2      ;if not, don't bother with joystick read
            lda SWCHA             ;read joysticks
            sta cached_joystick
@ReadStick_2:
            lda prev_room         ;get temporary room
            sta curr_room         ; and make it the current room
            lda prev_man_x        ;get temporary X coordinate
            sta man_x             ; and make it the man's X coordinate
            lda prev_man_y        ;get temporary Y coordinate
            sta man_y             ; and make it the man's Y coordinate
            lda cached_joystick   ;get the joystick position
            ora JoystickMergeValues,y  ;merge out movement not allowed in this phase
            sta direction_wanted  ;and store cooked movement
            ldy #3                ;set the delta for the ball
            ldx #man_object       ;point to man's coordinates
            jsr MoveGroundObject  ;move the man
            rts


; deal with object pickup and putdown
PickupPutdown:
            rol INPT4             ;get joystick trigger
            ror joystick_record   ;merge into joystick record
            lda joystick_record   ;get joystick record
            and #$c0              ;merge out previous presses
            cmp #$40              ;was it previously pressed?
            bne @PickupPutdown_2  ;if not branch
            lda #$a2
            cmp object_carried    ;if nothing is being carried
            beq @PickupPutdown_2  ; then branch
            sta object_carried    ;drop object
            lda #4                ;set noise type to four
            sta sound_type
            lda #4                ;set noise count to four
            sta sound_duration_counter
@PickupPutdown_2:
; check for collision
            lda CXP0FB
            and #$40              ;get Ball-Player00 collision
            beq @PickupPutdown_3  ;if nothing occurred then branch
; with Player00
            lda object1           ;get type of Player00
            sta obj_collided_with
            jmp CollisionDetected ;deal with collision

@PickupPutdown_3:
            lda CXP1FB
            and #$40              ;get Ball-Player01 collision
            beq @PickupPutdown_4  ;if nothing has happened, branch
            lda object2           ;get type of Player01
            sta obj_collided_with
            jmp CollisionDetected ;deal with collision

@PickupPutdown_4:
            jmp NoObject          ;deal with no collision (return)

CollisionDetected:
            ldx obj_collided_with
            jsr GetObjectAddress  ;get its dynamic information
            lda obj_collided_with
            cmp #$51              ;is it carriable?
            bcc NoObject          ;if not, branch
            ldy #0
            lda (dr_ptr),y        ;get the object's room
            cmp curr_room         ;is it in the current room?
            bne NoObject          ;if not, branch
            lda obj_collided_with
            cmp object_carried    ;is it the object being carried?
            beq PickupObject      ;if so, branch (and actually pick it up)
            lda #5                ;set noise type to five
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
            sbc man_x             ;subtract the man's X coordinate
            sta objman_x_delta    ; and store the difference
            ldy #2
            lda (dr_ptr),y        ;get the object's Y coordinate
            sec
            sbc man_y             ;subtract the man's Y coordinate
            sta objman_y_delta    ; and store the difference
NoObject:   rts                   ; no collision

; move the carried object
MoveCarriedObject:
            ldx object_carried
            cpx #$a2              ;if nothing then branch (return)
            beq @MoveCarriedObject_2
            jsr GetObjectAddress  ;get its dynamic information
            ldy #0
            lda curr_room         ;get the current room
            sta (dr_ptr),y        ; and store the object's current room
            ldy #$01
            lda man_x             ;get the man's X coordinate
            clc
            adc objman_x_delta    ;add the X difference
            sta (dr_ptr),y        ; and store as the object's X coordinate
            ldy #2
            lda man_y             ;get the man's Y coordinate
            clc
            adc objman_y_delta    ;add the Y difference
            sta (dr_ptr),y        ; and store as the object's Y coordinate
            ldy #0                ;set no delta
            lda #$ff              ;set no movement
            ldx dr_ptr            ;get the object's dynamic address
            jsr MoveGroundObject  ;move the object
@MoveCarriedObject_2:
            rts

; move the object
MoveGroundObject:
            jsr MoveObjectDelta     ;move the object by delta
            ldy #2                  ;set to do the three
MoveGroundObject_2:
            sty portcullis_number
            lda PortCurrBase,y      ;get the portal state
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
            sta PortCurrBase,y      ;set the portcullis state to 01
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
            lda $01,x             ;get the object's X coordinate
            cmp #3                ;is it three or less?
            bcc @DealWithLeft_2   ;if so, branch (off to left)
            cmp #$f0              ;is it $F0 or more?
            bcs @DealWithLeft_2   ;if so, branch (off to right)
            jmp DealWithDown

@DealWithLeft_2:
            cpx #man_object       ;are we dealing with the man?
            beq @DealWithLeft_3   ;if so, branch
            lda #$9a              ;set new X coordinate for the others
            jmp @DealWithLeft_4

@DealWithLeft_3:
            lda #$9e              ;set new X coordinate for the ball
@DealWithLeft_4:
            sta $01,x             ;store the next X coordinate
            ldy #8                ;and get the direction wanted
            jmp GetNewRoom        ;go and get new room

; check and deal with Down
DealWithDown:
            lda $02,x             ;get object's Y coordinate
            cmp #$0d              ;if it's greater than $0D then
            bcs DealWithRight     ; branch
            lda #$69              ;set new Y coordinate
            sta $02,x
            ldy #7                ;get the direction wanted
            jmp GetNewRoom        ;go and get new room

; check and deal with right
DealWithRight:
            lda $01,x             ;get the object's X coordinate
            cpx #man_object       ;are we dealing with the man?
            bne @DealWithRight_2  ;branch if not
            cmp #$9f              ;has the object reached the right?
            bcc MovementReturn    ;branch if not
            lda $00,x             ;get the Ball's room
            cmp #3                ;is it room #3 (right to secret room)
            bne @DealWithRight_3  ;branch if not
            lda DotInfo+ObjectInfoType::room_num  ;check the room of the black dot
            cmp #$15              ;is it in the hidden room area?
            beq @DealWithRight_3  ;if so, branch
; manually change to secret room
            lda #$1e              ;set room to secret room
            sta $00,x             ;and make it current
            lda #3                ;set the X coordinate
            sta $01,x
            jmp MovementReturn    ;and exit

@DealWithRight_2:
            cmp #direction_wanted ;has the object reached the right of the screen?
            bcc MovementReturn    ;branch if not (no room change)
@DealWithRight_3:
            lda #3                ;set the next X coordinate
            sta $01,x
            ldy #6                ;and get the direction wanted
            jmp GetNewRoom        ;get the new room

; get new room
GetNewRoom: lda $00,x             ;get the object's room
            jsr RoomNumToAddress  ;convert it to an address
            lda (dr_ptr),y        ;get the adjacent room
            jsr AdjustRoomLevel   ;deal with the level differences
            sta $00,x             ; and store as new object's room
MovementReturn:
            rts

; move the object in direction by delta
MoveObjectDelta:
            sta direction_wanted
@MoveObject_2:
            dey                   ;count down the delta
            bmi @MoveObject_7
            lda direction_wanted
            and #$80              ;check for right move
            bne @MoveObject_3     ;if no move right then branch
            inc $01,x             ;increment the X coordinate
@MoveObject_3:
            lda direction_wanted
            and #$40              ;check for left move
            bne @MoveObject_4     ;if no move left then branch
            dec $01,x             ;decrement the X coordinate
@MoveObject_4:
            lda direction_wanted
            and #$10              ;check for move up
            bne @MoveObject_5     ;if no move up then branch
            inc $02,x
@MoveObject_5:
            lda direction_wanted
            and #$20              ;check for move down
            bne @MoveObject_6     ;if no move down then branch
            dec $02,x             ;decrement the Y coordinate
@MoveObject_6:
            jmp @MoveObject_2     ;keep going until delta finished

@MoveObject_7:
            rts

; adjust room for different levels
AdjustRoomLevel:
            cmp #$80                ;is the room number
            bcc @AdjustRoomLevel_2  ; above $80?
            sec
            sbc #$80                ;remove the $80 flag and
            sta tmp1                ; store the room number
            lda NumberCurrBase      ;get the level number
            lsr a                   ;divide it by two
            clc
            adc tmp1                ;add to the original room
            tay
            lda RoomDiffs,y         ;use as an offset to get the next room
@AdjustRoomLevel_2:
            rts

; get player-ball collision
PBCollision:
            cmp object1           ;is it the first object?
            beq @PBCollision_2    ;yes, then branch
            cmp object2           ;is it the second object?
            beq @PBCollision_3    ;yes, then branch
            lda #0                ;otherwise nothing
            rts

@PBCollision_2:
            lda CXP0FB            ;get player00-ball collision
            and #$40
            rts

@PBCollision_3:
            lda CXP1FB            ;get player01-ball collision
            and #$40
            rts

; find which object has hit object wanted
FindObjHit: lda CXPPMM            ;get player00-player01
            and #$80              ; collision
            beq @FindObjHit_2     ;if nothing, branch
            cpx object1           ;is object 1 the one being hit?
            beq @FindObjHit_3     ;if so, branch
            cpx object2           ;is object 2 the one being hit?
            beq @FindObjHit_4     ;if so, branch
@FindObjHit_2:
            lda #$a2              ;therefore select the other
            rts

@FindObjHit_3:
            lda object2               ;therefore select the other
            rts

@FindObjHit_4:
            lda object1               ;therefore select the other
            rts

; move object
MoveGameObject:
            jsr GetLinkedObject   ;get linked object and movement
            ldx MoveGameObjectArg_ObjNumber
            lda direction_wanted
            bne @MoveGameObject_2 ;if movement then branch
            lda $03,x             ;use old movement
@MoveGameObject_2:
            sta $03,x             ;store the new movement
            ldy objdelta          ;get the object's delta
            jsr MoveGroundObject  ;move the object
            rts

; find linked object and get movement
GetLinkedObject:
            lda #0                ;set index to zero
            sta linked_obj_index
@GetLinkedObj_2:
            ldy linked_obj_index
            lda (objstore_ptr),y  ;get first object
            tax
            iny
            lda (objstore_ptr),y  ;get second object
            tay
            lda $00,x             ;get Object1's room
            cmp $0000,y           ;compare the Object2's room
            bne @GetLinkedObj_3   ;if not the same room then branch
            cpy MoveGameObjectArg_Difficulty  ;have we matched the second object
            beq @GetLinkedObj_3   ; for difficulty (if so, carry on)
            cpx MoveGameObjectArg_Difficulty  ;have we matched the first object
            beq @GetLinkedObj_3   ; for difficulty (if so, carry on)
            jsr @GetLinkedObj_4   ;get object's movement
            rts

@GetLinkedObj_3:
            inc linked_obj_index
            inc linked_obj_index
            ldy linked_obj_index
            lda (objstore_ptr),y  ;check for end of sequence
            bne @GetLinkedObj_2   ;if not branch
            lda #0                ;set no move if no
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

; move a dragon
MoveDragon: stx curr_obj_number   ;save object we're dealing with
            lda a:Objects+ObjectType::info_ptr,x
            tax
            lda $04,x             ;get the object's state
            cmp #0                ;is it in state 00 (normal #1)
            bne @MoveDragon_6     ;branch if not
; dragon normal (state 1)
            lda SWCHB             ;read console switches
            and #$80              ;check for P1 difficulty
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
            ora NumberCurrBase    ;merge in the level number
            tay                   ;create lookup
            lda DragonDiff,y      ;get new state
            sta $04,x             ;store as dragon's state (open mouthed)
            lda prev_man_x
            sta $01,x             ;get temp ball X coord and store as dragon's
            lda prev_man_y
            sta $02,x             ;get temp ball Y coord and store as dragon's
            lda #1
            sta sound_type        ;set noise type to 01
            lda #$10
            sta sound_duration_counter  ;set noise count to $10 i.e. make roar noise
@MoveDragon_4:
            stx portcullis_number
            ldx curr_obj_number   ;get the object number
            jsr FindObjHit        ;set if another object has hit the dragon
            ldx portcullis_number
            cmp #$51              ;has the sword hit the dragon?
            bne @MoveDragon_5     ;if not, branch
            lda #1                ;set the state to 01 (dead)
            sta $04,x
            lda #3                ;set sound three
            sta sound_type
            lda #$10              ;set a noise count of $10
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
            sta curr_room         ;store as the ball's current room
            sta prev_room               ; and previous room
            lda $01,x             ;get the dragon's X coordinate
            clc
            adc #3                ;adjust
            sta man_x             ; and store as the man's X coordinate
            sta prev_man_x               ; and previous X coordinate
            lda $02,x             ;get the dragon's Y coordinate
            sec
            sbc #$0a              ;adjust
            sta man_y             ; and store as the man's Y coordinate
            sta prev_man_y        ; and the previous Y coordinate
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
            lda #2                ;set noise two
            sta sound_type
            lda #$10              ;set the count of noise to $10
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
            sbc z:BlackBatInfo+ObjectInfoType::xcoord  ;find the difference with the Bat's X coordinate
            clc
            adc #4                ;adjust so Bat in middle of object
            and #$f8              ;is Bat within seven pixels?
            bne @MoveBat_4        ;if not, no pickup possible
            lda $02,x             ;get the object's Y coordinate
            sec
            sbc z:BlackBatInfo+ObjectInfoType::ycoord  ;find the difference with the Bat's
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
            lda z:BlackBatInfo+ObjectInfoType::xcoord
            clc
            adc #8                ;adjust to the right
            sta $01,x             ;make it the object's X coordinate
            lda z:BlackBatInfo+ObjectInfoType::ycoord
            sta $02,x             ;store is as the object's Y coordinate
            lda BlackBatCarriedObject  ;get the object being carried by the bat
            ldy object_carried
            cmp Objects+ObjectType::info_ptr,y  ;are they the same?
            bne @MoveBat_5        ;if not branch
            lda #$a2              ;set nothing being carried
            sta object_carried
@MoveBat_5: rts


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
            ldx #man_object
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


; deal with magnet
Mag:        lda z:MagnetInfo+ObjectInfoType::ycoord
            sec
            sbc #8                ;adjust to its "poles"
            sta z:MagnetInfo+ObjectInfoType::ycoord
            lda #0                ;con difficulty!
            sta MoveGameObjectArg_Difficulty
            lda #<MagnetMatrix    ;set low address of object store
            sta objstore_ptr
            lda #>MagnetMatrix    ;set high address of object store
            sta objstore_ptr+1
            jsr GetLinkedObject   ;get linked object and set movement
            lda direction_wanted
            beq @Mag_2            ;if none, then forget it
            ldy #1                ;set delta to one
            jsr MoveGroundObject  ;move object
@Mag_2:     lda z:MagnetInfo+ObjectInfoType::ycoord           ;reset the magnet's
            clc                   ; Y coordinate
            adc #8
            sta z:MagnetInfo+ObjectInfoType::ycoord
            rts


; deal with invisible surround moving
Surround:   lda curr_room         ;set the current room
            jsr RoomNumToAddress  ;convert it to an address
            ldy #2
            lda (dr_ptr),y        ;get the room's color
            cmp #8                ;is it invisible?
            beq @Surround_2       ;if so branch
            lda #0                ;if not, signal the
            sta SurroundInfo+ObjectInfoType::ycoord ; invisible surround not wanted
            jmp @Surround_Done

@Surround_2:
            lda curr_room         ;get the current room
            sta SurroundInfo      ;and store as the invisible surround
            lda man_x             ;get the man's X coordinate
            sec
            sbc #$0e              ;adjust for surround,
            sta SurroundInfo+ObjectInfoType::xcoord
            lda man_y             ;get the man's Y coordinate
            clc
            adc #$0e              ;adjust for surround
            sta SurroundInfo+ObjectInfoType::ycoord
            lda SurroundInfo+ObjectInfoType::xcoord
            cmp #$f0              ;is it close to the right edge?
            bcc @Surround_3       ;branch if not
            lda #1                ;flick surround to the other side of the screen
            sta SurroundInfo+ObjectInfoType::xcoord
            jmp @Surround_Done
@Surround_3:
            cmp #$82              ;???
            bcc @Surround_Done    ;???
            lda #$81              ;???
            sta SurroundInfo+ObjectInfoType::xcoord ;???
@Surround_Done:
            rts

; make a noise
MakeSound:  lda sound_duration_counter  ;check noise count
            bne @MakeSound_2      ;branch if noise to be made
            sta AUDV0             ;turn off the volume
            sta AUDV1
            rts

@MakeSound_2:
            dec sound_duration_counter  ;go to the next note
            lda sound_type        ;get the noise type
            beq GameOverNoise     ;game over
            cmp #1                ;roar
            beq RoarNoise
            cmp #2                ;man eaten
            beq EatenNoise
            cmp #3                ;dying dragon
            beq DragDieNoise
            cmp #4                ;dropping object
            beq DropObjectNoise
            cmp #5                ;pickup up object
            beq GetObjectNoise
            rts

; noise 0: game over
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

; noise 1: roar
RoarNoise:  lda sound_duration_counter
            lsr a
            lda #3                ;if it was even then
            bcs SetVolume         ; branch
            lda #8                ;get a different audio control value
SetVolume:  sta AUDC0             ;set audio control 00
            lda sound_duration_counter  ;set the volume to the noise count
            sta AUDV0
            lsr a                 ;divide by four
            lsr a
            clc
            adc #$1c              ;set the frequency
            sta AUDF0
            rts

; noise 2: man eaten
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

; noise 3: dying dragon
DragDieNoise:
            lda #4                ;set the audio control
            sta AUDC0
            lda sound_duration_counter  ;put the note count in
            sta AUDV0             ; the volume
            eor #$1f
            sta AUDF0             ;flip the count as store
            rts                   ; as the frequency

; noise 4: dropping object
DropObjectNoise:
            lda sound_duration_counter
            eor #3                ;reverse it as noise does up
NoiseDropObject_2:
            sta AUDF0             ;store in frequency for channel 00
            lda #5
            sta AUDV0             ;set volume on channel 00
            lda #6
            sta AUDC0             ;set a noise on channel 00
            rts

; noise 5: picking up an object
GetObjectNoise:
            lda sound_duration_counter
            jmp NoiseDropObject_2 ; and make same noise as drop


            .rodata

; Room bounds data.
;
; e.g. the chalice can only exist in room range [$13, $1a] for level 3.
Lvl3ObjRoomBounds:
            .byte ChaliceInfo,   $13, $1a     ;chalice
            .byte Dragon1Info,   $01, $1d     ;red dragon
            .byte Dragon2Info,   $01, $1d     ;yellow dragon
            .byte Dragon3Info,   $01, $1d     ;green dragon
            .byte SwordInfo,     $01, $1d     ;sword
            .byte BridgeInfo,    $01, $1d     ;bridge
            .byte YellowKeyInfo, $01, $1d     ;yellow key
            .byte WhiteKeyInfo,  $01, $16     ;white key
            .byte BlackKeyInfo,  $01, $12     ;black key
            .byte BlackBatInfo,  $01, $1d     ;bat
            .byte MagnetInfo,    $01, $1d     ;magnet

GameObjects:
            .word Game1Objects      ;pointer to object locations for game 01
            .word Game2Objects      ;pointer to object locations for game 02
            .word Game2Objects      ;pointer to object locations for game 03

; object locations (room and coordinate) for game 01
Game1Objects:
            ;     Rm,  X,   Y,   Mvt, State
            .byte $03, $51, $12           ;black dot (normally $15, but moved to $03 for game 01 for convenience)
            .byte $0e, $50, $20, $00, $00 ;red dragon
            .byte $01, $50, $20, $00, $00 ;yellow dragon
            .byte $1d, $50, $20, $00, $00 ;green dragon
            .byte $1b, $80, $20           ;magnet
            .byte $12, $20, $20           ;sword
            .byte $1c, $30, $20           ;chalice
            .byte $04, $29, $37           ;bridge
            .byte $11, $20, $40           ;yellow key
            .byte $0e, $20, $40           ;white key
            .byte $1d, $20, $40           ;black key
            .byte $1c                     ;portcullis state
            .byte $1c                     ;portcullis state
            .byte $1c                     ;portcullis state
            .byte $1a, $20, $20, $00, $00 ;bat
            .byte $78, $00                ;bat (carrying, fed-up)

; object locations (room and coordinate) for games 02 and 03
Game2Objects:
            ;     Rm,  X,   Y,   Mvt, State
            .byte $15, $51, $12           ;black dot
            .byte $14, $50, $20, $a0, $00 ;red dragon
            .byte $19, $50, $20, $a0, $00 ;yellow dragon
            .byte $04, $50, $20, $a0, $00 ;green dragon
            .byte $0e, $80, $20           ;magnet
            .byte $11, $20, $20           ;sword
            .byte $14, $30, $20           ;chalice
            .byte $0b, $40, $40           ;bridge
            .byte $09, $20, $40           ;yellow key
            .byte $06, $20, $40           ;white key
            .byte $19, $20, $40           ;black key
            .byte $1c                     ;portcullis state
            .byte $1c                     ;portcullis state
            .byte $1c                     ;portcullis state
            .byte $02, $20, $20, $90, $00 ;bat
            .byte $78, $00                ;bat (carrying, fed-up)

; red dragon's object matrix
RedDragMatrix:
            .byte SwordInfo,   Dragon1Info   ;sword, red dragon
            .byte Dragon1Info, man_object    ;red dragon, man
            .byte Dragon1Info, ChaliceInfo   ;red dragon, chalice
            .byte Dragon1Info, WhiteKeyInfo  ;red dragon, white key
            .byte $00

; yellow dragon's object matrix
YelDragMatrix:
            .byte  SwordInfo,     Dragon2Info  ;sword, yellow dragon
            .byte  YellowKeyInfo, Dragon2Info  ;yellow key, yellow dragon
            .byte  Dragon2Info,   man_object   ;yellow dragon, man
            .byte  Dragon2Info,   ChaliceInfo  ;yellow dragon, chalice
            .byte  $00

GreenDragMatrix:
            .byte SwordInfo,   Dragon3Info   ;sword, green dragon
            .byte Dragon3Info, man_object    ;green dragon, man
            .byte Dragon3Info, ChaliceInfo   ;green dragon, chalice
            .byte Dragon3Info, BridgeInfo    ;green dragon, bridge
            .byte Dragon3Info, MagnetInfo    ;green dragon, magnet
            .byte Dragon3Info, BlackKeyInfo  ;green dragon, black key
            .byte $00

; dragon difficulty
DragonDiff: .byte  $d0, $e8       ;level 1: Am, Pro
            .byte  $f0, $f6       ;level 2: Am, Pro
            .byte  $f0, $f6       ;level 3: Am, Pro

; bat object matrix
BatMatrix:  .byte  BlackBatInfo, ChaliceInfo    ;bat, chalice
            .byte  BlackBatInfo, SwordInfo      ;bat, sword
            .byte  BlackBatInfo, BridgeInfo     ;bat, bridge
            .byte  BlackBatInfo, YellowKeyInfo  ;bat, yellow key
            .byte  BlackBatInfo, WhiteKeyInfo   ;bat, white key
            .byte  BlackBatInfo, BlackKeyInfo   ;bat, black key
            .byte  BlackBatInfo, Dragon1Info    ;bat, red dragon
            .byte  BlackBatInfo, Dragon2Info    ;bat, yellow dragon
            .byte  BlackBatInfo, Dragon3Info    ;bat, green dragon
            .byte  BlackBatInfo, MagnetInfo     ;bat, magnet
            .byte  0

PortOffsets:
            .byte  $09, $12, $1b       ;portcullis #1, #2, #3

KeyOffsets: .byte  $63, $6c, $75       ;keys (yellow, white, black)
EntryRoomOffsets:
            .byte  $12, $1a, $1b       ;castle entry rooms (yellow, white, black)
CastleRoomOffsets:
            .byte  $11, $0f, $10       ;castle rooms (yellow, white, black)ffff

MagnetMatrix:
            .byte YellowKeyInfo, MagnetInfo   ;yellow key, magnet
            .byte WhiteKeyInfo,  MagnetInfo   ;white key, magnet
            .byte BlackKeyInfo,  MagnetInfo   ;black key, magnet
            .byte SwordInfo,     MagnetInfo   ;sword, magnet
            .byte BridgeInfo,    MagnetInfo   ;bridge, magnet
            .byte ChaliceInfo,   MagnetInfo   ;chalice, magnet
            .byte 0

JoystickMergeValues:
            .byte  $00, $c0, $30  ;no change, no horizontal, no vertical

LeftOfName: .byte $f0, $ff, $ff
            .byte $00, $00, $00
            .byte $00, $00, $00
            .byte $00, $00, $00
            .byte $00, $00, $00
            .byte $00, $00, $00

BelowYellowCastle:
            .byte $f0, $ff, $0f   ;line shared with above
            .byte $00, $00, $00
            .byte $00, $00, $00
            .byte $00, $00, $00
            .byte $00, $00, $00
            .byte $00, $00, $00
            .byte $f0, $ff, $ff

SideCorridor:
            .byte $f0, $ff, $0f
            .byte $00, $00, $00
            .byte $00, $00, $00
            .byte $00, $00, $00
            .byte $00, $00, $00
            .byte $00, $00, $00
            .byte $f0, $ff, $0f

NumberRoom: .byte $f0, $ff, $ff
            .byte $30, $00, $00
            .byte $30, $00, $00
            .byte $30, $00, $00
            .byte $30, $00, $00
            .byte $30, $00, $00
            .byte $f0, $ff, $0f

TwoExitRoom:
            .byte $f0, $ff, $0f   ; 1111....11111111....1111
            .byte $30, $00, $00   ; ..11....................
            .byte $30, $00, $00   ; ..11....................
            .byte $30, $00, $00   ; ..11....................
            .byte $30, $00, $00   ; ..11....................
            .byte $30, $00, $00   ; ..11....................
            .byte $f0, $ff, $0f   ; 1111....11111111....1111

BlueMazeTop:
            .byte $f0, $ff, $0f   ; 1111....11111111....1111
            .byte $00, $0c, $0c   ; ............11......11..
            .byte $f0, $0c, $3c   ; 1111........11....1111..
            .byte $f0, $0c, $00   ; 1111........11..........
            .byte $f0, $ff, $3f   ; 1111....11111111..111111
            .byte $00, $30, $30   ; ..........11......11....
            .byte $f0, $33, $3f   ; 1111......11..11..111111

BlueMaze1:  .byte $f0, $ff, $ff
            .byte $00, $00, $00
            .byte $f0, $fc, $ff
            .byte $f0, $00, $c0
            .byte $f0, $3f, $cf
            .byte $00, $30, $cc
            .byte $f0, $f3, $cc

BlueMazeBottom:
            .byte $f0, $f3, $0c
            .byte $00, $30, $0c
            .byte $f0, $3f, $0f
            .byte $f0, $00, $00
            .byte $f0, $f0, $00
            .byte $00, $30, $00
            .byte $f0, $ff, $ff

BlueMazeCenter:
            .byte $f0, $33, $3f
            .byte $00, $30, $3c
            .byte $f0, $ff, $3c
            .byte $00, $03, $3c
            .byte $f0, $33, $3c
            .byte $00, $33, $0c
            .byte $f0, $f3, $0c

BlueMazeEntry:
            .byte $f0, $f3, $cc
            .byte $00, $33, $0c
            .byte $f0, $33, $fc
            .byte $00, $33, $00
            .byte $f0, $f3, $ff
            .byte $00, $00, $00
            .byte $f0, $ff, $0f

MazeMiddle: .byte $f0, $ff, $cc
            .byte $00, $00, $cc
            .byte $f0, $03, $cf
            .byte $00, $03, $00
            .byte $f0, $f3, $fc
            .byte $00, $33, $0c

MazeSide:   .byte $f0, $33, $cc       ;line shared with above room
            .byte $00, $30, $cc
            .byte $00, $3f, $cf
            .byte $00, $00, $c0
            .byte $00, $3f, $c3
            .byte $00, $30, $c0
            .byte $f0, $ff, $ff

MazeEntry:  .byte $f0, $ff, $0f
            .byte $00, $30, $00
            .byte $f0, $30, $ff
            .byte $00, $30, $c0
            .byte $f0, $f3, $c0
            .byte $00, $03, $c0
            .byte $f0, $ff, $cc

CastleDef:  .byte $f0, $fe, $15
            .byte $30, $03, $1f
            .byte $30, $03, $ff
            .byte $30, $00, $ff
            .byte $30, $00, $3f
            .byte $30, $00, $00
            .byte $f0, $ff, $0f

RedMaze1:   .byte $f0, $ff, $ff
            .byte $00, $00, $00
            .byte $f0, $ff, $0f
            .byte $00, $00, $0c
            .byte $f0, $ff, $0c
            .byte $f0, $03, $cc

RedMazeBottom:
            .byte $f0, $33, $cf       ;line shared with room above
            .byte $f0, $30, $00
            .byte $f0, $33, $ff
            .byte $00, $33, $00
            .byte $f0, $ff, $00
            .byte $00, $00, $00
            .byte $f0, $ff, $0f

RedMazeTop: .byte $f0, $ff, $ff
            .byte $00, $00, $c0
            .byte $f0, $ff, $cf
            .byte $00, $00, $cc
            .byte $f0, $33, $ff
            .byte $f0, $33, $00

WhiteCastleEntry:
            .byte $f0, $3f, $0c       ;line shared with room above
            .byte $f0, $00, $0c
            .byte $f0, $ff, $0f
            .byte $00, $30, $00
            .byte $f0, $30, $00
            .byte $00, $30, $00
            .byte $f0, $ff, $0f

TopEntryRoom:
            .byte $f0, $ff, $0f
            .byte $30, $00, $00
            .byte $30, $00, $00
            .byte $30, $00, $00
            .byte $30, $00, $00
            .byte $30, $00, $00
            .byte $f0, $ff, $ff

BlackMaze1: .byte $f0, $f0, $ff
            .byte $00, $00, $03
            .byte $f0, $ff, $03
            .byte $00, $00, $00
            .byte $30, $3f, $ff
            .byte $00, $30, $00

BlackMaze3: .byte $f0, $f0, $ff       ;line shared with room above; mirrored
            .byte $30, $00, $00
            .byte $30, $3f, $ff
            .byte $00, $30, $00
            .byte $f0, $f0, $ff
            .byte $30, $00, $03
            .byte $f0, $f0, $ff

BlackMaze2: .byte $f0, $ff, $ff
            .byte $00, $00, $c0
            .byte $f0, $ff, $cf
            .byte $00, $00, $0c
            .byte $f0, $0f, $ff
            .byte $00, $0f, $c0

BlackMazeEntry:
            .byte $30, $cf, $cc       ;line shared with room above; mirrored
            .byte $00, $c0, $cc
            .byte $f0, $ff, $0f
            .byte $00, $00, $00
            .byte $f0, $ff, $0f
            .byte $00, $00, $00
            .byte $f0, $ff, $0f

PortMacro ,info, states
SurroundMacro
BridgeMacro
KeyMacro
BlackBatMacro
DragonMacro ,1
SwordMacro ,1
DotMacro
EasterEgg
ChaliceMacro
NullMacro
NumberMacro
MagnetMacro

ObjectsMacro

RoomsMacro

; room differences for different levels (level 1, 2, 3)
RoomDiffs:  .byte $10, $0f, $0f     ;down from room 01
            .byte $05, $11, $11     ;down from room 02
            .byte $1d, $0a, $0a     ;down from room 03
            .byte $1c, $16, $16     ;U/L/R/D from room 1b (black castle room)
            .byte $1b, $0c, $0c     ;down from room 1c
            .byte $03, $0c, $0c     ;up from room 1d (top entry room)


            .segment "CODE0"

            .segment "VECTORS"
            .word START
            .word START
            .word START

            .segment "VECTORS0"
            .word START
            .word START
            .word START
