/*  ngrriscv SOC - a SOC RISCV emulator for the RV32IM architecture  
 *  Version 0.2
 *  by Nelson Ribeiro, 12-10-2018 
 *
 *  Based on hf_riscv_sim.c by Sergio Johann Filho, 
 *  see https://sea-region.github.com/sjohann81/hf-risc/tree/master/tools/sim/hf_riscv_sim
 *  Changes from original:
 *      Fixed some small bugs; 
 *      Added FENCE.I, WFI and FENCE.VMA as no-op instructions;
 *      Added M instructions;
 *      Changed/added CSR instructions;
 *      Changed IO memory mapping;
 *      Changed/added some debug capability; 
 *  
 *  Compile with:
 *      gcc -O2 ngrriscvsim.c -o ngrriscvsim.exe
 *   or to add some extra debug features:
 *      gcc -O2 -DDEBUG ngrriscvsim.c -o ngrriscvsim.exe
 *
 *  Original work is licensed under GPLv2, implying that this derivate work is also
 *      license under GPLv2. See Licence.ngrriscv.md for copyright notice.
 *  
 *  Original copyright:
 */     

/* file:          hf_riscv_sim.c
 * description:   HF-RISCV simulator
 * date:          11/2015
 * author:        Sergio Johann Filho <sergio.filho@pucrs.br>
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#define EXIT_TRAP               0x8000F000
#define MEM_BASE                0x80000000
#define MEM_SIZE                0x00008000

#define RISCV_UART_DATA_RXTX    0x8000C000
#define RISCV_UART_CTRL_STATUS  0x8000C004
#define RISCV_MTIME_BASE        0x8000C008
#define RISCV_MTIMECMP_BASE     0x8000C00C

#define MSTATUS_MIE             0x00000008
#define MSTATUS_MPIE            0x00000080
#define MSTATUS_MPP             0x00001800  
#define MIP_MSIP                (1 << 3)
#define MIP_MTIP                (1 << 7)
#define MIP_MEIP                (1 << 11)
#define PRV_M 3

//Needed for targets with different endianesss than the host
#define ntohs(A) ( ((A)>>8) | (((A)&0xff)<<8) )
#define htons(A) ntohs(A)
#define ntohl(A) ( ((A)>>24) | (((A)&0xff0000)>>8) | (((A)&0xff00)<<8) | ((A)<<24) )
#define htonl(A) ntohl(A)

#define EXC_CAUSE_INST_ADDRESS_MISALIGNED   0x00000000 // Interrupt = 0 (Sync);  Exception code 0 Instruction Address Misaligned
#define EXC_CAUSE_ILLEGAL_INST              0x00000002 // Interrupt = 0 (Sync);  Exception code 2 Illegal Instruction
#define EXC_CAUSE_BREAKPOINT                0x00000003 // Interrupt = 0 (Sync);  Exception code 3 Breakpoint
#define EXC_CAUSE_LOAD_ADDRESS_MISALIGNED   0x00000004 // Interrupt = 0 (Sync);  Exception code 4 Load Address Misaligned
#define EXC_CAUSE_STORE_ADDRESS_MISALIGNED  0x00000006
#define EXC_CAUSE_ECALL_MMODE               0x0000000B
#define IRQ_MACHINE_TIMER_INTERRUPT         0x80000007 // Interrupt = 1 (Async); Exception code 7 Machine Timer Interrupt

#define CSR_OP_NONE     0x0
#define CSR_OP_WRITE    0x1
#define CSR_OP_SET      0x2
#define CSR_OP_CLEAR    0x3
#define CSR_OP_WRITEI   0x4
#define CSR_OP_SETI     0x5
#define CSR_OP_CLEARI   0x6

#define MEM_OP_WRITE    0x0
#define MEM_OP_READ     0x1

static inline int  test_mask(uint32_t x, int mask)   { return (!! (x & mask));}
static inline void set_mask(uint32_t *x, int mask)   { *x |= (mask);}
static inline void clear_mask(uint32_t *x, int mask) { *x &= ~(mask);}

typedef struct {
    int32_t r[32];
    uint32_t pc, pc_next;
    int8_t *mem;
    uint32_t csr_mstatus, csr_mie, csr_mtvec, csr_mscratch, csr_mepc, csr_mcause, csr_mtval, csr_mip;
    uint32_t mcycles, mcompare;
    uint8_t uarttxdata;
    uint8_t cur_priv;
    //uint8_t cur_exception_mode;
} state;

int8_t sram[MEM_SIZE];

char strdebug[64];
uint32_t dump_memory;
uint32_t bppc;
uint32_t bppc_enabled = 0;
uint32_t bppc_found = 0;
uint32_t *ptrdebug;
uint32_t log_enable;

#ifdef DEBUG
    void dumpregs(state *s){
        int32_t i;

        for (i = 0; i < 32; i+=8){
            printf("\nr%02d [%08x] r%02d [%08x] r%02d [%08x] r%02d [%08x] r%02d [%08x] r%02d [%08x] r%02d [%08x] r%02d [%08x]",
            i, s->r[i], i+1, s->r[i+1], i+2, s->r[i+2], i+3, s->r[i+3],
            i+4, s->r[i+4], i+5, s->r[i+5], i+6, s->r[i+6], i+7, s->r[i+7]);
        }
        printf("\n");
    }
#endif

static int32_t mem_fetch(state *s, uint32_t address){
    uint32_t value=0;
    uint32_t *ptr;

    if (address == EXIT_TRAP) exit(0);
    
    ptr = (uint32_t *)(s->mem + (address % MEM_SIZE));
    value = *ptr;

    return(value);
}

static int32_t test_mem(state *s, int32_t size, uint32_t address, int32_t op){

    int32_t addressOK=1;	

    if (!(test_mask(s->csr_mstatus, MSTATUS_MIE))){
        switch(size){
            case 4 : if (address & 3) addressOK = 0; break;
            case 2 : if (address & 1) addressOK = 0; break;
            default: addressOK=1;
        }

        if (addressOK == 0){
            if (op == MEM_OP_WRITE)
                s->csr_mcause   = EXC_CAUSE_STORE_ADDRESS_MISALIGNED;
            else
                s->csr_mcause   = EXC_CAUSE_LOAD_ADDRESS_MISALIGNED;
            s->csr_mtval    = address;
            s->csr_mepc     = s->pc & 0xFFFFFFFC;
            s->pc           = s->csr_mtvec;
            s->pc_next      = s->csr_mtvec;            
            if (test_mask(s->csr_mstatus, MSTATUS_MIE)){                   
                set_mask(&(s->csr_mstatus), MSTATUS_MPIE);
                clear_mask(&(s->csr_mstatus), MSTATUS_MIE);                
            }
            s->mcycles++;
        }
    }
    /*printf("\nTEST_MEM: OP=0x%1x, address0x%8x size=0x%1x addressOK=0x%1x", op, address, size, addressOK);*/
    
    return addressOK;
}

