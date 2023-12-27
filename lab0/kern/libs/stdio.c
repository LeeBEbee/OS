#include <console.h>
#include <defs.h>
#include <stdio.h>

/* *
 * cputch - 将单个字符 @c 写入 stdout，并将 @cnt 指向的计数器值加1。
 * */
static void cputch(int c, int *cnt) {
    cons_putc(c);  // 将字符 c 写入控制台
    (*cnt)++;      // 增加字符计数器的值
}

/* *
 * vcprintf - 根据给定的格式字符串 @fmt 和参数列表 @ap 格式化字符串并将其写入 stdout
 *
 * 返回值是写入 stdout 的字符数。
 * 如果你已经处理过一个 va_list，那么调用这个函数。
 * 否则，你可能更喜欢 cprintf()。
 * */
int vcprintf(const char *fmt, va_list ap) {
    int cnt = 0;   
    vprintfmt((void *)cputch, &cnt, fmt, ap);  // 调用 vprintfmt 函数来处理格式化字符串
    return cnt;  // 返回写入的字符数
}

/* *
 * cprintf - 根据给定的格式字符串 @fmt 和可变参数列表格式化字符串并将其写入 stdout
 *
 * 返回值是写入 stdout 的字符数。
 * */
int cprintf(const char *fmt, ...) {
    va_list ap;
    int cnt;
    va_start(ap, fmt);        // 初始化可变参数列表
    cnt = vcprintf(fmt, ap);  // 调用 vcprintf 来处理格式化字符串
    va_end(ap);               // 清理可变参数列表
    return cnt;               // 返回写入的字符数
}

/* cputchar - 将单个字符 @c 写入 stdout */
void cputchar(int c) { cons_putc(c); }

/* *
 * cputs- 将字符串 @str 写入 stdout 并在末尾添加一个换行符。
 * */
int cputs(const char *str) {
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0') {  // 遍历字符串 str
        cputch(c, &cnt);             // 将字符 c 写入 stdout 并增加计数器的值
    }
    cputch('\n', &cnt);  // 在末尾添加一个换行符
    return cnt;          // 返回写入的字符数
}

/* getchar - 从 stdin 读取一个非零字符 */
int getchar(void) {
    int c;
    while ((c = cons_getc()) == 0) /* do nothing */ ;  // 如果读取的字符是零，那么一直等待直到读取到一个非零字符
    return c;  // 返回读取的字符
} 
