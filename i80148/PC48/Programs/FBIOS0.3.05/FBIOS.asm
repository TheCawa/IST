.org 0x00000000

.text
init:
	CLI
	LDI.dw IX, 0x00020019
	LDI.b XL1, 0x05
	STR.b XL1, [IX]
	LDI.b XL1, 0x03
	STR.b XL1, [IX]
	LDI.b XL1, 0x07
	STR.b XL1, [IX+2]
	; LDI.b XL1, 0x12 ; Graphic mode
	STR.b R0, [IX+1]
	LDI.b XL1, 0x01
	STR.b XL1, [IX]
	LDI.dw SP, 0x0004FF00
	LDI.dw BP, 0x00047F80

idtr_init:
	LDI.dw IDTR, 0x00010000
	LDI.b A0, 0x13
	LSL A0, 2
	LDI.dw EX1, disk_isr
	STR.dw EX1, [IDTR:A0]
	
main:
	LDI.dw IX, msg_init
	CALL print
	LDI.dw IX, msg_ram
	CALL print
	CALL memtest
	LDI.dw IX, msg_kb_ok
	CALL print
	
	; Список устройств
	LOD.b EX7, [0x0002001A]
	CMP.b EX7, 0x10
	JMP.NE skip40x30
	
	LDI.dw IX, msg_dev_list_30
	CALL print
	LDI.dw IX, msg_dl_header_30
	CALL print
	LDI.dw IX, msg_dl_hr_30
	CALL print
	JMP skip80x
	
skip40x30:
	LDI.dw IX, msg_dev_list
	CALL print
	
	LDI.b XL7, 205
	LDI.b XL6, 24
	CALL print_unary
	
	LDI.dw IX, msg_dl_high_corner
	CALL print
	
	LDI.dw IX, msg_dl_header
	CALL print
	
	; LDI.b XL7, 0xC3
	; STR.b XL7, [0x00020018]
	LDI.b XL7, 196
	LDI.b XL6, 43
	CALL print_unary
	
	LDI.dw IX, msg_dl_hr
	CALL print
	
skip80x:
	LDI.dw IX, 0x00020000 ; MMIO Base
	LDI.dw IY, 0x00010400 ; CMOS Base
	XOR A7, A7 ; Slot pointer
	INC A7
	LDI.dw A5, 4 ; Amount of slots
	
slot_l:
	LDI.b XL1, 179
	STR.b XL1, [0x00020018]
	LDI.b XL1, 0x20
	STR.b XL1, [0x00020018]
	
	XOR FL, FL
	COPY EX1, A7
	LDI.b XL6, 4
	CALL h2a
	
	LDI.b XL7, 0x20
	LDI.b XL6, 3
	CALL print_unary
	
	COPY A6, A7
	LSL A6, 8
	LOD.dw EX7, [IX+A6]
	
	; Device recording
	PUSH A7
	LSL A7, 2
	STR.dw EX7, [IY+A7]
	POP A7
	
	; A0 - Flags
	; A1 - Device class
	; A2 - Vendor ID
	COPY A0, XL7
	COPY A1, EX7
	LSR A1, 8
	COPY A2, A1
	LSR A2, 8
	
	; Class ID
	COPY XL1, A1
	LDI.b XL6, 2
	CALL h2a
	
	LDI.b XL7, 0x20
	LDI.b XL6, 4
	CALL print_unary
	
	; Vendor ID
	COPY XL1, A2
	LDI.b XL6, 2
	CALL h2a
	
	LDI.b XL7, 0x20
	LDI.b XL6, 4
	CALL print_unary
	
	; Device Flags
	COPY XL1, A0
	LDI.b XL6, 2
	CALL h2a
	
	LDI.b XL7, 0x20
	LDI.b XL6, 2
	CALL print_unary
	LDI.b XL1, 0x2D
	STR.b XL1, [0x00020018]
	LDI.b XL1, 0x20
	STR.b XL1, [0x00020018]
	
	; Name
	PUSH EX7
	LDI.dw EX7, 0x000000FF
	AND A1, EX7
	POP EX7
	
	CMP.b A1, 0x05
	JMP.GR dv_unknown
	MUL.dw A1, 12
	LDI.dw IX, dev_none
	ADD IX, A1
	CALL print
	JMP dl_nend

dv_unknown:
	LDI.dw IX, dev_unknown
	CALL print
	
dl_nend:
	LOD.b EX7, [0x0002001A]
	CMP.b EX7, 0x10
	JMP.NE use_stub
	LDI.b XL1, 0x7C
	STR.b XL1, [0x00020018]
	JMP skip_stub
	
use_stub:
	LDI.dw IX, dev_80stub
	CALL print
	LDI.b XL1, 179
	STR.b XL1, [0x00020018]
	
skip_stub:
	LDI.b XL1, 10
	STR.b XL1, [0x00020018]
	INC A7
	DEC A5
	JMP.NZ slot_l
	
	PUSH EX7
	LOD.b EX7, [0x0002001A]
	CMP.b EX7, 0x10
	JMP.NE skip40x30dhr
	LDI.dw IX, msg_dl_hr_30
	CALL print
	JMP skip80xdhr
skip40x30dhr:
	LDI.b XL7, 0xD4
	STR.b XL7, [0x00020018]
	LDI.b XL7, 205
	LDI.b XL6, 43
	CALL print_unary
	
	LDI.dw IX, msg_dl_low_corner
	CALL print
skip80xdhr:
	POP EX7
 ; making disk calls - INT 13h
	LDI.dw IY, rd_disk
	STR.dw IY, [0x00030104]
	LDI.dw IY, wr_disk
	STR.dw IY, [0x00030108]
	
	LDI.dw A7, 0x00020068
	LDI.dw A6, 0x0002006C
	LOD.dw EX1, [A7]
	LOD.dw EX2, [A6]
	
	PUSH EX1
	PUSH EX2
	PUSH EX3

	LOD.dw EX1, [A7-8]
	LOD.dw EX3, [A7-4]
	SUB.dw EX3, 4
	STR.dw EX3, [A6]
	LDI.dw IX, msg_press_del
	CALL print
	
	POP EX3
	POP EX2
	POP EX1
	
	STR.dw EX1, [A7]
	STR.dw EX2, [A6]
	
	CALL disk_listing
	LDI.b XL1, 0x0A
	STR.dw XL1, [0x00020018]
	
wait_del:
	PUSH EX7
	PUSH EX1
	LDI.dw EX7, 4000
	STR.dw EX7, [0x00020031]
wait_del_l:
	XOR FL, FL
	LOD.b XL1, [0x0002000B]
	CMP.b XL1, 0x7F
	JMP.EQ del_pressed
	CMP.b XL1, 0x09
	JMP.EQ tab_pressed
	CMP.b XL1, 0x0D
	JMP.EQ enter_pressed
	LOD.dw EX7, [0x00020031]
	CMP.dw EX7, 1000
	JMP.GR wait_del_l
	POP EX1
	POP EX7
	JMP boot
del_pressed:
	LOD.dw EX1, [0x00010C20]
	LDI.dw EX7, 0x00000001
	AND EX1, EX7
	CMP EX1, R0
	JMP.EQ del_pressed_skip0
	CALL enter_password
	INC A1
	CALL check_password
del_pressed_skip0:
	POP EX1
	POP EX7
	JMP setup_utility
tab_pressed:
	POP EX1
	POP EX7
	JMP boot_menu
enter_pressed:
	POP EX1
	POP EX7
	
boot:
	CALL find_disk
	CALL clr_gpr
	
	LDI.dw IX, dsk_loading
	CALL print

	LDI.dw IX, 0x00060000
	XOR A0, A0
	COPY EX2, R0
	LDI.dw EX3, 1
	LOD.dw A1, [0x00030104]
	CALLR A1
	; LDI.dw EX1, 0x00000001
	; INT 0x13
	CMP EX1, R0
	JMP.NE disk_read_error
	
	; Delay
	LDI.dw EX7, 2000
	STR.dw EX7, [0x00020031]
cbios_delay:
	LOD.dw EX7, [0x00020031]
	CMP.dw EX7, 1000
	JMP.GR cbios_delay
	LDI.b XL1, 0x01
	STR.B XL1, [0x00020019]
	JMA 0x00060000
	
