; Stock C64 NTSC/PAL RS-232 userport driver

            .setcpu "6502"

            .include "cbm_kernal.inc"

            .import rs232_userport_newmodem_funcs_setup
            .import rs232_userport_newmodem_funcs_disable

            .export rs232_userport_funcs_setup   := setup
            .export rs232_userport_funcs_open    := open_modem_device
            .export rs232_userport_funcs_close   := close_modem_device
            .export rs232_userport_funcs_getchar := getchar_from_modem_device
            .export rs232_userport_funcs_putchar := putchar_to_modem_device

modem_file_no    = 128
modem_device_no  = 2
palnts           = $02a6  ; RS-232: PAL/NTSC switch, for selecting baud rate tables: 0=NTSC, 1=PAL

            .code

setup:      ; a: baud_rate: 0=300, 1=1200, 2=2400
            pha
            jsr rs232_userport_newmodem_funcs_setup
            pla

            asl a
            ldy palnts              ; NTSC or PAL?
            beq :+
            clc
            adc #pal_baud_offset
:           tay
            lda baud,y
            sta serial_config+2
            lda baud+1,y
            sta serial_config+3
            rts

open_modem_device:
            jsr close_modem_device
            lda #4                 ; filename length
            ldx #<serial_config
            ldy #>serial_config
            jsr SETNAM
            lda #modem_file_no
            ldx #modem_device_no
            ldy #3
            jsr SETLFS
            jsr OPEN
            jmp CLRCHN

close_modem_device:
            jsr rs232_userport_newmodem_funcs_disable
            lda #modem_file_no
            jmp CLOSE

getchar_from_modem_device:
            jsr CLRCHN
            ldx #modem_file_no
            jsr CHKIN
            jmp GETIN

putchar_to_modem_device:
            pha
            jsr CLRCHN
            ldx #modem_file_no
            jsr CHKOUT
            pla
            jmp CHROUT


            .rodata

ntsc_clock_freq = 1022727
pal_clock_freq  =  985248

baud:
ntsc_baud:
            .word ntsc_clock_freq/ 300/2 - 100  ; 300
            .word ntsc_clock_freq/1200/2 - 100  ; 1200
            .word ntsc_clock_freq/2400/2 - 100  ; 2400

pal_baud:
            .word pal_clock_freq / 300/2 - 100  ; 300
            .word pal_clock_freq /1200/2 - 100  ; 1200
            .word pal_clock_freq /2400/2 - 100  ; 2400

pal_baud_offset = pal_baud - ntsc_baud


            .data

serial_config:
            .byte 0     ; 1 stopbit, 8 bit wordsize
            .byte 0     ; full duplex, no parity
            .byte 0, 0  ; baud rate lo, hi
