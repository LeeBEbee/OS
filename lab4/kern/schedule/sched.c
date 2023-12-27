#include <list.h>
#include <sync.h>
#include <proc.h>
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
    proc->state = PROC_RUNNABLE;
}

//实现了Linux操作系统的进程调度
//选择一个可运行的进程并让它在CPU上运行
//在给定的时间片内，这个进程可以使用CPU进行计算，直到时间片用完或者进程阻塞，然后调度程序再选择下一个进程运行
//具体就是将current指针赋予一个新的proc
void
schedule(void) {
    bool intr_flag; // 用于保存中断状态的标志
    list_entry_t *le, *last; // le表示正在检查的进程，last表示检查的最后一个进程
    struct proc_struct *next = NULL;//下一个要运行的进程
    local_intr_save(intr_flag);//关闭中断并保存原有中断状态
    {
        current->need_resched = 0; //当前进程不再需要调度
        last = (current == idleproc) ? &proc_list : &(current->list_link);//当前进程是否为启动进程，如果是则从表头开始找
        le = last;
        //在proc_list队列中查找下一个处于“就绪”态的线程或进程next
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);//获取当前进程的proc_strect
                //此函数的作用是，利用结构体中的一个特征，找到该结构体，此时寻找proc_struct中第一个list_link为le的
                //如果找到一个可运行的，循环结束
                if (next->state == PROC_RUNNABLE) {
                    break;
                }
            }
        } while (le != last);//如果le又回到了队列头，则退出循环
        if (next == NULL || next->state != PROC_RUNNABLE) {
            next = idleproc;//如果没找到，或不可运行，则让idleproc（空闲进程）运行
        }
        next->runs ++;//增加该进程的运行次数

        if (next != current) {
            proc_run(next);//找到这样的进程后，就调用proc_run函数，保存当前进程current的执行现场（进程上下文），恢复新进程的执行现场，完成进程切换
        }
    }
    local_intr_restore(intr_flag);//恢复原有的中断状态
}