disk_read_error:
	; LDI.b XL1, 0x0A
	; STR.b XL1, [0x00020018]
	LDI.dw IX, dsk_error
	CALL print
	HALT
	
disk_timeout:
	; LDI.b XL1, 0x0A
	; STR.dw XL1, [0x00020018]
	LDI.dw IX, dsk_timeout
	CALL print
	HALT
	
disk_not_found:
	LDI.dw IX, dsk_missing
	CALL print
	HALT
	
find_disk:
	XOR EX3, EX3
find_disk_l:
	STR.dw EX3, [0x00020116]
	LOD.dw EX2, [0x00020100]
	LDI.dw EX5, 0x000000FF
	AND EX2, EX5
	CMP.b XL2, 0x01
	JMP.EQ find_disk_end
	INC EX3
	CMP.b XL3, 3
	JMP.GR disk_not_found
	JMP find_disk_l
find_disk_end:
	LOD.dw EX2, [0x00020110]
	CMP XL2, R0
	JMP.NE disk_st_error
	RET
	
disk_listing:
	XOR EX3, EX3
disk_listing_l:
	STR.dw EX3, [0x00020116]
	COPY EX4, EX3
	ADD.b XL4, 0x30
	LDI.dw IX, dsk_try
	CALL print
	STR.b XL4, [0x00020018]
	LDI.dw IX, ppp
	CALL print
	LOD.dw EX2, [0x00020100]
	LDI.dw EX5, 0x000000FF
	AND EX2, EX5
	CMP.b XL2, 0x01
	JMP.EQ disk_listing_present
disk_listing_empty:
	LDI.dw IX, boot_menu_empty
	CALL print
	LDI.b XL1, 0x0A
	STR.b XL1, [0x00020018]
	JMP disk_listing_skip0
disk_listing_present:
	LDI.dw IX, boot_menu_present
	CALL print
	LDI.b XL1, 0x0A
	STR.b XL1, [0x00020018]
disk_listing_skip0:
	INC EX3
	CMP.b XL3, 3
	JMP.GR disk_listing_end
	JMP disk_listing_l
disk_listing_end:
	RET
	
disk_st_error:
	; LDI.b XL1, 0x0A
	; STR.b XL1, [0x00020018]
	LDI.dw IX, dsk_st_err
	CALL print
	HALT
	
print:
	PUSH FL
	PUSH EX1
print_l:
	LOD.b XL1, [IX]
	CMP XL1, R0
	JMP.EQ print_done
	STR.b XL1, [0x00020018]
	INC IX
	JMP print_l
print_done:
	POP EX1
	POP FL
	RET
	
h2a:
	; EX1 - input
	PUSH FL
	PUSH EX2 ; char
	PUSH EX7 ; mask
	PUSH EX3
	LDI.dw EX7, 0x0000000F
	ROL EX1, 4
	COPY EX3, EX6 
h2a_shift:
	XOR FL, FL
	ROR EX1, 4
	DEC EX3
	JMP.NZ h2a_shift
h2a_l:
	XOR FL, FL
	XOR EX2, EX2
	COPY EX2, EX1
	ROL EX1, 4
	AND EX2, EX7
	CMP.b XL2, 10
	JMP.GE h2a_check
	ADD.b XL2, 0x30
	JMP h2a_print
h2a_check:
	ADD.b XL2, 0x37
h2a_print:
	STR.b XL2, [0x00020018]
	XOR FL, FL
	DEC EX6
	JMP.NZ h2a_l
	POP FL
	POP EX2
	POP EX7
	POP EX3
	XOR EX1, EX1
	RET
	
memtest:
	XOR EX1, EX1
	XOR EX4, EX4
	LOD.dw EX1, [0x0002000C]
	LSR EX1, 10
	COPY EX3, EX1
mt_h2d:
	XOR FL, FL
	INC EX4
	COPY EX2, EX3
	DIV.dw EX3, 10
	REM.dw EX2, 10
	COPY EX1, EX2
	ADD.b XL1, 0x30
	PUSH XL1
	CMP.dw EX3, 0x00000000
	JMP.NZ mt_h2d
mt_decout:
	DEC EX4
	POP XL1
	STR.b XL1, [0x00020018]
	JMP.NZ mt_decout
	CALL clr_gpr
	RET
	
rd_disk:
	LDI.dw A1, 0x00020111
	XOR A7, A7
	XOR A0, A0
	XOR EX5, EX5
	XOR EX7, EX7
	LDI.dw EX4, 256
rd_disk_l:
	STR.dw EX2, [A1+1]
	LDI.b XL7, 2
	STR.dw EX7, [A1]
	LDI.dw EX6, 0x0000FFFF
rd_disk_wait:
	LOD.dw EX7, [A1-1]
	LDI.b XL5, 1
	AND EX7, EX5
	CMP EX7, R0
	JMP.EQ rd_disk_ready
	DEC EX6
	CMP EX6, R0
	JMP.NE rd_disk_wait
	XOR EX1, EX1
	DEC EX1
	JMP.NE disk_timeout
rd_disk_ready:
	LDI.b XL7, 1
	STR.b XL7, [A1]
	STR.dw R0, [A1]
rd_disk_rdata:
	STR.dw A7, [0x0002011C]
	LOD.dw EX1, [0x0002011A]
	STR.dw EX1, [IX:A0]
	ADD.dw A7, 4
	ADD.dw A0, 4
	DEC EX4
	JMP.NZ rd_disk_rdata
	LDI.dw EX4, 256
	ADD IX, A0
	XOR A0, A0
	INC EX2
	DEC EX3
	JMP.NZ rd_disk_l
	COPY EX1, R0
	CALL clr_gpr
	RET

wr_disk:
	XOR A7, A7
	; LDI.dw A7, 0xFFFFFFFC
	XOR EX7, EX7
	LDI.dw A1, 0x00020111
	LDI.w X4, 256
	XOR A0, A0
wr_disk_loop:
	STR.dw EX2, [0x00020112]
wr_disk_wrdata:
	XOR FL, FL
	STR.dw A7, [0x0002011C]
	LOD.dw EX1, [IX:A0]
	LDI.b XL7, 8
	STR.dw EX1, [0x0002011B]
	STR.dw EX7, [A1]
	XOR EX7, EX7
	STR.dw EX7, [A1]
	ADD.dw A7, 4
	; STR.dw A7, [0x0002011C]
	ADD.dw A0, 4
	DEC EX4
	JMP.NZ wr_disk_wrdata
	LDI.b XL7, 4
	STR.dw EX7, [A1]
	LDI.dw EX6, 0x0000FFFF
wr_disk_wait:
	LOD.dw EX7, [0x00020110]
	LDI.b XL5, 1
	AND EX7, EX5
	CMP EX7, R0
	JMP.EQ wr_disk_ready
	DEC EX6
	CMP EX6, R0
	JMP.NE wr_disk_wait
	LDI.dw EX1, 0xFFFFFFFF
	JMP.NE disk_timeout
wr_disk_ready:
	LDI.b XL7, 1
	STR.dw EX7, [A1]
	XOR EX7, EX7
	STR.dw EX7, [A1]
	ADD IX, A0
	XOR A0, A0
	XOR A7, A7
	LDI.w X4, 256
	INC EX2
	STR.dw EX2, [0x00020112]
	DEC EX3
	JMP.NZ wr_disk_loop
wr_disk_success:
	CALL clr_gpr
	STR.dw R0, [0x0002011C]
    RET
	
; wr_disk:
	; LDI.dw A1, 0x00020111
	; XOR A7, A7
	; XOR A0, A0
	; XOR EX5, EX5
	; XOR EX7, EX7
	; LDI.dw EX4, 256
; wr_disk_l:
	; STR.dw EX2, [A1+1]
	; LDI.b XL7, 2
	; STR.dw EX7, [A1]
	; LDI.dw EX6, 0x0000FFFF
; wr_disk_wait:
	; LOD.dw EX7, [A1-1]
	; LDI.b XL5, 1
	; AND EX7, EX5
	; CMP EX7, R0
	; JMP.EQ wr_disk_ready
	; DEC EX6
	; CMP EX6, R0
	; JMP.NE wr_disk_wait
	; XOR EX1, EX1
	; DEC EX1
	; JMP.NE disk_timeout
