#include <proc.h>
#include <kmalloc.h>
#include <string.h>
#include <sync.h>
#include <pmm.h>
#include <error.h>
#include <sched.h>
#include <elf.h>
#include <vmm.h>
#include <trap.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

/* ------------- process/thread mechanism design&implementation -------------
(an simplified Linux process/thread mechanism )
introduction:
  ucore implements a simple process/thread mechanism. process contains the independent memory sapce, at least one threads
for execution, the kernel data(for management), processor state (for context switch), files(in lab6), etc. ucore needs to
manage all these details efficiently. In ucore, a thread is just a special kind of process(share process's memory).
------------------------------
process state       :     meaning               -- reason
    PROC_UNINIT     :   uninitialized           -- alloc_proc
    PROC_SLEEPING   :   sleeping                -- try_free_pages, do_wait, do_sleep
    PROC_RUNNABLE   :   runnable(maybe running) -- proc_init, wakeup_proc, 
    PROC_ZOMBIE     :   almost dead             -- do_exit

-----------------------------
process state changing:
                                            
  alloc_proc                                 RUNNING
      +                                   +--<----<--+
      +                                   + proc_run +
      V                                   +-->---->--+ 
PROC_UNINIT -- proc_init/wakeup_proc --> PROC_RUNNABLE -- try_free_pages/do_wait/do_sleep --> PROC_SLEEPING --
                                           A      +                                                           +
                                           |      +--- do_exit --> PROC_ZOMBIE                                +
                                           +                                                                  + 
                                           -----------------------wakeup_proc----------------------------------
-----------------------------
process relations
parent:           proc->parent  (proc is children)
children:         proc->cptr    (proc is parent)
older sibling:    proc->optr    (proc is younger sibling)
younger sibling:  proc->yptr    (proc is older sibling)
-----------------------------
related syscall for process:
SYS_exit        : process exit,                           -->do_exit
SYS_fork        : create child process, dup mm            -->do_fork-->wakeup_proc
SYS_wait        : wait process                            -->do_wait
SYS_exec        : after fork, process execute a program   -->load a program and refresh the mm
SYS_clone       : create child thread                     -->do_fork-->wakeup_proc
SYS_yield       : process flag itself need resecheduling, -- proc->need_sched=1, then scheduler will rescheule this process
SYS_sleep       : process sleep                           -->do_sleep 
SYS_kill        : kill process                            -->do_kill-->proc->flags |= PF_EXITING
                                                                 -->wakeup_proc-->do_wait-->do_exit   
SYS_getpid      : get the process's pid

*/

// the process set's list
list_entry_t proc_list;
//所有进程控制块的双向线性列表，proc_struct中的成员变量list_link将链接入这个链表中

#define HASH_SHIFT          10
#define HASH_LIST_SIZE      (1 << HASH_SHIFT)
#define pid_hashfn(x)       (hash32(x, HASH_SHIFT))

// has list for process set based on pid
static list_entry_t hash_list[HASH_LIST_SIZE];
//所有进程控制块的哈希表，proc_struct中的成员变量hash_link将基于pid链接入这个哈希表中

// idle proc
struct proc_struct *idleproc = NULL;

// init proc
struct proc_struct *initproc = NULL;
//指向一个内核线程。本实验以后，此指针将指向第一个用户态进程

// current proc
struct proc_struct *current = NULL;//当前占用CPU且处于“运行”状态进程控制块指针
//通常这个变量是只读的，只有在进程切换的时候才进行修改

static int nr_process = 0;

