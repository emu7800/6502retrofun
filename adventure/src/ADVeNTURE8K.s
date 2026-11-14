;
; Adventure 8K for the Atari 2600
; A homebrew hack of the original Adventure by Warren Robinett.
; Mike Murphy (mike@emu7800.net)
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
    roaring = $7f
.endenum

.enum SwordState
    left  = 0
    right = $ff
.endenum

.enum EasterEggState
    tos = 0
    tng = $ff
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


.zeropage

roomgfx_base:                   .word 0
roomgfx_offset:                 .byte 0
p0gfx_base:                     .word 0
p0gfx_offset:                   .byte 0
p1gfx_base:                     .word 0
p1gfx_offset:                   .byte 0
player0pos:                     .byte 0, 0
player1pos:                     .byte 0, 0
ManDynamic:                     .byte 0, 0, 0
PrevManDynamic:                 .byte 0, 0, 0
SurroundDynamic:                .byte 0, 0, 0
man_y2:                         .byte 0     ; man's adjusted y coordinate
scan_line:                      .byte 0     ; current scan line
cached_swchb:                   .byte 0     ; cached console switches
cached_joystick:                .byte 0     ; cached joystick switches
joystick_record:                .byte 0     ; used by PickupPutdown
direction_wanted:               .byte 0
dr_ptr:                         .word 0     ; pointer for dereferencing
object1:                        .byte 0     ; cached object for display using player0 sprite
object2:                        .byte 0     ; cached object for display using player1 sprite
obj_collided_with:              .byte 0     ; object1 or object2 that collided with the man
obj_counter:                    .byte 0     ; last cached object for display
object_carried:                 .byte 0     ; object carried by the man
objman_x_delta:                 .byte 0
objman_y_delta:                 .byte 0
curr_dragon_objoffset:          .byte 0     ; current dragon being serviced
portcullis_number:              .byte 0
linked_objtable_ptr:            .word 0
linked_objtable_index:          .byte 0
objdelta:                       .byte 0     ; velocity for MoveGameObject to use
MoveGameObjectArg_ObjNumber:    .byte 0     ; identifies the object for MoveGameObject to move
MoveGameObjectArg_Difficulty:   .byte 0     ; difficulty for MoveGameObject to use
GetObjectState_Arg:             .byte 0     ; used by GetObjectState to get actual state <= this value
NumberCurrState:                .byte 0     ; 0=lvl1, 1=lvl2, 2=lvl3
SwordCurrState:                 .byte 0     ; SwordState enum
EasterEggCurrState:             .byte 0     ; EasterEgg enum
is_game_complete:               .byte 0     ; $80=yes, $40=no/playing, $00=no/selecting
sound_duration_counter:         .byte 0
sound_type:                     .byte 0     ; NoiseType enum
input_counter:                  .word 0

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
BatDynamic:                     .byte 0, 0, 0, 0, 0, 0, 0
PortCurrStatesBase:             .byte 0, 0, 0

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
NullGfx:
 .byte 0
 .res 1, 0 ; pad remainder of page
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

;; Display initialization
InitializeDisplay_R:
            ldx #$28              ;clear TIA registers $04-$2c
            lda #0
:           sta 4,x
            dex
            bpl :-
            lda #13               ;position the thin walls (missiles)
            ldx #SpriteType::leftthinwall
            jsr PosSpriteX
            lda #150
            ldx #SpriteType::rightthinwall
            jsr PosSpriteX
            sta WSYNC             ;wait for horizontal blank
            sta HMOVE             ;apply the horizontal move
            rts

;; Render visible portion of screen
PrintDisplay_R:
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

;; Handle vertical sync
DoVSYNC_R:

; Spin until middle of line offset 255 (64t timer previously set to 32, 26.9 lines)
            lda INTIM           ;get timer output
            bne DoVSYNC_R       ;wait for time-out

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

.segment "CODE1"
StartGame:
            sei                 ;disable interrupts
            cld
            ldx #$ff
            txs                 ;reset stack
:           sta 0,x             ;clear $80 to $ff user vars
            dex
            bmi :-
            jsr InitializeDisplay
            jsr SetupRoomObjects

;; Top of game loop
MainGameLoop:
            jsr CheckGameStart
            jsr MakeSound
            jsr MaintainInputCounter
            lda is_game_complete
            bmi NonActiveLoop     ;branch if complete
            beq NonActiveLoop     ;branch if selecting
            lda ChaliceDynamic+DynamicType::room
            cmp #roomnum_YellowCastleEntry
            bne :+                ;branch if chalice not in the yellow castle

@GameCompleted:
            lda #$ff
            sta sound_duration_counter
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

NonActiveLoop:
            jsr DoVSYNC           ;wait for VSYNC
            jsr PrintDisplay      ;display the room and objects
            jsr SetupRoomPrint    ;set up room and objects for display
            jmp MainGameLoop

;; Check console switches if game should be started
CheckGameStart:
            lda SWCHB             ;get the console switches
            eor #$ff              ;flip (as reset active low)
            and cached_swchb      ;compare with what was before
            and #ConsoleSwitchType::reset
            beq @CheckSelect      ;if no reset then branch
            lda is_game_complete
            bmi SetupRoomObjects  ;branch since game has been completed

@Reincarnate:
            lda #roomnum_YellowCastle
            sta ManDynamic+DynamicType::room            ;make it the current room
            sta PrevManDynamic+DynamicType::room        ;make it the previous room
            lda #80
            sta ManDynamic+DynamicType::xcoord          ;make it the current man X coordinate
            sta PrevManDynamic+DynamicType::xcoord      ;make it the previous man X coordinate
            lda #32
            sta ManDynamic+DynamicType::ycoord          ;make it the current man Y coordinate
            sta PrevManDynamic+DynamicType::ycoord      ;make it the previous man Y coordinate
            lda #0
            sta RedDragonDynamic+DynamicType::state     ;set the red dragon's state to OK
            sta YellowDragonDynamic+DynamicType::state  ;set the yellow dragon's state to OK
            sta GreenDragonDynamic+DynamicType::state   ;set the green dragon's state to OK
            sta sound_duration_counter                  ;set the note count to zero
            lda #objoffset_Null
            sta object_carried
            lda #$40
            sta is_game_complete

@CheckSelect:
            lda SWCHB                         ;get the console switches
            eor #$ff                          ;flip (as select is active low)
            and cached_swchb                  ;compare with what was before
            and #ConsoleSwitchType::select
            beq SaveConSwitchesAndExit        ;branch if select not being used
            lda ManDynamic+DynamicType::room  ;get the current room
            cmp #roomnum_NumberRoom
            bne SetupRoomObjects              ;branch if not
            inc NumberCurrState
            lda NumberCurrState
            cmp #3                            ;have we reached the maximum?
            bcc SetupRoomObjects
            lda #0                            ;if yep then set back to zero
            sta NumberCurrState               ;store the new level number

SetupRoomObjects:
            lda #roomnum_NumberRoom
            sta ManDynamic+DynamicType::room
            sta PrevManDynamic+DynamicType::room
            lda #0                            ;set man ycoord to 0 so can't be seen
            sta ManDynamic+DynamicType::ycoord
            sta PrevManDynamic+DynamicType::ycoord
            lda NumberCurrState               ;get the level number
            asl a
            tay
            lda GameObjectLocations,y         ;get the low pointer to object locations
            sta dr_ptr
            lda GameObjectLocations+1,y       ;get the high pointer to object locations
            sta dr_ptr+1

@CopyToGameObjectsWorkingArea:
            ldy #Game1ObjectLocationsEnd - Game1ObjectLocations - 1
:           lda (dr_ptr),y
            sta GameObjectsWorkingArea,y
            dey
            bpl :-

            lda NumberCurrState               ;get the level number
            cmp #2
            bcc :+                            ;branch if level one or two (where all objects are in defined areas)
            jsr RandomizeLevel3               ;put some objects in random rooms
            jsr DoVSYNC                       ;wait for VSYNC
            jsr PrintDisplay                  ;display rooms and objects
:           lda #0                            ;signal that the game has started
            sta is_game_complete
            lda #objoffset_Null
            sta object_carried
SaveConSwitchesAndExit:
            lda SWCHB                         ;store the current console switches
            sta cached_swchb
            rts