; wr_disk_ready:
	; LDI.b XL7, 1
	; STR.b XL7, [A1]
	; STR.dw R0, [A1]
; wr_disk_rdata:
	; STR.dw A7, [0x0002011C]
	; LOD.dw EX1, [IX:A0]
	; STR.dw EX1, [0x0002011A]
	; ADD.dw A7, 4
	; ADD.dw A0, 4
	; DEC EX4
	; JMP.NZ wr_disk_rdata
	; LDI.dw EX4, 256
	; ADD IX, A0
	; XOR A0, A0
	; INC EX2
	; DEC EX3
	; JMP.NZ wr_disk_l
	; COPY EX1, R0
	; CALL clr_gpr
	; RET

; // SETUP UTILITY AND BOOT MENU //
; // SETUP UTILITY AND BOOT MENU //
; // SETUP UTILITY AND BOOT MENU //

setup_utility:
	; Clean screen
	LDI.b XL1, 0x01
	STR.b XL1, [0x00020019]
	LDI.b XL1, 0x03
	STR.b XL1, [0x00020019]
	
	LDI.dw IX, 0x00010C00
	LDI.dw IY, 0x00040080
	LDI.dw A0, 36
	CALL copy_block
	
	PUSH EX1
	PUSH EX2
	LOD.dw EX1, [0x00020060]
	LOD.dw EX2, [0x00020064]
	MUL EX1, EX2
	COPY IY, EX1
	POP EX1
	POP EX2
	
	LDI.dw A3, 0x00020068
	LDI.dw A4, 0x0002006C
	STR.dw R0, [A3] ; x = 0
	STR.dw R0, [A4] ; y = 0
	LDI.b XL2, 0x30 ; bg = 0x1, fg = 0x7
	LDI.b XL1, 0x20
	LDI.dw A7, 0x00020018
setup_fill:
	XOR FL, FL
	STR.dw EX2, [A7+3] ; 0x00002001B
	STR.b XL1, [A7]
	DEC IY
	JMP.NZ setup_fill
	STR.dw R0, [A3] ; x = 0
	STR.dw R0, [A4] ; y = 0
	LOD.dw IY, [A3-8] ; 0x00020060
	PUSH IY
setup_header:
	STR.b XL1, [A7]
	DEC IY
	JMP.NZ setup_header
	STR.dw R0, [A4]
	LOD.dw IY, [A3-8]
	LSR IY, 2
	ADD.dw IY, 10
	STR.dw IY, [A3]
	LDI.dw IX, msg_fbsu
	CALL print
	POP IY
	PUSH IY
	PUSH EX1
	LDI.dw EX1, 1
	STR.dw R0, [A3] ; x = 0
	STR.dw EX1, [A4] ; y = 1
	POP EX1
	POP IY
	LDI.b XL2, 0x17
	STR.b XL2, [A7+3]
	LDI.b XL1, 0x20
	PUSH EX2
	LOD.dw EX2, [A3-8]
cat_print:
	STR.b XL1, [A7]
	DEC EX2
	JMP.NZ cat_print
	POP EX2
	
	PUSH IY
	STR.dw R0, [A3]
	LDI.dw IX, 2
	STR.dw IX, [A4]
	LOD.dw EX3, [A3-4]
	SUB.dw EX3, 3
	MUL IY, EX3
setup_blue:
	STR.b XL2, [A7+3]
	STR.b XL1, [A7]
	DEC IY
	JMP.NZ setup_blue
	LDI.b XL2, 0x30
	STR.b XL2, [A7+3]
	LDI.b XL1, 0x20
	STR.b XL1, [A7]
	LDI.dw IX, msg_navigation
	CALL print
	
	; Drawing box
draw_lines:
	LDI.b XL1, 0x71
	STR.dw XL1, [A7+3]
	STR.dw R0, [A3]
	LDI.b XL1, 2
	STR.dw XL1, [A4]
	LDI.b XL1, 0xC9
	STR.b XL1, [A7]
	LOD.b XL6, [A3-8] ; 0x00020060
	SUB.b XL6, 0x02
	COPY XL5, XL6
	LDI.b XL7, 0xCD
	CALL print_unary
	LDI.b XL1, 0xBB
	STR.b XL1, [A7]
	
	LOD.b XL1, [A3-4] ; 0x00020064
	SUB.b XL1, 2
	STR.b XL1, [A4]
	
	LDI.b XL1, 0xC8
	STR.b XL1, [A7]
	COPY XL6, XL5
	CALL print_unary
	LDI.b XL1, 0xBC
	STR.b XL1, [A7]
	CALL draw_lr
	
	; BIOS RAM:
	; BP = 0x00040000 - tab pointer
	;      0x00 - main
	;      0x01 - advanced
	;      0x02 - boot
	;      0x03 - security
	;	   0x04 - exit
	; BP = 0x00040004 - row pointer
	; BP = 0x00040008 - setting pointer
	; BP = 0x0004000C - max rows pointer
	; BP = 0x00040010 - max settings pointer
	
setup_cat_redraw:
	LDI.dw A3, 0x00020068
	LDI.dw A4, 0x0002006C
	STR.dw R0, [A3]
	LDI.dw IX, 1
	STR.dw IX, [A4]
	LDI.b XL2, 0x17
	STR.b XL2, [0x0002001B]
	LDI.b XL1, 0x20
	STR.b XL1, [0x00020018]
	
	COPY EX6, R0
	LDI.dw IX, cat_main
check_category:
	LOD.dw EX7, [0x00040000]
	CMP EX7, EX6
	JMP.NE chkcat_ne
	LDI.b XL2, 0x71
	STR.b XL2, [0x0002001B]
chkcat_ne:
	CALL print
	LDI.b XL2, 0x17
	STR.b XL2, [0x0002001B]
	INC IX
	INC XL6
	CMP.b XL6, 0x05
	JMP.NE check_category
	LDI.b XL2, 0x71
	STR.b XL2, [0x0002001B]

	LOD.dw EX6, [0x00040000]
	CMP.dw EX6, 0x00
	JMP.EQ show_main
	CMP.dw EX6, 0x01
	JMP.EQ show_advanced
	CMP.dw EX6, 0x02
	JMP.EQ show_boot
	CMP.dw EX6, 0x03
	JMP.EQ show_security
	CMP.dw EX6, 0x04
	JMP.EQ show_exit
	JMP setup_wait_key
	
show_main:
	CALL draw_lr
	STR.dw R0, [0x0004000C] ; 0 rows maximum
	CALL set_cursor
	LDI.dw IX, cpu_name
	CALL print
	CALL b_rxiy
	LDI.dw IX, bios_ver
	CALL print
	
	CALL b_rxiy
	CALL b_rxiy
	
	LDI.dw IX, msg_mem
	CALL print
	CALL memtest
	LDI.dw IX, msg_kb_ok
	CALL print
	
	; CALL b_rxiy
	; CALL b_rxiy
	
	; CALL getcfr
	
	JMP setup_wait_key
	
show_advanced:
	CALL draw_lr
	LDI.b XL1, 1
	STR.dw XL1, [0x0004000C] ; 2 rows maximum
	CALL set_cursor
	LOD.dw A7, [0x00040004]
	CMP A7, R0
	JMP.NE show_advanced_regdump_nonsel
show_advanced_regdump:
	LDI.b XL2, 0x7F
	STR.b XL2, [0x0002001B]
show_advanced_regdump_nonsel:
	LDI.dw IX, advanced_rdump
	CALL print
	LDI.b XL2, 0x71
	STR.b XL2, [0x0002001B]
	CALL b_rxiy
	CMP.b A7, 0x01
	JMP.NE show_advanced_ncosmetics
	LDI.b XL2, 0x7F
	STR.b XL2, [0x0002001B]
show_advanced_ncosmetics:
	LDI.dw IX, bios_none
	CALL print
	
	; LDI.b XL2, 0x71
	; STR.b XL2, [0x0002001B]
	; CALL b_rxiy
	; CMP.b A7, 0x02
	; JMP.NE show_advanced_nsl
	; LDI.b XL2, 0x7F
	; STR.b XL2, [0x0002001B]
