.struct ObjectInfoType
    room_num      .byte
    xcoord        .byte
    ycoord        .byte
.endstruct

.struct LongObjectInfoType
    .tag ObjectInfoType
    move          .byte  ; optional, not all objects use
.endstruct

.struct StateType
    state_num     .byte
.endstruct
.struct StateEntryType
    state         .tag StateType
    xcoord        .byte
    ycoord        .byte
.endstruct

.struct ObjectType
    info_ptr      .word  ; pointer to ObjectInfoType
    currstate_ptr .word  ; pointer to StateType
    states_ptr    .word  ; pointer to list of StateEntryTypes
    color         .byte
    bw            .byte  ; color in B&W
    size          .byte  ; size of object
.endstruct




.macro SurroundMacro zp
.ifnblank zp
    SurroundInfo:      .tag ObjectInfoType
.else
    SurroundCurr:      .byte 0
    SurroundStates:    .byte $ff
                       .word :+
    : surround_gfxgr_data
.endif
.endmacro

.macro DotMacro zp
.ifnblank zp
    DotInfo:           .tag ObjectInfoType
.else
    DotCurr:           .byte 0
    DotStates:         .byte $ff
                       .word :+
    : dot_gfxgr_data
.endif
.endmacro

.macro DragonMacro zp, invert
.ifnblank zp
.else
    DragonStates:
                       .byte $00
                       .word :+
                       .byte $01
                       .word :+++
                       .byte $02
                       .word :+
                       .byte $ff
                       .word :++
    : dragonnormal_gfxgr_data invert
    : dragonroar_gfxgr_data   invert
    : dragondead_gfxgr_data   invert
.endif
.endmacro

.macro Dragon1Macro
    Dragon1Info:       .tag LongObjectInfoType
    Dragon1CurrBase:   .byte 0
.endmacro

.macro Dragon2Macro
    Dragon2Info:       .tag LongObjectInfoType
    Dragon2CurrBase:   .byte 0
.endmacro

.macro Dragon3Macro
    Dragon3Info:       .tag LongObjectInfoType
    Dragon3CurrBase:   .byte 0
.endmacro

.macro MagnetMacro zp
.ifnblank zp
    MagnetInfo:        .tag ObjectInfoType
.else
    MagnetCurr:        .byte 0
    MagnetStates:      .byte $ff
                       .word :+
    :  magnet_gfxgr_data
.endif
.endmacro

.macro SwordMacro zp, invert
.ifnblank zp
    SwordInfo:         .tag ObjectInfoType
.else
    SwordCurr:         .byte 0
    SwordStates:       .byte $ff
                       .word :+
    : sword_gfxgr_data invert
.endif
.endmacro

.macro ChaliceMacro zp
.ifnblank zp
    ChaliceInfo:       .tag ObjectInfoType
.else
    ChaliceCurr:       .byte 0
    ChaliceStates:     .byte $ff
                       .word :+
    : chalice_gfxgr_data
.endif
.endmacro

.macro BridgeMacro zp
.ifnblank zp
    BridgeInfo:        .tag ObjectInfoType
.else
    BridgeCurr:        .byte 0
    BridgeStates:      .byte $ff
                       .word :+
    : bridge_gfxgr_data
.endif
.endmacro

.macro KeyMacro zp
.ifnblank zp
.else
    KeyCurr:           .byte 0
    KeyStates:         .byte $ff
                       .word :+
    : key_gfxgr_data
.endif
.endmacro

.macro YellowKeyMacro zp
.ifnblank zp
    YellowKeyInfo:     .tag ObjectInfoType
.endif
.endmacro

.macro WhiteKeyMacro zp
.ifnblank zp
    WhiteKeyInfo:      .tag ObjectInfoType
.endif
.endmacro

.macro BlackKeyMacro zp
.ifnblank zp
    BlackKeyInfo:      .tag ObjectInfoType
.endif
.endmacro

.macro PortMacro zp, info, states
.ifnblank zp
    PortCurrBase:      .byte 0, 0, 0
.endif
.ifnblank info
    PortInfo1:         .byte $11, $4d, $31       ;room 11 (4D, 31)
    PortInfo2:         .byte $0f, $4d, $31       ;room 0F (4D, 31)
    PortInfo3:         .byte $10, $4d, $31       ;room 10 (4D, 31)
.endif
.ifnblank states
    PortStates:        .byte $04                ;state 04 - open
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
                       : port_gfxgr_data
                       : port_gfxgr_data
                       : port_gfxgr_data
                       : port_gfxgr_data
                       : port_gfxgr_data
                       : port_gfxgr_data
                       : port_gfxgr_data
                       port_gfxgr_data
                       .byte 0
.endif
.endmacro

