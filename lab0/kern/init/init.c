#include <stdio.h>
//在linux下运行一个C程序，需要格式化输出，此时我么是自己写的stdio.h
#include <string.h>
#include <sbi.h>
//noreturn 告诉编译器这个函数不会返回
int kern_init(void) __attribute__((noreturn));

int kern_init(void) {
    extern char edata[], end[];
 //这里声明的两个符号，实际上由链接器ld在链接过程中定义, 所以加了extern关键字
    memset(edata, 0, end - edata);
// string.h声明一个函数，用于将s指向的内存区域的前n个字节设置为c
    const char *message = "(THU.CST) os is loading ...\n";
    cprintf("%s\n\n", message); //cprintf是我们自己定义的格式化输出函数
   while (1)
        ;
}