; show_advanced_nsl:
	; LDI.dw IX, advanced_sl
	; CALL print
	
	; LOD.dw EX1, [0x000400A0]
	; LDI.b XL2, 1
	; CALL chks_status
	
	; LDI.b XL2, 0x71
	; STR.b XL2, [0x0002001B]
	; CALL b_rxiy
	; CMP.b A7, 0x03
	; JMP.NE show_advanced_nsp
	; LDI.b XL2, 0x7F
	; STR.b XL2, [0x0002001B]
; show_advanced_nsp:
	; LDI.dw IX, advanced_sp
	; CALL print
	
	; LOD.dw EX1, [0x000400A0]
	; LDI.b XL2, 2
	; CALL chks_status
	
	LDI.b XL2, 0x71
	STR.b XL2, [0x0002001B]
	JMP setup_wait_key
	
show_boot:
	CALL draw_lr
	STR.dw R0, [0x0004000C] ; 0 rows maximum
	CALL set_cursor
	LDI.dw IX, boot_menu_empty
	CALL print
	JMP setup_wait_key
	
show_security:
	CALL draw_lr
	LDI.b XL1, 1
	STR.dw XL1, [0x0004000C] ; 1 rows maximum
	CALL set_cursor
	LOD.dw A7, [0x00040004]
	CMP A7, R0
	JMP.NE show_security_nsp
	LDI.b XL2, 0x7F
	STR.b XL2, [0x0002001B]
show_security_nsp:
	LDI.dw IX, security_sp
	CALL print
	LDI.b XL2, 0x71
	STR.b XL2, [0x0002001B]
	CALL b_rxiy
	
	CMP.b A7, 0x01
	JMP.NE show_security_nrqp
	LDI.b XL2, 0x7F
	STR.b XL2, [0x0002001B]
show_security_nrqp:
	LDI.dw IX, security_rqp
	CALL print
	LOD.dw EX1, [0x000400A0]
	COPY EX2, R0
	CALL chks_status
	LDI.b XL2, 0x71
	STR.b XL2, [0x0002001B]
	; CALL b_rxiy
	
	; CMP.b A7, 0x02
	; JMP.NE show_security_nnone
	; LDI.b XL2, 0x7F
	; STR.b XL2, [0x0002001B]
; show_security_nnone:
	; LDI.dw IX, bios_none
	; CALL print
	; LDI.b XL2, 0x71
	; STR.b XL2, [0x0002001B]
	JMP setup_wait_key
	
show_exit:
	CALL draw_lr
	XOR EX1, EX1
	INC EX1
	STR.dw EX1, [0x0004000C] ; 2 rows maximum
	CALL set_cursor
	
	LOD.dw A7, [0x00040004]
	CMP A7, R0
	JMP.NE show_exit_without_notsel
	LDI.b XL1, 0x7F
	STR.b XL1, [0x0002001B]
	JMP show_exit_without_notsel
	
show_exit_without_notsel:
	LDI.dw IX, exit_without
	CALL print
	STR.b XL1, [0x0002001B]
	CALL b_rxiy
	
	LDI.b XL1, 0x71
	STR.b XL1, [0x0002001B]
	
	LOD.dw A7, [0x00040004]
	CMP.dw A7, 0x00000001
	JMP.NE show_exit_sae_notsel
	LOD.b XL1, [0x0002001B]
	LDI.b XL1, 0x7F
	STR.b XL1, [0x0002001B]
	JMP show_exit_sae_notsel
	
show_exit_sae_notsel:
	LDI.dw IX, exit_sae
	CALL print
	STR.b XL1, [0x0002001B]
	JMP setup_wait_key
	
setup_wait_key:
	CALL wait_key
	LDI.dw A7, 0x00040000
	CMP.b XL7, 0x64 ; Right arrow
	JMP.EQ inc_cat_pointer
	CMP.b XL7, 0x61 ; Left arrow
	JMP.EQ dec_cat_pointer
	CMP.b XL7, 0x77 ; Up arrow
	JMP.EQ dec_row_ptr
	CMP.b XL7, 0x73 ; Даун ебаный
	JMP.EQ inc_row_ptr
	CMP.b XL7, 0x0D
	JMP.EQ enter_handler ; Handle enter
	JMP setup_wait_key
	HALT

chks_status:
	; EX1 - setting
	; EX2 - bit selection
	PUSH EX3
	XOR EX3, EX3
	INC EX3
	CMP XL2, R0
	JMP.EQ chks_status_compare
chks_status_shift:
	ROR EX1, 1
	DEC XL2
	JMP.NZ chks_status_shift
chks_status_compare:
	AND EX1, EX3
	CMP.b XL1, 1
	JMP.NE chks_status_disable
	LDI.dw IX, bios_enable
	CALL print
	JMP chks_status_end
chks_status_disable:
	LDI.dw IX, bios_disable
	CALL print
chks_status_end:
	LDI.b XL1, 0x5D
	STR.b XL1, [0x00020018]
	POP EX3
	RET

b_rxiy:
	STR.dw A0, [A3]
	INC A1
	STR.dw A1, [A4]
	RET

set_cursor:
	LDI.dw A0, 4
	LDI.dw A1, 3
	STR.dw A0, [A3]
	STR.dw A1, [A4]
	RET
	
wait_key:
	LOD.b XL7, [0x0002000B]
	CMP.b XL7, 0
	JMP.EQ wait_key
	RET
	
inc_cat_pointer:
	STR.dw R0, [A7+4]
	LOD.dw EX1, [A7]
	CMP.b XL1, 4
	JMP.GE inc_cat_overflow
	INC EX1
	STR.dw EX1, [A7]
	JMP setup_cat_redraw
inc_cat_overflow:
	STR.dw R0, [A7]
	JMP setup_cat_redraw
dec_cat_pointer:
	STR.dw R0, [A7+4]
	LOD.dw EX1, [A7]
	CMP.b XL1, 0x00
	JMP.EQ dec_cat_overflow
	DEC EX1
	STR.dw EX1, [A7]
	JMP setup_cat_redraw
dec_cat_overflow:
	LDI.dw EX1, 4
	STR.dw EX1, [A7]
	JMP setup_cat_redraw
	
dec_row_ptr:
	LOD.dw EX1, [A7+4]
	CMP.b XL1, 0x00
	JMP.EQ dec_row_overflow
	DEC EX1
	STR.dw EX1, [A7+4]
	JMP setup_cat_redraw
dec_row_overflow:
	LOD.dw EX1, [A7+12]
	STR.dw EX1, [A7+4]
	JMP setup_cat_redraw
	
inc_row_ptr:
	LOD.dw EX1, [A7+4]
	LOD.dw EX2, [A7+12]
	CMP EX1, EX2
	JMP.GE inc_row_overflow
	INC EX1
	STR.dw EX1, [A7+4]
	JMP setup_cat_redraw
inc_row_overflow:
	STR.dw R0, [A7+4]
	JMP setup_cat_redraw
	
enter_handler:
	LOD.dw EX1, [A7] ; Tab pointer
	LOD.dw EX2, [A7+4] ; Row pointer
	CMP XL1, R0
	JMP.EQ eh_main
	CMP.b XL1, 0x01
	JMP.EQ eh_advanced
	CMP.b XL1, 0x02
	JMP.EQ eh_boot
	CMP.b XL1, 0x03
	JMP.EQ eh_security
	CMP.b XL1, 0x04
	JMP.EQ eh_exit
	JMP setup_wait_key
	
eh_main:
	JMP setup_wait_key
eh_advanced:
	; LDI.dw IX, 0x000400A0
	LDI.dw A7, 0x00040000
	CMP.b XL2, 0x00
	JMP.EQ eh_advanced_func0
	CMP.b XL2, 0x01
	JMP.EQ eh_advanced_func1
	; CMP.b XL2, 0x02
	; JMP.EQ eh_advanced_func2
	; CMP.b XL2, 0x03
	; JMP.EQ eh_advanced_func3
	JMP setup_cat_redraw
eh_advanced_func0:
	CALL rdump_dialog
eh_advanced_func1:
	JMP setup_cat_redraw
