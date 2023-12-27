#include <sbi.h>  // 包含sbi头文件，sbi（Supervisor Binary Interface）是RISC-V架构中的一种接口定义，用于操作系统和硕士模式之间的交互
#include <console.h>  // 包含console头文件，提供控制台操作相关的函数和数据结构定义

/* kbd_intr - try to feed input characters from keyboard */
void kbd_intr(void) {}  // 从键盘获取输入字符的函数，目前为空函数，没有实现

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}  // 从串行端口获取输入字符的函数，目前为空函数，没有实现

/* cons_init - initializes the console devices */
void cons_init(void) {}  // 初始化控制台设备的函数，目前为空函数，没有实现

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }  // 打印一个字符到控制台的函数，调用sbi的sbi_console_putchar函数实现

/* *
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {  // 从控制台获取输入字符的函数
    int c = 0;  // 定义一个整型变量c并初始化为0
    c = sbi_console_getchar();  // 调用sbi的sbi_console_getchar函数获取输入字符，并赋值给c
    return c;  // 返回c
}