void kernel_thread_entry(void);
void forkrets(struct trapframe *tf);
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void) {
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL) {
    
    //LAB4:EXERCISE1 YOUR CODE
    /*
     * below fields in proc_struct need to be initialized
     *       enum proc_state state;                      // Process state
     *       int pid;                                    // Process ID
     *       int runs;                                   // the running times of Proces
     *       uintptr_t kstack;                           // Process kernel stack
     *       volatile bool need_resched;                 // bool value: need to be rescheduled to release CPU?
     *       struct proc_struct *parent;                 // the parent process
     *       struct mm_struct *mm;                       // Process's memory management field
     *       struct context context;                     // Switch here to run process
     *       struct trapframe *tf;                       // Trap frame for current interrupt
     *       uintptr_t cr3;                              // CR3 register: the base addr of Page Directroy Table(PDT)
     *       uint32_t flags;                             // Process flag
     *       char name[PROC_NAME_LEN + 1];               // Process name
     */
    proc->state=PROC_UNINIT;//给进程设置为未初始化状态，此进程为一空壳
    proc->pid=-1;//未初始化的进程，其pid为-1
    proc->runs=0;//初始化时间片,刚刚初始化的进程，运行时间一定为零
    proc->kstack=0;//内核栈地址,该进程分配的地址为0，因为还没有执行，也没有被重定位，因为默认地址都是从0开始的。
    proc->need_resched=0;//不需要调度
    proc->parent=NULL;//父进程为空
    proc->mm=NULL;//虚拟内存为空
    memset(&(proc->context),0,sizeof(struct context));//初始化上下文
    proc->tf=NULL;//中断帧指针为空
    proc->cr3=boot_cr3;//页目录为内核页目录表的基址
    proc->flags=0;//标志位为0
    memset(&(proc->name),0,PROC_NAME_LEN);//进程名为0
    /*idleproc->cr3 == boot_cr3 && idleproc->tf == NULL && !context_init_flag
        && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0
        && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL
        && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag*/
 
    }
    return proc;
}

// set_proc_name - set the name of proc
char *
set_proc_name(struct proc_struct *proc, const char *name) {
    memset(proc->name, 0, sizeof(proc->name));
    return memcpy(proc->name, name, PROC_NAME_LEN);
}

// get_proc_name - get the name of proc
char *
get_proc_name(struct proc_struct *proc) {
    static char name[PROC_NAME_LEN + 1];
    memset(name, 0, sizeof(name));
    return memcpy(name, proc->name, PROC_NAME_LEN);
}

// get_pid - alloc a unique pid for process
static int
get_pid(void) {
    static_assert(MAX_PID > MAX_PROCESS);
    //确保最大PID数，大于最大进程数MAX_PROCESS
    struct proc_struct *proc;
    list_entry_t *list = &proc_list, *le;
    static int next_safe = MAX_PID, last_pid = MAX_PID;
    //next_safe 用于存储下一个安全的（即未被占用的）PID，而 last_pid 用于记录最后一次分配的PID
    if (++ last_pid >= MAX_PID) {
        last_pid = 1;
        goto inside;
    }
    if (last_pid >= next_safe) {
    inside:
        next_safe = MAX_PID;
    repeat:
        le = list;
        while ((le = list_next(le)) != list) { //循环进行，直到重新读到链表的开头
            proc = le2proc(le, list_link);//使用宏 le2proc 从链表元素 le 获取 proc_struct 的指针
            //获取包含list_link=le的实例
            if (proc->pid == last_pid) {
                if (++ last_pid >= next_safe) {
                    if (last_pid >= MAX_PID) {
                        last_pid = 1;
                    }
                    next_safe = MAX_PID;
                    goto repeat;
                }
            }
            else if (proc->pid > last_pid && next_safe > proc->pid) {
                next_safe = proc->pid;
            }
        }
    }
    return last_pid;
}

// proc_run - make process "proc" running on cpu
// NOTE: before call switch_to, should load  base addr of "proc"'s new PDT
void
proc_run(struct proc_struct *proc) {
    //当进程非当前进程时将实现上下文切换
    if (proc != current) {
        // LAB4:EXERCISE3 YOUR CODE
        /*
        * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
        * MACROs or Functions:
        *   local_intr_save():        Disable interrupts
        *   local_intr_restore():     Enable Interrupts
        *   lcr3():                   Modify the value of CR3 register
        *   switch_to():              Context switching between two processes
        */
       struct proc_struct *prev=current,*next = proc;//用一个prev来存储当前的进程信息
       bool intr_flag;//返回一个是否禁用成功的函数
       local_intr_save(intr_flag);//禁用中断
       {
       current=proc;//切换当前进程为要运行的进程
       lcr3(proc->cr3);//切换页表，以便使用新进程的地址空间
       switch_to(&prev->context,&proc->context);//上下文切换
       }
       local_intr_restore(intr_flag);//允许中断


       
    }
}