; put objects in random rooms for level 3
RandomizeLevel3:
            ldy #Level3ObjectsToRandomizeEnd-Level3ObjectsToRandomize-1
@GetRandomRoom:
            ldx Level3ObjectsToRandomize,y  ;get object to randomize

            lda input_counter               ;get the low input counter as seed
            lsr a                           ;generate a pseudo-random room number
            lsr a
            lsr a
            lsr a
            lsr a
            sec
            adc input_counter               ;store the low input counter
            sta input_counter
            and #$1f                        ;trim so represents a room value

            ;Exclude everything from NumberRoom, SecretRoom
            cmp #roomnum_SecretRoom
            bcc @GetRandomRoom
            beq @GetRandomRoom
            ;Exclude BlackKey from Black* rooms
            cpx #BlackKeyDynamic
            bne :+
            cmp #roomnum_BlackMazeTopLeft
            bcc @RandomRoomOk
            cmp #roomnum_BlackCastleEntry
            bcc @GetRandomRoom
            beq @GetRandomRoom
            ;Exclude WhiteKey from RedMaze*, WhiteCastleEntry rooms
:           cpx #WhiteKeyDynamic
            bne :+
            cmp #roomnum_RedMazeTopLeft
            bcs @GetRandomRoom
            ;Limit to Black*, RedMaze*, WhiteCastleEntry, OtherPurpleRoom, TopEntryRoom* rooms
:           cpx #ChaliceDynamic
            bne @RandomRoomOk
            cmp #roomnum_BlackMazeTopLeft
            bcc @GetRandomRoom

@RandomRoomOk:
            sta DynamicType::room,x         ;store the new room value
            dey
            bpl @GetRandomRoom              ;goto the next object until all done
            rts

;; Set up a room for print
SetupRoomPrint:
            lda ManDynamic+DynamicType::room
            jsr RoomNumToAddress      ;convert to room address in dr_ptr
            ldy #RoomType::gfx_ptr
            lda (dr_ptr),y
            sta roomgfx_base
            iny
            lda (dr_ptr),y
            sta roomgfx_base+1

            lda SWCHB                 ;get console switches
            and #ConsoleSwitchType::bw
            beq :+
            ldy #RoomType::color
            lda (dr_ptr),y
            jsr ChangeColorIfNeeded
            sta COLUPF                ;set playfield color
            jmp :++
:           ldy #RoomType::bw_color
            lda (dr_ptr),y
            jsr ChangeColorIfNeeded
            sta COLUPF                ;set playfield color

:           lda #ColorType::lightgray
            jsr ChangeColorIfNeeded
            sta COLUBK                ;set background color

            ldy #RoomType::pf_control
            lda (dr_ptr),y
            sta CTRLPF                ;set playfield control
            and #%11000000
            lsr a
            lsr a
            lsr a
            lsr a
            lsr a
            sta ENAM1                 ;enable right hand thin wall (if wanted - Missile1)
            lsr a
            sta ENAM0                 ;enable left hand thin wall (if wanted - Missile0)

            jsr CacheObjects          ;get next two objects to display

            lda object1
            cmp #objoffset_InvisibleSurround
            beq SwapPrintObjects      ;swap to move InvisibleSurround to object2/Player1
            cmp #objoffset_Bridge
            bne SetupObjectPrint      ;carry on if not Bridge in object1/Player0
            lda object2
            cmp #objoffset_InvisibleSurround
            beq SetupObjectPrint      ;InvisibleSurround in object2/Player1 OK, else swap to move Bridge to object2/Player1

SwapPrintObjects:
            lda object1
            pha
            lda object2
            sta object1
            pla
            sta object2

SetupObjectPrint:
; set up Object1 to print
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
            jsr GetObjectState    ;find current state, put in y
            iny                   ;index to the state's corresponding graphic pointer
            lda (dr_ptr),y        ;get Object1's low graphic address
            sta p0gfx_base        ; and store for print
            iny
            lda (dr_ptr),y        ;get Object1's high graphic address
            sta p0gfx_base+1      ; and store for print

            lda SWCHB             ;get console switches
            and #ConsoleSwitchType::bw
            beq :+
            lda Objects+ObjectType::color,x
            jsr ChangeColorIfNeeded
            sta COLUP0            ;set player0 color
            jmp :++
:           lda Objects+ObjectType::bw_color,x
            jsr ChangeColorIfNeeded
            sta COLUP0            ;set player0 color

:           lda Objects+ObjectType::size,x
            ora #%00010000        ;and set to larger size if necessary
            sta NUSIZ0            ;used by bridge and invisible surround

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
            jsr GetObjectState    ;find current state, put in y
            iny                   ;index to the state's corresponding graphic pointer
            lda (dr_ptr),y
            sta p1gfx_base        ;get Object2's low graphic address
            iny
            lda (dr_ptr),y        ;get Object2's high graphic address
            sta p1gfx_base+1

            lda SWCHB             ;get console switches
            and #ConsoleSwitchType::bw
            beq :+
            lda Objects+ObjectType::color,x
            jsr ChangeColorIfNeeded
            sta COLUP1            ;set player1 color
            jmp :++
:           lda Objects+ObjectType::bw_color,x
            jsr ChangeColorIfNeeded
            sta COLUP1            ;set player1 color

:           lda Objects+ObjectType::size,x
            ora #%00010000        ;and set to larger size if necessary
            sta NUSIZ1            ;used by bridge and invisible surround
            rts

; fill cache with two objects in this room
CacheObjects:
            ldy obj_counter                   ;get last object
            lda #objoffset_Null
            sta object1
            sta object2
@MoveNextObject:
            tya
            clc                               ;goto the next object to check
            adc #.sizeof(ObjectType)
            cmp #objoffset_Null
            bcc :+
            lda #0                            ;wrap around
:           tay
            lda Objects+ObjectType::dynamic_ptr,y
            sta dr_ptr
            lda Objects+ObjectType::dynamic_ptr+1,y
            sta dr_ptr+1
            ldx #DynamicType::room
            lda (dr_ptr,x)
            cmp ManDynamic+DynamicType::room  ;is object in this room?
            bne @CheckForMoreObjects          ;if not lets try next object (branch)
            lda object1                       ;check first slot
            cmp #objoffset_Null
            bne :+
            sty object1                       ;store this object's number to print
            jmp @CheckForMoreObjects          ; and try for more
:           sty object2                       ;store this object's number to print
            jmp @StoreCount                   ; and then give up - no slots free

@CheckForMoreObjects:
            cpy obj_counter                   ;have we done all the objects?
            bne @MoveNextObject               ;if not, continue
@StoreCount:
            sty obj_counter                   ;if so, store current count
            rts                               ; for next time

; Get room address from room number
; input: a=room number
; returns: dr_ptr set to room address
RoomNumToAddress:
            .assert .sizeof(RoomType) = 9, error, "This subroutine expects RoomType to be 9 bytes long."
            pha                   ;store room number wanted
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
            pla                   ;get the original room number
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
; input: dr_ptr, GetObjectState_Arg
; returns: offset in y
GetObjectState:
            ldy #0
            lda GetObjectState_Arg
@Next:      cmp (dr_ptr),y        ;have we found it in the list of states?
            bcc @Done             ;if nearing it then found it and return
            beq @Done             ;if found it then return
            .assert .sizeof(StateType) = 3, error, "This subroutine expects StateType to be 3 bytes long."
            iny                   ;goto next state in list of states
            iny
            iny
            bne @Next
@Done:      rts

; Change color if needed
; input: a=color
; returns: a=potentially updated color (flash, inactive)
ChangeColorIfNeeded:
            .assert (ColorType::flash & 2) = 2, error, "Bad ColorType::flash value."
            lsr a                        ;if bit 0 of the color is set
            bcc @CheckRecentMovement     ; branch if clear, no flash
            lda input_counter            ;flash

@CheckRecentMovement:
            ldy input_counter+1          ;get the high input counter
            bpl @Done                    ;if console/joystick moved recently then branch
            eor input_counter+1          ;vary colors after a period of inactivty to limit CRT burn in
            and #%11111011               ; turn down the luminance
@Done:      asl a                        ; and restore original color if necessary
            rts

