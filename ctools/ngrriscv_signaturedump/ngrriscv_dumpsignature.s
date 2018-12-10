#define RV_COMPLIANCE_CODE_END            \
    .align  4                            ;\
    .globl  printInt2Hex                 ;\
printInt2Hex:                            ;\
    li      a1,28                        ;\
    li      a6,-268435456                ;\
    li      t3,9                         ;\
    li      a4,-2147418112               ;\
    li      t1,16                        ;\
    li      a7,-4                        ;\
.L9:                                     ;\
    and     a5,a0,a6                     ;\
    srl     a5,a5,a1                     ;\
    andi    a2,a5,0xff                   ;\
    bgtu    a5,t3,.L6                    ;\
    addi    a2,a2,48                     ;\
    andi    a2,a2,0xff                   ;\
.L8:                                     ;\
    lw      a5,-252(a4)                  ;\
    andi    a5,a5,2                      ;\
    bnez    a5,.L8                       ;\
    sw      a2,-256(a4)                  ;\
    sw      t1,-252(a4)                  ;\
    addi    a1,a1,-4                     ;\
    srli    a6,a6,4                      ;\
    bne     a1,a7,.L9                    ;\
    ret                                  ;\
.L6:                                     ;\
    addi    a2,a2,87                     ;\
    andi    a2,a2,0xff                   ;\
    j   .L8                              ;\
                                         ;\
    .align  4                            ;\
    .globl  ngrriscv_dumpsignature       ;\
ngrriscv_dumpsignature:                  ;\
    addi    sp,sp,-32                    ;\
    sw      s1,20(sp)                    ;\
    lui     a5,%hi(end_signature)        ;\
    lui     s1,%hi(begin_signature)      ;\
    sw      s2,16(sp)                    ;\
    sw      ra,28(sp)                    ;\
    sw      s0,24(sp)                    ;\
    sw      s3,12(sp)                    ;\
    sw      s4,8(sp)                     ;\
    addi    s2,s1,%lo(begin_signature)   ;\
    addi    a5,a5,%lo(end_signature)     ;\
    bgeu    s2,a5,.L12                   ;\
    addi    a5,a5,-1                     ;\
    sub     a5,a5,s2                     ;\
    andi    a5,a5,-4                     ;\
    addi    a5,a5,4                      ;\
    add     s2,s2,a5                     ;\
    addi    s1,s1,%lo(begin_signature)   ;\
    li      s0,-2147418112               ;\
    li      s4,10                        ;\
    li      s3,16                        ;\
.L15:                                    ;\
    lw      a0,0(s1)                     ;\
    call    printInt2Hex                 ;\
.L14:                                    ;\
    lw      a5,-252(s0)                  ;\
    andi    a5,a5,2                      ;\
    bnez    a5,.L14                      ;\
    sw      s4,-256(s0)                  ;\
    sw      s3,-252(s0)                  ;\
    addi    s1,s1,4                      ;\
    bne     s1,s2,.L15                   ;\
.L12:                                    ;\
    lw      ra,28(sp)                    ;\
    lw      s0,24(sp)                    ;\
    lw      s1,20(sp)                    ;\
    lw      s2,16(sp)                    ;\
    lw      s3,12(sp)                    ;\
    lw      s4,8(sp)                     ;\
    addi    sp,sp,32                     ;\
    jr      ra                           ;\
