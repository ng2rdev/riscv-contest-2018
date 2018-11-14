/**************************************************************************
 *                                                                        
 *  ngrriscv Boot loader (s-record loader)
 *
 * Compile with (or other riscv compiler):
 *   riscv32-unknown-elf-gcc -O2 -nostdlib -nostdinc bootloader.c -o bootloader.elf -Wl,-T,bootloader.ld,-Map,bootloader.map,--print-memory-usage
 *
 *
 *  Distributed under License Apache License v2.0
 *  See license.ngrriscv_bootloader.md for license details.
 */

/**********************************************************************/

__asm__("                    \n"
"    .section .init          \n"              
"	 .globl _start           \n"  
"	 .type _start,@function  \n"  
"                            \n"  
"_start:                     \n"  
".option push                \n"  
".option norelax             \n"  
"	la gp, __global_pointer$ \n"  
".option pop                 \n"  
"	la sp, _sp               \n"
"	/* Clear bss section */  \n"  
"	la a0, __bss_start       \n"  
"	la a1, _end              \n"  
"	bgeu a0, a1, 2f          \n"  
"1:                          \n"  
"	sw zero, (a0)            \n"  
"	addi a0, a0, 4           \n"  
"	bltu a0, a1, 1b          \n"  
"2:                          \n"  
"	call main                \n"  
"mainDone:                   \n"  
"    j mainDone              \n"
"    ret                     \n"  
"");

#define UART_BASE_ADDRESS        (0x8000C000)
#define TIMER_BASE_ADDRESS       (0x8000C008)
#define UART_DATA_RXTX_REG       (UART_BASE_ADDRESS + 0x0)
#define UART_STATUS_REG          (UART_BASE_ADDRESS + 0x4)
#define UART_CONTROL_REG         (UART_BASE_ADDRESS + 0x4)

#define RX_READY_FLAG_BIT        (1<<0)
#define TX_BUSY_FLAG_BIT         (1<<1)
#define SEND_TX_BIT              (1<<4)	
    
static inline void outbyte (char value){  
    while (((*(volatile unsigned int*)(UART_STATUS_REG)) & TX_BUSY_FLAG_BIT) == TX_BUSY_FLAG_BIT);
	(*(volatile unsigned int *)(UART_DATA_RXTX_REG) = value);
    (*(volatile unsigned int *)(UART_CONTROL_REG) = SEND_TX_BIT); 
}

static inline unsigned char inbyte (){   
	while (((*(volatile unsigned int*)(UART_STATUS_REG)) & RX_READY_FLAG_BIT) != RX_READY_FLAG_BIT);
	return (unsigned char)(*(volatile unsigned int*)(UART_DATA_RXTX_REG));
}
    
static inline void gets(unsigned char *s) {
	do {
		*s = inbyte();
		if ((*s == '\r') || (*s == '\n')) {break;}
		s++;
	} while (1);
}
	
static inline unsigned int hex2int(int len, unsigned char *h)
{
	unsigned int tmp = 0;
	unsigned int i;
	unsigned char c;

	for (i=0; i<len; i++) {
	    c = h[i];
	    if (c >= 'A') c = c - 'A' + 10; else c -= '0';
	    tmp = (tmp << 4) | c;
	}
	return(tmp);
}

void static execcode(int addr){
    void (*prog) ();
    prog = (void *) addr;
    prog();
}

void main() {
	unsigned char buffer[256];
	int i, size, addr;
	char *data;
    void (*prog) ();
  
	do {
	    gets(buffer);
	    if (buffer[0] == 'S') {
            addr = hex2int(8, &buffer[4]);
            data = (unsigned char *) &buffer[12];
            if (buffer[1] == '3') {
                size = (hex2int(2, &buffer[2])*2 - 10) >> 1;
                for (i=0; i<size; i++) 
                    ((char *)addr)[i] = hex2int(2, &data[2*i]);
            } else if (buffer[1] == '7') {
                execcode(addr);
            }
	    }
	} while (1);
}