#include <mmu.h>
#include <memlayout.h>
//此处进行内核栈的分配，然后转入C语言编写的内核初始化函数
    .section .text,"ax",%progbits  //指定一个.text的节，后两个参数指定特征
    .globl kern_entry //声明了一个全局符号，此处为入口处标签
kern_entry:
    la sp, bootstacktop //加载bootstacktop的地址到堆栈寄存器sp

    tail kern_init //跳转至kern_init函数

.section .data //指定一个.data的节
    # .align 2^12
    .align PGSHIFT //下一条指定和数据的对齐方式为页大小
    .global bootstack //声明一个全局符号
bootstack:
    .space KSTACKSIZE //空出一个大小为KSTACKSIZE的空间
    .global bootstacktop //声明一个全局符号
bootstacktop: