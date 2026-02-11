.struct RoomDataEntry
    gfx_ptr     .word  ; room graphics data
    color       .byte
    bw_color    .byte
    pf_control  .byte  ; 7=if left thin wall wanted, 6=if right thin wall wanted, 5-0=playfield control
    room_up     .byte
    room_right  .byte
    room_down   .byte
    room_left   .byte
.endstruct

.macro RoomsMacro original
    Rooms:

    RoomNumbers_NumberRoom1 = (*-Rooms) / .sizeof(RoomDataEntry)
    .word NumberRoom                      ; 00 game select
    .byte $66, $0a                        ; purple
    .byte %00100001
    .byte RoomNumbers_NumberRoom1         ; up
    .byte RoomNumbers_NumberRoom1         ; right
    .byte RoomNumbers_NumberRoom1         ; down
    .byte RoomNumbers_NumberRoom1         ; left

    RoomNumbers_BelowYellowCastle1 = (*-Rooms) / .sizeof(RoomDataEntry)
    .word BelowYellowCastle               ; 01
    .byte $d8, $0a
    .byte %10100001                       ; left thin wall
    .byte RoomNumbers_BlueMazeEntry       ; up
    .byte RoomNumbers_BelowYellowCastle2  ; right
    .byte $80 + RoomNumbers_NumberRoom1   ; down
    .byte RoomNumbers_LeftOfName          ; left

    RoomNumbers_BelowYellowCastle2 = (*-Rooms) / .sizeof(RoomDataEntry)
    .word BelowYellowCastle               ; 02
    .byte $c8, $0a                        ; green
    .byte %00100001
    .byte RoomNumbers_CastleDef3          ; up
    .byte RoomNumbers_LeftOfName          ; right
    .byte $80 + RoomNumbers_LeftOfName    ; down
    .byte RoomNumbers_BelowYellowCastle1  ; left

    RoomNumbers_LeftOfName = (*-Rooms) / .sizeof(RoomDataEntry)
    .word LeftOfName                      ; 03 left of name
    .byte $e8, $0a
    .byte %01100001                       ; right thin wall
    .byte RoomNumbers_BlueMazeBottom        ; up
    .byte RoomNumbers_BelowYellowCastle1    ; right
    .byte $80 + RoomNumbers_BlueMazeBottom  ; down
    .byte RoomNumbers_BelowYellowCastle2    ; left

     RoomNumbers_BlueMazeTop = (*-Rooms) / .sizeof(RoomDataEntry)
    .word BlueMazeTop                     ; 04 top of blue maze
    .byte $86, $0a                        ; blue
    .byte %00100001
    .byte RoomNumbers_CastleDef2          ; up
    .byte RoomNumbers_BlueMaze1           ; right
    .byte RoomNumbers_BlueMazeCenter      ; down
    .byte RoomNumbers_BlueMazeBottom      ; left

    RoomNumbers_BlueMaze1 = (*-Rooms) / .sizeof(RoomDataEntry)
    .word BlueMaze1                       ; 05 blue maze #1
    .byte $86, $0a                        ; blue
    .byte %00100001
    .byte RoomNumbers_TopEntryRoom2       ; up
    .byte RoomNumbers_BlueMazeBottom      ; right
    .byte RoomNumbers_BlueMazeEntry       ; down
    .byte RoomNumbers_BlueMazeTop         ; left

    RoomNumbers_BlueMazeBottom = (*-Rooms) / .sizeof(RoomDataEntry)
    .word BlueMazeBottom                  ; 06 bottom of blue maze
    .byte $86, $0a                        ; blue
    .byte %00100001
    .byte RoomNumbers_BlueMazeCenter      ; up
    .byte RoomNumbers_BlueMazeTop         ; right
    .byte RoomNumbers_LeftOfName          ; down
    .byte RoomNumbers_BlueMaze1           ; left

    RoomNumbers_BlueMazeCenter = (*-Rooms) / .sizeof(RoomDataEntry)
    .word BlueMazeCenter                  ; 07 center of blue maze
    .byte $86, $0a                        ; blue
    .byte %00100001
    .byte RoomNumbers_BlueMazeTop         ; up
    .byte RoomNumbers_BlueMazeEntry       ; right
    .byte RoomNumbers_BlueMazeBottom      ; down
    .byte RoomNumbers_BlueMazeEntry       ; left

     RoomNumbers_BlueMazeEntry = (*-Rooms) / .sizeof(RoomDataEntry)
    .word BlueMazeEntry                   ; 08 blue maze entry
    .byte $86, $0a                        ; blue
    .byte %00100001
    .byte RoomNumbers_BlueMaze1           ; up
    .byte RoomNumbers_BlueMazeCenter      ; right
    .byte RoomNumbers_BelowYellowCastle1  ; down
    .byte RoomNumbers_BlueMazeCenter      ; left

     RoomNumbers_MazeMiddle = (*-Rooms) / .sizeof(RoomDataEntry)
    .word MazeMiddle                      ; 09 maze middle
    .byte $08, $08                        ; invisible
    .byte %00100101
    .byte RoomNumbers_MazeEntry           ; up
    .byte RoomNumbers_MazeEntry           ; right
    .byte RoomNumbers_MazeSide            ; down
    .byte RoomNumbers_MazeEntry           ; left

    RoomNumbers_MazeEntry = (*-Rooms) / .sizeof(RoomDataEntry)
    .word MazeEntry                       ; 0a maze entry
    .byte $08, $08                        ; invisible
    .byte %00100101
    .byte RoomNumbers_LeftOfName          ; up
    .byte RoomNumbers_MazeMiddle          ; right
    .byte RoomNumbers_MazeMiddle          ; down
    .byte RoomNumbers_MazeMiddle          ; left

    RoomNumbers_MazeSide = (*-Rooms) / .sizeof(RoomDataEntry)
    .word MazeSide                        ; 0b maze side
    .byte $08, $08                        ; invisible
    .byte %00100101
    .byte RoomNumbers_MazeMiddle          ; up
    .byte RoomNumbers_SideCorridor1       ; right
    .byte RoomNumbers_NumberRoom3         ; down
    .byte RoomNumbers_SideCorridor2       ; left

    RoomNumbers_SideCorridor1 = (*-Rooms) / .sizeof(RoomDataEntry)
    .word SideCorridor                    ; 0c side corridor
    .byte $98, $0a
    .byte %01100001
    .byte RoomNumbers_NumberRoom3         ; up
    .byte RoomNumbers_SideCorridor2       ; right
    .byte RoomNumbers_TopEntryRoom2       ; down
    .byte RoomNumbers_MazeSide            ; left

    RoomNumbers_SideCorridor2 = (*-Rooms) / .sizeof(RoomDataEntry)
    .word SideCorridor                    ; 0d side corridor
    .byte $b8, $0a
    .byte %10100001
    .byte RoomNumbers_CastleDef1          ; up
    .byte RoomNumbers_MazeSide            ; right
    .byte RoomNumbers_TopEntryRoom1       ; down
    .byte RoomNumbers_SideCorridor1       ; left

    RoomNumbers_TopEntryRoom1 = (*-Rooms) / .sizeof(RoomDataEntry)
    .word TopEntryRoom                    ; 0e top entry room
    .byte $a8, $0a
    .byte %00100001
    .byte RoomNumbers_SideCorridor2       ; up
    .byte RoomNumbers_CastleDef2          ; right
    .byte RoomNumbers_CastleDef1          ; down
    .byte RoomNumbers_CastleDef2          ; left

    RoomNumbers_CastleDef1 = (*-Rooms) / .sizeof(RoomDataEntry)
    .word CastleDef                       ; 0f white castle
    .byte $0c, $0c                        ; white
    .byte %00100001
    .byte RoomNumbers_TopEntryRoom1       ; up
    .byte RoomNumbers_CastleDef1          ; right
    .byte RoomNumbers_SideCorridor2       ; down
    .byte RoomNumbers_CastleDef1          ; left

    RoomNumbers_CastleDef2 = (*-Rooms) / .sizeof(RoomDataEntry)
    .word CastleDef                       ; 10 black castle
    .byte $00, $02                        ; black
    .byte %00100001
    .byte RoomNumbers_BelowYellowCastle1  ; up
    .byte RoomNumbers_NumberRoom3         ; right
    .byte RoomNumbers_BlueMazeTop         ; down
    .byte RoomNumbers_NumberRoom3         ; left

    RoomNumbers_CastleDef3 = (*-Rooms) / .sizeof(RoomDataEntry)
    .word CastleDef                       ; 11 yellow castle
    .byte $1a, $0a                        ; yellow
    .byte %00100001
    .byte RoomNumbers_BlueMazeBottom      ; up
    .byte RoomNumbers_LeftOfName          ; right
    .byte RoomNumbers_BelowYellowCastle2  ; down
    .byte RoomNumbers_BelowYellowCastle1  ; left

    RoomNumbers_NumberRoom2 = (*-Rooms) / .sizeof(RoomDataEntry)
    .word NumberRoom                      ; 12 yellow castle entry
    .byte $1a, $0a                        ; yellow
    .byte %00100001
    .byte RoomNumbers_NumberRoom2         ; up
    .byte RoomNumbers_NumberRoom2         ; right
    .byte RoomNumbers_NumberRoom2         ; down
    .byte RoomNumbers_NumberRoom2         ; left

    RoomNumbers_BlackMaze1 = (*-Rooms) / .sizeof(RoomDataEntry)
    .word BlackMaze1                      ; 13 black maze #1
    .byte $08, $08                        ; invisible
    .byte %00100101
    .byte RoomNumbers_BlackMaze3          ; up
    .byte RoomNumbers_BlackMaze2          ; right
    .byte RoomNumbers_BlackMaze3          ; down
    .byte RoomNumbers_BlackMazeEntry      ; left

    RoomNumbers_BlackMaze2 = (*-Rooms) / .sizeof(RoomDataEntry)
    .word BlackMaze2                      ; 14 black maze #2
    .byte $08, $08                        ; invisible
    .byte %00100100
    .byte RoomNumbers_BlackMazeEntry      ; up
    .byte RoomNumbers_BlackMaze3          ; right
    .byte RoomNumbers_BlackMazeEntry      ; down
    .byte RoomNumbers_BlackMaze1          ; left

    RoomNumbers_BlackMaze3 = (*-Rooms) / .sizeof(RoomDataEntry)
    .word BlackMaze3                      ; 15 black maze #3
    .byte $08, $08                        ; invisible
    .byte %00100100
    .byte RoomNumbers_BlackMaze1          ; up
    .byte RoomNumbers_BlackMazeEntry      ; right
    .byte RoomNumbers_BlackMaze1          ; down
    .byte RoomNumbers_BlackMaze2          ; left

    RoomNumbers_BlackMazeEntry = (*-Rooms) / .sizeof(RoomDataEntry)
    .word BlackMazeEntry                  ; 16 black maze entry
    .byte $08, $08                        ; invisible
    .byte %00100101
    .byte RoomNumbers_BlackMaze2          ; up
    .byte RoomNumbers_BlackMaze1          ; right
    .byte RoomNumbers_TwoExitRoom         ; down
    .byte RoomNumbers_BlackMaze3          ; left

    RoomNumbers_RedMaze1 = (*-Rooms) / .sizeof(RoomDataEntry)
    .word RedMaze1                        ; 17 red maze #1
    .byte $36, $0a                        ; red
    .byte %00100001
    .byte RoomNumbers_RedMazeBottom       ; up
    .byte RoomNumbers_RedMazeTop          ; right
    .byte RoomNumbers_RedMazeBottom       ; down
    .byte RoomNumbers_RedMazeTop          ; left

    RoomNumbers_RedMazeTop = (*-Rooms) / .sizeof(RoomDataEntry)
    .word RedMazeTop                      ; 18 top of red maze
    .byte $36, $0a                        ; red
    .byte %00100001
    .byte RoomNumbers_WhiteCastleEntry    ; up
    .byte RoomNumbers_RedMaze1            ; right
    .byte RoomNumbers_WhiteCastleEntry    ; down
    .byte RoomNumbers_RedMaze1            ; left

    RoomNumbers_RedMazeBottom = (*-Rooms) / .sizeof(RoomDataEntry)
    .word RedMazeBottom                   ; 19 bottom of red maze
    .byte $36, $0a                        ; red
    .byte %00100001
    .byte RoomNumbers_RedMaze1            ; up
    .byte RoomNumbers_WhiteCastleEntry    ; right
    .byte RoomNumbers_RedMaze1            ; down
    .byte RoomNumbers_WhiteCastleEntry    ; left

    RoomNumbers_WhiteCastleEntry = (*-Rooms) / .sizeof(RoomDataEntry)
    .word WhiteCastleEntry                ; 1a white castle entry
    .byte $36, $0a                        ; red
    .byte %00100001
    .byte RoomNumbers_RedMazeTop          ; up
    .byte RoomNumbers_RedMazeBottom       ; right
    .byte RoomNumbers_RedMazeTop          ; down
    .byte RoomNumbers_RedMazeBottom       ; left

    RoomNumbers_TwoExitRoom = (*-Rooms) / .sizeof(RoomDataEntry)
    .word TwoExitRoom                     ; 1b black castle entry
    .byte $36, $0a                        ; red
    .byte %00100001
    .byte $80 + RoomNumbers_MazeMiddle    ; up
    .byte $80 + RoomNumbers_MazeMiddle    ; right
    .byte $80 + RoomNumbers_MazeMiddle    ; down
    .byte $80 + RoomNumbers_MazeMiddle    ; left

    RoomNumbers_NumberRoom3 = (*-Rooms) / .sizeof(RoomDataEntry)
    .word NumberRoom                      ; 1c other purple room
    .byte $66, $0a                        ; purple
    .byte %00100001
    .byte RoomNumbers_TopEntryRoom2       ; up
    .byte RoomNumbers_BlueMazeCenter      ; right
    .byte $80 + RoomNumbers_SideCorridor1 ; down
    .byte RoomNumbers_BlueMazeEntry       ; left

    RoomNumbers_TopEntryRoom2 = (*-Rooms) / .sizeof(RoomDataEntry)
    .word TopEntryRoom                    ; 1d (top entry room)
    .byte $36, $0a                        ; red
    .byte %00100001
    .byte $80 + RoomNumbers_CastleDef1    ; up
    .byte RoomNumbers_BelowYellowCastle1  ; right
    .byte RoomNumbers_CastleDef2          ; down
    .byte RoomNumbers_LeftOfName          ; left

    RoomNumbers_SecretRoom = (*-Rooms) / .sizeof(RoomDataEntry)
    .word BelowYellowCastle               ; 1e name/secret room
    .byte $66, $0a                        ; purple
    .byte %00100001
    .ifnblank original
    .byte RoomNumbers_BlueMazeBottom      ; up
    .else
    .byte RoomNumbers_NumberRoom1         ; right
    .endif
    .byte RoomNumbers_BelowYellowCastle1  ; right
    .byte RoomNumbers_BlueMazeBottom      ; down
    .byte RoomNumbers_LeftOfName          ; left

    .ifblank original