;; Maintain input_counter, clearing high byte when input has been detected (captures randomness)
MaintainInputCounter:
            inc input_counter
            bne @NoWrap
            inc input_counter+1
            bne @NoWrap
            lda #$80                ;wrap the high input_counter (indicating timeout) if needed
            sta input_counter+1
@NoWrap:    lda SWCHA               ;get joystick values
            cmp #<~MoveTypes::none  ;if any movement then branch
            bne @JoystickUsed
            lda SWCHB               ;get the console switches
            and #ConsoleSwitchType::select_and_reset
            cmp #ConsoleSwitchType::select_and_reset ;have either of them been used?
            beq @Done               ;if no usage then return
@JoystickUsed:
            lda #0                  ;zero the high input_counter if the
            sta input_counter+1     ; switches or joystick have been used
@Done:      rts

; load dr_ptr with address of object's dynamic info
; input: x=object number (which is an offset from Objects)
; returns: dr_ptr with dynamic info address
GetObjectDynamicInfoAddress:
            lda Objects+ObjectType::dynamic_ptr,x
            sta dr_ptr            ;get and store the low address
            lda Objects+ObjectType::dynamic_ptr+1,x
            sta dr_ptr+1          ;get and store the high address
            rts

;; Check ball (man) collisions and move ball
;  input:
;    y=0 allow joystick read all movement
;    y=1 disallow joystick read - move vertically only
;    y=2 disallow joystick read/bridge check - move horizontally only
BallMovement:
            lda CXBLPF            ;bl-pf collision
            and #%10000000        ;get bl-pf collision (man v. wall)
            bne @ManCollision     ; branch if collision
            lda CXM0FB            ;m0-pf, m0-bl collision
            and #%01000000        ;get m0-bl collision (man v. left thin wall)
            bne @ManCollision     ; branch if collision
            lda CXM1FB            ;m1-pf, m1-bl collision
            and #%01000000        ;get m1-bl collision (man v. right thin wall)
            beq :+                ; branch if no collision
            lda object2           ;if Object2 to print is
            cmp #objoffset_Dot    ; then ignore man colliding w/right thin wall
            bne @ManCollision     ; branch if collision
:           lda CXP0FB            ;p0-pf, p0-bl collision
            and #%01000000        ;get p0-bl collision (p0 v. man)
            beq :+                ; branch if no collision
            lda object1           ;if Object1 to print is
            cmp #objoffset_InvisibleSurround  ; then ignore man colliding w/surround
            bne @ManCollision     ; branch if collision (p0-man)
:           lda CXP1FB            ;p1-pf, p1-bl collision
            and #%01000000        ;get p1-bl collision (p1 v. man)
            beq @NoManCollision   ; branch if no collision
            lda object2           ;if Object2 to print is
            cmp #objoffset_InvisibleSurround  ; then ignore man colliding w/surround
            beq @NoManCollision
@ManCollision:
            cpy #2                ;are we checking for the bridge?
            bne @ReadStick        ; branch if not
            lda object_carried
            cmp #objoffset_Bridge
            beq @ReadStick
            lda ManDynamic+DynamicType::room
            cmp BridgeDynamic+DynamicType::room  ;is the bridge in this room?
            bne @ReadStick                       ; branch if not
            lda ManDynamic+DynamicType::xcoord
            sec
            sbc BridgeDynamic+DynamicType::xcoord
            cmp #10               ;if < 10 or > 23 then forget it
            bcc @ReadStick
            cmp #23
            bcs @ReadStick
            lda z:BridgeDynamic+DynamicType::ycoord
            sec
            sbc ManDynamic+DynamicType::ycoord
            cmp #252
            bcs @NoManCollision   ;if < -4 then going through bridge
            cmp #25               ;if > 25 then forget it
            bcs @ReadStick
@NoManCollision:
            lda #<~MoveTypes::none ;reset the joystick input
            sta cached_joystick
            lda ManDynamic+DynamicType::room
            sta PrevManDynamic+DynamicType::room
            lda ManDynamic+DynamicType::xcoord
            sta PrevManDynamic+DynamicType::xcoord
            lda ManDynamic+DynamicType::ycoord
            sta PrevManDynamic+DynamicType::ycoord
@ReadStick: cpy #0                ;allow joystick read - all movement
            bne :+                ;if not, don't bother with joystick read
            lda SWCHA             ;read joysticks
            sta cached_joystick
:           lda PrevManDynamic+DynamicType::room
            sta ManDynamic+DynamicType::room
            lda PrevManDynamic+DynamicType::xcoord
            sta ManDynamic+DynamicType::xcoord
            lda PrevManDynamic+DynamicType::ycoord
            sta ManDynamic+DynamicType::ycoord
            lda cached_joystick        ;get the joystick position@
            ora JoystickMergeValues,y  ;merge out movement not allowed in this phase
            sta direction_wanted       ;and store cooked movement
            ldy #3                     ;set the delta for the man
            ldx #ManDynamic            ;point to man's coordinates
            jmp MoveGroundObject

;; Deal with object pickup and putdown
PickupPutdown:
            rol INPT4             ;get joystick trigger
            ror joystick_record   ;merge into joystick record
            lda joystick_record   ;get joystick record
            and #%11000000        ;merge out previous presses
            cmp #%01000000        ;was it previously pressed?
            bne :+                ;if not branch
            lda #objoffset_Null
            cmp object_carried
            beq :+                ;branch if nothing is carried
            sta object_carried    ;drop object
            lda #NoiseType::drop_item
            sta sound_type
            lda #4
            sta sound_duration_counter
:           lda CXP0FB            ;p0-pf, p0-bl collision
            and #%01000000        ;get p0-bl collision
            beq :+                ;branch if no collision
            lda object1           ;get type of Player0
            sta obj_collided_with
            jmp CollisionDetected ;deal with collision
:           lda CXP1FB            ;p1-pf, p1-bl collision
            and #%01000000        ;get p1-bl collision
            beq @Done
            lda object2           ;get type of Player1
            sta obj_collided_with
            bne CollisionDetected ;deal with collision
@Done:      rts

CollisionDetected:
            ldx obj_collided_with
            jsr GetObjectDynamicInfoAddress   ;loads dr_ptr
            lda obj_collided_with
            cmp #objoffset_StartOfCarriables  ;is it carriable?
            bcc @Done                         ;not carriable, exit
            ldy #DynamicType::room
            lda (dr_ptr),y                    ;get the object's room
            cmp ManDynamic+DynamicType::room  ;compare w/man's room
            bne @Done                         ; if not same room, exit
            lda obj_collided_with
            cmp object_carried
            beq @PickupObject
            lda #NoiseType::get_item
            sta sound_type
            lda #4
            sta sound_duration_counter
@PickupObject:
            lda obj_collided_with             ;set the object as being carried
            sta object_carried
            ldx dr_ptr                        ;object to move
            ldy #6                            ;move 6 steps in the direction specified
            lda cached_joystick               ; by joystick
            jsr MoveObjectDelta
            ldy #DynamicType::xcoord
            lda (dr_ptr),y                    ;get the object's X coordinate
            sec
            sbc ManDynamic+DynamicType::xcoord
            sta objman_x_delta                ; and store the difference wrt man's X coordinate
            ldy #DynamicType::ycoord
            lda (dr_ptr),y                    ;get the object's Y coordinate
            sec
            sbc ManDynamic+DynamicType::ycoord
            sta objman_y_delta                ; and store the difference wrt man's Y coordinate

@FlipSwordAsNeeded:
            lda object_carried
            cmp #objoffset_Sword
            bne @Done
            lda objman_x_delta
            beq @Done
            and #$80
            tay                               ;0: sword is located to the right, ~0: sword is located to the left
            lda #SwordState::right
            cpy #0
            beq :+
            lda #SwordState::left
:           sta SwordCurrState

@Done:      rts

;; Move the carried object
MoveCarriedObject:
            ldx object_carried
            cpx #objoffset_Null
            beq :+
            jsr GetObjectDynamicInfoAddress   ;loads dr_ptr
            ldy #DynamicType::room
            lda ManDynamic+DynamicType::room
            sta (dr_ptr),y                    ;store the object's current room
            ldy #DynamicType::xcoord
            lda ManDynamic+DynamicType::xcoord
            clc
            adc objman_x_delta                ;add the X difference
            sta (dr_ptr),y                    ; and store as the object's X coordinate
            ldy #DynamicType::ycoord
            lda ManDynamic+DynamicType::ycoord
            clc
            adc objman_y_delta                ;add the Y difference
            sta (dr_ptr),y                    ; and store as the object's Y coordinate
            ldy #0                            ;set no delta
            lda #<~MoveTypes::none            ;set no movement
            ldx dr_ptr                        ;get the object's dynamic address
            jsr MoveGroundObject
