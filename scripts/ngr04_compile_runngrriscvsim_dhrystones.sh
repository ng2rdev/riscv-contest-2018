#######################################################################
###     Compiles the DhryStones Benchmark
#######################################################################
pushd .
git clone https://github.com/riscv/riscv-tests
cd riscv-tests
git submodule update --init --recursive
autoconf
./configure --prefix=$RISCV/target --with-xlen=$XLEN

#######################################################################
### Applies two patches: 
###   1st - Only want to compile dhrystone (rv32im use implies error on mm benchmark)
###   2nd - Added my own function to print characters on UART Peripheral

sed 's/bmarks =/bmarks = dhrystone\nbmarks_old =/g' ./benchmarks/Makefile -i
patch -p0 <<'EOF'
--- ./benchmarks/common/syscalls_old.c	2018-10-27 12:06:34.187801400 +0100
+++ ./benchmarks/common/syscalls.c	2018-10-27 12:25:55.863301400 +0100
@@ -15,21 +15,32 @@
 extern volatile uint64_t tohost;
 extern volatile uint64_t fromhost;
 
+#define UART_BASE_ADDRESS        (0x8000C000)
+#define UART_DATA_TX_REG         (UART_BASE_ADDRESS + 0x0)
+#define UART_STATUS_REG          (UART_BASE_ADDRESS + 0x4)
+#define UART_CONTROL_REG         (UART_BASE_ADDRESS + 0x4)
+
+#define TX_BUSY_FLAG_BIT         (1<<1)
+#define SEND_TX_BIT              (1<<4)
+
+void outbyte (char value){  
+    while (((*(volatile unsigned int*)(UART_STATUS_REG)) & TX_BUSY_FLAG_BIT) == TX_BUSY_FLAG_BIT);
+	(*(volatile unsigned int *)(UART_DATA_TX_REG) = value);
+    (*(volatile unsigned int *)(UART_CONTROL_REG) = SEND_TX_BIT); 
+}
+
+
 static uintptr_t syscall(uintptr_t which, uint64_t arg0, uint64_t arg1, uint64_t arg2)
-{
+{      
   volatile uint64_t magic_mem[8] __attribute__((aligned(64)));
-  magic_mem[0] = which;
-  magic_mem[1] = arg0;
-  magic_mem[2] = arg1;
-  magic_mem[3] = arg2;
-  __sync_synchronize();
-
-  tohost = (uintptr_t)magic_mem;
-  while (fromhost == 0)
-    ;
-  fromhost = 0;
 
-  __sync_synchronize();
+  if (which==SYS_write){
+        int i = 0;
+        int len = (int) arg2;
+        char *s = (char *) arg1;
+        for (i=0; i<len; i++) 
+            outbyte(s[i]);      
+  }           
   return magic_mem[0];
 }
EOF

make benchmarks
cp $BASE_DIR/riscv-tests/benchmarks/dhrystone.riscv $BASE_DIR/ngrriscv-dhrystones-tests/
$RISCV_OBJDUMP --disassembler-options=no-aliases,numeric -t $BASE_DIR/ngrriscv-dhrystones-tests/dhrystone.riscv > $BASE_DIR/ngrriscv-dhrystones-tests/dhrystone.riscv.dump
${RISCV_PREFIX}objdump -D         $BASE_DIR/ngrriscv-dhrystones-tests/dhrystone.riscv | sort > $BASE_DIR/ngrriscv-dhrystones-tests/dhrystone.riscv.symbs
${RISCV_PREFIX}objcopy -O srec    $BASE_DIR/ngrriscv-dhrystones-tests/dhrystone.riscv $BASE_DIR/ngrriscv-dhrystones-tests/dhrystone.riscv.srec
${RISCV_PREFIX}objcopy -O binary  $BASE_DIR/ngrriscv-dhrystones-tests/dhrystone.riscv $BASE_DIR/ngrriscv-dhrystones-tests/dhrystone.riscv.bin
${RISCV_PREFIX}objcopy -O verilog $BASE_DIR/ngrriscv-dhrystones-tests/dhrystone.riscv $BASE_DIR/ngrriscv-dhrystones-tests/dhrystone.riscv.verilog

popd