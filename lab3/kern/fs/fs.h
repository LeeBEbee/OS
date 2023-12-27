#ifndef __KERN_FS_FS_H__
#define __KERN_FS_FS_H__

#include <mmu.h>

#define SECTSIZE            512
//定义的是扇区大小，扇区是硬盘读取数据的最小单位
#define PAGE_NSECT          (PGSIZE / SECTSIZE)
//每个页内的扇区个数

#define SWAP_DEV_NO         1
//SWAP_DEV_NO 是一个宏定义，其定义的值为1，代表交换设备的编号

#endif /* !__KERN_FS_FS_H__ */

