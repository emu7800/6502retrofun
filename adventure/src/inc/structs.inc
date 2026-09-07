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

.struct ObjectRoomPosType
    room          .byte
    pos           .tag ObjectPosType
.endstruct

.struct ObjectRoomPosMoveType
    roompos       .tag ObjectRoomPosType
    move          .byte
.endstruct

.struct StateType
    state         .byte
    pos           .tag ObjectPosType
.endstruct

.struct ObjectType
    roompos_ptr   .word  ; pointer to a ObjectRoomPosType
    currstate_ptr .word  ; pointer to a state
    states_ptr    .word  ; pointer to list of StateType
    color         .byte  ; ColorType
    bw_color      .byte  ; BWColorType
    size          .byte
.endstruct
