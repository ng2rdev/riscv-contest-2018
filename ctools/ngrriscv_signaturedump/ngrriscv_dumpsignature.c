/*
 * "ngrriscv_dumpsignature" C code example
 *  Version 0.2, 12-10-2018
 *
 *  Run to obtain assembly code:
 *      riscv32-unknown-elf-gcc -O2 -S ngrriscv_dumpsignature.c
 *
 *  Distributed under License Apache License v2.0
 *  See license.ngrriscv_dumpsignature.md for license details.
 *
 */    
    
    #define UART_BASE_ADDRESS        (0x8000C000)                                                      
    #define UART_DATA_RXTX_REG       (UART_BASE_ADDRESS + 0x0)                                         
    #define UART_STATUS_REG          (UART_BASE_ADDRESS + 0x4)                                         
    #define UART_CONTROL_REG         (UART_BASE_ADDRESS + 0x4)                                         
    #define TX_BUSY_FLAG_BIT         (1<<1)                                                            
    #define SEND_TX_BIT              (1<<4)                                                            

    extern unsigned int begin_signature;
    extern unsigned int end_signature;

    void outbyte (char value){                                                                         
        while (((*(volatile unsigned int*)(UART_STATUS_REG)) & TX_BUSY_FLAG_BIT) == TX_BUSY_FLAG_BIT); 
        (*(volatile unsigned int *)(UART_DATA_RXTX_REG) = value);                                        
        (*(volatile unsigned int *)(UART_CONTROL_REG) = SEND_TX_BIT);                                  
    }                                                                                                  

    #define TOHEX(i) (i <= 9 ? '0' + i : 'a' - 10 + i)                                                 
    void printInt2Hex(int x){                                                    
        unsigned int mask = 0xF0000000;
        int i =  0;
        int j = 28;
        for (i=0; i<8; i++){
            outbyte(TOHEX(((x & mask) >> j)));
            mask = mask >> 4;
            j -=4;
        }    
    }    

    void ngrriscv_dumpsignature(){                                                                     
        unsigned int *sigbegin = &begin_signature;                                           
        unsigned int *sigend   = &end_signature;                                             
        unsigned int *cp       = sigbegin;                                                                            
        while (cp < sigend){                                                                           
            printInt2Hex(*(cp+3));
            printInt2Hex(*(cp+2));
            printInt2Hex(*(cp+1));
            printInt2Hex(*(cp+0));
            outbyte('\n');
            cp+=4;    
        }                                                                                               
    }