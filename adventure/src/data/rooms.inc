color_black       = $00
color_invisible   = $08
color_white       = $0c
color_yellow      = $1a
color_red         = $36
color_purple      = $66
color_blue        = $86
color_lightblue   = $98
color_turquoise   = $a8
color_lightgreen  = $b8
color_green       = $c8
color_darkgreen   = $d8
color_darkyellow  = $e8

bw_color_0        = $02
bw_color_1        = $08
bw_color_2        = $0a
bw_color_3        = $0c

pf_control_leftthinwall  = %10000000
pf_control_rightthinwall = %01000000
pf_control_4bl           = %00100000
pf_control_pfp           = %00000100
pf_control_ref           = %00000001

.struct RoomTableEntry
    gfx_ptr     .word
    color       .byte
    bw_color    .byte
    pf_control  .byte
    room_up     .byte
    room_right  .byte
    room_down   .byte
    room_left   .byte
.endstruct

.macro RoomsTableMacro

Rooms:
roomnum_NumberRoom = (* - Rooms) / .sizeof(RoomTableEntry)
    .word NumberRoom
    .byte color_purple, bw_color_2
    .byte pf_control_4bl | pf_control_ref
    .byte roomnum_NumberRoom, roomnum_NumberRoom, roomnum_NumberRoom, roomnum_NumberRoom

roomnum_BelowYellowCastleLeftThinWall = (* - Rooms) / .sizeof(RoomTableEntry)
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
    .byte color_darkgreen, bw_color_2
    .byte pf_control_leftthinwall | pf_control_4bl | pf_control_ref
    .byte roomnum_BlueMazeEntry, roomnum_BelowYellowCastle, roomnum_downfrom_BelowYellowCastleLeftThinWall, roomnum_BelowYellowCastleRightThinWall

roomnum_BelowYellowCastle = (* - Rooms) / .sizeof(RoomTableEntry)
    .word BelowYellowCastle
    .byte color_green, bw_color_2
    .byte pf_control_4bl | pf_control_ref
    .byte roomnum_YellowCastle, roomnum_BelowYellowCastleRightThinWall, roomnum_downfrom_BelowYellowCastleGreen, roomnum_BelowYellowCastleLeftThinWall

roomnum_BelowYellowCastleRightThinWall = (* - Rooms) / .sizeof(RoomTableEntry)
    .word LeftOfName
    .byte color_darkyellow, bw_color_2
    .byte pf_control_rightthinwall | pf_control_4bl | pf_control_ref
    .byte roomnum_BlueMazeBottom, roomnum_BelowYellowCastleLeftThinWall, roomnum_downfrom_BelowYellowCastleRightThinWall, roomnum_BelowYellowCastle

roomnum_BlueMazeTop = (* - Rooms) / .sizeof(RoomTableEntry)
    .word BlueMazeTop
    .byte color_blue, bw_color_2
    .byte pf_control_4bl | pf_control_ref
    .byte roomnum_BlackCastle, roomnum_BlueMaze1, roomnum_BlueMazeCenter, roomnum_BlueMazeBottom

roomnum_BlueMaze1 = (* - Rooms) / .sizeof(RoomTableEntry)
    .word BlueMaze1
    .byte color_blue, bw_color_2
    .byte pf_control_4bl | pf_control_ref
    .byte roomnum_TopEntryRoom2, roomnum_BlueMazeBottom, roomnum_BlueMazeEntry, roomnum_BlueMazeTop

roomnum_BlueMazeBottom = (* - Rooms) / .sizeof(RoomTableEntry)
    .word BlueMazeBottom
    .byte color_blue, bw_color_2
    .byte pf_control_4bl | pf_control_ref
    .byte roomnum_BlueMazeCenter, roomnum_BlueMazeTop, roomnum_BelowYellowCastleRightThinWall, roomnum_BlueMaze1

roomnum_BlueMazeCenter = (* - Rooms) / .sizeof(RoomTableEntry)
    .word BlueMazeCenter
    .byte color_blue, bw_color_2
    .byte pf_control_4bl | pf_control_ref
    .byte roomnum_BlueMazeTop, roomnum_BlueMazeEntry, roomnum_BlueMazeBottom, roomnum_BlueMazeEntry

roomnum_BlueMazeEntry = (* - Rooms) / .sizeof(RoomTableEntry)
    .word BlueMazeEntry
    .byte color_blue, bw_color_2
    .byte pf_control_4bl | pf_control_ref
    .byte roomnum_BlueMaze1, roomnum_BlueMazeCenter, roomnum_BelowYellowCastleLeftThinWall, roomnum_BlueMazeCenter

