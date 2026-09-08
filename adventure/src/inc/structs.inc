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
    xcoord        .byte  ; ObjectPosType
    ycoord        .byte  ;
.endstruct

.struct StateType
    state         .byte
    xcoord        .byte  ; ObjectPosType
    ycoord        .byte  ;
.endstruct

.struct ObjectRoomPosMoveType
    room          .byte  ; ObjectRoomPosType
    xcoord        .byte  ; ObjectPosType
    ycoord        .byte  ;
    move          .byte
.endstruct

.struct DragonDynamicType
    room          .byte  ; ObjectRoomPosMoveType
    xcoord        .byte  ;
    ycoord        .byte  ;
    move          .byte  ;
    state         .byte
.endstruct

.struct BlackBatDynamicType
    room          .byte  ; ObjectRoomPosMoveType
    xcoord        .byte  ;
    ycoord        .byte  ;
    move          .byte  ;
    state         .byte
    carriedobject .byte
    fedup         .byte
.endstruct

.struct ObjectType
    roompos_ptr   .word  ; pointer to a ObjectRoomPosType or DragonDynamicType
    currstate_ptr .word  ; pointer to a state
    states_ptr    .word  ; pointer to list of StateType
    color         .byte  ; ColorType
    bw_color      .byte  ; BWColorType
    size          .byte
.endstruct
