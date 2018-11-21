#######################################################################
#Compiles the Zephyr OS examples

pushd .

mkdir riscv-zephyr-examples

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
cp ./zephyr/zephyr.elf ${BASE_DIR}/riscv-zephyr-examples/zephyr_hello_world.elf
cd ../..

cd samples/philosophers/
mkdir build && cd build
cmake -GNinja -DBOARD=ggupduino2_ngrriscv ..
ninja
cp ./zephyr/zephyr.elf ${BASE_DIR}/riscv-zephyr-examples/zephyr_philosophers.elf
cd ../.. 

cd samples/synchronization/
mkdir build && cd build
cmake -GNinja -DBOARD=ggupduino2_ngrriscv ..
ninja 
cp ./zephyr/zephyr.elf ${BASE_DIR}/riscv-zephyr-examples/zephyr_synchronization.elf
cd ../.. 


declare -a rv32im_zephyr_examples=(
    "zephyr_hello_world" 
    "zephyr_philosophers" 
    "zephyr_synchronization")
 
for f in "${rv32im_zephyr_examples[@]}"
do
    ${RISCV_PREFIX}objdump -D --disassembler-options=no-aliases,numeric ${BASE_DIR}/riscv-zephyr-examples/${f}.elf  > ${BASE_DIR}/riscv-zephyr-examples/${f}.dump
    ${RISCV_PREFIX}objdump -t         ${BASE_DIR}/riscv-zephyr-examples/${f}.elf | sort > ${BASE_DIR}/riscv-zephyr-examples/${f}.symbs
    ${RISCV_PREFIX}objcopy -O srec    ${BASE_DIR}/riscv-zephyr-examples/${f}.elf ${BASE_DIR}/riscv-zephyr-examples/${f}.srec
    ${RISCV_PREFIX}objcopy -O binary  ${BASE_DIR}/riscv-zephyr-examples/${f}.elf ${BASE_DIR}/riscv-zephyr-examples/${f}.bin
    ${RISCV_PREFIX}objcopy -O verilog ${BASE_DIR}/riscv-zephyr-examples/${f}.elf ${BASE_DIR}/riscv-zephyr-examples/${f}.verilog
done

${BASE_DIR}/ctools/ngrriscvsim/ngrriscvsim.exe ${BASE_DIR}/riscv-zephyr-examples/zephyr_hello_world.bin
${BASE_DIR}/ctools/ngrriscvsim/ngrriscvsim.exe ${BASE_DIR}/riscv-zephyr-examples/zephyr_philosophers.bin
${BASE_DIR}/ctools/ngrriscvsim/ngrriscvsim.exe ${BASE_DIR}/riscv-zephyr-examples/zephyr_synchronization.bin


popd