.macro BlackBatMacro zp
.ifnblank zp
    BlackBatInfo:          .tag LongObjectInfoType
    BlackBatCurrBase:      .byte 0
    BlackBatCarriedObject: .byte 0      ; object being carried by the Black Bat
    BlackBatFedUp:         .byte 0
.else
    BatStates:             .byte $03
                           .word :+
                           .byte $ff
                           .word :++
    : bat1_gfxgr_data
    : bat2_gfxgr_data
.endif
.endmacro

.macro EasterEgg original
.ifnblank original
    : easteregg_gfxgr_data norm,
.endif
    EasterEggInfo:         .byte $1e, $50, $69       ;room 1E (50, 69)
    EasterEggCurr:         .byte 0
    EasterEggStates:       .byte $ff
.ifnblank original
                           .word :-
.else
                           .word :+
    : easteregg_gfxgr_data ,alt
.endif
.endmacro

.macro NullMacro
    NullCurr:              .byte 0
    NullStates:            .byte $ff
                           .word :+
    : null_gfxgr_data
.endmacro

.macro NumberMacro zp, gfx1, gfx2, gfx3
.ifnblank zp
    NumberCurrBase:        .byte 0
.else
    NumberInfo:            .byte $00, $50, $40       ;room 00 (50,40)
    NumberStates:          .byte $01
    .ifnblank gfx1
                           .word gfx1
    .else
                           .word :+
    .endif
                           .byte $03
    .ifnblank gfx2
                           .word gfx2
    .else
                           .word :++
    .endif
                           .byte $ff
    .ifnblank gfx3
                           .word gfx3
    .else
                           .word :+++
    .endif
    .ifblank gfx1
        : number1_gfxgr_data
        : number2_gfxgr_data
        : number3_gfxgr_data
    .endif
.endif
.endmacro

.macro ObjectsMacro
    Objects:

; 00 invisible surround offsets
    .word SurroundInfo
    .word SurroundCurr
    .word SurroundStates
    .byte $28, $0c
    .byte 7

; 01 portcullis #1
    .word PortInfo1
    .word PortCurrBase+0
    .word PortStates
    .byte 0, 0; black
    .byte 0

; 02 portcullis #2
    .word PortInfo2
    .word PortCurrBase+1
    .word PortStates
    .byte 0, 0; black
    .byte 0

; 03 portcullis #3
    .word PortInfo3
    .word PortCurrBase+2
    .word PortStates
    .byte 0, 0; black
    .byte 0

; 04 name
    .word EasterEggInfo
    .word EasterEggCurr
    .word EasterEggStates
    .byte $cb, 0 ; flash
    .byte 0

; 05 number
    .word NumberInfo
    .word NumberCurrBase
    .word NumberStates
    .byte $c8, 0 ; green
    .byte 0

; 06 dragon #1 (aka, "Rhindle")
    .word Dragon1Info
    .word Dragon1CurrBase
    .word DragonStates
    .byte $36, $0e ; red
    .byte 0

; 07 dragon #2 (aka, "Yorgle")
    .word Dragon2Info
    .word Dragon2CurrBase
    .word DragonStates
    .byte $1a, $06 ; yellow
    .byte 0

; 08 dragon #3 (aka,"Grundle")
    .word Dragon3Info
    .word Dragon3CurrBase
    .word DragonStates
    .byte $c8, 0 ; green
    .byte 0

; 09 sword
    .word SwordInfo
    .word SwordCurr
    .word SwordStates
    .byte $1a, $06 ; yellow
    .byte 0

; 0a bridge
    .word BridgeInfo
    .word BridgeCurr
    .word BridgeStates
    .byte $66, $02 ; purple
    .byte $07

; 0b key #01
    .word YellowKeyInfo
    .word KeyCurr
    .word KeyStates
    .byte $1a, $06 ; yellow
    .byte 0

; 0c key #02
    .word WhiteKeyInfo
    .word KeyCurr
    .word KeyStates
    .byte $0e, $0e ; white
    .byte 0

; 0d key #03
    .word BlackKeyInfo
    .word KeyCurr
    .word KeyStates
    .byte 0, 0 ; black
    .byte 0

; 0e black bat (aka, "Knubberrub")
    .word BlackBatInfo
    .word BlackBatCurrBase
    .word BatStates
    .byte 0, 0 ; black
    .byte 0

; 0f black dot
    .word DotInfo
    .word DotCurr
    .word DotStates
    .byte $08, $08 ; light gray
    .byte 0

; 10 enchanted chalice (aka, "Holy Grail")
    .word ChaliceInfo
    .word ChaliceCurr
    .word ChaliceStates
    .byte $cb, $06 ; flash
    .byte 0

; 11 magnet
    .word MagnetInfo
    .word MagnetCurr
    .word MagnetStates
    .byte $00, $06 ; black
    .byte 0

; 12 null
    .word BridgeInfo
    .word NullCurr
    .word NullStates
    .byte 0, 0 ; black
    .byte 0
.endmacro