#include <assert.h>
#include <defs.h>
#include <fs.h>
#include <ide.h>
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
//硬盘驱动的初始化函数
#define MAX_IDE 2 //定义了最大的IDE设备数量为2
#define MAX_DISK_NSECS 56 //定义了硬盘的最大扇区数量为56
static char ide[MAX_DISK_NSECS * SECTSIZE];//定义了一个内存数组来模拟硬盘的存储空间，大小为最大扇区数量乘以扇区大小
//此处SECESIZE大小为512 2^9
bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
// 判断IDE设备是否有效的函数，如果设备编号小于最大支持设备数，那么设备有效

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
// 获取IDE设备的大小，这里为硬盘的扇区数量

// 从硬盘读取扇区
//ideno:设备编号 secno:扇区编号  dst：目标地址  nsecs：扇区数量
//ideno: 假设挂载了多块磁盘，选择哪一块磁盘 这里我们其实只有一块“磁盘”，这个参数就没用到
int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
        //计算要读取扇区的偏移地址
    int iobase = secno * SECTSIZE;
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
    //memcpy(目的地址指针，源地址指针，要复制的长度)
    //只允许以磁盘扇区为数据传输的基本单位
    return 0;
}

//将数据写入硬盘扇区
//ideno:设备编号 secno:扇区编号  src：源地址  nsecs：扇区数量
int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
    int iobase = secno * SECTSIZE;
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
    return 0;
}