static int32_t mem_read(state *s, int32_t size, uint32_t address){
    uint32_t value=0;
    uint32_t *ptr;

    switch(address){
        case RISCV_MTIMECMP_BASE    :   return (int32_t)s->mcompare;
        case RISCV_MTIME_BASE       :   return (int32_t)s->mcycles;
        case RISCV_UART_CTRL_STATUS :   return (int32_t)0x00000001;
        case RISCV_UART_DATA_RXTX   :   return (int32_t)((uint32_t)getchar());
    }

    ptr = (uint32_t *)(s->mem + (address % MEM_SIZE));

    switch(size){
        case 4: value = *(int32_t *)ptr; break;
        case 2: value = *(int16_t *)ptr; break;
        case 1: value = *(int8_t *)ptr;  break;
        default: ;
    }

    return(value);
}

static void mem_write(state *s, int32_t size, uint32_t address, uint32_t value){
    uint32_t i;
    uint32_t *ptr;

    switch(address){
        case RISCV_UART_DATA_RXTX   : s->uarttxdata = (uint8_t) value; return;
        case RISCV_MTIME_BASE       : s->mcycles    = (uint64_t) value; return;
        case RISCV_MTIMECMP_BASE    : s->csr_mie    = value; return;
        case EXIT_TRAP              : exit(0);
        case RISCV_UART_CTRL_STATUS : printf("%c", (int8_t)(s->uarttxdata & 0xff)); return;
    }

    ptr = (uint32_t *)(s->mem + (address % MEM_SIZE));

    switch(size){
        case 4: *(int32_t *)ptr = value;            break;
        case 2: *(int16_t *)ptr = (uint16_t)value;  break;
        case 1: *(int8_t *)ptr = (uint8_t)value;    break;
        default: ;
    }
}

