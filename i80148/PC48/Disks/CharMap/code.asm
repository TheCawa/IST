.org 0x00060000

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
	; LDI.b XL1, 0x00 ; Graphic mode
	STR.b R0, [IX+1]
	LDI.b XL1, 0x01
	STR.b XL1, [IX]
	
	LOD.dw EX1, [0x0002000C]
	SUB.dw EX1, 0x10000
	COPY EX1, SP
	SUB.dw EX1, 0x10000
	COPY EX1, BP
	XOR EX1, EX1
	
	LDI.dw IX, 0x00060400
	LDI.dw EX2, 1
	COPY EX3, EX2
	LOD.dw A1, [0x00030104]
	CALLR A1
	
main:
	XOR EX1, EX1
	LDI.b XL2, 0x10
	LDI.b XL3, 0x10
	LDI.b XL7, 0x20
	LDI.b XL6, 0x0A
cycle:
	CMP.b XL1, 0x20
	JMP.LS skip_char
	CMP.b XL1, 0x7F
	JMP.EQ skip_char
	CMP.b XL1, 0xFF
	JMP.EQ skip_char
	STR.b XL1, [0x00020018]
skip_ret:
	STR.b XL7, [0x00020018]
	INC XL1
	DEC XL2
	JMP.NZ cycle
	STR.b XL6, [0x00020018]
	LDI.b XL2, 0x10
	DEC XL3
	JMP.NZ cycle
	HALT

skip_char:
	STR.b XL7, [0x00020018]
	JMP skip_ret

.data
buffer: .db 0, 0, 0, 0