.org 0x00060000
.text

start:
	LDI.dw IX, 0x00060400
	LDI.dw EX2, 1
	LDI.dw EX3, 8
	LOD.dw A1, [0x00030104]
	CALLR A1
    LDI.B XL1, 0x01
    STR.B XL1, [0x00020019]
    LDI.DW IX, msg_welcome
    CALL print_string
    LOD.DW EX1, [0x00020028]
    STR.DW EX1, [boot_unix]
    LDI.DW IX, prompt
    CALL print_string
    LDI.DW EX2, 0

loop:
    LOD.B XL1, [0x0002000B]
    CMP.B XL1, 0
    JMP.EQ loop
    CMP.B XL1, 13
    JMP.EQ handle_enter
    CMP.B XL1, 8
    JMP.EQ handle_backspace
    CMP.DW EX2, 127
    JMP.GE loop
    LDI.DW IX, cmd_buf
    ADD IX, EX2
    STR.B XL1, [IX]
    INC EX2
    STR.B XL1, [0x00020018]
    JMA loop

handle_enter:
    LDI.DW IX, cmd_buf
    ADD IX, EX2
    LDI.B XL1, 0
    STR.B XL1, [IX]
    LDI.B XL1, 10
    STR.B XL1, [0x00020018]
    LDI.B XL1, 13
    STR.B XL1, [0x00020018]
    CALL parse_command
    LDI.DW EX2, 0
    LDI.DW IX, prompt
    CALL print_string
    JMA loop

handle_backspace:
    CMP.DW EX2, 0
    JMP.EQ loop
    DEC EX2
    LDI.B XL1, 8
    STR.B XL1, [0x00020018]
    LDI.B XL1, ' '
    STR.B XL1, [0x00020018]
    LDI.B XL1, 8
    STR.B XL1, [0x00020018]
    JMA loop

parse_command:
    CMP.DW EX2, 0
    JMP.EQ pc_ret

    LDI.DW IX, cmd_buf
    LDI.DW IY, kw_help
    CALL check_word
    CMP.DW EX4, 0
    JMP.EQ do_help

    LDI.DW IX, cmd_buf
    LDI.DW IY, kw_qmark
    CALL check_word
    CMP.DW EX4, 0
    JMP.EQ do_help

    LDI.DW IX, cmd_buf
    LDI.DW IY, kw_clear
    CALL check_word
    CMP.DW EX4, 0
    JMP.EQ do_clear

    LDI.DW IX, cmd_buf
    LDI.DW IY, kw_cls
    CALL check_word
    CMP.DW EX4, 0
    JMP.EQ do_clear

    LDI.DW IX, cmd_buf
    LDI.DW IY, kw_echo
    CALL check_word
    CMP.DW EX4, 0
    JMP.EQ do_echo

    LDI.DW IX, cmd_buf
    LDI.DW IY, kw_ver
    CALL check_word
    CMP.DW EX4, 0
    JMP.EQ do_ver

    LDI.DW IX, cmd_buf
    LDI.DW IY, kw_about
    CALL check_word
    CMP.DW EX4, 0
    JMP.EQ do_about

    LDI.DW IX, cmd_buf
    LDI.DW IY, kw_ram
    CALL check_word
    CMP.DW EX4, 0
    JMP.EQ do_ram

    LDI.DW IX, cmd_buf
    LDI.DW IY, kw_uptime
    CALL check_word
    CMP.DW EX4, 0
    JMP.EQ do_uptime

    LDI.DW IX, cmd_buf
    LDI.DW IY, kw_time
    CALL check_word
    CMP.DW EX4, 0
    JMP.EQ do_time

    LDI.DW IX, cmd_buf
    LDI.DW IY, kw_date
    CALL check_word
    CMP.DW EX4, 0
    JMP.EQ do_date

    LDI.DW IX, cmd_buf
    LDI.DW IY, kw_rtc
    CALL check_word
    CMP.DW EX4, 0
    JMP.EQ do_rtc

    LDI.DW IX, msg_unknown
    CALL print_string
pc_ret:
    RET

do_help:
    LDI.DW IX, msg_help
    CALL print_string
    RET

do_clear:
    LDI.B XL1, 0x01
    STR.B XL1, [0x00020019]
    RET

do_echo:
de_skip:
    LOD.B XL1, [IX]
    CMP.B XL1, ' '
    JMP.NE de_print
    INC IX
    JMA de_skip
de_print:
    CALL print_string
    LDI.B XL1, 10
    STR.B XL1, [0x00020018]
    LDI.B XL1, 13
    STR.B XL1, [0x00020018]
    RET

do_ver:
    LDI.DW IX, msg_ver
    CALL print_string
    RET