:           rts

; Move the object in direction by delta
; Move to next room if needed
; input: a=MoveTypes/direction, x=object to move, y=move delta
MoveGroundObject:
            jsr MoveObjectDelta               ;move the object by delta
            ldy #2                            ;set to do the three
@HandlePortal:
            sty portcullis_number
            lda PortCurrStatesBase,y
            cmp #PortCullisState::closed
            beq @NextPortal                   ; next port if closed
; deal with object moving out of a castle
            ldy portcullis_number
            lda DynamicType::room,x
            cmp EntryRoomOffsets,y            ;is it in a castle entry room?
            bne @NextPortal                   ; next port if not
            lda DynamicType::ycoord,x
            cmp #13                           ;at the bottom? (is y < 13)
            bpl @NextPortal                   ; next port if not
            lda CastleRoomOffsets,y
            sta DynamicType::room,x           ;put the object in the castle room
            lda #80
            sta DynamicType::xcoord,x
            lda #44
            sta DynamicType::ycoord,x
            lda #PortCullisState::open
            sta PortCurrStatesBase,y
            rts
@NextPortal:
            ldy portcullis_number
            dey
            bpl @HandlePortal

@DealWithUp:
            lda DynamicType::ycoord,x
            cmp #106                          ;has it reached above the top? (is y >= 106)
            bmi @DealWithLeft                 ; if not, branch
            lda #13                           ;set new Y coordinate to bottom
            sta DynamicType::ycoord,x
            ldy #RoomType::room_up
            jmp @GetNewRoom

@DealWithLeft:
            lda DynamicType::xcoord,x
            cpx #ManDynamic                   ;are we dealing with the man?
            bne @ChkLeft                      ; branch if not

@ChkLeft2:  cmp #3                            ;is x < 3?
            bcc :+
            cmp #240                          ;is x >= 240
            bcs :+
            bcc @DealWithDown

:           lda DynamicType::room,x           ;the man's room is right of secret room?
            cmp #roomnum_BelowYellowCastleLeftThinWall
            bne @GoLeft                       ; branch if not
            lda DotDynamic+DynamicType::room  ;check the room of the dot
            cmp #roomnum_BlackMazeBottomLeft  ;is it in the hidden room area?
            beq @GoLeft                       ; if so, branch
            lda #roomnum_SecretRoom
            sta DynamicType::room,x           ;change to secret room
            lda #158                          ;set the X coordinate
            sta DynamicType::xcoord,x
            lda #EasterEggState::tng
            sta EasterEggCurrState
            bne @MovementReturn

@ChkLeft:   cmp #3                            ;is x < 3
            bcc @GoLeft                       ;if so, go left
            cmp #240                          ;is x >= 240
            bcs @GoLeft                       ;if so, go left
            bcc @DealWithDown

@GoLeft:    cpx #ManDynamic                   ;are we dealing with the man?
            beq :+                            ;if so, branch
            lda #154                          ;set new X coordinate for everyone other than the man
            bne :++
:           lda #158                          ;set new X coordinate for the man
:           sta DynamicType::xcoord,x
            ldy #RoomType::room_left
            jmp @GetNewRoom

@DealWithDown:
            lda DynamicType::ycoord,x
            cmp #13                           ;is y < 13?
            bcs @DealWithRight
            lda #105                          ;set new Y coordinate
            sta DynamicType::ycoord,x
            ldy #RoomType::room_down
            jmp @GetNewRoom

@DealWithRight:
            lda DynamicType::xcoord,x
            cpx #ManDynamic                   ;are we dealing with the man?
            bne @ChkRight                     ; branch if not
            cmp #159                          ;is x >= 159?
            bcc @MovementReturn               ; branch if not

            lda DynamicType::room,x           ;the man's room
            cmp #roomnum_BelowYellowCastleRightThinWall  ;is left of secret room?
            bne @GoRight                      ; branch if not
            lda DotDynamic+DynamicType::room  ;check the room of the dot
            cmp #roomnum_BlackMazeBottomLeft  ;is it in the hidden room area?
            beq @GoRight                      ; if so, branch
            lda #roomnum_SecretRoom
            sta DynamicType::room,x           ;change to secret room
            lda #3                            ;set the X coordinate
            sta DynamicType::xcoord,x
            lda #EasterEggState::tos
            sta EasterEggCurrState
            bne @MovementReturn

@ChkRight:  cmp #155                          ;is x >= 155
            bcc @MovementReturn               ; branch if not, no room change
@GoRight:   lda #3                            ;set new X coordinate
            sta DynamicType::xcoord,x
            ldy #RoomType::room_right
@GetNewRoom:
            lda DynamicType::room,x
            jsr RoomNumToAddress              ;convert to room address in dr_ptr
            lda (dr_ptr),y                    ;get the adjacent room
            jsr AdjustRoomLevel               ;deal with the level differences
            sta DynamicType::room,x           ; and store as new object's room
@MovementReturn:
            rts

; Move the object in direction by delta
; input: a=MoveTypes, x=object to move, y=delta
MoveObjectDelta:
            sta direction_wanted
@MoveObjectOneStep:
            dey                     ;count down the delta
            bmi @MoveObjectDone
            lda direction_wanted
            and #MoveTypes::right
            bne :+                  ;if no move right then branch
            inc DynamicType::xcoord,x
:           lda direction_wanted
            and #MoveTypes::left
            bne :+                  ;if no move left then branch
            dec DynamicType::xcoord,x
:           lda direction_wanted
            and #MoveTypes::up
            bne :+                  ;if no move up then branch
            inc DynamicType::ycoord,x
:           lda direction_wanted
            and #MoveTypes::down
            bne :+                  ;if no move down then branch
            dec DynamicType::ycoord,x
:           jmp @MoveObjectOneStep  ;keep going until delta finished
@MoveObjectDone:
            rts

; Adjust room for different levels
; input: a=original room
; returns: a=possibly different room
AdjustRoomLevel:
            cmp #%10000000          ;does room number have
            bcc @NoChange           ; the hi bit set?
            and #%01111111          ;remove the hi bit and
            clc
            adc NumberCurrState     ;room number + level
            tay
            lda RoomDiffs,y         ;use as an offset to get the next room
@NoChange:  rts

; Determine whether a player sprite is colliding with ball (The Man)
; input: a=object number
; returns: a=0 if no collision, a<>0 if collision
PBCollision:
            cmp object1             ;is it the first object?
            beq @P0                 ; branch if yes
            cmp object2             ;is it the second object?
            beq @P1                 ; branch if yes
            lda #0                  ;otherwise nothing
            rts
@P0:        lda CXP0FB              ;p0-pf, p0-bl collision
            and #%01000000          ;get p0-bl collision
            rts
@P1:        lda CXP1FB              ;p1-pf, p1-bl collision
            and #%01000000          ;get p1-bl collision
            rts

; Find which object has hit object wanted
; input: x=object number
; returns: hit object number in a
FindObjHit: lda CXPPMM              ;p0-p1, m0-m1 collision
            and #%10000000          ;get p0-p1 collision
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

; Move object (Dragon or Bat)
; input:
;    linked_objtable_ptr
;    MoveGameObjectArg_Difficulty
;    MoveGameObjectArg_ObjNumber
;    objdelta
; returns:
;    linked_objtable_index
;    direction_wanted
MoveGameObject:
            jsr GetLinkedObject     ;get linked object and direction wanted
            ldx MoveGameObjectArg_ObjNumber
            lda direction_wanted
            bne :+                  ;if movement then branch
            lda DynamicType::move,x ;use old movement
:           sta DynamicType::move,x ;store the new movement
            ldy objdelta
            jmp MoveGroundObject

; Get linked object and direction wanted
; input:
;    linked_objtable_ptr
;    MoveGameObjectArg_Difficulty
; returns:
;    linked_objtable_index
;    direction_wanted
GetLinkedObject:
            lda #0
            sta linked_objtable_index
