;
; Adventure 8K for the Atari 2600 - Mike Murphy (mike@emu7800.net)
; A homebrew hack of the 1979 classic Adventure by Warren Robinett.
;

.setcpu "6502"
.include "vcs.inc"

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
    leftdifficulty    = %01000000 ; 0=Amateur (B) 1=Pro (A)
    rightdifficulty   = %10000000 ; 0=Amateur (B) 1=Pro (A)
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
    normal  = 0
    dead    = 1
    ateman  = 2
    roaring = 255
.endenum

.enum PortCullisState
    open           = 1
    closed         = 28
    wraparound_max = 56
.endenum

.enum MoveTypes
    none  = 0
    up    = %00010000
    down  = %00100000
    left  = %01000000
    right = %10000000
.endenum

.struct RoomType
    gfx_ptr       .word
    color         .byte ; ColorType enum
    bw_color      .byte ; ColorType enum
    pf_control    .byte ; RoomControlType enum
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
    gfx_ptr       .word
.endstruct

.struct ObjectType
    dynamic_ptr   .word  ; pointer to a DynamicType
    currstate_ptr .word  ; pointer to a state byte
    states_ptr    .word  ; pointer to array of StateType
    color         .byte  ; ColorType enum
    bw_color      .byte  ; ColorType enum
    size          .byte
.endstruct


.zeropage   ; segment mapped to $80

roomgfx_base:                   .word 0
p0gfx_base:                     .word 0
p1gfx_base:                     .word 0
player0pos:                     .byte 0, 0
player1pos:                     .byte 0, 0
ManDynamic:                     .byte 0, 0, 0
PrevManDynamic:                 .byte 0, 0, 0
SurroundDynamic:                .byte 0, 0, 0
man_y2:                         .byte 0     ; man's adjusted y coordinate?
scan_line:                      .byte 0     ; current scan line
roomgfx_offset:                 .byte 0     ; room graphics offset
p0gfx_offset:                   .byte 0     ; player0 graphics offset
p1gfx_offset:                   .byte 0     ; player1 graphics offset
cached_swchb:                   .byte 0     ; cached console switches
cached_joystick:                .byte 0
joystick_record:                .byte 0     ; used by PickupPutdown
dr_ptr:                         .word 0     ; pointer for dereferencing
object1:                        .byte 0     ; cached object for display using player0 sprite
object2:                        .byte 0     ; cached object for display using player1 sprite
obj_collided_with:              .byte 0     ; object1 or object2 that collided with the man
portcullis_number:              .byte 0
direction_wanted:               .byte 0
obj_counter:                    .byte 0     ; last cached object for display
object_carried:                 .byte 0     ; object carried by the man
objman_x_delta:                 .byte 0
objman_y_delta:                 .byte 0
curr_dragon_objoffset:          .byte 0     ; current dragon being serviced

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

linked_objtable_ptr:            .word 0
linked_objtable_index:          .byte 0
objdelta:                       .byte 0     ; velocity for MoveGameObject to use
MoveGameObjectArg_ObjNumber:    .byte 0     ; identifies the object for MoveGameObject to move
MoveGameObjectArg_Difficulty:   .byte 0     ; difficulty for MoveGameObject to use
tmp1:                           .byte 0
GetObjectState_Arg:             .byte 0
NumberCurrState:                .byte 0     ; 0=lvl1, 2=lvl2, 4=lvl3
is_game_complete:               .byte 0     ; $ff=yes, 0=no
sound_duration_counter:         .byte 0
sound_type:                     .byte 0     ; NoiseType enum
input_counter:                  .word 0

stack_space:                    ; $e7-$ff (12 frames)