LeftOfName:         leftofname_gfxpf_data
BelowYellowCastle:  belowyellowcastle_gfxpf_data
SideCorridor:       sidecorridor_gfxpf_data
NumberRoom:         numberroom_gfxpf_data
TwoExitRoom:        twoexitroom_gfxpf_data
BlueMazeTop:        bluemazetop_gfxpf_data
BlueMaze1:          bluemaze1_gfxpf_data
BlueMazeBottom:     bluemazebottom_gfxpf_data
BlueMazeCenter:     bluemazecenter_gfxpf_data
BlueMazeEntry:      bluemazeentry_gfxpf_data
MazeMiddle:         mazemiddle_gfxpf_data
MazeSide:           mazeside_gfxpf_data
MazeEntry:          mazeentry_gfxpf_data
CastleDef:          castle_gfxpf_data
RedMaze1:           redmaze1_gfxpf_data
RedMazeBottom:      redmazebottom_gfxpf_data
RedMazeTop:         redmazetop_gfxpf_data
WhiteCastleEntry:   whitecastleentry_gfxpf_data
TopEntryRoom:       topentryroom_gfxpf_data
BlackMaze1:         blackmaze1_gfxpf_data
BlackMaze3:         blackmaze3_gfxpf_data
BlackMaze2:         blackmaze2_gfxpf_data
BlackMazeEntry:     blackmazeentry_gfxpf_data
    .endif
.endmacro