; eh_advanced_func2:
	; LOD.dw EX1, [A7+160]
	; XOR EX2, EX2
	; INC EX2
	; CALL switch_bit
	; STR.dw EX1, [A7+160]
	; JMP setup_cat_redraw
; eh_advanced_func3:
	; LOD.dw EX1, [A7+160]
	; LDI.dw EX2, 2
	; CALL switch_bit
	; STR.dw EX1, [A7+160]
	; JMP setup_cat_redraw
	
eh_boot:
	JMP setup_wait_key
	
eh_security:
	LDI.dw A7, 0x000400A0
	CMP.b XL2, 0x00
	JMP.EQ eh_security_func0
	CMP.b XL2, 0x01
	JMP.EQ eh_security_func1
	JMP setup_wait_key
eh_security_func0:
	CALL enter_password
	CALL set_password
	JMP setup_cat_redraw
eh_security_func1:
	LOD.dw EX1, [A7]
	COPY EX2, R0
	CALL switch_bit
	STR.dw EX1, [A7]
	JMP setup_cat_redraw
	
eh_exit:
	LDI.dw A7, 0x00040000
	CMP.b XL2, 0x00
	JMP.EQ eh_exit_func0
	CMP.b XL2, 0x01
	JMP.EQ eh_exit_func1
	
eh_exit_func0:
	CALL confirm_dialog
	CMP XL1, R0
	JMP.EQ setup_cat_redraw
	STR.dw R0, [A7]
	STR.dw R0, [A7+8]
	STR.dw R0, [A7+12]
	LDI.b XL1, 0x07
	STR.b XL1, [0x0002001B]
	CALL clr_gpr
	JMPR R0
eh_exit_func1:
	LDI.dw IX, 0x00040080 ; temporary CMOS settings
	LDI.dw IY, 0x00010C00 ; CMOS settings
	LDI.dw A0, 36
	CALL copy_block
	; STR.dw R0, [A7]
	; STR.dw R0, [A7+8]
	; STR.dw R0, [A7+12]
	; LDI.b XL1, 0x07
	; STR.b XL1, [0x0002001B]
	CALL clr_gpr
	JMPR R0
	
enter_password:
	LDI.b XL1, 34
	LDI.b XL2, 3
	LDI.b XL4, 0x6F
	XOR EX3, EX3
	CALL print_window
	LDI.dw IX, security_msg
	CALL print
	INC A0
	STR.dw A0, [0x00020068]
	LDI.b XL1, 0x07
	STR.b XL1, [0x0002001B]
	LDI.b XL7, 0x2E
	LDI.b XL6, 32
	CALL print_unary
	STR.dw A0, [0x00020068]
	RET
	
set_password:
	LDI.dw IY, 0x00040080
	XOR A7, A7 ; offset
	XOR A6, A6
	LDI.b A6, 32
set_password_l:
	CALL wait_key
	CMP.b XL7, 0x08
	JMP.EQ set_password_del
	CMP.b XL7, 0x0D
	JMP.EQ set_password_end
	CMP.b XL7, 0x1B
	JMP.EQ set_password_exit
	CMP.b XL7, 0x21
	JMP.LS set_password_l
	CMP.b XL7, 0x7F
	JMP.EQ set_password_del
	CMP.b XL7, 0xFF
	JMP.EQ set_password_l
set_password_output:
	CMP A6, R0
	JMP.EQ set_password_l
	STR.b XL7, [IY:A7]
	STR.b XL7, [0x00020018]
	INC A7
	DEC A6
	JMP set_password_l
set_password_end:
	CMP A6, R0
	JMP.EQ set_password_end_end
set_password_end_l:
	STR.b R0, [IY:A7]
	INC A7
	DEC A6
	JMP.NZ set_password_end_l
set_password_end_end:
	RET	
	
set_password_exit:
	LDI.b A7, 32
set_password_exit_l:
	DEC A7
	STR.b R0, [IY:A7]
	JMP.NZ set_password_exit_l
	JMP set_password_end

set_password_del:
	CMP A7, R0
	JMP.EQ set_password_l
	LDI.b XL7, 0x08
	STR.b XL7, [0x00020018]
	DEC A7
	INC A6
	STR.b R0, [IY:A7]
	LDI.b XL7, 0x2E
	STR.b XL7, [0x00020018]
	LDI.b XL7, 0x08
	STR.b XL7, [0x00020018]
	JMP set_password_l
	
	
	
check_password:
	LDI.dw IY, 0x00020018
	STR.dw A0, [0x00020068]
	STR.dw A1, [0x0002006C]
	LDI.b XL7, 0x2E
	LDI.dw EX6, 32
	CALL print_unary
	STR.dw A0, [0x00020068]
	XOR A7, A7 ; offset
	XOR A6, A6
	LDI.b A6, 32
check_password_l:
	CALL wait_key
	CMP.b XL7, 0x08
	JMP.EQ check_password_del
	CMP.b XL7, 0x0D
	JMP.EQ check_password_end
	CMP.b XL7, 0x1B
	JMP.EQ check_password_exit
	CMP.b XL7, 0x21
	JMP.LS check_password_l
	CMP.b XL7, 0x7F
	JMP.EQ check_password_del
	CMP.b XL7, 0xFF
	JMP.EQ check_password_l
check_password_output:
	CMP A6, R0
	JMP.EQ check_password_l
	STR.b XL7, [BP:A7]
	STR.b XL7, [IY]
	INC A7
	DEC A6
	JMP check_password_l
check_password_end:
	CMP A6, R0
	JMP.EQ check_password_compare
check_password_end_l:
	STR.b R0, [BP:A7]
	INC A7
	DEC A6
	JMP.NZ check_password_end_l
check_password_compare:
	XOR A7, A7
	XOR A6, A6
	LDI.b XL5, 0x04
	LDI.b A6, 0x08
	LDI.dw IX, 0x00010C00
check_password_compare_l:
	LOD.dw EX1, [IX:A7]
	LOD.dw EX2, [BP:A7]
	CMP EX1, EX2
	JMP.NE check_password
	ADD A7, XL5
	DEC A6
	JMP.NZ check_password_compare_l
check_password_end_end:
	RET	
	
check_password_exit:
	LDI.b A7, 32
check_password_exit_l:
	DEC A7
	STR.b R0, [BP:A7]
	JMP.NZ check_password_exit_l
	JMPR R0

check_password_del:
	CMP A7, R0
	JMP.EQ check_password_l
	LDI.b XL7, 0x08
	STR.b XL7, [IY]
	DEC A7
	INC A6
	STR.b R0, [BP:A7]
	LDI.b XL7, 0x2E
	STR.b XL7, [IY]
	LDI.b XL7, 0x08
	STR.b XL7, [IY]
	JMP check_password_l
	
	
	
	
	
copy_block:
	; IX - src
	; IY - dist
	; A0 - count bytes
	; A1 - offset
	PUSH EX1
	PUSH A1
	XOR A1, A1
copy_block_l:
	LOD.b XL1, [IX:A1]
	STR.b XL1, [IY:A1]
	INC A1
	DEC A0
	JMP.NZ copy_block_l
	POP A1
	POP EX1
	RET
	
draw_lr:
	PUSH EX1
	PUSH EX2
	PUSH EX6
	PUSH A0
	PUSH A7
	LDI.dw A7, 0x00020060
	STR.dw R0, [A7+8] ; 0x00020068
	LDI.b XL1, 3
	STR.b XL1, [A7+12]
	LOD.dw A0, [A7+4]
	SUB.b A0, 5
draw_lr_l:
	LDI.b XL1, 0xBA
	STR.b XL1, [A7-72]
	LDI.b XL7, 0x20
	LOD.b XL6, [A7]
	SUB.b XL6, 2
	CALL print_unary
	STR.b XL1, [A7-72]
	DEC A0
	JMP.NZ draw_lr_l
	POP A7
	POP A0
	POP EX6
	POP EX2
	POP EX1
	RET

switch_bit:
	; EX1 - Bios setting
	; EX2 - Bit selector
	PUSH EX3
	XOR EX3, EX3
	INC EX3
	CMP.b XL2, R0
	JMP.EQ switch_bit_end
switch_bit_l:
	ROL EX3, 1
	DEC EX2
	JMP.NZ switch_bit_l