.segment "CODE0"
LeftOfName:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $ff, $ff   ; 11111111111111111111 11111111111111111111
 .byte $00, $00, $00   ; .................... ....................
 .byte $00, $00, $00   ; .................... ....................
 .byte $00, $00, $00   ; .................... ....................
 .byte $00, $00, $00   ; .................... ....................
 .byte $00, $00, $00   ; .................... ....................
 .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
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
 .byte $00, $0c, $0c   ; ........11....11.... ....11....11........
 .byte $f0, $0c, $3c   ; 1111....11....1111.. ..1111....11....1111
 .byte $f0, $0c, $00   ; 1111....11.......... ..........11....1111
 .byte $f0, $ff, $3f   ; 111111111111111111.. ..111111111111111111
 .byte $00, $30, $30   ; ......11........11.. ..11........11......
 .byte $f0, $33, $3f   ; 1111..11..11111111.. ..11111111..11..1111
 .assert >(*-1) = >(BlueMazeTop), error, "Sprite spans page."
BlueMazeLeft:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $ff, $ff   ; 11111111111111111111 11111111111111111111
 .byte $00, $00, $00   ; .................... ....................
 .byte $f0, $fc, $ff   ; 1111111111..11111111 11111111..1111111111
 .byte $f0, $00, $c0   ; 1111..............11 11..............1111
 .byte $f0, $3f, $cf   ; 1111..1111111111..11 11..1111111111..1111
 .byte $00, $30, $cc   ; ......11......11..11 11..11......11......
 .byte $f0, $f3, $cc   ; 11111111..11..11..11 11..11..111111111111
 .assert >(*-1) = >(BlueMazeLeft), error, "Sprite spans page."
BlueMazeBottom:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $f3, $0c   ; 11111111..11..11.... ....11..11..11111111
 .byte $00, $30, $0c   ; ......11......11.... ....11......11......
 .byte $f0, $3f, $0f   ; 1111..1111111111.... ....1111111111..1111
 .byte $f0, $00, $00   ; 1111................ ................1111
 .byte $f0, $f0, $00   ; 11111111............ ............11111111
 .byte $00, $30, $00   ; ......11............ ............11......
 .byte $f0, $ff, $ff   ; 11111111111111111111 11111111111111111111
 .assert >(*-1) = >(BlueMazeBottom), error, "Sprite spans page."
BlueMazeCenter:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $33, $3f   ; 1111..11..11111111.. ..11111111..11..1111
 .byte $00, $30, $3c   ; ......11......1111.. ..1111......11......
 .byte $f0, $ff, $3c   ; 111111111111..1111.. ..1111..111111111111
 .byte $00, $03, $3c   ; ..........11..1111.. ..1111..11..........
 .byte $f0, $33, $3c   ; 1111..11..11..1111.. ..1111..11..11..1111
 .byte $00, $33, $0c   ; ......11..11..11.... ....11..11..11......
 .byte $f0, $f3, $0c   ; 11111111..11..11.... ....11..11..11111111
 .assert >(*-1) = >(BlueMazeCenter), error, "Sprite spans page."
BlueMazeEntry:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $f3, $cc   ; 11111111..11..11..11 11..11..11..11111111
 .byte $00, $33, $0c   ; ......11..11..11.... ....11..11..11......
 .byte $f0, $33, $fc   ; 1111..11..11..111111 111111..11..11..1111
 .byte $00, $33, $00   ; ......11..11........ ........11..11......
 .byte $f0, $f3, $ff   ; 11111111..1111111111 1111111111..11111111
 .byte $00, $00, $00   ; .................... ....................
 .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
 .assert >(*-1) = >(BlueMazeEntry), error, "Sprite spans page."
MazeMiddle:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $ff, $cc   ; 111111111111..11..11 11..11..111111111111
 .byte $00, $00, $cc   ; ..............11..11 11..11..............
 .byte $f0, $03, $cf   ; 1111......111111..11 11..111111......1111
 .byte $00, $03, $00   ; ..........11........ ........11..........
 .byte $f0, $f3, $fc   ; 11111111..11..111111 111111..11..11111111
 .byte $00, $33, $0c   ; ......11..11..11.... ....11..11..11......
 .byte $f0, $33, $cc   ; 1111..11..11..11..11 11..11..11..11..1111
 .assert >(*-1) = >(MazeMiddle), error, "Sprite spans page."