do_about:
    LDI.DW IX, msg_about
    CALL print_string
    RET

do_ram:
    LOD.DW EX1, [0x0002000C]
    CALL print_dec_dw
    LDI.DW IX, msg_mb
    CALL print_string
    RET

do_uptime:
    LOD.DW EX1, [0x00020028]
    LOD.DW EX2, [boot_unix]
    SUB EX1, EX2
    CALL print_dec_dw
    LDI.DW IX, msg_s
    CALL print_string
    RET

do_time:
    LOD.B XL1, [0x00020022]
    CALL print_dec2
    LDI.B XL1, ':'
    STR.B XL1, [0x00020018]
    LOD.B XL1, [0x00020021]
    CALL print_dec2
    LDI.B XL1, ':'
    STR.B XL1, [0x00020018]
    LOD.B XL1, [0x00020020]
    CALL print_dec2
    LDI.DW IX, msg_crlf
    CALL print_string
    RET

do_date:
    LOD.B XL1, [0x00020027]
    LDI.DW EX2, 0xFF
    AND EX1, EX2
    LDI.DW EX2, 10
    MUL EX1, EX2
    CALL print_dec2
    LOD.B XL1, [0x00020025]
    CALL print_dec2
    LDI.B XL1, '-'
    STR.B XL1, [0x00020018]
    LOD.B XL1, [0x00020024]
    CALL print_dec2
    LDI.B XL1, '-'
    STR.B XL1, [0x00020018]
    LOD.B XL1, [0x00020023]
    CALL print_dec2
    LDI.DW IX, msg_crlf
    CALL print_string
    RET

do_rtc:
    LOD.DW EX1, [0x00020028]
    CALL print_dec_dw
    LDI.DW IX, msg_crlf
    CALL print_string
    RET

check_word:
    PUSH EX1
    PUSH EX3
    LDI.DW EX1, 0
    LDI.DW EX3, 0
cw_loop:
    LOD.B XL3, [IY]
    CMP.DW EX3, 0
    JMP.EQ cw_end_kw

    LOD.B XL1, [IX]
    CMP EX1, EX3
    JMP.NE cw_fail

    INC IX
    INC IY
    JMA cw_loop

cw_end_kw:
    LOD.B XL1, [IX]
    CMP.DW EX1, 0
    JMP.EQ cw_ok
    CMP.DW EX1, 0x20
    JMP.EQ cw_ok
cw_fail:
    LDI.DW EX4, 1
    POP EX3
    POP EX1
    RET
cw_ok:
    LDI.DW EX4, 0
    POP EX3
    POP EX1
    RET

print_string:
    PUSH EX1
ps_loop:
    LOD.B XL1, [IX]
    CMP.B XL1, 0
    JMP.EQ ps_done
    STR.B XL1, [0x00020018]
    INC IX
    JMA ps_loop
ps_done:
    POP EX1
    RET

print_hex_nibble:
    PUSH EX6
    PUSH EX7
    CMP.DW EX5, 10
    JMP.GE phn_alpha
    LDI.DW EX6, '0'
    ADD EX5, EX6
    JMP phn_emit
phn_alpha:
    LDI.DW EX6, 'A'
    LDI.DW EX7, 10
    SUB EX5, EX7
    ADD EX5, EX6
phn_emit:
    STR.B XL5, [0x00020018]
    POP EX7
    POP EX6
    RET

print_hex_byte:
    PUSH EX1
    PUSH EX2
    PUSH EX5
    PUSH EX6
    PUSH EX7
    LDI.DW EX2, 0x0F
    COPY EX5, EX1
    LSR EX5, 4
    AND EX5, EX2
    CALL print_hex_nibble
    COPY EX5, EX1
    AND EX5, EX2
    CALL print_hex_nibble
    POP EX7
    POP EX6
    POP EX5
    POP EX2
    POP EX1
    RET

print_hex_dword:
    PUSH EX1
    PUSH EX2
    PUSH EX5
    PUSH EX6
    PUSH EX7
    LDI.DW EX2, 0x0F

    COPY EX7, EX1
    LSR EX7, 28
    AND EX7, EX2
    COPY EX5, EX7
    CALL print_hex_nibble

    COPY EX7, EX1
    LSR EX7, 24
    AND EX7, EX2
    COPY EX5, EX7
    CALL print_hex_nibble

    COPY EX7, EX1
    LSR EX7, 20
    AND EX7, EX2
    COPY EX5, EX7
    CALL print_hex_nibble

    COPY EX7, EX1
    LSR EX7, 16
    AND EX7, EX2
    COPY EX5, EX7
    CALL print_hex_nibble

    COPY EX7, EX1
    LSR EX7, 12
    AND EX7, EX2
    COPY EX5, EX7
    CALL print_hex_nibble

    COPY EX7, EX1
    LSR EX7, 8
    AND EX7, EX2
    COPY EX5, EX7
    CALL print_hex_nibble

    COPY EX7, EX1
    LSR EX7, 4
    AND EX7, EX2
    COPY EX5, EX7
    CALL print_hex_nibble

    COPY EX7, EX1
    AND EX7, EX2
    COPY EX5, EX7
    CALL print_hex_nibble

    POP EX7
    POP EX6
    POP EX5
    POP EX2
    POP EX1
    RET