switch_bit_end:
	XOR EX1, EX3
	POP EX3
	RET

 ; EX1 = Answer (0 - No, 1 - Yes)
confirm_dialog:
	PUSH IX
	PUSH IY
	PUSH A0
	PUSH A1
	PUSH EX6
	PUSH EX7
	PUSH A7
	LDI.dw IY, 0x00020060
	
	XOR EX1, EX1
	XOR EX2, EX2
	XOR EX3, EX3
	XOR EX4, EX4
	
	LDI.b XL1, 26
	LDI.b XL2, 3
	LDI.b XL4, 0x4F
	CALL print_window
	INC A1
	STR.dw A1, [0x0002006C]
	LDI.dw IX, rusure
	CALL print
	LOD.dw A7, [IY+8]
	COPY EX1, R0
cdialog_wait_key:
	CALL wait_key
	CMP.b XL7, 0x79
	JMP.EQ cdialog_y
	CMP.b XL7, 0x59
	JMP.EQ cdialog_y
	CMP.b XL7, 0x4E
	JMP.EQ cdialog_n
	CMP.b XL7, 0x6E
	JMP.EQ cdialog_n
	CMP.b XL7, 0x1B
	JMP.EQ cdialog_end
	CMP.b XL7, 0x60
	JMP.EQ cdialog_end
	CMP.b XL7, 0x0D
	JMP.EQ cdialog_end
	JMP cdialog_wait_key
cdialog_y:
	LDI.b XL1, 0x01
	STR.b XL7, [0x00020018]
	STR.b A7, [IY+8]
	JMP cdialog_wait_key
cdialog_n:
	COPY XL1, R0
	STR.b XL7, [0x00020018]
	STR.b A7, [IY+8]
	JMP cdialog_wait_key
cdialog_end:
	POP A7
	POP EX7
	POP EX6
	POP A1
	POP A0
	POP IY
	POP IX
	RET
	
rdump_dialog:
	PUSH IX
	PUSH A0
	PUSH A1
	PUSH EX6
	PUSH EX7
	PUSH A7
	PUSH EX2
	
	XOR EX1, EX1
	XOR EX2, EX2
	XOR EX3, EX3
	XOR EX4, EX4
	
	LDI.b XL1, 26
	LDI.b XL2, 1
	LDI.b XL4, 0x4F
	CALL print_window
	LDI.dw IY, 0x00020060
rdump_main:
	STR.b A0, [IY+8]
	STR.b A1, [IY+12]
	LDI.dw IX, speed
	CALL print
	LDI.dw EX1, 2000
	STR.dw EX1, [0x00020031]
	XOR EX2, EX2
rdump_main_l:
	INC EX2
	LOD.B EX7, [0x0002000B]
	CMP.b XL7, 0x00
	JMP.NE rdump_end
	LOD.dw EX1, [0x00020031]
	CMP.dw EX1, 1000
	JMP.GR rdump_main_l
	XOR A7, A7
	COPY EX1, EX2
	ADD.dw EX1, 100
	DIV.dw EX1, 143
dw2dec:
	LDI.b A6, 10
	XOR A5, A5
	LDI.b XL3, 10
dw2dec_l:
	COPY EX2, EX1
	REM EX2, EX3
	DIV EX1, EX3
	ADD.b XL2, 0x30
	STR.b XL2, [BP:A5]
	INC A5
	DEC A6
	JMP.NZ dw2dec_l
	COPY A4, A5
dw2dec_out_l:
	DEC A5
	LOD.b XL1, [BP:A5]
	STR.b XL1, [0x00020018]
	JMP.NZ dw2dec_out_l
	XOR EX3, EX3
	XOR EX2, EX2
	LDI.dw IX, khz
	CALL print
	JMP rdump_main
rdump_end:
	POP EX2
	POP A7
	POP EX7
	POP EX6
	POP A1
	POP A0
	POP IX
	RET
	
print_window:
	; Inner arguments:
	; EX1 - Size X
	; EX2 - Size Y
	; EX3 - Y offset
	; EX4 - Color
	; Return:
	; A0 - Pos X
	; A1 - Pos Y
	PUSH EX6
	PUSH EX7
	PUSH A2
	PUSH A3
	PUSH A7
	LDI.dw A7, 0x00020060
	STR.b XL4, [A7-69]
	LOD.dw A0, [A7]
	LOD.dw A1, [A7+4]
	LSR A0, 1
	LSR A1, 1
	COPY EX3, EX1
	COPY EX4, EX2
	COPY A2, A0
	COPY A3, A1
	LSR EX3, 1
	LSR EX4, 1 
	SUB A0, EX3
	SUB A1, EX4
	DEC A0
	DEC A1
	STR.dw A0, [A7+8]
	STR.dw A1, [A7+12]
	LDI.b XL7, 0xDA
	STR.b XL7, [A7-72]
	LDI.b XL7, 0xC4
	COPY EX6, EX1
	COPY EX3, EX6
	CALL print_unary
	LDI.b XL7, 0xBF
	STR.b XL7, [A7-72]
	COPY EX4, EX2
print_window_l:
	LDI.b XL7, 0x0A
	STR.b XL7, [A7-72]
	STR.dw A0, [A7+8]
	LDI.b XL7, 0xB3
	STR.b XL7, [A7-72]
	LDI.b XL7, 0x20
	COPY EX6, EX3
	CALL print_unary
	LDI.b XL7, 0xB3
	STR.b XL7, [A7-72]
	DEC EX4
	JMP.NZ print_window_l
	
print_window_end:
	LDI.b XL7, 0x0A
	STR.b XL7, [A7-72]
	STR.dw A0, [A7+8]
	LDI.b XL7, 0xC0
	STR.b XL7, [A7-72]
	LDI.b XL7, 0xC4
	COPY EX6, EX3
	CALL print_unary
	LDI.b XL7, 0xD9
	STR.b XL7, [A7-72]
	INC A0
	INC A1
	STR.dw A0, [A7+8]
	STR.dw A1, [A7+12]
	
	POP A7
	POP A3
	POP A2
	POP EX7
	POP EX6
	RET

 ; ================================
 ; BOOT MENU
 ; ================================

boot_menu:
	STR.dw R0, [0x00040004]
	LDI.b XL1, 0x05
	STR.b XL1, [0x00020019]
	LDI.b XL1, 0x03
	STR.b XL1, [0x00020019]
	STR.dw R0, [0x00040004]
	STR.dw EX1, [0x0004000C]
	
	XOR A0, A0
	XOR A1, A1
	XOR A2, A2
	CALL clr_gpr

	LDI.b XL1, 0x07
	STR.b XL1, [0x0002001B]
	LDI.b XL1, 0x01
	STR.b XL1, [0x00020019]
	LOD.dw EX1, [0x00020060] ; X
	LOD.dw EX2, [0x00020064] ; Y
	LSR EX1, 1
	LSR EX2, 1
	SUB.dw EX1, 18
	SUB.dw EX2, 8
	
	PUSH EX1
	PUSH EX2
	INC EX1
	INC EX2
	
	LDI.dw A3, 0x00020068
	LDI.dw A4, 0x0002006C
	
	STR.dw EX1, [A3]
	STR.dw EX2, [A4]
	
	COPY EX3, EX1 ; Backup pos X
	
	LDI.b XL6, 0x08
	STR.b XL6, [0x0002001B]
	LDI.b XL7, 0xB0 ; 0xB0
	
	LDI.dw A0, 36
	LDI.dw A1, 10
	COPY A2, A0 ; Backup res X
	PUSH A0
	PUSH A1
	PUSH A2
	
bm_print_shadow:
	XOR FL, FL
	STR.dw EX1, [A3]
	STR.dw EX2, [A4]
	STR.b XL7, [0x00020018]
	INC EX1
	DEC A0
	CMP A0, R0
	JMP.NE bm_print_shadow
	COPY EX1, EX3
	COPY A0, A2
	INC EX2
	DEC A1
	CMP A1, R0
	JMP.NE bm_print_shadow
	
	POP A2
	POP A1
	POP A0
	POP EX2
	POP EX1
	PUSH EX1
	PUSH EX2
	
	COPY EX3, EX1
	PUSH EX3
	LDI.b XL6, 0x30
	STR.b XL6, [0x0002001B]
	
