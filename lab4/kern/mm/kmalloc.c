#include <defs.h>
#include <list.h>
#include <memlayout.h>
#include <assert.h>
#include <kmalloc.h>
#include <sync.h>
#include <pmm.h>
#include <stdio.h>

/*
 * SLOB Allocator: Simple List Of Blocks
 *
 * Matt Mackall <mpm@selenic.com> 12/30/03
 *
 * How SLOB works:
 *
 * The core of SLOB is a traditional K&R style heap allocator, with
 * support for returning aligned objects. The granularity of this
 * allocator is 8 bytes on x86, though it's perhaps possible to reduce
 * this to 4 if it's deemed worth the effort. The slob heap is a
 * singly-linked list of pages from __get_free_page, grown on demand
 * and allocation from the heap is currently first-fit.
 *
 * Above this is an implementation of kmalloc/kfree. Blocks returned
 * from kmalloc are 8-byte aligned and prepended with a 8-byte header.
 * If kmalloc is asked for objects of PAGE_SIZE or larger, it calls
 * __get_free_pages directly so that it can return page-aligned blocks
 * and keeps a linked list of such pages and their orders. These
 * objects are detected in kfree() by their page alignment.
 *
 * SLAB is emulated on top of SLOB by simply calling constructors and
 * destructors for every SLAB allocation. Objects are returned with
 * the 8-byte alignment unless the SLAB_MUST_HWCACHE_ALIGN flag is
 * set, in which case the low-level allocator will fragment blocks to
 * create the proper alignment. Again, objects of page-size or greater
 * are allocated by calling __get_free_pages. As SLAB objects know
 * their size, no separate size bookkeeping is necessary and there is
 * essentially no allocation space overhead.
 */


//some helper
#define spin_lock_irqsave(l, f) local_intr_save(f)
#define spin_unlock_irqrestore(l, f) local_intr_restore(f)
typedef unsigned int gfp_t;
#ifndef PAGE_SIZE
#define PAGE_SIZE PGSIZE
#endif

#ifndef L1_CACHE_BYTES
#define L1_CACHE_BYTES 64
#endif

#ifndef ALIGN
#define ALIGN(addr,size)   (((addr)+(size)-1)&(~((size)-1))) 
#endif


struct slob_block {
	int units;
	struct slob_block *next;
};
typedef struct slob_block slob_t;

#define SLOB_UNIT sizeof(slob_t)
#define SLOB_UNITS(size) (((size) + SLOB_UNIT - 1)/SLOB_UNIT)
#define SLOB_ALIGN L1_CACHE_BYTES

struct bigblock {
	int order;
	void *pages;
	struct bigblock *next;
};
typedef struct bigblock bigblock_t;

static slob_t arena = { .next = &arena, .units = 1 };
static slob_t *slobfree = &arena;
static bigblock_t *bigblocks;

static void* __slob_get_free_pages(gfp_t gfp, int order)
{
  struct Page * page = alloc_pages(1 << order);
  if(!page)
    return NULL;
  return page2kva(page);
}

#define __slob_get_free_page(gfp) __slob_get_free_pages(gfp, 0)

static inline void __slob_free_pages(unsigned long kva, int order)
{
  free_pages(kva2page(kva), 1 << order);
}

static void slob_free(void *b, int size);

// 定义一个名为slob_alloc的函数，需要三个参数：请求的内存大小（size）、内存分配标志（gfp）和内存对齐值（align）。
static void *slob_alloc(size_t size, gfp_t gfp, int align)
{	
	// 首先，确保请求的内存大小加上最小内存单位不超过一个页面的大小
	assert( (size + SLOB_UNIT) < PAGE_SIZE );
	// 定义了三个指针：prev、cur和aligned，分别表示在内存链表中的前一个块、当前块和需要对齐的块
	slob_t *prev, *cur, *aligned = 0;
	int delta = 0, units = SLOB_UNITS(size);
	unsigned long flags;

	// 使用spin_lock_irqsave函数关闭中断并获取自旋锁，保护临界区的操作
	spin_lock_irqsave(&slob_lock, flags);
	// 初始化prev和cur指针，使其指向空闲内存的链表头
	prev = slobfree;
	// 使用for循环遍历整个空闲内存链表
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
		// 如果需要进行内存对齐，则计算对齐之后的内存块地址，以及由于对齐导致的内存偏移
		if (align) {
			aligned = (slob_t *)ALIGN((unsigned long)cur, align);
			delta = aligned - cur;
		}
		if (cur->units >= units + delta) { /* room enough? */
			if (delta) { /* need to fragment head to align? */
				aligned->units = cur->units - delta;
				aligned->next = cur->next;
				cur->next = aligned;
				cur->units = delta;
				prev = cur;
				cur = aligned;
			}

			if (cur->units == units) /* exact fit? */
				prev->next = cur->next; /* unlink */
			else { /* fragment */
				prev->next = cur + units;
				prev->next->units = cur->units - units;
				prev->next->next = cur->next;
				cur->units = units;
			}

			slobfree = prev;
			spin_unlock_irqrestore(&slob_lock, flags);
			return cur;
		}
		if (cur == slobfree) {
			spin_unlock_irqrestore(&slob_lock, flags);

			if (size == PAGE_SIZE) /* trying to shrink arena? */
				return 0;

			cur = (slob_t *)__slob_get_free_page(gfp);
			if (!cur)
				return 0;

			slob_free(cur, PAGE_SIZE);
			spin_lock_irqsave(&slob_lock, flags);
			cur = slobfree;
		}
	}
}

