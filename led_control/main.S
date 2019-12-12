.include "gpio_control.h"
.text
.global main
.func main

	main:

	bl open_devmem
	bl close_devmem

.endfunc