// forkret -- the first kernel entry point of a new thread/process
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void) {
    forkrets(current->tf);
}
//当新进程被调度并开始执行时，它会从forkret函数开始执行
//在进程分叉后，为新进程设置正确的执行状态，并开始执行新进程

// hash_proc - add proc into proc hash_list
static void
hash_proc(struct proc_struct *proc) {
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
}
//hashfn 函数通过进程的 PID 计算出哈希桶的索引
//

// find_proc - find proc frome proc hash_list according to pid
struct proc_struct *
find_proc(int pid) {
    if (0 < pid && pid < MAX_PID) {
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
        while ((le = list_next(le)) != list) {
            struct proc_struct *proc = le2proc(le, hash_link);
            if (proc->pid == pid) {
                return proc;
            }
        }
    }
    return NULL;
}

// kernel_thread - create a kernel thread using "fn" function
// NOTE: the contents of temp trapframe tf will be copied to 
//       proc->tf in do_fork-->copy_thread function
int
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
    // 对trameframe，也就是我们程序的一些上下文进行一些初始化
    struct trapframe tf;
    memset(&tf, 0, sizeof(struct trapframe));

    //设置内核线程的参数和函数指针
    tf.gpr.s0 = (uintptr_t)fn;//s0 寄存器保存函数指针
    tf.gpr.s1 = (uintptr_t)arg;// s1 寄存器保存函数参数

    // 设置 trapframe 中的 status 寄存器（SSTATUS）
    // SSTATUS_SPP：Supervisor Previous Privilege（设置为 supervisor 模式，因为这是一个内核线程）
    // SSTATUS_SPIE：Supervisor Previous Interrupt Enable（设置为启用中断，因为这是一个内核线程）
    // SSTATUS_SIE：Supervisor Interrupt Enable（设置为禁用中断，因为我们不希望该线程被中断）
    // 设置SPP和SPIE位，并同时清除SIE位，从而实现特权级别切换、保留中断使能状态并禁用中断的操作
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
    // 将入口点（epc）设置为 kernel_thread_entry 函数，作用实际上是将pc指针指向它(*trapentry.S会用到)
    tf.epc = (uintptr_t)kernel_thread_entry;//入口在entry.S中,作用：传入参数，启动函数

    // 使用 do_fork 创建一个新进程（内核线程），这样才真正用设置的tf创建新进程
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
    // set if VM shared between processes
}
//在该过程中完成tf的转移和初始化

// setup_kstack - alloc pages with size KSTACKPAGE(2个page) as process kernel stack
static int
setup_kstack(struct proc_struct *proc) {
    struct Page *page = alloc_pages(KSTACKPAGE);//分配两个page作为程序的内核栈
    if (page != NULL) {
        proc->kstack = (uintptr_t)page2kva(page);
        //传入page的内核虚拟地址
        return 0;
    }
    return -E_NO_MEM;
}

// put_kstack - free the memory space of process kernel stack
static void
put_kstack(struct proc_struct *proc) {
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
}

// copy_mm - process "proc" duplicate OR share process "current"'s mm according clone_flags
//         - if clone_flags & CLONE_VM, then "share" ; else "duplicate"
static int
copy_mm(uint32_t clone_flags, struct proc_struct *proc) {
    assert(current->mm == NULL);
    /* do nothing in this project */
    return 0;
}

