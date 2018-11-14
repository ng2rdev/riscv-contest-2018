########################################################################
# Instructions for MSYS2
########################################################################
#   ###*** Install MSYS2                        ***
#   ###*** Start MSYS2 MSYS Shell               ***
pacman -Syu
#   ###*** Close window
#   ###*** Start new MSYS2 MSYS Shell           ***
pacman -S git cmake make gcc dtc diffutils ncurses-devel python3 gperf tar isl unzip


########################################################################
# Instructions for MSYS2
########################################################################
sudo yum install autoconf automake libmpc-devel mpfr-devel gmp-devel gawk  bison flex texinfo patchutils gcc gcc-c++ zlib-devel expat-devel isl


########################################################################
# Setup Directories
########################################################################
mkdir ngrriscv
cd ngrriscv/
mkdir ngrriscv-compiler
mkdir ngrriscv-compliance-tests
mkdir ngrriscv-dhrystones-tests
mkdir ngrriscv-zephyr-tests
cd ..

########################################################################
# Setup General Variables
########################################################################
export BASE_DIR=`pwd`
export XLEN=32
export ARCH=risc32
export RISCV_ISA=rv32im
export RISCV_GCC_OPTS_EXTRA="-march=rv32im -mabi=ilp32 -mstrict-align -mbranch-cost=4"
export RISCV_GCC_OPTS="$RISCV_GCC_OPTS_EXTRA -DPREALLOCATE=1 -mcmodel=medany -static -std=gnu99 -O3 -fno-inline -fno-builtin-printf"
export RISCV_OBJDUMP=$(RISCV_PREFIX)objdump --disassemble-all --disassemble-zeroes
export RISCV_SIM=ngrriscvsim --isa=rv32im
export IS_MSYS2_OS=$(grep -q MSYS_NT-6.1 <<< `uname -a` && echo "1" || echo "0")
export IS_LINUX_OS=$(grep -q Linux <<< `uname -a` && echo "1" || echo "0")


########################################################################
# Setup Compilers
########################################################################
if [ $IS_MSYS2_OS -eq 1 ] 
then
        #export RISCV_PREFIX=riscv32-unknown-elf-  
        #export RISCV=/apps/compilers/riscv32-unknown-elf    
        #export PATH=$PATH:$RISCV/bin/        
        export RISCV_PREFIX=riscv-none-embed-
        export RISCV=/apps/compilers/riscv-none-embed        
        export PATH=$PATH:$RISCV/bin
fi
if [ $IS_LINUX_OS -eq 1 ] 
then
    export RISCV_PREFIX=riscv32-zephyr-elf-  
    export RISCV=/opt/zephyr-sdk/sysroots/x86_64-pokysdk-linux/usr/bin/riscv32-zephyr-elf/
    export PATH=$PATH:$RISCV/bin/    
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

# ########################################################################
# # Compiles the GNU Toolchain
# ########################################################################
# git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
# cd riscv-gnu-toolchain/
# ./configure --prefix=$BASE_DIR/compilers/riscv32-unknown-elf XLEN=32 --with-arch=rv32im --with-abi=ilp32
# make
# export RISCV_PREFIX=riscv32-unknown-elf-  
# export RISCV=$BASE_DIR/compilers/riscv32-unknown-elf    
# export PATH=$PATH:$RISCV/bin/



#######################################################################
#Compiles the DhryStones Benchmark
git clone https://github.com/riscv/riscv-tests
cd riscv-tests
git submodule update --init --recursive
autoconf
./configure --prefix=$RISCV/target --with-xlen=$XLEN
make benchmarks
cp $BASE_DIR/riscv-tests/benchmarks/dhrystone.riscv* $BASE_DIR/ngrriscv-dhrystones-tests/
cd ..


#######################################################################
#Compiles the RISC-V Compliance tests
git clone --recursive https://github.com/riscv/riscv-compliance
cd riscv-compliance
make RISCV_TARGET=riscvOVPsim RISCV_DEVICE=rv32im
cd ..

#######################################################################
#Compiles the Zephyr

pushd .
mkdir python36 && cd python36
wget https://www.python.org/ftp/python/3.6.4/Python-3.6.4.tar.xz
tar -xJf Python-3.6.4.tar.xz
cd Python-3.6.4
./configure -prefix=/usr/local/
sudo make altinstall
sudo ln -s /usr/local/bin/python3.6 /usr/bin/python3
sudo ln -s /usr/local/bin/python3.6 /usr/local/bin/python3
sudo ln -s /usr/local/bin/pip3.6 /usr/bin/pip3
sudo ln -s /usr/local/bin/pip3.6 /usr/local/bin/pip3
python3 --version
popd

pushd .
mkdir cmake && cd cmake
wget https://cmake.org/files/v3.8/cmake-3.8.2-Linux-x86_64.sh
yes | sh cmake-3.8.2-Linux-x86_64.sh | cat
echo "export PATH=$PWD/cmake-3.8.2-Linux-x86_64/bin:\$PATH" >> $HOME/.zephyrrc
cmake --version
popd

pushd .
git clone git://github.com/ninja-build/ninja.git && cd ninja
git checkout release
./configure.py --bootstrap
cp ninja.exe /usr/bin/
popd

curl -O 'https://bootstrap.pypa.io/get-pip.py'
./get-pip.py
rm get-pip.py

pushd .
mkdir zephyr-sdk && cd zephyr-sdk
wget https://github.com/zephyrproject-rtos/meta-zephyr-sdk/releases/download/0.9.3/zephyr-sdk-0.9.3-setup.run
sudo sh zephyr-sdk-0.9.3-setup.run
export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
export ZEPHYR_SDK_INSTALL_DIR=/opt/zephyr-sdk
popd


git clone --config core.autocrlf=false https://github.com/zephyrproject-rtos/zephyr
pip3 install -r zephyr/scripts/requirements.txt
cd zephyr
source zephyr-env.sh
cd samples/hello_world
mkdir build && cd build
#cmake -DBOARD=qemu_riscv32 ..
cmake -GNinja -DBOARD=qemu_riscv32 ..
ninja 
 





#######################################################################
# msys2 configuration
pacman -S cmake mingw-w64-x86_64-ninja

pacman -S git cmake make gcc dtc diffutils ncurses-devel python3 gperf tar isl
