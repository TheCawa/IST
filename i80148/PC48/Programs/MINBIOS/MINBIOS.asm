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
	
	LDI.dw IX, msg_dev_list_30
	CALL print
	LDI.dw IX, msg_dl_header_30
	CALL print
	LDI.dw IX, msg_dl_hr_30
	CALL print
	
skip80x:
	LDI.dw IX, 0x00020000 ; MMIO Base
	LDI.dw IY, 0x00010400 ; CMOS Base
	XOR A7, A7 ; Slot pointer
	INC A7
	LDI.dw A5, 4 ; Amount of slots
	
slot_l:
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
	
skip_stub:
	LDI.b XL1, 10
	STR.b XL1, [0x00020018]
	INC A7
	DEC A5
	JMP.NZ slot_l
	
	PUSH EX7
	LDI.dw IX, msg_dl_hr_30
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
	DEC EX3
	DEC EX3
	STR.dw EX3, [A6]
	LDI.dw IX, msg_press_enter
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
	CMP.b XL1, 0x0D
	JMP.EQ enter_pressed
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
	JMA 0x00060008
	
disk_read_error:
	LDI.dw IX, dsk_error
	CALL print
	HALT
	
disk_timeout:
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
	JMP.NE find_disk_skip0
	LOD.dw IX, [0x00010C20]
	LDI.dw A6, 0x00060000
	LDI.dw IY, 0x00000030
	AND IX, IY
	CMP IX, IY
	JMP.EQ find_disk_end
	
	COPY IX, A6
	XOR EX2, EX2
	XOR EX3, EX3
	INC EX3
	LOD.dw A1, [0x00030104]
	CALLR A1
	
	LOD.dw EX1, [A6]
	CMP.dw EX1, 0xB007AB1E
	JMP.NE find_disk_skip0
	JMP find_disk_end
	
find_disk_skip0:
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
	PUSH FL
	PUSH A0
	PUSH A1
	PUSH A7
	PUSH EX5
	PUSH EX7
	PUSH EX4
	PUSH EX6
	PUSH EX1
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
	XOR A7, A7
	INC EX2
	DEC EX3
	JMP.NZ rd_disk_l
	COPY EX1, R0
	POP EX1
	POP EX6
	POP EX4
	POP EX7
	POP EX5
	POP A7
	POP A1
	POP A0
	POP FL
	RET

wr_disk:
	PUSH FL
	PUSH A0
	PUSH A1
	PUSH A7
	PUSH EX5
	PUSH EX7
	PUSH EX4
	PUSH EX6
	PUSH EX1
	XOR A7, A7
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
	POP EX1
	POP EX6
	POP EX4
	POP EX7
	POP EX5
	POP A7
	POP A1
	POP A0
	POP FL
	STR.dw R0, [0x0002011C]
    RET
	
print_unary:
	PUSH FL
print_unary_l:
	XOR FL, FL
	STR.b XL7, [0x00020018]
	DEC XL6
	JMP.NZ print_unary_l
	POP FL
	RET

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
msg_init: .db 10, "MinBIOS", 10, 0

msg_press_enter: .db "Press <ENTER> for BOOT", 0

msg_ram: .db "RAM : ", 0
msg_kb_ok: .db "KB", 10, 10, 0

; Дисковые сообщения
dsk_loading: .db "Starting system disk . . .", 0
dsk_error: .db 10, "Disk read error!", 0
dsk_timeout: .db 10, "Disk timed out!", 0
dsk_missing: .db "No bootable disk found!", 0
dsk_st_err: .db 10, "Disk status error!", 0

dsk_try: .db "Disk# ", 0
ppp: .db " ", 0

msg_dev_list_30: .db "XPB Device listing:", 10, 0
msg_dl_header_30: .db "SLOT - Cid - Vid - Flg - Name", 10, 0
msg_dl_hr_30: .db 10, 0

dev_none: .db "None       ", 0
dev_storage: .db "Storage    ", 0
dev_input: .db "Input      ", 0
dev_timer: .db "Timer      ", 0
dev_rtc: .db "RTC        ", 0
dev_video: .db "Video      ", 0
dev_unknown: .db "Unknown    ", 0
dev_80stub: .db 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0

boot_menu_empty: .db "empty  ", 0
boot_menu_present: .db "present", 0