:           ldy linked_objtable_index
            lda (linked_objtable_ptr),y
            tax                               ;x is Object1
            iny
            lda (linked_objtable_ptr),y
            tay                               ;y is Object2
            lda z:DynamicType::room,x         ;compare Object1's room
            cmp DynamicType::room,y           ; w/Object2's room
            bne :+                            ;if not the same room then branch
            cpy MoveGameObjectArg_Difficulty  ;have we matched Object2 for difficulty?
            beq :+                            ; branch if yes
            cpx MoveGameObjectArg_Difficulty  ;have we matched Object1 for difficulty?
            beq :+                            ; branch if yes
            bne @DetermineDirectionWanted
:           inc linked_objtable_index
            inc linked_objtable_index
            ldy linked_objtable_index
            lda (linked_objtable_ptr),y  ;check for end of sequence
            bne :--                      ; loop around if not
            lda #MoveTypes::none
            sta direction_wanted
            rts
@DetermineDirectionWanted:
            lda #<~MoveTypes::none
            sta direction_wanted
            lda DynamicType::room,y      ;compare Object2's room
            cmp z:DynamicType::room,x    ; w/ Object1's room
            bne @Done                    ;if not the same, forget it
            lda DynamicType::xcoord,y    ;compare Object2's X coordinate
            cmp z:DynamicType::xcoord,x  ; w/ Object1's X coordinate
            bcc @SetLeft                 ;if Object2 X < Object1 X then branch
            beq @CmpY                    ;if Object2 X = Object1 X then branch
            lda direction_wanted
            and #<~MoveTypes::right      ;move Object1 right
            sta direction_wanted
            jmp @CmpY
@SetLeft:   lda direction_wanted
            and #<~MoveTypes::left       ;move Object1 left
            sta direction_wanted
@CmpY:      lda DynamicType::ycoord,y    ;compare Object2's Y coordinate
            cmp z:DynamicType::ycoord,x  ; w/ Object1's Y coordinate
            bcc @SetDown                 ;if Object2 Y < Object1 Y then branch
            beq @Done                    ;if Object2 Y = Object1 Y then branch
            lda direction_wanted
            and #<~MoveTypes::up         ;move Object1 up
            sta direction_wanted
            jmp @Done
@SetDown:   lda direction_wanted
            and #<~MoveTypes::down       ;move Object1 down
            sta direction_wanted
@Done:      lda direction_wanted
            rts

;; Move the red dragon "Rhindle"
MoveRedDragon:
            lda #<RedDragonLinkedObjectTable
            sta linked_objtable_ptr
            lda #>RedDragonLinkedObjectTable
            sta linked_objtable_ptr+1
            lda #3
            sta objdelta
            ldx #objoffset_DragonRhindle
            jmp MoveDragon

;; Move the yellow dragon "Yorgle"
MoveYellowDragon:
            lda #<YellowDragLinkedObjectTable
            sta linked_objtable_ptr
            lda #>YellowDragLinkedObjectTable
            sta linked_objtable_ptr+1
            lda #2
            sta objdelta
            ldx #objoffset_DragonYorgle
            jmp MoveDragon

;; Move the green dragon "Grundle"
MoveGreenDragon:
            lda #<GreenDragonLinkedObjectTable
            sta linked_objtable_ptr
            lda #>GreenDragonLinkedObjectTable
            sta linked_objtable_ptr+1
            lda #2
            sta objdelta
            ldx #objoffset_DragonGrundle
            jmp MoveDragon

; Move a dragon
; input:
; x                   = dragon object (objoffset_DragonRhindle, objoffset_DragonYorgle, objoffset_DragonGrundle)
; linked_objtable_ptr = dragon linked object table
; objdelta            = velocity
MoveDragon: stx curr_dragon_objoffset
            lda Objects+ObjectType::dynamic_ptr,x
            tax
            lda z:DynamicType::state,x
            and #$7f
            cmp #DragonState::normal
            bne @DragonStateNotNormal    ;branch if not normal
@DragonStateNormal:
            lda SWCHB                    ;read console switches
            and #ConsoleSwitchType::rightdifficulty
            beq :+                       ;if Amateur (B) branch
            lda #0                       ;set hard - ignore nothing
            beq :++
:           lda #SwordDynamic            ;set easy - ignore sword
:           sta MoveGameObjectArg_Difficulty
            stx MoveGameObjectArg_ObjNumber
            jsr MoveGameObject

@FlipDragonAsNeeded:
            lda direction_wanted
            eor #$ff
            and #MoveTypes::left | MoveTypes::right
            beq :++                      ;forget it if not moving left or right
            and #MoveTypes::left
            tay                          ;0: face right, ~0: face left
            lda z:DynamicType::state,x
            ora #$80                     ;face right
            cpy #0
            beq :+
            and #$7f                     ;face left
:           sta z:DynamicType::state,x

:           lda curr_dragon_objoffset
            jsr PBCollision              ;check player-ball collision
            beq @CheckSwordContact       ;branch if no collision
            lda NumberCurrState
            asl a
            tay
            lda SWCHB                    ;get console switches
            and #%01000000               ;left difficulty (P0)
            beq :+                       ;branch if Amateur (B)
            iny
:           lda z:DynamicType::state,x
            and #$80
            ora DragonDifficulty,y       ;get new state
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
            ldx curr_dragon_objoffset
            jsr FindObjHit               ;set if another object has hit the dragon
            ldx portcullis_number
            cmp #objoffset_Sword         ;has the sword hit the dragon?
            bne :+                       ;if not, branch
            lda z:DynamicType::state,x
            and #$80
            ora #DragonState::dead
            sta z:DynamicType::state,x
            lda #NoiseType::dragon_died
            sta sound_type
            lda #16
            sta sound_duration_counter
:           jmp @DoneWithDragon
@DragonStateNotNormal:
            cmp #DragonState::dead
            beq @DoneWithDragon          ;branch if so
            cmp #DragonState::ateman
            bne @DragonRoaring           ;branch if not
@DragonStateAteMan:
            lda z:DynamicType::room,x
            sta ManDynamic+DynamicType::room
            sta PrevManDynamic+DynamicType::room
            lda z:DynamicType::xcoord,x
            clc
            adc #3                       ;adjust +3x
            sta ManDynamic+DynamicType::xcoord
            sta PrevManDynamic+DynamicType::xcoord
            lda z:DynamicType::ycoord,x
            sec
            sbc #10                      ;adjust -10y
            sta ManDynamic+DynamicType::ycoord
            sta PrevManDynamic+DynamicType::ycoord
            jmp @DoneWithDragon
@DragonRoaring:
            inc z:DynamicType::state,x   ;increment the dragon's state
            lda z:DynamicType::state,x   ;get its state
            and #$7f
            cmp #$7c                     ;is it near the end?
            bcc @DoneWithDragon          ;if not, branch
            lda curr_dragon_objoffset
            jsr PBCollision              ;check player-ball collision
            beq @DoneWithDragon          ;if not, branch
            lda z:DynamicType::state,x
            and #$80
            ora #DragonState::ateman
            sta z:DynamicType::state,x
            lda #NoiseType::man_eaten
            sta sound_type
            lda #16
            sta sound_duration_counter
            lda #155                     ;get the maximum X coordinate
            cmp z:DynamicType::xcoord,x  ;compare with the dragon's X coordinate
            beq :+
            bcs :+
            sta z:DynamicType::xcoord,x  ;cap it at max X coordinate
:           lda #23                      ;set minimum Y coordinate
            cmp z:DynamicType::ycoord,x  ;compare with the dragon's Y coordinate
            bcc @DoneWithDragon
            sta z:DynamicType::ycoord,x  ;cap it at min Y coordinate
@DoneWithDragon:
            rts

;; Move the bat "Knubberrub"
MoveBat:    inc BatDynamic+DynamicType::state ;put bat in the next state
            lda BatDynamic+DynamicType::state
            cmp #8                       ;has it reached the maximum?
            bne :+
            lda #0                       ; reset the bat state if so
            sta BatDynamic+DynamicType::state
