########################################################################
# Instructions for MSYS2
########################################################################
pushd .
cd ${BASE_DIR}/ctools/ngrriscvsim
gcc -O2 -DDEBUG ngrriscvsim.c -o  ngrriscvsim.exe
popd