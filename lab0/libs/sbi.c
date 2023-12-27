
#include <sbi.h> // 导入sbi库
#include <defs.h> // 导入defs库

// 定义SBI调用的类型
uint64_t SBI_SET_TIMER = 0; // 设置计时器
uint64_t SBI_CONSOLE_PUTCHAR = 1; // 控制台输出字符
uint64_t SBI_CONSOLE_GETCHAR = 2; // 控制台获取字符
uint64_t SBI_CLEAR_IPI = 3; // 清除IPI
uint64_t SBI_SEND_IPI = 4; // 发送IPI
uint64_t SBI_REMOTE_FENCE_I = 5; // 远程I指令栅栏
uint64_t SBI_REMOTE_SFENCE_VMA = 6; // 远程VMA存储栅栏
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7; // 远程VMA存储栅栏ASID
uint64_t SBI_SHUTDOWN = 8; // 关机

// 定义一个函数sbi_call，用于进行SBI调用
uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
uint64_t ret_val; // 定义一个变量，用于存储返回值
// 使用内联汇编进行SBI调用
asm volatile (
“mv x17, %[sbi_type]\n” // 将sbi_type移动到寄存器x17
“mv x10, %[arg0]\n” // 将arg0移动到寄存器x10
“mv x11, %[arg1]\n” // 将arg1移动到寄存器x11
“mv x12, %[arg2]\n” // 将arg2移动到寄存器x12
“ecall\n” // 使能异常调用
“mv %[ret_val], x10” // 将寄存器x10的值移动到ret_val
//我们还需要自己通过内联汇编把返回值拿到我们的变量里
: [ret_val] “=r” (ret_val) // 输出部分，将寄存器的值移动到C变量
: [sbi_type] “r” (sbi_type), [arg0] “r” (arg0), [arg1] “r” (arg1), [arg2] “r” (arg2) // 输入部分，将C变量的值移动到寄存器
: “memory” // 告诉编译器这段汇编可能会改变内存
);
return ret_val; // 返回值
}

// 定义一个函数，用于在控制台输出一个字符
void sbi_console_putchar(unsigned char ch) {
sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0); // 调用SBI_CONSOLE_PUTCHAR进行输出
}

// 定义一个函数，用于设置计时器
void sbi_set_timer(unsigned long long stime_value) {
sbi_call(SBI_SET_TIMER, stime_value, 0, 0); // 调用SBI_SET_TIMER进行设置
}