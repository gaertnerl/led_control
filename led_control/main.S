.equ gpio_gr, 17
.equ gpio_ye, 22
.equ gpio_re, 27

.equ output_mask, 0b001

.data

.text
.global main
.func main

	main:

	mov ip, sp
	stmfd sp!, {r4-r11, lr}
	mov fp, ip

	bl open_devmem

	bl mmap
	# save base address in r8
	mov r8, r0

	mov r0, #output_mask
	mov r1, #gpio_gr
	mov r2, r8
	bl gpio_function_select

	mov r1, #gpio_gr
	mov r2, r8
	bl gpio_set

	mov r0, #1
	bl sleep

	mov r1, #gpio_gr
	mov r2, r8
	bl gpio_clr

	mov r0, #output_mask
	mov r1, #gpio_ye
	mov r2, r8
	bl gpio_function_select

	mov r1, #gpio_ye
	mov r2, r8
	bl gpio_set

	mov r0, #1
	bl sleep

	mov r1, #gpio_ye
	mov r2, r8
	bl gpio_clr

	mov r0, #output_mask
	mov r1, #gpio_re
	mov r2, r8
	bl gpio_function_select

	mov r1, #gpio_re
	mov r2, r8
	bl gpio_set

	mov r0, #1
	bl sleep

	mov r1, #gpio_re
	mov r2, r8
	bl gpio_clr

	mov r0, r8
	bl munmap

	bl close_devmem

	ldmfd sp!, {r4-r11, lr}
	bx lr

.endfunc





