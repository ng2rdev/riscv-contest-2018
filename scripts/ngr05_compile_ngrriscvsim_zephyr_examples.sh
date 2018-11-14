#######################################################################
#Compiles the Zephyr

pushd .
if [ $IS_MSYS2_OS -eq 1 ]
then
    export ZEPHYR_TOOLCHAIN_VARIANT=cross-compile
    export CROSS_COMPILE=$RISCV/bin/riscv32-unknown-elf-
    unset  ZEPHYR_SDK_INSTALL_DIR
    unset  $ZEPHYR_SDK_INSTALL_DIR
fi
if [ $IS_LINUX_OS -eq 1 ]
then
    export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
    export ZEPHYR_SDK_INSTALL_DIR=/opt/zephyr-sdk
fi    

curl -O 'https://bootstrap.pypa.io/get-pip.py'
./get-pip.py
rm get-pip.py

wget https://github.com/zephyrproject-rtos/zephyr/archive/zephyr-v1.13.0.tar.gz
tar -xzf zephyr-v1.13.0.tar.gz
patch p0 < ./scripts/zephyr-ngrriscv.patch
pip3 install -r zephyr-zephyr-v1.13.0/scripts/requirements.txt
cd zephyr-zephyr-v1.13.0
source zephyr-env.sh

cd samples/hello_world
mkdir build && cd build
cmake -GNinja -DBOARD=ggupduino2_ngrriscv ..
ninja 
cp ./zephyr/zephyr.elf /data/ngrriscv/ngrriscv-zephyr-tests/zephyr_hello_world.elf
cd ../..

cd samples/philosophers/
mkdir build && cd build
cmake -GNinja -DBOARD=ggupduino2_ngrriscv ..
ninja
cp ./zephyr/zephyr.elf /data/ngrriscv/ngrriscv-zephyr-tests/zephyr_philosophers.elf
cd ../.. 

cd samples/synchronization/
mkdir build && cd build
cmake -GNinja -DBOARD=ggupduino2_ngrriscv ..
ninja 
cp ./zephyr/zephyr.elf /data/ngrriscv/ngrriscv-zephyr-tests/zephyr_synchronization.elf
cd ../.. 
popd