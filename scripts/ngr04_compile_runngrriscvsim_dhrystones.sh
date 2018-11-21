#######################################################################
###     Compiles the DhryStones Benchmark
#######################################################################
pushd .


mkdir riscv-dhrystones
cd riscv-dhrystones
patch -p1 < ../scripts/riscv-dhrystones_ngrriscv.patch
make

${BASE_DIR}/ctools/ngrriscvsim/ngrriscvsim.exe ${BASE_DIR}/riscv-dhrystones/build/dhrystone.bin


popd