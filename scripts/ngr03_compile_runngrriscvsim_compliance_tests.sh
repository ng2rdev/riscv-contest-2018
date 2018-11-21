

#######################################################################
#Compiles and runs the RISC-V Compliance tests in the ngrriscvsim

pushd .
#RISCV_GCC_OPTS='-march=rv32im -mabi=ilp32 -mstrict-align -mbranch-cost=4 -DPREALLOCATE=1 -mcmodel=medany -static -std=gnu99 -static -nostdlib -nostartfiles -save-temps'
unset RISCV_GCC_OPTS
git clone --recursive https://github.com/riscv/riscv-compliance
cd riscv-compliance
patch -p1 < ../scripts/riscv-compliance-ngrriscv.patch
cd ngrriscvsim
mkdir bin
gcc -O2 -DDEBUG ./src/ngrriscvsim.c -o ./bin/ngrriscvsim.exe
cd ..
make RISCV_TARGET=ngrriscvsim RISCV_DEVICE=rv32im RISCV_ISA=rv32i
#make RISCV_TARGET=ngrriscvsim RISCV_DEVICE=rv32im RISCV_ISA=rv32im
# cp $BASE_DIR/riscv-compliance_ngrriscv/work/*.elf $BASE_DIR/ngrriscv-compliance-tests/
# make RISCV_TARGET=ngrriscv RISCV_DEVICE=rv32im RISCV_ISA=rv32i
# make RISCV_TARGET=ngrriscv RISCV_DEVICE=rv32im RISCV_ISA=rv32i
# 
# declare -a rv32i_sc_tests=(
#     "I-ENDIANESS-01" 
#     "I-RF_x0-01" 
#     "I-RF_size-01"
#     "I-RF_width-01"
#     "I-MISALIGN_JMP-01"
#     "I-MISALIGN_LDST-01"
#     "I-DELAY_SLOTS-01"
#     "I-JAL-01"
#     "I-JALR-01"
#     "I-LUI-01"
#     "I-AUIPC-01"
#     "I-LW-01"
#     "I-LH-01"
#     "I-LHU-01"
#     "I-LB-01"
#     "I-LBU-01"
#     "I-SW-01"
#     "I-SH-01"
#     "I-SB-01"
#     "I-ADD-01"
#     "I-ADDI-01"
#     "I-AND-01"
#     "I-OR-01"
#     "I-ORI-01"
#     "I-XORI-01"
#     "I-XOR-01"
#     "I-SUB-01"
#     "I-ANDI-01"
#     "I-FENCE.I-01"
#     "I-SLTI-01"
#     "I-SLTIU-01"
#     "I-BEQ-01"
#     "I-BNE-01"
#     "I-BLT-01"
#     "I-BLTU-01"
#     "I-BGE-01"
#     "I-BGEU-01"
#     "I-SRLI-01"
#     "I-SLLI-01"
#     "I-SRAI-01"
#     "I-SLL-01"
#     "I-SRL-01"
#     "I-SRA-01"
#     "I-SLT-01"
#     "I-SLTU-01"
#     "I-CSRRW-01"
#     "I-CSRRWI-01"
#     "I-NOP-01"
#     "I-CSRRS-01"
#     "I-CSRRSI-01"
#     "I-CSRRC-01"
#     "I-CSRRCI-01"
#     "I-ECALL-01"
#     "I-EBREAK-01"
#     "I-IO")
# 
# for f in "${rv32i_sc_tests[@]}"
# do
#     ${RISCV_PREFIX}objdump -D --disassembler-options=no-aliases,numeric $BASE_DIR/ngrriscv-compliance-tests/${f}.elf  > $BASE_DIR/ngrriscv-compliance-tests/${f}.dump
#     ${RISCV_PREFIX}objdump -t $BASE_DIR/ngrriscv-compliance-tests/${f}.elf | sort > $BASE_DIR/ngrriscv-compliance-tests/${f}.symbs
#     ${RISCV_PREFIX}objcopy -O srec    $BASE_DIR/ngrriscv-compliance-tests/${f}.elf $BASE_DIR/ngrriscv-compliance-tests/${f}.srec
#     ${RISCV_PREFIX}objcopy -O binary  $BASE_DIR/ngrriscv-compliance-tests/${f}.elf $BASE_DIR/ngrriscv-compliance-tests/${f}.bin
#     ${RISCV_PREFIX}objcopy -O verilog $BASE_DIR/ngrriscv-compliance-tests/${f}.elf $BASE_DIR/ngrriscv-compliance-tests/${f}.verilog
# done

popd