int32_t csr_op(state *s, uint8_t op, uint8_t reg, uint32_t value, uint16_t csr ){

    uint32_t oldvalue = 0;
    uint32_t newvalue = 0;

    switch(csr){
        case 0x300: oldvalue = s->csr_mstatus;        break;
        case 0x304: oldvalue = s->csr_mie;            break;
        case 0x305: oldvalue = s->csr_mtvec;          break;
        case 0x340: oldvalue = s->csr_mscratch;       break;
        case 0x341: oldvalue = s->csr_mepc;           break;
        case 0x342: oldvalue = s->csr_mcause;         break;
        case 0x343: oldvalue = s->csr_mtval;          break;
        case 0x344: oldvalue = s->csr_mip;            break;
        case 0xB00: oldvalue = (uint32_t) s->mcycles; break;
        default   : oldvalue = 0;
    }

    switch(op){
        case CSR_OP_WRITE   : newvalue = value;       break;
        case CSR_OP_SET     : if (reg!=0) newvalue = oldvalue | value;    else newvalue = oldvalue; break;
        case CSR_OP_CLEAR   : if (reg!=0) newvalue = oldvalue & (~value); else newvalue = oldvalue; break;
        case CSR_OP_WRITEI  : newvalue = value;       break;
        case CSR_OP_SETI    : if (reg!=0) newvalue = oldvalue | value;    else newvalue = oldvalue; break;
        case CSR_OP_CLEARI  : if (reg!=0) newvalue = oldvalue & (~value); else newvalue = oldvalue; break;
        default             : newvalue = oldvalue;
    }

    switch(csr){
        case 0x300:  s->csr_mstatus  = newvalue;                break;
        case 0x304:  s->csr_mie      = newvalue;                break;
        case 0x305:  s->csr_mtvec    = newvalue & 0xFFFFFFFC;   break;
        case 0x340:  s->csr_mscratch = newvalue;                break;
        case 0x341:  s->csr_mepc     = newvalue & 0xFFFFFFFC;   break;
        case 0x342:  s->csr_mcause   = newvalue;                break;
        case 0x343:  s->csr_mtval    = newvalue;                break;
        default   : ;
    }

#ifdef DEBUG    
    if (bppc_enabled && bppc_found){
        printf("\nCSROP\top=0x%1x reg=0x%02x value=0x%08x csr=0x%03x oldvalue=0x%08x newvalue=0x%08x", op, reg, value, csr, oldvalue, newvalue);
    }
#endif   
    return (int32_t) oldvalue;
}

void exec_ecall(state *s){
    s->csr_mcause   = EXC_CAUSE_ECALL_MMODE;
    s->csr_mtval    = 0;
    s->csr_mepc     = s->pc & 0xFFFFFFFC;
    s->pc           = s->csr_mtvec;
    s->pc_next      = s->csr_mtvec;    
    if (test_mask(s->csr_mstatus, MSTATUS_MIE)){                   
        set_mask(&(s->csr_mstatus), MSTATUS_MPIE);
        clear_mask(&(s->csr_mstatus), MSTATUS_MIE);                
    }        
    s->mcycles++;
}

void exec_ebreak(state *s){
    s->csr_mcause   = EXC_CAUSE_BREAKPOINT;
    s->csr_mtval    = s->pc;
    s->csr_mepc     = s->pc & 0xFFFFFFFC;
    s->pc           = s->csr_mtvec;
    s->pc_next      = s->csr_mtvec;    
    if (test_mask(s->csr_mstatus, MSTATUS_MIE)){                   
        set_mask(&(s->csr_mstatus), MSTATUS_MPIE);
        clear_mask(&(s->csr_mstatus), MSTATUS_MIE);                
    }         
    s->mcycles++;
}

