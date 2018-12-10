########################################################################
# Setup General Variables
########################################################################
export IS_MSYS2_OS=$(grep -q MSYS_NT-6.1 <<< `uname -a` && echo "1" || echo "0")
export IS_LINUX_OS=$(grep -q Linux <<< `uname -a` && echo "1" || echo "0")
export BASE_DIR=`pwd`
export BASE_DIR=`pwd`
export XLEN=32
export ARCH=riscv32
export RISCV_ISA=rv32im
export RISCV_GCC_OPTS_EXTRA="-march=rv32im -mabi=ilp32 -mstrict-align -mbranch-cost=4"
export RISCV_GCC_OPTS="$RISCV_GCC_OPTS_EXTRA -DPREALLOCATE=1 -mcmodel=medany -static -std=gnu99 -O3 -fno-inline -fno-builtin-printf"
export RISCV_SIM="ngrriscvsim "    
export IS_MSYS2_OS=$(grep -q MSYS_NT-6.1 <<< `uname -a` && echo "1" || echo "0")
export IS_LINUX_OS=$(grep -q Linux <<< `uname -a` && echo "1" || echo "0")

########################################################################
# Setup Compilers
########################################################################
if [ $IS_MSYS2_OS -eq 1 ] 
then
    export RISCV_PREFIX=riscv32-unknown-elf-
    export RISCV_OBJDUMP="${RISCV_PREFIX}objdump --disassemble-all --disassemble-zeroes"
    export RISCV=/apps/compilers/riscv32-unknown-elf
    export PATH=$PATH:$RISCV/bin/
    #export RISCV_PREFIX=riscv-none-embed-
    #export RISCV_OBJDUMP="${RISCV_PREFIX}objdump --disassemble-all --disassemble-zeroes"
    #export RISCV=/apps/compilers/riscv-none-embed        
    #export PATH=$PATH:$RISCV/bin
fi
if [ $IS_LINUX_OS -eq 1 ] 
then
    export RISCV_PREFIX=riscv32-zephyr-elf-  
    export RISCV_OBJDUMP="${RISCV_PREFIX}objdump --disassemble-all --disassemble-zeroes"
    export RISCV=/opt/zephyr-sdk/sysroots/x86_64-pokysdk-linux/usr/bin/riscv32-zephyr-elf/
    export PATH=$PATH:$RISCV   
fi

########################################################################
# Setup ZEPHYR
########################################################################
if [ $IS_MSYS2_OS -eq 1 ] 
then
    export ZEPHYR_TOOLCHAIN_VARIANT=cross-compile
    export ZEPHYR_SDK_INSTALL_DIR=$RISCV/bin/
fi
if [ $IS_LINUX_OS -eq 1 ] 
then
    export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
    export ZEPHYR_SDK_INSTALL_DIR=/opt/zephyr-sdk
fi
