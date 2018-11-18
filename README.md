# riscv-contest-2018

---
### Description

ngrriscv is a performance optimized 32-bit, in order, 5-stage pipelined RISC-V microprocessor designed primarily with the riscv-contest-2018 in mind, but due to several factors, it wont be ready in time to participate in the contest.

ngrriscv is a derivative work form SecretBlaze (http://www.lirmm.fr/ADAC/?page_id=462), and to conform to the original license, ngrriscv is also distributed under GENERAL PUBLIC LICENSE Version 3.

ngrriscvsim, a RISC-V microprocessor simulator which passes all compliance tests for rv32i ISA, simulates the execution of instructions with CPI=1, it has about of 600 lines of C code, is also a derivative work from HF-RISCV Simulator (https://github.com/sjohann81/hf-risc). 
ngrriscvsim is then distributed under GENERAL PUBLIC LICENSE Version 2 license.

I have the intention to port this RISC-V simulator to the Lattice Mico8 (lm8) micro-controller, just because I think that will be fun to check the DMIPS/MHz of a small 8-bit micro running an simulator of a more powerful microprocessor.


### Pipeline


### ngrriscv SoC Memory Map

Current memory map is (it may change):

- ROM           : 0x80000000 - 0x80005FFF (24KB)
- RAM           : 0x80006000 - 0x80007FFF  (8KB)
- UART          : 0x8000C000 - 0x8000C007   (8B)  
- TIMER         : 0x8000C008 - 0x8000C00F   (8B)  
- BOOT_INST     : 0x8000F000 - 0x8000F3FF  (1KB)  


### Performance (Lattice UPDuinoV2)


Logic Resources:
- xx LUTS
- xx Registers
- xx DSP
- xx EBR   

Efficiency:
- Dhrystones: x.xx DMIPS/MHz
- CoreMark:   x.xx CoreMark/MHz

Total:
- Dhrystones: x.xx DMIPS