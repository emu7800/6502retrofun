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

.macro RoomsMacro
    Rooms:

    .word NumberRoom        ;00 number room
    .byte $66, $0a          ;purple
    .byte %00100001
    .byte $00, $00, $00, $00

    .word BelowYellowCastle ;01 (top access) reflected / 8 clock ball
    .byte $d8, $0a
    .byte %10100001         ; left thin wall
    .byte $08, $02, $80, $03

    .word BelowYellowCastle ;02 (top access)
    .byte $c8, $0a          ;green
    .byte %00100001
    .byte $11, $03, $83, $01

    .word LeftOfName        ;03 left of name
    .byte $e8, $0a
    .byte %01100001         ; right thin wall
    .byte $06, $01, $86, $02

    .word BlueMazeTop       ;04 top of blue maze
    .byte $86, $0a          ;blue
    .byte %00100001
    .byte $10, $05, $07, $06

    .word BlueMaze1         ;05 blue maze #1; blue
    .byte $86, $0a          ;blue
    .byte %00100001
    .byte $1d, $06, $08, $04

    .word BlueMazeBottom    ;06 bottom of blue maze
    .byte $86, $0a
    .byte %00100001
    .byte $07, $04, $03, $05

    .word BlueMazeCenter    ;07 center of blue maze
    .byte $86, $0a          ;blue
    .byte %00100001
    .byte $04, $08, $06, $08

    .word BlueMazeEntry     ;08 blue maze entry
    .byte $86, $0a          ;blue
    .byte %00100001, $05, $07, $01, $07

    .word MazeMiddle        ;09 maze middle
    .byte $08, $08          ;invisible
    .byte %00100101
    .byte $0a, $0a, $0b, $0a

    .word MazeEntry         ;0a maze entry
    .byte $08, $08          ;invisible
    .byte %00100101
    .byte $03, $09, $09, $09

    .word MazeSide          ;0b maze side
    .byte $08, $08          ;invisible
    .byte %00100101
    .byte $09, $0c, $1c, $0d

    .word SideCorridor      ;0c (side corridor)
    .byte $98, $0a
    .byte %01100001
    .byte $1c, $0d, $1d, $0b

    .word SideCorridor      ;0d (side corridor)
    .byte $b8, $0a
    .byte %10100001
    .byte $0f, $0b, $0e, $0c

    .word TopEntryRoom      ;0e (top entry room)
    .byte $a8, $0a
    .byte %00100001
    .byte $0d, $10, $0f, $10

    .word CastleDef         ;0f white castle
    .byte $0c, $0c          ;white
    .byte %00100001
    .byte $0e, $0f, $0d, $0f

    .word CastleDef         ;10 black castle
    .byte $00, $02          ;black
    .byte %00100001
    .byte $01, $1c, $04, $1c

    .word CastleDef         ;11 yellow castle
    .byte $1a, $0a          ;yellow
    .byte %00100001
    .byte $06, $03, $02, $01

    .word NumberRoom        ;12 yellow castle entry
    .byte $1a, $0a          ;yellow
    .byte %00100001
    .byte $12, $12, $12, $12

    .word BlackMaze1        ;13 black maze #1
    .byte $08, $08          ;invisible
    .byte %00100101
    .byte $15, $14, $15, $16

    .word BlackMaze2        ;14 black maze #2
    .byte $08, $08          ;invisible
    .byte %00100100
    .byte $16, $15, $16, $13

    .word BlackMaze3        ;15 black maze #3
    .byte $08, $08          ;invisible
    .byte %00100100
    .byte $13, $16, $13, $14

    .word BlackMazeEntry    ;16 black maze entry
    .byte $08, $08          ;invisible
    .byte %00100101
    .byte $14, $13, $1b, $15

    .word RedMaze1          ;17 red maze #1
    .byte $36, $0a          ;red
    .byte %00100001
    .byte $19, $18, $19, $18

    .word RedMazeTop        ;18 top of red maze
    .byte $36, $0a          ;red
    .byte %00100001
    .byte $1a, $17, $1a, $17

    .word RedMazeBottom     ;19 bottom of red maze
    .byte $36, $0a          ;red
    .byte %00100001
    .byte $17, $1a, $17, $1a

    .word WhiteCastleEntry  ;1a white castle entry
    .byte $36, $0a          ;red
    .byte %00100001
    .byte $18, $19, $18, $19

    .word TwoExitRoom       ;1b black castle entry
    .byte $36, $0a          ;red
    .byte %00100001
    .byte $89, $89, $89, $89

    .word NumberRoom        ;1c other purple room
    .byte $66, $0a          ;purple
    .byte %00100001
    .byte $1d, $07, $8c, $08

    .word TopEntryRoom      ;1d (top entry room)
    .byte $36, $0a          ;red
    .byte %00100001
    .byte $8f, $01, $10, $03

    .word BelowYellowCastle ;1e name/secret room
    .byte $66, $0a          ;purple
    .byte %00100001
    .byte $06, $01, $06, $03

.endmacro