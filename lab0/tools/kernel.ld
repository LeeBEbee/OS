/* Simple linker script for the ucore kernel.
   See the GNU ld 'info' manual ("info ld") to learn the syntax. */

OUTPUT_ARCH(riscv) /* 指定输出文件的指令集架构, 在riscv平台上运行 */
ENTRY(kern_entry)  /*指定程序入口*/

BASE_ADDRESS = 0x80200000; /*指定基地址*/

SECTIONS
{
    /* Load the kernel at this address: "." means the current address */
    . = BASE_ADDRESS;/*对.赋值为基地址*/

    .text : {
        *(.text.kern_entry .text .stub .text.* .gnu.linkonce.t.*)/*将输入文件中的 .text.kern_entry、.text、.stub、所有以 .text. 开头的段，以及所有以 .gnu.linkonce.t. 开头的段，合并到输出文件的 .text 段中。*/
    }

    PROVIDE(etext = .); /* Define the 'etext' symbol to this value */

    .rodata : {
        *(.rodata .rodata.* .gnu.linkonce.r.*)
    }

    /* Adjust the address for the data segment to the next page */
    . = ALIGN(0x1000);
	/*按页对齐*/
    /* The data segment */
    .data : {
        *(.data)
        *(.data.*)
    }
    /* small data section, 存储字节数小于某个标准的变量，一般是char, short等类型的 */
    .sdata : {
        *(.sdata)
        *(.sdata.*)
    }

    PROVIDE(edata = .);
    /*PROVIDE 是链接器脚本的一个命令，用于定义一个符号并给它赋值*/
    .bss : {
        *(.bss)
        *(.bss.*)
        *(.sbss*)
    }

    PROVIDE(end = .);
 /* /DISCARD/表示忽略，输入文件里 *(.eh_frame .note.GNU-stack)这些section都被忽略，不会加入到输出文件中 */
    /DISCARD/ : {
        *(.eh_frame .note.GNU-stack)
    }
}
