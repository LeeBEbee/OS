#ifndef __KERN_PROCESS_PROC_H__
#define __KERN_PROCESS_PROC_H__

#include <defs.h>
#include <list.h>
#include <trap.h>
#include <memlayout.h>


// process's state in his life cycle
enum proc_state {
    PROC_UNINIT = 0,  // uninitialized 进程刚被创建但还未被初始化的状态，该进程仅仅是一个空壳，未分配任何资源或代码
    PROC_SLEEPING,    // sleeping
    PROC_RUNNABLE,    // runnable(maybe running) 已准备好运行，可能正在运行
    PROC_ZOMBIE,      // almost dead, and wait parent proc to reclaim his resource
    //已经结束，等待父进程回收其资源
};
//保存一个进程（或线程）的执行上下文
struct context {
    uintptr_t ra;//表示返回地址寄存器的值。当一个函数调用另一个函数时，会把返回地址保存在ra寄存器中
    uintptr_t sp;//表示栈指针寄存器的值。栈指针寄存器指向进程的栈顶，用于支持函数调用和局部变量的存储
    //剩下的是各种通用寄存器
    uintptr_t s0;
    uintptr_t s1;
    uintptr_t s2;
    uintptr_t s3;
    uintptr_t s4;
    uintptr_t s5;
    uintptr_t s6;
    uintptr_t s7;
    uintptr_t s8;
    uintptr_t s9;
    uintptr_t s10;
    uintptr_t s11;
};//上下文只保存了部分寄存器，因为线程切换在一个函数当中
//编译器会自动帮助我们生成保存和恢复调用者保存寄存器的代码
//在实际的进程切换过程中我们只需要保存被调用者保存寄存器

#define PROC_NAME_LEN               15
#define MAX_PROCESS                 4096
#define MAX_PID                     (MAX_PROCESS * 2)

extern list_entry_t proc_list;

struct proc_struct {
    enum proc_state state;                      // 进程的状态
    //一共可以有这四种状态：
    //PROC_UNINIT 0：进程初始状态，表示进程已经被创建，但尚未初始化
    //PROC_SLEEPING 1：进程睡眠状态，表示进程正在等待某种条件，当这个条件满足时，进程会被唤醒并变为可运行状态，当这个条件满足时，进程会被唤醒并变为可运行状态
    //PROC_RUNNABLE 2：进程可运行状态，表示进程已经准备好运行，只是等待CPU的调度
    //PROC_ZOMBIE 3：进程僵尸状态，表示进程已经结束运行，但其父进程尚未收到其结束的通知，进程的一些资源（例如进程描述符）还没有被完全释放
    int pid;                                    // 进程的ID
    int runs;                                   // 进程的运行次数
    uintptr_t kstack;                           // 进程的内核栈
    //内核栈是在内核态下使用的栈，当进程从用户态切换到内核态时，会切换到内核栈进行运行
    //内核栈中主要保存的是进程在内核态运行时的一些临时数据，以及在发生上下文切换时保存进程的执行现场。
    volatile bool need_resched;                 // 表示进程是否需要被重新调度以释放CPU
    struct proc_struct *parent;                 // 指向父进程的指针
    //在内核中，只有内核创建的idle进程没有父进程，其他进程都有父进程。
    //进程的父子关系组成了一棵进程树
    struct mm_struct *mm;                       // 用来表示进程的内存管理字段,这里面保存了内存管理的信息，包括内存映射，虚存管理等内容。
    struct context context;                     // 在这里切换以运行进程
    //context中保存了进程执行的上下文，也就是几个关键的寄存器的值
    //这些寄存器的值用于在进程切换中还原之前进程的运行状态
    // 2 个连续的物理页，作为内核栈的空间
    //寄存器。因为线程切换在一个函数当中（我们下一小节就会看到），所以编译器会自动帮助我们生成保存和恢复调用者保存寄存器的代码
    struct trapframe *tf;                       // 当前中断的陷阱帧
    //tf里保存了进程的中断帧。当进程从用户空间跳进内核空间的时候，进程的执行状态被保存在了中断帧中
    uintptr_t cr3;                              // CR3寄存器：页目录表(PDT)的基地址
    //不同的进程，物理页表基址不同，因此需要cr3来保存，不同页表的基址。
    uint32_t flags;                             // 进程标志
    char name[PROC_NAME_LEN + 1];               // 进程的名称
    list_entry_t list_link;                     // 进程链接列表 
    list_entry_t hash_link;                     // 进程哈希列表
};

#define le2proc(le, member)         \
    to_struct((le), struct proc_struct, member)

extern struct proc_struct *idleproc, *initproc, *current;

void proc_init(void);
void proc_run(struct proc_struct *proc);
int kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags);

char *set_proc_name(struct proc_struct *proc, const char *name);
char *get_proc_name(struct proc_struct *proc);
void cpu_idle(void) __attribute__((noreturn));

struct proc_struct *find_proc(int pid);
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf);
int do_exit(int error_code);

#endif /* !__KERN_PROCESS_PROC_H__ */