// copy_thread - setup the trapframe on the  process's kernel stack top and
//             - setup the kernel entry point and stack of process
static void
copy_thread(struct proc_struct *proc, uintptr_t esp, struct trapframe *tf) {
    //esp 是一个参数，表示要设置的进程的栈指针。在这个函数中，esp 的值决定了进程的栈指针的位置。
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
    //proc->kstack 是进程的内核栈的起始地址，KSTACKSIZE 是内核栈的大小，
    //这里使用减法是因为在内存中，栈是从高地址向低地址增长的
    *(proc->tf) = *tf;
    //使用 *tf 的内容拷贝到这个位置上
    
    //ESP：栈帧栈顶寄存器  EBP：栈帧栈底寄存器 EIP：寄存器存储当前执行指令

    // Set a0 to 0 so a child process knows it's just forked
    // 如果 esp 为 0，则将栈指针设置为 proc->tf 的地址
    // 否则将栈指针设置为 esp 的值
    proc->tf->gpr.a0 = 0;//将trapframe中的a0寄存器（返回值）设置为0，说明这个进程是一个子进程
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
    //鉴定此时的esp是否为0，从kernel_thread来的都是0
    //设置进程的上下文
    proc->context.ra = (uintptr_t)forkret;//forkrets函数很短，位于kern/trap/trapentry.S
    // 将返回地址设置为 forkret 函数的地址

    proc->context.sp = (uintptr_t)(proc->tf);//把trapframe放在上下文的栈顶
    //设置栈指针为 proc->tf 的地址
    
}


/* do_fork -     parent process for a new child process
 * @clone_flags: used to guide how to clone the child process
 * @stack:       the parent's user stack pointer. if stack==0, It means to fork a kernel thread.
 * @tf:          the trapframe info, which will be copied to child process's proc->tf
 */
int
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS) {
        goto fork_out;
    }
    ret = -E_NO_MEM;
    //LAB4:EXERCISE2 YOUR CODE
    /*
     * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
     * MACROs or Functions:
     *   alloc_proc:   create a proc struct and init fields (lab4:exercise1)
     *   setup_kstack: alloc pages with size KSTACKPAGE as process kernel stack
     *   copy_mm:      process "proc" duplicate OR share process "current"'s mm according clone_flags
     *                 if clone_flags & CLONE_VM, then "share" ; else "duplicate"
     *   copy_thread:  setup the trapframe on the  process's kernel stack top and
     *                 setup the kernel entry point and stack of process
     *   hash_proc:    add proc into proc hash_list
     *   get_pid:      alloc a unique pid for process
     *   wakeup_proc:  set proc->state = PROC_RUNNABLE
     * VARIABLES:
     *   proc_list:    the process set's list
     *   nr_process:   the number of process set
     */

    //    1. call alloc_proc to allocate a proc_struct
    //    分配并初始化进程控制块alloc_proc
        if((proc=alloc_proc())==NULL)
        {
            goto fork_out;
        }
        //将子进程的父节点设置为当前进程
        proc->parent = current;
    //    2. call setup_kstack to allocate a kernel stack for child process，此时为分配两个页表
        if(setup_kstack(proc)!=0)//2.调用setup_stack()函数为进程分配一个内核栈
        {
            goto bad_fork_cleanup_kstack;
        }
    //    3. call copy_mm to dup OR share mm according clone_flag
    //    clone_flags决定是复制还是共享内存管理系统（copy_mm函数）
       if( copy_mm(clone_flags,proc)!=0)
       {
            goto bad_fork_cleanup_kstack;
       }
    //    4. call copy_thread to setup tf & context in proc_struct
        //设置进程的中断帧和上下文（copy_thread函数）
        copy_thread(proc,stack,tf);//复制父进程的中断帧和上下文信息
        //do_fork函数会调用copy_thread函数来在新创建的进程内核栈上专门给进程的中断帧分配一块空间
    //    5. insert proc_struct into hash_list && proc_list
        bool intr_flag;
        local_intr_save(intr_flag);//屏蔽中断
        {
            proc->pid=get_pid();//返回一个链表中尚未使用的节点号（最近的）
            hash_proc(proc);
            list_add(&proc_list,&(proc->list_link));
            nr_process++;//进程数加一
        }
         local_intr_restore(intr_flag);//恢复中断
    //    6. call wakeup_proc to make the new child process RUNNABLE
        wakeup_proc(proc);//唤醒新进程 proc->state = PROC_RUNNABLE;
    //    7. set ret vaule using child proc's pid
        ret=proc->pid;
        

    

fork_out:
    return ret;

bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}
//完成新子进程的初始化并启动

// do_exit - called by sys_exit
//   1. call exit_mmap & put_pgdir & mm_destroy to free the almost all memory space of process
//   2. set process' state as PROC_ZOMBIE, then call wakeup_proc(parent) to ask parent reclaim itself.
//   3. call scheduler to switch to other process
int
do_exit(int error_code) {
    panic("process exit!!.\n");
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg) {
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
    cprintf("To U: \"%s\".\n", (const char *)arg);
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
    return 0;
}

// proc_init - set up the first kernel thread idleproc "idle" by itself and 
//           - create the second kernel thread init_main
void
proc_init(void) {
    int i;
    //初始化进程列表（把所有进程控制块串联起来的数据结构）
    list_init(&proc_list);
    //初始化哈希列表
    for (i = 0; i < HASH_LIST_SIZE; i ++) {
        list_init(hash_list + i);
    }
    // 分配一个进程结构体给idleproc，如果分配失败则终止程序
    if ((idleproc = alloc_proc()) == NULL) {//调用alloc_proc函数来通过kmalloc函数获得proc_struct结构的一块内存块-，作为第0个进程控制块。并把proc进行初步初始化
        panic("cannot alloc idleproc.\n");
        //调用panic函数停止系统
    }

    // 在这里，我们使用kmalloc和memset函数来手动创建一个和idleproc->context大小一样的内存空间，
    // 然后将这个内存空间的所有位都设置为0，然后我们使用memcmp函数来比较这个内存空间和idleproc->context的内容是否一样。
    // 如果一样，说明idleproc->context在创建时，已经被正确地初始化为了0。
    int *context_mem = (int*) kmalloc(sizeof(struct context));
    memset(context_mem, 0, sizeof(struct context));
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));
    
    // 以上述同样的方式，我们创建一个和idleproc->name大小一样的内存空间，
    // 并检查idleproc->name在创建时是否被正确地初始化为了0
    int *proc_name_mem = (int*) kmalloc(PROC_NAME_LEN);
    memset(proc_name_mem, 0, PROC_NAME_LEN);
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);
    // 如果idleproc的所有成员都被正确地初始化为了0，那么我们就打印一条消息，说明alloc_proc函数正确地工作了
    if(idleproc->cr3 == boot_cr3 && idleproc->tf == NULL && !context_init_flag
        && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0
        && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL
        && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag
    ){
        cprintf("alloc_proc() correct!\n");

    }

    // 之后，我们开始设置idleproc的各个成员的值
    idleproc->pid = 0; // pid设置为0，表示这是系统的第一个进程
    idleproc->state = PROC_RUNNABLE; // 进程状态设置为PROC_RUNNABLE，表示这个进程已经可以运行了
    idleproc->kstack = (uintptr_t)bootstack;// 设置内核栈指针
    idleproc->need_resched = 1;// 需要立即调度运行
    set_proc_name(idleproc, "idle"); // 设置进程名称为"idle"
    nr_process ++;// 进程数加1

    // current指向当前正在运行的进程，因为现在只有idleproc一个进程，所以current指向idleproc
    current = idleproc;
    
    // 调用kernel_thread函数创建init_main进程，这个进程会在用户空间运行，并打印"Hello world!!"
    int pid = kernel_thread(init_main, "Hello world!!", 0);
    // 如果创建失败，则停止系统
    if (pid <= 0) {
        panic("create init_main failed.\n");
    }

    // 通过pid找到刚刚创建的init_main进程的控制块，并将initproc指向它
    initproc = find_proc(pid);
    // 设置initproc进程的名称为"init"
    set_proc_name(initproc, "init");
    
    // 最后，我们需要确保idleproc和initproc进程都已经被正确创建
    assert(idleproc != NULL && idleproc->pid == 0);
    assert(initproc != NULL && initproc->pid == 1);
}

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void
cpu_idle(void) {
    while (1) {
        if (current->need_resched) { //如果该进程需要立即被调度，则将该进程的need_resched设置为1
            schedule();//此时启动调度函数，该过程会将当前进程的need_resched
        }
    }
}

