
########################################################################
# Install Instructions for
#	1) Dependency Packages
#	2) riscv32im gcc/binutils compiler
#	3) python3 (install from sources for CentOS; install package in msys2)
#	4) cmake   (install binary for CentOS; install package in msys2)	
#	5) ninja 
#
########################################################################
# Instructions for MSYS2
########################################################################
#   #*** Install MSYS2                        ***
#   #*** Start MSYS2 MSYS Shell               ***
#	pacman -Syu
#   #*** Close window
#   #*** Start new MSYS2 MSYS Shell           ***
#   pacman -S git make cmake gcc dtc ncurses-devel gperf tar isl-devel unzip gmp-devel mpfr-devel mpc-devel gawk bison flex texinfo zlib-devel libexpat-devel python3 python3-pip
#
########################################################################
# Instructions for CENTOS 7
########################################################################
#	sudo yum install autoconf tar unzip automake libmpc-devel mpfr-devel gmp-devel gawk  bison flex texinfo patchutils gcc gcc-c++ zlib-devel expat-devel isl gperf
#


export IS_MSYS2_OS=$(grep -q MSYS_NT-6.1 <<< `uname -a` && echo "1" || echo "0")
export IS_LINUX_OS=$(grep -q Linux <<< `uname -a` && echo "1" || echo "0")
export BASE_DIR=`pwd`


########################################################################
# Fetches/Compiles/Installs RISCV32 GNU GCC Compiler
########################################################################
if [ $IS_MSYS2_OS -eq 1 ] 
then
    if [ $1 -eq 0 ] 
    then
        git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
        cd riscv-gnu-toolchain/
        ./configure --prefix=$BASE_DIR/compilers/riscv32-unknown-elf XLEN=32 --with-arch=rv32im --with-abi=ilp32
        make
        export RISCV_PREFIX=riscv32-unknown-elf-  
        export RISCV=$BASE_DIR/compilers/riscv32-unknown-elf    
        export PATH=$PATH:$RISCV/bin/    
    fi

    if [ $1 -eq 1 ]     
    then
        wget https://github.com/gnu-mcu-eclipse/riscv-none-gcc/releases/download/v8.1.0-2-20181019/gnu-mcu-eclipse-riscv-none-gcc-8.1.0-2-20181019-0952-win64.zip
        unzip gnu-mcu-eclipse-riscv-none-gcc-8.1.0-2-20181019-0952-win64.zip
        cd gnu-mcu-eclipse/riscv-none-gcc/8.1.0-2-20181019-0952
        mkdir /apps/compilers/riscv-none-embed/
        mv * /apps/compilers/riscv-none-embed/
        cd ../../../
        rm -rf gnu-mcu-eclipse/    
        rm -rf gnu-mcu-eclipse-riscv-none-gcc-8.1.0-2-20181019-0952-win64.zip        
        export RISCV_PREFIX=riscv-none-embed-
        export RISCV=/apps/compilers/riscv-none-embed        
        export PATH=$PATH:$RISCV/bin
    fi
fi
if [ $IS_LINUX_OS -eq 1 ] 
then
    pushd .
    mkdir zephyr-sdk && cd zephyr-sdk
    wget https://github.com/zephyrproject-rtos/meta-zephyr-sdk/releases/download/0.9.3/zephyr-sdk-0.9.3-setup.run
    sudo sh zephyr-sdk-0.9.3-setup.run
    export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
    export ZEPHYR_SDK_INSTALL_DIR=/opt/zephyr-sdk
    popd  
fi

########################################################################
# Fetches/Compiles/Installs python3
########################################################################

if [ $IS_LINUX_OS -eq 1 ] 
then
    pushd .
    mkdir python36 && cd python36
    wget https://www.python.org/ftp/python/3.6.4/Python-3.6.4.tar.xz
    tar -xJf Python-3.6.4.tar.xz
    cd Python-3.6.4
    ./configure -prefix=/usr/local/
    make altinstall
    ln -s /usr/local/bin/python3.6 /usr/bin/python3
    ln -s /usr/local/bin/python3.6 /usr/local/bin/python3
    ln -s /usr/local/bin/pip3.6 /usr/bin/pip3
    ln -s /usr/local/bin/pip3.6 /usr/local/bin/pip3
    python3 --version
    popd
fi
########################################################################
# Fetches/Compiles/Installs cmake
########################################################################
if [ $IS_LINUX_OS -eq 1 ] 
then
    pushd .
    mkdir cmake && cd cmake
    wget https://cmake.org/files/v3.8/cmake-3.8.2-Linux-x86_64.sh
    yes | sh cmake-3.8.2-Linux-x86_64.sh | cat
    echo "export PATH=$PWD/cmake-3.8.2-Linux-x86_64/bin:\$PATH" >> $HOME/.zephyrrc
    cmake --version
    popd
fi

########################################################################
# Fetches/Compiles/Installs ninja
########################################################################
pushd .
git clone git://github.com/ninja-build/ninja.git && cd ninja
git checkout release
./configure.py --bootstrap
cp ninja.exe /usr/bin/
pushd .
