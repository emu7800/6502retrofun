.enum ColorType
    black       = $00
    lightgray   = $08
    invisible   = ColorType::lightgray
    darkwhite   = $0c
    white       = $0e
    yellow      = $1a
    orange      = $28
    red         = $36
    purple      = $66
    blue        = $86
    lightblue   = $98
    turquoise   = $a8
    lightgreen  = $b8
    green       = $c8
    flash       = $cb
    darkgreen   = $d8
    darkyellow  = $e8
.endenum

.enum BWColorType
    black       = $00
    darkergray  = $02
    darkgray    = $06
    invisible   = $08
    lightgray   = $0a
    lightergray = $0c
    white       = $0e
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