:           lda BatDynamic+DynamicType::fedup
            beq @BatFedup                ;if bat fed-up then branch
            inc BatDynamic+DynamicType::fedup
            lda z:BatDynamic+DynamicType::move
            ldx #BatDynamic
            ldy #3                       ;get the bat's delta
            jsr MoveGroundObject         ;move the bat
            jmp @MoveCarriedObject       ;update the bat's object
@BatFedup:  lda #BatDynamic
            sta MoveGameObjectArg_ObjNumber
            lda #3
            sta objdelta
            lda #<BatLinkedObjectTable
            sta linked_objtable_ptr
            lda #>BatLinkedObjectTable
            sta linked_objtable_ptr+1
            lda BatDynamic+DynamicType::carriedobject
            sta MoveGameObjectArg_Difficulty
            jsr MoveGameObject
            ldy linked_objtable_index
            lda (linked_objtable_ptr),y  ;look up the object found in the table
            beq @MoveCarriedObject       ;if nothing found then forget it
            iny
            lda (linked_objtable_ptr),y  ;get the object wanted
            tax
            lda z:DynamicType::room,x
            cmp BatDynamic+DynamicType::room  ;is it the same as the bat's?
            bne @MoveCarriedObject       ;if not forget it
@SeeIfPickupPossible:
            lda z:DynamicType::xcoord,x
            sec
            sbc z:BatDynamic+DynamicType::xcoord  ;find the difference with the bat's X coordinate
            clc
            adc #4                       ;adjust so bat in middle of object
            and #%11111000               ;is bat within seven pixels?
            bne @MoveCarriedObject       ;if not, no pickup possible
            lda z:DynamicType::ycoord,x
            sec
            sbc z:BatDynamic+DynamicType::ycoord  ;find the difference with the bat's Y coordinate
            clc
            adc #4                       ;adjust so bat in middle of object
            and #%11111000               ;is the bat within seven pixels?
            bne @MoveCarriedObject       ;if not, no pickup possible
@PickupObject:
            stx BatDynamic+DynamicType::carriedobject  ;store wanted object as being carried
            lda #16                                    ;reset the bat fed-up time
            sta BatDynamic+DynamicType::fedup
@MoveCarriedObject:
            ldx BatDynamic+DynamicType::carriedobject  ;get object being carried by bat
            lda BatDynamic+DynamicType::room
            sta z:DynamicType::room,x
            lda z:BatDynamic+DynamicType::xcoord
            clc
            adc #8                                     ;adjust to the right +8x
            sta z:DynamicType::xcoord,x
            lda z:BatDynamic+DynamicType::ycoord
            sta z:DynamicType::ycoord,x
@ClearCarriedObjectIfNeeded:
            lda BatDynamic+DynamicType::carriedobject  ;get object being carried by bat
            ldy object_carried
            cmp Objects+ObjectType::dynamic_ptr,y      ;are they the same?
            bne :+                                     ; if not branch to exit
            lda #objoffset_Null
            sta object_carried
:           rts

;; Deal with portcullis and collisions
Portals:    ldy #2                      ;for each portcullis
@DoNext:    ldx PortOffsets,y           ;get the portcullis' offset number
            jsr FindObjHit              ;see if an object collided with it
            sta obj_collided_with
            cmp KeyOffsets,y            ;is it the associated key?
            bne :+                      ;if not then branch
            tya                         ;get the portcullis number
            tax
            inc PortCurrStatesBase,x    ;change its state to open it
:           tya                         ;get the portcullis number
            tax
            lda PortCurrStatesBase,x
            cmp #PortCullisState::closed
            beq @IncPortCullisState     ;yes - then branch
            lda PortOffsets,y           ;get portcullis number
            jsr PBCollision             ;check player-ball collision
            beq :+                      ;if not then branch
            lda #PortCullisState::open
            sta PortCurrStatesBase,x
            ldx #ManDynamic
            jmp @PutManInCastle
:           lda obj_collided_with       ;get the object that hit the portcullis
            cmp #objoffset_Null
            beq :+                      ;if so, branch
            ldx obj_collided_with
            sty portcullis_number
            jsr GetObjectDynamicInfoAddress  ; loads dr_ptr
            ldy portcullis_number
            ldx dr_ptr                  ;load address of object's dynamic info to x
            jmp @PutManInCastle
:           jmp @IncPortCullisState
@PutManInCastle:
            lda EntryRoomOffsets,y      ;look up castle entry room for this port
            sta DynamicType::room,x     ;make it the object's room
            lda #16                     ;give the object a new Y coordinate
            sta DynamicType::ycoord,x
@IncPortCullisState:
            tya                         ;get the portcullis number
            tax
            lda PortCurrStatesBase,x
            cmp #PortCullisState::open
            beq :+                      ; branch if open
            cmp #PortCullisState::closed
            beq :+                      ; branch if closed
            inc PortCurrStatesBase,x
            lda PortCurrStatesBase,x
            cmp #PortCullisState::wraparound_max
            bne :+                      ; branch if not reached wraparound max
            lda #PortCullisState::open  ;wrap around
            sta PortCurrStatesBase,x
:           dey                         ;go to the next portcullis
            bmi @PortalsDone            ;branch if finished
            jmp @DoNext                 ;do next portcullis
@PortalsDone:
            rts

;; Deal with magnet
Mag:        lda z:MagnetDynamic+DynamicType::ycoord
            sec
            sbc #8                ;adjust to its "poles"
            sta z:MagnetDynamic+DynamicType::ycoord
            lda #0
            sta MoveGameObjectArg_Difficulty
            lda #<MagnetLinkedObjectTable
            sta linked_objtable_ptr
            lda #>MagnetLinkedObjectTable
            sta linked_objtable_ptr+1
            jsr GetLinkedObject   ;get linked object and direction wanted
            lda direction_wanted
            beq :+                ;if none, then forget it
            ldy #1                ;set delta to one
            jsr MoveGroundObject
:           lda z:MagnetDynamic+DynamicType::ycoord  ;reset the magnet's Y coordinate
            clc
            adc #8
            sta z:MagnetDynamic+DynamicType::ycoord
            rts

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
            sta COLUPF
            sta AUDC0
            lsr a
            sta AUDV0
            lsr a
            lsr a
            sta AUDF0
            rts

RoarNoise:  lda sound_duration_counter
            lsr a
            lda #3                ;5-bit polynomial feeding 4-bit polynomial
            bcs :+                ;branch if it was odd
            lda #8                ;9-bit polynomial
:           sta AUDC0
            lda sound_duration_counter
            sta AUDV0
            lsr a
            lsr a
            clc
            adc #28
            sta AUDF0
            rts

EatenNoise:
            lda #6                ;divide by 31, pure tone
            sta AUDC0
            lda sound_duration_counter
            eor #%00001111
            sta AUDF0
            lda sound_duration_counter
            lsr a
            clc
            adc #8
            sta AUDV0
            rts

DragDieNoise:
            lda #4                ;divide by 2, pure tone
            sta AUDC0
            lda sound_duration_counter
            sta AUDV0
            eor #%00011111
            sta AUDF0
            rts

DropObjectNoise:
            lda sound_duration_counter
            eor #3                ;reverse it as noise goes up
:           sta AUDF0
            lda #5
            sta AUDV0
            lda #6                ;divide by 31, pure tone
            sta AUDC0
            rts

GetObjectNoise:
            lda sound_duration_counter
            jmp :-                ;make same noise as drop


; index = 2*NumberCurrState + ConsoleSwitchType::leftdifficulty
DragonDifficulty:
            .byte DragonState::roaring-47, DragonState::roaring-23  ;level 1: 0=Amateur (B), 1=Pro (A)
            .byte DragonState::roaring-15, DragonState::roaring-9   ;level 2: 0=Amateur (B), 1=Pro (A)
            .byte DragonState::roaring-15, DragonState::roaring-9   ;level 3: 0=Amateur (B), 1=Pro (A)

RedDragonLinkedObjectTable:
            .byte SwordDynamic,        RedDragonDynamic
            .byte RedDragonDynamic,    ManDynamic
            .byte RedDragonDynamic,    ChaliceDynamic
            .byte RedDragonDynamic,    WhiteKeyDynamic
            .byte 0

YellowDragLinkedObjectTable:
            .byte SwordDynamic,        YellowDragonDynamic
            .byte YellowKeyDynamic,    YellowDragonDynamic
            .byte YellowDragonDynamic, ManDynamic
            .byte YellowDragonDynamic, ChaliceDynamic
            .byte 0