print_dec2:
    PUSH EX1
    PUSH EX2
    PUSH EX3
    LDI.DW EX2, 0xFF
    AND EX1, EX2
    COPY EX3, EX1
    LDI.DW EX2, 10
    DIV EX1, EX2
    LDI.DW EX2, '0'
    ADD EX1, EX2
    STR.B XL1, [0x00020018]
    COPY EX1, EX3
    LDI.DW EX2, 10
    REM EX1, EX2
    LDI.DW EX2, '0'
    ADD EX1, EX2
    STR.B XL1, [0x00020018]
    POP EX3
    POP EX2
    POP EX1
    RET

print_dec_dw:
    PUSH EX1
    PUSH EX2
    PUSH EX3
    PUSH EX4
    PUSH EX5
    LDI.DW EX3, 0
pd_collect:
    LDI.DW EX2, 10
    COPY EX4, EX1
    DIV EX1, EX2
    REM EX4, EX2
    PUSH EX4
    INC EX3
    CMP.DW EX1, 0
    JMP.NE pd_collect
pd_emit:
    POP EX1
    LDI.DW EX2, '0'
    ADD EX1, EX2
    STR.B XL1, [0x00020018]
    DEC EX3
    CMP.DW EX3, 0
    JMP.NE pd_emit
    POP EX5
    POP EX4
    POP EX3
    POP EX2
    POP EX1
    RET

byteswap:
    PUSH EX2
    PUSH EX3
    PUSH EX4
    PUSH EX5
    LDI.DW EX5, 0xFF
    COPY EX2, EX1
    LSR EX2, 24
    AND EX2, EX5
    COPY EX3, EX1
    LSR EX3, 16
    AND EX3, EX5
    LSL EX3, 8
    COPY EX4, EX1
    LSR EX4, 8
    AND EX4, EX5
    LSL EX4, 16
    AND EX1, EX5
    LSL EX1, 24
    OR EX1, EX2
    OR EX1, EX3
    OR EX1, EX4
    POP EX5
    POP EX4
    POP EX3
    POP EX2
    RET

.data

prompt:      .DB "> ", 0
kw_help:     .DB "help", 0
kw_qmark:    .DB "?", 0
kw_clear:    .DB "clear", 0
kw_cls:      .DB "cls", 0
kw_echo:     .DB "echo", 0
kw_ver:      .DB "ver", 0
kw_about:    .DB "about", 0
kw_ram:      .DB "ram", 0
kw_uptime:   .DB "uptime", 0
kw_time:     .DB "time", 0
kw_date:     .DB "date", 0
kw_rtc:     .DB "rtc", 0

msg_welcome: .DB "OS v0.1", 10, 13, "Type 'help' for commands.", 10, 13, 0
msg_help:    .DB "Commands:", 10, 13
             .DB "  help, ?     this help", 10, 13
             .DB "  clear, cls  clear screen", 10, 13
             .DB "  echo TEXT   print text", 10, 13
             .DB "  ver         version", 10, 13
             .DB "  about       about", 10, 13
             .DB "  ram         RAM size", 10, 13
             .DB "  uptime      timer ticks", 10, 13
             .DB "  time        RTC HH:MM:SS", 10, 13
             .DB "  date        RTC YYYY-MM-DD", 10, 13
             .DB "  rtc        RTC raw time", 10, 13, 0
msg_unknown: .DB "Unknown command. Try 'help'.", 10, 13, 0
msg_ver:     .DB "OS 0.1", 10, 13, 0
msg_about:   .DB "OS for i80148, written by TheCawa.", 10, 13, 0
msg_mb:      .DB " MB", 10, 13, 0
msg_s:       .DB " s", 10, 13, 0
msg_crlf:    .DB 10, 13, 0

boot_unix:   .DD 0

cmd_buf:
    .DD 0,0,0,0,0,0,0,0
    .DD 0,0,0,0,0,0,0,0
    .DD 0,0,0,0,0,0,0,0
    .DD 0,0,0,0,0,0,0,0