MazeSide:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $33, $cc   ; 1111..11..11..11..11 11..11..11..11..1111
 .byte $00, $30, $cc   ; ......11......11..11 11..11......11......
 .byte $00, $3f, $cf   ; ......1111111111..11 11..111111111.......
 .byte $00, $00, $c0   ; ..................11 11..................
 .byte $00, $3f, $c3   ; ......11111111....11 11....1111111.......
 .byte $00, $30, $c0   ; ......11..........11 11.........11.......
 .byte $f0, $ff, $ff   ; 11111111111111111111 11111111111111111111
 .assert >(*-1) = >(MazeSide), error, "Sprite spans page."
 .res 4, 0 ; pad remainder of page
MazeEntry:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
 .byte $00, $30, $00   ; ......11............ ............11......
 .byte $f0, $30, $ff   ; 1111..11....11111111 11111111....11..1111
 .byte $00, $30, $c0   ; ......11..........11 11..........11......
 .byte $f0, $f3, $c0   ; 11111111..11......11 11......11..11111111
 .byte $00, $03, $c0   ; ..........11......11 11......11..........
 .byte $f0, $ff, $cc   ; 111111111111..11..11 11..11..111111111111
 .assert >(*-1) = >(MazeEntry), error, "Sprite spans page."
CastleDef:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $fe, $15   ; 11111111111.1.1.1... ...1.1.1.11111111111
 .byte $30, $03, $1f   ; 11........1111111... ...1111111........11
 .byte $30, $03, $ff   ; 11........1111111111 1111111111........11
 .byte $30, $00, $ff   ; 11..........11111111 11111111..........11
 .byte $30, $00, $3f   ; 11..........111111.. ..111111..........11
 .byte $30, $00, $00   ; 11.................. ..................11
 .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
 .assert >(*-1) = >(CastleDef), error, "Sprite spans page."
RedMazeTopLeft:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $ff, $ff   ; 11111111111111111111 11111111111111111111
 .byte $00, $00, $00   ; .................... ....................
 .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
 .byte $00, $00, $0c   ; ..............11.... ....11..............
 .byte $f0, $ff, $0c   ; 111111111111..11.... ....11..111111111111
 .byte $f0, $03, $cc   ; 1111......11..11..11 11..11..11......1111
 .byte $f0, $33, $cf   ; 1111..11..111111..11 11..111111..11..1111
 .assert >(*-1) = >(RedMazeTopLeft), error, "Sprite spans page."
RedMazeBottomLeft:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $33, $cf   ; 1111..11..11......11 11......11..11..1111
 .byte $f0, $30, $00   ; 1111..11............ ............11..1111
 .byte $f0, $33, $ff   ; 1111..11..1111111111 1111111111..11..1111
 .byte $00, $33, $00   ; ......11..11........ ........11..11......
 .byte $f0, $ff, $00   ; 111111111111........ ........111111111111
 .byte $00, $00, $00   ; .................... ....................
 .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
 .assert >(*-1) = >(RedMazeBottomLeft), error, "Sprite spans page."
RedMazeTopRight:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $ff, $ff   ; 11111111111111111111 11111111111111111111
 .byte $00, $00, $c0   ; ..................11 11..................
 .byte $f0, $ff, $cf   ; 1111111111111111..11 11..1111111111111111
 .byte $00, $00, $cc   ; ..............11..11 11..11..............
 .byte $f0, $33, $ff   ; 1111..11..1111111111 1111111111..11..1111
 .byte $f0, $33, $00   ; 1111..11..11.................11..11..1111
 .byte $f0, $3f, $0c   ; 1111..111111..11.... ....11..111111..1111
 .assert >(*-1) = >(RedMazeTopRight), error, "Sprite spans page."