static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
		return;

	if (size)
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
		if (cur >= cur->next && (b > cur || b < cur->next))
			break;

	if (b + b->units == cur->next) {
		b->units += cur->next->units;
		b->next = cur->next->next;
	} else
		b->next = cur->next;

	if (cur + cur->units == b) {
		cur->units += b->units;
		cur->next = b->next;
	} else
		cur->next = b;

	slobfree = cur;

	spin_unlock_irqrestore(&slob_lock, flags);
}



void
slob_init(void) {
  cprintf("use SLOB allocator\n");
}

inline void 
kmalloc_init(void) {
    slob_init();
    cprintf("kmalloc_init() succeeded!\n");
}

size_t
slob_allocated(void) {
  return 0;
}

size_t
kallocated(void) {
   return slob_allocated();
}

static int find_order(int size)
{
	int order = 0;
	for ( ; size > 4096 ; size >>=1)
		order++;
	return order;
}

static void *__kmalloc(size_t size, gfp_t gfp)
{	
	// 定义一个slob_t类型的指针m，用来接收slob_alloc函数返回的内存块
	slob_t *m;
	// 定义一个bigblock_t类型的指针bb，用来接收slob_alloc函数返回的大内存块
	bigblock_t *bb;
	//用来保存中断状态
	unsigned long flags;

	if (size < PAGE_SIZE - SLOB_UNIT) {
		// 调用slob_alloc函数，试图分配一个大小为size + SLOB_UNIT的内存块
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
		// 如果分配成功（m不为NULL），则返回分配到的内存块的地址
		return m ? (void *)(m + 1) : 0;
	}
	// 如果请求的内存大小大于页大小减去一个SLOB_UNIT，那么就尝试在slob中分配一个bigblock_t类型的内存块
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
	// 如果分配失败（bb为NULL），则返回0
	if (!bb)
		return 0;

	// 调用find_order函数，计算需要分配的页的数量
	bb->order = find_order(size);
	// 调用__slob_get_free_pages函数，尝试获取bb->order数量的空闲页。
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
	// 如果成功获取了空闲页
	if (bb->pages) {
		// 获取自旋锁block_lock，同时保存当前的中断状态
		spin_lock_irqsave(&block_lock, flags);
		// 将bb插入到大块内存链表bigblocks的头部
		bb->next = bigblocks;
		// 更新大块内存链表bigblocks的头指针为bb
		bigblocks = bb;
		 // 释放自旋锁block_lock，同时恢复之前保存的中断状态
		spin_unlock_irqrestore(&block_lock, flags);
		// 返回分配到的内存块的地址
		return bb->pages;
	}
	// 如果没有成功获取空闲页，则释放之前分配的bigblock_t类型的内存块
	slob_free(bb, sizeof(bigblock_t));
	return 0;
}

void *
kmalloc(size_t size)
{
  return __kmalloc(size, 0);
}


void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
		return;

	if (!((unsigned long)block & (PAGE_SIZE-1))) {
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
			if (bb->pages == block) {
				*last = bb->next;
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
				slob_free(bb, sizeof(bigblock_t));
				return;
			}
		}
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}


unsigned int ksize(const void *block)
{
	bigblock_t *bb;
	unsigned long flags;

	if (!block)
		return 0;

	if (!((unsigned long)block & (PAGE_SIZE-1))) {
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; bb = bb->next)
			if (bb->pages == block) {
				spin_unlock_irqrestore(&slob_lock, flags);
				return PAGE_SIZE << bb->order;
			}
		spin_unlock_irqrestore(&block_lock, flags);
	}

	return ((slob_t *)block - 1)->units * SLOB_UNIT;
}



