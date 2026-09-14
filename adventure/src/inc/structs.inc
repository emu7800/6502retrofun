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

.struct ObjectDynamicType
    room          .byte
    xcoord        .byte  ; ObjectPosType
    ycoord        .byte  ;
.endstruct

.struct DragonDynamicType
    room          .byte  ; ObjectDynamicType
    xcoord        .byte  ;
    ycoord        .byte  ;
    move          .byte
    state         .byte
.endstruct

.struct BlackBatDynamicType
    room          .byte  ; DragonDynamicType
    xcoord        .byte  ;
    ycoord        .byte  ;
    move          .byte  ;
    state         .byte  ;
    carriedobject .byte
    fedup         .byte
.endstruct

.struct StateType
    state         .byte
    xcoord        .byte  ; ObjectPosType
    ycoord        .byte  ;
.endstruct

.struct ObjectType
    dynamic_ptr   .word  ; pointer to a DynamicType
    currstate_ptr .word  ; pointer to a state byte
    states_ptr    .word  ; pointer to array of StateType
    color         .byte  ; ColorType
    bw_color      .byte  ; BWColorType
    size          .byte
.endstruct