WhiteCastleEntry:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $3f, $0c   ; 1111..111111..11.... ....11..111111..1111
 .byte $f0, $00, $0c   ; 1111..........11.... ....11..........1111
 .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
 .byte $00, $30, $00   ; ......11............ ............11......
 .byte $f0, $30, $00   ; 1111..11............ ............11..1111
 .byte $00, $30, $00   ; ......11............ ............11......
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
BlackMazeTopLeft:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $f0, $f0, $ff   ; 11111111....11111111 11111111....11111111
 .byte $00, $00, $03   ; ............11...... ......11............
 .byte $f0, $ff, $03   ; 11111111111111...... ......11111111111111
 .byte $00, $00, $00   ; .................... ....................
 .byte $30, $3f, $ff   ; 11....11111111111111 11111111111111....11
 .byte $00, $30, $00   ; ......11............ ............11......
 .byte $f0, $f0, $ff   ; 11111111....11111111 11111111....11111111
 .assert >(*-1) = >(BlackMazeTopLeft), error, "Sprite spans page."
BlackMazeBottomLeft:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF0hPF1-----PF2-----
 .byte $f0, $f0, $ff   ; 11111111....11111111 11111111....11111111
 .byte $30, $00, $00   ; 11.................. 11..................
 .byte $30, $3f, $ff   ; 11....11111111111111 11....11111111111111
 .byte $00, $30, $00   ; ......11............ ......11............
 .byte $f0, $f0, $ff   ; 11111111....11111111 11111111....11111111
 .byte $30, $00, $03   ; 11..........11...... 11..........11......
 .byte $f0, $f0, $ff   ; 11111111....11111111 11111111....11111111
 .assert >(*-1) = >(BlackMazeBottomLeft), error, "Sprite spans page."
BlackMazeTopRight:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF0hPF1-----PF2-----
 .byte $f0, $ff, $ff   ; 11111111111111111111 11111111111111111111
 .byte $00, $00, $c0   ; ..................11 ..................11
 .byte $f0, $ff, $cf   ; 1111111111111111..11 1111111111111111..11
 .byte $00, $00, $0c   ; ..............11.... ..............11....
 .byte $f0, $0f, $ff   ; 1111....111111111111 1111....111111111111
 .byte $00, $0f, $c0   ; ........1111......11 ........1111......11
 .byte $30, $cf, $cc   ; 11..11..1111..11..11 11..11..1111..11..11
 .assert >(*-1) = >(BlackMazeTopRight), error, "Sprite spans page."
BlackMazeEntry:
 ;     PF0  PF1  PF2     PF0hPF1-----PF2----- PF2-----PF1-----PF0h
 .byte $30, $cf, $cc   ; 11..11..1111..11..11 11..11..1111..11..11
 .byte $00, $c0, $cc   ; ....11........11..11 11..11........11....
 .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
 .byte $00, $00, $00   ; .................... ....................
 .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
 .byte $00, $00, $00   ; .................... ....................
 .byte $f0, $ff, $0f   ; 1111111111111111.... ....1111111111111111
 .assert >(*-1) = >(BlackMazeEntry), error, "Sprite spans page."
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
 .res 8, 0 ; pad remainder of page
SurroundGfx:
 .byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
 .byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
 .byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
 .byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
 .byte 0
 .assert >(*-1) = >(SurroundGfx), error, "Sprite spans page."
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
KeyGfx:
 .byte %00000111 ;      XXX
 .byte %11111101 ; XXXXXX X
 .byte %10100111 ; X X  XXX
 .byte 0
 .assert >(*-1) = >(KeyGfx), error, "Sprite spans page."
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
SwordLeftGfx:
 .byte %00100000 ;   X
 .byte %01000000 ;  X
 .byte %11111111 ; XXXXXXXX
 .byte %01000000 ;  X
 .byte %00100000 ;   X
 .byte 0
 .assert >(*-1) = >(SwordLeftGfx), error, "Sprite spans page."
SwordRightGfx:
 .byte %00000100 ;      X
 .byte %00000010 ;       X
 .byte %11111111 ; XXXXXXXX
 .byte %00000010 ;       X
 .byte %00000100 ;      X
 .byte 0
 .assert >(*-1) = >(SwordRightGfx), error, "Sprite spans page."
