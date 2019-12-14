.globl open_devmem, close_devmem, mmap, munmap, gpio_function_select, gpio_set, gpio_clr


@ DEFINITIONEN
.equ BITS_PER_GPIO, 3
.equ GPIOS_PER_REG, 10
.equ mask, 0b111
.equ PERI_BASE,			0x3f000000
.equ GPIO_BASEOFFSET, 	0x00200000
.equ GPIO_LASTADDRESS, 	0x002000B4
.equ GPIO_MEMSIZE, 		0x00001000

.equ SYSCALL_OPEN,5
.equ SYSCALL_CLOSE,6
.equ SYSCALL_WRITE,4
.equ SYSCALL_MMAP,192
.equ SYSCALL_MUNMAP,92

.equ OPEN_PARAMETER_SYNC_RDWR, 0x00101002

.set GPIO_BASE, PERI_BASE+GPIO_BASEOFFSET

.data
.balign 4

	# RaspPi 2: GPIO addresses start at 0x3f200000
	PERI_BASE_WORD:				.word GPIO_BASE
	dev_mem_filename: 			.asciz "/dev/mem"


.text
.balign 4


	open_devmem:
	#returns
	#r0: file descriptor

	mov ip, sp
	stmfd sp!, {r4-r11, lr}
	mov fp, ip


	// r0, r1, r2 are parameters
	// for open() function
	ldr r0, =dev_mem_filename
	ldr r1, =OPEN_PARAMETER_SYNC_RDWR
	mov r2, #0
	//r7 determines syscall function
	mov r7, #SYSCALL_OPEN
	//software interrupt
	swi #0

	ldmfd sp!, {r4-r11, lr}
	bx lr



	close_dev_mem:
	# parameters
	# r1: file descriptor
	# returns
	# r0: syscall return code

	mov ip, sp
	stmfd sp!, {r4-r11, lr}
	mov fp, ip

	mov r0, r1
	mov r7, #6
	swi #0

	ldmfd sp!, {r4-r11, lr}
	bx lr


	mmap:
	# parameters
	# r0: file descriptor

	# returns
	# r0: GPIO base address

	mov ip, sp
	stmfd sp!, {r4-r11, lr}
	mov fp, ip

	// mmap arguments
	// --------------
	// r0 address
	// r1 length
	// r2 security
	// r3 flags
	// r4 file descriptor
	// r5 offset
	// r7 syscall code

	mov r4, r0
	mov r0, #0
	mov r1, #GPIO_MEMSIZE
	mov r2, #3
	mov r3, #1
	ldr r5, =GPIO_BASE
	lsr r5, r5, #12

	mov r7, #SYSCALL_MMAP
	swi #0

	ldmfd sp!, {r4-r11, lr}
	bx lr


	gpio_set:
	// parameters
	// r1: target gpio
	// r2: gpio base address

	mov ip, sp
	stmfd sp!, {r4-r11, lr}
	mov fp, ip

	// select pin via mask
	mov r0, #0b1
	lsl r0, r0, r1
	str r0, [r2, #28]

	ldmfd sp!, {r4-r11, lr}
	bx lr


	gpio_clr:
	// parameters
	// r1: target gpio
	// r2: gpio base address

	mov ip, sp
	stmfd sp!, {r4-r11, lr}
	mov fp, ip

	// select pin via mask
	mov r0, #0b1
	lsl r0, r0, r1
	str r0, [r2, #40]

	ldmfd sp!, {r4-r11, lr}
	bx lr


	gpio_function_select:
	// parameters
	// r0: function code
	// r1: target gpio
	// r2: base address

	mov ip, sp
	stmfd sp!, {r4-r11, lr}
	mov fp, ip

	mov r9, r0
	mov r8, r2
	mov r0, r1
	bl gpio_fsel_offset

	// add register offset to base address
	add r4, r8, r1
	// load register from address
	ldr r11, [r4]
	// copy the register, put zeros at pin
	mov r7, #0b111
	bic r11, r11, r7, LSL R2	// R0 <- R0 AND NOT ( 0b111 << R10)
	// create ouput mask, shift to pin and or
	mov r6, r9
	orr r11, r11, r6, LSL R2 // R0 <- R0 ORR (0b101 << R10)
	// store to update the gpio
	str r11, [r4]

	ldmfd sp!, {r4-r11, lr}
	bx lr


	munmap:
	// parameter
	// r0: gpio base address

	mov ip, sp
	stmfd sp!, {r4-r11, lr}
	mov fp, ip

	mov r1, #GPIO_MEMSIZE
	mov r7, #SYSCALL_MUNMAP
	swi #0

	ldmfd sp!, {r4-r11, lr}
	bx lr


	close_devmem:
	mov ip, sp
	stmfd sp!, {r4-r11, lr}
	mov fp, ip

	mov r0, r11
	mov r7, #SYSCALL_CLOSE
	swi #0

	ldmfd sp!, {r4-r11, lr}
	bx lr


	gpio_fsel_offset:
	// parameters
	// r0: target gpio

	// returns
	// r1: register_offset
	// r2: pin offset

	mov ip, sp
	stmfd sp!, {r4-r11, lr}
	mov fp, ip

	//ADDRESS ALGORITHM:
	// REG_ADDR = BASE_ADDR + Floor(GPIO_NR / 10) * 4 Byte
	// PIN_ADDR	= REG_ADDR + (GPIO_NR % 10) * 3 Bit
	// ADDRESS = REG_ADDR + PIN_ADDR


	reg_addr:
	//returns
	//r1: register address

	// initialize regs
	//---------------------------
	mov r1, #0
	mov r10, #GPIOS_PER_REG

	div_loop_reg_addr:

	// pin_nr - pins_per_register
	// ...s -> update flags
	subs r0, r0, r10

	// jumo if r0 negative
	bmi div_loop_reg_addr_done

	// add 4 byte
	add r1, r1, #4
	b div_loop_reg_addr

	div_loop_reg_addr_done:
	b pin_offs
	//---------------------------


	pin_offs:
	//---------------------------
	// returns
	// r2: pin address offset

	// r0 was negative
	// add number_of_pins back to r0
	mov r10, #GPIOS_PER_REG
	add r0, r0, r10

	// initialize registers
	mov r10, #BITS_PER_GPIO
	mov r2, #0

	div_loop_pin_offs:

	//	add 3 to pin offset
	//	as long as r0 is positive

	subs r0, r0, #1
	bmi div_loop_pin_offs_done
	add r2, r2, r10
	b div_loop_pin_offs

	div_loop_pin_offs_done:
	b addr_and_pin_offset_done
	//---------------------------------


	addr_and_pin_offset_done:

	ldmfd sp!, {r4-r11, lr}
	bx lr