roomnum_MazeMiddle = (* - Rooms) / .sizeof(RoomTableEntry)
    .word MazeMiddle
    .byte color_invisible, bw_color_1
    .byte pf_control_4bl | pf_control_pfp | pf_control_ref
    .byte roomnum_MazeEntry, roomnum_MazeEntry, roomnum_MazeSide, roomnum_MazeEntry

roomnum_MazeEntry = (* - Rooms) / .sizeof(RoomTableEntry)
    .word MazeEntry
    .byte color_invisible, bw_color_1
    .byte pf_control_4bl | pf_control_pfp | pf_control_ref
    .byte roomnum_BelowYellowCastleRightThinWall, roomnum_MazeMiddle, roomnum_MazeMiddle, roomnum_MazeMiddle

roomnum_MazeSide = (* - Rooms) / .sizeof(RoomTableEntry)
    .word MazeSide
    .byte color_invisible, bw_color_1
    .byte pf_control_4bl | pf_control_pfp | pf_control_ref
    .byte roomnum_MazeMiddle, roomnum_SideCorridor1, roomnum_OtherPurpleRoom, roomnum_SideCorridor2

roomnum_SideCorridor1 = (* - Rooms) / .sizeof(RoomTableEntry)
    .word SideCorridor
    .byte color_lightblue, bw_color_2
    .byte pf_control_rightthinwall | pf_control_4bl | pf_control_ref
    .byte roomnum_OtherPurpleRoom, roomnum_SideCorridor2, roomnum_TopEntryRoom2, roomnum_MazeSide

roomnum_SideCorridor2 = (* - Rooms) / .sizeof(RoomTableEntry)
    .word SideCorridor
    .byte color_lightgreen, bw_color_2
    .byte pf_control_leftthinwall | pf_control_4bl | pf_control_ref
    .byte roomnum_WhiteCastle, roomnum_MazeSide, roomnum_TopEntryRoom1, roomnum_SideCorridor1

roomnum_TopEntryRoom1 = (* - Rooms) / .sizeof(RoomTableEntry)
    .word TopEntryRoom
    .byte color_turquoise, bw_color_2
    .byte pf_control_4bl | pf_control_ref
    .byte roomnum_SideCorridor2, roomnum_BlackCastle, roomnum_WhiteCastle, roomnum_BlackCastle

roomnum_WhiteCastle = (* - Rooms) / .sizeof(RoomTableEntry)
    .word CastleDef
    .byte color_white, bw_color_3
    .byte pf_control_4bl | pf_control_ref
    .byte roomnum_TopEntryRoom1, roomnum_WhiteCastle, roomnum_SideCorridor2, roomnum_WhiteCastle

roomnum_BlackCastle = (* - Rooms) / .sizeof(RoomTableEntry)
    .word CastleDef
    .byte color_black, bw_color_0
    .byte pf_control_4bl | pf_control_ref
    .byte roomnum_BelowYellowCastleLeftThinWall, roomnum_OtherPurpleRoom, roomnum_BlueMazeTop, roomnum_OtherPurpleRoom

roomnum_YellowCastle = (* - Rooms) / .sizeof(RoomTableEntry)
    .word CastleDef
    .byte color_yellow, bw_color_2
    .byte pf_control_4bl | pf_control_ref
    .byte roomnum_BlueMazeBottom, roomnum_BelowYellowCastleRightThinWall, roomnum_BelowYellowCastle, roomnum_BelowYellowCastleLeftThinWall

roomnum_YellowCastleEntry = (* - Rooms) / .sizeof(RoomTableEntry)
roomrange_blackkey_end = roomnum_YellowCastleEntry
    .word NumberRoom
    .byte color_yellow, bw_color_2
    .byte pf_control_4bl | pf_control_ref
    .byte roomnum_YellowCastleEntry, roomnum_YellowCastleEntry, roomnum_YellowCastleEntry, roomnum_YellowCastleEntry

roomnum_BlackMaze1 = (* - Rooms) / .sizeof(RoomTableEntry)
roomrange_chalice_start = roomnum_BlackMaze1
    .word BlackMaze1
    .byte color_invisible, bw_color_1
    .byte pf_control_4bl | pf_control_pfp | pf_control_ref
    .byte roomnum_BlackMaze3, roomnum_BlackMaze2, roomnum_BlackMaze3, roomnum_BlackMazeEntry

roomnum_BlackMaze2 = (* - Rooms) / .sizeof(RoomTableEntry)
    .word BlackMaze2
    .byte color_invisible, bw_color_1
    .byte pf_control_4bl | pf_control_pfp
    .byte roomnum_BlackMazeEntry, roomnum_BlackMaze3, roomnum_BlackMazeEntry, roomnum_BlackMaze1