bm_print_blue:
	XOR FL, FL
	STR.dw EX1, [A3]
	STR.dw EX2, [A4]
	STR.b XL7, [0x00020018]
	INC EX1
	DEC A0
	CMP A0, R0
	JMP.NE bm_print_blue
	COPY EX1, EX3
	COPY A0, A2
	INC EX2
	DEC A1
	CMP A1, R0
	JMP.NE bm_print_blue
	
	POP EX3
	POP EX2
	POP EX1
	STR.dw EX1, [A3]
	STR.dw EX2, [A4]
	LDI.b XL7, 0xC9
	STR.b XL7, [0x00020018]
	LDI.b XL7, 0xCD
	LDI.b XL6, 11
	CALL print_unary
	
	PUSH EX1
	PUSH EX2
	LDI.dw IX, boot_menu_head
	CALL print
	POP EX2
	POP EX1
	
	LDI.b XL7, 0xCD
	LDI.b XL6, 10
	CALL print_unary
	
	LDI.b XL7, 0xBB
	STR.b XL7, [0x00020018]
	
	CALL rxiy
	
	PUSH EX1
	PUSH EX2
	LDI.dw IX, boot_menu_msg
	CALL print
	POP EX2
	POP EX1
	
	CALL rxiy
	CALL prhr
	
	LDI.b XL4, 4
bm_print_lr:
	LDI.b XL7, 0xBA
	STR.b XL7, [0x00020018]
	LDI.b XL7, 0x20
	LDI.b XL6, 34
	CALL print_unary
	LDI.b XL7, 0xBA
	STR.b XL7, [0x00020018]
	CALL rxiy
	DEC XL4
	JMP.NZ bm_print_lr
	
	CALL prhr
	
	PUSH EX1
	PUSH EX2
	LDI.dw IX, boot_menu_navigation
	CALL print
	POP EX2
	POP EX1
	CALL rxiy
	
	LDI.b XL7, 0xC8
	STR.b XL7, [0x00020018]
	LDI.b XL7, 0xCD
	LDI.b XL6, 34
	CALL print_unary
	LDI.b XL7, 0xBC
	STR.b XL7, [0x00020018]
	
bm_disk_list:
	LOD.dw EX1, [0x00020060]
	LOD.dw EX2, [0x00020064]
	LSR EX1, 1
	LSR EX2, 1
	SUB.dw EX1, 18
	SUB.dw EX2, 8
	ADD.dw EX1, 2
	ADD.dw EX2, 3
	STR.dw EX1, [A3]
	STR.dw EX2, [A4]
	COPY EX5, EX1
	
	LDI.dw IY, 0x00040000
	LOD.dw EX2, [IY+12]
	XOR EX3, EX3
bm_disk_loop:
	LOD.dw EX4, [IY+4]
	CMP EX4, EX3
	JMP.EQ bm_disk_sel
	JMP bm_disk_nonsel
bm_disk_sel:
	PUSH EX1
	LDI.b XL1, 0x4F
	STR.b XL1, [0x0002001B]
	POP EX1
bm_disk_nonsel:
	XOR EX4, EX4
	LDI.dw IX, boot_menu_disk
	CALL print
	STR.dw EX3, [0x00020116]
	COPY EX1, EX3
	ADD.b XL1, 0x30
	STR.b XL1, [0x00020018]
	LDI.dw IX, boot_menu_stub
	CALL print
	LOD.dw EX1, [0x00020100]
	INC EX4
	AND EX1, EX4
	CMP XL1, XL4
	JMP.EQ bm_disk_present
	LDI.dw IX, boot_menu_empty
	CALL print
	JMP bm_disk_empty
bm_disk_present:
	LDI.dw IX, boot_menu_present
	CALL print
bm_disk_empty:
	LDI.b XL7, 0x20
	LDI.b XL6, 16
	CALL print_unary
	LDI.b XL2, 0x0A
	STR.b XL2, [0x00020018]
	INC EX3
	STR.dw EX5, [A3]
	LOD.dw EX4, [IY+12]
	CMP EX3, EX4
	PUSH EX1
	LDI.b XL1, 0x30
	STR.b XL1, [0x0002001B]
	POP EX1
	JMP.LE bm_disk_loop
	
bm_disk_end:
	CALL rxiy
	
bm_wait_key:
	LDI.dw A7, 0x00040000
	CALL wait_key
	CMP.b XL7, 0x77 ; Up arrow
	JMP.EQ bm_dec_row_ptr
	CMP.b XL7, 0x73 ; Даун ебаный
	JMP.EQ bm_inc_row_ptr
	CMP.b XL7, 0x0D
	JMP.EQ bm_handle_enter
	JMP bm_wait_key
	HALT
	
print_unary:
	PUSH FL
print_unary_l:
	XOR FL, FL
	STR.b XL7, [0x00020018]
	DEC XL6
	JMP.NZ print_unary_l
	POP FL
	RET
	
rxiy:
	COPY EX1, EX3
	INC EX2
	STR.dw EX1, [0x00020068]
	STR.dw EX2, [0x0002006C]
	RET
	
prhr:
	LDI.b XL7, 0xC7
	STR.b XL7, [0x00020018]
	LDI.b XL7, 0xC4
	LDI.b XL6, 34
	CALL print_unary
	LDI.b XL7, 0xB6
	STR.b XL7, [0x00020018]
	CALL rxiy
	RET
	
bm_dec_row_ptr:
	LOD.dw EX1, [A7+4]
	CMP.b XL1, 0x00
	JMP.EQ bm_dec_row_overflow
	DEC EX1
	STR.dw EX1, [A7+4]
	JMP bm_disk_list
bm_dec_row_overflow:
	LOD.dw EX1, [A7+12]
	STR.dw EX1, [A7+4]
	JMP bm_disk_list
	
bm_inc_row_ptr:
	LOD.dw EX1, [A7+4]
	LOD.dw EX2, [A7+12]
	CMP EX1, EX2
	JMP.GE bm_inc_row_overflow
	INC EX1
	STR.dw EX1, [A7+4]
	JMP bm_disk_list
bm_inc_row_overflow:
	STR.dw R0, [A7+4]
	JMP bm_disk_list
	
bm_handle_enter:
	LDI.dw EX7, 0x0002001B
	STR.dw R0, [0x00020068]
	XOR EX1, EX1
	INC EX1
	STR.dw EX1, [0x0002006C]
	LDI.b XL1, 0x07
	STR.b XL1, [EX7]
	LOD.dw A7, [IY+4]
	STR.dw A7, [0x00020116]
	LOD.dw EX1, [0x00020100]
	XOR EX4, EX4
	INC EX4
	AND EX1, EX4
	CMP.b XL1, 0x01
	JMP.EQ bm_load
	LDI.b XL1, 0x07
	STR.b XL1, [EX7]
	LDI.dw IX, boot_menu_dskmiss
	CALL print
	LDI.b XL1, 0x70
	STR.b XL1, [EX7]
	LDI.b XL1, 0x30
	STR.b XL1, [EX7]
	JMP bm_disk_list
	
bm_load:
	LDI.b XL7, 0x20
	LDI.b XL6, 34
	CALL print_unary
	STR.dw R0, [0x00020068]
	LDI.dw IX, boot_menu_booting
	CALL print
	LDI.b XL1, 10
	STR.b XL1, [0x00020018]
	LDI.dw IX, boot_menu_waitsome
	CALL print
	
	LDI.dw EX1, 2000
	LDI.dw IX, 0x00020031
	STR.dw EX1, [IX]
bm_pit:
	LOD.dw EX1, [IX]
	CMP.dw EX1, 1000
	JMP.GR bm_pit
	
	LDI.b XL1, 10
	STR.b XL1, [0x00020018]
	
	CALL clr_gpr
	CALL bm_boot
	
bm_boot:
	CALL chkdsk_presence
	CALL clr_gpr
	
	LDI.dw IX, dsk_loading
	CALL print

	LDI.dw IX, 0x00060000
	XOR A0, A0
	COPY EX2, R0
	LDI.dw EX3, 1
	LOD.dw A1, [0x00030104]
	CALLR A1
	; LDI.dw EX1, 0x00000001
	; INT 0x13
	CMP EX1, R0
	JMP.NE disk_read_error
	
	; Delay
	LDI.dw EX7, 2000
	STR.dw EX7, [0x00020031]