void exec_mret(state *s){
    s->pc           = s->csr_mepc;
    s->pc_next      = s->csr_mepc;
    
    if (test_mask(s->csr_mstatus, MSTATUS_MPIE)){                   
        set_mask(&(s->csr_mstatus), MSTATUS_MIE);
    }               
    s->mcycles++;    
 }


void cycle(state *s){
    uint32_t inst, i;
    uint32_t opcode, rd, rs1, rs2, funct3, funct7, funct5, imm_i, imm_s, imm_sb, imm_u, imm_uj;
    int32_t *r = s->r;
    uint32_t *u = (uint32_t *)s->r;
    uint32_t ptr_l, ptr_s;
    uint16_t csr;
    int32_t tmp;

    //Test if timer interrupt has happened 
    if (s->csr_mip){
        if ((s->csr_mstatus & MSTATUS_MIE) && (s->csr_mie & s->csr_mip & MIP_MTIP)){       
            s->csr_mcause   = IRQ_MACHINE_TIMER_INTERRUPT;
            s->csr_mtval    = 0;
            s->csr_mepc     = s->pc & 0xFFFFFFFC;
            s->pc           = s->csr_mtvec;
            s->pc_next      = s->csr_mtvec;
            
            if (test_mask(s->csr_mstatus, MSTATUS_MIE)){                   
                set_mask(&(s->csr_mstatus), MSTATUS_MPIE);
                clear_mask(&(s->csr_mstatus), MSTATUS_MIE);                
            }  
            
            s->mcycles++;
            goto endcycle;
        }
    }

    //Test for instruction address misaligned
    if(s->pc & 3){
        s->csr_mcause   = EXC_CAUSE_INST_ADDRESS_MISALIGNED;
        s->csr_mtval    = s->pc;
        s->csr_mepc     = s->pc & 0xFFFFFFFC;
        s->pc           = s->csr_mtvec;
        s->pc_next      = s->csr_mtvec;
        if (test_mask(s->csr_mstatus, MSTATUS_MIE)){                   
            set_mask(&(s->csr_mstatus), MSTATUS_MPIE);
            clear_mask(&(s->csr_mstatus), MSTATUS_MIE);                
        }         
        
        s->mcycles++;
        goto endcycle;
    }
    else{
        inst = mem_fetch(s, s->pc);
    }

    opcode      = inst & 0x7f;
    rd          = (inst >>  7) & 0x1f;
    rs1         = (inst >> 15) & 0x1f;
    rs2         = (inst >> 20) & 0x1f;
    funct3      = (inst >> 12) & 0x7;
    funct7      = (inst >> 25) & 0x7f;
    funct5      = (inst >> 20) & 0x1f;
    imm_i       = (inst & 0xfff00000) >> 20;
    imm_s       = ((inst & 0xf80) >> 7) | ((inst & 0xfe000000) >> 20);
    imm_sb      = ((inst & 0xf00) >> 7) | ((inst & 0x7e000000) >> 20) | ((inst & 0x80) << 4) | ((inst & 0x80000000) >> 19);
    imm_u       = inst & 0xfffff000;
    imm_uj      = ((inst & 0x80000000) >> 11) | (inst & 0x00ff000) | ((inst & 0x00100000) >> 9) | ((inst & 0x7fe00000) >> 20);
    csr         = (uint16_t)((((uint32_t) inst) >> 20) & 0xFFF);
    if (inst & 0x80000000){
        imm_i  |= 0xfffff000;
        imm_s  |= 0xfffff000;
        imm_sb |= 0xffffe000;
        imm_uj |= 0xffe00000;
    }
    ptr_l       = r[rs1] + (int32_t)imm_i;
    ptr_s       = r[rs1] + (int32_t)imm_s;

    switch(opcode){
        case 0x37: r[rd] = imm_u; break;                                                                            /* LUI */
        case 0x17: r[rd] = s->pc + imm_u; break;                                                                    /* AUIPC */
        case 0x6f: r[rd] = s->pc_next; s->pc_next = s->pc + imm_uj; break;                                          /* JAL note: need to test funct3? */
        case 0x67: tmp=r[rs1]; r[rd] = s->pc_next; s->pc_next = (tmp + imm_i) & 0xfffffffe; ; break;                /* JALR */
        case 0x63:              
            switch(funct3){             
                case 0x0: if (r[rs1] == r[rs2]) { s->pc_next = s->pc + imm_sb; } break;                             /* BEQ */
                case 0x1: if (r[rs1] != r[rs2]) { s->pc_next = s->pc + imm_sb; } break;                             /* BNE */
                case 0x4: if (r[rs1] <  r[rs2]) { s->pc_next = s->pc + imm_sb; } break;                             /* BLT */
                case 0x5: if (r[rs1] >= r[rs2]) { s->pc_next = s->pc + imm_sb; } break;                             /* BGE */
                case 0x6: if (u[rs1] <  u[rs2]) { s->pc_next = s->pc + imm_sb; } break;                             /* BLTU */
                case 0x7: if (u[rs1] >= u[rs2]) { s->pc_next = s->pc + imm_sb; } break;                             /* BGEU */
                default: goto fail; 
            }   
            break;  
        case 0x03:  
            switch(funct3){ 
                case 0x0:                                      r[rd] = (int8_t)mem_read(s,1,ptr_l); break;          /* LB */
                case 0x1: if (test_mem(s,2,ptr_l,MEM_OP_READ)) r[rd] = (int16_t)mem_read(s,2,ptr_l); break;         /* LH */
                case 0x2: if (test_mem(s,4,ptr_l,MEM_OP_READ)) r[rd] = mem_read(s,4,ptr_l); break;                  /* LW */
                case 0x4:                                      r[rd] = (uint8_t)mem_read(s,1,ptr_l); break;         /* LBU */
                case 0x5: if (test_mem(s,2,ptr_l,MEM_OP_READ)) r[rd] = (uint16_t)mem_read(s,2,ptr_l); break;        /* LHU */
                default: goto fail; 
            }   
            break;  
        case 0x23:  
            switch(funct3){ 
                case 0x0:                                       mem_write(s,1,ptr_s,r[rs2]); break;                 /* SB */
                case 0x1: if (test_mem(s,2,ptr_s,MEM_OP_WRITE)) mem_write(s,2,ptr_s,r[rs2]); break;                 /* SH */
                case 0x2: if (test_mem(s,4,ptr_s,MEM_OP_WRITE)) mem_write(s,4,ptr_s,r[rs2]); break;                 /* SW */
                default: goto fail;
            }
            break;
        case 0x13:
            switch(funct3){
                case 0x0: r[rd] = r[rs1] + (int32_t)imm_i; break;                                                   /* ADDI */
                case 0x2: r[rd] = r[rs1] < (int32_t)imm_i; break;                                                   /* SLTI */
                case 0x3: r[rd] = u[rs1] < (uint32_t)imm_i; break;                                                  /* SLTIU */
                case 0x4: r[rd] = r[rs1] ^ (int32_t)imm_i; break;                                                   /* XORI */
                case 0x6: r[rd] = r[rs1] | (int32_t)imm_i; break;                                                   /* ORI */
                case 0x7: r[rd] = r[rs1] & (int32_t)imm_i; break;                                                   /* ANDI */
                case 0x1: r[rd] = u[rs1] << (rs2 & 0x3f); break;                                                    /* SLLI note: need to test funct7?*/
                case 0x5:               
                    switch(funct7){             
                        case 0x0: r[rd] = u[rs1] >> (rs2 & 0x3f); break;                                            /* SRLI */
                        case 0x20: r[rd] = r[rs1] >> (rs2 & 0x3f); break;                                           /* SRAI */
                        default: goto fail; 
                    }   
                    break;  
                default: goto fail; 
            }   
            break;  
        case 0x33:  
            switch(funct7){ 
                case 0x0:   
                    switch(funct3){ 
                        case 0x0: r[rd] = r[rs1] + r[rs2]; break;                                                   /* ADD */
                        case 0x1: r[rd] = r[rs1] << r[rs2]; break;                                                  /* SLL */
                        case 0x2: r[rd] = r[rs1] < r[rs2]; break;                                                   /* SLT */
                        case 0x3: r[rd] = u[rs1] < u[rs2]; break;                                                   /* SLTU */
                        case 0x4: r[rd] = r[rs1] ^ r[rs2]; break;                                                   /* XOR */
                        case 0x5: r[rd] = u[rs1] >> u[rs2]; break;                                                  /* SRL */
                        case 0x6: r[rd] = r[rs1] | r[rs2]; break;                                                   /* OR */
                        case 0x7: r[rd] = r[rs1] & r[rs2]; break;                                                   /* AND */
                        default: goto fail;         
                    }
                    break;
                case 0x1:
                    switch(funct3){
                        case 0x0: r[rd] = r[rs1] * r[rs2]; break;                                                   /* MUL */
                        case 0x1: r[rd] = (int32_t) ( (((int64_t) r[rs1]) * (((int64_t)  r[rs2]))) >> 32); break;   /* MULH */
                        case 0x2: r[rd] = (int32_t) ( (((int64_t) r[rs1]) * (((uint64_t) r[rs2]))) >> 32); break;   /* MULHSU  */
                        case 0x3: r[rd] = (int32_t) ( (((uint64_t)r[rs1]) * (((uint64_t) r[rs2]))) >> 32); break;   /* MULHU */
                        case 0x4: r[rd] = r[rs1] / r[rs2]; break;                                                   /* DIV  */
                        case 0x5: r[rd] = u[rs1] / u[rs2]; break;                                                   /* DIVU  */
                        case 0x6: r[rd] = r[rs1] % r[rs2]; break;                                                   /* REM  */
                        case 0x7: r[rd] = u[rs1] % u[rs2]; break;                                                   /* REMU */
                        default: goto fail;
                    }
                    break;
                case 0x20:
                    switch(funct3){
                        case 0x0: r[rd] = r[rs1] - r[rs2]; break;                                                   /* SUB */
                        case 0x5: r[rd] = r[rs1] >> r[rs2]; break;                                                  /* SRA */
                        default: goto fail;
                    }
                    break;
                default: goto fail;
            }
            break;
        case 0x73:
            switch(funct3){
                case 0x0:
                    switch(funct7){
                        case 0x0:
                            switch(funct5){
                                case 0x0: exec_ecall(s); break;                                                     /* ECALL */
                                case 0x1: exec_ebreak(s); break;                                                    /* EBREAK */
                                /* case 0x2: exec_uret(s); break; */                                                /* URET */
                                default: goto fail;             
                            }               
                            break;              
                        case 0x8:               
                            switch(funct5){             
                                /* case 0x2: exec_sret(s); break; */                                                /* SRET */
                                case 0x5: exit(0); break;                                                           /* WFI      note: like a NOP*/
                                default: goto fail;             
                            }               
                            break;              
                        case 0x9: break;                                                                            /* SFENCE.VMA note: like a NOP*/
                        case 0x18: exec_mret(s); break;                                                             /* MRET */
                        default: goto fail;
                    }
                    break;
                case 0x1: tmp = csr_op(s, CSR_OP_WRITE , rs1, r[rs1], csr); if (rd!=0)  r[rd]=tmp; break;           /* CSRRW  */
                case 0x2: tmp = csr_op(s, CSR_OP_SET   , rs1, r[rs1], csr); r[rd]=tmp;             break;           /* CSRRS  */
                case 0x3: tmp = csr_op(s, CSR_OP_CLEAR , rs1, r[rs1], csr); r[rd]=tmp;             break;           /* CSRRC */
                case 0x5: tmp = csr_op(s, CSR_OP_WRITEI, rs1, rs1,    csr); if (rd!=0)  r[rd]=tmp; break;           /* CSRRWI */
                case 0x6: tmp = csr_op(s, CSR_OP_SETI  , rs1, rs1,    csr); r[rd]=tmp;             break;           /* CSRRSI   */
                case 0x7: tmp = csr_op(s, CSR_OP_CLEARI, rs1, rs1,    csr); r[rd]=tmp;             break;           /* CSRRCI  */
                default: goto fail;
            }
            break;
        case 0x0F:
            switch(funct3){
                case 0x0: break;                                                                                    /* FENCE    note: like a NOP*/
                case 0x1: break;                                                                                    /* FENCE.I  note: like a NOP*/
                default: goto fail;
            }
            break;
        default: goto fail;
    }
    s->r[0] = 0;
    s->mcycles++;


#ifdef DEBUG 
    if (bppc_enabled && bppc_found){
        printf("\npc=0x%08x inst=0x%08x opcode=0x%02x funct3=0x%x funct7=0x%02x funct5=0x%02x rs1=%02d rs2=%02d rd=%02d csr=0x%02x",
                s->pc, inst, opcode, funct3, funct7, funct5, rs1, rs2, rd, csr);
        printf("\nimm_i=0x%08x imm_s=0x%08x imm_sb=0x%08x imm_u=0x%08x imm_uj=0x%08x",
                imm_i, imm_s, imm_sb, imm_u, imm_uj);
        printf("\nmstatus=0x%04x mie=0x%04x mtvec=0x%08x mscratch=0x%08x mepc=0x%08x mcause=0x%04x mtval=0x%08x mip=0x%04x",
                s->csr_mstatus, s->csr_mie, s->csr_mtvec, s->csr_mscratch, s->csr_mepc, s->csr_mcause, s->csr_mtval, s->csr_mip);
        printf("\nmcycles=0x%08x mcompare=0x%08x uarttxdata=0x%02x",
                s->mcycles, s->mcompare, (uint32_t)s->uarttxdata);
        dumpregs(s);

        dump_memory=1;
        while (dump_memory){
            if (log_enable==0) gets(strdebug); else strdebug[0]='\0';
            if ((strdebug[0]!='M') & (strdebug[0]!='m'))
                dump_memory=0;
            else{
                int address = strtol(&strdebug[2], NULL, 16);
                for (i=0; i<8; i++){
                    ptrdebug = (uint32_t *)(s->mem + (address % MEM_SIZE));
                    printf("Memory[0x%08x] = 0x%08x\n",address,  *ptrdebug);
                    address+=4;
                }
            }
        }
    }
#endif    

    s->pc       = s->pc_next;
    s->pc_next  = s->pc_next + 4;

endcycle:
    if (s->mcycles>=s->mcompare) s->csr_mip |= MIP_MTIP;
    if (s->pc == bppc)           bppc_found = 1;
    return;

fail:
    printf("\ninvalid opcode (pc=0x%08x inst=0x%08x opcode=0x%02x funct3=0x%x funct7=0x%02x funct5=0x%02x)", s->pc, inst, opcode, funct3, funct7, funct5);
    exit(0);
}

int main(int argc, char *argv[]){
    state context;
    state *s;
    FILE *in;
    int bytes, i;


    s = &context;
    memset(s, 0, sizeof(state));
    memset(sram, 0xff, sizeof(MEM_SIZE));

    if (argc >= 2){
        in = fopen(argv[1], "rb");
        if (in == 0){
            printf("\nerror opening binary file.\n");
            return 1;
        }
        bytes = fread(&sram, 1, MEM_SIZE, in);
        fclose(in);
        if (bytes == 0){
            printf("\nerror reading binary file.\n");
            return 1;
        }
        if (argc >= 3){
            bppc = (uint32_t)strtol(argv[2], NULL, 16);
            bppc_enabled = 1;
            if (bppc==0x1) bppc_found = 1;
            if (bppc==0x2) {bppc_found = 1; log_enable = 1;}
        }
    }else{
        printf("\nsyntax: ngrriscvsim [file.bin] [logfile.txt]\n");
        return 1;
    }

    s->pc           = MEM_BASE ;
    s->pc_next      = s->pc + 4;
    s->mem          = &sram[0];
    s->cur_priv     = PRV_M;
    s->csr_mstatus  = MSTATUS_MPP;

    for(;;){
        cycle(s);
    }

    return(0);
}
