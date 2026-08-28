.struct RoomType
    gfx_ptr     .word
    color       .byte ; ColorType enum
    bw_color    .byte ; BWColorType enum
    pf_control  .byte
    room_up     .byte
    room_right  .byte
    room_down   .byte
    room_left   .byte
.endstruct

.struct ObjectPosType
    xcoord        .byte
    ycoord        .byte
.endstruct

.struct ObjectInfoType
    room_num      .byte
    pos           .tag ObjectPosType
.endstruct

.struct LongObjectInfoType
    .tag ObjectInfoType
    move          .byte
.endstruct

.struct StateType
    state_num     .byte
    pos           .tag ObjectPosType
.endstruct

.struct ObjectType
    info_ptr      .word  ; pointer to a ObjectInfoType
    currstate_ptr .word  ; pointer to a state_num
    states_ptr    .word  ; pointer to list of StateType
    color         .byte  ; ColorType
    bw_color      .byte  ; BWColorType
    size          .byte
.endstruct