bm_cbios_delay:
	LOD.dw EX7, [0x00020031]
	CMP.dw EX7, 1000
	JMP.GR bm_cbios_delay
	LDI.b XL1, 0x01
	STR.B XL1, [0x00020019]
	JMA 0x00060000
	
chkdsk_presence:
	LOD.dw EX2, [0x00020100]
	LDI.dw EX5, 0x000000FF
	AND EX2, EX5
	CMP.b XL2, 0x01
	JMP.NE disk_not_found
	LOD.dw EX2, [0x00020110]
	CMP XL2, R0
	JMP.NE disk_st_error
	RET
	
clr_gpr:
	XOR EX1, EX1
	XOR EX2, EX2
	XOR EX3, EX3
	XOR EX4, EX4
	XOR EX5, EX5
	XOR EX6, EX6
	XOR EX7, EX7
	XOR FL, FL
	RET
	
disk_isr:
	CLI
	PUSH EX5
	PUSH EX6
	PUSH EX7
	PUSH A0
	PUSH A1
	PUSH A2
	PUSH A7
	
	; LOD.dw A2, [0x00020116]
	; STR.dw EX4, [0x00020116]
	
	CMP EX1, R0
	JMP.EQ disk_isr_end
	CMP.b EX1, 0x01
	JMP.EQ disk_isr_rd
	CMP.b EX1, 0x02
	JMP.EQ disk_isr_wr
	JMP disk_isr_end
	
disk_isr_rd:	
	; LOD.dw A1, [0x00030104]
	; CALLR A1
	CALL rd_disk
	JMP disk_isr_end
	
disk_isr_wr:
	; LOD.dw A1, [0x00030108]
	; CALLR A1
	CALL wr_disk

disk_isr_end:
	; STR.dw A2, [0x00020116]
	POP A7
	POP A2
	POP A1
	POP A0
	POP EX7
	POP EX6
	POP EX5
	IRET


.data
buffer: .db 0, 0, 0, 0
msg_init: .db 10, "FBIOS v0.3.05", 10, 10, 0

msg_press_del: .db "Press [DEL] to enter SETUP", 10
msg_press_tab: .db "Press [TAB] to enter BOOT MENU", 10
msg_press_enter: .db "Press [ENTER] for BOOT", 0

; msg_undcon: .db "Under construction", 0
msg_fbsu: .db "FBIOS SETUP UTILITY", 0
msg_navigation: .db "W/A/S/D/Enter/Esc/`", 0

; Графические режим
; t80x25: .db "Text, 80x25, 16 colors", 10, 0
; t40x30: .db "Text, 40x30, 16 colors", 10, 0
; t80x60: .db "Text, 80x60, 16 colors", 10, 0
; t80x30: .db "Text, 80x30, 16 colors", 10, 0
; t_unknown: .db "UNKNOWN", 10, 0

; ОЗУ и единицы измерения memtest
msg_mem: .db "Memory   : ", 0
msg_ram: .db "RAM : ", 0
msg_kb_ok: .db "KB", 10, 10, 0

; Дисковые сообщения
dsk_loading: .db "Starting system disk . . .", 0
dsk_error: .db 10, "Disk read error!", 0
dsk_timeout: .db 10, "Disk timed out!", 0
dsk_missing: .db "No bootable disk found!", 0
dsk_st_err: .db 10, "Disk status error!", 0

dsk_try: .db " - Disk#", 0
ppp: .db " ............... ", 0

; Заголовок списка устройств
msg_dev_list: .db 0xD5, 205, "XPB Device listing", 0
msg_dl_header: .db 179, " SLOT - Cid - Vid - Flg - Name             ", 179, 10, 0xC3, 0
msg_dl_hr: .db 180, 10, 0
msg_dl_high_corner: .db 0xB8, 10, 0
msg_dl_low_corner: .db 0xBE, 10, 0

; Заголовок списка устройств, для режима 40x30
msg_dev_list_30: .db "*=XPB Device listing==================*", 10, 0
msg_dl_header_30: .db "| SLOT - Cid - Vid - Flg - Name       |", 10, 0
msg_dl_hr_30: .db "+-------------------------------------+", 10, 0

; Классы устройств
dev_none: .db "None       ", 0
; dev_system: .db "System     ", 0
dev_storage: .db "Storage    ", 0
dev_input: .db "Input      ", 0
dev_timer: .db "Timer      ", 0
dev_rtc: .db "RTC        ", 0
dev_video: .db "Video      ", 0
dev_unknown: .db "Unknown    ", 0
dev_80stub: .db 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0

; Данные для BIOS
rusure: .db " Are you sure? (Y/N) - ", 0
cpu_name: .db "CPU      : i80148", 0
bios_ver: .db "BIOS     : FBIOS v0.3.05", 0

bios_disable: .db "Disabled", 0
bios_enable: .db "Enabled", 0

cat_main: .db " Main ", 0 
cat_advanced: .db " Advanced ", 0
cat_boot: .db " Boot ", 0
cat_security: .db " Security ", 0
cat_exit: .db " Exit ", 0

boot_seldisk: .db 0x0F, "Select disk for boot", 0

exit_without: .db "> Exit without saving", 0
exit_sae: .db "> Save and exit", 0

advanced_rdump: .db "> View CPU frequency", 0
; advanced_sl: .db "  Test0 - [", 0 ; Show BIOS Logo - [
; advanced_sp: .db "  Test1 - [", 0 ; Hide POST-screen - [
; advanced_cosmetics: .db "> Cosmetics", 0
bios_none: .db "  None", 0

security_sp: .db "> Set BIOS password", 0
security_rqp: .db "  Request password - [", 0
security_msg: .db " Enter password:", 10, 0

speed: .db "Frequency ", 0xF7, 0x20, 0
khz: .db " kHz", 0

boot_menu_head: .db "  Boot menu  ", 0
boot_menu_msg: .db 0xBA, "       Select bootable disk       ", 0xBA, 0
boot_menu_navigation: .db 0xBA, " W/S/Up/Down                      ", 0xBA, 0
boot_menu_disk: .db "disk#", 0
boot_menu_stub: .db " - ", 0
boot_menu_empty: .db "empty  ", 0
boot_menu_present: .db "present", 0
boot_menu_error: .db "ERROR  ", 0
boot_menu_booting: .db "Booting from ", 0
boot_menu_waitsome: .db "Wait...", 0
boot_menu_dskmiss: .db "Disk is missing, try another disk!", 0

;    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; 1 ⁠ ╔═══════════  Boot menu  ══════⁠════⁠╗
; 2  ║       Select bootable disk       ║
; ⁠3  ╟⁠─⁠─⁠─⁠───────────────────────────────╢
; 4  ║ disk#0 - empty                   ║
; 5  ║ disk#1 - present                 ║
; 6  ║ disk#2 - ERROR!                  ║
; 7  ║ disk#3 - empty                   ║
; ⁠8  ╟⁠─⁠─⁠─⁠───────────────────────────────╢
; ⁠9  ║ W/S/Up/Down                      ║
; 10 ╚⁠═⁠═⁠═⁠═⁠═⁠═⁠═⁠═⁠═⁠═⁠═⁠═⁠═⁠═⁠═⁠═⁠═⁠═⁠═⁠═⁠═⁠═⁠═⁠══⁠═⁠═⁠═⁠═⁠══⁠═⁠═⁠⁠═⁠╝
;    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX



;    XXXXXXXXXXXXXXXXXXXXXXXXXXXX
; 1  +==========================+
; 2  |                          |
; 3  | Are you sure? (Y/N) - _  |
; 4  |                          |
; 5  +==========================+
;    XXXXXXXXXXXXXXXXXXXXXXXXXXXX


;    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; 1  +============================+
; 2  |                            |
; 3  | Frequency ~ 0000000000 Khz |
; 4  |                            |
; 5  +============================+
;    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

;    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; 1  +==================================+
; 2  | Enter password:                  |
; 3  | ................................ |
; 4  |                                  |
; 5  +==================================+
;    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX