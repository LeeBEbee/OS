#include <swap.h>
#include <swapfs.h>
#include <mmu.h>
#include <fs.h>
#include <ide.h>
#include <pmm.h>
#include <assert.h>
//该代码用于管理交换区
//交换区是硬盘的一部分空间，当物理内存不足时，操作系统会把内存中的一部分数据暂时移到交换区，从而释放出内存空间

//初始化交换区文件系统
void
swapfs_init(void) {
    static_assert((PGSIZE % SECTSIZE) == 0);//静态断言保证内存页大小是扇区大小的整数倍
    if (!ide_device_valid(SWAP_DEV_NO)) { // 判断交换区设备是否有效
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
    //ide_device_size(SWAP_DEV_NO)返回最大扇区数量，此时为56。(PGSIZE / SECTSIZE)内存页中可有的扇区数目
    //由于数据交换时，操作系统以页为单位，此时需要指导交换区可以容纳多少个内存页，此时称为偏移量
    //偏移量实际上表示的是交换区中可以存放的内存页的数量
}

//从交换区读取一页数据
//entry是交换区条目，它包含了交换区中的一个页的地址
//page是一个Page结构的指针，它用于保存读取的数据
int
swapfs_read(swap_entry_t entry, struct Page *page) {
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
    // swap_offset(entry) 为计算偏移量，此时计算出开始的页的地址作为扇区编号
    //PAGE_NSECT：为每个页内扇区个数
    //page2kva(page)返回page的虚拟地址，此时将PAGE_NSECT个扇区（一页），从 swap_offset(entry) * PAGE_NSECT上写入到page2kva(page)中。
}

//向交换区写入一页数据
int
swapfs_write(swap_entry_t entry, struct Page *page) {
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
    //此时page2kva(page)为源地址
    //首先通过swap_offset(entry)获取交换区的偏移量
}