GreenDragonLinkedObjectTable:
            .byte SwordDynamic,        GreenDragonDynamic
            .byte GreenDragonDynamic,  ManDynamic
            .byte GreenDragonDynamic,  ChaliceDynamic
            .byte GreenDragonDynamic,  BridgeDynamic
            .byte GreenDragonDynamic,  MagnetDynamic
            .byte GreenDragonDynamic,  BlackKeyDynamic
            .byte 0

BatLinkedObjectTable:
            .byte BatDynamic,          ChaliceDynamic
            .byte BatDynamic,          SwordDynamic
            .byte BatDynamic,          BridgeDynamic
            .byte BatDynamic,          YellowKeyDynamic
            .byte BatDynamic,          WhiteKeyDynamic
            .byte BatDynamic,          BlackKeyDynamic
            .byte BatDynamic,          RedDragonDynamic
            .byte BatDynamic,          YellowDragonDynamic
            .byte BatDynamic,          GreenDragonDynamic
            .byte BatDynamic,          MagnetDynamic
            .byte 0

MagnetLinkedObjectTable:
            .byte YellowKeyDynamic,    MagnetDynamic
            .byte WhiteKeyDynamic,     MagnetDynamic
            .byte BlackKeyDynamic,     MagnetDynamic
            .byte SwordDynamic,        MagnetDynamic
            .byte BridgeDynamic,       MagnetDynamic
            .byte ChaliceDynamic,      MagnetDynamic
            .byte 0

PortOffsets:       .byte  objoffset_PortCullisYlw,   objoffset_PortCullisWht,  objoffset_PortCullisBlk
KeyOffsets:        .byte  objoffset_YellowKey,       objoffset_WhiteKey,       objoffset_BlackKey
EntryRoomOffsets:  .byte  roomnum_YellowCastleEntry, roomnum_WhiteCastleEntry, roomnum_BlackCastleEntry
CastleRoomOffsets: .byte  roomnum_YellowCastle,      roomnum_WhiteCastle,      roomnum_BlackCastle

JoystickMergeValues:
            ;     no change,  no horizontal, no vertical
            .byte 0,          %11000000,     %00110000

GameObjectLocations:
            .word Game1ObjectLocations
            .word Game2ObjectLocations
            .word Game2ObjectLocations

.assert (Game1ObjectLocationsEnd - Game1ObjectLocations) = (Game2ObjectLocationsEnd - Game2ObjectLocations), error, "Game object locations sizes not equal"

Game1ObjectLocations:
; DynamicType     Location                                X    Y    Mvt  State      Object
            .byte roomnum_BlackMazeBottomLeft,           81,  18                    ;dot
            .byte roomnum_TopEntryRoom1,                 80,  32,   0,   0          ;red dragon
            .byte roomnum_BelowYellowCastleLeftThinWall, 80,  32,   0,   0          ;yellow dragon
            .byte roomnum_TopEntryRoom2,                 80,  32,   0,   0          ;green dragon
            .byte roomnum_BlackCastleEntry,             128,  32                    ;magnet
            .byte roomnum_YellowCastleEntry,             32,  32                    ;sword
            .byte roomnum_OtherPurpleRoom,               48,  32                    ;chalice
            .byte roomnum_BlueMazeTop,                   41,  55                    ;bridge
            .byte roomnum_YellowCastle,                  32,  64                    ;yellow key
            .byte roomnum_TopEntryRoom1,                 32,  64                    ;white key
            .byte roomnum_TopEntryRoom2,                 32,  64                    ;black key
            .byte roomnum_WhiteCastleEntry,              32,  32,   0,   0, $78, 0  ;bat
            .byte PortCullisState::closed                                           ;portcullis state - Ylw
            .byte PortCullisState::closed                                           ;portcullis state - Wht
            .byte PortCullisState::closed                                           ;portcullis state - Blk
Game1ObjectLocationsEnd:

Game2ObjectLocations:
; DynamicType     Location                                X    Y    Mvt  State      Object
            .byte roomnum_BlackMazeBottomLeft,           81,  18                    ;dot
            .byte roomnum_BlackMazeTopRight,             80,  32,  $a0,  0          ;red dragon
            .byte roomnum_RedMazeBottomLeft,             80,  32,  $a0,  0          ;yellow dragon
            .byte roomnum_BlueMazeTop,                   80,  32,  $a0,  0          ;green dragon
            .byte roomnum_TopEntryRoom1,                128,  32                    ;magnet
            .byte roomnum_YellowCastle,                  32,  32                    ;sword
            .byte roomnum_BlackMazeTopRight,             48,  32                    ;chalice
            .byte roomnum_MazeSide,                      64,  64                    ;bridge
            .byte roomnum_MazeMiddle,                    32,  64                    ;yellow key
            .byte roomnum_BlueMazeBottom,                32,  64                    ;white key
            .byte roomnum_RedMazeBottomLeft,             32,  64                    ;black key
            .byte roomnum_BelowYellowCastle,             32,  32,  $90,  0, $78, 0  ;bat
            .byte PortCullisState::closed                                           ;portcullis state - Ylw
            .byte PortCullisState::closed                                           ;portcullis state - Wht
            .byte PortCullisState::closed                                           ;portcullis state - Blk
Game2ObjectLocationsEnd:

Level3ObjectsToRandomize:
            .byte RedDragonDynamic
            .byte YellowDragonDynamic
            .byte GreenDragonDynamic
            .byte MagnetDynamic
            .byte SwordDynamic
            .byte ChaliceDynamic
            .byte BridgeDynamic
            .byte YellowKeyDynamic
            .byte WhiteKeyDynamic
            .byte BlackKeyDynamic
            .byte BatDynamic
Level3ObjectsToRandomizeEnd:

PortCullisStates:   .byte 4                 ; open
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
PortDynamicYlw:     .byte roomnum_YellowCastle, 77, 49
PortDynamicWht:     .byte roomnum_WhiteCastle,  77, 49
PortDynamicBlk:     .byte roomnum_BlackCastle,  77, 49

SurroundCurrState:  .byte 0
SurroundStates:     .byte $ff
                    .word SurroundGfx

BridgeCurrState:    .byte 0
BridgeStates:       .byte $ff
                    .word BridgeGfx

KeyCurrState:       .byte 0
KeyStates:          .byte $ff
                    .word KeyGfx

DragonStates:       .byte DragonState::normal
                    .word DragonNormLeftGfx
                    .byte DragonState::dead
                    .word DragonDeadLeftGfx
                    .byte DragonState::ateman
                    .word DragonNormLeftGfx
                    .byte DragonState::roaring
                    .word DragonRoarLeftGfx
                    .byte DragonState::normal  | $80
                    .word DragonNormRightGfx
                    .byte DragonState::dead    | $80
                    .word DragonDeadRightGfx
                    .byte DragonState::ateman  | $80
                    .word DragonNormRightGfx
                    .byte DragonState::roaring | $80
                    .word DragonRoarRightGfx

BatStates:          .byte 3
                    .word Bat1Gfx
                    .byte $ff
                    .word Bat2Gfx

SwordStates:        .byte SwordState::left
                    .word SwordLeftGfx
                    .byte SwordState::right
                    .word SwordRightGfx

DotCurrState:       .byte 0
DotStates:          .byte $ff
                    .word DotGfx

EasterEggDynamic:   .byte roomnum_SecretRoom, 80, 105
EasterEggStates:    .byte 0
                    .word EasterEggGfx
                    .byte $ff
                    .word EasterEggGfx2

ChaliceCurrState:   .byte 0
ChaliceStates:      .byte $ff
                    .word ChaliceGfx

NullCurrState:      .byte 0
NullStates:         .byte $ff
                    .word NullGfx

NumberDynamic:      .byte roomnum_NumberRoom, 80, 64
NumberStates:       .byte 0
                    .word Number1Gfx
                    .byte 1
                    .word Number2Gfx
                    .byte $ff
                    .word Number3Gfx

MagnetCurrState:    .byte 0
MagnetStates:       .byte $ff
                    .word MagnetGfx1