DotGfx:
 .byte %10000000 ; X
 .byte 0
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
 .res 2, 0 ; pad remainder of page
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

;; Render visible portion of screen
PrintDisplayR:
            sta HMCLR                 ;clear horizontal motion
            lda player0pos+PlayerPosType::xcoord
            ldx #SpriteType::object1
            jsr PosSpriteX
            lda player1pos+PlayerPosType::xcoord
            ldx #SpriteType::object2
            jsr PosSpriteX
            lda ManDynamic+DynamicType::xcoord
            ldx #SpriteType::man
            jsr PosSpriteX
            sta WSYNC                 ;wait for horizontal blank
            sta HMOVE                 ;apply horizontal motion
            sta CXCLR                 ;clear collision latches
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
            beq @PrintPlayer0

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

@PrintPlayer0:
            ldx #0
            lda scan_line
            sec                      ;have we reached the Object1's Y coordinate?
            sbc player0pos+PlayerPosType::ycoord
            bpl @PrintMan            ;if not then branch
            ldy p0gfx_offset         ;get Player0 definition index
            lda (p0gfx_base),y       ;get the next Player0 definition byte
            tax
            beq @PrintMan            ;if zero then definition finished
            inc p0gfx_offset         ;go to next Player0 definition byte

@PrintMan:  ldy #0                   ;disable Ball graphic
            lda scan_line
            sec                      ;have we reached the Man's
            sbc man_y2               ; Y coordinate?
            and #$fc                 ;mask value to four either side (getting depth of 8)
            bne @PrintRoom           ;if not, branch
            ldy #2                   ;enable Ball graphic

@PrintRoom: lda scan_line
            and #15                  ;have we reached a sixteenth scan line?
            bne @WaitForHorizBlank   ;if not, branch
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
@GotoNextScanline:
            dec scan_line
            lda scan_line
            cmp #8                   ;have we reached to within 8 scanlines of the bottom?
            bpl @PrintPlayer1        ;if not, branch

; Picture ends on line offset 229, next instruction starts at color clock 63
; ...cleanly end picture by waiting until end of scanline, losing about 50 CPU cycles
            sta WSYNC
            sta VBLANK               ;turn off beam
            jmp @PrintDone

; Print Player0 (Object1) and Ball (Man)
@WaitForHorizBlank:
            sta WSYNC                ;wait for horizontal blank
            sty ENABL                ;enable ball (if wanted)
            stx GRP0                 ;display Player0 definition byte (if wanted)
            jmp @GotoNextScanline

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

InitializeR:
            sei                   ;disable interrupts
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
            lda #13               ;position the thin walls (missiles)
            ldx #SpriteType::leftthinwall
            jsr PosSpriteX
            lda #150
            ldx #SpriteType::rightthinwall
            jsr PosSpriteX
            sta WSYNC             ;wait for horizontal blank
            sta HMOVE             ;apply the horizontal move
            rts

.segment "CODE1"
StartGame:
            jsr Initialize
           ;jsr SetupRoomObjects
            jmp StartGame

.segment "VECTORS0"
;PrintDisplay:
            sta Bank+0
            jsr PrintDisplayR
            sta Bank+1
            rts
;Initialize:
            sta Bank+0
            jsr InitializeR
            sta Bank+1
            rts
;Reset:
            sta Bank+1
            jmp StartGame
;Bank:
            .word 0
            .word Reset ; NMI
            .word Reset ; RESET
            .word Reset ; IRQ

.segment "VECTORS1"
PrintDisplay:
            sta Bank+0
            jsr PrintDisplayR
            sta Bank+1
            rts
Initialize:
            sta Bank+0
            jsr InitializeR
            sta Bank+1
            rts
Reset:
            sta Bank+1
            jmp StartGame
Bank:
            .word 0
            .word Reset ; NMI
            .word Reset ; RESET
            .word Reset ; IRQ
