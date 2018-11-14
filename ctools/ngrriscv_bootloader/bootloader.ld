OUTPUT_ARCH( "riscv" )

ENTRY( _start )

MEMORY
{
  rom (rxai!w)   : ORIGIN = 0xF000, LENGTH = 1K
  ram (wxa!ri)   : ORIGIN = 0x4000, LENGTH = 1K
}


SECTIONS
{
  __stack_size = 512;

  .init           :
  {
    KEEP (*(SORT_NONE(.init)))
  } >rom 

  .text           :
  {
    *(.text.unlikely .text.unlikely.*)
    *(.text.startup .text.startup.*)
    *(.text .text.*)
    *(.gnu.linkonce.t.*)
    *(.note.gnu.build-id)
  } >rom 

  .data          :
  {
    *(.rdata)
    *(.rodata .rodata.*)
    *(.gnu.linkonce.r.*)
    *(.data .data.*)
    *(.gnu.linkonce.d.*)
    . = ALIGN(8);
    PROVIDE( __global_pointer$ = . + 0x800 );
    *(.sdata .sdata.*)
    *(.gnu.linkonce.s.*)
    . = ALIGN(8);
    *(.srodata.cst16)
    *(.srodata.cst8)
    *(.srodata.cst4)
    *(.srodata.cst2)
    *(.srodata .srodata.*)
  } >ram 

  . = ALIGN(4);
  PROVIDE( _edata = . );
  PROVIDE( edata = . );

  PROVIDE( _fbss = . );
  PROVIDE( __bss_start = . );
  .bss            :
  {
    *(.sbss*)
    *(.gnu.linkonce.sb.*)
    *(.bss .bss.*)
    *(.gnu.linkonce.b.*)
    *(COMMON)
    . = ALIGN(4);
  } >ram 

  . = ALIGN(8);
  PROVIDE( _end = . );
  PROVIDE( end = . );

  .stack          :
  {
    PROVIDE( _heap_end = . );
    PROVIDE( _stack_end = . );
    . += __stack_size;
    PROVIDE( _sp = . );
  } >ram 
}