Rooms:
roomnum_NumberRoom = (* - Rooms) / .sizeof(RoomType)
    .word NumberRoom
    .byte ColorType::purple, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_SecretRoom, roomnum_SecretRoom, roomnum_SecretRoom, roomnum_SecretRoom

roomnum_SecretRoom = (* - Rooms) / .sizeof(RoomType)
    .word BelowYellowCastle
    .byte ColorType::purple, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_NumberRoom, roomnum_BelowYellowCastleLeftThinWall, roomnum_BlueMazeBottom, roomnum_BelowYellowCastleRightThinWall

roomnum_BelowYellowCastleLeftThinWall = (* - Rooms) / .sizeof(RoomType)
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
    .byte roomnum_BlackCastle, roomnum_BlueMazeLeft, roomnum_BlueMazeCenter, roomnum_BlueMazeBottom

roomnum_BlueMazeLeft = (* - Rooms) / .sizeof(RoomType)
    .word BlueMazeLeft
    .byte ColorType::blue, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_TopEntryRoom2, roomnum_BlueMazeBottom, roomnum_BlueMazeEntry, roomnum_BlueMazeTop

roomnum_BlueMazeBottom = (* - Rooms) / .sizeof(RoomType)
    .word BlueMazeBottom
    .byte ColorType::blue, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_BlueMazeCenter, roomnum_BlueMazeTop, roomnum_BelowYellowCastleRightThinWall, roomnum_BlueMazeLeft

roomnum_BlueMazeCenter = (* - Rooms) / .sizeof(RoomType)
    .word BlueMazeCenter
    .byte ColorType::blue, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_BlueMazeTop, roomnum_BlueMazeEntry, roomnum_BlueMazeBottom, roomnum_BlueMazeEntry

roomnum_BlueMazeEntry = (* - Rooms) / .sizeof(RoomType)
    .word BlueMazeEntry
    .byte ColorType::blue, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_BlueMazeLeft, roomnum_BlueMazeCenter, roomnum_BelowYellowCastleLeftThinWall, roomnum_BlueMazeCenter

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
    .word NumberRoom
    .byte ColorType::yellow, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_YellowCastleEntry, roomnum_YellowCastleEntry, roomnum_YellowCastleEntry, roomnum_YellowCastleEntry

roomnum_BlackMazeTopLeft = (* - Rooms) / .sizeof(RoomType)
    .word BlackMazeTopLeft
    .byte ColorType::invisible, ColorType::invisible
    .byte RoomControlType::pfref_pfp
    .byte roomnum_BlackMazeBottomLeft, roomnum_BlackMazeTopRight, roomnum_BlackMazeBottomLeft, roomnum_BlackMazeEntry

roomnum_BlackMazeTopRight = (* - Rooms) / .sizeof(RoomType)
    .word BlackMazeTopRight
    .byte ColorType::invisible, ColorType::invisible
    .byte RoomControlType::pfp
    .byte roomnum_BlackMazeEntry, roomnum_BlackMazeBottomLeft, roomnum_BlackMazeEntry, roomnum_BlackMazeTopLeft

roomnum_BlackMazeBottomLeft = (* - Rooms) / .sizeof(RoomType)
    .word BlackMazeBottomLeft
    .byte ColorType::invisible, ColorType::invisible
    .byte RoomControlType::pfp
    .byte roomnum_BlackMazeTopLeft, roomnum_BlackMazeEntry, roomnum_BlackMazeTopLeft, roomnum_BlackMazeTopRight

roomnum_BlackMazeEntry = (* - Rooms) / .sizeof(RoomType)
    .word BlackMazeEntry
    .byte ColorType::invisible, ColorType::invisible
    .byte RoomControlType::pfref_pfp
    .byte roomnum_BlackMazeTopRight, roomnum_BlackMazeTopLeft, roomnum_BlackCastleEntry, roomnum_BlackMazeBottomLeft

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

roomnum_TopEntryRoom1 = (* - Rooms) / .sizeof(RoomType)
    .word TopEntryRoom
    .byte ColorType::turquoise, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_SideCorridor2, roomnum_BlackCastle, roomnum_WhiteCastle, roomnum_BlackCastle

roomnum_TopEntryRoom2 = (* - Rooms) / .sizeof(RoomType)
    .word TopEntryRoom
    .byte ColorType::red, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_upfrom_TopEntryRoom, roomnum_BelowYellowCastleLeftThinWall, roomnum_BlackCastle, roomnum_BelowYellowCastleRightThinWall

roomnum_RedMazeTopLeft = (* - Rooms) / .sizeof(RoomType)
    .word RedMazeTopLeft
    .byte ColorType::red, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_RedMazeBottomLeft, roomnum_RedMazeTopRight, roomnum_RedMazeBottomLeft, roomnum_RedMazeTopRight

roomnum_RedMazeTopRight = (* - Rooms) / .sizeof(RoomType)
    .word RedMazeTopRight
    .byte ColorType::red, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_WhiteCastleEntry, roomnum_RedMazeTopLeft, roomnum_WhiteCastleEntry, roomnum_RedMazeTopLeft

roomnum_RedMazeBottomLeft = (* - Rooms) / .sizeof(RoomType)
    .word RedMazeBottomLeft
    .byte ColorType::red, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_RedMazeTopLeft, roomnum_WhiteCastleEntry, roomnum_RedMazeTopLeft, roomnum_WhiteCastleEntry

roomnum_WhiteCastleEntry = (* - Rooms) / .sizeof(RoomType)
    .word WhiteCastleEntry
    .byte ColorType::red, ColorType::lightergray
    .byte RoomControlType::pfref
    .byte roomnum_RedMazeTopRight, roomnum_RedMazeBottomLeft, roomnum_RedMazeTopRight, roomnum_RedMazeBottomLeft


RoomDiffs:
; room differences for different levels
; level 1                                     level 2                 level 3

roomnum_downfrom_BelowYellowCastleLeftThinWall = (* - RoomDiffs) | $80
.byte roomnum_BlackCastle,                    roomnum_WhiteCastle,    roomnum_WhiteCastle

roomnum_downfrom_BelowYellowCastleGreen = (* - RoomDiffs) | $80
.byte roomnum_BlueMazeLeft,                   roomnum_YellowCastle,   roomnum_YellowCastle

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

objoffset_PortCullisYlw = (* - Objects)
    .word PortDynamicYlw
    .word PortCurrStatesBase+0
    .word PortCullisStates
    .byte ColorType::black, ColorType::black
    .byte 0

objoffset_PortCullisWht = (* - Objects)
    .word PortDynamicWht
    .word PortCurrStatesBase+1
    .word PortCullisStates
    .byte ColorType::black, ColorType::black
    .byte 0

objoffset_PortCullisBlk = (* - Objects)
    .word PortDynamicBlk
    .word PortCurrStatesBase+2
    .word PortCullisStates
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
objoffset_StartOfCarriables = objoffset_Sword
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

objoffset_Bat = (* - Objects)
    .word BatDynamic
    .word BatDynamic+DynamicType::state
    .word BatStates
    .byte ColorType::black, ColorType::black
    .byte 0

objoffset_Dot = (* - Objects)
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


.segment "VECTORS0"
;DoVSYNC:
            sta Bank+0
            jsr DoVSYNC_R
            sta Bank+1
            rts
;PrintDisplay:
            sta Bank+0
            jsr PrintDisplay_R
            sta Bank+1
            rts
;InitializeDisplay:
            sta Bank+0
            jsr InitializeDisplay_R
            sta Bank+1
            rts
;Reset:
            sta Bank+1
            jmp StartGame

           .byte $32, $30, $32, $36, $31, $32, $30, $31 ; 20261201
           .byte 0, 1
           .word Reset
           .word Reset
           .word Reset

.segment "VECTORS1"
DoVSYNC:
            sta Bank+0
            jsr DoVSYNC_R
            sta Bank+1
            rts
PrintDisplay:
            sta Bank+0
            jsr PrintDisplay_R
            sta Bank+1
            rts
InitializeDisplay:
            sta Bank+0
            jsr InitializeDisplay_R
            sta Bank+1
            rts
Reset:
            sta Bank+1
            jmp StartGame

Version:    .byte $32, $30, $32, $36, $31, $32, $30, $31 ; 20261201
Bank:       .byte 0, 1
NMI:        .word Reset
RESET:      .word Reset
IRQ:        .word Reset