roomnum_BlackMaze3 = (* - Rooms) / .sizeof(RoomTableEntry)
    .word BlackMaze3
    .byte color_invisible, bw_color_1
    .byte pf_control_4bl | pf_control_pfp
    .byte roomnum_BlackMaze1, roomnum_BlackMazeEntry, roomnum_BlackMaze1, roomnum_BlackMaze2

roomnum_BlackMazeEntry = (* - Rooms) / .sizeof(RoomTableEntry)
roomrange_whitekey_end = roomnum_BlackMazeEntry
    .word BlackMazeEntry
    .byte color_invisible, bw_color_1
    .byte pf_control_4bl | pf_control_pfp | pf_control_ref
    .byte roomnum_BlackMaze2, roomnum_BlackMaze1, roomnum_BlackCastleEntry, roomnum_BlackMaze3

roomnum_RedMaze1 = (* - Rooms) / .sizeof(RoomTableEntry)
    .word RedMaze1
    .byte color_red, bw_color_2
    .byte pf_control_4bl | pf_control_ref
    .byte roomnum_RedMazeBottom, roomnum_RedMazeTop, roomnum_RedMazeBottom, roomnum_RedMazeTop

roomnum_RedMazeTop = (* - Rooms) / .sizeof(RoomTableEntry)
    .word RedMazeTop
    .byte color_red, bw_color_2
    .byte pf_control_4bl | pf_control_ref
    .byte roomnum_WhiteCastleEntry, roomnum_RedMaze1, roomnum_WhiteCastleEntry, roomnum_RedMaze1

roomnum_RedMazeBottom = (* - Rooms) / .sizeof(RoomTableEntry)
    .word RedMazeBottom
    .byte color_red, bw_color_2
    .byte pf_control_4bl | pf_control_ref
    .byte roomnum_RedMaze1, roomnum_WhiteCastleEntry, roomnum_RedMaze1, roomnum_WhiteCastleEntry

roomnum_WhiteCastleEntry = (* - Rooms) / .sizeof(RoomTableEntry)
roomrange_chalice_end = roomnum_WhiteCastleEntry
    .word WhiteCastleEntry
    .byte color_red, bw_color_2
    .byte pf_control_4bl | pf_control_ref
    .byte roomnum_RedMazeTop, roomnum_RedMazeBottom, roomnum_RedMazeTop, roomnum_RedMazeBottom

roomnum_BlackCastleEntry = (* - Rooms) / .sizeof(RoomTableEntry)
    .word TwoExitRoom
    .byte color_red, bw_color_2
    .byte pf_control_4bl | pf_control_ref
    .byte roomnum_uprightdownleftfrom_BlackCastleEntry, roomnum_uprightdownleftfrom_BlackCastleEntry, roomnum_uprightdownleftfrom_BlackCastleEntry, roomnum_uprightdownleftfrom_BlackCastleEntry

roomnum_OtherPurpleRoom = (* - Rooms) / .sizeof(RoomTableEntry)
    .word NumberRoom
    .byte color_purple, bw_color_2
    .byte pf_control_4bl | pf_control_ref
    .byte roomnum_TopEntryRoom2, roomnum_BlueMazeCenter, roomnum_downfrom_OtherPurpleRoom, roomnum_BlueMazeEntry

roomnum_TopEntryRoom2 = (* - Rooms) / .sizeof(RoomTableEntry)
roomrange_reddragon_end    = roomnum_TopEntryRoom2
roomrange_yellowdragon_end = roomnum_TopEntryRoom2
roomrange_greendragon_end  = roomnum_TopEntryRoom2
roomrange_sword_end        = roomnum_TopEntryRoom2
roomrange_bridge_end       = roomnum_TopEntryRoom2
roomrange_yellowkey_end    = roomnum_TopEntryRoom2
roomrange_bat_end          = roomnum_TopEntryRoom2
roomrange_magnet_end       = roomnum_TopEntryRoom2

    .word TopEntryRoom
    .byte color_red, bw_color_2
    .byte pf_control_4bl | pf_control_ref
    .byte roomnum_upfrom_TopEntryRoom, roomnum_BelowYellowCastleLeftThinWall, roomnum_BlackCastle, roomnum_BelowYellowCastleRightThinWall

roomnum_SecretRoom = (* - Rooms) / .sizeof(RoomTableEntry)
    .word BelowYellowCastle
    .byte color_purple, bw_color_2
    .byte pf_control_4bl | pf_control_ref
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

.endmacro
