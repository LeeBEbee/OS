
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c020b2b7          	lui	t0,0xc020b
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000a:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc020000e:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200012:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200016:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200018:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc020001c:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200020:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200024:	c020b137          	lui	sp,0xc020b

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200028:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020002c:	03228293          	addi	t0,t0,50 # ffffffffc0200032 <kern_init>
    jr t0
ffffffffc0200030:	8282                	jr	t0

ffffffffc0200032 <kern_init>:
void grade_backtrace(void);

int
kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200032:	000a7517          	auipc	a0,0xa7
ffffffffc0200036:	50e50513          	addi	a0,a0,1294 # ffffffffc02a7540 <buf>
ffffffffc020003a:	000b3617          	auipc	a2,0xb3
ffffffffc020003e:	a6260613          	addi	a2,a2,-1438 # ffffffffc02b2a9c <end>
kern_init(void) {
ffffffffc0200042:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	590060ef          	jal	ra,ffffffffc02065da <memset>
    cons_init();                // init the console
ffffffffc020004e:	52a000ef          	jal	ra,ffffffffc0200578 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc0200052:	00006597          	auipc	a1,0x6
ffffffffc0200056:	5b658593          	addi	a1,a1,1462 # ffffffffc0206608 <etext+0x4>
ffffffffc020005a:	00006517          	auipc	a0,0x6
ffffffffc020005e:	5ce50513          	addi	a0,a0,1486 # ffffffffc0206628 <etext+0x24>
ffffffffc0200062:	11e000ef          	jal	ra,ffffffffc0200180 <cprintf>

    print_kerninfo();
ffffffffc0200066:	1a2000ef          	jal	ra,ffffffffc0200208 <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc020006a:	540020ef          	jal	ra,ffffffffc02025aa <pmm_init>

    pic_init();                 // init interrupt controller
ffffffffc020006e:	5de000ef          	jal	ra,ffffffffc020064c <pic_init>
    idt_init();                 // init interrupt descriptor table
ffffffffc0200072:	5dc000ef          	jal	ra,ffffffffc020064e <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc0200076:	470040ef          	jal	ra,ffffffffc02044e6 <vmm_init>
    proc_init();                // init process table
ffffffffc020007a:	4db050ef          	jal	ra,ffffffffc0205d54 <proc_init>
    
    ide_init();                 // init ide devices
ffffffffc020007e:	56c000ef          	jal	ra,ffffffffc02005ea <ide_init>
    swap_init();                // init swap
ffffffffc0200082:	3ce030ef          	jal	ra,ffffffffc0203450 <swap_init>

    clock_init();               // init clock interrupt
ffffffffc0200086:	4a0000ef          	jal	ra,ffffffffc0200526 <clock_init>
    intr_enable();              // enable irq interrupt
ffffffffc020008a:	5b6000ef          	jal	ra,ffffffffc0200640 <intr_enable>
    
    cpu_idle();                 // run idle process
ffffffffc020008e:	65d050ef          	jal	ra,ffffffffc0205eea <cpu_idle>

ffffffffc0200092 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0200092:	715d                	addi	sp,sp,-80
ffffffffc0200094:	e486                	sd	ra,72(sp)
ffffffffc0200096:	e0a6                	sd	s1,64(sp)
ffffffffc0200098:	fc4a                	sd	s2,56(sp)
ffffffffc020009a:	f84e                	sd	s3,48(sp)
ffffffffc020009c:	f452                	sd	s4,40(sp)
ffffffffc020009e:	f056                	sd	s5,32(sp)
ffffffffc02000a0:	ec5a                	sd	s6,24(sp)
ffffffffc02000a2:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000a4:	c901                	beqz	a0,ffffffffc02000b4 <readline+0x22>
ffffffffc02000a6:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000a8:	00006517          	auipc	a0,0x6
ffffffffc02000ac:	58850513          	addi	a0,a0,1416 # ffffffffc0206630 <etext+0x2c>
ffffffffc02000b0:	0d0000ef          	jal	ra,ffffffffc0200180 <cprintf>
readline(const char *prompt) {
ffffffffc02000b4:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000b6:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000b8:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000ba:	4aa9                	li	s5,10
ffffffffc02000bc:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000be:	000a7b97          	auipc	s7,0xa7
ffffffffc02000c2:	482b8b93          	addi	s7,s7,1154 # ffffffffc02a7540 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000c6:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000ca:	12e000ef          	jal	ra,ffffffffc02001f8 <getchar>
        if (c < 0) {
ffffffffc02000ce:	00054a63          	bltz	a0,ffffffffc02000e2 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000d2:	00a95a63          	bge	s2,a0,ffffffffc02000e6 <readline+0x54>
ffffffffc02000d6:	029a5263          	bge	s4,s1,ffffffffc02000fa <readline+0x68>
        c = getchar();
ffffffffc02000da:	11e000ef          	jal	ra,ffffffffc02001f8 <getchar>
        if (c < 0) {
ffffffffc02000de:	fe055ae3          	bgez	a0,ffffffffc02000d2 <readline+0x40>
            return NULL;
ffffffffc02000e2:	4501                	li	a0,0
ffffffffc02000e4:	a091                	j	ffffffffc0200128 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000e6:	03351463          	bne	a0,s3,ffffffffc020010e <readline+0x7c>
ffffffffc02000ea:	e8a9                	bnez	s1,ffffffffc020013c <readline+0xaa>
        c = getchar();
ffffffffc02000ec:	10c000ef          	jal	ra,ffffffffc02001f8 <getchar>
        if (c < 0) {
ffffffffc02000f0:	fe0549e3          	bltz	a0,ffffffffc02000e2 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000f4:	fea959e3          	bge	s2,a0,ffffffffc02000e6 <readline+0x54>
ffffffffc02000f8:	4481                	li	s1,0
            cputchar(c);
ffffffffc02000fa:	e42a                	sd	a0,8(sp)
ffffffffc02000fc:	0ba000ef          	jal	ra,ffffffffc02001b6 <cputchar>
            buf[i ++] = c;
ffffffffc0200100:	6522                	ld	a0,8(sp)
ffffffffc0200102:	009b87b3          	add	a5,s7,s1
ffffffffc0200106:	2485                	addiw	s1,s1,1
ffffffffc0200108:	00a78023          	sb	a0,0(a5)
ffffffffc020010c:	bf7d                	j	ffffffffc02000ca <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc020010e:	01550463          	beq	a0,s5,ffffffffc0200116 <readline+0x84>
ffffffffc0200112:	fb651ce3          	bne	a0,s6,ffffffffc02000ca <readline+0x38>
            cputchar(c);
ffffffffc0200116:	0a0000ef          	jal	ra,ffffffffc02001b6 <cputchar>
            buf[i] = '\0';
ffffffffc020011a:	000a7517          	auipc	a0,0xa7
ffffffffc020011e:	42650513          	addi	a0,a0,1062 # ffffffffc02a7540 <buf>
ffffffffc0200122:	94aa                	add	s1,s1,a0
ffffffffc0200124:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0200128:	60a6                	ld	ra,72(sp)
ffffffffc020012a:	6486                	ld	s1,64(sp)
ffffffffc020012c:	7962                	ld	s2,56(sp)
ffffffffc020012e:	79c2                	ld	s3,48(sp)
ffffffffc0200130:	7a22                	ld	s4,40(sp)
ffffffffc0200132:	7a82                	ld	s5,32(sp)
ffffffffc0200134:	6b62                	ld	s6,24(sp)
ffffffffc0200136:	6bc2                	ld	s7,16(sp)
ffffffffc0200138:	6161                	addi	sp,sp,80
ffffffffc020013a:	8082                	ret
            cputchar(c);
ffffffffc020013c:	4521                	li	a0,8
ffffffffc020013e:	078000ef          	jal	ra,ffffffffc02001b6 <cputchar>
            i --;
ffffffffc0200142:	34fd                	addiw	s1,s1,-1
ffffffffc0200144:	b759                	j	ffffffffc02000ca <readline+0x38>

ffffffffc0200146 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200146:	1141                	addi	sp,sp,-16
ffffffffc0200148:	e022                	sd	s0,0(sp)
ffffffffc020014a:	e406                	sd	ra,8(sp)
ffffffffc020014c:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020014e:	42c000ef          	jal	ra,ffffffffc020057a <cons_putc>
    (*cnt) ++;
ffffffffc0200152:	401c                	lw	a5,0(s0)
}
ffffffffc0200154:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200156:	2785                	addiw	a5,a5,1
ffffffffc0200158:	c01c                	sw	a5,0(s0)
}
ffffffffc020015a:	6402                	ld	s0,0(sp)
ffffffffc020015c:	0141                	addi	sp,sp,16
ffffffffc020015e:	8082                	ret

ffffffffc0200160 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200160:	1101                	addi	sp,sp,-32
ffffffffc0200162:	862a                	mv	a2,a0
ffffffffc0200164:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200166:	00000517          	auipc	a0,0x0
ffffffffc020016a:	fe050513          	addi	a0,a0,-32 # ffffffffc0200146 <cputch>
ffffffffc020016e:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200170:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200172:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200174:	068060ef          	jal	ra,ffffffffc02061dc <vprintfmt>
    return cnt;
}
ffffffffc0200178:	60e2                	ld	ra,24(sp)
ffffffffc020017a:	4532                	lw	a0,12(sp)
ffffffffc020017c:	6105                	addi	sp,sp,32
ffffffffc020017e:	8082                	ret

ffffffffc0200180 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc0200180:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200182:	02810313          	addi	t1,sp,40 # ffffffffc020b028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200186:	8e2a                	mv	t3,a0
ffffffffc0200188:	f42e                	sd	a1,40(sp)
ffffffffc020018a:	f832                	sd	a2,48(sp)
ffffffffc020018c:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020018e:	00000517          	auipc	a0,0x0
ffffffffc0200192:	fb850513          	addi	a0,a0,-72 # ffffffffc0200146 <cputch>
ffffffffc0200196:	004c                	addi	a1,sp,4
ffffffffc0200198:	869a                	mv	a3,t1
ffffffffc020019a:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc020019c:	ec06                	sd	ra,24(sp)
ffffffffc020019e:	e0ba                	sd	a4,64(sp)
ffffffffc02001a0:	e4be                	sd	a5,72(sp)
ffffffffc02001a2:	e8c2                	sd	a6,80(sp)
ffffffffc02001a4:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001a6:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001a8:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02001aa:	032060ef          	jal	ra,ffffffffc02061dc <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001ae:	60e2                	ld	ra,24(sp)
ffffffffc02001b0:	4512                	lw	a0,4(sp)
ffffffffc02001b2:	6125                	addi	sp,sp,96
ffffffffc02001b4:	8082                	ret

ffffffffc02001b6 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02001b6:	a6d1                	j	ffffffffc020057a <cons_putc>

ffffffffc02001b8 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02001b8:	1101                	addi	sp,sp,-32
ffffffffc02001ba:	e822                	sd	s0,16(sp)
ffffffffc02001bc:	ec06                	sd	ra,24(sp)
ffffffffc02001be:	e426                	sd	s1,8(sp)
ffffffffc02001c0:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02001c2:	00054503          	lbu	a0,0(a0)
ffffffffc02001c6:	c51d                	beqz	a0,ffffffffc02001f4 <cputs+0x3c>
ffffffffc02001c8:	0405                	addi	s0,s0,1
ffffffffc02001ca:	4485                	li	s1,1
ffffffffc02001cc:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001ce:	3ac000ef          	jal	ra,ffffffffc020057a <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001d2:	00044503          	lbu	a0,0(s0)
ffffffffc02001d6:	008487bb          	addw	a5,s1,s0
ffffffffc02001da:	0405                	addi	s0,s0,1
ffffffffc02001dc:	f96d                	bnez	a0,ffffffffc02001ce <cputs+0x16>
    (*cnt) ++;
ffffffffc02001de:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001e2:	4529                	li	a0,10
ffffffffc02001e4:	396000ef          	jal	ra,ffffffffc020057a <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001e8:	60e2                	ld	ra,24(sp)
ffffffffc02001ea:	8522                	mv	a0,s0
ffffffffc02001ec:	6442                	ld	s0,16(sp)
ffffffffc02001ee:	64a2                	ld	s1,8(sp)
ffffffffc02001f0:	6105                	addi	sp,sp,32
ffffffffc02001f2:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001f4:	4405                	li	s0,1
ffffffffc02001f6:	b7f5                	j	ffffffffc02001e2 <cputs+0x2a>

ffffffffc02001f8 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc02001f8:	1141                	addi	sp,sp,-16
ffffffffc02001fa:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02001fc:	3b2000ef          	jal	ra,ffffffffc02005ae <cons_getc>
ffffffffc0200200:	dd75                	beqz	a0,ffffffffc02001fc <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200202:	60a2                	ld	ra,8(sp)
ffffffffc0200204:	0141                	addi	sp,sp,16
ffffffffc0200206:	8082                	ret

ffffffffc0200208 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200208:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020020a:	00006517          	auipc	a0,0x6
ffffffffc020020e:	42e50513          	addi	a0,a0,1070 # ffffffffc0206638 <etext+0x34>
void print_kerninfo(void) {
ffffffffc0200212:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200214:	f6dff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200218:	00000597          	auipc	a1,0x0
ffffffffc020021c:	e1a58593          	addi	a1,a1,-486 # ffffffffc0200032 <kern_init>
ffffffffc0200220:	00006517          	auipc	a0,0x6
ffffffffc0200224:	43850513          	addi	a0,a0,1080 # ffffffffc0206658 <etext+0x54>
ffffffffc0200228:	f59ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc020022c:	00006597          	auipc	a1,0x6
ffffffffc0200230:	3d858593          	addi	a1,a1,984 # ffffffffc0206604 <etext>
ffffffffc0200234:	00006517          	auipc	a0,0x6
ffffffffc0200238:	44450513          	addi	a0,a0,1092 # ffffffffc0206678 <etext+0x74>
ffffffffc020023c:	f45ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200240:	000a7597          	auipc	a1,0xa7
ffffffffc0200244:	30058593          	addi	a1,a1,768 # ffffffffc02a7540 <buf>
ffffffffc0200248:	00006517          	auipc	a0,0x6
ffffffffc020024c:	45050513          	addi	a0,a0,1104 # ffffffffc0206698 <etext+0x94>
ffffffffc0200250:	f31ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200254:	000b3597          	auipc	a1,0xb3
ffffffffc0200258:	84858593          	addi	a1,a1,-1976 # ffffffffc02b2a9c <end>
ffffffffc020025c:	00006517          	auipc	a0,0x6
ffffffffc0200260:	45c50513          	addi	a0,a0,1116 # ffffffffc02066b8 <etext+0xb4>
ffffffffc0200264:	f1dff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200268:	000b3597          	auipc	a1,0xb3
ffffffffc020026c:	c3358593          	addi	a1,a1,-973 # ffffffffc02b2e9b <end+0x3ff>
ffffffffc0200270:	00000797          	auipc	a5,0x0
ffffffffc0200274:	dc278793          	addi	a5,a5,-574 # ffffffffc0200032 <kern_init>
ffffffffc0200278:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020027c:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200280:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200282:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200286:	95be                	add	a1,a1,a5
ffffffffc0200288:	85a9                	srai	a1,a1,0xa
ffffffffc020028a:	00006517          	auipc	a0,0x6
ffffffffc020028e:	44e50513          	addi	a0,a0,1102 # ffffffffc02066d8 <etext+0xd4>
}
ffffffffc0200292:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200294:	b5f5                	j	ffffffffc0200180 <cprintf>

ffffffffc0200296 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc0200296:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc0200298:	00006617          	auipc	a2,0x6
ffffffffc020029c:	47060613          	addi	a2,a2,1136 # ffffffffc0206708 <etext+0x104>
ffffffffc02002a0:	04d00593          	li	a1,77
ffffffffc02002a4:	00006517          	auipc	a0,0x6
ffffffffc02002a8:	47c50513          	addi	a0,a0,1148 # ffffffffc0206720 <etext+0x11c>
void print_stackframe(void) {
ffffffffc02002ac:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002ae:	1cc000ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02002b2 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002b2:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002b4:	00006617          	auipc	a2,0x6
ffffffffc02002b8:	48460613          	addi	a2,a2,1156 # ffffffffc0206738 <etext+0x134>
ffffffffc02002bc:	00006597          	auipc	a1,0x6
ffffffffc02002c0:	49c58593          	addi	a1,a1,1180 # ffffffffc0206758 <etext+0x154>
ffffffffc02002c4:	00006517          	auipc	a0,0x6
ffffffffc02002c8:	49c50513          	addi	a0,a0,1180 # ffffffffc0206760 <etext+0x15c>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002cc:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002ce:	eb3ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
ffffffffc02002d2:	00006617          	auipc	a2,0x6
ffffffffc02002d6:	49e60613          	addi	a2,a2,1182 # ffffffffc0206770 <etext+0x16c>
ffffffffc02002da:	00006597          	auipc	a1,0x6
ffffffffc02002de:	4be58593          	addi	a1,a1,1214 # ffffffffc0206798 <etext+0x194>
ffffffffc02002e2:	00006517          	auipc	a0,0x6
ffffffffc02002e6:	47e50513          	addi	a0,a0,1150 # ffffffffc0206760 <etext+0x15c>
ffffffffc02002ea:	e97ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
ffffffffc02002ee:	00006617          	auipc	a2,0x6
ffffffffc02002f2:	4ba60613          	addi	a2,a2,1210 # ffffffffc02067a8 <etext+0x1a4>
ffffffffc02002f6:	00006597          	auipc	a1,0x6
ffffffffc02002fa:	4d258593          	addi	a1,a1,1234 # ffffffffc02067c8 <etext+0x1c4>
ffffffffc02002fe:	00006517          	auipc	a0,0x6
ffffffffc0200302:	46250513          	addi	a0,a0,1122 # ffffffffc0206760 <etext+0x15c>
ffffffffc0200306:	e7bff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    }
    return 0;
}
ffffffffc020030a:	60a2                	ld	ra,8(sp)
ffffffffc020030c:	4501                	li	a0,0
ffffffffc020030e:	0141                	addi	sp,sp,16
ffffffffc0200310:	8082                	ret

ffffffffc0200312 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200312:	1141                	addi	sp,sp,-16
ffffffffc0200314:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200316:	ef3ff0ef          	jal	ra,ffffffffc0200208 <print_kerninfo>
    return 0;
}
ffffffffc020031a:	60a2                	ld	ra,8(sp)
ffffffffc020031c:	4501                	li	a0,0
ffffffffc020031e:	0141                	addi	sp,sp,16
ffffffffc0200320:	8082                	ret

ffffffffc0200322 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200322:	1141                	addi	sp,sp,-16
ffffffffc0200324:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200326:	f71ff0ef          	jal	ra,ffffffffc0200296 <print_stackframe>
    return 0;
}
ffffffffc020032a:	60a2                	ld	ra,8(sp)
ffffffffc020032c:	4501                	li	a0,0
ffffffffc020032e:	0141                	addi	sp,sp,16
ffffffffc0200330:	8082                	ret

ffffffffc0200332 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200332:	7115                	addi	sp,sp,-224
ffffffffc0200334:	ed5e                	sd	s7,152(sp)
ffffffffc0200336:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200338:	00006517          	auipc	a0,0x6
ffffffffc020033c:	4a050513          	addi	a0,a0,1184 # ffffffffc02067d8 <etext+0x1d4>
kmonitor(struct trapframe *tf) {
ffffffffc0200340:	ed86                	sd	ra,216(sp)
ffffffffc0200342:	e9a2                	sd	s0,208(sp)
ffffffffc0200344:	e5a6                	sd	s1,200(sp)
ffffffffc0200346:	e1ca                	sd	s2,192(sp)
ffffffffc0200348:	fd4e                	sd	s3,184(sp)
ffffffffc020034a:	f952                	sd	s4,176(sp)
ffffffffc020034c:	f556                	sd	s5,168(sp)
ffffffffc020034e:	f15a                	sd	s6,160(sp)
ffffffffc0200350:	e962                	sd	s8,144(sp)
ffffffffc0200352:	e566                	sd	s9,136(sp)
ffffffffc0200354:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200356:	e2bff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020035a:	00006517          	auipc	a0,0x6
ffffffffc020035e:	4a650513          	addi	a0,a0,1190 # ffffffffc0206800 <etext+0x1fc>
ffffffffc0200362:	e1fff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    if (tf != NULL) {
ffffffffc0200366:	000b8563          	beqz	s7,ffffffffc0200370 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020036a:	855e                	mv	a0,s7
ffffffffc020036c:	4c8000ef          	jal	ra,ffffffffc0200834 <print_trapframe>
ffffffffc0200370:	00006c17          	auipc	s8,0x6
ffffffffc0200374:	500c0c13          	addi	s8,s8,1280 # ffffffffc0206870 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200378:	00006917          	auipc	s2,0x6
ffffffffc020037c:	4b090913          	addi	s2,s2,1200 # ffffffffc0206828 <etext+0x224>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200380:	00006497          	auipc	s1,0x6
ffffffffc0200384:	4b048493          	addi	s1,s1,1200 # ffffffffc0206830 <etext+0x22c>
        if (argc == MAXARGS - 1) {
ffffffffc0200388:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020038a:	00006b17          	auipc	s6,0x6
ffffffffc020038e:	4aeb0b13          	addi	s6,s6,1198 # ffffffffc0206838 <etext+0x234>
        argv[argc ++] = buf;
ffffffffc0200392:	00006a17          	auipc	s4,0x6
ffffffffc0200396:	3c6a0a13          	addi	s4,s4,966 # ffffffffc0206758 <etext+0x154>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020039a:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020039c:	854a                	mv	a0,s2
ffffffffc020039e:	cf5ff0ef          	jal	ra,ffffffffc0200092 <readline>
ffffffffc02003a2:	842a                	mv	s0,a0
ffffffffc02003a4:	dd65                	beqz	a0,ffffffffc020039c <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003a6:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003aa:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003ac:	e1bd                	bnez	a1,ffffffffc0200412 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc02003ae:	fe0c87e3          	beqz	s9,ffffffffc020039c <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003b2:	6582                	ld	a1,0(sp)
ffffffffc02003b4:	00006d17          	auipc	s10,0x6
ffffffffc02003b8:	4bcd0d13          	addi	s10,s10,1212 # ffffffffc0206870 <commands>
        argv[argc ++] = buf;
ffffffffc02003bc:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003be:	4401                	li	s0,0
ffffffffc02003c0:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003c2:	1e4060ef          	jal	ra,ffffffffc02065a6 <strcmp>
ffffffffc02003c6:	c919                	beqz	a0,ffffffffc02003dc <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003c8:	2405                	addiw	s0,s0,1
ffffffffc02003ca:	0b540063          	beq	s0,s5,ffffffffc020046a <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003ce:	000d3503          	ld	a0,0(s10)
ffffffffc02003d2:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003d4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003d6:	1d0060ef          	jal	ra,ffffffffc02065a6 <strcmp>
ffffffffc02003da:	f57d                	bnez	a0,ffffffffc02003c8 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003dc:	00141793          	slli	a5,s0,0x1
ffffffffc02003e0:	97a2                	add	a5,a5,s0
ffffffffc02003e2:	078e                	slli	a5,a5,0x3
ffffffffc02003e4:	97e2                	add	a5,a5,s8
ffffffffc02003e6:	6b9c                	ld	a5,16(a5)
ffffffffc02003e8:	865e                	mv	a2,s7
ffffffffc02003ea:	002c                	addi	a1,sp,8
ffffffffc02003ec:	fffc851b          	addiw	a0,s9,-1
ffffffffc02003f0:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003f2:	fa0555e3          	bgez	a0,ffffffffc020039c <kmonitor+0x6a>
}
ffffffffc02003f6:	60ee                	ld	ra,216(sp)
ffffffffc02003f8:	644e                	ld	s0,208(sp)
ffffffffc02003fa:	64ae                	ld	s1,200(sp)
ffffffffc02003fc:	690e                	ld	s2,192(sp)
ffffffffc02003fe:	79ea                	ld	s3,184(sp)
ffffffffc0200400:	7a4a                	ld	s4,176(sp)
ffffffffc0200402:	7aaa                	ld	s5,168(sp)
ffffffffc0200404:	7b0a                	ld	s6,160(sp)
ffffffffc0200406:	6bea                	ld	s7,152(sp)
ffffffffc0200408:	6c4a                	ld	s8,144(sp)
ffffffffc020040a:	6caa                	ld	s9,136(sp)
ffffffffc020040c:	6d0a                	ld	s10,128(sp)
ffffffffc020040e:	612d                	addi	sp,sp,224
ffffffffc0200410:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200412:	8526                	mv	a0,s1
ffffffffc0200414:	1b0060ef          	jal	ra,ffffffffc02065c4 <strchr>
ffffffffc0200418:	c901                	beqz	a0,ffffffffc0200428 <kmonitor+0xf6>
ffffffffc020041a:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc020041e:	00040023          	sb	zero,0(s0)
ffffffffc0200422:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200424:	d5c9                	beqz	a1,ffffffffc02003ae <kmonitor+0x7c>
ffffffffc0200426:	b7f5                	j	ffffffffc0200412 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc0200428:	00044783          	lbu	a5,0(s0)
ffffffffc020042c:	d3c9                	beqz	a5,ffffffffc02003ae <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc020042e:	033c8963          	beq	s9,s3,ffffffffc0200460 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc0200432:	003c9793          	slli	a5,s9,0x3
ffffffffc0200436:	0118                	addi	a4,sp,128
ffffffffc0200438:	97ba                	add	a5,a5,a4
ffffffffc020043a:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020043e:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200442:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200444:	e591                	bnez	a1,ffffffffc0200450 <kmonitor+0x11e>
ffffffffc0200446:	b7b5                	j	ffffffffc02003b2 <kmonitor+0x80>
ffffffffc0200448:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc020044c:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020044e:	d1a5                	beqz	a1,ffffffffc02003ae <kmonitor+0x7c>
ffffffffc0200450:	8526                	mv	a0,s1
ffffffffc0200452:	172060ef          	jal	ra,ffffffffc02065c4 <strchr>
ffffffffc0200456:	d96d                	beqz	a0,ffffffffc0200448 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200458:	00044583          	lbu	a1,0(s0)
ffffffffc020045c:	d9a9                	beqz	a1,ffffffffc02003ae <kmonitor+0x7c>
ffffffffc020045e:	bf55                	j	ffffffffc0200412 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200460:	45c1                	li	a1,16
ffffffffc0200462:	855a                	mv	a0,s6
ffffffffc0200464:	d1dff0ef          	jal	ra,ffffffffc0200180 <cprintf>
ffffffffc0200468:	b7e9                	j	ffffffffc0200432 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020046a:	6582                	ld	a1,0(sp)
ffffffffc020046c:	00006517          	auipc	a0,0x6
ffffffffc0200470:	3ec50513          	addi	a0,a0,1004 # ffffffffc0206858 <etext+0x254>
ffffffffc0200474:	d0dff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    return 0;
ffffffffc0200478:	b715                	j	ffffffffc020039c <kmonitor+0x6a>

ffffffffc020047a <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc020047a:	000b2317          	auipc	t1,0xb2
ffffffffc020047e:	58e30313          	addi	t1,t1,1422 # ffffffffc02b2a08 <is_panic>
ffffffffc0200482:	00033e03          	ld	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200486:	715d                	addi	sp,sp,-80
ffffffffc0200488:	ec06                	sd	ra,24(sp)
ffffffffc020048a:	e822                	sd	s0,16(sp)
ffffffffc020048c:	f436                	sd	a3,40(sp)
ffffffffc020048e:	f83a                	sd	a4,48(sp)
ffffffffc0200490:	fc3e                	sd	a5,56(sp)
ffffffffc0200492:	e0c2                	sd	a6,64(sp)
ffffffffc0200494:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200496:	020e1a63          	bnez	t3,ffffffffc02004ca <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc020049a:	4785                	li	a5,1
ffffffffc020049c:	00f33023          	sd	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004a0:	8432                	mv	s0,a2
ffffffffc02004a2:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004a4:	862e                	mv	a2,a1
ffffffffc02004a6:	85aa                	mv	a1,a0
ffffffffc02004a8:	00006517          	auipc	a0,0x6
ffffffffc02004ac:	41050513          	addi	a0,a0,1040 # ffffffffc02068b8 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02004b0:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004b2:	ccfff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004b6:	65a2                	ld	a1,8(sp)
ffffffffc02004b8:	8522                	mv	a0,s0
ffffffffc02004ba:	ca7ff0ef          	jal	ra,ffffffffc0200160 <vcprintf>
    cprintf("\n");
ffffffffc02004be:	00007517          	auipc	a0,0x7
ffffffffc02004c2:	41250513          	addi	a0,a0,1042 # ffffffffc02078d0 <default_pmm_manager+0x518>
ffffffffc02004c6:	cbbff0ef          	jal	ra,ffffffffc0200180 <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02004ca:	4501                	li	a0,0
ffffffffc02004cc:	4581                	li	a1,0
ffffffffc02004ce:	4601                	li	a2,0
ffffffffc02004d0:	48a1                	li	a7,8
ffffffffc02004d2:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004d6:	170000ef          	jal	ra,ffffffffc0200646 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02004da:	4501                	li	a0,0
ffffffffc02004dc:	e57ff0ef          	jal	ra,ffffffffc0200332 <kmonitor>
    while (1) {
ffffffffc02004e0:	bfed                	j	ffffffffc02004da <__panic+0x60>

ffffffffc02004e2 <__warn>:
    }
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004e2:	715d                	addi	sp,sp,-80
ffffffffc02004e4:	832e                	mv	t1,a1
ffffffffc02004e6:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004e8:	85aa                	mv	a1,a0
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004ea:	8432                	mv	s0,a2
ffffffffc02004ec:	fc3e                	sd	a5,56(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004ee:	861a                	mv	a2,t1
    va_start(ap, fmt);
ffffffffc02004f0:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004f2:	00006517          	auipc	a0,0x6
ffffffffc02004f6:	3e650513          	addi	a0,a0,998 # ffffffffc02068d8 <commands+0x68>
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004fa:	ec06                	sd	ra,24(sp)
ffffffffc02004fc:	f436                	sd	a3,40(sp)
ffffffffc02004fe:	f83a                	sd	a4,48(sp)
ffffffffc0200500:	e0c2                	sd	a6,64(sp)
ffffffffc0200502:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0200504:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200506:	c7bff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020050a:	65a2                	ld	a1,8(sp)
ffffffffc020050c:	8522                	mv	a0,s0
ffffffffc020050e:	c53ff0ef          	jal	ra,ffffffffc0200160 <vcprintf>
    cprintf("\n");
ffffffffc0200512:	00007517          	auipc	a0,0x7
ffffffffc0200516:	3be50513          	addi	a0,a0,958 # ffffffffc02078d0 <default_pmm_manager+0x518>
ffffffffc020051a:	c67ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    va_end(ap);
}
ffffffffc020051e:	60e2                	ld	ra,24(sp)
ffffffffc0200520:	6442                	ld	s0,16(sp)
ffffffffc0200522:	6161                	addi	sp,sp,80
ffffffffc0200524:	8082                	ret

ffffffffc0200526 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc0200526:	67e1                	lui	a5,0x18
ffffffffc0200528:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xd558>
ffffffffc020052c:	000b2717          	auipc	a4,0xb2
ffffffffc0200530:	4ef73623          	sd	a5,1260(a4) # ffffffffc02b2a18 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200534:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200538:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020053a:	953e                	add	a0,a0,a5
ffffffffc020053c:	4601                	li	a2,0
ffffffffc020053e:	4881                	li	a7,0
ffffffffc0200540:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200544:	02000793          	li	a5,32
ffffffffc0200548:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc020054c:	00006517          	auipc	a0,0x6
ffffffffc0200550:	3ac50513          	addi	a0,a0,940 # ffffffffc02068f8 <commands+0x88>
    ticks = 0;
ffffffffc0200554:	000b2797          	auipc	a5,0xb2
ffffffffc0200558:	4a07be23          	sd	zero,1212(a5) # ffffffffc02b2a10 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020055c:	b115                	j	ffffffffc0200180 <cprintf>

ffffffffc020055e <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020055e:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200562:	000b2797          	auipc	a5,0xb2
ffffffffc0200566:	4b67b783          	ld	a5,1206(a5) # ffffffffc02b2a18 <timebase>
ffffffffc020056a:	953e                	add	a0,a0,a5
ffffffffc020056c:	4581                	li	a1,0
ffffffffc020056e:	4601                	li	a2,0
ffffffffc0200570:	4881                	li	a7,0
ffffffffc0200572:	00000073          	ecall
ffffffffc0200576:	8082                	ret

ffffffffc0200578 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200578:	8082                	ret

ffffffffc020057a <cons_putc>:
#include <sched.h>
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020057a:	100027f3          	csrr	a5,sstatus
ffffffffc020057e:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200580:	0ff57513          	andi	a0,a0,255
ffffffffc0200584:	e799                	bnez	a5,ffffffffc0200592 <cons_putc+0x18>
ffffffffc0200586:	4581                	li	a1,0
ffffffffc0200588:	4601                	li	a2,0
ffffffffc020058a:	4885                	li	a7,1
ffffffffc020058c:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc0200590:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200592:	1101                	addi	sp,sp,-32
ffffffffc0200594:	ec06                	sd	ra,24(sp)
ffffffffc0200596:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200598:	0ae000ef          	jal	ra,ffffffffc0200646 <intr_disable>
ffffffffc020059c:	6522                	ld	a0,8(sp)
ffffffffc020059e:	4581                	li	a1,0
ffffffffc02005a0:	4601                	li	a2,0
ffffffffc02005a2:	4885                	li	a7,1
ffffffffc02005a4:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005a8:	60e2                	ld	ra,24(sp)
ffffffffc02005aa:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02005ac:	a851                	j	ffffffffc0200640 <intr_enable>

ffffffffc02005ae <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02005ae:	100027f3          	csrr	a5,sstatus
ffffffffc02005b2:	8b89                	andi	a5,a5,2
ffffffffc02005b4:	eb89                	bnez	a5,ffffffffc02005c6 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02005b6:	4501                	li	a0,0
ffffffffc02005b8:	4581                	li	a1,0
ffffffffc02005ba:	4601                	li	a2,0
ffffffffc02005bc:	4889                	li	a7,2
ffffffffc02005be:	00000073          	ecall
ffffffffc02005c2:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005c4:	8082                	ret
int cons_getc(void) {
ffffffffc02005c6:	1101                	addi	sp,sp,-32
ffffffffc02005c8:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005ca:	07c000ef          	jal	ra,ffffffffc0200646 <intr_disable>
ffffffffc02005ce:	4501                	li	a0,0
ffffffffc02005d0:	4581                	li	a1,0
ffffffffc02005d2:	4601                	li	a2,0
ffffffffc02005d4:	4889                	li	a7,2
ffffffffc02005d6:	00000073          	ecall
ffffffffc02005da:	2501                	sext.w	a0,a0
ffffffffc02005dc:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005de:	062000ef          	jal	ra,ffffffffc0200640 <intr_enable>
}
ffffffffc02005e2:	60e2                	ld	ra,24(sp)
ffffffffc02005e4:	6522                	ld	a0,8(sp)
ffffffffc02005e6:	6105                	addi	sp,sp,32
ffffffffc02005e8:	8082                	ret

ffffffffc02005ea <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc02005ea:	8082                	ret

ffffffffc02005ec <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc02005ec:	00253513          	sltiu	a0,a0,2
ffffffffc02005f0:	8082                	ret

ffffffffc02005f2 <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc02005f2:	03800513          	li	a0,56
ffffffffc02005f6:	8082                	ret

ffffffffc02005f8 <ide_read_secs>:

int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
    int iobase = secno * SECTSIZE;
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02005f8:	000a7797          	auipc	a5,0xa7
ffffffffc02005fc:	34878793          	addi	a5,a5,840 # ffffffffc02a7940 <ide>
    int iobase = secno * SECTSIZE;
ffffffffc0200600:	0095959b          	slliw	a1,a1,0x9
                  size_t nsecs) {
ffffffffc0200604:	1141                	addi	sp,sp,-16
ffffffffc0200606:	8532                	mv	a0,a2
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc0200608:	95be                	add	a1,a1,a5
ffffffffc020060a:	00969613          	slli	a2,a3,0x9
                  size_t nsecs) {
ffffffffc020060e:	e406                	sd	ra,8(sp)
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc0200610:	7dd050ef          	jal	ra,ffffffffc02065ec <memcpy>
    return 0;
}
ffffffffc0200614:	60a2                	ld	ra,8(sp)
ffffffffc0200616:	4501                	li	a0,0
ffffffffc0200618:	0141                	addi	sp,sp,16
ffffffffc020061a:	8082                	ret

ffffffffc020061c <ide_write_secs>:

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
    int iobase = secno * SECTSIZE;
ffffffffc020061c:	0095979b          	slliw	a5,a1,0x9
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200620:	000a7517          	auipc	a0,0xa7
ffffffffc0200624:	32050513          	addi	a0,a0,800 # ffffffffc02a7940 <ide>
                   size_t nsecs) {
ffffffffc0200628:	1141                	addi	sp,sp,-16
ffffffffc020062a:	85b2                	mv	a1,a2
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc020062c:	953e                	add	a0,a0,a5
ffffffffc020062e:	00969613          	slli	a2,a3,0x9
                   size_t nsecs) {
ffffffffc0200632:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200634:	7b9050ef          	jal	ra,ffffffffc02065ec <memcpy>
    return 0;
}
ffffffffc0200638:	60a2                	ld	ra,8(sp)
ffffffffc020063a:	4501                	li	a0,0
ffffffffc020063c:	0141                	addi	sp,sp,16
ffffffffc020063e:	8082                	ret

ffffffffc0200640 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200640:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200644:	8082                	ret

ffffffffc0200646 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200646:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020064a:	8082                	ret

ffffffffc020064c <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc020064c:	8082                	ret

ffffffffc020064e <idt_init>:
 */
void idt_init(void) {
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020064e:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200652:	00000797          	auipc	a5,0x0
ffffffffc0200656:	69278793          	addi	a5,a5,1682 # ffffffffc0200ce4 <__alltraps>
ffffffffc020065a:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc020065e:	000407b7          	lui	a5,0x40
ffffffffc0200662:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200666:	8082                	ret

ffffffffc0200668 <print_regs>:
    cprintf("  tval 0x%08x\n", tf->tval);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200668:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc020066a:	1141                	addi	sp,sp,-16
ffffffffc020066c:	e022                	sd	s0,0(sp)
ffffffffc020066e:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200670:	00006517          	auipc	a0,0x6
ffffffffc0200674:	2a850513          	addi	a0,a0,680 # ffffffffc0206918 <commands+0xa8>
void print_regs(struct pushregs *gpr) {
ffffffffc0200678:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020067a:	b07ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020067e:	640c                	ld	a1,8(s0)
ffffffffc0200680:	00006517          	auipc	a0,0x6
ffffffffc0200684:	2b050513          	addi	a0,a0,688 # ffffffffc0206930 <commands+0xc0>
ffffffffc0200688:	af9ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020068c:	680c                	ld	a1,16(s0)
ffffffffc020068e:	00006517          	auipc	a0,0x6
ffffffffc0200692:	2ba50513          	addi	a0,a0,698 # ffffffffc0206948 <commands+0xd8>
ffffffffc0200696:	aebff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc020069a:	6c0c                	ld	a1,24(s0)
ffffffffc020069c:	00006517          	auipc	a0,0x6
ffffffffc02006a0:	2c450513          	addi	a0,a0,708 # ffffffffc0206960 <commands+0xf0>
ffffffffc02006a4:	addff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02006a8:	700c                	ld	a1,32(s0)
ffffffffc02006aa:	00006517          	auipc	a0,0x6
ffffffffc02006ae:	2ce50513          	addi	a0,a0,718 # ffffffffc0206978 <commands+0x108>
ffffffffc02006b2:	acfff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02006b6:	740c                	ld	a1,40(s0)
ffffffffc02006b8:	00006517          	auipc	a0,0x6
ffffffffc02006bc:	2d850513          	addi	a0,a0,728 # ffffffffc0206990 <commands+0x120>
ffffffffc02006c0:	ac1ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02006c4:	780c                	ld	a1,48(s0)
ffffffffc02006c6:	00006517          	auipc	a0,0x6
ffffffffc02006ca:	2e250513          	addi	a0,a0,738 # ffffffffc02069a8 <commands+0x138>
ffffffffc02006ce:	ab3ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02006d2:	7c0c                	ld	a1,56(s0)
ffffffffc02006d4:	00006517          	auipc	a0,0x6
ffffffffc02006d8:	2ec50513          	addi	a0,a0,748 # ffffffffc02069c0 <commands+0x150>
ffffffffc02006dc:	aa5ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02006e0:	602c                	ld	a1,64(s0)
ffffffffc02006e2:	00006517          	auipc	a0,0x6
ffffffffc02006e6:	2f650513          	addi	a0,a0,758 # ffffffffc02069d8 <commands+0x168>
ffffffffc02006ea:	a97ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02006ee:	642c                	ld	a1,72(s0)
ffffffffc02006f0:	00006517          	auipc	a0,0x6
ffffffffc02006f4:	30050513          	addi	a0,a0,768 # ffffffffc02069f0 <commands+0x180>
ffffffffc02006f8:	a89ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02006fc:	682c                	ld	a1,80(s0)
ffffffffc02006fe:	00006517          	auipc	a0,0x6
ffffffffc0200702:	30a50513          	addi	a0,a0,778 # ffffffffc0206a08 <commands+0x198>
ffffffffc0200706:	a7bff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020070a:	6c2c                	ld	a1,88(s0)
ffffffffc020070c:	00006517          	auipc	a0,0x6
ffffffffc0200710:	31450513          	addi	a0,a0,788 # ffffffffc0206a20 <commands+0x1b0>
ffffffffc0200714:	a6dff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200718:	702c                	ld	a1,96(s0)
ffffffffc020071a:	00006517          	auipc	a0,0x6
ffffffffc020071e:	31e50513          	addi	a0,a0,798 # ffffffffc0206a38 <commands+0x1c8>
ffffffffc0200722:	a5fff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200726:	742c                	ld	a1,104(s0)
ffffffffc0200728:	00006517          	auipc	a0,0x6
ffffffffc020072c:	32850513          	addi	a0,a0,808 # ffffffffc0206a50 <commands+0x1e0>
ffffffffc0200730:	a51ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200734:	782c                	ld	a1,112(s0)
ffffffffc0200736:	00006517          	auipc	a0,0x6
ffffffffc020073a:	33250513          	addi	a0,a0,818 # ffffffffc0206a68 <commands+0x1f8>
ffffffffc020073e:	a43ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200742:	7c2c                	ld	a1,120(s0)
ffffffffc0200744:	00006517          	auipc	a0,0x6
ffffffffc0200748:	33c50513          	addi	a0,a0,828 # ffffffffc0206a80 <commands+0x210>
ffffffffc020074c:	a35ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200750:	604c                	ld	a1,128(s0)
ffffffffc0200752:	00006517          	auipc	a0,0x6
ffffffffc0200756:	34650513          	addi	a0,a0,838 # ffffffffc0206a98 <commands+0x228>
ffffffffc020075a:	a27ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020075e:	644c                	ld	a1,136(s0)
ffffffffc0200760:	00006517          	auipc	a0,0x6
ffffffffc0200764:	35050513          	addi	a0,a0,848 # ffffffffc0206ab0 <commands+0x240>
ffffffffc0200768:	a19ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020076c:	684c                	ld	a1,144(s0)
ffffffffc020076e:	00006517          	auipc	a0,0x6
ffffffffc0200772:	35a50513          	addi	a0,a0,858 # ffffffffc0206ac8 <commands+0x258>
ffffffffc0200776:	a0bff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020077a:	6c4c                	ld	a1,152(s0)
ffffffffc020077c:	00006517          	auipc	a0,0x6
ffffffffc0200780:	36450513          	addi	a0,a0,868 # ffffffffc0206ae0 <commands+0x270>
ffffffffc0200784:	9fdff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200788:	704c                	ld	a1,160(s0)
ffffffffc020078a:	00006517          	auipc	a0,0x6
ffffffffc020078e:	36e50513          	addi	a0,a0,878 # ffffffffc0206af8 <commands+0x288>
ffffffffc0200792:	9efff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200796:	744c                	ld	a1,168(s0)
ffffffffc0200798:	00006517          	auipc	a0,0x6
ffffffffc020079c:	37850513          	addi	a0,a0,888 # ffffffffc0206b10 <commands+0x2a0>
ffffffffc02007a0:	9e1ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02007a4:	784c                	ld	a1,176(s0)
ffffffffc02007a6:	00006517          	auipc	a0,0x6
ffffffffc02007aa:	38250513          	addi	a0,a0,898 # ffffffffc0206b28 <commands+0x2b8>
ffffffffc02007ae:	9d3ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02007b2:	7c4c                	ld	a1,184(s0)
ffffffffc02007b4:	00006517          	auipc	a0,0x6
ffffffffc02007b8:	38c50513          	addi	a0,a0,908 # ffffffffc0206b40 <commands+0x2d0>
ffffffffc02007bc:	9c5ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02007c0:	606c                	ld	a1,192(s0)
ffffffffc02007c2:	00006517          	auipc	a0,0x6
ffffffffc02007c6:	39650513          	addi	a0,a0,918 # ffffffffc0206b58 <commands+0x2e8>
ffffffffc02007ca:	9b7ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02007ce:	646c                	ld	a1,200(s0)
ffffffffc02007d0:	00006517          	auipc	a0,0x6
ffffffffc02007d4:	3a050513          	addi	a0,a0,928 # ffffffffc0206b70 <commands+0x300>
ffffffffc02007d8:	9a9ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02007dc:	686c                	ld	a1,208(s0)
ffffffffc02007de:	00006517          	auipc	a0,0x6
ffffffffc02007e2:	3aa50513          	addi	a0,a0,938 # ffffffffc0206b88 <commands+0x318>
ffffffffc02007e6:	99bff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02007ea:	6c6c                	ld	a1,216(s0)
ffffffffc02007ec:	00006517          	auipc	a0,0x6
ffffffffc02007f0:	3b450513          	addi	a0,a0,948 # ffffffffc0206ba0 <commands+0x330>
ffffffffc02007f4:	98dff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02007f8:	706c                	ld	a1,224(s0)
ffffffffc02007fa:	00006517          	auipc	a0,0x6
ffffffffc02007fe:	3be50513          	addi	a0,a0,958 # ffffffffc0206bb8 <commands+0x348>
ffffffffc0200802:	97fff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200806:	746c                	ld	a1,232(s0)
ffffffffc0200808:	00006517          	auipc	a0,0x6
ffffffffc020080c:	3c850513          	addi	a0,a0,968 # ffffffffc0206bd0 <commands+0x360>
ffffffffc0200810:	971ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200814:	786c                	ld	a1,240(s0)
ffffffffc0200816:	00006517          	auipc	a0,0x6
ffffffffc020081a:	3d250513          	addi	a0,a0,978 # ffffffffc0206be8 <commands+0x378>
ffffffffc020081e:	963ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200822:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200824:	6402                	ld	s0,0(sp)
ffffffffc0200826:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200828:	00006517          	auipc	a0,0x6
ffffffffc020082c:	3d850513          	addi	a0,a0,984 # ffffffffc0206c00 <commands+0x390>
}
ffffffffc0200830:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200832:	b2b9                	j	ffffffffc0200180 <cprintf>

ffffffffc0200834 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200834:	1141                	addi	sp,sp,-16
ffffffffc0200836:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200838:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc020083a:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc020083c:	00006517          	auipc	a0,0x6
ffffffffc0200840:	3dc50513          	addi	a0,a0,988 # ffffffffc0206c18 <commands+0x3a8>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200844:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200846:	93bff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    print_regs(&tf->gpr);
ffffffffc020084a:	8522                	mv	a0,s0
ffffffffc020084c:	e1dff0ef          	jal	ra,ffffffffc0200668 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200850:	10043583          	ld	a1,256(s0)
ffffffffc0200854:	00006517          	auipc	a0,0x6
ffffffffc0200858:	3dc50513          	addi	a0,a0,988 # ffffffffc0206c30 <commands+0x3c0>
ffffffffc020085c:	925ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200860:	10843583          	ld	a1,264(s0)
ffffffffc0200864:	00006517          	auipc	a0,0x6
ffffffffc0200868:	3e450513          	addi	a0,a0,996 # ffffffffc0206c48 <commands+0x3d8>
ffffffffc020086c:	915ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200870:	11043583          	ld	a1,272(s0)
ffffffffc0200874:	00006517          	auipc	a0,0x6
ffffffffc0200878:	3ec50513          	addi	a0,a0,1004 # ffffffffc0206c60 <commands+0x3f0>
ffffffffc020087c:	905ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200880:	11843583          	ld	a1,280(s0)
}
ffffffffc0200884:	6402                	ld	s0,0(sp)
ffffffffc0200886:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200888:	00006517          	auipc	a0,0x6
ffffffffc020088c:	3e850513          	addi	a0,a0,1000 # ffffffffc0206c70 <commands+0x400>
}
ffffffffc0200890:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200892:	8efff06f          	j	ffffffffc0200180 <cprintf>

ffffffffc0200896 <pgfault_handler>:
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
            trap_in_kernel(tf) ? 'K' : 'U',
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

static int pgfault_handler(struct trapframe *tf) {
ffffffffc0200896:	1101                	addi	sp,sp,-32
ffffffffc0200898:	e426                	sd	s1,8(sp)
    extern struct mm_struct *check_mm_struct;
    if(check_mm_struct !=NULL) { //used for test check_swap
ffffffffc020089a:	000b2497          	auipc	s1,0xb2
ffffffffc020089e:	1d648493          	addi	s1,s1,470 # ffffffffc02b2a70 <check_mm_struct>
ffffffffc02008a2:	609c                	ld	a5,0(s1)
static int pgfault_handler(struct trapframe *tf) {
ffffffffc02008a4:	e822                	sd	s0,16(sp)
ffffffffc02008a6:	ec06                	sd	ra,24(sp)
ffffffffc02008a8:	842a                	mv	s0,a0
    if(check_mm_struct !=NULL) { //used for test check_swap
ffffffffc02008aa:	cbad                	beqz	a5,ffffffffc020091c <pgfault_handler+0x86>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02008ac:	10053783          	ld	a5,256(a0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02008b0:	11053583          	ld	a1,272(a0)
ffffffffc02008b4:	04b00613          	li	a2,75
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02008b8:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02008bc:	c7b1                	beqz	a5,ffffffffc0200908 <pgfault_handler+0x72>
ffffffffc02008be:	11843703          	ld	a4,280(s0)
ffffffffc02008c2:	47bd                	li	a5,15
ffffffffc02008c4:	05700693          	li	a3,87
ffffffffc02008c8:	00f70463          	beq	a4,a5,ffffffffc02008d0 <pgfault_handler+0x3a>
ffffffffc02008cc:	05200693          	li	a3,82
ffffffffc02008d0:	00006517          	auipc	a0,0x6
ffffffffc02008d4:	3b850513          	addi	a0,a0,952 # ffffffffc0206c88 <commands+0x418>
ffffffffc02008d8:	8a9ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
            print_pgfault(tf);
        }
    struct mm_struct *mm;
    if (check_mm_struct != NULL) {
ffffffffc02008dc:	6088                	ld	a0,0(s1)
ffffffffc02008de:	cd1d                	beqz	a0,ffffffffc020091c <pgfault_handler+0x86>
        assert(current == idleproc);
ffffffffc02008e0:	000b2717          	auipc	a4,0xb2
ffffffffc02008e4:	1a073703          	ld	a4,416(a4) # ffffffffc02b2a80 <current>
ffffffffc02008e8:	000b2797          	auipc	a5,0xb2
ffffffffc02008ec:	1a07b783          	ld	a5,416(a5) # ffffffffc02b2a88 <idleproc>
ffffffffc02008f0:	04f71663          	bne	a4,a5,ffffffffc020093c <pgfault_handler+0xa6>
            print_pgfault(tf);
            panic("unhandled page fault.\n");
        }
        mm = current->mm;
    }
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc02008f4:	11043603          	ld	a2,272(s0)
ffffffffc02008f8:	11843583          	ld	a1,280(s0)
}
ffffffffc02008fc:	6442                	ld	s0,16(sp)
ffffffffc02008fe:	60e2                	ld	ra,24(sp)
ffffffffc0200900:	64a2                	ld	s1,8(sp)
ffffffffc0200902:	6105                	addi	sp,sp,32
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200904:	1220406f          	j	ffffffffc0204a26 <do_pgfault>
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200908:	11843703          	ld	a4,280(s0)
ffffffffc020090c:	47bd                	li	a5,15
ffffffffc020090e:	05500613          	li	a2,85
ffffffffc0200912:	05700693          	li	a3,87
ffffffffc0200916:	faf71be3          	bne	a4,a5,ffffffffc02008cc <pgfault_handler+0x36>
ffffffffc020091a:	bf5d                	j	ffffffffc02008d0 <pgfault_handler+0x3a>
        if (current == NULL) {
ffffffffc020091c:	000b2797          	auipc	a5,0xb2
ffffffffc0200920:	1647b783          	ld	a5,356(a5) # ffffffffc02b2a80 <current>
ffffffffc0200924:	cf85                	beqz	a5,ffffffffc020095c <pgfault_handler+0xc6>
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200926:	11043603          	ld	a2,272(s0)
ffffffffc020092a:	11843583          	ld	a1,280(s0)
}
ffffffffc020092e:	6442                	ld	s0,16(sp)
ffffffffc0200930:	60e2                	ld	ra,24(sp)
ffffffffc0200932:	64a2                	ld	s1,8(sp)
        mm = current->mm;
ffffffffc0200934:	7788                	ld	a0,40(a5)
}
ffffffffc0200936:	6105                	addi	sp,sp,32
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200938:	0ee0406f          	j	ffffffffc0204a26 <do_pgfault>
        assert(current == idleproc);
ffffffffc020093c:	00006697          	auipc	a3,0x6
ffffffffc0200940:	36c68693          	addi	a3,a3,876 # ffffffffc0206ca8 <commands+0x438>
ffffffffc0200944:	00006617          	auipc	a2,0x6
ffffffffc0200948:	37c60613          	addi	a2,a2,892 # ffffffffc0206cc0 <commands+0x450>
ffffffffc020094c:	06d00593          	li	a1,109
ffffffffc0200950:	00006517          	auipc	a0,0x6
ffffffffc0200954:	38850513          	addi	a0,a0,904 # ffffffffc0206cd8 <commands+0x468>
ffffffffc0200958:	b23ff0ef          	jal	ra,ffffffffc020047a <__panic>
            print_trapframe(tf);
ffffffffc020095c:	8522                	mv	a0,s0
ffffffffc020095e:	ed7ff0ef          	jal	ra,ffffffffc0200834 <print_trapframe>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200962:	10043783          	ld	a5,256(s0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200966:	11043583          	ld	a1,272(s0)
ffffffffc020096a:	04b00613          	li	a2,75
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc020096e:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200972:	e399                	bnez	a5,ffffffffc0200978 <pgfault_handler+0xe2>
ffffffffc0200974:	05500613          	li	a2,85
ffffffffc0200978:	11843703          	ld	a4,280(s0)
ffffffffc020097c:	47bd                	li	a5,15
ffffffffc020097e:	02f70663          	beq	a4,a5,ffffffffc02009aa <pgfault_handler+0x114>
ffffffffc0200982:	05200693          	li	a3,82
ffffffffc0200986:	00006517          	auipc	a0,0x6
ffffffffc020098a:	30250513          	addi	a0,a0,770 # ffffffffc0206c88 <commands+0x418>
ffffffffc020098e:	ff2ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
            panic("unhandled page fault.\n");
ffffffffc0200992:	00006617          	auipc	a2,0x6
ffffffffc0200996:	35e60613          	addi	a2,a2,862 # ffffffffc0206cf0 <commands+0x480>
ffffffffc020099a:	07400593          	li	a1,116
ffffffffc020099e:	00006517          	auipc	a0,0x6
ffffffffc02009a2:	33a50513          	addi	a0,a0,826 # ffffffffc0206cd8 <commands+0x468>
ffffffffc02009a6:	ad5ff0ef          	jal	ra,ffffffffc020047a <__panic>
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02009aa:	05700693          	li	a3,87
ffffffffc02009ae:	bfe1                	j	ffffffffc0200986 <pgfault_handler+0xf0>

ffffffffc02009b0 <interrupt_handler>:

static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02009b0:	11853783          	ld	a5,280(a0)
ffffffffc02009b4:	472d                	li	a4,11
ffffffffc02009b6:	0786                	slli	a5,a5,0x1
ffffffffc02009b8:	8385                	srli	a5,a5,0x1
ffffffffc02009ba:	08f76363          	bltu	a4,a5,ffffffffc0200a40 <interrupt_handler+0x90>
ffffffffc02009be:	00006717          	auipc	a4,0x6
ffffffffc02009c2:	3ea70713          	addi	a4,a4,1002 # ffffffffc0206da8 <commands+0x538>
ffffffffc02009c6:	078a                	slli	a5,a5,0x2
ffffffffc02009c8:	97ba                	add	a5,a5,a4
ffffffffc02009ca:	439c                	lw	a5,0(a5)
ffffffffc02009cc:	97ba                	add	a5,a5,a4
ffffffffc02009ce:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02009d0:	00006517          	auipc	a0,0x6
ffffffffc02009d4:	39850513          	addi	a0,a0,920 # ffffffffc0206d68 <commands+0x4f8>
ffffffffc02009d8:	fa8ff06f          	j	ffffffffc0200180 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02009dc:	00006517          	auipc	a0,0x6
ffffffffc02009e0:	36c50513          	addi	a0,a0,876 # ffffffffc0206d48 <commands+0x4d8>
ffffffffc02009e4:	f9cff06f          	j	ffffffffc0200180 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02009e8:	00006517          	auipc	a0,0x6
ffffffffc02009ec:	32050513          	addi	a0,a0,800 # ffffffffc0206d08 <commands+0x498>
ffffffffc02009f0:	f90ff06f          	j	ffffffffc0200180 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc02009f4:	00006517          	auipc	a0,0x6
ffffffffc02009f8:	33450513          	addi	a0,a0,820 # ffffffffc0206d28 <commands+0x4b8>
ffffffffc02009fc:	f84ff06f          	j	ffffffffc0200180 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200a00:	1141                	addi	sp,sp,-16
ffffffffc0200a02:	e406                	sd	ra,8(sp)
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc0200a04:	b5bff0ef          	jal	ra,ffffffffc020055e <clock_set_next_event>
            if (++ticks % TICK_NUM == 0 && current) {
ffffffffc0200a08:	000b2697          	auipc	a3,0xb2
ffffffffc0200a0c:	00868693          	addi	a3,a3,8 # ffffffffc02b2a10 <ticks>
ffffffffc0200a10:	629c                	ld	a5,0(a3)
ffffffffc0200a12:	06400713          	li	a4,100
ffffffffc0200a16:	0785                	addi	a5,a5,1
ffffffffc0200a18:	02e7f733          	remu	a4,a5,a4
ffffffffc0200a1c:	e29c                	sd	a5,0(a3)
ffffffffc0200a1e:	eb01                	bnez	a4,ffffffffc0200a2e <interrupt_handler+0x7e>
ffffffffc0200a20:	000b2797          	auipc	a5,0xb2
ffffffffc0200a24:	0607b783          	ld	a5,96(a5) # ffffffffc02b2a80 <current>
ffffffffc0200a28:	c399                	beqz	a5,ffffffffc0200a2e <interrupt_handler+0x7e>
                //print_ticks();
                current->need_resched = 1;
ffffffffc0200a2a:	4705                	li	a4,1
ffffffffc0200a2c:	ef98                	sd	a4,24(a5)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200a2e:	60a2                	ld	ra,8(sp)
ffffffffc0200a30:	0141                	addi	sp,sp,16
ffffffffc0200a32:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200a34:	00006517          	auipc	a0,0x6
ffffffffc0200a38:	35450513          	addi	a0,a0,852 # ffffffffc0206d88 <commands+0x518>
ffffffffc0200a3c:	f44ff06f          	j	ffffffffc0200180 <cprintf>
            print_trapframe(tf);
ffffffffc0200a40:	bbd5                	j	ffffffffc0200834 <print_trapframe>

ffffffffc0200a42 <exception_handler>:
void kernel_execve_ret(struct trapframe *tf,uintptr_t kstacktop);
void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
ffffffffc0200a42:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200a46:	1101                	addi	sp,sp,-32
ffffffffc0200a48:	e822                	sd	s0,16(sp)
ffffffffc0200a4a:	ec06                	sd	ra,24(sp)
ffffffffc0200a4c:	e426                	sd	s1,8(sp)
ffffffffc0200a4e:	473d                	li	a4,15
ffffffffc0200a50:	842a                	mv	s0,a0
ffffffffc0200a52:	18f76e63          	bltu	a4,a5,ffffffffc0200bee <exception_handler+0x1ac>
ffffffffc0200a56:	00006717          	auipc	a4,0x6
ffffffffc0200a5a:	57a70713          	addi	a4,a4,1402 # ffffffffc0206fd0 <commands+0x760>
ffffffffc0200a5e:	078a                	slli	a5,a5,0x2
ffffffffc0200a60:	97ba                	add	a5,a5,a4
ffffffffc0200a62:	439c                	lw	a5,0(a5)
ffffffffc0200a64:	97ba                	add	a5,a5,a4
ffffffffc0200a66:	8782                	jr	a5
            //cprintf("Environment call from U-mode\n");
            tf->epc += 4;
            syscall();
            break;
        case CAUSE_SUPERVISOR_ECALL:
            cprintf("Environment call from S-mode\n");
ffffffffc0200a68:	00006517          	auipc	a0,0x6
ffffffffc0200a6c:	4c050513          	addi	a0,a0,1216 # ffffffffc0206f28 <commands+0x6b8>
ffffffffc0200a70:	f10ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
            tf->epc += 4;
ffffffffc0200a74:	10843783          	ld	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200a78:	60e2                	ld	ra,24(sp)
ffffffffc0200a7a:	64a2                	ld	s1,8(sp)
            tf->epc += 4;
ffffffffc0200a7c:	0791                	addi	a5,a5,4
ffffffffc0200a7e:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200a82:	6442                	ld	s0,16(sp)
ffffffffc0200a84:	6105                	addi	sp,sp,32
            syscall();
ffffffffc0200a86:	6540506f          	j	ffffffffc02060da <syscall>
            cprintf("Environment call from H-mode\n");
ffffffffc0200a8a:	00006517          	auipc	a0,0x6
ffffffffc0200a8e:	4be50513          	addi	a0,a0,1214 # ffffffffc0206f48 <commands+0x6d8>
}
ffffffffc0200a92:	6442                	ld	s0,16(sp)
ffffffffc0200a94:	60e2                	ld	ra,24(sp)
ffffffffc0200a96:	64a2                	ld	s1,8(sp)
ffffffffc0200a98:	6105                	addi	sp,sp,32
            cprintf("Instruction access fault\n");
ffffffffc0200a9a:	ee6ff06f          	j	ffffffffc0200180 <cprintf>
            cprintf("Environment call from M-mode\n");
ffffffffc0200a9e:	00006517          	auipc	a0,0x6
ffffffffc0200aa2:	4ca50513          	addi	a0,a0,1226 # ffffffffc0206f68 <commands+0x6f8>
ffffffffc0200aa6:	b7f5                	j	ffffffffc0200a92 <exception_handler+0x50>
            cprintf("Instruction page fault\n");
ffffffffc0200aa8:	00006517          	auipc	a0,0x6
ffffffffc0200aac:	4e050513          	addi	a0,a0,1248 # ffffffffc0206f88 <commands+0x718>
ffffffffc0200ab0:	b7cd                	j	ffffffffc0200a92 <exception_handler+0x50>
            cprintf("Load page fault\n");
ffffffffc0200ab2:	00006517          	auipc	a0,0x6
ffffffffc0200ab6:	4ee50513          	addi	a0,a0,1262 # ffffffffc0206fa0 <commands+0x730>
ffffffffc0200aba:	ec6ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200abe:	8522                	mv	a0,s0
ffffffffc0200ac0:	dd7ff0ef          	jal	ra,ffffffffc0200896 <pgfault_handler>
ffffffffc0200ac4:	84aa                	mv	s1,a0
ffffffffc0200ac6:	16051a63          	bnez	a0,ffffffffc0200c3a <exception_handler+0x1f8>
}
ffffffffc0200aca:	60e2                	ld	ra,24(sp)
ffffffffc0200acc:	6442                	ld	s0,16(sp)
ffffffffc0200ace:	64a2                	ld	s1,8(sp)
ffffffffc0200ad0:	6105                	addi	sp,sp,32
ffffffffc0200ad2:	8082                	ret
            cprintf("Store/AMO page fault\n");
ffffffffc0200ad4:	00006517          	auipc	a0,0x6
ffffffffc0200ad8:	4e450513          	addi	a0,a0,1252 # ffffffffc0206fb8 <commands+0x748>
ffffffffc0200adc:	ea4ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200ae0:	8522                	mv	a0,s0
ffffffffc0200ae2:	db5ff0ef          	jal	ra,ffffffffc0200896 <pgfault_handler>
ffffffffc0200ae6:	84aa                	mv	s1,a0
ffffffffc0200ae8:	d16d                	beqz	a0,ffffffffc0200aca <exception_handler+0x88>
                print_trapframe(tf);
ffffffffc0200aea:	8522                	mv	a0,s0
ffffffffc0200aec:	d49ff0ef          	jal	ra,ffffffffc0200834 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200af0:	86a6                	mv	a3,s1
ffffffffc0200af2:	00006617          	auipc	a2,0x6
ffffffffc0200af6:	3e660613          	addi	a2,a2,998 # ffffffffc0206ed8 <commands+0x668>
ffffffffc0200afa:	10900593          	li	a1,265
ffffffffc0200afe:	00006517          	auipc	a0,0x6
ffffffffc0200b02:	1da50513          	addi	a0,a0,474 # ffffffffc0206cd8 <commands+0x468>
ffffffffc0200b06:	975ff0ef          	jal	ra,ffffffffc020047a <__panic>
            cprintf("Instruction address misaligned\n");
ffffffffc0200b0a:	00006517          	auipc	a0,0x6
ffffffffc0200b0e:	2ce50513          	addi	a0,a0,718 # ffffffffc0206dd8 <commands+0x568>
ffffffffc0200b12:	b741                	j	ffffffffc0200a92 <exception_handler+0x50>
            cprintf("Instruction access fault\n");
ffffffffc0200b14:	00006517          	auipc	a0,0x6
ffffffffc0200b18:	2e450513          	addi	a0,a0,740 # ffffffffc0206df8 <commands+0x588>
ffffffffc0200b1c:	bf9d                	j	ffffffffc0200a92 <exception_handler+0x50>
		cprintf("Exception Type: Illegal instruction\n");
ffffffffc0200b1e:	00006517          	auipc	a0,0x6
ffffffffc0200b22:	2fa50513          	addi	a0,a0,762 # ffffffffc0206e18 <commands+0x5a8>
ffffffffc0200b26:	e5aff0ef          	jal	ra,ffffffffc0200180 <cprintf>
		cprintf("Illegal instruction caught at 0x%016llx\n", tf->epc);
ffffffffc0200b2a:	10843583          	ld	a1,264(s0)
ffffffffc0200b2e:	00006517          	auipc	a0,0x6
ffffffffc0200b32:	31250513          	addi	a0,a0,786 # ffffffffc0206e40 <commands+0x5d0>
ffffffffc0200b36:	e4aff0ef          	jal	ra,ffffffffc0200180 <cprintf>
		tf->epc += 2;
ffffffffc0200b3a:	10843783          	ld	a5,264(s0)
ffffffffc0200b3e:	0789                	addi	a5,a5,2
ffffffffc0200b40:	10f43423          	sd	a5,264(s0)
            break;
ffffffffc0200b44:	b759                	j	ffffffffc0200aca <exception_handler+0x88>
            cprintf("Breakpoint\n");
ffffffffc0200b46:	00006517          	auipc	a0,0x6
ffffffffc0200b4a:	32a50513          	addi	a0,a0,810 # ffffffffc0206e70 <commands+0x600>
ffffffffc0200b4e:	e32ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
            if(tf->gpr.a7 == 10){
ffffffffc0200b52:	6458                	ld	a4,136(s0)
ffffffffc0200b54:	47a9                	li	a5,10
ffffffffc0200b56:	0af70e63          	beq	a4,a5,ffffffffc0200c12 <exception_handler+0x1d0>
			cprintf("ebreak caught at 0x%016llx\n", tf->epc);
ffffffffc0200b5a:	10843583          	ld	a1,264(s0)
ffffffffc0200b5e:	00006517          	auipc	a0,0x6
ffffffffc0200b62:	32250513          	addi	a0,a0,802 # ffffffffc0206e80 <commands+0x610>
ffffffffc0200b66:	e1aff0ef          	jal	ra,ffffffffc0200180 <cprintf>
			tf->epc += 2;
ffffffffc0200b6a:	10843783          	ld	a5,264(s0)
ffffffffc0200b6e:	0789                	addi	a5,a5,2
ffffffffc0200b70:	10f43423          	sd	a5,264(s0)
ffffffffc0200b74:	bf99                	j	ffffffffc0200aca <exception_handler+0x88>
            cprintf("Load address misaligned\n");
ffffffffc0200b76:	00006517          	auipc	a0,0x6
ffffffffc0200b7a:	32a50513          	addi	a0,a0,810 # ffffffffc0206ea0 <commands+0x630>
ffffffffc0200b7e:	bf11                	j	ffffffffc0200a92 <exception_handler+0x50>
            cprintf("Load access fault\n");
ffffffffc0200b80:	00006517          	auipc	a0,0x6
ffffffffc0200b84:	34050513          	addi	a0,a0,832 # ffffffffc0206ec0 <commands+0x650>
ffffffffc0200b88:	df8ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200b8c:	8522                	mv	a0,s0
ffffffffc0200b8e:	d09ff0ef          	jal	ra,ffffffffc0200896 <pgfault_handler>
ffffffffc0200b92:	84aa                	mv	s1,a0
ffffffffc0200b94:	d91d                	beqz	a0,ffffffffc0200aca <exception_handler+0x88>
                print_trapframe(tf);
ffffffffc0200b96:	8522                	mv	a0,s0
ffffffffc0200b98:	c9dff0ef          	jal	ra,ffffffffc0200834 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200b9c:	86a6                	mv	a3,s1
ffffffffc0200b9e:	00006617          	auipc	a2,0x6
ffffffffc0200ba2:	33a60613          	addi	a2,a2,826 # ffffffffc0206ed8 <commands+0x668>
ffffffffc0200ba6:	0de00593          	li	a1,222
ffffffffc0200baa:	00006517          	auipc	a0,0x6
ffffffffc0200bae:	12e50513          	addi	a0,a0,302 # ffffffffc0206cd8 <commands+0x468>
ffffffffc0200bb2:	8c9ff0ef          	jal	ra,ffffffffc020047a <__panic>
            cprintf("Store/AMO access fault\n");
ffffffffc0200bb6:	00006517          	auipc	a0,0x6
ffffffffc0200bba:	35a50513          	addi	a0,a0,858 # ffffffffc0206f10 <commands+0x6a0>
ffffffffc0200bbe:	dc2ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200bc2:	8522                	mv	a0,s0
ffffffffc0200bc4:	cd3ff0ef          	jal	ra,ffffffffc0200896 <pgfault_handler>
ffffffffc0200bc8:	84aa                	mv	s1,a0
ffffffffc0200bca:	f00500e3          	beqz	a0,ffffffffc0200aca <exception_handler+0x88>
                print_trapframe(tf);
ffffffffc0200bce:	8522                	mv	a0,s0
ffffffffc0200bd0:	c65ff0ef          	jal	ra,ffffffffc0200834 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200bd4:	86a6                	mv	a3,s1
ffffffffc0200bd6:	00006617          	auipc	a2,0x6
ffffffffc0200bda:	30260613          	addi	a2,a2,770 # ffffffffc0206ed8 <commands+0x668>
ffffffffc0200bde:	0e800593          	li	a1,232
ffffffffc0200be2:	00006517          	auipc	a0,0x6
ffffffffc0200be6:	0f650513          	addi	a0,a0,246 # ffffffffc0206cd8 <commands+0x468>
ffffffffc0200bea:	891ff0ef          	jal	ra,ffffffffc020047a <__panic>
            print_trapframe(tf);
ffffffffc0200bee:	8522                	mv	a0,s0
}
ffffffffc0200bf0:	6442                	ld	s0,16(sp)
ffffffffc0200bf2:	60e2                	ld	ra,24(sp)
ffffffffc0200bf4:	64a2                	ld	s1,8(sp)
ffffffffc0200bf6:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc0200bf8:	b935                	j	ffffffffc0200834 <print_trapframe>
            panic("AMO address misaligned\n");
ffffffffc0200bfa:	00006617          	auipc	a2,0x6
ffffffffc0200bfe:	2fe60613          	addi	a2,a2,766 # ffffffffc0206ef8 <commands+0x688>
ffffffffc0200c02:	0e200593          	li	a1,226
ffffffffc0200c06:	00006517          	auipc	a0,0x6
ffffffffc0200c0a:	0d250513          	addi	a0,a0,210 # ffffffffc0206cd8 <commands+0x468>
ffffffffc0200c0e:	86dff0ef          	jal	ra,ffffffffc020047a <__panic>
                tf->epc += 4;
ffffffffc0200c12:	10843783          	ld	a5,264(s0)
ffffffffc0200c16:	0791                	addi	a5,a5,4
ffffffffc0200c18:	10f43423          	sd	a5,264(s0)
                syscall();
ffffffffc0200c1c:	4be050ef          	jal	ra,ffffffffc02060da <syscall>
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200c20:	000b2797          	auipc	a5,0xb2
ffffffffc0200c24:	e607b783          	ld	a5,-416(a5) # ffffffffc02b2a80 <current>
ffffffffc0200c28:	6b9c                	ld	a5,16(a5)
ffffffffc0200c2a:	8522                	mv	a0,s0
}
ffffffffc0200c2c:	6442                	ld	s0,16(sp)
ffffffffc0200c2e:	60e2                	ld	ra,24(sp)
ffffffffc0200c30:	64a2                	ld	s1,8(sp)
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200c32:	6589                	lui	a1,0x2
ffffffffc0200c34:	95be                	add	a1,a1,a5
}
ffffffffc0200c36:	6105                	addi	sp,sp,32
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200c38:	aaad                	j	ffffffffc0200db2 <kernel_execve_ret>
                print_trapframe(tf);
ffffffffc0200c3a:	8522                	mv	a0,s0
ffffffffc0200c3c:	bf9ff0ef          	jal	ra,ffffffffc0200834 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200c40:	86a6                	mv	a3,s1
ffffffffc0200c42:	00006617          	auipc	a2,0x6
ffffffffc0200c46:	29660613          	addi	a2,a2,662 # ffffffffc0206ed8 <commands+0x668>
ffffffffc0200c4a:	10200593          	li	a1,258
ffffffffc0200c4e:	00006517          	auipc	a0,0x6
ffffffffc0200c52:	08a50513          	addi	a0,a0,138 # ffffffffc0206cd8 <commands+0x468>
ffffffffc0200c56:	825ff0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0200c5a <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void
trap(struct trapframe *tf) {
ffffffffc0200c5a:	1101                	addi	sp,sp,-32
ffffffffc0200c5c:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
//    cputs("some trap");
    if (current == NULL) {
ffffffffc0200c5e:	000b2417          	auipc	s0,0xb2
ffffffffc0200c62:	e2240413          	addi	s0,s0,-478 # ffffffffc02b2a80 <current>
ffffffffc0200c66:	6018                	ld	a4,0(s0)
trap(struct trapframe *tf) {
ffffffffc0200c68:	ec06                	sd	ra,24(sp)
ffffffffc0200c6a:	e426                	sd	s1,8(sp)
ffffffffc0200c6c:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c6e:	11853683          	ld	a3,280(a0)
    if (current == NULL) {
ffffffffc0200c72:	cf1d                	beqz	a4,ffffffffc0200cb0 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200c74:	10053483          	ld	s1,256(a0)
        trap_dispatch(tf);
    } else {
        struct trapframe *otf = current->tf;
ffffffffc0200c78:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200c7c:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200c7e:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c82:	0206c463          	bltz	a3,ffffffffc0200caa <trap+0x50>
        exception_handler(tf);
ffffffffc0200c86:	dbdff0ef          	jal	ra,ffffffffc0200a42 <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200c8a:	601c                	ld	a5,0(s0)
ffffffffc0200c8c:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel) {
ffffffffc0200c90:	e499                	bnez	s1,ffffffffc0200c9e <trap+0x44>
            if (current->flags & PF_EXITING) {
ffffffffc0200c92:	0b07a703          	lw	a4,176(a5)
ffffffffc0200c96:	8b05                	andi	a4,a4,1
ffffffffc0200c98:	e329                	bnez	a4,ffffffffc0200cda <trap+0x80>
                do_exit(-E_KILLED);
            }
            if (current->need_resched) {
ffffffffc0200c9a:	6f9c                	ld	a5,24(a5)
ffffffffc0200c9c:	eb85                	bnez	a5,ffffffffc0200ccc <trap+0x72>
                schedule();
            }
        }
    }
}
ffffffffc0200c9e:	60e2                	ld	ra,24(sp)
ffffffffc0200ca0:	6442                	ld	s0,16(sp)
ffffffffc0200ca2:	64a2                	ld	s1,8(sp)
ffffffffc0200ca4:	6902                	ld	s2,0(sp)
ffffffffc0200ca6:	6105                	addi	sp,sp,32
ffffffffc0200ca8:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200caa:	d07ff0ef          	jal	ra,ffffffffc02009b0 <interrupt_handler>
ffffffffc0200cae:	bff1                	j	ffffffffc0200c8a <trap+0x30>
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200cb0:	0006c863          	bltz	a3,ffffffffc0200cc0 <trap+0x66>
}
ffffffffc0200cb4:	6442                	ld	s0,16(sp)
ffffffffc0200cb6:	60e2                	ld	ra,24(sp)
ffffffffc0200cb8:	64a2                	ld	s1,8(sp)
ffffffffc0200cba:	6902                	ld	s2,0(sp)
ffffffffc0200cbc:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200cbe:	b351                	j	ffffffffc0200a42 <exception_handler>
}
ffffffffc0200cc0:	6442                	ld	s0,16(sp)
ffffffffc0200cc2:	60e2                	ld	ra,24(sp)
ffffffffc0200cc4:	64a2                	ld	s1,8(sp)
ffffffffc0200cc6:	6902                	ld	s2,0(sp)
ffffffffc0200cc8:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200cca:	b1dd                	j	ffffffffc02009b0 <interrupt_handler>
}
ffffffffc0200ccc:	6442                	ld	s0,16(sp)
ffffffffc0200cce:	60e2                	ld	ra,24(sp)
ffffffffc0200cd0:	64a2                	ld	s1,8(sp)
ffffffffc0200cd2:	6902                	ld	s2,0(sp)
ffffffffc0200cd4:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200cd6:	3180506f          	j	ffffffffc0205fee <schedule>
                do_exit(-E_KILLED);
ffffffffc0200cda:	555d                	li	a0,-9
ffffffffc0200cdc:	660040ef          	jal	ra,ffffffffc020533c <do_exit>
            if (current->need_resched) {
ffffffffc0200ce0:	601c                	ld	a5,0(s0)
ffffffffc0200ce2:	bf65                	j	ffffffffc0200c9a <trap+0x40>

ffffffffc0200ce4 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200ce4:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200ce8:	00011463          	bnez	sp,ffffffffc0200cf0 <__alltraps+0xc>
ffffffffc0200cec:	14002173          	csrr	sp,sscratch
ffffffffc0200cf0:	712d                	addi	sp,sp,-288
ffffffffc0200cf2:	e002                	sd	zero,0(sp)
ffffffffc0200cf4:	e406                	sd	ra,8(sp)
ffffffffc0200cf6:	ec0e                	sd	gp,24(sp)
ffffffffc0200cf8:	f012                	sd	tp,32(sp)
ffffffffc0200cfa:	f416                	sd	t0,40(sp)
ffffffffc0200cfc:	f81a                	sd	t1,48(sp)
ffffffffc0200cfe:	fc1e                	sd	t2,56(sp)
ffffffffc0200d00:	e0a2                	sd	s0,64(sp)
ffffffffc0200d02:	e4a6                	sd	s1,72(sp)
ffffffffc0200d04:	e8aa                	sd	a0,80(sp)
ffffffffc0200d06:	ecae                	sd	a1,88(sp)
ffffffffc0200d08:	f0b2                	sd	a2,96(sp)
ffffffffc0200d0a:	f4b6                	sd	a3,104(sp)
ffffffffc0200d0c:	f8ba                	sd	a4,112(sp)
ffffffffc0200d0e:	fcbe                	sd	a5,120(sp)
ffffffffc0200d10:	e142                	sd	a6,128(sp)
ffffffffc0200d12:	e546                	sd	a7,136(sp)
ffffffffc0200d14:	e94a                	sd	s2,144(sp)
ffffffffc0200d16:	ed4e                	sd	s3,152(sp)
ffffffffc0200d18:	f152                	sd	s4,160(sp)
ffffffffc0200d1a:	f556                	sd	s5,168(sp)
ffffffffc0200d1c:	f95a                	sd	s6,176(sp)
ffffffffc0200d1e:	fd5e                	sd	s7,184(sp)
ffffffffc0200d20:	e1e2                	sd	s8,192(sp)
ffffffffc0200d22:	e5e6                	sd	s9,200(sp)
ffffffffc0200d24:	e9ea                	sd	s10,208(sp)
ffffffffc0200d26:	edee                	sd	s11,216(sp)
ffffffffc0200d28:	f1f2                	sd	t3,224(sp)
ffffffffc0200d2a:	f5f6                	sd	t4,232(sp)
ffffffffc0200d2c:	f9fa                	sd	t5,240(sp)
ffffffffc0200d2e:	fdfe                	sd	t6,248(sp)
ffffffffc0200d30:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200d34:	100024f3          	csrr	s1,sstatus
ffffffffc0200d38:	14102973          	csrr	s2,sepc
ffffffffc0200d3c:	143029f3          	csrr	s3,stval
ffffffffc0200d40:	14202a73          	csrr	s4,scause
ffffffffc0200d44:	e822                	sd	s0,16(sp)
ffffffffc0200d46:	e226                	sd	s1,256(sp)
ffffffffc0200d48:	e64a                	sd	s2,264(sp)
ffffffffc0200d4a:	ea4e                	sd	s3,272(sp)
ffffffffc0200d4c:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200d4e:	850a                	mv	a0,sp
    jal trap
ffffffffc0200d50:	f0bff0ef          	jal	ra,ffffffffc0200c5a <trap>

ffffffffc0200d54 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200d54:	6492                	ld	s1,256(sp)
ffffffffc0200d56:	6932                	ld	s2,264(sp)
ffffffffc0200d58:	1004f413          	andi	s0,s1,256
ffffffffc0200d5c:	e401                	bnez	s0,ffffffffc0200d64 <__trapret+0x10>
ffffffffc0200d5e:	1200                	addi	s0,sp,288
ffffffffc0200d60:	14041073          	csrw	sscratch,s0
ffffffffc0200d64:	10049073          	csrw	sstatus,s1
ffffffffc0200d68:	14191073          	csrw	sepc,s2
ffffffffc0200d6c:	60a2                	ld	ra,8(sp)
ffffffffc0200d6e:	61e2                	ld	gp,24(sp)
ffffffffc0200d70:	7202                	ld	tp,32(sp)
ffffffffc0200d72:	72a2                	ld	t0,40(sp)
ffffffffc0200d74:	7342                	ld	t1,48(sp)
ffffffffc0200d76:	73e2                	ld	t2,56(sp)
ffffffffc0200d78:	6406                	ld	s0,64(sp)
ffffffffc0200d7a:	64a6                	ld	s1,72(sp)
ffffffffc0200d7c:	6546                	ld	a0,80(sp)
ffffffffc0200d7e:	65e6                	ld	a1,88(sp)
ffffffffc0200d80:	7606                	ld	a2,96(sp)
ffffffffc0200d82:	76a6                	ld	a3,104(sp)
ffffffffc0200d84:	7746                	ld	a4,112(sp)
ffffffffc0200d86:	77e6                	ld	a5,120(sp)
ffffffffc0200d88:	680a                	ld	a6,128(sp)
ffffffffc0200d8a:	68aa                	ld	a7,136(sp)
ffffffffc0200d8c:	694a                	ld	s2,144(sp)
ffffffffc0200d8e:	69ea                	ld	s3,152(sp)
ffffffffc0200d90:	7a0a                	ld	s4,160(sp)
ffffffffc0200d92:	7aaa                	ld	s5,168(sp)
ffffffffc0200d94:	7b4a                	ld	s6,176(sp)
ffffffffc0200d96:	7bea                	ld	s7,184(sp)
ffffffffc0200d98:	6c0e                	ld	s8,192(sp)
ffffffffc0200d9a:	6cae                	ld	s9,200(sp)
ffffffffc0200d9c:	6d4e                	ld	s10,208(sp)
ffffffffc0200d9e:	6dee                	ld	s11,216(sp)
ffffffffc0200da0:	7e0e                	ld	t3,224(sp)
ffffffffc0200da2:	7eae                	ld	t4,232(sp)
ffffffffc0200da4:	7f4e                	ld	t5,240(sp)
ffffffffc0200da6:	7fee                	ld	t6,248(sp)
ffffffffc0200da8:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200daa:	10200073          	sret

ffffffffc0200dae <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200dae:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200db0:	b755                	j	ffffffffc0200d54 <__trapret>

ffffffffc0200db2 <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200db2:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cf0>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200db6:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200dba:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200dbe:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200dc2:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200dc6:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200dca:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200dce:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200dd2:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200dd6:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200dd8:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200dda:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200ddc:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200dde:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200de0:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200de2:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200de4:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200de6:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200de8:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200dea:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200dec:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200dee:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200df0:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200df2:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200df4:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200df6:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200df8:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200dfa:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200dfc:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200dfe:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200e00:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200e02:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200e04:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200e06:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200e08:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200e0a:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200e0c:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200e0e:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200e10:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200e12:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200e14:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200e16:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200e18:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200e1a:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200e1c:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200e1e:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200e20:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200e22:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200e24:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200e26:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200e28:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200e2a:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200e2c:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200e2e:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200e30:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200e32:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200e34:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200e36:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200e38:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200e3a:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0200e3c:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0200e3e:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0200e40:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0200e42:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0200e44:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0200e46:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0200e48:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0200e4a:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0200e4c:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0200e4e:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0200e50:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0200e52:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0200e54:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0200e56:	812e                	mv	sp,a1
ffffffffc0200e58:	bdf5                	j	ffffffffc0200d54 <__trapret>

ffffffffc0200e5a <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200e5a:	000ae797          	auipc	a5,0xae
ffffffffc0200e5e:	ae678793          	addi	a5,a5,-1306 # ffffffffc02ae940 <free_area>
ffffffffc0200e62:	e79c                	sd	a5,8(a5)
ffffffffc0200e64:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200e66:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200e6a:	8082                	ret

ffffffffc0200e6c <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200e6c:	000ae517          	auipc	a0,0xae
ffffffffc0200e70:	ae456503          	lwu	a0,-1308(a0) # ffffffffc02ae950 <free_area+0x10>
ffffffffc0200e74:	8082                	ret

ffffffffc0200e76 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200e76:	715d                	addi	sp,sp,-80
ffffffffc0200e78:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200e7a:	000ae417          	auipc	s0,0xae
ffffffffc0200e7e:	ac640413          	addi	s0,s0,-1338 # ffffffffc02ae940 <free_area>
ffffffffc0200e82:	641c                	ld	a5,8(s0)
ffffffffc0200e84:	e486                	sd	ra,72(sp)
ffffffffc0200e86:	fc26                	sd	s1,56(sp)
ffffffffc0200e88:	f84a                	sd	s2,48(sp)
ffffffffc0200e8a:	f44e                	sd	s3,40(sp)
ffffffffc0200e8c:	f052                	sd	s4,32(sp)
ffffffffc0200e8e:	ec56                	sd	s5,24(sp)
ffffffffc0200e90:	e85a                	sd	s6,16(sp)
ffffffffc0200e92:	e45e                	sd	s7,8(sp)
ffffffffc0200e94:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e96:	2a878d63          	beq	a5,s0,ffffffffc0201150 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0200e9a:	4481                	li	s1,0
ffffffffc0200e9c:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200e9e:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200ea2:	8b09                	andi	a4,a4,2
ffffffffc0200ea4:	2a070a63          	beqz	a4,ffffffffc0201158 <default_check+0x2e2>
        count ++, total += p->property;
ffffffffc0200ea8:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200eac:	679c                	ld	a5,8(a5)
ffffffffc0200eae:	2905                	addiw	s2,s2,1
ffffffffc0200eb0:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200eb2:	fe8796e3          	bne	a5,s0,ffffffffc0200e9e <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200eb6:	89a6                	mv	s3,s1
ffffffffc0200eb8:	729000ef          	jal	ra,ffffffffc0201de0 <nr_free_pages>
ffffffffc0200ebc:	6f351e63          	bne	a0,s3,ffffffffc02015b8 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ec0:	4505                	li	a0,1
ffffffffc0200ec2:	64d000ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc0200ec6:	8aaa                	mv	s5,a0
ffffffffc0200ec8:	42050863          	beqz	a0,ffffffffc02012f8 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ecc:	4505                	li	a0,1
ffffffffc0200ece:	641000ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc0200ed2:	89aa                	mv	s3,a0
ffffffffc0200ed4:	70050263          	beqz	a0,ffffffffc02015d8 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ed8:	4505                	li	a0,1
ffffffffc0200eda:	635000ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc0200ede:	8a2a                	mv	s4,a0
ffffffffc0200ee0:	48050c63          	beqz	a0,ffffffffc0201378 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200ee4:	293a8a63          	beq	s5,s3,ffffffffc0201178 <default_check+0x302>
ffffffffc0200ee8:	28aa8863          	beq	s5,a0,ffffffffc0201178 <default_check+0x302>
ffffffffc0200eec:	28a98663          	beq	s3,a0,ffffffffc0201178 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200ef0:	000aa783          	lw	a5,0(s5)
ffffffffc0200ef4:	2a079263          	bnez	a5,ffffffffc0201198 <default_check+0x322>
ffffffffc0200ef8:	0009a783          	lw	a5,0(s3)
ffffffffc0200efc:	28079e63          	bnez	a5,ffffffffc0201198 <default_check+0x322>
ffffffffc0200f00:	411c                	lw	a5,0(a0)
ffffffffc0200f02:	28079b63          	bnez	a5,ffffffffc0201198 <default_check+0x322>
extern size_t npage;
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page) {
    return page - pages + nbase;
ffffffffc0200f06:	000b2797          	auipc	a5,0xb2
ffffffffc0200f0a:	b3a7b783          	ld	a5,-1222(a5) # ffffffffc02b2a40 <pages>
ffffffffc0200f0e:	40fa8733          	sub	a4,s5,a5
ffffffffc0200f12:	00008617          	auipc	a2,0x8
ffffffffc0200f16:	e2e63603          	ld	a2,-466(a2) # ffffffffc0208d40 <nbase>
ffffffffc0200f1a:	8719                	srai	a4,a4,0x6
ffffffffc0200f1c:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200f1e:	000b2697          	auipc	a3,0xb2
ffffffffc0200f22:	b1a6b683          	ld	a3,-1254(a3) # ffffffffc02b2a38 <npage>
ffffffffc0200f26:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f28:	0732                	slli	a4,a4,0xc
ffffffffc0200f2a:	28d77763          	bgeu	a4,a3,ffffffffc02011b8 <default_check+0x342>
    return page - pages + nbase;
ffffffffc0200f2e:	40f98733          	sub	a4,s3,a5
ffffffffc0200f32:	8719                	srai	a4,a4,0x6
ffffffffc0200f34:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f36:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200f38:	4cd77063          	bgeu	a4,a3,ffffffffc02013f8 <default_check+0x582>
    return page - pages + nbase;
ffffffffc0200f3c:	40f507b3          	sub	a5,a0,a5
ffffffffc0200f40:	8799                	srai	a5,a5,0x6
ffffffffc0200f42:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f44:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200f46:	30d7f963          	bgeu	a5,a3,ffffffffc0201258 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0200f4a:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f4c:	00043c03          	ld	s8,0(s0)
ffffffffc0200f50:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200f54:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200f58:	e400                	sd	s0,8(s0)
ffffffffc0200f5a:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200f5c:	000ae797          	auipc	a5,0xae
ffffffffc0200f60:	9e07aa23          	sw	zero,-1548(a5) # ffffffffc02ae950 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200f64:	5ab000ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc0200f68:	2c051863          	bnez	a0,ffffffffc0201238 <default_check+0x3c2>
    free_page(p0);
ffffffffc0200f6c:	4585                	li	a1,1
ffffffffc0200f6e:	8556                	mv	a0,s5
ffffffffc0200f70:	631000ef          	jal	ra,ffffffffc0201da0 <free_pages>
    free_page(p1);
ffffffffc0200f74:	4585                	li	a1,1
ffffffffc0200f76:	854e                	mv	a0,s3
ffffffffc0200f78:	629000ef          	jal	ra,ffffffffc0201da0 <free_pages>
    free_page(p2);
ffffffffc0200f7c:	4585                	li	a1,1
ffffffffc0200f7e:	8552                	mv	a0,s4
ffffffffc0200f80:	621000ef          	jal	ra,ffffffffc0201da0 <free_pages>
    assert(nr_free == 3);
ffffffffc0200f84:	4818                	lw	a4,16(s0)
ffffffffc0200f86:	478d                	li	a5,3
ffffffffc0200f88:	28f71863          	bne	a4,a5,ffffffffc0201218 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200f8c:	4505                	li	a0,1
ffffffffc0200f8e:	581000ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc0200f92:	89aa                	mv	s3,a0
ffffffffc0200f94:	26050263          	beqz	a0,ffffffffc02011f8 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200f98:	4505                	li	a0,1
ffffffffc0200f9a:	575000ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc0200f9e:	8aaa                	mv	s5,a0
ffffffffc0200fa0:	3a050c63          	beqz	a0,ffffffffc0201358 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200fa4:	4505                	li	a0,1
ffffffffc0200fa6:	569000ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc0200faa:	8a2a                	mv	s4,a0
ffffffffc0200fac:	38050663          	beqz	a0,ffffffffc0201338 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0200fb0:	4505                	li	a0,1
ffffffffc0200fb2:	55d000ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc0200fb6:	36051163          	bnez	a0,ffffffffc0201318 <default_check+0x4a2>
    free_page(p0);
ffffffffc0200fba:	4585                	li	a1,1
ffffffffc0200fbc:	854e                	mv	a0,s3
ffffffffc0200fbe:	5e3000ef          	jal	ra,ffffffffc0201da0 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200fc2:	641c                	ld	a5,8(s0)
ffffffffc0200fc4:	20878a63          	beq	a5,s0,ffffffffc02011d8 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0200fc8:	4505                	li	a0,1
ffffffffc0200fca:	545000ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc0200fce:	30a99563          	bne	s3,a0,ffffffffc02012d8 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0200fd2:	4505                	li	a0,1
ffffffffc0200fd4:	53b000ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc0200fd8:	2e051063          	bnez	a0,ffffffffc02012b8 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0200fdc:	481c                	lw	a5,16(s0)
ffffffffc0200fde:	2a079d63          	bnez	a5,ffffffffc0201298 <default_check+0x422>
    free_page(p);
ffffffffc0200fe2:	854e                	mv	a0,s3
ffffffffc0200fe4:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200fe6:	01843023          	sd	s8,0(s0)
ffffffffc0200fea:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200fee:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200ff2:	5af000ef          	jal	ra,ffffffffc0201da0 <free_pages>
    free_page(p1);
ffffffffc0200ff6:	4585                	li	a1,1
ffffffffc0200ff8:	8556                	mv	a0,s5
ffffffffc0200ffa:	5a7000ef          	jal	ra,ffffffffc0201da0 <free_pages>
    free_page(p2);
ffffffffc0200ffe:	4585                	li	a1,1
ffffffffc0201000:	8552                	mv	a0,s4
ffffffffc0201002:	59f000ef          	jal	ra,ffffffffc0201da0 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0201006:	4515                	li	a0,5
ffffffffc0201008:	507000ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc020100c:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc020100e:	26050563          	beqz	a0,ffffffffc0201278 <default_check+0x402>
ffffffffc0201012:	651c                	ld	a5,8(a0)
ffffffffc0201014:	8385                	srli	a5,a5,0x1
ffffffffc0201016:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc0201018:	54079063          	bnez	a5,ffffffffc0201558 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc020101c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020101e:	00043b03          	ld	s6,0(s0)
ffffffffc0201022:	00843a83          	ld	s5,8(s0)
ffffffffc0201026:	e000                	sd	s0,0(s0)
ffffffffc0201028:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc020102a:	4e5000ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc020102e:	50051563          	bnez	a0,ffffffffc0201538 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0201032:	08098a13          	addi	s4,s3,128
ffffffffc0201036:	8552                	mv	a0,s4
ffffffffc0201038:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc020103a:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc020103e:	000ae797          	auipc	a5,0xae
ffffffffc0201042:	9007a923          	sw	zero,-1774(a5) # ffffffffc02ae950 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0201046:	55b000ef          	jal	ra,ffffffffc0201da0 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc020104a:	4511                	li	a0,4
ffffffffc020104c:	4c3000ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc0201050:	4c051463          	bnez	a0,ffffffffc0201518 <default_check+0x6a2>
ffffffffc0201054:	0889b783          	ld	a5,136(s3)
ffffffffc0201058:	8385                	srli	a5,a5,0x1
ffffffffc020105a:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc020105c:	48078e63          	beqz	a5,ffffffffc02014f8 <default_check+0x682>
ffffffffc0201060:	0909a703          	lw	a4,144(s3)
ffffffffc0201064:	478d                	li	a5,3
ffffffffc0201066:	48f71963          	bne	a4,a5,ffffffffc02014f8 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020106a:	450d                	li	a0,3
ffffffffc020106c:	4a3000ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc0201070:	8c2a                	mv	s8,a0
ffffffffc0201072:	46050363          	beqz	a0,ffffffffc02014d8 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc0201076:	4505                	li	a0,1
ffffffffc0201078:	497000ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc020107c:	42051e63          	bnez	a0,ffffffffc02014b8 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0201080:	418a1c63          	bne	s4,s8,ffffffffc0201498 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0201084:	4585                	li	a1,1
ffffffffc0201086:	854e                	mv	a0,s3
ffffffffc0201088:	519000ef          	jal	ra,ffffffffc0201da0 <free_pages>
    free_pages(p1, 3);
ffffffffc020108c:	458d                	li	a1,3
ffffffffc020108e:	8552                	mv	a0,s4
ffffffffc0201090:	511000ef          	jal	ra,ffffffffc0201da0 <free_pages>
ffffffffc0201094:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0201098:	04098c13          	addi	s8,s3,64
ffffffffc020109c:	8385                	srli	a5,a5,0x1
ffffffffc020109e:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02010a0:	3c078c63          	beqz	a5,ffffffffc0201478 <default_check+0x602>
ffffffffc02010a4:	0109a703          	lw	a4,16(s3)
ffffffffc02010a8:	4785                	li	a5,1
ffffffffc02010aa:	3cf71763          	bne	a4,a5,ffffffffc0201478 <default_check+0x602>
ffffffffc02010ae:	008a3783          	ld	a5,8(s4)
ffffffffc02010b2:	8385                	srli	a5,a5,0x1
ffffffffc02010b4:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02010b6:	3a078163          	beqz	a5,ffffffffc0201458 <default_check+0x5e2>
ffffffffc02010ba:	010a2703          	lw	a4,16(s4)
ffffffffc02010be:	478d                	li	a5,3
ffffffffc02010c0:	38f71c63          	bne	a4,a5,ffffffffc0201458 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02010c4:	4505                	li	a0,1
ffffffffc02010c6:	449000ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc02010ca:	36a99763          	bne	s3,a0,ffffffffc0201438 <default_check+0x5c2>
    free_page(p0);
ffffffffc02010ce:	4585                	li	a1,1
ffffffffc02010d0:	4d1000ef          	jal	ra,ffffffffc0201da0 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02010d4:	4509                	li	a0,2
ffffffffc02010d6:	439000ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc02010da:	32aa1f63          	bne	s4,a0,ffffffffc0201418 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc02010de:	4589                	li	a1,2
ffffffffc02010e0:	4c1000ef          	jal	ra,ffffffffc0201da0 <free_pages>
    free_page(p2);
ffffffffc02010e4:	4585                	li	a1,1
ffffffffc02010e6:	8562                	mv	a0,s8
ffffffffc02010e8:	4b9000ef          	jal	ra,ffffffffc0201da0 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02010ec:	4515                	li	a0,5
ffffffffc02010ee:	421000ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc02010f2:	89aa                	mv	s3,a0
ffffffffc02010f4:	48050263          	beqz	a0,ffffffffc0201578 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc02010f8:	4505                	li	a0,1
ffffffffc02010fa:	415000ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc02010fe:	2c051d63          	bnez	a0,ffffffffc02013d8 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc0201102:	481c                	lw	a5,16(s0)
ffffffffc0201104:	2a079a63          	bnez	a5,ffffffffc02013b8 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201108:	4595                	li	a1,5
ffffffffc020110a:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc020110c:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0201110:	01643023          	sd	s6,0(s0)
ffffffffc0201114:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0201118:	489000ef          	jal	ra,ffffffffc0201da0 <free_pages>
    return listelm->next;
ffffffffc020111c:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020111e:	00878963          	beq	a5,s0,ffffffffc0201130 <default_check+0x2ba>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0201122:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201126:	679c                	ld	a5,8(a5)
ffffffffc0201128:	397d                	addiw	s2,s2,-1
ffffffffc020112a:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc020112c:	fe879be3          	bne	a5,s0,ffffffffc0201122 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc0201130:	26091463          	bnez	s2,ffffffffc0201398 <default_check+0x522>
    assert(total == 0);
ffffffffc0201134:	46049263          	bnez	s1,ffffffffc0201598 <default_check+0x722>
}
ffffffffc0201138:	60a6                	ld	ra,72(sp)
ffffffffc020113a:	6406                	ld	s0,64(sp)
ffffffffc020113c:	74e2                	ld	s1,56(sp)
ffffffffc020113e:	7942                	ld	s2,48(sp)
ffffffffc0201140:	79a2                	ld	s3,40(sp)
ffffffffc0201142:	7a02                	ld	s4,32(sp)
ffffffffc0201144:	6ae2                	ld	s5,24(sp)
ffffffffc0201146:	6b42                	ld	s6,16(sp)
ffffffffc0201148:	6ba2                	ld	s7,8(sp)
ffffffffc020114a:	6c02                	ld	s8,0(sp)
ffffffffc020114c:	6161                	addi	sp,sp,80
ffffffffc020114e:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201150:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0201152:	4481                	li	s1,0
ffffffffc0201154:	4901                	li	s2,0
ffffffffc0201156:	b38d                	j	ffffffffc0200eb8 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0201158:	00006697          	auipc	a3,0x6
ffffffffc020115c:	eb868693          	addi	a3,a3,-328 # ffffffffc0207010 <commands+0x7a0>
ffffffffc0201160:	00006617          	auipc	a2,0x6
ffffffffc0201164:	b6060613          	addi	a2,a2,-1184 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0201168:	0f000593          	li	a1,240
ffffffffc020116c:	00006517          	auipc	a0,0x6
ffffffffc0201170:	eb450513          	addi	a0,a0,-332 # ffffffffc0207020 <commands+0x7b0>
ffffffffc0201174:	b06ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201178:	00006697          	auipc	a3,0x6
ffffffffc020117c:	f4068693          	addi	a3,a3,-192 # ffffffffc02070b8 <commands+0x848>
ffffffffc0201180:	00006617          	auipc	a2,0x6
ffffffffc0201184:	b4060613          	addi	a2,a2,-1216 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0201188:	0bd00593          	li	a1,189
ffffffffc020118c:	00006517          	auipc	a0,0x6
ffffffffc0201190:	e9450513          	addi	a0,a0,-364 # ffffffffc0207020 <commands+0x7b0>
ffffffffc0201194:	ae6ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201198:	00006697          	auipc	a3,0x6
ffffffffc020119c:	f4868693          	addi	a3,a3,-184 # ffffffffc02070e0 <commands+0x870>
ffffffffc02011a0:	00006617          	auipc	a2,0x6
ffffffffc02011a4:	b2060613          	addi	a2,a2,-1248 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02011a8:	0be00593          	li	a1,190
ffffffffc02011ac:	00006517          	auipc	a0,0x6
ffffffffc02011b0:	e7450513          	addi	a0,a0,-396 # ffffffffc0207020 <commands+0x7b0>
ffffffffc02011b4:	ac6ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02011b8:	00006697          	auipc	a3,0x6
ffffffffc02011bc:	f6868693          	addi	a3,a3,-152 # ffffffffc0207120 <commands+0x8b0>
ffffffffc02011c0:	00006617          	auipc	a2,0x6
ffffffffc02011c4:	b0060613          	addi	a2,a2,-1280 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02011c8:	0c000593          	li	a1,192
ffffffffc02011cc:	00006517          	auipc	a0,0x6
ffffffffc02011d0:	e5450513          	addi	a0,a0,-428 # ffffffffc0207020 <commands+0x7b0>
ffffffffc02011d4:	aa6ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(!list_empty(&free_list));
ffffffffc02011d8:	00006697          	auipc	a3,0x6
ffffffffc02011dc:	fd068693          	addi	a3,a3,-48 # ffffffffc02071a8 <commands+0x938>
ffffffffc02011e0:	00006617          	auipc	a2,0x6
ffffffffc02011e4:	ae060613          	addi	a2,a2,-1312 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02011e8:	0d900593          	li	a1,217
ffffffffc02011ec:	00006517          	auipc	a0,0x6
ffffffffc02011f0:	e3450513          	addi	a0,a0,-460 # ffffffffc0207020 <commands+0x7b0>
ffffffffc02011f4:	a86ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02011f8:	00006697          	auipc	a3,0x6
ffffffffc02011fc:	e6068693          	addi	a3,a3,-416 # ffffffffc0207058 <commands+0x7e8>
ffffffffc0201200:	00006617          	auipc	a2,0x6
ffffffffc0201204:	ac060613          	addi	a2,a2,-1344 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0201208:	0d200593          	li	a1,210
ffffffffc020120c:	00006517          	auipc	a0,0x6
ffffffffc0201210:	e1450513          	addi	a0,a0,-492 # ffffffffc0207020 <commands+0x7b0>
ffffffffc0201214:	a66ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(nr_free == 3);
ffffffffc0201218:	00006697          	auipc	a3,0x6
ffffffffc020121c:	f8068693          	addi	a3,a3,-128 # ffffffffc0207198 <commands+0x928>
ffffffffc0201220:	00006617          	auipc	a2,0x6
ffffffffc0201224:	aa060613          	addi	a2,a2,-1376 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0201228:	0d000593          	li	a1,208
ffffffffc020122c:	00006517          	auipc	a0,0x6
ffffffffc0201230:	df450513          	addi	a0,a0,-524 # ffffffffc0207020 <commands+0x7b0>
ffffffffc0201234:	a46ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201238:	00006697          	auipc	a3,0x6
ffffffffc020123c:	f4868693          	addi	a3,a3,-184 # ffffffffc0207180 <commands+0x910>
ffffffffc0201240:	00006617          	auipc	a2,0x6
ffffffffc0201244:	a8060613          	addi	a2,a2,-1408 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0201248:	0cb00593          	li	a1,203
ffffffffc020124c:	00006517          	auipc	a0,0x6
ffffffffc0201250:	dd450513          	addi	a0,a0,-556 # ffffffffc0207020 <commands+0x7b0>
ffffffffc0201254:	a26ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201258:	00006697          	auipc	a3,0x6
ffffffffc020125c:	f0868693          	addi	a3,a3,-248 # ffffffffc0207160 <commands+0x8f0>
ffffffffc0201260:	00006617          	auipc	a2,0x6
ffffffffc0201264:	a6060613          	addi	a2,a2,-1440 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0201268:	0c200593          	li	a1,194
ffffffffc020126c:	00006517          	auipc	a0,0x6
ffffffffc0201270:	db450513          	addi	a0,a0,-588 # ffffffffc0207020 <commands+0x7b0>
ffffffffc0201274:	a06ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(p0 != NULL);
ffffffffc0201278:	00006697          	auipc	a3,0x6
ffffffffc020127c:	f7868693          	addi	a3,a3,-136 # ffffffffc02071f0 <commands+0x980>
ffffffffc0201280:	00006617          	auipc	a2,0x6
ffffffffc0201284:	a4060613          	addi	a2,a2,-1472 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0201288:	0f800593          	li	a1,248
ffffffffc020128c:	00006517          	auipc	a0,0x6
ffffffffc0201290:	d9450513          	addi	a0,a0,-620 # ffffffffc0207020 <commands+0x7b0>
ffffffffc0201294:	9e6ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(nr_free == 0);
ffffffffc0201298:	00006697          	auipc	a3,0x6
ffffffffc020129c:	f4868693          	addi	a3,a3,-184 # ffffffffc02071e0 <commands+0x970>
ffffffffc02012a0:	00006617          	auipc	a2,0x6
ffffffffc02012a4:	a2060613          	addi	a2,a2,-1504 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02012a8:	0df00593          	li	a1,223
ffffffffc02012ac:	00006517          	auipc	a0,0x6
ffffffffc02012b0:	d7450513          	addi	a0,a0,-652 # ffffffffc0207020 <commands+0x7b0>
ffffffffc02012b4:	9c6ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012b8:	00006697          	auipc	a3,0x6
ffffffffc02012bc:	ec868693          	addi	a3,a3,-312 # ffffffffc0207180 <commands+0x910>
ffffffffc02012c0:	00006617          	auipc	a2,0x6
ffffffffc02012c4:	a0060613          	addi	a2,a2,-1536 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02012c8:	0dd00593          	li	a1,221
ffffffffc02012cc:	00006517          	auipc	a0,0x6
ffffffffc02012d0:	d5450513          	addi	a0,a0,-684 # ffffffffc0207020 <commands+0x7b0>
ffffffffc02012d4:	9a6ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02012d8:	00006697          	auipc	a3,0x6
ffffffffc02012dc:	ee868693          	addi	a3,a3,-280 # ffffffffc02071c0 <commands+0x950>
ffffffffc02012e0:	00006617          	auipc	a2,0x6
ffffffffc02012e4:	9e060613          	addi	a2,a2,-1568 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02012e8:	0dc00593          	li	a1,220
ffffffffc02012ec:	00006517          	auipc	a0,0x6
ffffffffc02012f0:	d3450513          	addi	a0,a0,-716 # ffffffffc0207020 <commands+0x7b0>
ffffffffc02012f4:	986ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02012f8:	00006697          	auipc	a3,0x6
ffffffffc02012fc:	d6068693          	addi	a3,a3,-672 # ffffffffc0207058 <commands+0x7e8>
ffffffffc0201300:	00006617          	auipc	a2,0x6
ffffffffc0201304:	9c060613          	addi	a2,a2,-1600 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0201308:	0b900593          	li	a1,185
ffffffffc020130c:	00006517          	auipc	a0,0x6
ffffffffc0201310:	d1450513          	addi	a0,a0,-748 # ffffffffc0207020 <commands+0x7b0>
ffffffffc0201314:	966ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201318:	00006697          	auipc	a3,0x6
ffffffffc020131c:	e6868693          	addi	a3,a3,-408 # ffffffffc0207180 <commands+0x910>
ffffffffc0201320:	00006617          	auipc	a2,0x6
ffffffffc0201324:	9a060613          	addi	a2,a2,-1632 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0201328:	0d600593          	li	a1,214
ffffffffc020132c:	00006517          	auipc	a0,0x6
ffffffffc0201330:	cf450513          	addi	a0,a0,-780 # ffffffffc0207020 <commands+0x7b0>
ffffffffc0201334:	946ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201338:	00006697          	auipc	a3,0x6
ffffffffc020133c:	d6068693          	addi	a3,a3,-672 # ffffffffc0207098 <commands+0x828>
ffffffffc0201340:	00006617          	auipc	a2,0x6
ffffffffc0201344:	98060613          	addi	a2,a2,-1664 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0201348:	0d400593          	li	a1,212
ffffffffc020134c:	00006517          	auipc	a0,0x6
ffffffffc0201350:	cd450513          	addi	a0,a0,-812 # ffffffffc0207020 <commands+0x7b0>
ffffffffc0201354:	926ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201358:	00006697          	auipc	a3,0x6
ffffffffc020135c:	d2068693          	addi	a3,a3,-736 # ffffffffc0207078 <commands+0x808>
ffffffffc0201360:	00006617          	auipc	a2,0x6
ffffffffc0201364:	96060613          	addi	a2,a2,-1696 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0201368:	0d300593          	li	a1,211
ffffffffc020136c:	00006517          	auipc	a0,0x6
ffffffffc0201370:	cb450513          	addi	a0,a0,-844 # ffffffffc0207020 <commands+0x7b0>
ffffffffc0201374:	906ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201378:	00006697          	auipc	a3,0x6
ffffffffc020137c:	d2068693          	addi	a3,a3,-736 # ffffffffc0207098 <commands+0x828>
ffffffffc0201380:	00006617          	auipc	a2,0x6
ffffffffc0201384:	94060613          	addi	a2,a2,-1728 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0201388:	0bb00593          	li	a1,187
ffffffffc020138c:	00006517          	auipc	a0,0x6
ffffffffc0201390:	c9450513          	addi	a0,a0,-876 # ffffffffc0207020 <commands+0x7b0>
ffffffffc0201394:	8e6ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(count == 0);
ffffffffc0201398:	00006697          	auipc	a3,0x6
ffffffffc020139c:	fa868693          	addi	a3,a3,-88 # ffffffffc0207340 <commands+0xad0>
ffffffffc02013a0:	00006617          	auipc	a2,0x6
ffffffffc02013a4:	92060613          	addi	a2,a2,-1760 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02013a8:	12500593          	li	a1,293
ffffffffc02013ac:	00006517          	auipc	a0,0x6
ffffffffc02013b0:	c7450513          	addi	a0,a0,-908 # ffffffffc0207020 <commands+0x7b0>
ffffffffc02013b4:	8c6ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(nr_free == 0);
ffffffffc02013b8:	00006697          	auipc	a3,0x6
ffffffffc02013bc:	e2868693          	addi	a3,a3,-472 # ffffffffc02071e0 <commands+0x970>
ffffffffc02013c0:	00006617          	auipc	a2,0x6
ffffffffc02013c4:	90060613          	addi	a2,a2,-1792 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02013c8:	11a00593          	li	a1,282
ffffffffc02013cc:	00006517          	auipc	a0,0x6
ffffffffc02013d0:	c5450513          	addi	a0,a0,-940 # ffffffffc0207020 <commands+0x7b0>
ffffffffc02013d4:	8a6ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013d8:	00006697          	auipc	a3,0x6
ffffffffc02013dc:	da868693          	addi	a3,a3,-600 # ffffffffc0207180 <commands+0x910>
ffffffffc02013e0:	00006617          	auipc	a2,0x6
ffffffffc02013e4:	8e060613          	addi	a2,a2,-1824 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02013e8:	11800593          	li	a1,280
ffffffffc02013ec:	00006517          	auipc	a0,0x6
ffffffffc02013f0:	c3450513          	addi	a0,a0,-972 # ffffffffc0207020 <commands+0x7b0>
ffffffffc02013f4:	886ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02013f8:	00006697          	auipc	a3,0x6
ffffffffc02013fc:	d4868693          	addi	a3,a3,-696 # ffffffffc0207140 <commands+0x8d0>
ffffffffc0201400:	00006617          	auipc	a2,0x6
ffffffffc0201404:	8c060613          	addi	a2,a2,-1856 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0201408:	0c100593          	li	a1,193
ffffffffc020140c:	00006517          	auipc	a0,0x6
ffffffffc0201410:	c1450513          	addi	a0,a0,-1004 # ffffffffc0207020 <commands+0x7b0>
ffffffffc0201414:	866ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201418:	00006697          	auipc	a3,0x6
ffffffffc020141c:	ee868693          	addi	a3,a3,-280 # ffffffffc0207300 <commands+0xa90>
ffffffffc0201420:	00006617          	auipc	a2,0x6
ffffffffc0201424:	8a060613          	addi	a2,a2,-1888 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0201428:	11200593          	li	a1,274
ffffffffc020142c:	00006517          	auipc	a0,0x6
ffffffffc0201430:	bf450513          	addi	a0,a0,-1036 # ffffffffc0207020 <commands+0x7b0>
ffffffffc0201434:	846ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201438:	00006697          	auipc	a3,0x6
ffffffffc020143c:	ea868693          	addi	a3,a3,-344 # ffffffffc02072e0 <commands+0xa70>
ffffffffc0201440:	00006617          	auipc	a2,0x6
ffffffffc0201444:	88060613          	addi	a2,a2,-1920 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0201448:	11000593          	li	a1,272
ffffffffc020144c:	00006517          	auipc	a0,0x6
ffffffffc0201450:	bd450513          	addi	a0,a0,-1068 # ffffffffc0207020 <commands+0x7b0>
ffffffffc0201454:	826ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201458:	00006697          	auipc	a3,0x6
ffffffffc020145c:	e6068693          	addi	a3,a3,-416 # ffffffffc02072b8 <commands+0xa48>
ffffffffc0201460:	00006617          	auipc	a2,0x6
ffffffffc0201464:	86060613          	addi	a2,a2,-1952 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0201468:	10e00593          	li	a1,270
ffffffffc020146c:	00006517          	auipc	a0,0x6
ffffffffc0201470:	bb450513          	addi	a0,a0,-1100 # ffffffffc0207020 <commands+0x7b0>
ffffffffc0201474:	806ff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201478:	00006697          	auipc	a3,0x6
ffffffffc020147c:	e1868693          	addi	a3,a3,-488 # ffffffffc0207290 <commands+0xa20>
ffffffffc0201480:	00006617          	auipc	a2,0x6
ffffffffc0201484:	84060613          	addi	a2,a2,-1984 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0201488:	10d00593          	li	a1,269
ffffffffc020148c:	00006517          	auipc	a0,0x6
ffffffffc0201490:	b9450513          	addi	a0,a0,-1132 # ffffffffc0207020 <commands+0x7b0>
ffffffffc0201494:	fe7fe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201498:	00006697          	auipc	a3,0x6
ffffffffc020149c:	de868693          	addi	a3,a3,-536 # ffffffffc0207280 <commands+0xa10>
ffffffffc02014a0:	00006617          	auipc	a2,0x6
ffffffffc02014a4:	82060613          	addi	a2,a2,-2016 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02014a8:	10800593          	li	a1,264
ffffffffc02014ac:	00006517          	auipc	a0,0x6
ffffffffc02014b0:	b7450513          	addi	a0,a0,-1164 # ffffffffc0207020 <commands+0x7b0>
ffffffffc02014b4:	fc7fe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014b8:	00006697          	auipc	a3,0x6
ffffffffc02014bc:	cc868693          	addi	a3,a3,-824 # ffffffffc0207180 <commands+0x910>
ffffffffc02014c0:	00006617          	auipc	a2,0x6
ffffffffc02014c4:	80060613          	addi	a2,a2,-2048 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02014c8:	10700593          	li	a1,263
ffffffffc02014cc:	00006517          	auipc	a0,0x6
ffffffffc02014d0:	b5450513          	addi	a0,a0,-1196 # ffffffffc0207020 <commands+0x7b0>
ffffffffc02014d4:	fa7fe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02014d8:	00006697          	auipc	a3,0x6
ffffffffc02014dc:	d8868693          	addi	a3,a3,-632 # ffffffffc0207260 <commands+0x9f0>
ffffffffc02014e0:	00005617          	auipc	a2,0x5
ffffffffc02014e4:	7e060613          	addi	a2,a2,2016 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02014e8:	10600593          	li	a1,262
ffffffffc02014ec:	00006517          	auipc	a0,0x6
ffffffffc02014f0:	b3450513          	addi	a0,a0,-1228 # ffffffffc0207020 <commands+0x7b0>
ffffffffc02014f4:	f87fe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02014f8:	00006697          	auipc	a3,0x6
ffffffffc02014fc:	d3868693          	addi	a3,a3,-712 # ffffffffc0207230 <commands+0x9c0>
ffffffffc0201500:	00005617          	auipc	a2,0x5
ffffffffc0201504:	7c060613          	addi	a2,a2,1984 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0201508:	10500593          	li	a1,261
ffffffffc020150c:	00006517          	auipc	a0,0x6
ffffffffc0201510:	b1450513          	addi	a0,a0,-1260 # ffffffffc0207020 <commands+0x7b0>
ffffffffc0201514:	f67fe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201518:	00006697          	auipc	a3,0x6
ffffffffc020151c:	d0068693          	addi	a3,a3,-768 # ffffffffc0207218 <commands+0x9a8>
ffffffffc0201520:	00005617          	auipc	a2,0x5
ffffffffc0201524:	7a060613          	addi	a2,a2,1952 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0201528:	10400593          	li	a1,260
ffffffffc020152c:	00006517          	auipc	a0,0x6
ffffffffc0201530:	af450513          	addi	a0,a0,-1292 # ffffffffc0207020 <commands+0x7b0>
ffffffffc0201534:	f47fe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201538:	00006697          	auipc	a3,0x6
ffffffffc020153c:	c4868693          	addi	a3,a3,-952 # ffffffffc0207180 <commands+0x910>
ffffffffc0201540:	00005617          	auipc	a2,0x5
ffffffffc0201544:	78060613          	addi	a2,a2,1920 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0201548:	0fe00593          	li	a1,254
ffffffffc020154c:	00006517          	auipc	a0,0x6
ffffffffc0201550:	ad450513          	addi	a0,a0,-1324 # ffffffffc0207020 <commands+0x7b0>
ffffffffc0201554:	f27fe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(!PageProperty(p0));
ffffffffc0201558:	00006697          	auipc	a3,0x6
ffffffffc020155c:	ca868693          	addi	a3,a3,-856 # ffffffffc0207200 <commands+0x990>
ffffffffc0201560:	00005617          	auipc	a2,0x5
ffffffffc0201564:	76060613          	addi	a2,a2,1888 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0201568:	0f900593          	li	a1,249
ffffffffc020156c:	00006517          	auipc	a0,0x6
ffffffffc0201570:	ab450513          	addi	a0,a0,-1356 # ffffffffc0207020 <commands+0x7b0>
ffffffffc0201574:	f07fe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201578:	00006697          	auipc	a3,0x6
ffffffffc020157c:	da868693          	addi	a3,a3,-600 # ffffffffc0207320 <commands+0xab0>
ffffffffc0201580:	00005617          	auipc	a2,0x5
ffffffffc0201584:	74060613          	addi	a2,a2,1856 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0201588:	11700593          	li	a1,279
ffffffffc020158c:	00006517          	auipc	a0,0x6
ffffffffc0201590:	a9450513          	addi	a0,a0,-1388 # ffffffffc0207020 <commands+0x7b0>
ffffffffc0201594:	ee7fe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(total == 0);
ffffffffc0201598:	00006697          	auipc	a3,0x6
ffffffffc020159c:	db868693          	addi	a3,a3,-584 # ffffffffc0207350 <commands+0xae0>
ffffffffc02015a0:	00005617          	auipc	a2,0x5
ffffffffc02015a4:	72060613          	addi	a2,a2,1824 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02015a8:	12600593          	li	a1,294
ffffffffc02015ac:	00006517          	auipc	a0,0x6
ffffffffc02015b0:	a7450513          	addi	a0,a0,-1420 # ffffffffc0207020 <commands+0x7b0>
ffffffffc02015b4:	ec7fe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(total == nr_free_pages());
ffffffffc02015b8:	00006697          	auipc	a3,0x6
ffffffffc02015bc:	a8068693          	addi	a3,a3,-1408 # ffffffffc0207038 <commands+0x7c8>
ffffffffc02015c0:	00005617          	auipc	a2,0x5
ffffffffc02015c4:	70060613          	addi	a2,a2,1792 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02015c8:	0f300593          	li	a1,243
ffffffffc02015cc:	00006517          	auipc	a0,0x6
ffffffffc02015d0:	a5450513          	addi	a0,a0,-1452 # ffffffffc0207020 <commands+0x7b0>
ffffffffc02015d4:	ea7fe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02015d8:	00006697          	auipc	a3,0x6
ffffffffc02015dc:	aa068693          	addi	a3,a3,-1376 # ffffffffc0207078 <commands+0x808>
ffffffffc02015e0:	00005617          	auipc	a2,0x5
ffffffffc02015e4:	6e060613          	addi	a2,a2,1760 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02015e8:	0ba00593          	li	a1,186
ffffffffc02015ec:	00006517          	auipc	a0,0x6
ffffffffc02015f0:	a3450513          	addi	a0,a0,-1484 # ffffffffc0207020 <commands+0x7b0>
ffffffffc02015f4:	e87fe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02015f8 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc02015f8:	1141                	addi	sp,sp,-16
ffffffffc02015fa:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02015fc:	12058f63          	beqz	a1,ffffffffc020173a <default_free_pages+0x142>
    for (; p != base + n; p ++) {
ffffffffc0201600:	00659693          	slli	a3,a1,0x6
ffffffffc0201604:	96aa                	add	a3,a3,a0
ffffffffc0201606:	87aa                	mv	a5,a0
ffffffffc0201608:	02d50263          	beq	a0,a3,ffffffffc020162c <default_free_pages+0x34>
ffffffffc020160c:	6798                	ld	a4,8(a5)
ffffffffc020160e:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201610:	10071563          	bnez	a4,ffffffffc020171a <default_free_pages+0x122>
ffffffffc0201614:	6798                	ld	a4,8(a5)
ffffffffc0201616:	8b09                	andi	a4,a4,2
ffffffffc0201618:	10071163          	bnez	a4,ffffffffc020171a <default_free_pages+0x122>
        p->flags = 0;
ffffffffc020161c:	0007b423          	sd	zero,8(a5)
    return page->ref;
}

static inline void
set_page_ref(struct Page *page, int val) {
    page->ref = val;
ffffffffc0201620:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201624:	04078793          	addi	a5,a5,64
ffffffffc0201628:	fed792e3          	bne	a5,a3,ffffffffc020160c <default_free_pages+0x14>
    base->property = n;
ffffffffc020162c:	2581                	sext.w	a1,a1
ffffffffc020162e:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201630:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201634:	4789                	li	a5,2
ffffffffc0201636:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020163a:	000ad697          	auipc	a3,0xad
ffffffffc020163e:	30668693          	addi	a3,a3,774 # ffffffffc02ae940 <free_area>
ffffffffc0201642:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201644:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201646:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc020164a:	9db9                	addw	a1,a1,a4
ffffffffc020164c:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020164e:	08d78f63          	beq	a5,a3,ffffffffc02016ec <default_free_pages+0xf4>
            struct Page* page = le2page(le, page_link);
ffffffffc0201652:	fe878713          	addi	a4,a5,-24
ffffffffc0201656:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc020165a:	4581                	li	a1,0
            if (base < page) {
ffffffffc020165c:	00e56a63          	bltu	a0,a4,ffffffffc0201670 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201660:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201662:	04d70a63          	beq	a4,a3,ffffffffc02016b6 <default_free_pages+0xbe>
    for (; p != base + n; p ++) {
ffffffffc0201666:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201668:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020166c:	fee57ae3          	bgeu	a0,a4,ffffffffc0201660 <default_free_pages+0x68>
ffffffffc0201670:	c199                	beqz	a1,ffffffffc0201676 <default_free_pages+0x7e>
ffffffffc0201672:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201676:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201678:	e390                	sd	a2,0(a5)
ffffffffc020167a:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020167c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020167e:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0201680:	00d70c63          	beq	a4,a3,ffffffffc0201698 <default_free_pages+0xa0>
        if (p + p->property == base) {
ffffffffc0201684:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201688:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base) {
ffffffffc020168c:	02059793          	slli	a5,a1,0x20
ffffffffc0201690:	83e9                	srli	a5,a5,0x1a
ffffffffc0201692:	97b2                	add	a5,a5,a2
ffffffffc0201694:	02f50b63          	beq	a0,a5,ffffffffc02016ca <default_free_pages+0xd2>
    return listelm->next;
ffffffffc0201698:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc020169a:	00d70b63          	beq	a4,a3,ffffffffc02016b0 <default_free_pages+0xb8>
        if (base + base->property == p) {
ffffffffc020169e:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc02016a0:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc02016a4:	02061793          	slli	a5,a2,0x20
ffffffffc02016a8:	83e9                	srli	a5,a5,0x1a
ffffffffc02016aa:	97aa                	add	a5,a5,a0
ffffffffc02016ac:	04f68763          	beq	a3,a5,ffffffffc02016fa <default_free_pages+0x102>
}
ffffffffc02016b0:	60a2                	ld	ra,8(sp)
ffffffffc02016b2:	0141                	addi	sp,sp,16
ffffffffc02016b4:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02016b6:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02016b8:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02016ba:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02016bc:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02016be:	02d70463          	beq	a4,a3,ffffffffc02016e6 <default_free_pages+0xee>
    prev->next = next->prev = elm;
ffffffffc02016c2:	8832                	mv	a6,a2
ffffffffc02016c4:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02016c6:	87ba                	mv	a5,a4
ffffffffc02016c8:	b745                	j	ffffffffc0201668 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc02016ca:	491c                	lw	a5,16(a0)
ffffffffc02016cc:	9dbd                	addw	a1,a1,a5
ffffffffc02016ce:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02016d2:	57f5                	li	a5,-3
ffffffffc02016d4:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02016d8:	6d0c                	ld	a1,24(a0)
ffffffffc02016da:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc02016dc:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02016de:	e59c                	sd	a5,8(a1)
    return listelm->next;
ffffffffc02016e0:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc02016e2:	e38c                	sd	a1,0(a5)
ffffffffc02016e4:	bf5d                	j	ffffffffc020169a <default_free_pages+0xa2>
ffffffffc02016e6:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02016e8:	873e                	mv	a4,a5
ffffffffc02016ea:	bf69                	j	ffffffffc0201684 <default_free_pages+0x8c>
}
ffffffffc02016ec:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02016ee:	e390                	sd	a2,0(a5)
ffffffffc02016f0:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02016f2:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02016f4:	ed1c                	sd	a5,24(a0)
ffffffffc02016f6:	0141                	addi	sp,sp,16
ffffffffc02016f8:	8082                	ret
            base->property += p->property;
ffffffffc02016fa:	ff872783          	lw	a5,-8(a4)
ffffffffc02016fe:	ff070693          	addi	a3,a4,-16
ffffffffc0201702:	9e3d                	addw	a2,a2,a5
ffffffffc0201704:	c910                	sw	a2,16(a0)
ffffffffc0201706:	57f5                	li	a5,-3
ffffffffc0201708:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020170c:	6314                	ld	a3,0(a4)
ffffffffc020170e:	671c                	ld	a5,8(a4)
}
ffffffffc0201710:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201712:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc0201714:	e394                	sd	a3,0(a5)
ffffffffc0201716:	0141                	addi	sp,sp,16
ffffffffc0201718:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020171a:	00006697          	auipc	a3,0x6
ffffffffc020171e:	c4e68693          	addi	a3,a3,-946 # ffffffffc0207368 <commands+0xaf8>
ffffffffc0201722:	00005617          	auipc	a2,0x5
ffffffffc0201726:	59e60613          	addi	a2,a2,1438 # ffffffffc0206cc0 <commands+0x450>
ffffffffc020172a:	08300593          	li	a1,131
ffffffffc020172e:	00006517          	auipc	a0,0x6
ffffffffc0201732:	8f250513          	addi	a0,a0,-1806 # ffffffffc0207020 <commands+0x7b0>
ffffffffc0201736:	d45fe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(n > 0);
ffffffffc020173a:	00006697          	auipc	a3,0x6
ffffffffc020173e:	c2668693          	addi	a3,a3,-986 # ffffffffc0207360 <commands+0xaf0>
ffffffffc0201742:	00005617          	auipc	a2,0x5
ffffffffc0201746:	57e60613          	addi	a2,a2,1406 # ffffffffc0206cc0 <commands+0x450>
ffffffffc020174a:	08000593          	li	a1,128
ffffffffc020174e:	00006517          	auipc	a0,0x6
ffffffffc0201752:	8d250513          	addi	a0,a0,-1838 # ffffffffc0207020 <commands+0x7b0>
ffffffffc0201756:	d25fe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc020175a <default_alloc_pages>:
    assert(n > 0);
ffffffffc020175a:	c941                	beqz	a0,ffffffffc02017ea <default_alloc_pages+0x90>
    if (n > nr_free) {
ffffffffc020175c:	000ad597          	auipc	a1,0xad
ffffffffc0201760:	1e458593          	addi	a1,a1,484 # ffffffffc02ae940 <free_area>
ffffffffc0201764:	0105a803          	lw	a6,16(a1)
ffffffffc0201768:	872a                	mv	a4,a0
ffffffffc020176a:	02081793          	slli	a5,a6,0x20
ffffffffc020176e:	9381                	srli	a5,a5,0x20
ffffffffc0201770:	00a7ee63          	bltu	a5,a0,ffffffffc020178c <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0201774:	87ae                	mv	a5,a1
ffffffffc0201776:	a801                	j	ffffffffc0201786 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc0201778:	ff87a683          	lw	a3,-8(a5)
ffffffffc020177c:	02069613          	slli	a2,a3,0x20
ffffffffc0201780:	9201                	srli	a2,a2,0x20
ffffffffc0201782:	00e67763          	bgeu	a2,a4,ffffffffc0201790 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201786:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201788:	feb798e3          	bne	a5,a1,ffffffffc0201778 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc020178c:	4501                	li	a0,0
}
ffffffffc020178e:	8082                	ret
    return listelm->prev;
ffffffffc0201790:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201794:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201798:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc020179c:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc02017a0:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc02017a4:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc02017a8:	02c77863          	bgeu	a4,a2,ffffffffc02017d8 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc02017ac:	071a                	slli	a4,a4,0x6
ffffffffc02017ae:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc02017b0:	41c686bb          	subw	a3,a3,t3
ffffffffc02017b4:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02017b6:	00870613          	addi	a2,a4,8
ffffffffc02017ba:	4689                	li	a3,2
ffffffffc02017bc:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc02017c0:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc02017c4:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc02017c8:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc02017cc:	e290                	sd	a2,0(a3)
ffffffffc02017ce:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc02017d2:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc02017d4:	01173c23          	sd	a7,24(a4)
ffffffffc02017d8:	41c8083b          	subw	a6,a6,t3
ffffffffc02017dc:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02017e0:	5775                	li	a4,-3
ffffffffc02017e2:	17c1                	addi	a5,a5,-16
ffffffffc02017e4:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc02017e8:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc02017ea:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02017ec:	00006697          	auipc	a3,0x6
ffffffffc02017f0:	b7468693          	addi	a3,a3,-1164 # ffffffffc0207360 <commands+0xaf0>
ffffffffc02017f4:	00005617          	auipc	a2,0x5
ffffffffc02017f8:	4cc60613          	addi	a2,a2,1228 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02017fc:	06200593          	li	a1,98
ffffffffc0201800:	00006517          	auipc	a0,0x6
ffffffffc0201804:	82050513          	addi	a0,a0,-2016 # ffffffffc0207020 <commands+0x7b0>
default_alloc_pages(size_t n) {
ffffffffc0201808:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020180a:	c71fe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc020180e <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc020180e:	1141                	addi	sp,sp,-16
ffffffffc0201810:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201812:	c5f1                	beqz	a1,ffffffffc02018de <default_init_memmap+0xd0>
    for (; p != base + n; p ++) {
ffffffffc0201814:	00659693          	slli	a3,a1,0x6
ffffffffc0201818:	96aa                	add	a3,a3,a0
ffffffffc020181a:	87aa                	mv	a5,a0
ffffffffc020181c:	00d50f63          	beq	a0,a3,ffffffffc020183a <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201820:	6798                	ld	a4,8(a5)
ffffffffc0201822:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc0201824:	cf49                	beqz	a4,ffffffffc02018be <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc0201826:	0007a823          	sw	zero,16(a5)
ffffffffc020182a:	0007b423          	sd	zero,8(a5)
ffffffffc020182e:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201832:	04078793          	addi	a5,a5,64
ffffffffc0201836:	fed795e3          	bne	a5,a3,ffffffffc0201820 <default_init_memmap+0x12>
    base->property = n;
ffffffffc020183a:	2581                	sext.w	a1,a1
ffffffffc020183c:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020183e:	4789                	li	a5,2
ffffffffc0201840:	00850713          	addi	a4,a0,8
ffffffffc0201844:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201848:	000ad697          	auipc	a3,0xad
ffffffffc020184c:	0f868693          	addi	a3,a3,248 # ffffffffc02ae940 <free_area>
ffffffffc0201850:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201852:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201854:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201858:	9db9                	addw	a1,a1,a4
ffffffffc020185a:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020185c:	04d78a63          	beq	a5,a3,ffffffffc02018b0 <default_init_memmap+0xa2>
            struct Page* page = le2page(le, page_link);
ffffffffc0201860:	fe878713          	addi	a4,a5,-24
ffffffffc0201864:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201868:	4581                	li	a1,0
            if (base < page) {
ffffffffc020186a:	00e56a63          	bltu	a0,a4,ffffffffc020187e <default_init_memmap+0x70>
    return listelm->next;
ffffffffc020186e:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201870:	02d70263          	beq	a4,a3,ffffffffc0201894 <default_init_memmap+0x86>
    for (; p != base + n; p ++) {
ffffffffc0201874:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201876:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020187a:	fee57ae3          	bgeu	a0,a4,ffffffffc020186e <default_init_memmap+0x60>
ffffffffc020187e:	c199                	beqz	a1,ffffffffc0201884 <default_init_memmap+0x76>
ffffffffc0201880:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201884:	6398                	ld	a4,0(a5)
}
ffffffffc0201886:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201888:	e390                	sd	a2,0(a5)
ffffffffc020188a:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020188c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020188e:	ed18                	sd	a4,24(a0)
ffffffffc0201890:	0141                	addi	sp,sp,16
ffffffffc0201892:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201894:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201896:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201898:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020189a:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020189c:	00d70663          	beq	a4,a3,ffffffffc02018a8 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc02018a0:	8832                	mv	a6,a2
ffffffffc02018a2:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02018a4:	87ba                	mv	a5,a4
ffffffffc02018a6:	bfc1                	j	ffffffffc0201876 <default_init_memmap+0x68>
}
ffffffffc02018a8:	60a2                	ld	ra,8(sp)
ffffffffc02018aa:	e290                	sd	a2,0(a3)
ffffffffc02018ac:	0141                	addi	sp,sp,16
ffffffffc02018ae:	8082                	ret
ffffffffc02018b0:	60a2                	ld	ra,8(sp)
ffffffffc02018b2:	e390                	sd	a2,0(a5)
ffffffffc02018b4:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02018b6:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02018b8:	ed1c                	sd	a5,24(a0)
ffffffffc02018ba:	0141                	addi	sp,sp,16
ffffffffc02018bc:	8082                	ret
        assert(PageReserved(p));
ffffffffc02018be:	00006697          	auipc	a3,0x6
ffffffffc02018c2:	ad268693          	addi	a3,a3,-1326 # ffffffffc0207390 <commands+0xb20>
ffffffffc02018c6:	00005617          	auipc	a2,0x5
ffffffffc02018ca:	3fa60613          	addi	a2,a2,1018 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02018ce:	04900593          	li	a1,73
ffffffffc02018d2:	00005517          	auipc	a0,0x5
ffffffffc02018d6:	74e50513          	addi	a0,a0,1870 # ffffffffc0207020 <commands+0x7b0>
ffffffffc02018da:	ba1fe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(n > 0);
ffffffffc02018de:	00006697          	auipc	a3,0x6
ffffffffc02018e2:	a8268693          	addi	a3,a3,-1406 # ffffffffc0207360 <commands+0xaf0>
ffffffffc02018e6:	00005617          	auipc	a2,0x5
ffffffffc02018ea:	3da60613          	addi	a2,a2,986 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02018ee:	04600593          	li	a1,70
ffffffffc02018f2:	00005517          	auipc	a0,0x5
ffffffffc02018f6:	72e50513          	addi	a0,a0,1838 # ffffffffc0207020 <commands+0x7b0>
ffffffffc02018fa:	b81fe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02018fe <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc02018fe:	c94d                	beqz	a0,ffffffffc02019b0 <slob_free+0xb2>
{
ffffffffc0201900:	1141                	addi	sp,sp,-16
ffffffffc0201902:	e022                	sd	s0,0(sp)
ffffffffc0201904:	e406                	sd	ra,8(sp)
ffffffffc0201906:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201908:	e9c1                	bnez	a1,ffffffffc0201998 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020190a:	100027f3          	csrr	a5,sstatus
ffffffffc020190e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201910:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201912:	ebd9                	bnez	a5,ffffffffc02019a8 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201914:	000a6617          	auipc	a2,0xa6
ffffffffc0201918:	c1c60613          	addi	a2,a2,-996 # ffffffffc02a7530 <slobfree>
ffffffffc020191c:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020191e:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201920:	679c                	ld	a5,8(a5)
ffffffffc0201922:	02877a63          	bgeu	a4,s0,ffffffffc0201956 <slob_free+0x58>
ffffffffc0201926:	00f46463          	bltu	s0,a5,ffffffffc020192e <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020192a:	fef76ae3          	bltu	a4,a5,ffffffffc020191e <slob_free+0x20>
			break;

	if (b + b->units == cur->next) {
ffffffffc020192e:	400c                	lw	a1,0(s0)
ffffffffc0201930:	00459693          	slli	a3,a1,0x4
ffffffffc0201934:	96a2                	add	a3,a3,s0
ffffffffc0201936:	02d78a63          	beq	a5,a3,ffffffffc020196a <slob_free+0x6c>
		b->units += cur->next->units;
		b->next = cur->next->next;
	} else
		b->next = cur->next;

	if (cur + cur->units == b) {
ffffffffc020193a:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc020193c:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b) {
ffffffffc020193e:	00469793          	slli	a5,a3,0x4
ffffffffc0201942:	97ba                	add	a5,a5,a4
ffffffffc0201944:	02f40e63          	beq	s0,a5,ffffffffc0201980 <slob_free+0x82>
		cur->units += b->units;
		cur->next = b->next;
	} else
		cur->next = b;
ffffffffc0201948:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc020194a:	e218                	sd	a4,0(a2)
    if (flag) {
ffffffffc020194c:	e129                	bnez	a0,ffffffffc020198e <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc020194e:	60a2                	ld	ra,8(sp)
ffffffffc0201950:	6402                	ld	s0,0(sp)
ffffffffc0201952:	0141                	addi	sp,sp,16
ffffffffc0201954:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201956:	fcf764e3          	bltu	a4,a5,ffffffffc020191e <slob_free+0x20>
ffffffffc020195a:	fcf472e3          	bgeu	s0,a5,ffffffffc020191e <slob_free+0x20>
	if (b + b->units == cur->next) {
ffffffffc020195e:	400c                	lw	a1,0(s0)
ffffffffc0201960:	00459693          	slli	a3,a1,0x4
ffffffffc0201964:	96a2                	add	a3,a3,s0
ffffffffc0201966:	fcd79ae3          	bne	a5,a3,ffffffffc020193a <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc020196a:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc020196c:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc020196e:	9db5                	addw	a1,a1,a3
ffffffffc0201970:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b) {
ffffffffc0201972:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201974:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b) {
ffffffffc0201976:	00469793          	slli	a5,a3,0x4
ffffffffc020197a:	97ba                	add	a5,a5,a4
ffffffffc020197c:	fcf416e3          	bne	s0,a5,ffffffffc0201948 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201980:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201982:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201984:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201986:	9ebd                	addw	a3,a3,a5
ffffffffc0201988:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc020198a:	e70c                	sd	a1,8(a4)
ffffffffc020198c:	d169                	beqz	a0,ffffffffc020194e <slob_free+0x50>
}
ffffffffc020198e:	6402                	ld	s0,0(sp)
ffffffffc0201990:	60a2                	ld	ra,8(sp)
ffffffffc0201992:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201994:	cadfe06f          	j	ffffffffc0200640 <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201998:	25bd                	addiw	a1,a1,15
ffffffffc020199a:	8191                	srli	a1,a1,0x4
ffffffffc020199c:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020199e:	100027f3          	csrr	a5,sstatus
ffffffffc02019a2:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02019a4:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019a6:	d7bd                	beqz	a5,ffffffffc0201914 <slob_free+0x16>
        intr_disable();
ffffffffc02019a8:	c9ffe0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        return 1;
ffffffffc02019ac:	4505                	li	a0,1
ffffffffc02019ae:	b79d                	j	ffffffffc0201914 <slob_free+0x16>
ffffffffc02019b0:	8082                	ret

ffffffffc02019b2 <__slob_get_free_pages.constprop.0>:
  struct Page * page = alloc_pages(1 << order);
ffffffffc02019b2:	4785                	li	a5,1
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc02019b4:	1141                	addi	sp,sp,-16
  struct Page * page = alloc_pages(1 << order);
ffffffffc02019b6:	00a7953b          	sllw	a0,a5,a0
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc02019ba:	e406                	sd	ra,8(sp)
  struct Page * page = alloc_pages(1 << order);
ffffffffc02019bc:	352000ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
  if(!page)
ffffffffc02019c0:	c91d                	beqz	a0,ffffffffc02019f6 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc02019c2:	000b1697          	auipc	a3,0xb1
ffffffffc02019c6:	07e6b683          	ld	a3,126(a3) # ffffffffc02b2a40 <pages>
ffffffffc02019ca:	8d15                	sub	a0,a0,a3
ffffffffc02019cc:	8519                	srai	a0,a0,0x6
ffffffffc02019ce:	00007697          	auipc	a3,0x7
ffffffffc02019d2:	3726b683          	ld	a3,882(a3) # ffffffffc0208d40 <nbase>
ffffffffc02019d6:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc02019d8:	00c51793          	slli	a5,a0,0xc
ffffffffc02019dc:	83b1                	srli	a5,a5,0xc
ffffffffc02019de:	000b1717          	auipc	a4,0xb1
ffffffffc02019e2:	05a73703          	ld	a4,90(a4) # ffffffffc02b2a38 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc02019e6:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc02019e8:	00e7fa63          	bgeu	a5,a4,ffffffffc02019fc <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc02019ec:	000b1697          	auipc	a3,0xb1
ffffffffc02019f0:	0646b683          	ld	a3,100(a3) # ffffffffc02b2a50 <va_pa_offset>
ffffffffc02019f4:	9536                	add	a0,a0,a3
}
ffffffffc02019f6:	60a2                	ld	ra,8(sp)
ffffffffc02019f8:	0141                	addi	sp,sp,16
ffffffffc02019fa:	8082                	ret
ffffffffc02019fc:	86aa                	mv	a3,a0
ffffffffc02019fe:	00006617          	auipc	a2,0x6
ffffffffc0201a02:	9f260613          	addi	a2,a2,-1550 # ffffffffc02073f0 <default_pmm_manager+0x38>
ffffffffc0201a06:	06900593          	li	a1,105
ffffffffc0201a0a:	00006517          	auipc	a0,0x6
ffffffffc0201a0e:	a0e50513          	addi	a0,a0,-1522 # ffffffffc0207418 <default_pmm_manager+0x60>
ffffffffc0201a12:	a69fe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0201a16 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201a16:	1101                	addi	sp,sp,-32
ffffffffc0201a18:	ec06                	sd	ra,24(sp)
ffffffffc0201a1a:	e822                	sd	s0,16(sp)
ffffffffc0201a1c:	e426                	sd	s1,8(sp)
ffffffffc0201a1e:	e04a                	sd	s2,0(sp)
  assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc0201a20:	01050713          	addi	a4,a0,16
ffffffffc0201a24:	6785                	lui	a5,0x1
ffffffffc0201a26:	0cf77363          	bgeu	a4,a5,ffffffffc0201aec <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201a2a:	00f50493          	addi	s1,a0,15
ffffffffc0201a2e:	8091                	srli	s1,s1,0x4
ffffffffc0201a30:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a32:	10002673          	csrr	a2,sstatus
ffffffffc0201a36:	8a09                	andi	a2,a2,2
ffffffffc0201a38:	e25d                	bnez	a2,ffffffffc0201ade <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201a3a:	000a6917          	auipc	s2,0xa6
ffffffffc0201a3e:	af690913          	addi	s2,s2,-1290 # ffffffffc02a7530 <slobfree>
ffffffffc0201a42:	00093683          	ld	a3,0(s2)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201a46:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201a48:	4398                	lw	a4,0(a5)
ffffffffc0201a4a:	08975e63          	bge	a4,s1,ffffffffc0201ae6 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree) {
ffffffffc0201a4e:	00f68b63          	beq	a3,a5,ffffffffc0201a64 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201a52:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201a54:	4018                	lw	a4,0(s0)
ffffffffc0201a56:	02975a63          	bge	a4,s1,ffffffffc0201a8a <slob_alloc.constprop.0+0x74>
		if (cur == slobfree) {
ffffffffc0201a5a:	00093683          	ld	a3,0(s2)
ffffffffc0201a5e:	87a2                	mv	a5,s0
ffffffffc0201a60:	fef699e3          	bne	a3,a5,ffffffffc0201a52 <slob_alloc.constprop.0+0x3c>
    if (flag) {
ffffffffc0201a64:	ee31                	bnez	a2,ffffffffc0201ac0 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201a66:	4501                	li	a0,0
ffffffffc0201a68:	f4bff0ef          	jal	ra,ffffffffc02019b2 <__slob_get_free_pages.constprop.0>
ffffffffc0201a6c:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201a6e:	cd05                	beqz	a0,ffffffffc0201aa6 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201a70:	6585                	lui	a1,0x1
ffffffffc0201a72:	e8dff0ef          	jal	ra,ffffffffc02018fe <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a76:	10002673          	csrr	a2,sstatus
ffffffffc0201a7a:	8a09                	andi	a2,a2,2
ffffffffc0201a7c:	ee05                	bnez	a2,ffffffffc0201ab4 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201a7e:	00093783          	ld	a5,0(s2)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201a82:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201a84:	4018                	lw	a4,0(s0)
ffffffffc0201a86:	fc974ae3          	blt	a4,s1,ffffffffc0201a5a <slob_alloc.constprop.0+0x44>
			if (cur->units == units) /* exact fit? */
ffffffffc0201a8a:	04e48763          	beq	s1,a4,ffffffffc0201ad8 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201a8e:	00449693          	slli	a3,s1,0x4
ffffffffc0201a92:	96a2                	add	a3,a3,s0
ffffffffc0201a94:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201a96:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201a98:	9f05                	subw	a4,a4,s1
ffffffffc0201a9a:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201a9c:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201a9e:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201aa0:	00f93023          	sd	a5,0(s2)
    if (flag) {
ffffffffc0201aa4:	e20d                	bnez	a2,ffffffffc0201ac6 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201aa6:	60e2                	ld	ra,24(sp)
ffffffffc0201aa8:	8522                	mv	a0,s0
ffffffffc0201aaa:	6442                	ld	s0,16(sp)
ffffffffc0201aac:	64a2                	ld	s1,8(sp)
ffffffffc0201aae:	6902                	ld	s2,0(sp)
ffffffffc0201ab0:	6105                	addi	sp,sp,32
ffffffffc0201ab2:	8082                	ret
        intr_disable();
ffffffffc0201ab4:	b93fe0ef          	jal	ra,ffffffffc0200646 <intr_disable>
			cur = slobfree;
ffffffffc0201ab8:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201abc:	4605                	li	a2,1
ffffffffc0201abe:	b7d1                	j	ffffffffc0201a82 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201ac0:	b81fe0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0201ac4:	b74d                	j	ffffffffc0201a66 <slob_alloc.constprop.0+0x50>
ffffffffc0201ac6:	b7bfe0ef          	jal	ra,ffffffffc0200640 <intr_enable>
}
ffffffffc0201aca:	60e2                	ld	ra,24(sp)
ffffffffc0201acc:	8522                	mv	a0,s0
ffffffffc0201ace:	6442                	ld	s0,16(sp)
ffffffffc0201ad0:	64a2                	ld	s1,8(sp)
ffffffffc0201ad2:	6902                	ld	s2,0(sp)
ffffffffc0201ad4:	6105                	addi	sp,sp,32
ffffffffc0201ad6:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201ad8:	6418                	ld	a4,8(s0)
ffffffffc0201ada:	e798                	sd	a4,8(a5)
ffffffffc0201adc:	b7d1                	j	ffffffffc0201aa0 <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201ade:	b69fe0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        return 1;
ffffffffc0201ae2:	4605                	li	a2,1
ffffffffc0201ae4:	bf99                	j	ffffffffc0201a3a <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201ae6:	843e                	mv	s0,a5
ffffffffc0201ae8:	87b6                	mv	a5,a3
ffffffffc0201aea:	b745                	j	ffffffffc0201a8a <slob_alloc.constprop.0+0x74>
  assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc0201aec:	00006697          	auipc	a3,0x6
ffffffffc0201af0:	93c68693          	addi	a3,a3,-1732 # ffffffffc0207428 <default_pmm_manager+0x70>
ffffffffc0201af4:	00005617          	auipc	a2,0x5
ffffffffc0201af8:	1cc60613          	addi	a2,a2,460 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0201afc:	06400593          	li	a1,100
ffffffffc0201b00:	00006517          	auipc	a0,0x6
ffffffffc0201b04:	94850513          	addi	a0,a0,-1720 # ffffffffc0207448 <default_pmm_manager+0x90>
ffffffffc0201b08:	973fe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0201b0c <kmalloc_init>:
slob_init(void) {
  cprintf("use SLOB allocator\n");
}

inline void 
kmalloc_init(void) {
ffffffffc0201b0c:	1141                	addi	sp,sp,-16
  cprintf("use SLOB allocator\n");
ffffffffc0201b0e:	00006517          	auipc	a0,0x6
ffffffffc0201b12:	95250513          	addi	a0,a0,-1710 # ffffffffc0207460 <default_pmm_manager+0xa8>
kmalloc_init(void) {
ffffffffc0201b16:	e406                	sd	ra,8(sp)
  cprintf("use SLOB allocator\n");
ffffffffc0201b18:	e68fe0ef          	jal	ra,ffffffffc0200180 <cprintf>
    slob_init();
    cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201b1c:	60a2                	ld	ra,8(sp)
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201b1e:	00006517          	auipc	a0,0x6
ffffffffc0201b22:	95a50513          	addi	a0,a0,-1702 # ffffffffc0207478 <default_pmm_manager+0xc0>
}
ffffffffc0201b26:	0141                	addi	sp,sp,16
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201b28:	e58fe06f          	j	ffffffffc0200180 <cprintf>

ffffffffc0201b2c <kallocated>:
}

size_t
kallocated(void) {
   return slob_allocated();
}
ffffffffc0201b2c:	4501                	li	a0,0
ffffffffc0201b2e:	8082                	ret

ffffffffc0201b30 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201b30:	1101                	addi	sp,sp,-32
ffffffffc0201b32:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201b34:	6905                	lui	s2,0x1
{
ffffffffc0201b36:	e822                	sd	s0,16(sp)
ffffffffc0201b38:	ec06                	sd	ra,24(sp)
ffffffffc0201b3a:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201b3c:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8be1>
{
ffffffffc0201b40:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201b42:	04a7f963          	bgeu	a5,a0,ffffffffc0201b94 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201b46:	4561                	li	a0,24
ffffffffc0201b48:	ecfff0ef          	jal	ra,ffffffffc0201a16 <slob_alloc.constprop.0>
ffffffffc0201b4c:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201b4e:	c929                	beqz	a0,ffffffffc0201ba0 <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201b50:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201b54:	4501                	li	a0,0
	for ( ; size > 4096 ; size >>=1)
ffffffffc0201b56:	00f95763          	bge	s2,a5,ffffffffc0201b64 <kmalloc+0x34>
ffffffffc0201b5a:	6705                	lui	a4,0x1
ffffffffc0201b5c:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201b5e:	2505                	addiw	a0,a0,1
	for ( ; size > 4096 ; size >>=1)
ffffffffc0201b60:	fef74ee3          	blt	a4,a5,ffffffffc0201b5c <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201b64:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201b66:	e4dff0ef          	jal	ra,ffffffffc02019b2 <__slob_get_free_pages.constprop.0>
ffffffffc0201b6a:	e488                	sd	a0,8(s1)
ffffffffc0201b6c:	842a                	mv	s0,a0
	if (bb->pages) {
ffffffffc0201b6e:	c525                	beqz	a0,ffffffffc0201bd6 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b70:	100027f3          	csrr	a5,sstatus
ffffffffc0201b74:	8b89                	andi	a5,a5,2
ffffffffc0201b76:	ef8d                	bnez	a5,ffffffffc0201bb0 <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201b78:	000b1797          	auipc	a5,0xb1
ffffffffc0201b7c:	ea878793          	addi	a5,a5,-344 # ffffffffc02b2a20 <bigblocks>
ffffffffc0201b80:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201b82:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201b84:	e898                	sd	a4,16(s1)
  return __kmalloc(size, 0);
}
ffffffffc0201b86:	60e2                	ld	ra,24(sp)
ffffffffc0201b88:	8522                	mv	a0,s0
ffffffffc0201b8a:	6442                	ld	s0,16(sp)
ffffffffc0201b8c:	64a2                	ld	s1,8(sp)
ffffffffc0201b8e:	6902                	ld	s2,0(sp)
ffffffffc0201b90:	6105                	addi	sp,sp,32
ffffffffc0201b92:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201b94:	0541                	addi	a0,a0,16
ffffffffc0201b96:	e81ff0ef          	jal	ra,ffffffffc0201a16 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201b9a:	01050413          	addi	s0,a0,16
ffffffffc0201b9e:	f565                	bnez	a0,ffffffffc0201b86 <kmalloc+0x56>
ffffffffc0201ba0:	4401                	li	s0,0
}
ffffffffc0201ba2:	60e2                	ld	ra,24(sp)
ffffffffc0201ba4:	8522                	mv	a0,s0
ffffffffc0201ba6:	6442                	ld	s0,16(sp)
ffffffffc0201ba8:	64a2                	ld	s1,8(sp)
ffffffffc0201baa:	6902                	ld	s2,0(sp)
ffffffffc0201bac:	6105                	addi	sp,sp,32
ffffffffc0201bae:	8082                	ret
        intr_disable();
ffffffffc0201bb0:	a97fe0ef          	jal	ra,ffffffffc0200646 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201bb4:	000b1797          	auipc	a5,0xb1
ffffffffc0201bb8:	e6c78793          	addi	a5,a5,-404 # ffffffffc02b2a20 <bigblocks>
ffffffffc0201bbc:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201bbe:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201bc0:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201bc2:	a7ffe0ef          	jal	ra,ffffffffc0200640 <intr_enable>
		return bb->pages;
ffffffffc0201bc6:	6480                	ld	s0,8(s1)
}
ffffffffc0201bc8:	60e2                	ld	ra,24(sp)
ffffffffc0201bca:	64a2                	ld	s1,8(sp)
ffffffffc0201bcc:	8522                	mv	a0,s0
ffffffffc0201bce:	6442                	ld	s0,16(sp)
ffffffffc0201bd0:	6902                	ld	s2,0(sp)
ffffffffc0201bd2:	6105                	addi	sp,sp,32
ffffffffc0201bd4:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201bd6:	45e1                	li	a1,24
ffffffffc0201bd8:	8526                	mv	a0,s1
ffffffffc0201bda:	d25ff0ef          	jal	ra,ffffffffc02018fe <slob_free>
  return __kmalloc(size, 0);
ffffffffc0201bde:	b765                	j	ffffffffc0201b86 <kmalloc+0x56>

ffffffffc0201be0 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201be0:	c169                	beqz	a0,ffffffffc0201ca2 <kfree+0xc2>
{
ffffffffc0201be2:	1101                	addi	sp,sp,-32
ffffffffc0201be4:	e822                	sd	s0,16(sp)
ffffffffc0201be6:	ec06                	sd	ra,24(sp)
ffffffffc0201be8:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE-1))) {
ffffffffc0201bea:	03451793          	slli	a5,a0,0x34
ffffffffc0201bee:	842a                	mv	s0,a0
ffffffffc0201bf0:	e3d9                	bnez	a5,ffffffffc0201c76 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201bf2:	100027f3          	csrr	a5,sstatus
ffffffffc0201bf6:	8b89                	andi	a5,a5,2
ffffffffc0201bf8:	e7d9                	bnez	a5,ffffffffc0201c86 <kfree+0xa6>
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201bfa:	000b1797          	auipc	a5,0xb1
ffffffffc0201bfe:	e267b783          	ld	a5,-474(a5) # ffffffffc02b2a20 <bigblocks>
    return 0;
ffffffffc0201c02:	4601                	li	a2,0
ffffffffc0201c04:	cbad                	beqz	a5,ffffffffc0201c76 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201c06:	000b1697          	auipc	a3,0xb1
ffffffffc0201c0a:	e1a68693          	addi	a3,a3,-486 # ffffffffc02b2a20 <bigblocks>
ffffffffc0201c0e:	a021                	j	ffffffffc0201c16 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201c10:	01048693          	addi	a3,s1,16
ffffffffc0201c14:	c3a5                	beqz	a5,ffffffffc0201c74 <kfree+0x94>
			if (bb->pages == block) {
ffffffffc0201c16:	6798                	ld	a4,8(a5)
ffffffffc0201c18:	84be                	mv	s1,a5
				*last = bb->next;
ffffffffc0201c1a:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block) {
ffffffffc0201c1c:	fe871ae3          	bne	a4,s0,ffffffffc0201c10 <kfree+0x30>
				*last = bb->next;
ffffffffc0201c20:	e29c                	sd	a5,0(a3)
    if (flag) {
ffffffffc0201c22:	ee2d                	bnez	a2,ffffffffc0201c9c <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201c24:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201c28:	4098                	lw	a4,0(s1)
ffffffffc0201c2a:	08f46963          	bltu	s0,a5,ffffffffc0201cbc <kfree+0xdc>
ffffffffc0201c2e:	000b1697          	auipc	a3,0xb1
ffffffffc0201c32:	e226b683          	ld	a3,-478(a3) # ffffffffc02b2a50 <va_pa_offset>
ffffffffc0201c36:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage) {
ffffffffc0201c38:	8031                	srli	s0,s0,0xc
ffffffffc0201c3a:	000b1797          	auipc	a5,0xb1
ffffffffc0201c3e:	dfe7b783          	ld	a5,-514(a5) # ffffffffc02b2a38 <npage>
ffffffffc0201c42:	06f47163          	bgeu	s0,a5,ffffffffc0201ca4 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201c46:	00007517          	auipc	a0,0x7
ffffffffc0201c4a:	0fa53503          	ld	a0,250(a0) # ffffffffc0208d40 <nbase>
ffffffffc0201c4e:	8c09                	sub	s0,s0,a0
ffffffffc0201c50:	041a                	slli	s0,s0,0x6
  free_pages(kva2page(kva), 1 << order);
ffffffffc0201c52:	000b1517          	auipc	a0,0xb1
ffffffffc0201c56:	dee53503          	ld	a0,-530(a0) # ffffffffc02b2a40 <pages>
ffffffffc0201c5a:	4585                	li	a1,1
ffffffffc0201c5c:	9522                	add	a0,a0,s0
ffffffffc0201c5e:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201c62:	13e000ef          	jal	ra,ffffffffc0201da0 <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201c66:	6442                	ld	s0,16(sp)
ffffffffc0201c68:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201c6a:	8526                	mv	a0,s1
}
ffffffffc0201c6c:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201c6e:	45e1                	li	a1,24
}
ffffffffc0201c70:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201c72:	b171                	j	ffffffffc02018fe <slob_free>
ffffffffc0201c74:	e20d                	bnez	a2,ffffffffc0201c96 <kfree+0xb6>
ffffffffc0201c76:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201c7a:	6442                	ld	s0,16(sp)
ffffffffc0201c7c:	60e2                	ld	ra,24(sp)
ffffffffc0201c7e:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201c80:	4581                	li	a1,0
}
ffffffffc0201c82:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201c84:	b9ad                	j	ffffffffc02018fe <slob_free>
        intr_disable();
ffffffffc0201c86:	9c1fe0ef          	jal	ra,ffffffffc0200646 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201c8a:	000b1797          	auipc	a5,0xb1
ffffffffc0201c8e:	d967b783          	ld	a5,-618(a5) # ffffffffc02b2a20 <bigblocks>
        return 1;
ffffffffc0201c92:	4605                	li	a2,1
ffffffffc0201c94:	fbad                	bnez	a5,ffffffffc0201c06 <kfree+0x26>
        intr_enable();
ffffffffc0201c96:	9abfe0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0201c9a:	bff1                	j	ffffffffc0201c76 <kfree+0x96>
ffffffffc0201c9c:	9a5fe0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0201ca0:	b751                	j	ffffffffc0201c24 <kfree+0x44>
ffffffffc0201ca2:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201ca4:	00006617          	auipc	a2,0x6
ffffffffc0201ca8:	81c60613          	addi	a2,a2,-2020 # ffffffffc02074c0 <default_pmm_manager+0x108>
ffffffffc0201cac:	06200593          	li	a1,98
ffffffffc0201cb0:	00005517          	auipc	a0,0x5
ffffffffc0201cb4:	76850513          	addi	a0,a0,1896 # ffffffffc0207418 <default_pmm_manager+0x60>
ffffffffc0201cb8:	fc2fe0ef          	jal	ra,ffffffffc020047a <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201cbc:	86a2                	mv	a3,s0
ffffffffc0201cbe:	00005617          	auipc	a2,0x5
ffffffffc0201cc2:	7da60613          	addi	a2,a2,2010 # ffffffffc0207498 <default_pmm_manager+0xe0>
ffffffffc0201cc6:	06e00593          	li	a1,110
ffffffffc0201cca:	00005517          	auipc	a0,0x5
ffffffffc0201cce:	74e50513          	addi	a0,a0,1870 # ffffffffc0207418 <default_pmm_manager+0x60>
ffffffffc0201cd2:	fa8fe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0201cd6 <pa2page.part.0>:
pa2page(uintptr_t pa) {
ffffffffc0201cd6:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201cd8:	00005617          	auipc	a2,0x5
ffffffffc0201cdc:	7e860613          	addi	a2,a2,2024 # ffffffffc02074c0 <default_pmm_manager+0x108>
ffffffffc0201ce0:	06200593          	li	a1,98
ffffffffc0201ce4:	00005517          	auipc	a0,0x5
ffffffffc0201ce8:	73450513          	addi	a0,a0,1844 # ffffffffc0207418 <default_pmm_manager+0x60>
pa2page(uintptr_t pa) {
ffffffffc0201cec:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201cee:	f8cfe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0201cf2 <pte2page.part.0>:
pte2page(pte_t pte) {
ffffffffc0201cf2:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201cf4:	00005617          	auipc	a2,0x5
ffffffffc0201cf8:	7ec60613          	addi	a2,a2,2028 # ffffffffc02074e0 <default_pmm_manager+0x128>
ffffffffc0201cfc:	07400593          	li	a1,116
ffffffffc0201d00:	00005517          	auipc	a0,0x5
ffffffffc0201d04:	71850513          	addi	a0,a0,1816 # ffffffffc0207418 <default_pmm_manager+0x60>
pte2page(pte_t pte) {
ffffffffc0201d08:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201d0a:	f70fe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0201d0e <alloc_pages>:
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
ffffffffc0201d0e:	7139                	addi	sp,sp,-64
ffffffffc0201d10:	f426                	sd	s1,40(sp)
ffffffffc0201d12:	f04a                	sd	s2,32(sp)
ffffffffc0201d14:	ec4e                	sd	s3,24(sp)
ffffffffc0201d16:	e852                	sd	s4,16(sp)
ffffffffc0201d18:	e456                	sd	s5,8(sp)
ffffffffc0201d1a:	e05a                	sd	s6,0(sp)
ffffffffc0201d1c:	fc06                	sd	ra,56(sp)
ffffffffc0201d1e:	f822                	sd	s0,48(sp)
ffffffffc0201d20:	84aa                	mv	s1,a0
ffffffffc0201d22:	000b1917          	auipc	s2,0xb1
ffffffffc0201d26:	d2690913          	addi	s2,s2,-730 # ffffffffc02b2a48 <pmm_manager>
        {
            page = pmm_manager->alloc_pages(n);
        }
        local_intr_restore(intr_flag);

        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201d2a:	4a05                	li	s4,1
ffffffffc0201d2c:	000b1a97          	auipc	s5,0xb1
ffffffffc0201d30:	d3ca8a93          	addi	s5,s5,-708 # ffffffffc02b2a68 <swap_init_ok>

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0);
ffffffffc0201d34:	0005099b          	sext.w	s3,a0
ffffffffc0201d38:	000b1b17          	auipc	s6,0xb1
ffffffffc0201d3c:	d38b0b13          	addi	s6,s6,-712 # ffffffffc02b2a70 <check_mm_struct>
ffffffffc0201d40:	a01d                	j	ffffffffc0201d66 <alloc_pages+0x58>
            page = pmm_manager->alloc_pages(n);
ffffffffc0201d42:	00093783          	ld	a5,0(s2)
ffffffffc0201d46:	6f9c                	ld	a5,24(a5)
ffffffffc0201d48:	9782                	jalr	a5
ffffffffc0201d4a:	842a                	mv	s0,a0
        swap_out(check_mm_struct, n, 0);
ffffffffc0201d4c:	4601                	li	a2,0
ffffffffc0201d4e:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201d50:	ec0d                	bnez	s0,ffffffffc0201d8a <alloc_pages+0x7c>
ffffffffc0201d52:	029a6c63          	bltu	s4,s1,ffffffffc0201d8a <alloc_pages+0x7c>
ffffffffc0201d56:	000aa783          	lw	a5,0(s5)
ffffffffc0201d5a:	2781                	sext.w	a5,a5
ffffffffc0201d5c:	c79d                	beqz	a5,ffffffffc0201d8a <alloc_pages+0x7c>
        swap_out(check_mm_struct, n, 0);
ffffffffc0201d5e:	000b3503          	ld	a0,0(s6)
ffffffffc0201d62:	64d010ef          	jal	ra,ffffffffc0203bae <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d66:	100027f3          	csrr	a5,sstatus
ffffffffc0201d6a:	8b89                	andi	a5,a5,2
            page = pmm_manager->alloc_pages(n);
ffffffffc0201d6c:	8526                	mv	a0,s1
ffffffffc0201d6e:	dbf1                	beqz	a5,ffffffffc0201d42 <alloc_pages+0x34>
        intr_disable();
ffffffffc0201d70:	8d7fe0ef          	jal	ra,ffffffffc0200646 <intr_disable>
ffffffffc0201d74:	00093783          	ld	a5,0(s2)
ffffffffc0201d78:	8526                	mv	a0,s1
ffffffffc0201d7a:	6f9c                	ld	a5,24(a5)
ffffffffc0201d7c:	9782                	jalr	a5
ffffffffc0201d7e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201d80:	8c1fe0ef          	jal	ra,ffffffffc0200640 <intr_enable>
        swap_out(check_mm_struct, n, 0);
ffffffffc0201d84:	4601                	li	a2,0
ffffffffc0201d86:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201d88:	d469                	beqz	s0,ffffffffc0201d52 <alloc_pages+0x44>
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}
ffffffffc0201d8a:	70e2                	ld	ra,56(sp)
ffffffffc0201d8c:	8522                	mv	a0,s0
ffffffffc0201d8e:	7442                	ld	s0,48(sp)
ffffffffc0201d90:	74a2                	ld	s1,40(sp)
ffffffffc0201d92:	7902                	ld	s2,32(sp)
ffffffffc0201d94:	69e2                	ld	s3,24(sp)
ffffffffc0201d96:	6a42                	ld	s4,16(sp)
ffffffffc0201d98:	6aa2                	ld	s5,8(sp)
ffffffffc0201d9a:	6b02                	ld	s6,0(sp)
ffffffffc0201d9c:	6121                	addi	sp,sp,64
ffffffffc0201d9e:	8082                	ret

ffffffffc0201da0 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201da0:	100027f3          	csrr	a5,sstatus
ffffffffc0201da4:	8b89                	andi	a5,a5,2
ffffffffc0201da6:	e799                	bnez	a5,ffffffffc0201db4 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201da8:	000b1797          	auipc	a5,0xb1
ffffffffc0201dac:	ca07b783          	ld	a5,-864(a5) # ffffffffc02b2a48 <pmm_manager>
ffffffffc0201db0:	739c                	ld	a5,32(a5)
ffffffffc0201db2:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0201db4:	1101                	addi	sp,sp,-32
ffffffffc0201db6:	ec06                	sd	ra,24(sp)
ffffffffc0201db8:	e822                	sd	s0,16(sp)
ffffffffc0201dba:	e426                	sd	s1,8(sp)
ffffffffc0201dbc:	842a                	mv	s0,a0
ffffffffc0201dbe:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201dc0:	887fe0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201dc4:	000b1797          	auipc	a5,0xb1
ffffffffc0201dc8:	c847b783          	ld	a5,-892(a5) # ffffffffc02b2a48 <pmm_manager>
ffffffffc0201dcc:	739c                	ld	a5,32(a5)
ffffffffc0201dce:	85a6                	mv	a1,s1
ffffffffc0201dd0:	8522                	mv	a0,s0
ffffffffc0201dd2:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201dd4:	6442                	ld	s0,16(sp)
ffffffffc0201dd6:	60e2                	ld	ra,24(sp)
ffffffffc0201dd8:	64a2                	ld	s1,8(sp)
ffffffffc0201dda:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201ddc:	865fe06f          	j	ffffffffc0200640 <intr_enable>

ffffffffc0201de0 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201de0:	100027f3          	csrr	a5,sstatus
ffffffffc0201de4:	8b89                	andi	a5,a5,2
ffffffffc0201de6:	e799                	bnez	a5,ffffffffc0201df4 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201de8:	000b1797          	auipc	a5,0xb1
ffffffffc0201dec:	c607b783          	ld	a5,-928(a5) # ffffffffc02b2a48 <pmm_manager>
ffffffffc0201df0:	779c                	ld	a5,40(a5)
ffffffffc0201df2:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0201df4:	1141                	addi	sp,sp,-16
ffffffffc0201df6:	e406                	sd	ra,8(sp)
ffffffffc0201df8:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201dfa:	84dfe0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201dfe:	000b1797          	auipc	a5,0xb1
ffffffffc0201e02:	c4a7b783          	ld	a5,-950(a5) # ffffffffc02b2a48 <pmm_manager>
ffffffffc0201e06:	779c                	ld	a5,40(a5)
ffffffffc0201e08:	9782                	jalr	a5
ffffffffc0201e0a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201e0c:	835fe0ef          	jal	ra,ffffffffc0200640 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201e10:	60a2                	ld	ra,8(sp)
ffffffffc0201e12:	8522                	mv	a0,s0
ffffffffc0201e14:	6402                	ld	s0,0(sp)
ffffffffc0201e16:	0141                	addi	sp,sp,16
ffffffffc0201e18:	8082                	ret

ffffffffc0201e1a <get_pte>:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201e1a:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201e1e:	1ff7f793          	andi	a5,a5,511
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201e22:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201e24:	078e                	slli	a5,a5,0x3
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201e26:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201e28:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201e2c:	6094                	ld	a3,0(s1)
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201e2e:	f04a                	sd	s2,32(sp)
ffffffffc0201e30:	ec4e                	sd	s3,24(sp)
ffffffffc0201e32:	e852                	sd	s4,16(sp)
ffffffffc0201e34:	fc06                	sd	ra,56(sp)
ffffffffc0201e36:	f822                	sd	s0,48(sp)
ffffffffc0201e38:	e456                	sd	s5,8(sp)
ffffffffc0201e3a:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201e3c:	0016f793          	andi	a5,a3,1
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201e40:	892e                	mv	s2,a1
ffffffffc0201e42:	89b2                	mv	s3,a2
ffffffffc0201e44:	000b1a17          	auipc	s4,0xb1
ffffffffc0201e48:	bf4a0a13          	addi	s4,s4,-1036 # ffffffffc02b2a38 <npage>
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201e4c:	e7b5                	bnez	a5,ffffffffc0201eb8 <get_pte+0x9e>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0201e4e:	12060b63          	beqz	a2,ffffffffc0201f84 <get_pte+0x16a>
ffffffffc0201e52:	4505                	li	a0,1
ffffffffc0201e54:	ebbff0ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc0201e58:	842a                	mv	s0,a0
ffffffffc0201e5a:	12050563          	beqz	a0,ffffffffc0201f84 <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc0201e5e:	000b1b17          	auipc	s6,0xb1
ffffffffc0201e62:	be2b0b13          	addi	s6,s6,-1054 # ffffffffc02b2a40 <pages>
ffffffffc0201e66:	000b3503          	ld	a0,0(s6)
ffffffffc0201e6a:	00080ab7          	lui	s5,0x80
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201e6e:	000b1a17          	auipc	s4,0xb1
ffffffffc0201e72:	bcaa0a13          	addi	s4,s4,-1078 # ffffffffc02b2a38 <npage>
ffffffffc0201e76:	40a40533          	sub	a0,s0,a0
ffffffffc0201e7a:	8519                	srai	a0,a0,0x6
ffffffffc0201e7c:	9556                	add	a0,a0,s5
ffffffffc0201e7e:	000a3703          	ld	a4,0(s4)
ffffffffc0201e82:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201e86:	4685                	li	a3,1
ffffffffc0201e88:	c014                	sw	a3,0(s0)
ffffffffc0201e8a:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201e8c:	0532                	slli	a0,a0,0xc
ffffffffc0201e8e:	14e7f263          	bgeu	a5,a4,ffffffffc0201fd2 <get_pte+0x1b8>
ffffffffc0201e92:	000b1797          	auipc	a5,0xb1
ffffffffc0201e96:	bbe7b783          	ld	a5,-1090(a5) # ffffffffc02b2a50 <va_pa_offset>
ffffffffc0201e9a:	6605                	lui	a2,0x1
ffffffffc0201e9c:	4581                	li	a1,0
ffffffffc0201e9e:	953e                	add	a0,a0,a5
ffffffffc0201ea0:	73a040ef          	jal	ra,ffffffffc02065da <memset>
    return page - pages + nbase;
ffffffffc0201ea4:	000b3683          	ld	a3,0(s6)
ffffffffc0201ea8:	40d406b3          	sub	a3,s0,a3
ffffffffc0201eac:	8699                	srai	a3,a3,0x6
ffffffffc0201eae:	96d6                	add	a3,a3,s5
  asm volatile("sfence.vma");
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201eb0:	06aa                	slli	a3,a3,0xa
ffffffffc0201eb2:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201eb6:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201eb8:	77fd                	lui	a5,0xfffff
ffffffffc0201eba:	068a                	slli	a3,a3,0x2
ffffffffc0201ebc:	000a3703          	ld	a4,0(s4)
ffffffffc0201ec0:	8efd                	and	a3,a3,a5
ffffffffc0201ec2:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201ec6:	0ce7f163          	bgeu	a5,a4,ffffffffc0201f88 <get_pte+0x16e>
ffffffffc0201eca:	000b1a97          	auipc	s5,0xb1
ffffffffc0201ece:	b86a8a93          	addi	s5,s5,-1146 # ffffffffc02b2a50 <va_pa_offset>
ffffffffc0201ed2:	000ab403          	ld	s0,0(s5)
ffffffffc0201ed6:	01595793          	srli	a5,s2,0x15
ffffffffc0201eda:	1ff7f793          	andi	a5,a5,511
ffffffffc0201ede:	96a2                	add	a3,a3,s0
ffffffffc0201ee0:	00379413          	slli	s0,a5,0x3
ffffffffc0201ee4:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V)) {
ffffffffc0201ee6:	6014                	ld	a3,0(s0)
ffffffffc0201ee8:	0016f793          	andi	a5,a3,1
ffffffffc0201eec:	e3ad                	bnez	a5,ffffffffc0201f4e <get_pte+0x134>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0201eee:	08098b63          	beqz	s3,ffffffffc0201f84 <get_pte+0x16a>
ffffffffc0201ef2:	4505                	li	a0,1
ffffffffc0201ef4:	e1bff0ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc0201ef8:	84aa                	mv	s1,a0
ffffffffc0201efa:	c549                	beqz	a0,ffffffffc0201f84 <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc0201efc:	000b1b17          	auipc	s6,0xb1
ffffffffc0201f00:	b44b0b13          	addi	s6,s6,-1212 # ffffffffc02b2a40 <pages>
ffffffffc0201f04:	000b3503          	ld	a0,0(s6)
ffffffffc0201f08:	000809b7          	lui	s3,0x80
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f0c:	000a3703          	ld	a4,0(s4)
ffffffffc0201f10:	40a48533          	sub	a0,s1,a0
ffffffffc0201f14:	8519                	srai	a0,a0,0x6
ffffffffc0201f16:	954e                	add	a0,a0,s3
ffffffffc0201f18:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201f1c:	4685                	li	a3,1
ffffffffc0201f1e:	c094                	sw	a3,0(s1)
ffffffffc0201f20:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201f22:	0532                	slli	a0,a0,0xc
ffffffffc0201f24:	08e7fa63          	bgeu	a5,a4,ffffffffc0201fb8 <get_pte+0x19e>
ffffffffc0201f28:	000ab783          	ld	a5,0(s5)
ffffffffc0201f2c:	6605                	lui	a2,0x1
ffffffffc0201f2e:	4581                	li	a1,0
ffffffffc0201f30:	953e                	add	a0,a0,a5
ffffffffc0201f32:	6a8040ef          	jal	ra,ffffffffc02065da <memset>
    return page - pages + nbase;
ffffffffc0201f36:	000b3683          	ld	a3,0(s6)
ffffffffc0201f3a:	40d486b3          	sub	a3,s1,a3
ffffffffc0201f3e:	8699                	srai	a3,a3,0x6
ffffffffc0201f40:	96ce                	add	a3,a3,s3
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201f42:	06aa                	slli	a3,a3,0xa
ffffffffc0201f44:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201f48:	e014                	sd	a3,0(s0)
        }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201f4a:	000a3703          	ld	a4,0(s4)
ffffffffc0201f4e:	068a                	slli	a3,a3,0x2
ffffffffc0201f50:	757d                	lui	a0,0xfffff
ffffffffc0201f52:	8ee9                	and	a3,a3,a0
ffffffffc0201f54:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201f58:	04e7f463          	bgeu	a5,a4,ffffffffc0201fa0 <get_pte+0x186>
ffffffffc0201f5c:	000ab503          	ld	a0,0(s5)
ffffffffc0201f60:	00c95913          	srli	s2,s2,0xc
ffffffffc0201f64:	1ff97913          	andi	s2,s2,511
ffffffffc0201f68:	96aa                	add	a3,a3,a0
ffffffffc0201f6a:	00391513          	slli	a0,s2,0x3
ffffffffc0201f6e:	9536                	add	a0,a0,a3
}
ffffffffc0201f70:	70e2                	ld	ra,56(sp)
ffffffffc0201f72:	7442                	ld	s0,48(sp)
ffffffffc0201f74:	74a2                	ld	s1,40(sp)
ffffffffc0201f76:	7902                	ld	s2,32(sp)
ffffffffc0201f78:	69e2                	ld	s3,24(sp)
ffffffffc0201f7a:	6a42                	ld	s4,16(sp)
ffffffffc0201f7c:	6aa2                	ld	s5,8(sp)
ffffffffc0201f7e:	6b02                	ld	s6,0(sp)
ffffffffc0201f80:	6121                	addi	sp,sp,64
ffffffffc0201f82:	8082                	ret
            return NULL;
ffffffffc0201f84:	4501                	li	a0,0
ffffffffc0201f86:	b7ed                	j	ffffffffc0201f70 <get_pte+0x156>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201f88:	00005617          	auipc	a2,0x5
ffffffffc0201f8c:	46860613          	addi	a2,a2,1128 # ffffffffc02073f0 <default_pmm_manager+0x38>
ffffffffc0201f90:	0e300593          	li	a1,227
ffffffffc0201f94:	00005517          	auipc	a0,0x5
ffffffffc0201f98:	57450513          	addi	a0,a0,1396 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0201f9c:	cdefe0ef          	jal	ra,ffffffffc020047a <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201fa0:	00005617          	auipc	a2,0x5
ffffffffc0201fa4:	45060613          	addi	a2,a2,1104 # ffffffffc02073f0 <default_pmm_manager+0x38>
ffffffffc0201fa8:	0ee00593          	li	a1,238
ffffffffc0201fac:	00005517          	auipc	a0,0x5
ffffffffc0201fb0:	55c50513          	addi	a0,a0,1372 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0201fb4:	cc6fe0ef          	jal	ra,ffffffffc020047a <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201fb8:	86aa                	mv	a3,a0
ffffffffc0201fba:	00005617          	auipc	a2,0x5
ffffffffc0201fbe:	43660613          	addi	a2,a2,1078 # ffffffffc02073f0 <default_pmm_manager+0x38>
ffffffffc0201fc2:	0eb00593          	li	a1,235
ffffffffc0201fc6:	00005517          	auipc	a0,0x5
ffffffffc0201fca:	54250513          	addi	a0,a0,1346 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0201fce:	cacfe0ef          	jal	ra,ffffffffc020047a <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201fd2:	86aa                	mv	a3,a0
ffffffffc0201fd4:	00005617          	auipc	a2,0x5
ffffffffc0201fd8:	41c60613          	addi	a2,a2,1052 # ffffffffc02073f0 <default_pmm_manager+0x38>
ffffffffc0201fdc:	0df00593          	li	a1,223
ffffffffc0201fe0:	00005517          	auipc	a0,0x5
ffffffffc0201fe4:	52850513          	addi	a0,a0,1320 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0201fe8:	c92fe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0201fec <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0201fec:	1141                	addi	sp,sp,-16
ffffffffc0201fee:	e022                	sd	s0,0(sp)
ffffffffc0201ff0:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201ff2:	4601                	li	a2,0
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0201ff4:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201ff6:	e25ff0ef          	jal	ra,ffffffffc0201e1a <get_pte>
    if (ptep_store != NULL) {
ffffffffc0201ffa:	c011                	beqz	s0,ffffffffc0201ffe <get_page+0x12>
        *ptep_store = ptep;
ffffffffc0201ffc:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0201ffe:	c511                	beqz	a0,ffffffffc020200a <get_page+0x1e>
ffffffffc0202000:	611c                	ld	a5,0(a0)
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0202002:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0202004:	0017f713          	andi	a4,a5,1
ffffffffc0202008:	e709                	bnez	a4,ffffffffc0202012 <get_page+0x26>
}
ffffffffc020200a:	60a2                	ld	ra,8(sp)
ffffffffc020200c:	6402                	ld	s0,0(sp)
ffffffffc020200e:	0141                	addi	sp,sp,16
ffffffffc0202010:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202012:	078a                	slli	a5,a5,0x2
ffffffffc0202014:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202016:	000b1717          	auipc	a4,0xb1
ffffffffc020201a:	a2273703          	ld	a4,-1502(a4) # ffffffffc02b2a38 <npage>
ffffffffc020201e:	00e7ff63          	bgeu	a5,a4,ffffffffc020203c <get_page+0x50>
ffffffffc0202022:	60a2                	ld	ra,8(sp)
ffffffffc0202024:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0202026:	fff80537          	lui	a0,0xfff80
ffffffffc020202a:	97aa                	add	a5,a5,a0
ffffffffc020202c:	079a                	slli	a5,a5,0x6
ffffffffc020202e:	000b1517          	auipc	a0,0xb1
ffffffffc0202032:	a1253503          	ld	a0,-1518(a0) # ffffffffc02b2a40 <pages>
ffffffffc0202036:	953e                	add	a0,a0,a5
ffffffffc0202038:	0141                	addi	sp,sp,16
ffffffffc020203a:	8082                	ret
ffffffffc020203c:	c9bff0ef          	jal	ra,ffffffffc0201cd6 <pa2page.part.0>

ffffffffc0202040 <unmap_range>:
        *ptep = 0;                  //(5) clear second page table entry
        tlb_invalidate(pgdir, la);  //(6) flush tlb
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc0202040:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202042:	00c5e7b3          	or	a5,a1,a2
void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc0202046:	f486                	sd	ra,104(sp)
ffffffffc0202048:	f0a2                	sd	s0,96(sp)
ffffffffc020204a:	eca6                	sd	s1,88(sp)
ffffffffc020204c:	e8ca                	sd	s2,80(sp)
ffffffffc020204e:	e4ce                	sd	s3,72(sp)
ffffffffc0202050:	e0d2                	sd	s4,64(sp)
ffffffffc0202052:	fc56                	sd	s5,56(sp)
ffffffffc0202054:	f85a                	sd	s6,48(sp)
ffffffffc0202056:	f45e                	sd	s7,40(sp)
ffffffffc0202058:	f062                	sd	s8,32(sp)
ffffffffc020205a:	ec66                	sd	s9,24(sp)
ffffffffc020205c:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020205e:	17d2                	slli	a5,a5,0x34
ffffffffc0202060:	e3ed                	bnez	a5,ffffffffc0202142 <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc0202062:	002007b7          	lui	a5,0x200
ffffffffc0202066:	842e                	mv	s0,a1
ffffffffc0202068:	0ef5ed63          	bltu	a1,a5,ffffffffc0202162 <unmap_range+0x122>
ffffffffc020206c:	8932                	mv	s2,a2
ffffffffc020206e:	0ec5fa63          	bgeu	a1,a2,ffffffffc0202162 <unmap_range+0x122>
ffffffffc0202072:	4785                	li	a5,1
ffffffffc0202074:	07fe                	slli	a5,a5,0x1f
ffffffffc0202076:	0ec7e663          	bltu	a5,a2,ffffffffc0202162 <unmap_range+0x122>
ffffffffc020207a:	89aa                	mv	s3,a0
            continue;
        }
        if (*ptep != 0) {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc020207c:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage) {
ffffffffc020207e:	000b1c97          	auipc	s9,0xb1
ffffffffc0202082:	9bac8c93          	addi	s9,s9,-1606 # ffffffffc02b2a38 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202086:	000b1c17          	auipc	s8,0xb1
ffffffffc020208a:	9bac0c13          	addi	s8,s8,-1606 # ffffffffc02b2a40 <pages>
ffffffffc020208e:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc0202092:	000b1d17          	auipc	s10,0xb1
ffffffffc0202096:	9b6d0d13          	addi	s10,s10,-1610 # ffffffffc02b2a48 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020209a:	00200b37          	lui	s6,0x200
ffffffffc020209e:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc02020a2:	4601                	li	a2,0
ffffffffc02020a4:	85a2                	mv	a1,s0
ffffffffc02020a6:	854e                	mv	a0,s3
ffffffffc02020a8:	d73ff0ef          	jal	ra,ffffffffc0201e1a <get_pte>
ffffffffc02020ac:	84aa                	mv	s1,a0
        if (ptep == NULL) {
ffffffffc02020ae:	cd29                	beqz	a0,ffffffffc0202108 <unmap_range+0xc8>
        if (*ptep != 0) {
ffffffffc02020b0:	611c                	ld	a5,0(a0)
ffffffffc02020b2:	e395                	bnez	a5,ffffffffc02020d6 <unmap_range+0x96>
        start += PGSIZE;
ffffffffc02020b4:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02020b6:	ff2466e3          	bltu	s0,s2,ffffffffc02020a2 <unmap_range+0x62>
}
ffffffffc02020ba:	70a6                	ld	ra,104(sp)
ffffffffc02020bc:	7406                	ld	s0,96(sp)
ffffffffc02020be:	64e6                	ld	s1,88(sp)
ffffffffc02020c0:	6946                	ld	s2,80(sp)
ffffffffc02020c2:	69a6                	ld	s3,72(sp)
ffffffffc02020c4:	6a06                	ld	s4,64(sp)
ffffffffc02020c6:	7ae2                	ld	s5,56(sp)
ffffffffc02020c8:	7b42                	ld	s6,48(sp)
ffffffffc02020ca:	7ba2                	ld	s7,40(sp)
ffffffffc02020cc:	7c02                	ld	s8,32(sp)
ffffffffc02020ce:	6ce2                	ld	s9,24(sp)
ffffffffc02020d0:	6d42                	ld	s10,16(sp)
ffffffffc02020d2:	6165                	addi	sp,sp,112
ffffffffc02020d4:	8082                	ret
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc02020d6:	0017f713          	andi	a4,a5,1
ffffffffc02020da:	df69                	beqz	a4,ffffffffc02020b4 <unmap_range+0x74>
    if (PPN(pa) >= npage) {
ffffffffc02020dc:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc02020e0:	078a                	slli	a5,a5,0x2
ffffffffc02020e2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02020e4:	08e7ff63          	bgeu	a5,a4,ffffffffc0202182 <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc02020e8:	000c3503          	ld	a0,0(s8)
ffffffffc02020ec:	97de                	add	a5,a5,s7
ffffffffc02020ee:	079a                	slli	a5,a5,0x6
ffffffffc02020f0:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02020f2:	411c                	lw	a5,0(a0)
ffffffffc02020f4:	fff7871b          	addiw	a4,a5,-1
ffffffffc02020f8:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc02020fa:	cf11                	beqz	a4,ffffffffc0202116 <unmap_range+0xd6>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc02020fc:	0004b023          	sd	zero,0(s1)
// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la) {
    // flush_tlb();
    // The flush_tlb flush the entire TLB, is there any better way?
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202100:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc0202104:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202106:	bf45                	j	ffffffffc02020b6 <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202108:	945a                	add	s0,s0,s6
ffffffffc020210a:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc020210e:	d455                	beqz	s0,ffffffffc02020ba <unmap_range+0x7a>
ffffffffc0202110:	f92469e3          	bltu	s0,s2,ffffffffc02020a2 <unmap_range+0x62>
ffffffffc0202114:	b75d                	j	ffffffffc02020ba <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202116:	100027f3          	csrr	a5,sstatus
ffffffffc020211a:	8b89                	andi	a5,a5,2
ffffffffc020211c:	e799                	bnez	a5,ffffffffc020212a <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc020211e:	000d3783          	ld	a5,0(s10)
ffffffffc0202122:	4585                	li	a1,1
ffffffffc0202124:	739c                	ld	a5,32(a5)
ffffffffc0202126:	9782                	jalr	a5
    if (flag) {
ffffffffc0202128:	bfd1                	j	ffffffffc02020fc <unmap_range+0xbc>
ffffffffc020212a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020212c:	d1afe0ef          	jal	ra,ffffffffc0200646 <intr_disable>
ffffffffc0202130:	000d3783          	ld	a5,0(s10)
ffffffffc0202134:	6522                	ld	a0,8(sp)
ffffffffc0202136:	4585                	li	a1,1
ffffffffc0202138:	739c                	ld	a5,32(a5)
ffffffffc020213a:	9782                	jalr	a5
        intr_enable();
ffffffffc020213c:	d04fe0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0202140:	bf75                	j	ffffffffc02020fc <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202142:	00005697          	auipc	a3,0x5
ffffffffc0202146:	3d668693          	addi	a3,a3,982 # ffffffffc0207518 <default_pmm_manager+0x160>
ffffffffc020214a:	00005617          	auipc	a2,0x5
ffffffffc020214e:	b7660613          	addi	a2,a2,-1162 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202152:	10f00593          	li	a1,271
ffffffffc0202156:	00005517          	auipc	a0,0x5
ffffffffc020215a:	3b250513          	addi	a0,a0,946 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc020215e:	b1cfe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0202162:	00005697          	auipc	a3,0x5
ffffffffc0202166:	3e668693          	addi	a3,a3,998 # ffffffffc0207548 <default_pmm_manager+0x190>
ffffffffc020216a:	00005617          	auipc	a2,0x5
ffffffffc020216e:	b5660613          	addi	a2,a2,-1194 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202172:	11000593          	li	a1,272
ffffffffc0202176:	00005517          	auipc	a0,0x5
ffffffffc020217a:	39250513          	addi	a0,a0,914 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc020217e:	afcfe0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc0202182:	b55ff0ef          	jal	ra,ffffffffc0201cd6 <pa2page.part.0>

ffffffffc0202186 <exit_range>:
void exit_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc0202186:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202188:	00c5e7b3          	or	a5,a1,a2
void exit_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc020218c:	fc86                	sd	ra,120(sp)
ffffffffc020218e:	f8a2                	sd	s0,112(sp)
ffffffffc0202190:	f4a6                	sd	s1,104(sp)
ffffffffc0202192:	f0ca                	sd	s2,96(sp)
ffffffffc0202194:	ecce                	sd	s3,88(sp)
ffffffffc0202196:	e8d2                	sd	s4,80(sp)
ffffffffc0202198:	e4d6                	sd	s5,72(sp)
ffffffffc020219a:	e0da                	sd	s6,64(sp)
ffffffffc020219c:	fc5e                	sd	s7,56(sp)
ffffffffc020219e:	f862                	sd	s8,48(sp)
ffffffffc02021a0:	f466                	sd	s9,40(sp)
ffffffffc02021a2:	f06a                	sd	s10,32(sp)
ffffffffc02021a4:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021a6:	17d2                	slli	a5,a5,0x34
ffffffffc02021a8:	20079a63          	bnez	a5,ffffffffc02023bc <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc02021ac:	002007b7          	lui	a5,0x200
ffffffffc02021b0:	24f5e463          	bltu	a1,a5,ffffffffc02023f8 <exit_range+0x272>
ffffffffc02021b4:	8ab2                	mv	s5,a2
ffffffffc02021b6:	24c5f163          	bgeu	a1,a2,ffffffffc02023f8 <exit_range+0x272>
ffffffffc02021ba:	4785                	li	a5,1
ffffffffc02021bc:	07fe                	slli	a5,a5,0x1f
ffffffffc02021be:	22c7ed63          	bltu	a5,a2,ffffffffc02023f8 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc02021c2:	c00009b7          	lui	s3,0xc0000
ffffffffc02021c6:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc02021ca:	ffe00937          	lui	s2,0xffe00
ffffffffc02021ce:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc02021d2:	5cfd                	li	s9,-1
ffffffffc02021d4:	8c2a                	mv	s8,a0
ffffffffc02021d6:	0125f933          	and	s2,a1,s2
ffffffffc02021da:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage) {
ffffffffc02021dc:	000b1d17          	auipc	s10,0xb1
ffffffffc02021e0:	85cd0d13          	addi	s10,s10,-1956 # ffffffffc02b2a38 <npage>
    return KADDR(page2pa(page));
ffffffffc02021e4:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc02021e8:	000b1717          	auipc	a4,0xb1
ffffffffc02021ec:	85870713          	addi	a4,a4,-1960 # ffffffffc02b2a40 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc02021f0:	000b1d97          	auipc	s11,0xb1
ffffffffc02021f4:	858d8d93          	addi	s11,s11,-1960 # ffffffffc02b2a48 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc02021f8:	c0000437          	lui	s0,0xc0000
ffffffffc02021fc:	944e                	add	s0,s0,s3
ffffffffc02021fe:	8079                	srli	s0,s0,0x1e
ffffffffc0202200:	1ff47413          	andi	s0,s0,511
ffffffffc0202204:	040e                	slli	s0,s0,0x3
ffffffffc0202206:	9462                	add	s0,s0,s8
ffffffffc0202208:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4eb8>
        if (pde1&PTE_V){
ffffffffc020220c:	001a7793          	andi	a5,s4,1
ffffffffc0202210:	eb99                	bnez	a5,ffffffffc0202226 <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc0202212:	12098463          	beqz	s3,ffffffffc020233a <exit_range+0x1b4>
ffffffffc0202216:	400007b7          	lui	a5,0x40000
ffffffffc020221a:	97ce                	add	a5,a5,s3
ffffffffc020221c:	894e                	mv	s2,s3
ffffffffc020221e:	1159fe63          	bgeu	s3,s5,ffffffffc020233a <exit_range+0x1b4>
ffffffffc0202222:	89be                	mv	s3,a5
ffffffffc0202224:	bfd1                	j	ffffffffc02021f8 <exit_range+0x72>
    if (PPN(pa) >= npage) {
ffffffffc0202226:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc020222a:	0a0a                	slli	s4,s4,0x2
ffffffffc020222c:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202230:	1cfa7263          	bgeu	s4,a5,ffffffffc02023f4 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202234:	fff80637          	lui	a2,0xfff80
ffffffffc0202238:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc020223a:	000806b7          	lui	a3,0x80
ffffffffc020223e:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202240:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0202244:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202246:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202248:	18f5fa63          	bgeu	a1,a5,ffffffffc02023dc <exit_range+0x256>
ffffffffc020224c:	000b1817          	auipc	a6,0xb1
ffffffffc0202250:	80480813          	addi	a6,a6,-2044 # ffffffffc02b2a50 <va_pa_offset>
ffffffffc0202254:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc0202258:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc020225a:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc020225e:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc0202260:	00080337          	lui	t1,0x80
ffffffffc0202264:	6885                	lui	a7,0x1
ffffffffc0202266:	a819                	j	ffffffffc020227c <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc0202268:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc020226a:	002007b7          	lui	a5,0x200
ffffffffc020226e:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start+PDSIZE && d0start < end);
ffffffffc0202270:	08090c63          	beqz	s2,ffffffffc0202308 <exit_range+0x182>
ffffffffc0202274:	09397a63          	bgeu	s2,s3,ffffffffc0202308 <exit_range+0x182>
ffffffffc0202278:	0f597063          	bgeu	s2,s5,ffffffffc0202358 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc020227c:	01595493          	srli	s1,s2,0x15
ffffffffc0202280:	1ff4f493          	andi	s1,s1,511
ffffffffc0202284:	048e                	slli	s1,s1,0x3
ffffffffc0202286:	94da                	add	s1,s1,s6
ffffffffc0202288:	609c                	ld	a5,0(s1)
                if (pde0&PTE_V) {
ffffffffc020228a:	0017f693          	andi	a3,a5,1
ffffffffc020228e:	dee9                	beqz	a3,ffffffffc0202268 <exit_range+0xe2>
    if (PPN(pa) >= npage) {
ffffffffc0202290:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202294:	078a                	slli	a5,a5,0x2
ffffffffc0202296:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202298:	14b7fe63          	bgeu	a5,a1,ffffffffc02023f4 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc020229c:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc020229e:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc02022a2:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc02022a6:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02022aa:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02022ac:	12bef863          	bgeu	t4,a1,ffffffffc02023dc <exit_range+0x256>
ffffffffc02022b0:	00083783          	ld	a5,0(a6)
ffffffffc02022b4:	96be                	add	a3,a3,a5
                    for (int i = 0;i <NPTEENTRY;i++)
ffffffffc02022b6:	011685b3          	add	a1,a3,a7
                        if (pt[i]&PTE_V){
ffffffffc02022ba:	629c                	ld	a5,0(a3)
ffffffffc02022bc:	8b85                	andi	a5,a5,1
ffffffffc02022be:	f7d5                	bnez	a5,ffffffffc020226a <exit_range+0xe4>
                    for (int i = 0;i <NPTEENTRY;i++)
ffffffffc02022c0:	06a1                	addi	a3,a3,8
ffffffffc02022c2:	fed59ce3          	bne	a1,a3,ffffffffc02022ba <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc02022c6:	631c                	ld	a5,0(a4)
ffffffffc02022c8:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02022ca:	100027f3          	csrr	a5,sstatus
ffffffffc02022ce:	8b89                	andi	a5,a5,2
ffffffffc02022d0:	e7d9                	bnez	a5,ffffffffc020235e <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc02022d2:	000db783          	ld	a5,0(s11)
ffffffffc02022d6:	4585                	li	a1,1
ffffffffc02022d8:	e032                	sd	a2,0(sp)
ffffffffc02022da:	739c                	ld	a5,32(a5)
ffffffffc02022dc:	9782                	jalr	a5
    if (flag) {
ffffffffc02022de:	6602                	ld	a2,0(sp)
ffffffffc02022e0:	000b0817          	auipc	a6,0xb0
ffffffffc02022e4:	77080813          	addi	a6,a6,1904 # ffffffffc02b2a50 <va_pa_offset>
ffffffffc02022e8:	fff80e37          	lui	t3,0xfff80
ffffffffc02022ec:	00080337          	lui	t1,0x80
ffffffffc02022f0:	6885                	lui	a7,0x1
ffffffffc02022f2:	000b0717          	auipc	a4,0xb0
ffffffffc02022f6:	74e70713          	addi	a4,a4,1870 # ffffffffc02b2a40 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc02022fa:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc02022fe:	002007b7          	lui	a5,0x200
ffffffffc0202302:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start+PDSIZE && d0start < end);
ffffffffc0202304:	f60918e3          	bnez	s2,ffffffffc0202274 <exit_range+0xee>
            if (free_pd0) {
ffffffffc0202308:	f00b85e3          	beqz	s7,ffffffffc0202212 <exit_range+0x8c>
    if (PPN(pa) >= npage) {
ffffffffc020230c:	000d3783          	ld	a5,0(s10)
ffffffffc0202310:	0efa7263          	bgeu	s4,a5,ffffffffc02023f4 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202314:	6308                	ld	a0,0(a4)
ffffffffc0202316:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202318:	100027f3          	csrr	a5,sstatus
ffffffffc020231c:	8b89                	andi	a5,a5,2
ffffffffc020231e:	efad                	bnez	a5,ffffffffc0202398 <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc0202320:	000db783          	ld	a5,0(s11)
ffffffffc0202324:	4585                	li	a1,1
ffffffffc0202326:	739c                	ld	a5,32(a5)
ffffffffc0202328:	9782                	jalr	a5
ffffffffc020232a:	000b0717          	auipc	a4,0xb0
ffffffffc020232e:	71670713          	addi	a4,a4,1814 # ffffffffc02b2a40 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202332:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc0202336:	ee0990e3          	bnez	s3,ffffffffc0202216 <exit_range+0x90>
}
ffffffffc020233a:	70e6                	ld	ra,120(sp)
ffffffffc020233c:	7446                	ld	s0,112(sp)
ffffffffc020233e:	74a6                	ld	s1,104(sp)
ffffffffc0202340:	7906                	ld	s2,96(sp)
ffffffffc0202342:	69e6                	ld	s3,88(sp)
ffffffffc0202344:	6a46                	ld	s4,80(sp)
ffffffffc0202346:	6aa6                	ld	s5,72(sp)
ffffffffc0202348:	6b06                	ld	s6,64(sp)
ffffffffc020234a:	7be2                	ld	s7,56(sp)
ffffffffc020234c:	7c42                	ld	s8,48(sp)
ffffffffc020234e:	7ca2                	ld	s9,40(sp)
ffffffffc0202350:	7d02                	ld	s10,32(sp)
ffffffffc0202352:	6de2                	ld	s11,24(sp)
ffffffffc0202354:	6109                	addi	sp,sp,128
ffffffffc0202356:	8082                	ret
            if (free_pd0) {
ffffffffc0202358:	ea0b8fe3          	beqz	s7,ffffffffc0202216 <exit_range+0x90>
ffffffffc020235c:	bf45                	j	ffffffffc020230c <exit_range+0x186>
ffffffffc020235e:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc0202360:	e42a                	sd	a0,8(sp)
ffffffffc0202362:	ae4fe0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202366:	000db783          	ld	a5,0(s11)
ffffffffc020236a:	6522                	ld	a0,8(sp)
ffffffffc020236c:	4585                	li	a1,1
ffffffffc020236e:	739c                	ld	a5,32(a5)
ffffffffc0202370:	9782                	jalr	a5
        intr_enable();
ffffffffc0202372:	acefe0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0202376:	6602                	ld	a2,0(sp)
ffffffffc0202378:	000b0717          	auipc	a4,0xb0
ffffffffc020237c:	6c870713          	addi	a4,a4,1736 # ffffffffc02b2a40 <pages>
ffffffffc0202380:	6885                	lui	a7,0x1
ffffffffc0202382:	00080337          	lui	t1,0x80
ffffffffc0202386:	fff80e37          	lui	t3,0xfff80
ffffffffc020238a:	000b0817          	auipc	a6,0xb0
ffffffffc020238e:	6c680813          	addi	a6,a6,1734 # ffffffffc02b2a50 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202392:	0004b023          	sd	zero,0(s1)
ffffffffc0202396:	b7a5                	j	ffffffffc02022fe <exit_range+0x178>
ffffffffc0202398:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc020239a:	aacfe0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020239e:	000db783          	ld	a5,0(s11)
ffffffffc02023a2:	6502                	ld	a0,0(sp)
ffffffffc02023a4:	4585                	li	a1,1
ffffffffc02023a6:	739c                	ld	a5,32(a5)
ffffffffc02023a8:	9782                	jalr	a5
        intr_enable();
ffffffffc02023aa:	a96fe0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc02023ae:	000b0717          	auipc	a4,0xb0
ffffffffc02023b2:	69270713          	addi	a4,a4,1682 # ffffffffc02b2a40 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc02023b6:	00043023          	sd	zero,0(s0)
ffffffffc02023ba:	bfb5                	j	ffffffffc0202336 <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02023bc:	00005697          	auipc	a3,0x5
ffffffffc02023c0:	15c68693          	addi	a3,a3,348 # ffffffffc0207518 <default_pmm_manager+0x160>
ffffffffc02023c4:	00005617          	auipc	a2,0x5
ffffffffc02023c8:	8fc60613          	addi	a2,a2,-1796 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02023cc:	12000593          	li	a1,288
ffffffffc02023d0:	00005517          	auipc	a0,0x5
ffffffffc02023d4:	13850513          	addi	a0,a0,312 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc02023d8:	8a2fe0ef          	jal	ra,ffffffffc020047a <__panic>
    return KADDR(page2pa(page));
ffffffffc02023dc:	00005617          	auipc	a2,0x5
ffffffffc02023e0:	01460613          	addi	a2,a2,20 # ffffffffc02073f0 <default_pmm_manager+0x38>
ffffffffc02023e4:	06900593          	li	a1,105
ffffffffc02023e8:	00005517          	auipc	a0,0x5
ffffffffc02023ec:	03050513          	addi	a0,a0,48 # ffffffffc0207418 <default_pmm_manager+0x60>
ffffffffc02023f0:	88afe0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc02023f4:	8e3ff0ef          	jal	ra,ffffffffc0201cd6 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc02023f8:	00005697          	auipc	a3,0x5
ffffffffc02023fc:	15068693          	addi	a3,a3,336 # ffffffffc0207548 <default_pmm_manager+0x190>
ffffffffc0202400:	00005617          	auipc	a2,0x5
ffffffffc0202404:	8c060613          	addi	a2,a2,-1856 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202408:	12100593          	li	a1,289
ffffffffc020240c:	00005517          	auipc	a0,0x5
ffffffffc0202410:	0fc50513          	addi	a0,a0,252 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202414:	866fe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0202418 <page_remove>:
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0202418:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020241a:	4601                	li	a2,0
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc020241c:	ec26                	sd	s1,24(sp)
ffffffffc020241e:	f406                	sd	ra,40(sp)
ffffffffc0202420:	f022                	sd	s0,32(sp)
ffffffffc0202422:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202424:	9f7ff0ef          	jal	ra,ffffffffc0201e1a <get_pte>
    if (ptep != NULL) {
ffffffffc0202428:	c511                	beqz	a0,ffffffffc0202434 <page_remove+0x1c>
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc020242a:	611c                	ld	a5,0(a0)
ffffffffc020242c:	842a                	mv	s0,a0
ffffffffc020242e:	0017f713          	andi	a4,a5,1
ffffffffc0202432:	e711                	bnez	a4,ffffffffc020243e <page_remove+0x26>
}
ffffffffc0202434:	70a2                	ld	ra,40(sp)
ffffffffc0202436:	7402                	ld	s0,32(sp)
ffffffffc0202438:	64e2                	ld	s1,24(sp)
ffffffffc020243a:	6145                	addi	sp,sp,48
ffffffffc020243c:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020243e:	078a                	slli	a5,a5,0x2
ffffffffc0202440:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202442:	000b0717          	auipc	a4,0xb0
ffffffffc0202446:	5f673703          	ld	a4,1526(a4) # ffffffffc02b2a38 <npage>
ffffffffc020244a:	06e7f363          	bgeu	a5,a4,ffffffffc02024b0 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc020244e:	fff80537          	lui	a0,0xfff80
ffffffffc0202452:	97aa                	add	a5,a5,a0
ffffffffc0202454:	079a                	slli	a5,a5,0x6
ffffffffc0202456:	000b0517          	auipc	a0,0xb0
ffffffffc020245a:	5ea53503          	ld	a0,1514(a0) # ffffffffc02b2a40 <pages>
ffffffffc020245e:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202460:	411c                	lw	a5,0(a0)
ffffffffc0202462:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202466:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0202468:	cb11                	beqz	a4,ffffffffc020247c <page_remove+0x64>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc020246a:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020246e:	12048073          	sfence.vma	s1
}
ffffffffc0202472:	70a2                	ld	ra,40(sp)
ffffffffc0202474:	7402                	ld	s0,32(sp)
ffffffffc0202476:	64e2                	ld	s1,24(sp)
ffffffffc0202478:	6145                	addi	sp,sp,48
ffffffffc020247a:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020247c:	100027f3          	csrr	a5,sstatus
ffffffffc0202480:	8b89                	andi	a5,a5,2
ffffffffc0202482:	eb89                	bnez	a5,ffffffffc0202494 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0202484:	000b0797          	auipc	a5,0xb0
ffffffffc0202488:	5c47b783          	ld	a5,1476(a5) # ffffffffc02b2a48 <pmm_manager>
ffffffffc020248c:	739c                	ld	a5,32(a5)
ffffffffc020248e:	4585                	li	a1,1
ffffffffc0202490:	9782                	jalr	a5
    if (flag) {
ffffffffc0202492:	bfe1                	j	ffffffffc020246a <page_remove+0x52>
        intr_disable();
ffffffffc0202494:	e42a                	sd	a0,8(sp)
ffffffffc0202496:	9b0fe0ef          	jal	ra,ffffffffc0200646 <intr_disable>
ffffffffc020249a:	000b0797          	auipc	a5,0xb0
ffffffffc020249e:	5ae7b783          	ld	a5,1454(a5) # ffffffffc02b2a48 <pmm_manager>
ffffffffc02024a2:	739c                	ld	a5,32(a5)
ffffffffc02024a4:	6522                	ld	a0,8(sp)
ffffffffc02024a6:	4585                	li	a1,1
ffffffffc02024a8:	9782                	jalr	a5
        intr_enable();
ffffffffc02024aa:	996fe0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc02024ae:	bf75                	j	ffffffffc020246a <page_remove+0x52>
ffffffffc02024b0:	827ff0ef          	jal	ra,ffffffffc0201cd6 <pa2page.part.0>

ffffffffc02024b4 <page_insert>:
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc02024b4:	7139                	addi	sp,sp,-64
ffffffffc02024b6:	e852                	sd	s4,16(sp)
ffffffffc02024b8:	8a32                	mv	s4,a2
ffffffffc02024ba:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02024bc:	4605                	li	a2,1
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc02024be:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02024c0:	85d2                	mv	a1,s4
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc02024c2:	f426                	sd	s1,40(sp)
ffffffffc02024c4:	fc06                	sd	ra,56(sp)
ffffffffc02024c6:	f04a                	sd	s2,32(sp)
ffffffffc02024c8:	ec4e                	sd	s3,24(sp)
ffffffffc02024ca:	e456                	sd	s5,8(sp)
ffffffffc02024cc:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02024ce:	94dff0ef          	jal	ra,ffffffffc0201e1a <get_pte>
    if (ptep == NULL) {
ffffffffc02024d2:	c961                	beqz	a0,ffffffffc02025a2 <page_insert+0xee>
    page->ref += 1;
ffffffffc02024d4:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V) {
ffffffffc02024d6:	611c                	ld	a5,0(a0)
ffffffffc02024d8:	89aa                	mv	s3,a0
ffffffffc02024da:	0016871b          	addiw	a4,a3,1
ffffffffc02024de:	c018                	sw	a4,0(s0)
ffffffffc02024e0:	0017f713          	andi	a4,a5,1
ffffffffc02024e4:	ef05                	bnez	a4,ffffffffc020251c <page_insert+0x68>
    return page - pages + nbase;
ffffffffc02024e6:	000b0717          	auipc	a4,0xb0
ffffffffc02024ea:	55a73703          	ld	a4,1370(a4) # ffffffffc02b2a40 <pages>
ffffffffc02024ee:	8c19                	sub	s0,s0,a4
ffffffffc02024f0:	000807b7          	lui	a5,0x80
ffffffffc02024f4:	8419                	srai	s0,s0,0x6
ffffffffc02024f6:	943e                	add	s0,s0,a5
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02024f8:	042a                	slli	s0,s0,0xa
ffffffffc02024fa:	8cc1                	or	s1,s1,s0
ffffffffc02024fc:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0202500:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4eb8>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202504:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0202508:	4501                	li	a0,0
}
ffffffffc020250a:	70e2                	ld	ra,56(sp)
ffffffffc020250c:	7442                	ld	s0,48(sp)
ffffffffc020250e:	74a2                	ld	s1,40(sp)
ffffffffc0202510:	7902                	ld	s2,32(sp)
ffffffffc0202512:	69e2                	ld	s3,24(sp)
ffffffffc0202514:	6a42                	ld	s4,16(sp)
ffffffffc0202516:	6aa2                	ld	s5,8(sp)
ffffffffc0202518:	6121                	addi	sp,sp,64
ffffffffc020251a:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020251c:	078a                	slli	a5,a5,0x2
ffffffffc020251e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202520:	000b0717          	auipc	a4,0xb0
ffffffffc0202524:	51873703          	ld	a4,1304(a4) # ffffffffc02b2a38 <npage>
ffffffffc0202528:	06e7ff63          	bgeu	a5,a4,ffffffffc02025a6 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc020252c:	000b0a97          	auipc	s5,0xb0
ffffffffc0202530:	514a8a93          	addi	s5,s5,1300 # ffffffffc02b2a40 <pages>
ffffffffc0202534:	000ab703          	ld	a4,0(s5)
ffffffffc0202538:	fff80937          	lui	s2,0xfff80
ffffffffc020253c:	993e                	add	s2,s2,a5
ffffffffc020253e:	091a                	slli	s2,s2,0x6
ffffffffc0202540:	993a                	add	s2,s2,a4
        if (p == page) {
ffffffffc0202542:	01240c63          	beq	s0,s2,ffffffffc020255a <page_insert+0xa6>
    page->ref -= 1;
ffffffffc0202546:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fccd564>
ffffffffc020254a:	fff7869b          	addiw	a3,a5,-1
ffffffffc020254e:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc0202552:	c691                	beqz	a3,ffffffffc020255e <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202554:	120a0073          	sfence.vma	s4
}
ffffffffc0202558:	bf59                	j	ffffffffc02024ee <page_insert+0x3a>
ffffffffc020255a:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc020255c:	bf49                	j	ffffffffc02024ee <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020255e:	100027f3          	csrr	a5,sstatus
ffffffffc0202562:	8b89                	andi	a5,a5,2
ffffffffc0202564:	ef91                	bnez	a5,ffffffffc0202580 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc0202566:	000b0797          	auipc	a5,0xb0
ffffffffc020256a:	4e27b783          	ld	a5,1250(a5) # ffffffffc02b2a48 <pmm_manager>
ffffffffc020256e:	739c                	ld	a5,32(a5)
ffffffffc0202570:	4585                	li	a1,1
ffffffffc0202572:	854a                	mv	a0,s2
ffffffffc0202574:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0202576:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020257a:	120a0073          	sfence.vma	s4
ffffffffc020257e:	bf85                	j	ffffffffc02024ee <page_insert+0x3a>
        intr_disable();
ffffffffc0202580:	8c6fe0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202584:	000b0797          	auipc	a5,0xb0
ffffffffc0202588:	4c47b783          	ld	a5,1220(a5) # ffffffffc02b2a48 <pmm_manager>
ffffffffc020258c:	739c                	ld	a5,32(a5)
ffffffffc020258e:	4585                	li	a1,1
ffffffffc0202590:	854a                	mv	a0,s2
ffffffffc0202592:	9782                	jalr	a5
        intr_enable();
ffffffffc0202594:	8acfe0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0202598:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020259c:	120a0073          	sfence.vma	s4
ffffffffc02025a0:	b7b9                	j	ffffffffc02024ee <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc02025a2:	5571                	li	a0,-4
ffffffffc02025a4:	b79d                	j	ffffffffc020250a <page_insert+0x56>
ffffffffc02025a6:	f30ff0ef          	jal	ra,ffffffffc0201cd6 <pa2page.part.0>

ffffffffc02025aa <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc02025aa:	00005797          	auipc	a5,0x5
ffffffffc02025ae:	e0e78793          	addi	a5,a5,-498 # ffffffffc02073b8 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02025b2:	638c                	ld	a1,0(a5)
void pmm_init(void) {
ffffffffc02025b4:	711d                	addi	sp,sp,-96
ffffffffc02025b6:	ec5e                	sd	s7,24(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02025b8:	00005517          	auipc	a0,0x5
ffffffffc02025bc:	fa850513          	addi	a0,a0,-88 # ffffffffc0207560 <default_pmm_manager+0x1a8>
    pmm_manager = &default_pmm_manager;
ffffffffc02025c0:	000b0b97          	auipc	s7,0xb0
ffffffffc02025c4:	488b8b93          	addi	s7,s7,1160 # ffffffffc02b2a48 <pmm_manager>
void pmm_init(void) {
ffffffffc02025c8:	ec86                	sd	ra,88(sp)
ffffffffc02025ca:	e4a6                	sd	s1,72(sp)
ffffffffc02025cc:	fc4e                	sd	s3,56(sp)
ffffffffc02025ce:	f05a                	sd	s6,32(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02025d0:	00fbb023          	sd	a5,0(s7)
void pmm_init(void) {
ffffffffc02025d4:	e8a2                	sd	s0,80(sp)
ffffffffc02025d6:	e0ca                	sd	s2,64(sp)
ffffffffc02025d8:	f852                	sd	s4,48(sp)
ffffffffc02025da:	f456                	sd	s5,40(sp)
ffffffffc02025dc:	e862                	sd	s8,16(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02025de:	ba3fd0ef          	jal	ra,ffffffffc0200180 <cprintf>
    pmm_manager->init();
ffffffffc02025e2:	000bb783          	ld	a5,0(s7)
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc02025e6:	000b0997          	auipc	s3,0xb0
ffffffffc02025ea:	46a98993          	addi	s3,s3,1130 # ffffffffc02b2a50 <va_pa_offset>
    npage = maxpa / PGSIZE;
ffffffffc02025ee:	000b0497          	auipc	s1,0xb0
ffffffffc02025f2:	44a48493          	addi	s1,s1,1098 # ffffffffc02b2a38 <npage>
    pmm_manager->init();
ffffffffc02025f6:	679c                	ld	a5,8(a5)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02025f8:	000b0b17          	auipc	s6,0xb0
ffffffffc02025fc:	448b0b13          	addi	s6,s6,1096 # ffffffffc02b2a40 <pages>
    pmm_manager->init();
ffffffffc0202600:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0202602:	57f5                	li	a5,-3
ffffffffc0202604:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0202606:	00005517          	auipc	a0,0x5
ffffffffc020260a:	f7250513          	addi	a0,a0,-142 # ffffffffc0207578 <default_pmm_manager+0x1c0>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc020260e:	00f9b023          	sd	a5,0(s3)
    cprintf("physcial memory map:\n");
ffffffffc0202612:	b6ffd0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0202616:	46c5                	li	a3,17
ffffffffc0202618:	06ee                	slli	a3,a3,0x1b
ffffffffc020261a:	40100613          	li	a2,1025
ffffffffc020261e:	07e005b7          	lui	a1,0x7e00
ffffffffc0202622:	16fd                	addi	a3,a3,-1
ffffffffc0202624:	0656                	slli	a2,a2,0x15
ffffffffc0202626:	00005517          	auipc	a0,0x5
ffffffffc020262a:	f6a50513          	addi	a0,a0,-150 # ffffffffc0207590 <default_pmm_manager+0x1d8>
ffffffffc020262e:	b53fd0ef          	jal	ra,ffffffffc0200180 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202632:	777d                	lui	a4,0xfffff
ffffffffc0202634:	000b1797          	auipc	a5,0xb1
ffffffffc0202638:	46778793          	addi	a5,a5,1127 # ffffffffc02b3a9b <end+0xfff>
ffffffffc020263c:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc020263e:	00088737          	lui	a4,0x88
ffffffffc0202642:	e098                	sd	a4,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202644:	00fb3023          	sd	a5,0(s6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0202648:	4701                	li	a4,0
ffffffffc020264a:	4585                	li	a1,1
ffffffffc020264c:	fff80837          	lui	a6,0xfff80
ffffffffc0202650:	a019                	j	ffffffffc0202656 <pmm_init+0xac>
        SetPageReserved(pages + i);
ffffffffc0202652:	000b3783          	ld	a5,0(s6)
ffffffffc0202656:	00671693          	slli	a3,a4,0x6
ffffffffc020265a:	97b6                	add	a5,a5,a3
ffffffffc020265c:	07a1                	addi	a5,a5,8
ffffffffc020265e:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0202662:	6090                	ld	a2,0(s1)
ffffffffc0202664:	0705                	addi	a4,a4,1
ffffffffc0202666:	010607b3          	add	a5,a2,a6
ffffffffc020266a:	fef764e3          	bltu	a4,a5,ffffffffc0202652 <pmm_init+0xa8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020266e:	000b3503          	ld	a0,0(s6)
ffffffffc0202672:	079a                	slli	a5,a5,0x6
ffffffffc0202674:	c0200737          	lui	a4,0xc0200
ffffffffc0202678:	00f506b3          	add	a3,a0,a5
ffffffffc020267c:	60e6e563          	bltu	a3,a4,ffffffffc0202c86 <pmm_init+0x6dc>
ffffffffc0202680:	0009b583          	ld	a1,0(s3)
    if (freemem < mem_end) {
ffffffffc0202684:	4745                	li	a4,17
ffffffffc0202686:	076e                	slli	a4,a4,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202688:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end) {
ffffffffc020268a:	4ae6e563          	bltu	a3,a4,ffffffffc0202b34 <pmm_init+0x58a>
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc020268e:	00005517          	auipc	a0,0x5
ffffffffc0202692:	f2a50513          	addi	a0,a0,-214 # ffffffffc02075b8 <default_pmm_manager+0x200>
ffffffffc0202696:	aebfd0ef          	jal	ra,ffffffffc0200180 <cprintf>

    return page;
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc020269a:	000bb783          	ld	a5,0(s7)
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc020269e:	000b0917          	auipc	s2,0xb0
ffffffffc02026a2:	39290913          	addi	s2,s2,914 # ffffffffc02b2a30 <boot_pgdir>
    pmm_manager->check();
ffffffffc02026a6:	7b9c                	ld	a5,48(a5)
ffffffffc02026a8:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02026aa:	00005517          	auipc	a0,0x5
ffffffffc02026ae:	f2650513          	addi	a0,a0,-218 # ffffffffc02075d0 <default_pmm_manager+0x218>
ffffffffc02026b2:	acffd0ef          	jal	ra,ffffffffc0200180 <cprintf>
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc02026b6:	00009697          	auipc	a3,0x9
ffffffffc02026ba:	94a68693          	addi	a3,a3,-1718 # ffffffffc020b000 <boot_page_table_sv39>
ffffffffc02026be:	00d93023          	sd	a3,0(s2)
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc02026c2:	c02007b7          	lui	a5,0xc0200
ffffffffc02026c6:	5cf6ec63          	bltu	a3,a5,ffffffffc0202c9e <pmm_init+0x6f4>
ffffffffc02026ca:	0009b783          	ld	a5,0(s3)
ffffffffc02026ce:	8e9d                	sub	a3,a3,a5
ffffffffc02026d0:	000b0797          	auipc	a5,0xb0
ffffffffc02026d4:	34d7bc23          	sd	a3,856(a5) # ffffffffc02b2a28 <boot_cr3>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02026d8:	100027f3          	csrr	a5,sstatus
ffffffffc02026dc:	8b89                	andi	a5,a5,2
ffffffffc02026de:	48079263          	bnez	a5,ffffffffc0202b62 <pmm_init+0x5b8>
        ret = pmm_manager->nr_free_pages();
ffffffffc02026e2:	000bb783          	ld	a5,0(s7)
ffffffffc02026e6:	779c                	ld	a5,40(a5)
ffffffffc02026e8:	9782                	jalr	a5
ffffffffc02026ea:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02026ec:	6098                	ld	a4,0(s1)
ffffffffc02026ee:	c80007b7          	lui	a5,0xc8000
ffffffffc02026f2:	83b1                	srli	a5,a5,0xc
ffffffffc02026f4:	5ee7e163          	bltu	a5,a4,ffffffffc0202cd6 <pmm_init+0x72c>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc02026f8:	00093503          	ld	a0,0(s2)
ffffffffc02026fc:	5a050d63          	beqz	a0,ffffffffc0202cb6 <pmm_init+0x70c>
ffffffffc0202700:	03451793          	slli	a5,a0,0x34
ffffffffc0202704:	5a079963          	bnez	a5,ffffffffc0202cb6 <pmm_init+0x70c>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0202708:	4601                	li	a2,0
ffffffffc020270a:	4581                	li	a1,0
ffffffffc020270c:	8e1ff0ef          	jal	ra,ffffffffc0201fec <get_page>
ffffffffc0202710:	62051563          	bnez	a0,ffffffffc0202d3a <pmm_init+0x790>

    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc0202714:	4505                	li	a0,1
ffffffffc0202716:	df8ff0ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc020271a:	8a2a                	mv	s4,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc020271c:	00093503          	ld	a0,0(s2)
ffffffffc0202720:	4681                	li	a3,0
ffffffffc0202722:	4601                	li	a2,0
ffffffffc0202724:	85d2                	mv	a1,s4
ffffffffc0202726:	d8fff0ef          	jal	ra,ffffffffc02024b4 <page_insert>
ffffffffc020272a:	5e051863          	bnez	a0,ffffffffc0202d1a <pmm_init+0x770>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc020272e:	00093503          	ld	a0,0(s2)
ffffffffc0202732:	4601                	li	a2,0
ffffffffc0202734:	4581                	li	a1,0
ffffffffc0202736:	ee4ff0ef          	jal	ra,ffffffffc0201e1a <get_pte>
ffffffffc020273a:	5c050063          	beqz	a0,ffffffffc0202cfa <pmm_init+0x750>
    assert(pte2page(*ptep) == p1);
ffffffffc020273e:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0202740:	0017f713          	andi	a4,a5,1
ffffffffc0202744:	5a070963          	beqz	a4,ffffffffc0202cf6 <pmm_init+0x74c>
    if (PPN(pa) >= npage) {
ffffffffc0202748:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020274a:	078a                	slli	a5,a5,0x2
ffffffffc020274c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020274e:	52e7fa63          	bgeu	a5,a4,ffffffffc0202c82 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0202752:	000b3683          	ld	a3,0(s6)
ffffffffc0202756:	fff80637          	lui	a2,0xfff80
ffffffffc020275a:	97b2                	add	a5,a5,a2
ffffffffc020275c:	079a                	slli	a5,a5,0x6
ffffffffc020275e:	97b6                	add	a5,a5,a3
ffffffffc0202760:	10fa16e3          	bne	s4,a5,ffffffffc020306c <pmm_init+0xac2>
    assert(page_ref(p1) == 1);
ffffffffc0202764:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bd0>
ffffffffc0202768:	4785                	li	a5,1
ffffffffc020276a:	12f69de3          	bne	a3,a5,ffffffffc02030a4 <pmm_init+0xafa>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc020276e:	00093503          	ld	a0,0(s2)
ffffffffc0202772:	77fd                	lui	a5,0xfffff
ffffffffc0202774:	6114                	ld	a3,0(a0)
ffffffffc0202776:	068a                	slli	a3,a3,0x2
ffffffffc0202778:	8efd                	and	a3,a3,a5
ffffffffc020277a:	00c6d613          	srli	a2,a3,0xc
ffffffffc020277e:	10e677e3          	bgeu	a2,a4,ffffffffc020308c <pmm_init+0xae2>
ffffffffc0202782:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202786:	96e2                	add	a3,a3,s8
ffffffffc0202788:	0006ba83          	ld	s5,0(a3)
ffffffffc020278c:	0a8a                	slli	s5,s5,0x2
ffffffffc020278e:	00fafab3          	and	s5,s5,a5
ffffffffc0202792:	00cad793          	srli	a5,s5,0xc
ffffffffc0202796:	62e7f263          	bgeu	a5,a4,ffffffffc0202dba <pmm_init+0x810>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc020279a:	4601                	li	a2,0
ffffffffc020279c:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020279e:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02027a0:	e7aff0ef          	jal	ra,ffffffffc0201e1a <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02027a4:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02027a6:	5f551a63          	bne	a0,s5,ffffffffc0202d9a <pmm_init+0x7f0>

    p2 = alloc_page();
ffffffffc02027aa:	4505                	li	a0,1
ffffffffc02027ac:	d62ff0ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc02027b0:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02027b2:	00093503          	ld	a0,0(s2)
ffffffffc02027b6:	46d1                	li	a3,20
ffffffffc02027b8:	6605                	lui	a2,0x1
ffffffffc02027ba:	85d6                	mv	a1,s5
ffffffffc02027bc:	cf9ff0ef          	jal	ra,ffffffffc02024b4 <page_insert>
ffffffffc02027c0:	58051d63          	bnez	a0,ffffffffc0202d5a <pmm_init+0x7b0>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02027c4:	00093503          	ld	a0,0(s2)
ffffffffc02027c8:	4601                	li	a2,0
ffffffffc02027ca:	6585                	lui	a1,0x1
ffffffffc02027cc:	e4eff0ef          	jal	ra,ffffffffc0201e1a <get_pte>
ffffffffc02027d0:	0e050ae3          	beqz	a0,ffffffffc02030c4 <pmm_init+0xb1a>
    assert(*ptep & PTE_U);
ffffffffc02027d4:	611c                	ld	a5,0(a0)
ffffffffc02027d6:	0107f713          	andi	a4,a5,16
ffffffffc02027da:	6e070d63          	beqz	a4,ffffffffc0202ed4 <pmm_init+0x92a>
    assert(*ptep & PTE_W);
ffffffffc02027de:	8b91                	andi	a5,a5,4
ffffffffc02027e0:	6a078a63          	beqz	a5,ffffffffc0202e94 <pmm_init+0x8ea>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc02027e4:	00093503          	ld	a0,0(s2)
ffffffffc02027e8:	611c                	ld	a5,0(a0)
ffffffffc02027ea:	8bc1                	andi	a5,a5,16
ffffffffc02027ec:	68078463          	beqz	a5,ffffffffc0202e74 <pmm_init+0x8ca>
    assert(page_ref(p2) == 1);
ffffffffc02027f0:	000aa703          	lw	a4,0(s5)
ffffffffc02027f4:	4785                	li	a5,1
ffffffffc02027f6:	58f71263          	bne	a4,a5,ffffffffc0202d7a <pmm_init+0x7d0>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc02027fa:	4681                	li	a3,0
ffffffffc02027fc:	6605                	lui	a2,0x1
ffffffffc02027fe:	85d2                	mv	a1,s4
ffffffffc0202800:	cb5ff0ef          	jal	ra,ffffffffc02024b4 <page_insert>
ffffffffc0202804:	62051863          	bnez	a0,ffffffffc0202e34 <pmm_init+0x88a>
    assert(page_ref(p1) == 2);
ffffffffc0202808:	000a2703          	lw	a4,0(s4)
ffffffffc020280c:	4789                	li	a5,2
ffffffffc020280e:	60f71363          	bne	a4,a5,ffffffffc0202e14 <pmm_init+0x86a>
    assert(page_ref(p2) == 0);
ffffffffc0202812:	000aa783          	lw	a5,0(s5)
ffffffffc0202816:	5c079f63          	bnez	a5,ffffffffc0202df4 <pmm_init+0x84a>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc020281a:	00093503          	ld	a0,0(s2)
ffffffffc020281e:	4601                	li	a2,0
ffffffffc0202820:	6585                	lui	a1,0x1
ffffffffc0202822:	df8ff0ef          	jal	ra,ffffffffc0201e1a <get_pte>
ffffffffc0202826:	5a050763          	beqz	a0,ffffffffc0202dd4 <pmm_init+0x82a>
    assert(pte2page(*ptep) == p1);
ffffffffc020282a:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc020282c:	00177793          	andi	a5,a4,1
ffffffffc0202830:	4c078363          	beqz	a5,ffffffffc0202cf6 <pmm_init+0x74c>
    if (PPN(pa) >= npage) {
ffffffffc0202834:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202836:	00271793          	slli	a5,a4,0x2
ffffffffc020283a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020283c:	44d7f363          	bgeu	a5,a3,ffffffffc0202c82 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0202840:	000b3683          	ld	a3,0(s6)
ffffffffc0202844:	fff80637          	lui	a2,0xfff80
ffffffffc0202848:	97b2                	add	a5,a5,a2
ffffffffc020284a:	079a                	slli	a5,a5,0x6
ffffffffc020284c:	97b6                	add	a5,a5,a3
ffffffffc020284e:	6efa1363          	bne	s4,a5,ffffffffc0202f34 <pmm_init+0x98a>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202852:	8b41                	andi	a4,a4,16
ffffffffc0202854:	6c071063          	bnez	a4,ffffffffc0202f14 <pmm_init+0x96a>

    page_remove(boot_pgdir, 0x0);
ffffffffc0202858:	00093503          	ld	a0,0(s2)
ffffffffc020285c:	4581                	li	a1,0
ffffffffc020285e:	bbbff0ef          	jal	ra,ffffffffc0202418 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202862:	000a2703          	lw	a4,0(s4)
ffffffffc0202866:	4785                	li	a5,1
ffffffffc0202868:	68f71663          	bne	a4,a5,ffffffffc0202ef4 <pmm_init+0x94a>
    assert(page_ref(p2) == 0);
ffffffffc020286c:	000aa783          	lw	a5,0(s5)
ffffffffc0202870:	74079e63          	bnez	a5,ffffffffc0202fcc <pmm_init+0xa22>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc0202874:	00093503          	ld	a0,0(s2)
ffffffffc0202878:	6585                	lui	a1,0x1
ffffffffc020287a:	b9fff0ef          	jal	ra,ffffffffc0202418 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc020287e:	000a2783          	lw	a5,0(s4)
ffffffffc0202882:	72079563          	bnez	a5,ffffffffc0202fac <pmm_init+0xa02>
    assert(page_ref(p2) == 0);
ffffffffc0202886:	000aa783          	lw	a5,0(s5)
ffffffffc020288a:	70079163          	bnez	a5,ffffffffc0202f8c <pmm_init+0x9e2>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc020288e:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0202892:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202894:	000a3683          	ld	a3,0(s4)
ffffffffc0202898:	068a                	slli	a3,a3,0x2
ffffffffc020289a:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc020289c:	3ee6f363          	bgeu	a3,a4,ffffffffc0202c82 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc02028a0:	fff807b7          	lui	a5,0xfff80
ffffffffc02028a4:	000b3503          	ld	a0,0(s6)
ffffffffc02028a8:	96be                	add	a3,a3,a5
ffffffffc02028aa:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc02028ac:	00d507b3          	add	a5,a0,a3
ffffffffc02028b0:	4390                	lw	a2,0(a5)
ffffffffc02028b2:	4785                	li	a5,1
ffffffffc02028b4:	6af61c63          	bne	a2,a5,ffffffffc0202f6c <pmm_init+0x9c2>
    return page - pages + nbase;
ffffffffc02028b8:	8699                	srai	a3,a3,0x6
ffffffffc02028ba:	000805b7          	lui	a1,0x80
ffffffffc02028be:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc02028c0:	00c69613          	slli	a2,a3,0xc
ffffffffc02028c4:	8231                	srli	a2,a2,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02028c6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02028c8:	68e67663          	bgeu	a2,a4,ffffffffc0202f54 <pmm_init+0x9aa>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc02028cc:	0009b603          	ld	a2,0(s3)
ffffffffc02028d0:	96b2                	add	a3,a3,a2
    return pa2page(PDE_ADDR(pde));
ffffffffc02028d2:	629c                	ld	a5,0(a3)
ffffffffc02028d4:	078a                	slli	a5,a5,0x2
ffffffffc02028d6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02028d8:	3ae7f563          	bgeu	a5,a4,ffffffffc0202c82 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc02028dc:	8f8d                	sub	a5,a5,a1
ffffffffc02028de:	079a                	slli	a5,a5,0x6
ffffffffc02028e0:	953e                	add	a0,a0,a5
ffffffffc02028e2:	100027f3          	csrr	a5,sstatus
ffffffffc02028e6:	8b89                	andi	a5,a5,2
ffffffffc02028e8:	2c079763          	bnez	a5,ffffffffc0202bb6 <pmm_init+0x60c>
        pmm_manager->free_pages(base, n);
ffffffffc02028ec:	000bb783          	ld	a5,0(s7)
ffffffffc02028f0:	4585                	li	a1,1
ffffffffc02028f2:	739c                	ld	a5,32(a5)
ffffffffc02028f4:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02028f6:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc02028fa:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02028fc:	078a                	slli	a5,a5,0x2
ffffffffc02028fe:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202900:	38e7f163          	bgeu	a5,a4,ffffffffc0202c82 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0202904:	000b3503          	ld	a0,0(s6)
ffffffffc0202908:	fff80737          	lui	a4,0xfff80
ffffffffc020290c:	97ba                	add	a5,a5,a4
ffffffffc020290e:	079a                	slli	a5,a5,0x6
ffffffffc0202910:	953e                	add	a0,a0,a5
ffffffffc0202912:	100027f3          	csrr	a5,sstatus
ffffffffc0202916:	8b89                	andi	a5,a5,2
ffffffffc0202918:	28079363          	bnez	a5,ffffffffc0202b9e <pmm_init+0x5f4>
ffffffffc020291c:	000bb783          	ld	a5,0(s7)
ffffffffc0202920:	4585                	li	a1,1
ffffffffc0202922:	739c                	ld	a5,32(a5)
ffffffffc0202924:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc0202926:	00093783          	ld	a5,0(s2)
ffffffffc020292a:	0007b023          	sd	zero,0(a5) # fffffffffff80000 <end+0x3fccd564>
  asm volatile("sfence.vma");
ffffffffc020292e:	12000073          	sfence.vma
ffffffffc0202932:	100027f3          	csrr	a5,sstatus
ffffffffc0202936:	8b89                	andi	a5,a5,2
ffffffffc0202938:	24079963          	bnez	a5,ffffffffc0202b8a <pmm_init+0x5e0>
        ret = pmm_manager->nr_free_pages();
ffffffffc020293c:	000bb783          	ld	a5,0(s7)
ffffffffc0202940:	779c                	ld	a5,40(a5)
ffffffffc0202942:	9782                	jalr	a5
ffffffffc0202944:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc0202946:	71441363          	bne	s0,s4,ffffffffc020304c <pmm_init+0xaa2>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc020294a:	00005517          	auipc	a0,0x5
ffffffffc020294e:	f6e50513          	addi	a0,a0,-146 # ffffffffc02078b8 <default_pmm_manager+0x500>
ffffffffc0202952:	82ffd0ef          	jal	ra,ffffffffc0200180 <cprintf>
ffffffffc0202956:	100027f3          	csrr	a5,sstatus
ffffffffc020295a:	8b89                	andi	a5,a5,2
ffffffffc020295c:	20079d63          	bnez	a5,ffffffffc0202b76 <pmm_init+0x5cc>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202960:	000bb783          	ld	a5,0(s7)
ffffffffc0202964:	779c                	ld	a5,40(a5)
ffffffffc0202966:	9782                	jalr	a5
ffffffffc0202968:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc020296a:	6098                	ld	a4,0(s1)
ffffffffc020296c:	c0200437          	lui	s0,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202970:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0202972:	00c71793          	slli	a5,a4,0xc
ffffffffc0202976:	6a05                	lui	s4,0x1
ffffffffc0202978:	02f47c63          	bgeu	s0,a5,ffffffffc02029b0 <pmm_init+0x406>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020297c:	00c45793          	srli	a5,s0,0xc
ffffffffc0202980:	00093503          	ld	a0,0(s2)
ffffffffc0202984:	2ee7f263          	bgeu	a5,a4,ffffffffc0202c68 <pmm_init+0x6be>
ffffffffc0202988:	0009b583          	ld	a1,0(s3)
ffffffffc020298c:	4601                	li	a2,0
ffffffffc020298e:	95a2                	add	a1,a1,s0
ffffffffc0202990:	c8aff0ef          	jal	ra,ffffffffc0201e1a <get_pte>
ffffffffc0202994:	2a050a63          	beqz	a0,ffffffffc0202c48 <pmm_init+0x69e>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202998:	611c                	ld	a5,0(a0)
ffffffffc020299a:	078a                	slli	a5,a5,0x2
ffffffffc020299c:	0157f7b3          	and	a5,a5,s5
ffffffffc02029a0:	28879463          	bne	a5,s0,ffffffffc0202c28 <pmm_init+0x67e>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02029a4:	6098                	ld	a4,0(s1)
ffffffffc02029a6:	9452                	add	s0,s0,s4
ffffffffc02029a8:	00c71793          	slli	a5,a4,0xc
ffffffffc02029ac:	fcf468e3          	bltu	s0,a5,ffffffffc020297c <pmm_init+0x3d2>
    }


    assert(boot_pgdir[0] == 0);
ffffffffc02029b0:	00093783          	ld	a5,0(s2)
ffffffffc02029b4:	639c                	ld	a5,0(a5)
ffffffffc02029b6:	66079b63          	bnez	a5,ffffffffc020302c <pmm_init+0xa82>

    struct Page *p;
    p = alloc_page();
ffffffffc02029ba:	4505                	li	a0,1
ffffffffc02029bc:	b52ff0ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc02029c0:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02029c2:	00093503          	ld	a0,0(s2)
ffffffffc02029c6:	4699                	li	a3,6
ffffffffc02029c8:	10000613          	li	a2,256
ffffffffc02029cc:	85d6                	mv	a1,s5
ffffffffc02029ce:	ae7ff0ef          	jal	ra,ffffffffc02024b4 <page_insert>
ffffffffc02029d2:	62051d63          	bnez	a0,ffffffffc020300c <pmm_init+0xa62>
    assert(page_ref(p) == 1);
ffffffffc02029d6:	000aa703          	lw	a4,0(s5) # fffffffffffff000 <end+0x3fd4c564>
ffffffffc02029da:	4785                	li	a5,1
ffffffffc02029dc:	60f71863          	bne	a4,a5,ffffffffc0202fec <pmm_init+0xa42>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02029e0:	00093503          	ld	a0,0(s2)
ffffffffc02029e4:	6405                	lui	s0,0x1
ffffffffc02029e6:	4699                	li	a3,6
ffffffffc02029e8:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8ad0>
ffffffffc02029ec:	85d6                	mv	a1,s5
ffffffffc02029ee:	ac7ff0ef          	jal	ra,ffffffffc02024b4 <page_insert>
ffffffffc02029f2:	46051163          	bnez	a0,ffffffffc0202e54 <pmm_init+0x8aa>
    assert(page_ref(p) == 2);
ffffffffc02029f6:	000aa703          	lw	a4,0(s5)
ffffffffc02029fa:	4789                	li	a5,2
ffffffffc02029fc:	72f71463          	bne	a4,a5,ffffffffc0203124 <pmm_init+0xb7a>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202a00:	00005597          	auipc	a1,0x5
ffffffffc0202a04:	ff058593          	addi	a1,a1,-16 # ffffffffc02079f0 <default_pmm_manager+0x638>
ffffffffc0202a08:	10000513          	li	a0,256
ffffffffc0202a0c:	389030ef          	jal	ra,ffffffffc0206594 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202a10:	10040593          	addi	a1,s0,256
ffffffffc0202a14:	10000513          	li	a0,256
ffffffffc0202a18:	38f030ef          	jal	ra,ffffffffc02065a6 <strcmp>
ffffffffc0202a1c:	6e051463          	bnez	a0,ffffffffc0203104 <pmm_init+0xb5a>
    return page - pages + nbase;
ffffffffc0202a20:	000b3683          	ld	a3,0(s6)
ffffffffc0202a24:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202a28:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202a2a:	40da86b3          	sub	a3,s5,a3
ffffffffc0202a2e:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202a30:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202a32:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202a34:	8031                	srli	s0,s0,0xc
ffffffffc0202a36:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202a3a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202a3c:	50f77c63          	bgeu	a4,a5,ffffffffc0202f54 <pmm_init+0x9aa>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202a40:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202a44:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202a48:	96be                	add	a3,a3,a5
ffffffffc0202a4a:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202a4e:	311030ef          	jal	ra,ffffffffc020655e <strlen>
ffffffffc0202a52:	68051963          	bnez	a0,ffffffffc02030e4 <pmm_init+0xb3a>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0202a56:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0202a5a:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a5c:	000a3683          	ld	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bd0>
ffffffffc0202a60:	068a                	slli	a3,a3,0x2
ffffffffc0202a62:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202a64:	20f6ff63          	bgeu	a3,a5,ffffffffc0202c82 <pmm_init+0x6d8>
    return KADDR(page2pa(page));
ffffffffc0202a68:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202a6a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202a6c:	4ef47463          	bgeu	s0,a5,ffffffffc0202f54 <pmm_init+0x9aa>
ffffffffc0202a70:	0009b403          	ld	s0,0(s3)
ffffffffc0202a74:	9436                	add	s0,s0,a3
ffffffffc0202a76:	100027f3          	csrr	a5,sstatus
ffffffffc0202a7a:	8b89                	andi	a5,a5,2
ffffffffc0202a7c:	18079b63          	bnez	a5,ffffffffc0202c12 <pmm_init+0x668>
        pmm_manager->free_pages(base, n);
ffffffffc0202a80:	000bb783          	ld	a5,0(s7)
ffffffffc0202a84:	4585                	li	a1,1
ffffffffc0202a86:	8556                	mv	a0,s5
ffffffffc0202a88:	739c                	ld	a5,32(a5)
ffffffffc0202a8a:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a8c:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0202a8e:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a90:	078a                	slli	a5,a5,0x2
ffffffffc0202a92:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202a94:	1ee7f763          	bgeu	a5,a4,ffffffffc0202c82 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a98:	000b3503          	ld	a0,0(s6)
ffffffffc0202a9c:	fff80737          	lui	a4,0xfff80
ffffffffc0202aa0:	97ba                	add	a5,a5,a4
ffffffffc0202aa2:	079a                	slli	a5,a5,0x6
ffffffffc0202aa4:	953e                	add	a0,a0,a5
ffffffffc0202aa6:	100027f3          	csrr	a5,sstatus
ffffffffc0202aaa:	8b89                	andi	a5,a5,2
ffffffffc0202aac:	14079763          	bnez	a5,ffffffffc0202bfa <pmm_init+0x650>
ffffffffc0202ab0:	000bb783          	ld	a5,0(s7)
ffffffffc0202ab4:	4585                	li	a1,1
ffffffffc0202ab6:	739c                	ld	a5,32(a5)
ffffffffc0202ab8:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202aba:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc0202abe:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ac0:	078a                	slli	a5,a5,0x2
ffffffffc0202ac2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202ac4:	1ae7ff63          	bgeu	a5,a4,ffffffffc0202c82 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ac8:	000b3503          	ld	a0,0(s6)
ffffffffc0202acc:	fff80737          	lui	a4,0xfff80
ffffffffc0202ad0:	97ba                	add	a5,a5,a4
ffffffffc0202ad2:	079a                	slli	a5,a5,0x6
ffffffffc0202ad4:	953e                	add	a0,a0,a5
ffffffffc0202ad6:	100027f3          	csrr	a5,sstatus
ffffffffc0202ada:	8b89                	andi	a5,a5,2
ffffffffc0202adc:	10079363          	bnez	a5,ffffffffc0202be2 <pmm_init+0x638>
ffffffffc0202ae0:	000bb783          	ld	a5,0(s7)
ffffffffc0202ae4:	4585                	li	a1,1
ffffffffc0202ae6:	739c                	ld	a5,32(a5)
ffffffffc0202ae8:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc0202aea:	00093783          	ld	a5,0(s2)
ffffffffc0202aee:	0007b023          	sd	zero,0(a5)
  asm volatile("sfence.vma");
ffffffffc0202af2:	12000073          	sfence.vma
ffffffffc0202af6:	100027f3          	csrr	a5,sstatus
ffffffffc0202afa:	8b89                	andi	a5,a5,2
ffffffffc0202afc:	0c079963          	bnez	a5,ffffffffc0202bce <pmm_init+0x624>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b00:	000bb783          	ld	a5,0(s7)
ffffffffc0202b04:	779c                	ld	a5,40(a5)
ffffffffc0202b06:	9782                	jalr	a5
ffffffffc0202b08:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc0202b0a:	3a8c1563          	bne	s8,s0,ffffffffc0202eb4 <pmm_init+0x90a>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202b0e:	00005517          	auipc	a0,0x5
ffffffffc0202b12:	f5a50513          	addi	a0,a0,-166 # ffffffffc0207a68 <default_pmm_manager+0x6b0>
ffffffffc0202b16:	e6afd0ef          	jal	ra,ffffffffc0200180 <cprintf>
}
ffffffffc0202b1a:	6446                	ld	s0,80(sp)
ffffffffc0202b1c:	60e6                	ld	ra,88(sp)
ffffffffc0202b1e:	64a6                	ld	s1,72(sp)
ffffffffc0202b20:	6906                	ld	s2,64(sp)
ffffffffc0202b22:	79e2                	ld	s3,56(sp)
ffffffffc0202b24:	7a42                	ld	s4,48(sp)
ffffffffc0202b26:	7aa2                	ld	s5,40(sp)
ffffffffc0202b28:	7b02                	ld	s6,32(sp)
ffffffffc0202b2a:	6be2                	ld	s7,24(sp)
ffffffffc0202b2c:	6c42                	ld	s8,16(sp)
ffffffffc0202b2e:	6125                	addi	sp,sp,96
    kmalloc_init();
ffffffffc0202b30:	fddfe06f          	j	ffffffffc0201b0c <kmalloc_init>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202b34:	6785                	lui	a5,0x1
ffffffffc0202b36:	17fd                	addi	a5,a5,-1
ffffffffc0202b38:	96be                	add	a3,a3,a5
ffffffffc0202b3a:	77fd                	lui	a5,0xfffff
ffffffffc0202b3c:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage) {
ffffffffc0202b3e:	00c7d693          	srli	a3,a5,0xc
ffffffffc0202b42:	14c6f063          	bgeu	a3,a2,ffffffffc0202c82 <pmm_init+0x6d8>
    pmm_manager->init_memmap(base, n);
ffffffffc0202b46:	000bb603          	ld	a2,0(s7)
    return &pages[PPN(pa) - nbase];
ffffffffc0202b4a:	96c2                	add	a3,a3,a6
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202b4c:	40f707b3          	sub	a5,a4,a5
    pmm_manager->init_memmap(base, n);
ffffffffc0202b50:	6a10                	ld	a2,16(a2)
ffffffffc0202b52:	069a                	slli	a3,a3,0x6
ffffffffc0202b54:	00c7d593          	srli	a1,a5,0xc
ffffffffc0202b58:	9536                	add	a0,a0,a3
ffffffffc0202b5a:	9602                	jalr	a2
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc0202b5c:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202b60:	b63d                	j	ffffffffc020268e <pmm_init+0xe4>
        intr_disable();
ffffffffc0202b62:	ae5fd0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b66:	000bb783          	ld	a5,0(s7)
ffffffffc0202b6a:	779c                	ld	a5,40(a5)
ffffffffc0202b6c:	9782                	jalr	a5
ffffffffc0202b6e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202b70:	ad1fd0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0202b74:	bea5                	j	ffffffffc02026ec <pmm_init+0x142>
        intr_disable();
ffffffffc0202b76:	ad1fd0ef          	jal	ra,ffffffffc0200646 <intr_disable>
ffffffffc0202b7a:	000bb783          	ld	a5,0(s7)
ffffffffc0202b7e:	779c                	ld	a5,40(a5)
ffffffffc0202b80:	9782                	jalr	a5
ffffffffc0202b82:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202b84:	abdfd0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0202b88:	b3cd                	j	ffffffffc020296a <pmm_init+0x3c0>
        intr_disable();
ffffffffc0202b8a:	abdfd0ef          	jal	ra,ffffffffc0200646 <intr_disable>
ffffffffc0202b8e:	000bb783          	ld	a5,0(s7)
ffffffffc0202b92:	779c                	ld	a5,40(a5)
ffffffffc0202b94:	9782                	jalr	a5
ffffffffc0202b96:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202b98:	aa9fd0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0202b9c:	b36d                	j	ffffffffc0202946 <pmm_init+0x39c>
ffffffffc0202b9e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202ba0:	aa7fd0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202ba4:	000bb783          	ld	a5,0(s7)
ffffffffc0202ba8:	6522                	ld	a0,8(sp)
ffffffffc0202baa:	4585                	li	a1,1
ffffffffc0202bac:	739c                	ld	a5,32(a5)
ffffffffc0202bae:	9782                	jalr	a5
        intr_enable();
ffffffffc0202bb0:	a91fd0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0202bb4:	bb8d                	j	ffffffffc0202926 <pmm_init+0x37c>
ffffffffc0202bb6:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202bb8:	a8ffd0ef          	jal	ra,ffffffffc0200646 <intr_disable>
ffffffffc0202bbc:	000bb783          	ld	a5,0(s7)
ffffffffc0202bc0:	6522                	ld	a0,8(sp)
ffffffffc0202bc2:	4585                	li	a1,1
ffffffffc0202bc4:	739c                	ld	a5,32(a5)
ffffffffc0202bc6:	9782                	jalr	a5
        intr_enable();
ffffffffc0202bc8:	a79fd0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0202bcc:	b32d                	j	ffffffffc02028f6 <pmm_init+0x34c>
        intr_disable();
ffffffffc0202bce:	a79fd0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202bd2:	000bb783          	ld	a5,0(s7)
ffffffffc0202bd6:	779c                	ld	a5,40(a5)
ffffffffc0202bd8:	9782                	jalr	a5
ffffffffc0202bda:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202bdc:	a65fd0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0202be0:	b72d                	j	ffffffffc0202b0a <pmm_init+0x560>
ffffffffc0202be2:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202be4:	a63fd0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202be8:	000bb783          	ld	a5,0(s7)
ffffffffc0202bec:	6522                	ld	a0,8(sp)
ffffffffc0202bee:	4585                	li	a1,1
ffffffffc0202bf0:	739c                	ld	a5,32(a5)
ffffffffc0202bf2:	9782                	jalr	a5
        intr_enable();
ffffffffc0202bf4:	a4dfd0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0202bf8:	bdcd                	j	ffffffffc0202aea <pmm_init+0x540>
ffffffffc0202bfa:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202bfc:	a4bfd0ef          	jal	ra,ffffffffc0200646 <intr_disable>
ffffffffc0202c00:	000bb783          	ld	a5,0(s7)
ffffffffc0202c04:	6522                	ld	a0,8(sp)
ffffffffc0202c06:	4585                	li	a1,1
ffffffffc0202c08:	739c                	ld	a5,32(a5)
ffffffffc0202c0a:	9782                	jalr	a5
        intr_enable();
ffffffffc0202c0c:	a35fd0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0202c10:	b56d                	j	ffffffffc0202aba <pmm_init+0x510>
        intr_disable();
ffffffffc0202c12:	a35fd0ef          	jal	ra,ffffffffc0200646 <intr_disable>
ffffffffc0202c16:	000bb783          	ld	a5,0(s7)
ffffffffc0202c1a:	4585                	li	a1,1
ffffffffc0202c1c:	8556                	mv	a0,s5
ffffffffc0202c1e:	739c                	ld	a5,32(a5)
ffffffffc0202c20:	9782                	jalr	a5
        intr_enable();
ffffffffc0202c22:	a1ffd0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0202c26:	b59d                	j	ffffffffc0202a8c <pmm_init+0x4e2>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202c28:	00005697          	auipc	a3,0x5
ffffffffc0202c2c:	cf068693          	addi	a3,a3,-784 # ffffffffc0207918 <default_pmm_manager+0x560>
ffffffffc0202c30:	00004617          	auipc	a2,0x4
ffffffffc0202c34:	09060613          	addi	a2,a2,144 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202c38:	22a00593          	li	a1,554
ffffffffc0202c3c:	00005517          	auipc	a0,0x5
ffffffffc0202c40:	8cc50513          	addi	a0,a0,-1844 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202c44:	837fd0ef          	jal	ra,ffffffffc020047a <__panic>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202c48:	00005697          	auipc	a3,0x5
ffffffffc0202c4c:	c9068693          	addi	a3,a3,-880 # ffffffffc02078d8 <default_pmm_manager+0x520>
ffffffffc0202c50:	00004617          	auipc	a2,0x4
ffffffffc0202c54:	07060613          	addi	a2,a2,112 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202c58:	22900593          	li	a1,553
ffffffffc0202c5c:	00005517          	auipc	a0,0x5
ffffffffc0202c60:	8ac50513          	addi	a0,a0,-1876 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202c64:	817fd0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc0202c68:	86a2                	mv	a3,s0
ffffffffc0202c6a:	00004617          	auipc	a2,0x4
ffffffffc0202c6e:	78660613          	addi	a2,a2,1926 # ffffffffc02073f0 <default_pmm_manager+0x38>
ffffffffc0202c72:	22900593          	li	a1,553
ffffffffc0202c76:	00005517          	auipc	a0,0x5
ffffffffc0202c7a:	89250513          	addi	a0,a0,-1902 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202c7e:	ffcfd0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc0202c82:	854ff0ef          	jal	ra,ffffffffc0201cd6 <pa2page.part.0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202c86:	00005617          	auipc	a2,0x5
ffffffffc0202c8a:	81260613          	addi	a2,a2,-2030 # ffffffffc0207498 <default_pmm_manager+0xe0>
ffffffffc0202c8e:	07f00593          	li	a1,127
ffffffffc0202c92:	00005517          	auipc	a0,0x5
ffffffffc0202c96:	87650513          	addi	a0,a0,-1930 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202c9a:	fe0fd0ef          	jal	ra,ffffffffc020047a <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0202c9e:	00004617          	auipc	a2,0x4
ffffffffc0202ca2:	7fa60613          	addi	a2,a2,2042 # ffffffffc0207498 <default_pmm_manager+0xe0>
ffffffffc0202ca6:	0c100593          	li	a1,193
ffffffffc0202caa:	00005517          	auipc	a0,0x5
ffffffffc0202cae:	85e50513          	addi	a0,a0,-1954 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202cb2:	fc8fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0202cb6:	00005697          	auipc	a3,0x5
ffffffffc0202cba:	95a68693          	addi	a3,a3,-1702 # ffffffffc0207610 <default_pmm_manager+0x258>
ffffffffc0202cbe:	00004617          	auipc	a2,0x4
ffffffffc0202cc2:	00260613          	addi	a2,a2,2 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202cc6:	1ed00593          	li	a1,493
ffffffffc0202cca:	00005517          	auipc	a0,0x5
ffffffffc0202cce:	83e50513          	addi	a0,a0,-1986 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202cd2:	fa8fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202cd6:	00005697          	auipc	a3,0x5
ffffffffc0202cda:	91a68693          	addi	a3,a3,-1766 # ffffffffc02075f0 <default_pmm_manager+0x238>
ffffffffc0202cde:	00004617          	auipc	a2,0x4
ffffffffc0202ce2:	fe260613          	addi	a2,a2,-30 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202ce6:	1ec00593          	li	a1,492
ffffffffc0202cea:	00005517          	auipc	a0,0x5
ffffffffc0202cee:	81e50513          	addi	a0,a0,-2018 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202cf2:	f88fd0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc0202cf6:	ffdfe0ef          	jal	ra,ffffffffc0201cf2 <pte2page.part.0>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0202cfa:	00005697          	auipc	a3,0x5
ffffffffc0202cfe:	9a668693          	addi	a3,a3,-1626 # ffffffffc02076a0 <default_pmm_manager+0x2e8>
ffffffffc0202d02:	00004617          	auipc	a2,0x4
ffffffffc0202d06:	fbe60613          	addi	a2,a2,-66 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202d0a:	1f500593          	li	a1,501
ffffffffc0202d0e:	00004517          	auipc	a0,0x4
ffffffffc0202d12:	7fa50513          	addi	a0,a0,2042 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202d16:	f64fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0202d1a:	00005697          	auipc	a3,0x5
ffffffffc0202d1e:	95668693          	addi	a3,a3,-1706 # ffffffffc0207670 <default_pmm_manager+0x2b8>
ffffffffc0202d22:	00004617          	auipc	a2,0x4
ffffffffc0202d26:	f9e60613          	addi	a2,a2,-98 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202d2a:	1f200593          	li	a1,498
ffffffffc0202d2e:	00004517          	auipc	a0,0x4
ffffffffc0202d32:	7da50513          	addi	a0,a0,2010 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202d36:	f44fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0202d3a:	00005697          	auipc	a3,0x5
ffffffffc0202d3e:	90e68693          	addi	a3,a3,-1778 # ffffffffc0207648 <default_pmm_manager+0x290>
ffffffffc0202d42:	00004617          	auipc	a2,0x4
ffffffffc0202d46:	f7e60613          	addi	a2,a2,-130 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202d4a:	1ee00593          	li	a1,494
ffffffffc0202d4e:	00004517          	auipc	a0,0x4
ffffffffc0202d52:	7ba50513          	addi	a0,a0,1978 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202d56:	f24fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202d5a:	00005697          	auipc	a3,0x5
ffffffffc0202d5e:	9ce68693          	addi	a3,a3,-1586 # ffffffffc0207728 <default_pmm_manager+0x370>
ffffffffc0202d62:	00004617          	auipc	a2,0x4
ffffffffc0202d66:	f5e60613          	addi	a2,a2,-162 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202d6a:	1fe00593          	li	a1,510
ffffffffc0202d6e:	00004517          	auipc	a0,0x4
ffffffffc0202d72:	79a50513          	addi	a0,a0,1946 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202d76:	f04fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0202d7a:	00005697          	auipc	a3,0x5
ffffffffc0202d7e:	a4e68693          	addi	a3,a3,-1458 # ffffffffc02077c8 <default_pmm_manager+0x410>
ffffffffc0202d82:	00004617          	auipc	a2,0x4
ffffffffc0202d86:	f3e60613          	addi	a2,a2,-194 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202d8a:	20300593          	li	a1,515
ffffffffc0202d8e:	00004517          	auipc	a0,0x4
ffffffffc0202d92:	77a50513          	addi	a0,a0,1914 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202d96:	ee4fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202d9a:	00005697          	auipc	a3,0x5
ffffffffc0202d9e:	96668693          	addi	a3,a3,-1690 # ffffffffc0207700 <default_pmm_manager+0x348>
ffffffffc0202da2:	00004617          	auipc	a2,0x4
ffffffffc0202da6:	f1e60613          	addi	a2,a2,-226 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202daa:	1fb00593          	li	a1,507
ffffffffc0202dae:	00004517          	auipc	a0,0x4
ffffffffc0202db2:	75a50513          	addi	a0,a0,1882 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202db6:	ec4fd0ef          	jal	ra,ffffffffc020047a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202dba:	86d6                	mv	a3,s5
ffffffffc0202dbc:	00004617          	auipc	a2,0x4
ffffffffc0202dc0:	63460613          	addi	a2,a2,1588 # ffffffffc02073f0 <default_pmm_manager+0x38>
ffffffffc0202dc4:	1fa00593          	li	a1,506
ffffffffc0202dc8:	00004517          	auipc	a0,0x4
ffffffffc0202dcc:	74050513          	addi	a0,a0,1856 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202dd0:	eaafd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202dd4:	00005697          	auipc	a3,0x5
ffffffffc0202dd8:	98c68693          	addi	a3,a3,-1652 # ffffffffc0207760 <default_pmm_manager+0x3a8>
ffffffffc0202ddc:	00004617          	auipc	a2,0x4
ffffffffc0202de0:	ee460613          	addi	a2,a2,-284 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202de4:	20800593          	li	a1,520
ffffffffc0202de8:	00004517          	auipc	a0,0x4
ffffffffc0202dec:	72050513          	addi	a0,a0,1824 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202df0:	e8afd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202df4:	00005697          	auipc	a3,0x5
ffffffffc0202df8:	a3468693          	addi	a3,a3,-1484 # ffffffffc0207828 <default_pmm_manager+0x470>
ffffffffc0202dfc:	00004617          	auipc	a2,0x4
ffffffffc0202e00:	ec460613          	addi	a2,a2,-316 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202e04:	20700593          	li	a1,519
ffffffffc0202e08:	00004517          	auipc	a0,0x4
ffffffffc0202e0c:	70050513          	addi	a0,a0,1792 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202e10:	e6afd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202e14:	00005697          	auipc	a3,0x5
ffffffffc0202e18:	9fc68693          	addi	a3,a3,-1540 # ffffffffc0207810 <default_pmm_manager+0x458>
ffffffffc0202e1c:	00004617          	auipc	a2,0x4
ffffffffc0202e20:	ea460613          	addi	a2,a2,-348 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202e24:	20600593          	li	a1,518
ffffffffc0202e28:	00004517          	auipc	a0,0x4
ffffffffc0202e2c:	6e050513          	addi	a0,a0,1760 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202e30:	e4afd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0202e34:	00005697          	auipc	a3,0x5
ffffffffc0202e38:	9ac68693          	addi	a3,a3,-1620 # ffffffffc02077e0 <default_pmm_manager+0x428>
ffffffffc0202e3c:	00004617          	auipc	a2,0x4
ffffffffc0202e40:	e8460613          	addi	a2,a2,-380 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202e44:	20500593          	li	a1,517
ffffffffc0202e48:	00004517          	auipc	a0,0x4
ffffffffc0202e4c:	6c050513          	addi	a0,a0,1728 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202e50:	e2afd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202e54:	00005697          	auipc	a3,0x5
ffffffffc0202e58:	b4468693          	addi	a3,a3,-1212 # ffffffffc0207998 <default_pmm_manager+0x5e0>
ffffffffc0202e5c:	00004617          	auipc	a2,0x4
ffffffffc0202e60:	e6460613          	addi	a2,a2,-412 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202e64:	23400593          	li	a1,564
ffffffffc0202e68:	00004517          	auipc	a0,0x4
ffffffffc0202e6c:	6a050513          	addi	a0,a0,1696 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202e70:	e0afd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0202e74:	00005697          	auipc	a3,0x5
ffffffffc0202e78:	93c68693          	addi	a3,a3,-1732 # ffffffffc02077b0 <default_pmm_manager+0x3f8>
ffffffffc0202e7c:	00004617          	auipc	a2,0x4
ffffffffc0202e80:	e4460613          	addi	a2,a2,-444 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202e84:	20200593          	li	a1,514
ffffffffc0202e88:	00004517          	auipc	a0,0x4
ffffffffc0202e8c:	68050513          	addi	a0,a0,1664 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202e90:	deafd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(*ptep & PTE_W);
ffffffffc0202e94:	00005697          	auipc	a3,0x5
ffffffffc0202e98:	90c68693          	addi	a3,a3,-1780 # ffffffffc02077a0 <default_pmm_manager+0x3e8>
ffffffffc0202e9c:	00004617          	auipc	a2,0x4
ffffffffc0202ea0:	e2460613          	addi	a2,a2,-476 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202ea4:	20100593          	li	a1,513
ffffffffc0202ea8:	00004517          	auipc	a0,0x4
ffffffffc0202eac:	66050513          	addi	a0,a0,1632 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202eb0:	dcafd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0202eb4:	00005697          	auipc	a3,0x5
ffffffffc0202eb8:	9e468693          	addi	a3,a3,-1564 # ffffffffc0207898 <default_pmm_manager+0x4e0>
ffffffffc0202ebc:	00004617          	auipc	a2,0x4
ffffffffc0202ec0:	e0460613          	addi	a2,a2,-508 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202ec4:	24500593          	li	a1,581
ffffffffc0202ec8:	00004517          	auipc	a0,0x4
ffffffffc0202ecc:	64050513          	addi	a0,a0,1600 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202ed0:	daafd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202ed4:	00005697          	auipc	a3,0x5
ffffffffc0202ed8:	8bc68693          	addi	a3,a3,-1860 # ffffffffc0207790 <default_pmm_manager+0x3d8>
ffffffffc0202edc:	00004617          	auipc	a2,0x4
ffffffffc0202ee0:	de460613          	addi	a2,a2,-540 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202ee4:	20000593          	li	a1,512
ffffffffc0202ee8:	00004517          	auipc	a0,0x4
ffffffffc0202eec:	62050513          	addi	a0,a0,1568 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202ef0:	d8afd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202ef4:	00004697          	auipc	a3,0x4
ffffffffc0202ef8:	7f468693          	addi	a3,a3,2036 # ffffffffc02076e8 <default_pmm_manager+0x330>
ffffffffc0202efc:	00004617          	auipc	a2,0x4
ffffffffc0202f00:	dc460613          	addi	a2,a2,-572 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202f04:	20d00593          	li	a1,525
ffffffffc0202f08:	00004517          	auipc	a0,0x4
ffffffffc0202f0c:	60050513          	addi	a0,a0,1536 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202f10:	d6afd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202f14:	00005697          	auipc	a3,0x5
ffffffffc0202f18:	92c68693          	addi	a3,a3,-1748 # ffffffffc0207840 <default_pmm_manager+0x488>
ffffffffc0202f1c:	00004617          	auipc	a2,0x4
ffffffffc0202f20:	da460613          	addi	a2,a2,-604 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202f24:	20a00593          	li	a1,522
ffffffffc0202f28:	00004517          	auipc	a0,0x4
ffffffffc0202f2c:	5e050513          	addi	a0,a0,1504 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202f30:	d4afd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202f34:	00004697          	auipc	a3,0x4
ffffffffc0202f38:	79c68693          	addi	a3,a3,1948 # ffffffffc02076d0 <default_pmm_manager+0x318>
ffffffffc0202f3c:	00004617          	auipc	a2,0x4
ffffffffc0202f40:	d8460613          	addi	a2,a2,-636 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202f44:	20900593          	li	a1,521
ffffffffc0202f48:	00004517          	auipc	a0,0x4
ffffffffc0202f4c:	5c050513          	addi	a0,a0,1472 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202f50:	d2afd0ef          	jal	ra,ffffffffc020047a <__panic>
    return KADDR(page2pa(page));
ffffffffc0202f54:	00004617          	auipc	a2,0x4
ffffffffc0202f58:	49c60613          	addi	a2,a2,1180 # ffffffffc02073f0 <default_pmm_manager+0x38>
ffffffffc0202f5c:	06900593          	li	a1,105
ffffffffc0202f60:	00004517          	auipc	a0,0x4
ffffffffc0202f64:	4b850513          	addi	a0,a0,1208 # ffffffffc0207418 <default_pmm_manager+0x60>
ffffffffc0202f68:	d12fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0202f6c:	00005697          	auipc	a3,0x5
ffffffffc0202f70:	90468693          	addi	a3,a3,-1788 # ffffffffc0207870 <default_pmm_manager+0x4b8>
ffffffffc0202f74:	00004617          	auipc	a2,0x4
ffffffffc0202f78:	d4c60613          	addi	a2,a2,-692 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202f7c:	21400593          	li	a1,532
ffffffffc0202f80:	00004517          	auipc	a0,0x4
ffffffffc0202f84:	58850513          	addi	a0,a0,1416 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202f88:	cf2fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202f8c:	00005697          	auipc	a3,0x5
ffffffffc0202f90:	89c68693          	addi	a3,a3,-1892 # ffffffffc0207828 <default_pmm_manager+0x470>
ffffffffc0202f94:	00004617          	auipc	a2,0x4
ffffffffc0202f98:	d2c60613          	addi	a2,a2,-724 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202f9c:	21200593          	li	a1,530
ffffffffc0202fa0:	00004517          	auipc	a0,0x4
ffffffffc0202fa4:	56850513          	addi	a0,a0,1384 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202fa8:	cd2fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202fac:	00005697          	auipc	a3,0x5
ffffffffc0202fb0:	8ac68693          	addi	a3,a3,-1876 # ffffffffc0207858 <default_pmm_manager+0x4a0>
ffffffffc0202fb4:	00004617          	auipc	a2,0x4
ffffffffc0202fb8:	d0c60613          	addi	a2,a2,-756 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202fbc:	21100593          	li	a1,529
ffffffffc0202fc0:	00004517          	auipc	a0,0x4
ffffffffc0202fc4:	54850513          	addi	a0,a0,1352 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202fc8:	cb2fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202fcc:	00005697          	auipc	a3,0x5
ffffffffc0202fd0:	85c68693          	addi	a3,a3,-1956 # ffffffffc0207828 <default_pmm_manager+0x470>
ffffffffc0202fd4:	00004617          	auipc	a2,0x4
ffffffffc0202fd8:	cec60613          	addi	a2,a2,-788 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202fdc:	20e00593          	li	a1,526
ffffffffc0202fe0:	00004517          	auipc	a0,0x4
ffffffffc0202fe4:	52850513          	addi	a0,a0,1320 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0202fe8:	c92fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202fec:	00005697          	auipc	a3,0x5
ffffffffc0202ff0:	99468693          	addi	a3,a3,-1644 # ffffffffc0207980 <default_pmm_manager+0x5c8>
ffffffffc0202ff4:	00004617          	auipc	a2,0x4
ffffffffc0202ff8:	ccc60613          	addi	a2,a2,-820 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0202ffc:	23300593          	li	a1,563
ffffffffc0203000:	00004517          	auipc	a0,0x4
ffffffffc0203004:	50850513          	addi	a0,a0,1288 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0203008:	c72fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc020300c:	00005697          	auipc	a3,0x5
ffffffffc0203010:	93c68693          	addi	a3,a3,-1732 # ffffffffc0207948 <default_pmm_manager+0x590>
ffffffffc0203014:	00004617          	auipc	a2,0x4
ffffffffc0203018:	cac60613          	addi	a2,a2,-852 # ffffffffc0206cc0 <commands+0x450>
ffffffffc020301c:	23200593          	li	a1,562
ffffffffc0203020:	00004517          	auipc	a0,0x4
ffffffffc0203024:	4e850513          	addi	a0,a0,1256 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0203028:	c52fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc020302c:	00005697          	auipc	a3,0x5
ffffffffc0203030:	90468693          	addi	a3,a3,-1788 # ffffffffc0207930 <default_pmm_manager+0x578>
ffffffffc0203034:	00004617          	auipc	a2,0x4
ffffffffc0203038:	c8c60613          	addi	a2,a2,-884 # ffffffffc0206cc0 <commands+0x450>
ffffffffc020303c:	22e00593          	li	a1,558
ffffffffc0203040:	00004517          	auipc	a0,0x4
ffffffffc0203044:	4c850513          	addi	a0,a0,1224 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0203048:	c32fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc020304c:	00005697          	auipc	a3,0x5
ffffffffc0203050:	84c68693          	addi	a3,a3,-1972 # ffffffffc0207898 <default_pmm_manager+0x4e0>
ffffffffc0203054:	00004617          	auipc	a2,0x4
ffffffffc0203058:	c6c60613          	addi	a2,a2,-916 # ffffffffc0206cc0 <commands+0x450>
ffffffffc020305c:	21c00593          	li	a1,540
ffffffffc0203060:	00004517          	auipc	a0,0x4
ffffffffc0203064:	4a850513          	addi	a0,a0,1192 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0203068:	c12fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020306c:	00004697          	auipc	a3,0x4
ffffffffc0203070:	66468693          	addi	a3,a3,1636 # ffffffffc02076d0 <default_pmm_manager+0x318>
ffffffffc0203074:	00004617          	auipc	a2,0x4
ffffffffc0203078:	c4c60613          	addi	a2,a2,-948 # ffffffffc0206cc0 <commands+0x450>
ffffffffc020307c:	1f600593          	li	a1,502
ffffffffc0203080:	00004517          	auipc	a0,0x4
ffffffffc0203084:	48850513          	addi	a0,a0,1160 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0203088:	bf2fd0ef          	jal	ra,ffffffffc020047a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc020308c:	00004617          	auipc	a2,0x4
ffffffffc0203090:	36460613          	addi	a2,a2,868 # ffffffffc02073f0 <default_pmm_manager+0x38>
ffffffffc0203094:	1f900593          	li	a1,505
ffffffffc0203098:	00004517          	auipc	a0,0x4
ffffffffc020309c:	47050513          	addi	a0,a0,1136 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc02030a0:	bdafd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02030a4:	00004697          	auipc	a3,0x4
ffffffffc02030a8:	64468693          	addi	a3,a3,1604 # ffffffffc02076e8 <default_pmm_manager+0x330>
ffffffffc02030ac:	00004617          	auipc	a2,0x4
ffffffffc02030b0:	c1460613          	addi	a2,a2,-1004 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02030b4:	1f700593          	li	a1,503
ffffffffc02030b8:	00004517          	auipc	a0,0x4
ffffffffc02030bc:	45050513          	addi	a0,a0,1104 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc02030c0:	bbafd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02030c4:	00004697          	auipc	a3,0x4
ffffffffc02030c8:	69c68693          	addi	a3,a3,1692 # ffffffffc0207760 <default_pmm_manager+0x3a8>
ffffffffc02030cc:	00004617          	auipc	a2,0x4
ffffffffc02030d0:	bf460613          	addi	a2,a2,-1036 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02030d4:	1ff00593          	li	a1,511
ffffffffc02030d8:	00004517          	auipc	a0,0x4
ffffffffc02030dc:	43050513          	addi	a0,a0,1072 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc02030e0:	b9afd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc02030e4:	00005697          	auipc	a3,0x5
ffffffffc02030e8:	95c68693          	addi	a3,a3,-1700 # ffffffffc0207a40 <default_pmm_manager+0x688>
ffffffffc02030ec:	00004617          	auipc	a2,0x4
ffffffffc02030f0:	bd460613          	addi	a2,a2,-1068 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02030f4:	23c00593          	li	a1,572
ffffffffc02030f8:	00004517          	auipc	a0,0x4
ffffffffc02030fc:	41050513          	addi	a0,a0,1040 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0203100:	b7afd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0203104:	00005697          	auipc	a3,0x5
ffffffffc0203108:	90468693          	addi	a3,a3,-1788 # ffffffffc0207a08 <default_pmm_manager+0x650>
ffffffffc020310c:	00004617          	auipc	a2,0x4
ffffffffc0203110:	bb460613          	addi	a2,a2,-1100 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203114:	23900593          	li	a1,569
ffffffffc0203118:	00004517          	auipc	a0,0x4
ffffffffc020311c:	3f050513          	addi	a0,a0,1008 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0203120:	b5afd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p) == 2);
ffffffffc0203124:	00005697          	auipc	a3,0x5
ffffffffc0203128:	8b468693          	addi	a3,a3,-1868 # ffffffffc02079d8 <default_pmm_manager+0x620>
ffffffffc020312c:	00004617          	auipc	a2,0x4
ffffffffc0203130:	b9460613          	addi	a2,a2,-1132 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203134:	23500593          	li	a1,565
ffffffffc0203138:	00004517          	auipc	a0,0x4
ffffffffc020313c:	3d050513          	addi	a0,a0,976 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0203140:	b3afd0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0203144 <copy_range>:
               bool share) {
ffffffffc0203144:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203146:	00d667b3          	or	a5,a2,a3
               bool share) {
ffffffffc020314a:	f486                	sd	ra,104(sp)
ffffffffc020314c:	f0a2                	sd	s0,96(sp)
ffffffffc020314e:	eca6                	sd	s1,88(sp)
ffffffffc0203150:	e8ca                	sd	s2,80(sp)
ffffffffc0203152:	e4ce                	sd	s3,72(sp)
ffffffffc0203154:	e0d2                	sd	s4,64(sp)
ffffffffc0203156:	fc56                	sd	s5,56(sp)
ffffffffc0203158:	f85a                	sd	s6,48(sp)
ffffffffc020315a:	f45e                	sd	s7,40(sp)
ffffffffc020315c:	f062                	sd	s8,32(sp)
ffffffffc020315e:	ec66                	sd	s9,24(sp)
ffffffffc0203160:	e86a                	sd	s10,16(sp)
ffffffffc0203162:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203164:	17d2                	slli	a5,a5,0x34
ffffffffc0203166:	1e079763          	bnez	a5,ffffffffc0203354 <copy_range+0x210>
    assert(USER_ACCESS(start, end));
ffffffffc020316a:	002007b7          	lui	a5,0x200
ffffffffc020316e:	8432                	mv	s0,a2
ffffffffc0203170:	16f66a63          	bltu	a2,a5,ffffffffc02032e4 <copy_range+0x1a0>
ffffffffc0203174:	8936                	mv	s2,a3
ffffffffc0203176:	16d67763          	bgeu	a2,a3,ffffffffc02032e4 <copy_range+0x1a0>
ffffffffc020317a:	4785                	li	a5,1
ffffffffc020317c:	07fe                	slli	a5,a5,0x1f
ffffffffc020317e:	16d7e363          	bltu	a5,a3,ffffffffc02032e4 <copy_range+0x1a0>
ffffffffc0203182:	5b7d                	li	s6,-1
ffffffffc0203184:	8aaa                	mv	s5,a0
ffffffffc0203186:	89ae                	mv	s3,a1
        start += PGSIZE;
ffffffffc0203188:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage) {
ffffffffc020318a:	000b0c97          	auipc	s9,0xb0
ffffffffc020318e:	8aec8c93          	addi	s9,s9,-1874 # ffffffffc02b2a38 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203192:	000b0c17          	auipc	s8,0xb0
ffffffffc0203196:	8aec0c13          	addi	s8,s8,-1874 # ffffffffc02b2a40 <pages>
    return page - pages + nbase;
ffffffffc020319a:	00080bb7          	lui	s7,0x80
    return KADDR(page2pa(page));
ffffffffc020319e:	00cb5b13          	srli	s6,s6,0xc
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc02031a2:	4601                	li	a2,0
ffffffffc02031a4:	85a2                	mv	a1,s0
ffffffffc02031a6:	854e                	mv	a0,s3
ffffffffc02031a8:	c73fe0ef          	jal	ra,ffffffffc0201e1a <get_pte>
ffffffffc02031ac:	84aa                	mv	s1,a0
        if (ptep == NULL) {
ffffffffc02031ae:	c175                	beqz	a0,ffffffffc0203292 <copy_range+0x14e>
        if (*ptep & PTE_V) {
ffffffffc02031b0:	611c                	ld	a5,0(a0)
ffffffffc02031b2:	8b85                	andi	a5,a5,1
ffffffffc02031b4:	e785                	bnez	a5,ffffffffc02031dc <copy_range+0x98>
        start += PGSIZE;
ffffffffc02031b6:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02031b8:	ff2465e3          	bltu	s0,s2,ffffffffc02031a2 <copy_range+0x5e>
    return 0;
ffffffffc02031bc:	4501                	li	a0,0
}
ffffffffc02031be:	70a6                	ld	ra,104(sp)
ffffffffc02031c0:	7406                	ld	s0,96(sp)
ffffffffc02031c2:	64e6                	ld	s1,88(sp)
ffffffffc02031c4:	6946                	ld	s2,80(sp)
ffffffffc02031c6:	69a6                	ld	s3,72(sp)
ffffffffc02031c8:	6a06                	ld	s4,64(sp)
ffffffffc02031ca:	7ae2                	ld	s5,56(sp)
ffffffffc02031cc:	7b42                	ld	s6,48(sp)
ffffffffc02031ce:	7ba2                	ld	s7,40(sp)
ffffffffc02031d0:	7c02                	ld	s8,32(sp)
ffffffffc02031d2:	6ce2                	ld	s9,24(sp)
ffffffffc02031d4:	6d42                	ld	s10,16(sp)
ffffffffc02031d6:	6da2                	ld	s11,8(sp)
ffffffffc02031d8:	6165                	addi	sp,sp,112
ffffffffc02031da:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL) {
ffffffffc02031dc:	4605                	li	a2,1
ffffffffc02031de:	85a2                	mv	a1,s0
ffffffffc02031e0:	8556                	mv	a0,s5
ffffffffc02031e2:	c39fe0ef          	jal	ra,ffffffffc0201e1a <get_pte>
ffffffffc02031e6:	c161                	beqz	a0,ffffffffc02032a6 <copy_range+0x162>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02031e8:	609c                	ld	a5,0(s1)
    if (!(pte & PTE_V)) {
ffffffffc02031ea:	0017f713          	andi	a4,a5,1
ffffffffc02031ee:	01f7f493          	andi	s1,a5,31
ffffffffc02031f2:	14070563          	beqz	a4,ffffffffc020333c <copy_range+0x1f8>
    if (PPN(pa) >= npage) {
ffffffffc02031f6:	000cb683          	ld	a3,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc02031fa:	078a                	slli	a5,a5,0x2
ffffffffc02031fc:	00c7d713          	srli	a4,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203200:	12d77263          	bgeu	a4,a3,ffffffffc0203324 <copy_range+0x1e0>
    return &pages[PPN(pa) - nbase];
ffffffffc0203204:	000c3783          	ld	a5,0(s8)
ffffffffc0203208:	fff806b7          	lui	a3,0xfff80
ffffffffc020320c:	9736                	add	a4,a4,a3
ffffffffc020320e:	071a                	slli	a4,a4,0x6
            struct Page *npage = alloc_page();
ffffffffc0203210:	4505                	li	a0,1
ffffffffc0203212:	00e78db3          	add	s11,a5,a4
ffffffffc0203216:	af9fe0ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc020321a:	8d2a                	mv	s10,a0
            assert(page != NULL);
ffffffffc020321c:	0a0d8463          	beqz	s11,ffffffffc02032c4 <copy_range+0x180>
            assert(npage != NULL);
ffffffffc0203220:	c175                	beqz	a0,ffffffffc0203304 <copy_range+0x1c0>
    return page - pages + nbase;
ffffffffc0203222:	000c3703          	ld	a4,0(s8)
    return KADDR(page2pa(page));
ffffffffc0203226:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc020322a:	40ed86b3          	sub	a3,s11,a4
ffffffffc020322e:	8699                	srai	a3,a3,0x6
ffffffffc0203230:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0203232:	0166f7b3          	and	a5,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0203236:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203238:	06c7fa63          	bgeu	a5,a2,ffffffffc02032ac <copy_range+0x168>
    return page - pages + nbase;
ffffffffc020323c:	40e507b3          	sub	a5,a0,a4
    return KADDR(page2pa(page));
ffffffffc0203240:	000b0717          	auipc	a4,0xb0
ffffffffc0203244:	81070713          	addi	a4,a4,-2032 # ffffffffc02b2a50 <va_pa_offset>
ffffffffc0203248:	6308                	ld	a0,0(a4)
    return page - pages + nbase;
ffffffffc020324a:	8799                	srai	a5,a5,0x6
ffffffffc020324c:	97de                	add	a5,a5,s7
    return KADDR(page2pa(page));
ffffffffc020324e:	0167f733          	and	a4,a5,s6
ffffffffc0203252:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0203256:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0203258:	04c77963          	bgeu	a4,a2,ffffffffc02032aa <copy_range+0x166>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE); // parent 的物理页复制给 child
ffffffffc020325c:	6605                	lui	a2,0x1
ffffffffc020325e:	953e                	add	a0,a0,a5
ffffffffc0203260:	38c030ef          	jal	ra,ffffffffc02065ec <memcpy>
            ret = page_insert(to, npage, start, perm); // 建立 child 的物理页和虚拟页的映射关系
ffffffffc0203264:	86a6                	mv	a3,s1
ffffffffc0203266:	8622                	mv	a2,s0
ffffffffc0203268:	85ea                	mv	a1,s10
ffffffffc020326a:	8556                	mv	a0,s5
ffffffffc020326c:	a48ff0ef          	jal	ra,ffffffffc02024b4 <page_insert>
            assert(ret == 0);
ffffffffc0203270:	d139                	beqz	a0,ffffffffc02031b6 <copy_range+0x72>
ffffffffc0203272:	00005697          	auipc	a3,0x5
ffffffffc0203276:	83668693          	addi	a3,a3,-1994 # ffffffffc0207aa8 <default_pmm_manager+0x6f0>
ffffffffc020327a:	00004617          	auipc	a2,0x4
ffffffffc020327e:	a4660613          	addi	a2,a2,-1466 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203282:	18c00593          	li	a1,396
ffffffffc0203286:	00004517          	auipc	a0,0x4
ffffffffc020328a:	28250513          	addi	a0,a0,642 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc020328e:	9ecfd0ef          	jal	ra,ffffffffc020047a <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0203292:	00200637          	lui	a2,0x200
ffffffffc0203296:	9432                	add	s0,s0,a2
ffffffffc0203298:	ffe00637          	lui	a2,0xffe00
ffffffffc020329c:	8c71                	and	s0,s0,a2
    } while (start != 0 && start < end);
ffffffffc020329e:	dc19                	beqz	s0,ffffffffc02031bc <copy_range+0x78>
ffffffffc02032a0:	f12461e3          	bltu	s0,s2,ffffffffc02031a2 <copy_range+0x5e>
ffffffffc02032a4:	bf21                	j	ffffffffc02031bc <copy_range+0x78>
                return -E_NO_MEM;
ffffffffc02032a6:	5571                	li	a0,-4
ffffffffc02032a8:	bf19                	j	ffffffffc02031be <copy_range+0x7a>
ffffffffc02032aa:	86be                	mv	a3,a5
ffffffffc02032ac:	00004617          	auipc	a2,0x4
ffffffffc02032b0:	14460613          	addi	a2,a2,324 # ffffffffc02073f0 <default_pmm_manager+0x38>
ffffffffc02032b4:	06900593          	li	a1,105
ffffffffc02032b8:	00004517          	auipc	a0,0x4
ffffffffc02032bc:	16050513          	addi	a0,a0,352 # ffffffffc0207418 <default_pmm_manager+0x60>
ffffffffc02032c0:	9bafd0ef          	jal	ra,ffffffffc020047a <__panic>
            assert(page != NULL);
ffffffffc02032c4:	00004697          	auipc	a3,0x4
ffffffffc02032c8:	7c468693          	addi	a3,a3,1988 # ffffffffc0207a88 <default_pmm_manager+0x6d0>
ffffffffc02032cc:	00004617          	auipc	a2,0x4
ffffffffc02032d0:	9f460613          	addi	a2,a2,-1548 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02032d4:	17200593          	li	a1,370
ffffffffc02032d8:	00004517          	auipc	a0,0x4
ffffffffc02032dc:	23050513          	addi	a0,a0,560 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc02032e0:	99afd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02032e4:	00004697          	auipc	a3,0x4
ffffffffc02032e8:	26468693          	addi	a3,a3,612 # ffffffffc0207548 <default_pmm_manager+0x190>
ffffffffc02032ec:	00004617          	auipc	a2,0x4
ffffffffc02032f0:	9d460613          	addi	a2,a2,-1580 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02032f4:	15e00593          	li	a1,350
ffffffffc02032f8:	00004517          	auipc	a0,0x4
ffffffffc02032fc:	21050513          	addi	a0,a0,528 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0203300:	97afd0ef          	jal	ra,ffffffffc020047a <__panic>
            assert(npage != NULL);
ffffffffc0203304:	00004697          	auipc	a3,0x4
ffffffffc0203308:	79468693          	addi	a3,a3,1940 # ffffffffc0207a98 <default_pmm_manager+0x6e0>
ffffffffc020330c:	00004617          	auipc	a2,0x4
ffffffffc0203310:	9b460613          	addi	a2,a2,-1612 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203314:	17300593          	li	a1,371
ffffffffc0203318:	00004517          	auipc	a0,0x4
ffffffffc020331c:	1f050513          	addi	a0,a0,496 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0203320:	95afd0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203324:	00004617          	auipc	a2,0x4
ffffffffc0203328:	19c60613          	addi	a2,a2,412 # ffffffffc02074c0 <default_pmm_manager+0x108>
ffffffffc020332c:	06200593          	li	a1,98
ffffffffc0203330:	00004517          	auipc	a0,0x4
ffffffffc0203334:	0e850513          	addi	a0,a0,232 # ffffffffc0207418 <default_pmm_manager+0x60>
ffffffffc0203338:	942fd0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("pte2page called with invalid pte");
ffffffffc020333c:	00004617          	auipc	a2,0x4
ffffffffc0203340:	1a460613          	addi	a2,a2,420 # ffffffffc02074e0 <default_pmm_manager+0x128>
ffffffffc0203344:	07400593          	li	a1,116
ffffffffc0203348:	00004517          	auipc	a0,0x4
ffffffffc020334c:	0d050513          	addi	a0,a0,208 # ffffffffc0207418 <default_pmm_manager+0x60>
ffffffffc0203350:	92afd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203354:	00004697          	auipc	a3,0x4
ffffffffc0203358:	1c468693          	addi	a3,a3,452 # ffffffffc0207518 <default_pmm_manager+0x160>
ffffffffc020335c:	00004617          	auipc	a2,0x4
ffffffffc0203360:	96460613          	addi	a2,a2,-1692 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203364:	15d00593          	li	a1,349
ffffffffc0203368:	00004517          	auipc	a0,0x4
ffffffffc020336c:	1a050513          	addi	a0,a0,416 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0203370:	90afd0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0203374 <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0203374:	12058073          	sfence.vma	a1
}
ffffffffc0203378:	8082                	ret

ffffffffc020337a <pgdir_alloc_page>:
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc020337a:	7179                	addi	sp,sp,-48
ffffffffc020337c:	e84a                	sd	s2,16(sp)
ffffffffc020337e:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc0203380:	4505                	li	a0,1
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0203382:	f022                	sd	s0,32(sp)
ffffffffc0203384:	ec26                	sd	s1,24(sp)
ffffffffc0203386:	e44e                	sd	s3,8(sp)
ffffffffc0203388:	f406                	sd	ra,40(sp)
ffffffffc020338a:	84ae                	mv	s1,a1
ffffffffc020338c:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc020338e:	981fe0ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc0203392:	842a                	mv	s0,a0
    if (page != NULL) {
ffffffffc0203394:	cd05                	beqz	a0,ffffffffc02033cc <pgdir_alloc_page+0x52>
        if (page_insert(pgdir, page, la, perm) != 0) {
ffffffffc0203396:	85aa                	mv	a1,a0
ffffffffc0203398:	86ce                	mv	a3,s3
ffffffffc020339a:	8626                	mv	a2,s1
ffffffffc020339c:	854a                	mv	a0,s2
ffffffffc020339e:	916ff0ef          	jal	ra,ffffffffc02024b4 <page_insert>
ffffffffc02033a2:	ed0d                	bnez	a0,ffffffffc02033dc <pgdir_alloc_page+0x62>
        if (swap_init_ok) {
ffffffffc02033a4:	000af797          	auipc	a5,0xaf
ffffffffc02033a8:	6c47a783          	lw	a5,1732(a5) # ffffffffc02b2a68 <swap_init_ok>
ffffffffc02033ac:	c385                	beqz	a5,ffffffffc02033cc <pgdir_alloc_page+0x52>
            if (check_mm_struct != NULL) {
ffffffffc02033ae:	000af517          	auipc	a0,0xaf
ffffffffc02033b2:	6c253503          	ld	a0,1730(a0) # ffffffffc02b2a70 <check_mm_struct>
ffffffffc02033b6:	c919                	beqz	a0,ffffffffc02033cc <pgdir_alloc_page+0x52>
                swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc02033b8:	4681                	li	a3,0
ffffffffc02033ba:	8622                	mv	a2,s0
ffffffffc02033bc:	85a6                	mv	a1,s1
ffffffffc02033be:	7e4000ef          	jal	ra,ffffffffc0203ba2 <swap_map_swappable>
                assert(page_ref(page) == 1);
ffffffffc02033c2:	4018                	lw	a4,0(s0)
                page->pra_vaddr = la;
ffffffffc02033c4:	fc04                	sd	s1,56(s0)
                assert(page_ref(page) == 1);
ffffffffc02033c6:	4785                	li	a5,1
ffffffffc02033c8:	04f71663          	bne	a4,a5,ffffffffc0203414 <pgdir_alloc_page+0x9a>
}
ffffffffc02033cc:	70a2                	ld	ra,40(sp)
ffffffffc02033ce:	8522                	mv	a0,s0
ffffffffc02033d0:	7402                	ld	s0,32(sp)
ffffffffc02033d2:	64e2                	ld	s1,24(sp)
ffffffffc02033d4:	6942                	ld	s2,16(sp)
ffffffffc02033d6:	69a2                	ld	s3,8(sp)
ffffffffc02033d8:	6145                	addi	sp,sp,48
ffffffffc02033da:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02033dc:	100027f3          	csrr	a5,sstatus
ffffffffc02033e0:	8b89                	andi	a5,a5,2
ffffffffc02033e2:	eb99                	bnez	a5,ffffffffc02033f8 <pgdir_alloc_page+0x7e>
        pmm_manager->free_pages(base, n);
ffffffffc02033e4:	000af797          	auipc	a5,0xaf
ffffffffc02033e8:	6647b783          	ld	a5,1636(a5) # ffffffffc02b2a48 <pmm_manager>
ffffffffc02033ec:	739c                	ld	a5,32(a5)
ffffffffc02033ee:	8522                	mv	a0,s0
ffffffffc02033f0:	4585                	li	a1,1
ffffffffc02033f2:	9782                	jalr	a5
            return NULL;
ffffffffc02033f4:	4401                	li	s0,0
ffffffffc02033f6:	bfd9                	j	ffffffffc02033cc <pgdir_alloc_page+0x52>
        intr_disable();
ffffffffc02033f8:	a4efd0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02033fc:	000af797          	auipc	a5,0xaf
ffffffffc0203400:	64c7b783          	ld	a5,1612(a5) # ffffffffc02b2a48 <pmm_manager>
ffffffffc0203404:	739c                	ld	a5,32(a5)
ffffffffc0203406:	8522                	mv	a0,s0
ffffffffc0203408:	4585                	li	a1,1
ffffffffc020340a:	9782                	jalr	a5
            return NULL;
ffffffffc020340c:	4401                	li	s0,0
        intr_enable();
ffffffffc020340e:	a32fd0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0203412:	bf6d                	j	ffffffffc02033cc <pgdir_alloc_page+0x52>
                assert(page_ref(page) == 1);
ffffffffc0203414:	00004697          	auipc	a3,0x4
ffffffffc0203418:	6a468693          	addi	a3,a3,1700 # ffffffffc0207ab8 <default_pmm_manager+0x700>
ffffffffc020341c:	00004617          	auipc	a2,0x4
ffffffffc0203420:	8a460613          	addi	a2,a2,-1884 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203424:	1cd00593          	li	a1,461
ffffffffc0203428:	00004517          	auipc	a0,0x4
ffffffffc020342c:	0e050513          	addi	a0,a0,224 # ffffffffc0207508 <default_pmm_manager+0x150>
ffffffffc0203430:	84afd0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0203434 <pa2page.part.0>:
pa2page(uintptr_t pa) {
ffffffffc0203434:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0203436:	00004617          	auipc	a2,0x4
ffffffffc020343a:	08a60613          	addi	a2,a2,138 # ffffffffc02074c0 <default_pmm_manager+0x108>
ffffffffc020343e:	06200593          	li	a1,98
ffffffffc0203442:	00004517          	auipc	a0,0x4
ffffffffc0203446:	fd650513          	addi	a0,a0,-42 # ffffffffc0207418 <default_pmm_manager+0x60>
pa2page(uintptr_t pa) {
ffffffffc020344a:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc020344c:	82efd0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0203450 <swap_init>:

static void check_swap(void);

int
swap_init(void)
{
ffffffffc0203450:	7135                	addi	sp,sp,-160
ffffffffc0203452:	ed06                	sd	ra,152(sp)
ffffffffc0203454:	e922                	sd	s0,144(sp)
ffffffffc0203456:	e526                	sd	s1,136(sp)
ffffffffc0203458:	e14a                	sd	s2,128(sp)
ffffffffc020345a:	fcce                	sd	s3,120(sp)
ffffffffc020345c:	f8d2                	sd	s4,112(sp)
ffffffffc020345e:	f4d6                	sd	s5,104(sp)
ffffffffc0203460:	f0da                	sd	s6,96(sp)
ffffffffc0203462:	ecde                	sd	s7,88(sp)
ffffffffc0203464:	e8e2                	sd	s8,80(sp)
ffffffffc0203466:	e4e6                	sd	s9,72(sp)
ffffffffc0203468:	e0ea                	sd	s10,64(sp)
ffffffffc020346a:	fc6e                	sd	s11,56(sp)
     swapfs_init();
ffffffffc020346c:	72e010ef          	jal	ra,ffffffffc0204b9a <swapfs_init>

     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     if (!(7 <= max_swap_offset &&
ffffffffc0203470:	000af697          	auipc	a3,0xaf
ffffffffc0203474:	5e86b683          	ld	a3,1512(a3) # ffffffffc02b2a58 <max_swap_offset>
ffffffffc0203478:	010007b7          	lui	a5,0x1000
ffffffffc020347c:	ff968713          	addi	a4,a3,-7
ffffffffc0203480:	17e1                	addi	a5,a5,-8
ffffffffc0203482:	42e7e663          	bltu	a5,a4,ffffffffc02038ae <swap_init+0x45e>
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }
     

     sm = &swap_manager_fifo;
ffffffffc0203486:	000a4797          	auipc	a5,0xa4
ffffffffc020348a:	06a78793          	addi	a5,a5,106 # ffffffffc02a74f0 <swap_manager_fifo>
     int r = sm->init();
ffffffffc020348e:	6798                	ld	a4,8(a5)
     sm = &swap_manager_fifo;
ffffffffc0203490:	000afb97          	auipc	s7,0xaf
ffffffffc0203494:	5d0b8b93          	addi	s7,s7,1488 # ffffffffc02b2a60 <sm>
ffffffffc0203498:	00fbb023          	sd	a5,0(s7)
     int r = sm->init();
ffffffffc020349c:	9702                	jalr	a4
ffffffffc020349e:	892a                	mv	s2,a0
     
     if (r == 0)
ffffffffc02034a0:	c10d                	beqz	a0,ffffffffc02034c2 <swap_init+0x72>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
ffffffffc02034a2:	60ea                	ld	ra,152(sp)
ffffffffc02034a4:	644a                	ld	s0,144(sp)
ffffffffc02034a6:	64aa                	ld	s1,136(sp)
ffffffffc02034a8:	79e6                	ld	s3,120(sp)
ffffffffc02034aa:	7a46                	ld	s4,112(sp)
ffffffffc02034ac:	7aa6                	ld	s5,104(sp)
ffffffffc02034ae:	7b06                	ld	s6,96(sp)
ffffffffc02034b0:	6be6                	ld	s7,88(sp)
ffffffffc02034b2:	6c46                	ld	s8,80(sp)
ffffffffc02034b4:	6ca6                	ld	s9,72(sp)
ffffffffc02034b6:	6d06                	ld	s10,64(sp)
ffffffffc02034b8:	7de2                	ld	s11,56(sp)
ffffffffc02034ba:	854a                	mv	a0,s2
ffffffffc02034bc:	690a                	ld	s2,128(sp)
ffffffffc02034be:	610d                	addi	sp,sp,160
ffffffffc02034c0:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc02034c2:	000bb783          	ld	a5,0(s7)
ffffffffc02034c6:	00004517          	auipc	a0,0x4
ffffffffc02034ca:	63a50513          	addi	a0,a0,1594 # ffffffffc0207b00 <default_pmm_manager+0x748>
    return listelm->next;
ffffffffc02034ce:	000ab417          	auipc	s0,0xab
ffffffffc02034d2:	47240413          	addi	s0,s0,1138 # ffffffffc02ae940 <free_area>
ffffffffc02034d6:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc02034d8:	4785                	li	a5,1
ffffffffc02034da:	000af717          	auipc	a4,0xaf
ffffffffc02034de:	58f72723          	sw	a5,1422(a4) # ffffffffc02b2a68 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc02034e2:	c9ffc0ef          	jal	ra,ffffffffc0200180 <cprintf>
ffffffffc02034e6:	641c                	ld	a5,8(s0)

static void
check_swap(void)
{
    //backup mem env
     int ret, count = 0, total = 0, i;
ffffffffc02034e8:	4d01                	li	s10,0
ffffffffc02034ea:	4d81                	li	s11,0
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc02034ec:	34878163          	beq	a5,s0,ffffffffc020382e <swap_init+0x3de>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02034f0:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02034f4:	8b09                	andi	a4,a4,2
ffffffffc02034f6:	32070e63          	beqz	a4,ffffffffc0203832 <swap_init+0x3e2>
        count ++, total += p->property;
ffffffffc02034fa:	ff87a703          	lw	a4,-8(a5)
ffffffffc02034fe:	679c                	ld	a5,8(a5)
ffffffffc0203500:	2d85                	addiw	s11,s11,1
ffffffffc0203502:	01a70d3b          	addw	s10,a4,s10
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203506:	fe8795e3          	bne	a5,s0,ffffffffc02034f0 <swap_init+0xa0>
     }
     assert(total == nr_free_pages());
ffffffffc020350a:	84ea                	mv	s1,s10
ffffffffc020350c:	8d5fe0ef          	jal	ra,ffffffffc0201de0 <nr_free_pages>
ffffffffc0203510:	42951763          	bne	a0,s1,ffffffffc020393e <swap_init+0x4ee>
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
ffffffffc0203514:	866a                	mv	a2,s10
ffffffffc0203516:	85ee                	mv	a1,s11
ffffffffc0203518:	00004517          	auipc	a0,0x4
ffffffffc020351c:	60050513          	addi	a0,a0,1536 # ffffffffc0207b18 <default_pmm_manager+0x760>
ffffffffc0203520:	c61fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create();
ffffffffc0203524:	42b000ef          	jal	ra,ffffffffc020414e <mm_create>
ffffffffc0203528:	8aaa                	mv	s5,a0
     assert(mm != NULL);
ffffffffc020352a:	46050a63          	beqz	a0,ffffffffc020399e <swap_init+0x54e>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc020352e:	000af797          	auipc	a5,0xaf
ffffffffc0203532:	54278793          	addi	a5,a5,1346 # ffffffffc02b2a70 <check_mm_struct>
ffffffffc0203536:	6398                	ld	a4,0(a5)
ffffffffc0203538:	3e071363          	bnez	a4,ffffffffc020391e <swap_init+0x4ce>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc020353c:	000af717          	auipc	a4,0xaf
ffffffffc0203540:	4f470713          	addi	a4,a4,1268 # ffffffffc02b2a30 <boot_pgdir>
ffffffffc0203544:	00073b03          	ld	s6,0(a4)
     check_mm_struct = mm;
ffffffffc0203548:	e388                	sd	a0,0(a5)
     assert(pgdir[0] == 0);
ffffffffc020354a:	000b3783          	ld	a5,0(s6)
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc020354e:	01653c23          	sd	s6,24(a0)
     assert(pgdir[0] == 0);
ffffffffc0203552:	42079663          	bnez	a5,ffffffffc020397e <swap_init+0x52e>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc0203556:	6599                	lui	a1,0x6
ffffffffc0203558:	460d                	li	a2,3
ffffffffc020355a:	6505                	lui	a0,0x1
ffffffffc020355c:	43b000ef          	jal	ra,ffffffffc0204196 <vma_create>
ffffffffc0203560:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc0203562:	52050a63          	beqz	a0,ffffffffc0203a96 <swap_init+0x646>

     insert_vma_struct(mm, vma);
ffffffffc0203566:	8556                	mv	a0,s5
ffffffffc0203568:	49d000ef          	jal	ra,ffffffffc0204204 <insert_vma_struct>

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc020356c:	00004517          	auipc	a0,0x4
ffffffffc0203570:	61c50513          	addi	a0,a0,1564 # ffffffffc0207b88 <default_pmm_manager+0x7d0>
ffffffffc0203574:	c0dfc0ef          	jal	ra,ffffffffc0200180 <cprintf>
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc0203578:	018ab503          	ld	a0,24(s5)
ffffffffc020357c:	4605                	li	a2,1
ffffffffc020357e:	6585                	lui	a1,0x1
ffffffffc0203580:	89bfe0ef          	jal	ra,ffffffffc0201e1a <get_pte>
     assert(temp_ptep!= NULL);
ffffffffc0203584:	4c050963          	beqz	a0,ffffffffc0203a56 <swap_init+0x606>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0203588:	00004517          	auipc	a0,0x4
ffffffffc020358c:	65050513          	addi	a0,a0,1616 # ffffffffc0207bd8 <default_pmm_manager+0x820>
ffffffffc0203590:	000ab497          	auipc	s1,0xab
ffffffffc0203594:	3e848493          	addi	s1,s1,1000 # ffffffffc02ae978 <check_rp>
ffffffffc0203598:	be9fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc020359c:	000ab997          	auipc	s3,0xab
ffffffffc02035a0:	3fc98993          	addi	s3,s3,1020 # ffffffffc02ae998 <swap_in_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc02035a4:	8a26                	mv	s4,s1
          check_rp[i] = alloc_page();
ffffffffc02035a6:	4505                	li	a0,1
ffffffffc02035a8:	f66fe0ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc02035ac:	00aa3023          	sd	a0,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bd0>
          assert(check_rp[i] != NULL );
ffffffffc02035b0:	2c050f63          	beqz	a0,ffffffffc020388e <swap_init+0x43e>
ffffffffc02035b4:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc02035b6:	8b89                	andi	a5,a5,2
ffffffffc02035b8:	34079363          	bnez	a5,ffffffffc02038fe <swap_init+0x4ae>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02035bc:	0a21                	addi	s4,s4,8
ffffffffc02035be:	ff3a14e3          	bne	s4,s3,ffffffffc02035a6 <swap_init+0x156>
     }
     list_entry_t free_list_store = free_list;
ffffffffc02035c2:	601c                	ld	a5,0(s0)
     assert(list_empty(&free_list));
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
     nr_free = 0;
ffffffffc02035c4:	000aba17          	auipc	s4,0xab
ffffffffc02035c8:	3b4a0a13          	addi	s4,s4,948 # ffffffffc02ae978 <check_rp>
    elm->prev = elm->next = elm;
ffffffffc02035cc:	e000                	sd	s0,0(s0)
     list_entry_t free_list_store = free_list;
ffffffffc02035ce:	ec3e                	sd	a5,24(sp)
ffffffffc02035d0:	641c                	ld	a5,8(s0)
ffffffffc02035d2:	e400                	sd	s0,8(s0)
ffffffffc02035d4:	f03e                	sd	a5,32(sp)
     unsigned int nr_free_store = nr_free;
ffffffffc02035d6:	481c                	lw	a5,16(s0)
ffffffffc02035d8:	f43e                	sd	a5,40(sp)
     nr_free = 0;
ffffffffc02035da:	000ab797          	auipc	a5,0xab
ffffffffc02035de:	3607ab23          	sw	zero,886(a5) # ffffffffc02ae950 <free_area+0x10>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1);
ffffffffc02035e2:	000a3503          	ld	a0,0(s4)
ffffffffc02035e6:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02035e8:	0a21                	addi	s4,s4,8
        free_pages(check_rp[i],1);
ffffffffc02035ea:	fb6fe0ef          	jal	ra,ffffffffc0201da0 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02035ee:	ff3a1ae3          	bne	s4,s3,ffffffffc02035e2 <swap_init+0x192>
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc02035f2:	01042a03          	lw	s4,16(s0)
ffffffffc02035f6:	4791                	li	a5,4
ffffffffc02035f8:	42fa1f63          	bne	s4,a5,ffffffffc0203a36 <swap_init+0x5e6>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc02035fc:	00004517          	auipc	a0,0x4
ffffffffc0203600:	66450513          	addi	a0,a0,1636 # ffffffffc0207c60 <default_pmm_manager+0x8a8>
ffffffffc0203604:	b7dfc0ef          	jal	ra,ffffffffc0200180 <cprintf>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203608:	6705                	lui	a4,0x1
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
ffffffffc020360a:	000af797          	auipc	a5,0xaf
ffffffffc020360e:	4607a723          	sw	zero,1134(a5) # ffffffffc02b2a78 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203612:	4629                	li	a2,10
ffffffffc0203614:	00c70023          	sb	a2,0(a4) # 1000 <_binary_obj___user_faultread_out_size-0x8bd0>
     assert(pgfault_num==1);
ffffffffc0203618:	000af697          	auipc	a3,0xaf
ffffffffc020361c:	4606a683          	lw	a3,1120(a3) # ffffffffc02b2a78 <pgfault_num>
ffffffffc0203620:	4585                	li	a1,1
ffffffffc0203622:	000af797          	auipc	a5,0xaf
ffffffffc0203626:	45678793          	addi	a5,a5,1110 # ffffffffc02b2a78 <pgfault_num>
ffffffffc020362a:	54b69663          	bne	a3,a1,ffffffffc0203b76 <swap_init+0x726>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc020362e:	00c70823          	sb	a2,16(a4)
     assert(pgfault_num==1);
ffffffffc0203632:	4398                	lw	a4,0(a5)
ffffffffc0203634:	2701                	sext.w	a4,a4
ffffffffc0203636:	3ed71063          	bne	a4,a3,ffffffffc0203a16 <swap_init+0x5c6>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc020363a:	6689                	lui	a3,0x2
ffffffffc020363c:	462d                	li	a2,11
ffffffffc020363e:	00c68023          	sb	a2,0(a3) # 2000 <_binary_obj___user_faultread_out_size-0x7bd0>
     assert(pgfault_num==2);
ffffffffc0203642:	4398                	lw	a4,0(a5)
ffffffffc0203644:	4589                	li	a1,2
ffffffffc0203646:	2701                	sext.w	a4,a4
ffffffffc0203648:	4ab71763          	bne	a4,a1,ffffffffc0203af6 <swap_init+0x6a6>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc020364c:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==2);
ffffffffc0203650:	4394                	lw	a3,0(a5)
ffffffffc0203652:	2681                	sext.w	a3,a3
ffffffffc0203654:	4ce69163          	bne	a3,a4,ffffffffc0203b16 <swap_init+0x6c6>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203658:	668d                	lui	a3,0x3
ffffffffc020365a:	4631                	li	a2,12
ffffffffc020365c:	00c68023          	sb	a2,0(a3) # 3000 <_binary_obj___user_faultread_out_size-0x6bd0>
     assert(pgfault_num==3);
ffffffffc0203660:	4398                	lw	a4,0(a5)
ffffffffc0203662:	458d                	li	a1,3
ffffffffc0203664:	2701                	sext.w	a4,a4
ffffffffc0203666:	4cb71863          	bne	a4,a1,ffffffffc0203b36 <swap_init+0x6e6>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc020366a:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==3);
ffffffffc020366e:	4394                	lw	a3,0(a5)
ffffffffc0203670:	2681                	sext.w	a3,a3
ffffffffc0203672:	4ee69263          	bne	a3,a4,ffffffffc0203b56 <swap_init+0x706>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203676:	6691                	lui	a3,0x4
ffffffffc0203678:	4635                	li	a2,13
ffffffffc020367a:	00c68023          	sb	a2,0(a3) # 4000 <_binary_obj___user_faultread_out_size-0x5bd0>
     assert(pgfault_num==4);
ffffffffc020367e:	4398                	lw	a4,0(a5)
ffffffffc0203680:	2701                	sext.w	a4,a4
ffffffffc0203682:	43471a63          	bne	a4,s4,ffffffffc0203ab6 <swap_init+0x666>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc0203686:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==4);
ffffffffc020368a:	439c                	lw	a5,0(a5)
ffffffffc020368c:	2781                	sext.w	a5,a5
ffffffffc020368e:	44e79463          	bne	a5,a4,ffffffffc0203ad6 <swap_init+0x686>
     
     check_content_set();
     assert( nr_free == 0);         
ffffffffc0203692:	481c                	lw	a5,16(s0)
ffffffffc0203694:	2c079563          	bnez	a5,ffffffffc020395e <swap_init+0x50e>
ffffffffc0203698:	000ab797          	auipc	a5,0xab
ffffffffc020369c:	30078793          	addi	a5,a5,768 # ffffffffc02ae998 <swap_in_seq_no>
ffffffffc02036a0:	000ab717          	auipc	a4,0xab
ffffffffc02036a4:	32070713          	addi	a4,a4,800 # ffffffffc02ae9c0 <swap_out_seq_no>
ffffffffc02036a8:	000ab617          	auipc	a2,0xab
ffffffffc02036ac:	31860613          	addi	a2,a2,792 # ffffffffc02ae9c0 <swap_out_seq_no>
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
ffffffffc02036b0:	56fd                	li	a3,-1
ffffffffc02036b2:	c394                	sw	a3,0(a5)
ffffffffc02036b4:	c314                	sw	a3,0(a4)
     for(i = 0; i<MAX_SEQ_NO ; i++) 
ffffffffc02036b6:	0791                	addi	a5,a5,4
ffffffffc02036b8:	0711                	addi	a4,a4,4
ffffffffc02036ba:	fec79ce3          	bne	a5,a2,ffffffffc02036b2 <swap_init+0x262>
ffffffffc02036be:	000ab717          	auipc	a4,0xab
ffffffffc02036c2:	29a70713          	addi	a4,a4,666 # ffffffffc02ae958 <check_ptep>
ffffffffc02036c6:	000ab697          	auipc	a3,0xab
ffffffffc02036ca:	2b268693          	addi	a3,a3,690 # ffffffffc02ae978 <check_rp>
ffffffffc02036ce:	6585                	lui	a1,0x1
    if (PPN(pa) >= npage) {
ffffffffc02036d0:	000afc17          	auipc	s8,0xaf
ffffffffc02036d4:	368c0c13          	addi	s8,s8,872 # ffffffffc02b2a38 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02036d8:	000afc97          	auipc	s9,0xaf
ffffffffc02036dc:	368c8c93          	addi	s9,s9,872 # ffffffffc02b2a40 <pages>
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
ffffffffc02036e0:	00073023          	sd	zero,0(a4)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc02036e4:	4601                	li	a2,0
ffffffffc02036e6:	855a                	mv	a0,s6
ffffffffc02036e8:	e836                	sd	a3,16(sp)
ffffffffc02036ea:	e42e                	sd	a1,8(sp)
         check_ptep[i]=0;
ffffffffc02036ec:	e03a                	sd	a4,0(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc02036ee:	f2cfe0ef          	jal	ra,ffffffffc0201e1a <get_pte>
ffffffffc02036f2:	6702                	ld	a4,0(sp)
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
ffffffffc02036f4:	65a2                	ld	a1,8(sp)
ffffffffc02036f6:	66c2                	ld	a3,16(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc02036f8:	e308                	sd	a0,0(a4)
         assert(check_ptep[i] != NULL);
ffffffffc02036fa:	1c050663          	beqz	a0,ffffffffc02038c6 <swap_init+0x476>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc02036fe:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0203700:	0017f613          	andi	a2,a5,1
ffffffffc0203704:	1e060163          	beqz	a2,ffffffffc02038e6 <swap_init+0x496>
    if (PPN(pa) >= npage) {
ffffffffc0203708:	000c3603          	ld	a2,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc020370c:	078a                	slli	a5,a5,0x2
ffffffffc020370e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203710:	14c7f363          	bgeu	a5,a2,ffffffffc0203856 <swap_init+0x406>
    return &pages[PPN(pa) - nbase];
ffffffffc0203714:	00005617          	auipc	a2,0x5
ffffffffc0203718:	62c60613          	addi	a2,a2,1580 # ffffffffc0208d40 <nbase>
ffffffffc020371c:	00063a03          	ld	s4,0(a2)
ffffffffc0203720:	000cb603          	ld	a2,0(s9)
ffffffffc0203724:	6288                	ld	a0,0(a3)
ffffffffc0203726:	414787b3          	sub	a5,a5,s4
ffffffffc020372a:	079a                	slli	a5,a5,0x6
ffffffffc020372c:	97b2                	add	a5,a5,a2
ffffffffc020372e:	14f51063          	bne	a0,a5,ffffffffc020386e <swap_init+0x41e>
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203732:	6785                	lui	a5,0x1
ffffffffc0203734:	95be                	add	a1,a1,a5
ffffffffc0203736:	6795                	lui	a5,0x5
ffffffffc0203738:	0721                	addi	a4,a4,8
ffffffffc020373a:	06a1                	addi	a3,a3,8
ffffffffc020373c:	faf592e3          	bne	a1,a5,ffffffffc02036e0 <swap_init+0x290>
         assert((*check_ptep[i] & PTE_V));          
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc0203740:	00004517          	auipc	a0,0x4
ffffffffc0203744:	5c850513          	addi	a0,a0,1480 # ffffffffc0207d08 <default_pmm_manager+0x950>
ffffffffc0203748:	a39fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    int ret = sm->check_swap();
ffffffffc020374c:	000bb783          	ld	a5,0(s7)
ffffffffc0203750:	7f9c                	ld	a5,56(a5)
ffffffffc0203752:	9782                	jalr	a5
     // now access the virt pages to test  page relpacement algorithm 
     ret=check_content_access();
     assert(ret==0);
ffffffffc0203754:	32051163          	bnez	a0,ffffffffc0203a76 <swap_init+0x626>

     nr_free = nr_free_store;
ffffffffc0203758:	77a2                	ld	a5,40(sp)
ffffffffc020375a:	c81c                	sw	a5,16(s0)
     free_list = free_list_store;
ffffffffc020375c:	67e2                	ld	a5,24(sp)
ffffffffc020375e:	e01c                	sd	a5,0(s0)
ffffffffc0203760:	7782                	ld	a5,32(sp)
ffffffffc0203762:	e41c                	sd	a5,8(s0)

     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1);
ffffffffc0203764:	6088                	ld	a0,0(s1)
ffffffffc0203766:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203768:	04a1                	addi	s1,s1,8
         free_pages(check_rp[i],1);
ffffffffc020376a:	e36fe0ef          	jal	ra,ffffffffc0201da0 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc020376e:	ff349be3          	bne	s1,s3,ffffffffc0203764 <swap_init+0x314>
     } 

     //free_page(pte2page(*temp_ptep));

     mm->pgdir = NULL;
ffffffffc0203772:	000abc23          	sd	zero,24(s5)
     mm_destroy(mm);
ffffffffc0203776:	8556                	mv	a0,s5
ffffffffc0203778:	35d000ef          	jal	ra,ffffffffc02042d4 <mm_destroy>
     check_mm_struct = NULL;

     pde_t *pd1=pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc020377c:	000af797          	auipc	a5,0xaf
ffffffffc0203780:	2b478793          	addi	a5,a5,692 # ffffffffc02b2a30 <boot_pgdir>
ffffffffc0203784:	639c                	ld	a5,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc0203786:	000c3703          	ld	a4,0(s8)
     check_mm_struct = NULL;
ffffffffc020378a:	000af697          	auipc	a3,0xaf
ffffffffc020378e:	2e06b323          	sd	zero,742(a3) # ffffffffc02b2a70 <check_mm_struct>
    return pa2page(PDE_ADDR(pde));
ffffffffc0203792:	639c                	ld	a5,0(a5)
ffffffffc0203794:	078a                	slli	a5,a5,0x2
ffffffffc0203796:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203798:	0ae7fd63          	bgeu	a5,a4,ffffffffc0203852 <swap_init+0x402>
    return &pages[PPN(pa) - nbase];
ffffffffc020379c:	414786b3          	sub	a3,a5,s4
ffffffffc02037a0:	069a                	slli	a3,a3,0x6
    return page - pages + nbase;
ffffffffc02037a2:	8699                	srai	a3,a3,0x6
ffffffffc02037a4:	96d2                	add	a3,a3,s4
    return KADDR(page2pa(page));
ffffffffc02037a6:	00c69793          	slli	a5,a3,0xc
ffffffffc02037aa:	83b1                	srli	a5,a5,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc02037ac:	000cb503          	ld	a0,0(s9)
    return page2ppn(page) << PGSHIFT;
ffffffffc02037b0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02037b2:	22e7f663          	bgeu	a5,a4,ffffffffc02039de <swap_init+0x58e>
     free_page(pde2page(pd0[0]));
ffffffffc02037b6:	000af797          	auipc	a5,0xaf
ffffffffc02037ba:	29a7b783          	ld	a5,666(a5) # ffffffffc02b2a50 <va_pa_offset>
ffffffffc02037be:	96be                	add	a3,a3,a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02037c0:	629c                	ld	a5,0(a3)
ffffffffc02037c2:	078a                	slli	a5,a5,0x2
ffffffffc02037c4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02037c6:	08e7f663          	bgeu	a5,a4,ffffffffc0203852 <swap_init+0x402>
    return &pages[PPN(pa) - nbase];
ffffffffc02037ca:	414787b3          	sub	a5,a5,s4
ffffffffc02037ce:	079a                	slli	a5,a5,0x6
ffffffffc02037d0:	953e                	add	a0,a0,a5
ffffffffc02037d2:	4585                	li	a1,1
ffffffffc02037d4:	dccfe0ef          	jal	ra,ffffffffc0201da0 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc02037d8:	000b3783          	ld	a5,0(s6)
    if (PPN(pa) >= npage) {
ffffffffc02037dc:	000c3703          	ld	a4,0(s8)
    return pa2page(PDE_ADDR(pde));
ffffffffc02037e0:	078a                	slli	a5,a5,0x2
ffffffffc02037e2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02037e4:	06e7f763          	bgeu	a5,a4,ffffffffc0203852 <swap_init+0x402>
    return &pages[PPN(pa) - nbase];
ffffffffc02037e8:	000cb503          	ld	a0,0(s9)
ffffffffc02037ec:	414787b3          	sub	a5,a5,s4
ffffffffc02037f0:	079a                	slli	a5,a5,0x6
     free_page(pde2page(pd1[0]));
ffffffffc02037f2:	4585                	li	a1,1
ffffffffc02037f4:	953e                	add	a0,a0,a5
ffffffffc02037f6:	daafe0ef          	jal	ra,ffffffffc0201da0 <free_pages>
     pgdir[0] = 0;
ffffffffc02037fa:	000b3023          	sd	zero,0(s6)
  asm volatile("sfence.vma");
ffffffffc02037fe:	12000073          	sfence.vma
    return listelm->next;
ffffffffc0203802:	641c                	ld	a5,8(s0)
     flush_tlb();

     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203804:	00878a63          	beq	a5,s0,ffffffffc0203818 <swap_init+0x3c8>
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
ffffffffc0203808:	ff87a703          	lw	a4,-8(a5)
ffffffffc020380c:	679c                	ld	a5,8(a5)
ffffffffc020380e:	3dfd                	addiw	s11,s11,-1
ffffffffc0203810:	40ed0d3b          	subw	s10,s10,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203814:	fe879ae3          	bne	a5,s0,ffffffffc0203808 <swap_init+0x3b8>
     }
     assert(count==0);
ffffffffc0203818:	1c0d9f63          	bnez	s11,ffffffffc02039f6 <swap_init+0x5a6>
     assert(total==0);
ffffffffc020381c:	1a0d1163          	bnez	s10,ffffffffc02039be <swap_init+0x56e>

     cprintf("check_swap() succeeded!\n");
ffffffffc0203820:	00004517          	auipc	a0,0x4
ffffffffc0203824:	53850513          	addi	a0,a0,1336 # ffffffffc0207d58 <default_pmm_manager+0x9a0>
ffffffffc0203828:	959fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
}
ffffffffc020382c:	b99d                	j	ffffffffc02034a2 <swap_init+0x52>
     while ((le = list_next(le)) != &free_list) {
ffffffffc020382e:	4481                	li	s1,0
ffffffffc0203830:	b9f1                	j	ffffffffc020350c <swap_init+0xbc>
        assert(PageProperty(p));
ffffffffc0203832:	00003697          	auipc	a3,0x3
ffffffffc0203836:	7de68693          	addi	a3,a3,2014 # ffffffffc0207010 <commands+0x7a0>
ffffffffc020383a:	00003617          	auipc	a2,0x3
ffffffffc020383e:	48660613          	addi	a2,a2,1158 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203842:	0bc00593          	li	a1,188
ffffffffc0203846:	00004517          	auipc	a0,0x4
ffffffffc020384a:	2aa50513          	addi	a0,a0,682 # ffffffffc0207af0 <default_pmm_manager+0x738>
ffffffffc020384e:	c2dfc0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc0203852:	be3ff0ef          	jal	ra,ffffffffc0203434 <pa2page.part.0>
        panic("pa2page called with invalid pa");
ffffffffc0203856:	00004617          	auipc	a2,0x4
ffffffffc020385a:	c6a60613          	addi	a2,a2,-918 # ffffffffc02074c0 <default_pmm_manager+0x108>
ffffffffc020385e:	06200593          	li	a1,98
ffffffffc0203862:	00004517          	auipc	a0,0x4
ffffffffc0203866:	bb650513          	addi	a0,a0,-1098 # ffffffffc0207418 <default_pmm_manager+0x60>
ffffffffc020386a:	c11fc0ef          	jal	ra,ffffffffc020047a <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc020386e:	00004697          	auipc	a3,0x4
ffffffffc0203872:	47268693          	addi	a3,a3,1138 # ffffffffc0207ce0 <default_pmm_manager+0x928>
ffffffffc0203876:	00003617          	auipc	a2,0x3
ffffffffc020387a:	44a60613          	addi	a2,a2,1098 # ffffffffc0206cc0 <commands+0x450>
ffffffffc020387e:	0fc00593          	li	a1,252
ffffffffc0203882:	00004517          	auipc	a0,0x4
ffffffffc0203886:	26e50513          	addi	a0,a0,622 # ffffffffc0207af0 <default_pmm_manager+0x738>
ffffffffc020388a:	bf1fc0ef          	jal	ra,ffffffffc020047a <__panic>
          assert(check_rp[i] != NULL );
ffffffffc020388e:	00004697          	auipc	a3,0x4
ffffffffc0203892:	37268693          	addi	a3,a3,882 # ffffffffc0207c00 <default_pmm_manager+0x848>
ffffffffc0203896:	00003617          	auipc	a2,0x3
ffffffffc020389a:	42a60613          	addi	a2,a2,1066 # ffffffffc0206cc0 <commands+0x450>
ffffffffc020389e:	0dc00593          	li	a1,220
ffffffffc02038a2:	00004517          	auipc	a0,0x4
ffffffffc02038a6:	24e50513          	addi	a0,a0,590 # ffffffffc0207af0 <default_pmm_manager+0x738>
ffffffffc02038aa:	bd1fc0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc02038ae:	00004617          	auipc	a2,0x4
ffffffffc02038b2:	22260613          	addi	a2,a2,546 # ffffffffc0207ad0 <default_pmm_manager+0x718>
ffffffffc02038b6:	02800593          	li	a1,40
ffffffffc02038ba:	00004517          	auipc	a0,0x4
ffffffffc02038be:	23650513          	addi	a0,a0,566 # ffffffffc0207af0 <default_pmm_manager+0x738>
ffffffffc02038c2:	bb9fc0ef          	jal	ra,ffffffffc020047a <__panic>
         assert(check_ptep[i] != NULL);
ffffffffc02038c6:	00004697          	auipc	a3,0x4
ffffffffc02038ca:	40268693          	addi	a3,a3,1026 # ffffffffc0207cc8 <default_pmm_manager+0x910>
ffffffffc02038ce:	00003617          	auipc	a2,0x3
ffffffffc02038d2:	3f260613          	addi	a2,a2,1010 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02038d6:	0fb00593          	li	a1,251
ffffffffc02038da:	00004517          	auipc	a0,0x4
ffffffffc02038de:	21650513          	addi	a0,a0,534 # ffffffffc0207af0 <default_pmm_manager+0x738>
ffffffffc02038e2:	b99fc0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02038e6:	00004617          	auipc	a2,0x4
ffffffffc02038ea:	bfa60613          	addi	a2,a2,-1030 # ffffffffc02074e0 <default_pmm_manager+0x128>
ffffffffc02038ee:	07400593          	li	a1,116
ffffffffc02038f2:	00004517          	auipc	a0,0x4
ffffffffc02038f6:	b2650513          	addi	a0,a0,-1242 # ffffffffc0207418 <default_pmm_manager+0x60>
ffffffffc02038fa:	b81fc0ef          	jal	ra,ffffffffc020047a <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc02038fe:	00004697          	auipc	a3,0x4
ffffffffc0203902:	31a68693          	addi	a3,a3,794 # ffffffffc0207c18 <default_pmm_manager+0x860>
ffffffffc0203906:	00003617          	auipc	a2,0x3
ffffffffc020390a:	3ba60613          	addi	a2,a2,954 # ffffffffc0206cc0 <commands+0x450>
ffffffffc020390e:	0dd00593          	li	a1,221
ffffffffc0203912:	00004517          	auipc	a0,0x4
ffffffffc0203916:	1de50513          	addi	a0,a0,478 # ffffffffc0207af0 <default_pmm_manager+0x738>
ffffffffc020391a:	b61fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(check_mm_struct == NULL);
ffffffffc020391e:	00004697          	auipc	a3,0x4
ffffffffc0203922:	23268693          	addi	a3,a3,562 # ffffffffc0207b50 <default_pmm_manager+0x798>
ffffffffc0203926:	00003617          	auipc	a2,0x3
ffffffffc020392a:	39a60613          	addi	a2,a2,922 # ffffffffc0206cc0 <commands+0x450>
ffffffffc020392e:	0c700593          	li	a1,199
ffffffffc0203932:	00004517          	auipc	a0,0x4
ffffffffc0203936:	1be50513          	addi	a0,a0,446 # ffffffffc0207af0 <default_pmm_manager+0x738>
ffffffffc020393a:	b41fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(total == nr_free_pages());
ffffffffc020393e:	00003697          	auipc	a3,0x3
ffffffffc0203942:	6fa68693          	addi	a3,a3,1786 # ffffffffc0207038 <commands+0x7c8>
ffffffffc0203946:	00003617          	auipc	a2,0x3
ffffffffc020394a:	37a60613          	addi	a2,a2,890 # ffffffffc0206cc0 <commands+0x450>
ffffffffc020394e:	0bf00593          	li	a1,191
ffffffffc0203952:	00004517          	auipc	a0,0x4
ffffffffc0203956:	19e50513          	addi	a0,a0,414 # ffffffffc0207af0 <default_pmm_manager+0x738>
ffffffffc020395a:	b21fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert( nr_free == 0);         
ffffffffc020395e:	00004697          	auipc	a3,0x4
ffffffffc0203962:	88268693          	addi	a3,a3,-1918 # ffffffffc02071e0 <commands+0x970>
ffffffffc0203966:	00003617          	auipc	a2,0x3
ffffffffc020396a:	35a60613          	addi	a2,a2,858 # ffffffffc0206cc0 <commands+0x450>
ffffffffc020396e:	0f300593          	li	a1,243
ffffffffc0203972:	00004517          	auipc	a0,0x4
ffffffffc0203976:	17e50513          	addi	a0,a0,382 # ffffffffc0207af0 <default_pmm_manager+0x738>
ffffffffc020397a:	b01fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(pgdir[0] == 0);
ffffffffc020397e:	00004697          	auipc	a3,0x4
ffffffffc0203982:	1ea68693          	addi	a3,a3,490 # ffffffffc0207b68 <default_pmm_manager+0x7b0>
ffffffffc0203986:	00003617          	auipc	a2,0x3
ffffffffc020398a:	33a60613          	addi	a2,a2,826 # ffffffffc0206cc0 <commands+0x450>
ffffffffc020398e:	0cc00593          	li	a1,204
ffffffffc0203992:	00004517          	auipc	a0,0x4
ffffffffc0203996:	15e50513          	addi	a0,a0,350 # ffffffffc0207af0 <default_pmm_manager+0x738>
ffffffffc020399a:	ae1fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(mm != NULL);
ffffffffc020399e:	00004697          	auipc	a3,0x4
ffffffffc02039a2:	1a268693          	addi	a3,a3,418 # ffffffffc0207b40 <default_pmm_manager+0x788>
ffffffffc02039a6:	00003617          	auipc	a2,0x3
ffffffffc02039aa:	31a60613          	addi	a2,a2,794 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02039ae:	0c400593          	li	a1,196
ffffffffc02039b2:	00004517          	auipc	a0,0x4
ffffffffc02039b6:	13e50513          	addi	a0,a0,318 # ffffffffc0207af0 <default_pmm_manager+0x738>
ffffffffc02039ba:	ac1fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(total==0);
ffffffffc02039be:	00004697          	auipc	a3,0x4
ffffffffc02039c2:	38a68693          	addi	a3,a3,906 # ffffffffc0207d48 <default_pmm_manager+0x990>
ffffffffc02039c6:	00003617          	auipc	a2,0x3
ffffffffc02039ca:	2fa60613          	addi	a2,a2,762 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02039ce:	11e00593          	li	a1,286
ffffffffc02039d2:	00004517          	auipc	a0,0x4
ffffffffc02039d6:	11e50513          	addi	a0,a0,286 # ffffffffc0207af0 <default_pmm_manager+0x738>
ffffffffc02039da:	aa1fc0ef          	jal	ra,ffffffffc020047a <__panic>
    return KADDR(page2pa(page));
ffffffffc02039de:	00004617          	auipc	a2,0x4
ffffffffc02039e2:	a1260613          	addi	a2,a2,-1518 # ffffffffc02073f0 <default_pmm_manager+0x38>
ffffffffc02039e6:	06900593          	li	a1,105
ffffffffc02039ea:	00004517          	auipc	a0,0x4
ffffffffc02039ee:	a2e50513          	addi	a0,a0,-1490 # ffffffffc0207418 <default_pmm_manager+0x60>
ffffffffc02039f2:	a89fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(count==0);
ffffffffc02039f6:	00004697          	auipc	a3,0x4
ffffffffc02039fa:	34268693          	addi	a3,a3,834 # ffffffffc0207d38 <default_pmm_manager+0x980>
ffffffffc02039fe:	00003617          	auipc	a2,0x3
ffffffffc0203a02:	2c260613          	addi	a2,a2,706 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203a06:	11d00593          	li	a1,285
ffffffffc0203a0a:	00004517          	auipc	a0,0x4
ffffffffc0203a0e:	0e650513          	addi	a0,a0,230 # ffffffffc0207af0 <default_pmm_manager+0x738>
ffffffffc0203a12:	a69fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(pgfault_num==1);
ffffffffc0203a16:	00004697          	auipc	a3,0x4
ffffffffc0203a1a:	27268693          	addi	a3,a3,626 # ffffffffc0207c88 <default_pmm_manager+0x8d0>
ffffffffc0203a1e:	00003617          	auipc	a2,0x3
ffffffffc0203a22:	2a260613          	addi	a2,a2,674 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203a26:	09500593          	li	a1,149
ffffffffc0203a2a:	00004517          	auipc	a0,0x4
ffffffffc0203a2e:	0c650513          	addi	a0,a0,198 # ffffffffc0207af0 <default_pmm_manager+0x738>
ffffffffc0203a32:	a49fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0203a36:	00004697          	auipc	a3,0x4
ffffffffc0203a3a:	20268693          	addi	a3,a3,514 # ffffffffc0207c38 <default_pmm_manager+0x880>
ffffffffc0203a3e:	00003617          	auipc	a2,0x3
ffffffffc0203a42:	28260613          	addi	a2,a2,642 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203a46:	0ea00593          	li	a1,234
ffffffffc0203a4a:	00004517          	auipc	a0,0x4
ffffffffc0203a4e:	0a650513          	addi	a0,a0,166 # ffffffffc0207af0 <default_pmm_manager+0x738>
ffffffffc0203a52:	a29fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(temp_ptep!= NULL);
ffffffffc0203a56:	00004697          	auipc	a3,0x4
ffffffffc0203a5a:	16a68693          	addi	a3,a3,362 # ffffffffc0207bc0 <default_pmm_manager+0x808>
ffffffffc0203a5e:	00003617          	auipc	a2,0x3
ffffffffc0203a62:	26260613          	addi	a2,a2,610 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203a66:	0d700593          	li	a1,215
ffffffffc0203a6a:	00004517          	auipc	a0,0x4
ffffffffc0203a6e:	08650513          	addi	a0,a0,134 # ffffffffc0207af0 <default_pmm_manager+0x738>
ffffffffc0203a72:	a09fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(ret==0);
ffffffffc0203a76:	00004697          	auipc	a3,0x4
ffffffffc0203a7a:	2ba68693          	addi	a3,a3,698 # ffffffffc0207d30 <default_pmm_manager+0x978>
ffffffffc0203a7e:	00003617          	auipc	a2,0x3
ffffffffc0203a82:	24260613          	addi	a2,a2,578 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203a86:	10200593          	li	a1,258
ffffffffc0203a8a:	00004517          	auipc	a0,0x4
ffffffffc0203a8e:	06650513          	addi	a0,a0,102 # ffffffffc0207af0 <default_pmm_manager+0x738>
ffffffffc0203a92:	9e9fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(vma != NULL);
ffffffffc0203a96:	00004697          	auipc	a3,0x4
ffffffffc0203a9a:	0e268693          	addi	a3,a3,226 # ffffffffc0207b78 <default_pmm_manager+0x7c0>
ffffffffc0203a9e:	00003617          	auipc	a2,0x3
ffffffffc0203aa2:	22260613          	addi	a2,a2,546 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203aa6:	0cf00593          	li	a1,207
ffffffffc0203aaa:	00004517          	auipc	a0,0x4
ffffffffc0203aae:	04650513          	addi	a0,a0,70 # ffffffffc0207af0 <default_pmm_manager+0x738>
ffffffffc0203ab2:	9c9fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(pgfault_num==4);
ffffffffc0203ab6:	00004697          	auipc	a3,0x4
ffffffffc0203aba:	20268693          	addi	a3,a3,514 # ffffffffc0207cb8 <default_pmm_manager+0x900>
ffffffffc0203abe:	00003617          	auipc	a2,0x3
ffffffffc0203ac2:	20260613          	addi	a2,a2,514 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203ac6:	09f00593          	li	a1,159
ffffffffc0203aca:	00004517          	auipc	a0,0x4
ffffffffc0203ace:	02650513          	addi	a0,a0,38 # ffffffffc0207af0 <default_pmm_manager+0x738>
ffffffffc0203ad2:	9a9fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(pgfault_num==4);
ffffffffc0203ad6:	00004697          	auipc	a3,0x4
ffffffffc0203ada:	1e268693          	addi	a3,a3,482 # ffffffffc0207cb8 <default_pmm_manager+0x900>
ffffffffc0203ade:	00003617          	auipc	a2,0x3
ffffffffc0203ae2:	1e260613          	addi	a2,a2,482 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203ae6:	0a100593          	li	a1,161
ffffffffc0203aea:	00004517          	auipc	a0,0x4
ffffffffc0203aee:	00650513          	addi	a0,a0,6 # ffffffffc0207af0 <default_pmm_manager+0x738>
ffffffffc0203af2:	989fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(pgfault_num==2);
ffffffffc0203af6:	00004697          	auipc	a3,0x4
ffffffffc0203afa:	1a268693          	addi	a3,a3,418 # ffffffffc0207c98 <default_pmm_manager+0x8e0>
ffffffffc0203afe:	00003617          	auipc	a2,0x3
ffffffffc0203b02:	1c260613          	addi	a2,a2,450 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203b06:	09700593          	li	a1,151
ffffffffc0203b0a:	00004517          	auipc	a0,0x4
ffffffffc0203b0e:	fe650513          	addi	a0,a0,-26 # ffffffffc0207af0 <default_pmm_manager+0x738>
ffffffffc0203b12:	969fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(pgfault_num==2);
ffffffffc0203b16:	00004697          	auipc	a3,0x4
ffffffffc0203b1a:	18268693          	addi	a3,a3,386 # ffffffffc0207c98 <default_pmm_manager+0x8e0>
ffffffffc0203b1e:	00003617          	auipc	a2,0x3
ffffffffc0203b22:	1a260613          	addi	a2,a2,418 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203b26:	09900593          	li	a1,153
ffffffffc0203b2a:	00004517          	auipc	a0,0x4
ffffffffc0203b2e:	fc650513          	addi	a0,a0,-58 # ffffffffc0207af0 <default_pmm_manager+0x738>
ffffffffc0203b32:	949fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(pgfault_num==3);
ffffffffc0203b36:	00004697          	auipc	a3,0x4
ffffffffc0203b3a:	17268693          	addi	a3,a3,370 # ffffffffc0207ca8 <default_pmm_manager+0x8f0>
ffffffffc0203b3e:	00003617          	auipc	a2,0x3
ffffffffc0203b42:	18260613          	addi	a2,a2,386 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203b46:	09b00593          	li	a1,155
ffffffffc0203b4a:	00004517          	auipc	a0,0x4
ffffffffc0203b4e:	fa650513          	addi	a0,a0,-90 # ffffffffc0207af0 <default_pmm_manager+0x738>
ffffffffc0203b52:	929fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(pgfault_num==3);
ffffffffc0203b56:	00004697          	auipc	a3,0x4
ffffffffc0203b5a:	15268693          	addi	a3,a3,338 # ffffffffc0207ca8 <default_pmm_manager+0x8f0>
ffffffffc0203b5e:	00003617          	auipc	a2,0x3
ffffffffc0203b62:	16260613          	addi	a2,a2,354 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203b66:	09d00593          	li	a1,157
ffffffffc0203b6a:	00004517          	auipc	a0,0x4
ffffffffc0203b6e:	f8650513          	addi	a0,a0,-122 # ffffffffc0207af0 <default_pmm_manager+0x738>
ffffffffc0203b72:	909fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(pgfault_num==1);
ffffffffc0203b76:	00004697          	auipc	a3,0x4
ffffffffc0203b7a:	11268693          	addi	a3,a3,274 # ffffffffc0207c88 <default_pmm_manager+0x8d0>
ffffffffc0203b7e:	00003617          	auipc	a2,0x3
ffffffffc0203b82:	14260613          	addi	a2,a2,322 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203b86:	09300593          	li	a1,147
ffffffffc0203b8a:	00004517          	auipc	a0,0x4
ffffffffc0203b8e:	f6650513          	addi	a0,a0,-154 # ffffffffc0207af0 <default_pmm_manager+0x738>
ffffffffc0203b92:	8e9fc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0203b96 <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc0203b96:	000af797          	auipc	a5,0xaf
ffffffffc0203b9a:	eca7b783          	ld	a5,-310(a5) # ffffffffc02b2a60 <sm>
ffffffffc0203b9e:	6b9c                	ld	a5,16(a5)
ffffffffc0203ba0:	8782                	jr	a5

ffffffffc0203ba2 <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc0203ba2:	000af797          	auipc	a5,0xaf
ffffffffc0203ba6:	ebe7b783          	ld	a5,-322(a5) # ffffffffc02b2a60 <sm>
ffffffffc0203baa:	739c                	ld	a5,32(a5)
ffffffffc0203bac:	8782                	jr	a5

ffffffffc0203bae <swap_out>:
{
ffffffffc0203bae:	711d                	addi	sp,sp,-96
ffffffffc0203bb0:	ec86                	sd	ra,88(sp)
ffffffffc0203bb2:	e8a2                	sd	s0,80(sp)
ffffffffc0203bb4:	e4a6                	sd	s1,72(sp)
ffffffffc0203bb6:	e0ca                	sd	s2,64(sp)
ffffffffc0203bb8:	fc4e                	sd	s3,56(sp)
ffffffffc0203bba:	f852                	sd	s4,48(sp)
ffffffffc0203bbc:	f456                	sd	s5,40(sp)
ffffffffc0203bbe:	f05a                	sd	s6,32(sp)
ffffffffc0203bc0:	ec5e                	sd	s7,24(sp)
ffffffffc0203bc2:	e862                	sd	s8,16(sp)
     for (i = 0; i != n; ++ i)
ffffffffc0203bc4:	cde9                	beqz	a1,ffffffffc0203c9e <swap_out+0xf0>
ffffffffc0203bc6:	8a2e                	mv	s4,a1
ffffffffc0203bc8:	892a                	mv	s2,a0
ffffffffc0203bca:	8ab2                	mv	s5,a2
ffffffffc0203bcc:	4401                	li	s0,0
ffffffffc0203bce:	000af997          	auipc	s3,0xaf
ffffffffc0203bd2:	e9298993          	addi	s3,s3,-366 # ffffffffc02b2a60 <sm>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203bd6:	00004b17          	auipc	s6,0x4
ffffffffc0203bda:	202b0b13          	addi	s6,s6,514 # ffffffffc0207dd8 <default_pmm_manager+0xa20>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203bde:	00004b97          	auipc	s7,0x4
ffffffffc0203be2:	1e2b8b93          	addi	s7,s7,482 # ffffffffc0207dc0 <default_pmm_manager+0xa08>
ffffffffc0203be6:	a825                	j	ffffffffc0203c1e <swap_out+0x70>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203be8:	67a2                	ld	a5,8(sp)
ffffffffc0203bea:	8626                	mv	a2,s1
ffffffffc0203bec:	85a2                	mv	a1,s0
ffffffffc0203bee:	7f94                	ld	a3,56(a5)
ffffffffc0203bf0:	855a                	mv	a0,s6
     for (i = 0; i != n; ++ i)
ffffffffc0203bf2:	2405                	addiw	s0,s0,1
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203bf4:	82b1                	srli	a3,a3,0xc
ffffffffc0203bf6:	0685                	addi	a3,a3,1
ffffffffc0203bf8:	d88fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0203bfc:	6522                	ld	a0,8(sp)
                    free_page(page);
ffffffffc0203bfe:	4585                	li	a1,1
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0203c00:	7d1c                	ld	a5,56(a0)
ffffffffc0203c02:	83b1                	srli	a5,a5,0xc
ffffffffc0203c04:	0785                	addi	a5,a5,1
ffffffffc0203c06:	07a2                	slli	a5,a5,0x8
ffffffffc0203c08:	00fc3023          	sd	a5,0(s8)
                    free_page(page);
ffffffffc0203c0c:	994fe0ef          	jal	ra,ffffffffc0201da0 <free_pages>
          tlb_invalidate(mm->pgdir, v);
ffffffffc0203c10:	01893503          	ld	a0,24(s2)
ffffffffc0203c14:	85a6                	mv	a1,s1
ffffffffc0203c16:	f5eff0ef          	jal	ra,ffffffffc0203374 <tlb_invalidate>
     for (i = 0; i != n; ++ i)
ffffffffc0203c1a:	048a0d63          	beq	s4,s0,ffffffffc0203c74 <swap_out+0xc6>
          int r = sm->swap_out_victim(mm, &page, in_tick);
ffffffffc0203c1e:	0009b783          	ld	a5,0(s3)
ffffffffc0203c22:	8656                	mv	a2,s5
ffffffffc0203c24:	002c                	addi	a1,sp,8
ffffffffc0203c26:	7b9c                	ld	a5,48(a5)
ffffffffc0203c28:	854a                	mv	a0,s2
ffffffffc0203c2a:	9782                	jalr	a5
          if (r != 0) {
ffffffffc0203c2c:	e12d                	bnez	a0,ffffffffc0203c8e <swap_out+0xe0>
          v=page->pra_vaddr; 
ffffffffc0203c2e:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203c30:	01893503          	ld	a0,24(s2)
ffffffffc0203c34:	4601                	li	a2,0
          v=page->pra_vaddr; 
ffffffffc0203c36:	7f84                	ld	s1,56(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203c38:	85a6                	mv	a1,s1
ffffffffc0203c3a:	9e0fe0ef          	jal	ra,ffffffffc0201e1a <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc0203c3e:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203c40:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc0203c42:	8b85                	andi	a5,a5,1
ffffffffc0203c44:	cfb9                	beqz	a5,ffffffffc0203ca2 <swap_out+0xf4>
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {
ffffffffc0203c46:	65a2                	ld	a1,8(sp)
ffffffffc0203c48:	7d9c                	ld	a5,56(a1)
ffffffffc0203c4a:	83b1                	srli	a5,a5,0xc
ffffffffc0203c4c:	0785                	addi	a5,a5,1
ffffffffc0203c4e:	00879513          	slli	a0,a5,0x8
ffffffffc0203c52:	00e010ef          	jal	ra,ffffffffc0204c60 <swapfs_write>
ffffffffc0203c56:	d949                	beqz	a0,ffffffffc0203be8 <swap_out+0x3a>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203c58:	855e                	mv	a0,s7
ffffffffc0203c5a:	d26fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0203c5e:	0009b783          	ld	a5,0(s3)
ffffffffc0203c62:	6622                	ld	a2,8(sp)
ffffffffc0203c64:	4681                	li	a3,0
ffffffffc0203c66:	739c                	ld	a5,32(a5)
ffffffffc0203c68:	85a6                	mv	a1,s1
ffffffffc0203c6a:	854a                	mv	a0,s2
     for (i = 0; i != n; ++ i)
ffffffffc0203c6c:	2405                	addiw	s0,s0,1
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0203c6e:	9782                	jalr	a5
     for (i = 0; i != n; ++ i)
ffffffffc0203c70:	fa8a17e3          	bne	s4,s0,ffffffffc0203c1e <swap_out+0x70>
}
ffffffffc0203c74:	60e6                	ld	ra,88(sp)
ffffffffc0203c76:	8522                	mv	a0,s0
ffffffffc0203c78:	6446                	ld	s0,80(sp)
ffffffffc0203c7a:	64a6                	ld	s1,72(sp)
ffffffffc0203c7c:	6906                	ld	s2,64(sp)
ffffffffc0203c7e:	79e2                	ld	s3,56(sp)
ffffffffc0203c80:	7a42                	ld	s4,48(sp)
ffffffffc0203c82:	7aa2                	ld	s5,40(sp)
ffffffffc0203c84:	7b02                	ld	s6,32(sp)
ffffffffc0203c86:	6be2                	ld	s7,24(sp)
ffffffffc0203c88:	6c42                	ld	s8,16(sp)
ffffffffc0203c8a:	6125                	addi	sp,sp,96
ffffffffc0203c8c:	8082                	ret
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc0203c8e:	85a2                	mv	a1,s0
ffffffffc0203c90:	00004517          	auipc	a0,0x4
ffffffffc0203c94:	0e850513          	addi	a0,a0,232 # ffffffffc0207d78 <default_pmm_manager+0x9c0>
ffffffffc0203c98:	ce8fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
                  break;
ffffffffc0203c9c:	bfe1                	j	ffffffffc0203c74 <swap_out+0xc6>
     for (i = 0; i != n; ++ i)
ffffffffc0203c9e:	4401                	li	s0,0
ffffffffc0203ca0:	bfd1                	j	ffffffffc0203c74 <swap_out+0xc6>
          assert((*ptep & PTE_V) != 0);
ffffffffc0203ca2:	00004697          	auipc	a3,0x4
ffffffffc0203ca6:	10668693          	addi	a3,a3,262 # ffffffffc0207da8 <default_pmm_manager+0x9f0>
ffffffffc0203caa:	00003617          	auipc	a2,0x3
ffffffffc0203cae:	01660613          	addi	a2,a2,22 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203cb2:	06800593          	li	a1,104
ffffffffc0203cb6:	00004517          	auipc	a0,0x4
ffffffffc0203cba:	e3a50513          	addi	a0,a0,-454 # ffffffffc0207af0 <default_pmm_manager+0x738>
ffffffffc0203cbe:	fbcfc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0203cc2 <swap_in>:
{
ffffffffc0203cc2:	7179                	addi	sp,sp,-48
ffffffffc0203cc4:	e84a                	sd	s2,16(sp)
ffffffffc0203cc6:	892a                	mv	s2,a0
     struct Page *result = alloc_page();
ffffffffc0203cc8:	4505                	li	a0,1
{
ffffffffc0203cca:	ec26                	sd	s1,24(sp)
ffffffffc0203ccc:	e44e                	sd	s3,8(sp)
ffffffffc0203cce:	f406                	sd	ra,40(sp)
ffffffffc0203cd0:	f022                	sd	s0,32(sp)
ffffffffc0203cd2:	84ae                	mv	s1,a1
ffffffffc0203cd4:	89b2                	mv	s3,a2
     struct Page *result = alloc_page();
ffffffffc0203cd6:	838fe0ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
     assert(result!=NULL);
ffffffffc0203cda:	c129                	beqz	a0,ffffffffc0203d1c <swap_in+0x5a>
     pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc0203cdc:	842a                	mv	s0,a0
ffffffffc0203cde:	01893503          	ld	a0,24(s2)
ffffffffc0203ce2:	4601                	li	a2,0
ffffffffc0203ce4:	85a6                	mv	a1,s1
ffffffffc0203ce6:	934fe0ef          	jal	ra,ffffffffc0201e1a <get_pte>
ffffffffc0203cea:	892a                	mv	s2,a0
     if ((r = swapfs_read((*ptep), result)) != 0)
ffffffffc0203cec:	6108                	ld	a0,0(a0)
ffffffffc0203cee:	85a2                	mv	a1,s0
ffffffffc0203cf0:	6e3000ef          	jal	ra,ffffffffc0204bd2 <swapfs_read>
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
ffffffffc0203cf4:	00093583          	ld	a1,0(s2)
ffffffffc0203cf8:	8626                	mv	a2,s1
ffffffffc0203cfa:	00004517          	auipc	a0,0x4
ffffffffc0203cfe:	12e50513          	addi	a0,a0,302 # ffffffffc0207e28 <default_pmm_manager+0xa70>
ffffffffc0203d02:	81a1                	srli	a1,a1,0x8
ffffffffc0203d04:	c7cfc0ef          	jal	ra,ffffffffc0200180 <cprintf>
}
ffffffffc0203d08:	70a2                	ld	ra,40(sp)
     *ptr_result=result;
ffffffffc0203d0a:	0089b023          	sd	s0,0(s3)
}
ffffffffc0203d0e:	7402                	ld	s0,32(sp)
ffffffffc0203d10:	64e2                	ld	s1,24(sp)
ffffffffc0203d12:	6942                	ld	s2,16(sp)
ffffffffc0203d14:	69a2                	ld	s3,8(sp)
ffffffffc0203d16:	4501                	li	a0,0
ffffffffc0203d18:	6145                	addi	sp,sp,48
ffffffffc0203d1a:	8082                	ret
     assert(result!=NULL);
ffffffffc0203d1c:	00004697          	auipc	a3,0x4
ffffffffc0203d20:	0fc68693          	addi	a3,a3,252 # ffffffffc0207e18 <default_pmm_manager+0xa60>
ffffffffc0203d24:	00003617          	auipc	a2,0x3
ffffffffc0203d28:	f9c60613          	addi	a2,a2,-100 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203d2c:	07e00593          	li	a1,126
ffffffffc0203d30:	00004517          	auipc	a0,0x4
ffffffffc0203d34:	dc050513          	addi	a0,a0,-576 # ffffffffc0207af0 <default_pmm_manager+0x738>
ffffffffc0203d38:	f42fc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0203d3c <_fifo_init_mm>:
    elm->prev = elm->next = elm;
ffffffffc0203d3c:	000ab797          	auipc	a5,0xab
ffffffffc0203d40:	cac78793          	addi	a5,a5,-852 # ffffffffc02ae9e8 <pra_list_head>
 */
static int
_fifo_init_mm(struct mm_struct *mm)
{     
     list_init(&pra_list_head);
     mm->sm_priv = &pra_list_head;
ffffffffc0203d44:	f51c                	sd	a5,40(a0)
ffffffffc0203d46:	e79c                	sd	a5,8(a5)
ffffffffc0203d48:	e39c                	sd	a5,0(a5)
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}
ffffffffc0203d4a:	4501                	li	a0,0
ffffffffc0203d4c:	8082                	ret

ffffffffc0203d4e <_fifo_init>:

static int
_fifo_init(void)
{
    return 0;
}
ffffffffc0203d4e:	4501                	li	a0,0
ffffffffc0203d50:	8082                	ret

ffffffffc0203d52 <_fifo_set_unswappable>:

static int
_fifo_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc0203d52:	4501                	li	a0,0
ffffffffc0203d54:	8082                	ret

ffffffffc0203d56 <_fifo_tick_event>:

static int
_fifo_tick_event(struct mm_struct *mm)
{ return 0; }
ffffffffc0203d56:	4501                	li	a0,0
ffffffffc0203d58:	8082                	ret

ffffffffc0203d5a <_fifo_check_swap>:
_fifo_check_swap(void) {
ffffffffc0203d5a:	711d                	addi	sp,sp,-96
ffffffffc0203d5c:	fc4e                	sd	s3,56(sp)
ffffffffc0203d5e:	f852                	sd	s4,48(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203d60:	00004517          	auipc	a0,0x4
ffffffffc0203d64:	10850513          	addi	a0,a0,264 # ffffffffc0207e68 <default_pmm_manager+0xab0>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203d68:	698d                	lui	s3,0x3
ffffffffc0203d6a:	4a31                	li	s4,12
_fifo_check_swap(void) {
ffffffffc0203d6c:	e0ca                	sd	s2,64(sp)
ffffffffc0203d6e:	ec86                	sd	ra,88(sp)
ffffffffc0203d70:	e8a2                	sd	s0,80(sp)
ffffffffc0203d72:	e4a6                	sd	s1,72(sp)
ffffffffc0203d74:	f456                	sd	s5,40(sp)
ffffffffc0203d76:	f05a                	sd	s6,32(sp)
ffffffffc0203d78:	ec5e                	sd	s7,24(sp)
ffffffffc0203d7a:	e862                	sd	s8,16(sp)
ffffffffc0203d7c:	e466                	sd	s9,8(sp)
ffffffffc0203d7e:	e06a                	sd	s10,0(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203d80:	c00fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203d84:	01498023          	sb	s4,0(s3) # 3000 <_binary_obj___user_faultread_out_size-0x6bd0>
    assert(pgfault_num==4);
ffffffffc0203d88:	000af917          	auipc	s2,0xaf
ffffffffc0203d8c:	cf092903          	lw	s2,-784(s2) # ffffffffc02b2a78 <pgfault_num>
ffffffffc0203d90:	4791                	li	a5,4
ffffffffc0203d92:	14f91e63          	bne	s2,a5,ffffffffc0203eee <_fifo_check_swap+0x194>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203d96:	00004517          	auipc	a0,0x4
ffffffffc0203d9a:	11250513          	addi	a0,a0,274 # ffffffffc0207ea8 <default_pmm_manager+0xaf0>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203d9e:	6a85                	lui	s5,0x1
ffffffffc0203da0:	4b29                	li	s6,10
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203da2:	bdefc0ef          	jal	ra,ffffffffc0200180 <cprintf>
ffffffffc0203da6:	000af417          	auipc	s0,0xaf
ffffffffc0203daa:	cd240413          	addi	s0,s0,-814 # ffffffffc02b2a78 <pgfault_num>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203dae:	016a8023          	sb	s6,0(s5) # 1000 <_binary_obj___user_faultread_out_size-0x8bd0>
    assert(pgfault_num==4);
ffffffffc0203db2:	4004                	lw	s1,0(s0)
ffffffffc0203db4:	2481                	sext.w	s1,s1
ffffffffc0203db6:	2b249c63          	bne	s1,s2,ffffffffc020406e <_fifo_check_swap+0x314>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0203dba:	00004517          	auipc	a0,0x4
ffffffffc0203dbe:	11650513          	addi	a0,a0,278 # ffffffffc0207ed0 <default_pmm_manager+0xb18>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203dc2:	6b91                	lui	s7,0x4
ffffffffc0203dc4:	4c35                	li	s8,13
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0203dc6:	bbafc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203dca:	018b8023          	sb	s8,0(s7) # 4000 <_binary_obj___user_faultread_out_size-0x5bd0>
    assert(pgfault_num==4);
ffffffffc0203dce:	00042903          	lw	s2,0(s0)
ffffffffc0203dd2:	2901                	sext.w	s2,s2
ffffffffc0203dd4:	26991d63          	bne	s2,s1,ffffffffc020404e <_fifo_check_swap+0x2f4>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203dd8:	00004517          	auipc	a0,0x4
ffffffffc0203ddc:	12050513          	addi	a0,a0,288 # ffffffffc0207ef8 <default_pmm_manager+0xb40>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203de0:	6c89                	lui	s9,0x2
ffffffffc0203de2:	4d2d                	li	s10,11
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203de4:	b9cfc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203de8:	01ac8023          	sb	s10,0(s9) # 2000 <_binary_obj___user_faultread_out_size-0x7bd0>
    assert(pgfault_num==4);
ffffffffc0203dec:	401c                	lw	a5,0(s0)
ffffffffc0203dee:	2781                	sext.w	a5,a5
ffffffffc0203df0:	23279f63          	bne	a5,s2,ffffffffc020402e <_fifo_check_swap+0x2d4>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0203df4:	00004517          	auipc	a0,0x4
ffffffffc0203df8:	12c50513          	addi	a0,a0,300 # ffffffffc0207f20 <default_pmm_manager+0xb68>
ffffffffc0203dfc:	b84fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0203e00:	6795                	lui	a5,0x5
ffffffffc0203e02:	4739                	li	a4,14
ffffffffc0203e04:	00e78023          	sb	a4,0(a5) # 5000 <_binary_obj___user_faultread_out_size-0x4bd0>
    assert(pgfault_num==5);
ffffffffc0203e08:	4004                	lw	s1,0(s0)
ffffffffc0203e0a:	4795                	li	a5,5
ffffffffc0203e0c:	2481                	sext.w	s1,s1
ffffffffc0203e0e:	20f49063          	bne	s1,a5,ffffffffc020400e <_fifo_check_swap+0x2b4>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203e12:	00004517          	auipc	a0,0x4
ffffffffc0203e16:	0e650513          	addi	a0,a0,230 # ffffffffc0207ef8 <default_pmm_manager+0xb40>
ffffffffc0203e1a:	b66fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203e1e:	01ac8023          	sb	s10,0(s9)
    assert(pgfault_num==5);
ffffffffc0203e22:	401c                	lw	a5,0(s0)
ffffffffc0203e24:	2781                	sext.w	a5,a5
ffffffffc0203e26:	1c979463          	bne	a5,s1,ffffffffc0203fee <_fifo_check_swap+0x294>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203e2a:	00004517          	auipc	a0,0x4
ffffffffc0203e2e:	07e50513          	addi	a0,a0,126 # ffffffffc0207ea8 <default_pmm_manager+0xaf0>
ffffffffc0203e32:	b4efc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203e36:	016a8023          	sb	s6,0(s5)
    assert(pgfault_num==6);
ffffffffc0203e3a:	401c                	lw	a5,0(s0)
ffffffffc0203e3c:	4719                	li	a4,6
ffffffffc0203e3e:	2781                	sext.w	a5,a5
ffffffffc0203e40:	18e79763          	bne	a5,a4,ffffffffc0203fce <_fifo_check_swap+0x274>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203e44:	00004517          	auipc	a0,0x4
ffffffffc0203e48:	0b450513          	addi	a0,a0,180 # ffffffffc0207ef8 <default_pmm_manager+0xb40>
ffffffffc0203e4c:	b34fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203e50:	01ac8023          	sb	s10,0(s9)
    assert(pgfault_num==7);
ffffffffc0203e54:	401c                	lw	a5,0(s0)
ffffffffc0203e56:	471d                	li	a4,7
ffffffffc0203e58:	2781                	sext.w	a5,a5
ffffffffc0203e5a:	14e79a63          	bne	a5,a4,ffffffffc0203fae <_fifo_check_swap+0x254>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203e5e:	00004517          	auipc	a0,0x4
ffffffffc0203e62:	00a50513          	addi	a0,a0,10 # ffffffffc0207e68 <default_pmm_manager+0xab0>
ffffffffc0203e66:	b1afc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203e6a:	01498023          	sb	s4,0(s3)
    assert(pgfault_num==8);
ffffffffc0203e6e:	401c                	lw	a5,0(s0)
ffffffffc0203e70:	4721                	li	a4,8
ffffffffc0203e72:	2781                	sext.w	a5,a5
ffffffffc0203e74:	10e79d63          	bne	a5,a4,ffffffffc0203f8e <_fifo_check_swap+0x234>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0203e78:	00004517          	auipc	a0,0x4
ffffffffc0203e7c:	05850513          	addi	a0,a0,88 # ffffffffc0207ed0 <default_pmm_manager+0xb18>
ffffffffc0203e80:	b00fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203e84:	018b8023          	sb	s8,0(s7)
    assert(pgfault_num==9);
ffffffffc0203e88:	401c                	lw	a5,0(s0)
ffffffffc0203e8a:	4725                	li	a4,9
ffffffffc0203e8c:	2781                	sext.w	a5,a5
ffffffffc0203e8e:	0ee79063          	bne	a5,a4,ffffffffc0203f6e <_fifo_check_swap+0x214>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0203e92:	00004517          	auipc	a0,0x4
ffffffffc0203e96:	08e50513          	addi	a0,a0,142 # ffffffffc0207f20 <default_pmm_manager+0xb68>
ffffffffc0203e9a:	ae6fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0203e9e:	6795                	lui	a5,0x5
ffffffffc0203ea0:	4739                	li	a4,14
ffffffffc0203ea2:	00e78023          	sb	a4,0(a5) # 5000 <_binary_obj___user_faultread_out_size-0x4bd0>
    assert(pgfault_num==10);
ffffffffc0203ea6:	4004                	lw	s1,0(s0)
ffffffffc0203ea8:	47a9                	li	a5,10
ffffffffc0203eaa:	2481                	sext.w	s1,s1
ffffffffc0203eac:	0af49163          	bne	s1,a5,ffffffffc0203f4e <_fifo_check_swap+0x1f4>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203eb0:	00004517          	auipc	a0,0x4
ffffffffc0203eb4:	ff850513          	addi	a0,a0,-8 # ffffffffc0207ea8 <default_pmm_manager+0xaf0>
ffffffffc0203eb8:	ac8fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0203ebc:	6785                	lui	a5,0x1
ffffffffc0203ebe:	0007c783          	lbu	a5,0(a5) # 1000 <_binary_obj___user_faultread_out_size-0x8bd0>
ffffffffc0203ec2:	06979663          	bne	a5,s1,ffffffffc0203f2e <_fifo_check_swap+0x1d4>
    assert(pgfault_num==11);
ffffffffc0203ec6:	401c                	lw	a5,0(s0)
ffffffffc0203ec8:	472d                	li	a4,11
ffffffffc0203eca:	2781                	sext.w	a5,a5
ffffffffc0203ecc:	04e79163          	bne	a5,a4,ffffffffc0203f0e <_fifo_check_swap+0x1b4>
}
ffffffffc0203ed0:	60e6                	ld	ra,88(sp)
ffffffffc0203ed2:	6446                	ld	s0,80(sp)
ffffffffc0203ed4:	64a6                	ld	s1,72(sp)
ffffffffc0203ed6:	6906                	ld	s2,64(sp)
ffffffffc0203ed8:	79e2                	ld	s3,56(sp)
ffffffffc0203eda:	7a42                	ld	s4,48(sp)
ffffffffc0203edc:	7aa2                	ld	s5,40(sp)
ffffffffc0203ede:	7b02                	ld	s6,32(sp)
ffffffffc0203ee0:	6be2                	ld	s7,24(sp)
ffffffffc0203ee2:	6c42                	ld	s8,16(sp)
ffffffffc0203ee4:	6ca2                	ld	s9,8(sp)
ffffffffc0203ee6:	6d02                	ld	s10,0(sp)
ffffffffc0203ee8:	4501                	li	a0,0
ffffffffc0203eea:	6125                	addi	sp,sp,96
ffffffffc0203eec:	8082                	ret
    assert(pgfault_num==4);
ffffffffc0203eee:	00004697          	auipc	a3,0x4
ffffffffc0203ef2:	dca68693          	addi	a3,a3,-566 # ffffffffc0207cb8 <default_pmm_manager+0x900>
ffffffffc0203ef6:	00003617          	auipc	a2,0x3
ffffffffc0203efa:	dca60613          	addi	a2,a2,-566 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203efe:	05100593          	li	a1,81
ffffffffc0203f02:	00004517          	auipc	a0,0x4
ffffffffc0203f06:	f8e50513          	addi	a0,a0,-114 # ffffffffc0207e90 <default_pmm_manager+0xad8>
ffffffffc0203f0a:	d70fc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgfault_num==11);
ffffffffc0203f0e:	00004697          	auipc	a3,0x4
ffffffffc0203f12:	0c268693          	addi	a3,a3,194 # ffffffffc0207fd0 <default_pmm_manager+0xc18>
ffffffffc0203f16:	00003617          	auipc	a2,0x3
ffffffffc0203f1a:	daa60613          	addi	a2,a2,-598 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203f1e:	07300593          	li	a1,115
ffffffffc0203f22:	00004517          	auipc	a0,0x4
ffffffffc0203f26:	f6e50513          	addi	a0,a0,-146 # ffffffffc0207e90 <default_pmm_manager+0xad8>
ffffffffc0203f2a:	d50fc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0203f2e:	00004697          	auipc	a3,0x4
ffffffffc0203f32:	07a68693          	addi	a3,a3,122 # ffffffffc0207fa8 <default_pmm_manager+0xbf0>
ffffffffc0203f36:	00003617          	auipc	a2,0x3
ffffffffc0203f3a:	d8a60613          	addi	a2,a2,-630 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203f3e:	07100593          	li	a1,113
ffffffffc0203f42:	00004517          	auipc	a0,0x4
ffffffffc0203f46:	f4e50513          	addi	a0,a0,-178 # ffffffffc0207e90 <default_pmm_manager+0xad8>
ffffffffc0203f4a:	d30fc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgfault_num==10);
ffffffffc0203f4e:	00004697          	auipc	a3,0x4
ffffffffc0203f52:	04a68693          	addi	a3,a3,74 # ffffffffc0207f98 <default_pmm_manager+0xbe0>
ffffffffc0203f56:	00003617          	auipc	a2,0x3
ffffffffc0203f5a:	d6a60613          	addi	a2,a2,-662 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203f5e:	06f00593          	li	a1,111
ffffffffc0203f62:	00004517          	auipc	a0,0x4
ffffffffc0203f66:	f2e50513          	addi	a0,a0,-210 # ffffffffc0207e90 <default_pmm_manager+0xad8>
ffffffffc0203f6a:	d10fc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgfault_num==9);
ffffffffc0203f6e:	00004697          	auipc	a3,0x4
ffffffffc0203f72:	01a68693          	addi	a3,a3,26 # ffffffffc0207f88 <default_pmm_manager+0xbd0>
ffffffffc0203f76:	00003617          	auipc	a2,0x3
ffffffffc0203f7a:	d4a60613          	addi	a2,a2,-694 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203f7e:	06c00593          	li	a1,108
ffffffffc0203f82:	00004517          	auipc	a0,0x4
ffffffffc0203f86:	f0e50513          	addi	a0,a0,-242 # ffffffffc0207e90 <default_pmm_manager+0xad8>
ffffffffc0203f8a:	cf0fc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgfault_num==8);
ffffffffc0203f8e:	00004697          	auipc	a3,0x4
ffffffffc0203f92:	fea68693          	addi	a3,a3,-22 # ffffffffc0207f78 <default_pmm_manager+0xbc0>
ffffffffc0203f96:	00003617          	auipc	a2,0x3
ffffffffc0203f9a:	d2a60613          	addi	a2,a2,-726 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203f9e:	06900593          	li	a1,105
ffffffffc0203fa2:	00004517          	auipc	a0,0x4
ffffffffc0203fa6:	eee50513          	addi	a0,a0,-274 # ffffffffc0207e90 <default_pmm_manager+0xad8>
ffffffffc0203faa:	cd0fc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgfault_num==7);
ffffffffc0203fae:	00004697          	auipc	a3,0x4
ffffffffc0203fb2:	fba68693          	addi	a3,a3,-70 # ffffffffc0207f68 <default_pmm_manager+0xbb0>
ffffffffc0203fb6:	00003617          	auipc	a2,0x3
ffffffffc0203fba:	d0a60613          	addi	a2,a2,-758 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203fbe:	06600593          	li	a1,102
ffffffffc0203fc2:	00004517          	auipc	a0,0x4
ffffffffc0203fc6:	ece50513          	addi	a0,a0,-306 # ffffffffc0207e90 <default_pmm_manager+0xad8>
ffffffffc0203fca:	cb0fc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgfault_num==6);
ffffffffc0203fce:	00004697          	auipc	a3,0x4
ffffffffc0203fd2:	f8a68693          	addi	a3,a3,-118 # ffffffffc0207f58 <default_pmm_manager+0xba0>
ffffffffc0203fd6:	00003617          	auipc	a2,0x3
ffffffffc0203fda:	cea60613          	addi	a2,a2,-790 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203fde:	06300593          	li	a1,99
ffffffffc0203fe2:	00004517          	auipc	a0,0x4
ffffffffc0203fe6:	eae50513          	addi	a0,a0,-338 # ffffffffc0207e90 <default_pmm_manager+0xad8>
ffffffffc0203fea:	c90fc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgfault_num==5);
ffffffffc0203fee:	00004697          	auipc	a3,0x4
ffffffffc0203ff2:	f5a68693          	addi	a3,a3,-166 # ffffffffc0207f48 <default_pmm_manager+0xb90>
ffffffffc0203ff6:	00003617          	auipc	a2,0x3
ffffffffc0203ffa:	cca60613          	addi	a2,a2,-822 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0203ffe:	06000593          	li	a1,96
ffffffffc0204002:	00004517          	auipc	a0,0x4
ffffffffc0204006:	e8e50513          	addi	a0,a0,-370 # ffffffffc0207e90 <default_pmm_manager+0xad8>
ffffffffc020400a:	c70fc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgfault_num==5);
ffffffffc020400e:	00004697          	auipc	a3,0x4
ffffffffc0204012:	f3a68693          	addi	a3,a3,-198 # ffffffffc0207f48 <default_pmm_manager+0xb90>
ffffffffc0204016:	00003617          	auipc	a2,0x3
ffffffffc020401a:	caa60613          	addi	a2,a2,-854 # ffffffffc0206cc0 <commands+0x450>
ffffffffc020401e:	05d00593          	li	a1,93
ffffffffc0204022:	00004517          	auipc	a0,0x4
ffffffffc0204026:	e6e50513          	addi	a0,a0,-402 # ffffffffc0207e90 <default_pmm_manager+0xad8>
ffffffffc020402a:	c50fc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgfault_num==4);
ffffffffc020402e:	00004697          	auipc	a3,0x4
ffffffffc0204032:	c8a68693          	addi	a3,a3,-886 # ffffffffc0207cb8 <default_pmm_manager+0x900>
ffffffffc0204036:	00003617          	auipc	a2,0x3
ffffffffc020403a:	c8a60613          	addi	a2,a2,-886 # ffffffffc0206cc0 <commands+0x450>
ffffffffc020403e:	05a00593          	li	a1,90
ffffffffc0204042:	00004517          	auipc	a0,0x4
ffffffffc0204046:	e4e50513          	addi	a0,a0,-434 # ffffffffc0207e90 <default_pmm_manager+0xad8>
ffffffffc020404a:	c30fc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgfault_num==4);
ffffffffc020404e:	00004697          	auipc	a3,0x4
ffffffffc0204052:	c6a68693          	addi	a3,a3,-918 # ffffffffc0207cb8 <default_pmm_manager+0x900>
ffffffffc0204056:	00003617          	auipc	a2,0x3
ffffffffc020405a:	c6a60613          	addi	a2,a2,-918 # ffffffffc0206cc0 <commands+0x450>
ffffffffc020405e:	05700593          	li	a1,87
ffffffffc0204062:	00004517          	auipc	a0,0x4
ffffffffc0204066:	e2e50513          	addi	a0,a0,-466 # ffffffffc0207e90 <default_pmm_manager+0xad8>
ffffffffc020406a:	c10fc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgfault_num==4);
ffffffffc020406e:	00004697          	auipc	a3,0x4
ffffffffc0204072:	c4a68693          	addi	a3,a3,-950 # ffffffffc0207cb8 <default_pmm_manager+0x900>
ffffffffc0204076:	00003617          	auipc	a2,0x3
ffffffffc020407a:	c4a60613          	addi	a2,a2,-950 # ffffffffc0206cc0 <commands+0x450>
ffffffffc020407e:	05400593          	li	a1,84
ffffffffc0204082:	00004517          	auipc	a0,0x4
ffffffffc0204086:	e0e50513          	addi	a0,a0,-498 # ffffffffc0207e90 <default_pmm_manager+0xad8>
ffffffffc020408a:	bf0fc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc020408e <_fifo_swap_out_victim>:
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc020408e:	751c                	ld	a5,40(a0)
{
ffffffffc0204090:	1141                	addi	sp,sp,-16
ffffffffc0204092:	e406                	sd	ra,8(sp)
         assert(head != NULL);
ffffffffc0204094:	cf91                	beqz	a5,ffffffffc02040b0 <_fifo_swap_out_victim+0x22>
     assert(in_tick==0);
ffffffffc0204096:	ee0d                	bnez	a2,ffffffffc02040d0 <_fifo_swap_out_victim+0x42>
    return listelm->next;
ffffffffc0204098:	679c                	ld	a5,8(a5)
}
ffffffffc020409a:	60a2                	ld	ra,8(sp)
ffffffffc020409c:	4501                	li	a0,0
    __list_del(listelm->prev, listelm->next);
ffffffffc020409e:	6394                	ld	a3,0(a5)
ffffffffc02040a0:	6798                	ld	a4,8(a5)
    *ptr_page = le2page(entry, pra_page_link);
ffffffffc02040a2:	fd878793          	addi	a5,a5,-40
    prev->next = next;
ffffffffc02040a6:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc02040a8:	e314                	sd	a3,0(a4)
ffffffffc02040aa:	e19c                	sd	a5,0(a1)
}
ffffffffc02040ac:	0141                	addi	sp,sp,16
ffffffffc02040ae:	8082                	ret
         assert(head != NULL);
ffffffffc02040b0:	00004697          	auipc	a3,0x4
ffffffffc02040b4:	f3068693          	addi	a3,a3,-208 # ffffffffc0207fe0 <default_pmm_manager+0xc28>
ffffffffc02040b8:	00003617          	auipc	a2,0x3
ffffffffc02040bc:	c0860613          	addi	a2,a2,-1016 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02040c0:	04100593          	li	a1,65
ffffffffc02040c4:	00004517          	auipc	a0,0x4
ffffffffc02040c8:	dcc50513          	addi	a0,a0,-564 # ffffffffc0207e90 <default_pmm_manager+0xad8>
ffffffffc02040cc:	baefc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(in_tick==0);
ffffffffc02040d0:	00004697          	auipc	a3,0x4
ffffffffc02040d4:	f2068693          	addi	a3,a3,-224 # ffffffffc0207ff0 <default_pmm_manager+0xc38>
ffffffffc02040d8:	00003617          	auipc	a2,0x3
ffffffffc02040dc:	be860613          	addi	a2,a2,-1048 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02040e0:	04200593          	li	a1,66
ffffffffc02040e4:	00004517          	auipc	a0,0x4
ffffffffc02040e8:	dac50513          	addi	a0,a0,-596 # ffffffffc0207e90 <default_pmm_manager+0xad8>
ffffffffc02040ec:	b8efc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02040f0 <_fifo_map_swappable>:
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc02040f0:	751c                	ld	a5,40(a0)
    assert(entry != NULL && head != NULL);
ffffffffc02040f2:	cb91                	beqz	a5,ffffffffc0204106 <_fifo_map_swappable+0x16>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02040f4:	6394                	ld	a3,0(a5)
ffffffffc02040f6:	02860713          	addi	a4,a2,40
    prev->next = next->prev = elm;
ffffffffc02040fa:	e398                	sd	a4,0(a5)
ffffffffc02040fc:	e698                	sd	a4,8(a3)
}
ffffffffc02040fe:	4501                	li	a0,0
    elm->next = next;
ffffffffc0204100:	fa1c                	sd	a5,48(a2)
    elm->prev = prev;
ffffffffc0204102:	f614                	sd	a3,40(a2)
ffffffffc0204104:	8082                	ret
{
ffffffffc0204106:	1141                	addi	sp,sp,-16
    assert(entry != NULL && head != NULL);
ffffffffc0204108:	00004697          	auipc	a3,0x4
ffffffffc020410c:	ef868693          	addi	a3,a3,-264 # ffffffffc0208000 <default_pmm_manager+0xc48>
ffffffffc0204110:	00003617          	auipc	a2,0x3
ffffffffc0204114:	bb060613          	addi	a2,a2,-1104 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0204118:	03200593          	li	a1,50
ffffffffc020411c:	00004517          	auipc	a0,0x4
ffffffffc0204120:	d7450513          	addi	a0,a0,-652 # ffffffffc0207e90 <default_pmm_manager+0xad8>
{
ffffffffc0204124:	e406                	sd	ra,8(sp)
    assert(entry != NULL && head != NULL);
ffffffffc0204126:	b54fc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc020412a <check_vma_overlap.part.0>:
}


// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc020412a:	1141                	addi	sp,sp,-16
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc020412c:	00004697          	auipc	a3,0x4
ffffffffc0204130:	f0c68693          	addi	a3,a3,-244 # ffffffffc0208038 <default_pmm_manager+0xc80>
ffffffffc0204134:	00003617          	auipc	a2,0x3
ffffffffc0204138:	b8c60613          	addi	a2,a2,-1140 # ffffffffc0206cc0 <commands+0x450>
ffffffffc020413c:	06d00593          	li	a1,109
ffffffffc0204140:	00004517          	auipc	a0,0x4
ffffffffc0204144:	f1850513          	addi	a0,a0,-232 # ffffffffc0208058 <default_pmm_manager+0xca0>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0204148:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc020414a:	b30fc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc020414e <mm_create>:
mm_create(void) {
ffffffffc020414e:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0204150:	04000513          	li	a0,64
mm_create(void) {
ffffffffc0204154:	e022                	sd	s0,0(sp)
ffffffffc0204156:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0204158:	9d9fd0ef          	jal	ra,ffffffffc0201b30 <kmalloc>
ffffffffc020415c:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc020415e:	c505                	beqz	a0,ffffffffc0204186 <mm_create+0x38>
    elm->prev = elm->next = elm;
ffffffffc0204160:	e408                	sd	a0,8(s0)
ffffffffc0204162:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc0204164:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0204168:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc020416c:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0204170:	000af797          	auipc	a5,0xaf
ffffffffc0204174:	8f87a783          	lw	a5,-1800(a5) # ffffffffc02b2a68 <swap_init_ok>
ffffffffc0204178:	ef81                	bnez	a5,ffffffffc0204190 <mm_create+0x42>
        else mm->sm_priv = NULL;
ffffffffc020417a:	02053423          	sd	zero,40(a0)
    return mm->mm_count;
}

static inline void
set_mm_count(struct mm_struct *mm, int val) {
    mm->mm_count = val;
ffffffffc020417e:	02042823          	sw	zero,48(s0)

typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock) {
    *lock = 0;
ffffffffc0204182:	02043c23          	sd	zero,56(s0)
}
ffffffffc0204186:	60a2                	ld	ra,8(sp)
ffffffffc0204188:	8522                	mv	a0,s0
ffffffffc020418a:	6402                	ld	s0,0(sp)
ffffffffc020418c:	0141                	addi	sp,sp,16
ffffffffc020418e:	8082                	ret
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0204190:	a07ff0ef          	jal	ra,ffffffffc0203b96 <swap_init_mm>
ffffffffc0204194:	b7ed                	j	ffffffffc020417e <mm_create+0x30>

ffffffffc0204196 <vma_create>:
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc0204196:	1101                	addi	sp,sp,-32
ffffffffc0204198:	e04a                	sd	s2,0(sp)
ffffffffc020419a:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020419c:	03000513          	li	a0,48
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc02041a0:	e822                	sd	s0,16(sp)
ffffffffc02041a2:	e426                	sd	s1,8(sp)
ffffffffc02041a4:	ec06                	sd	ra,24(sp)
ffffffffc02041a6:	84ae                	mv	s1,a1
ffffffffc02041a8:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02041aa:	987fd0ef          	jal	ra,ffffffffc0201b30 <kmalloc>
    if (vma != NULL) {
ffffffffc02041ae:	c509                	beqz	a0,ffffffffc02041b8 <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc02041b0:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc02041b4:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02041b6:	cd00                	sw	s0,24(a0)
}
ffffffffc02041b8:	60e2                	ld	ra,24(sp)
ffffffffc02041ba:	6442                	ld	s0,16(sp)
ffffffffc02041bc:	64a2                	ld	s1,8(sp)
ffffffffc02041be:	6902                	ld	s2,0(sp)
ffffffffc02041c0:	6105                	addi	sp,sp,32
ffffffffc02041c2:	8082                	ret

ffffffffc02041c4 <find_vma>:
find_vma(struct mm_struct *mm, uintptr_t addr) {
ffffffffc02041c4:	86aa                	mv	a3,a0
    if (mm != NULL) {
ffffffffc02041c6:	c505                	beqz	a0,ffffffffc02041ee <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc02041c8:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc02041ca:	c501                	beqz	a0,ffffffffc02041d2 <find_vma+0xe>
ffffffffc02041cc:	651c                	ld	a5,8(a0)
ffffffffc02041ce:	02f5f263          	bgeu	a1,a5,ffffffffc02041f2 <find_vma+0x2e>
    return listelm->next;
ffffffffc02041d2:	669c                	ld	a5,8(a3)
                while ((le = list_next(le)) != list) {
ffffffffc02041d4:	00f68d63          	beq	a3,a5,ffffffffc02041ee <find_vma+0x2a>
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
ffffffffc02041d8:	fe87b703          	ld	a4,-24(a5)
ffffffffc02041dc:	00e5e663          	bltu	a1,a4,ffffffffc02041e8 <find_vma+0x24>
ffffffffc02041e0:	ff07b703          	ld	a4,-16(a5)
ffffffffc02041e4:	00e5ec63          	bltu	a1,a4,ffffffffc02041fc <find_vma+0x38>
ffffffffc02041e8:	679c                	ld	a5,8(a5)
                while ((le = list_next(le)) != list) {
ffffffffc02041ea:	fef697e3          	bne	a3,a5,ffffffffc02041d8 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc02041ee:	4501                	li	a0,0
}
ffffffffc02041f0:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc02041f2:	691c                	ld	a5,16(a0)
ffffffffc02041f4:	fcf5ffe3          	bgeu	a1,a5,ffffffffc02041d2 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc02041f8:	ea88                	sd	a0,16(a3)
ffffffffc02041fa:	8082                	ret
                    vma = le2vma(le, list_link);
ffffffffc02041fc:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0204200:	ea88                	sd	a0,16(a3)
ffffffffc0204202:	8082                	ret

ffffffffc0204204 <insert_vma_struct>:


// insert_vma_struct -insert vma in mm's list link
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    assert(vma->vm_start < vma->vm_end);
ffffffffc0204204:	6590                	ld	a2,8(a1)
ffffffffc0204206:	0105b803          	ld	a6,16(a1) # 1010 <_binary_obj___user_faultread_out_size-0x8bc0>
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
ffffffffc020420a:	1141                	addi	sp,sp,-16
ffffffffc020420c:	e406                	sd	ra,8(sp)
ffffffffc020420e:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0204210:	01066763          	bltu	a2,a6,ffffffffc020421e <insert_vma_struct+0x1a>
ffffffffc0204214:	a085                	j	ffffffffc0204274 <insert_vma_struct+0x70>
    list_entry_t *le_prev = list, *le_next;

        list_entry_t *le = list;
        while ((le = list_next(le)) != list) {
            struct vma_struct *mmap_prev = le2vma(le, list_link);
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc0204216:	fe87b703          	ld	a4,-24(a5)
ffffffffc020421a:	04e66863          	bltu	a2,a4,ffffffffc020426a <insert_vma_struct+0x66>
ffffffffc020421e:	86be                	mv	a3,a5
ffffffffc0204220:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc0204222:	fef51ae3          	bne	a0,a5,ffffffffc0204216 <insert_vma_struct+0x12>
        }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list) {
ffffffffc0204226:	02a68463          	beq	a3,a0,ffffffffc020424e <insert_vma_struct+0x4a>
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc020422a:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc020422e:	fe86b883          	ld	a7,-24(a3)
ffffffffc0204232:	08e8f163          	bgeu	a7,a4,ffffffffc02042b4 <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0204236:	04e66f63          	bltu	a2,a4,ffffffffc0204294 <insert_vma_struct+0x90>
    }
    if (le_next != list) {
ffffffffc020423a:	00f50a63          	beq	a0,a5,ffffffffc020424e <insert_vma_struct+0x4a>
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc020423e:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0204242:	05076963          	bltu	a4,a6,ffffffffc0204294 <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0204246:	ff07b603          	ld	a2,-16(a5)
ffffffffc020424a:	02c77363          	bgeu	a4,a2,ffffffffc0204270 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count ++;
ffffffffc020424e:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0204250:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0204252:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0204256:	e390                	sd	a2,0(a5)
ffffffffc0204258:	e690                	sd	a2,8(a3)
}
ffffffffc020425a:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc020425c:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc020425e:	f194                	sd	a3,32(a1)
    mm->map_count ++;
ffffffffc0204260:	0017079b          	addiw	a5,a4,1
ffffffffc0204264:	d11c                	sw	a5,32(a0)
}
ffffffffc0204266:	0141                	addi	sp,sp,16
ffffffffc0204268:	8082                	ret
    if (le_prev != list) {
ffffffffc020426a:	fca690e3          	bne	a3,a0,ffffffffc020422a <insert_vma_struct+0x26>
ffffffffc020426e:	bfd1                	j	ffffffffc0204242 <insert_vma_struct+0x3e>
ffffffffc0204270:	ebbff0ef          	jal	ra,ffffffffc020412a <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0204274:	00004697          	auipc	a3,0x4
ffffffffc0204278:	df468693          	addi	a3,a3,-524 # ffffffffc0208068 <default_pmm_manager+0xcb0>
ffffffffc020427c:	00003617          	auipc	a2,0x3
ffffffffc0204280:	a4460613          	addi	a2,a2,-1468 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0204284:	07400593          	li	a1,116
ffffffffc0204288:	00004517          	auipc	a0,0x4
ffffffffc020428c:	dd050513          	addi	a0,a0,-560 # ffffffffc0208058 <default_pmm_manager+0xca0>
ffffffffc0204290:	9eafc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0204294:	00004697          	auipc	a3,0x4
ffffffffc0204298:	e1468693          	addi	a3,a3,-492 # ffffffffc02080a8 <default_pmm_manager+0xcf0>
ffffffffc020429c:	00003617          	auipc	a2,0x3
ffffffffc02042a0:	a2460613          	addi	a2,a2,-1500 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02042a4:	06c00593          	li	a1,108
ffffffffc02042a8:	00004517          	auipc	a0,0x4
ffffffffc02042ac:	db050513          	addi	a0,a0,-592 # ffffffffc0208058 <default_pmm_manager+0xca0>
ffffffffc02042b0:	9cafc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02042b4:	00004697          	auipc	a3,0x4
ffffffffc02042b8:	dd468693          	addi	a3,a3,-556 # ffffffffc0208088 <default_pmm_manager+0xcd0>
ffffffffc02042bc:	00003617          	auipc	a2,0x3
ffffffffc02042c0:	a0460613          	addi	a2,a2,-1532 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02042c4:	06b00593          	li	a1,107
ffffffffc02042c8:	00004517          	auipc	a0,0x4
ffffffffc02042cc:	d9050513          	addi	a0,a0,-624 # ffffffffc0208058 <default_pmm_manager+0xca0>
ffffffffc02042d0:	9aafc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02042d4 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void
mm_destroy(struct mm_struct *mm) {
    assert(mm_count(mm) == 0);
ffffffffc02042d4:	591c                	lw	a5,48(a0)
mm_destroy(struct mm_struct *mm) {
ffffffffc02042d6:	1141                	addi	sp,sp,-16
ffffffffc02042d8:	e406                	sd	ra,8(sp)
ffffffffc02042da:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc02042dc:	e78d                	bnez	a5,ffffffffc0204306 <mm_destroy+0x32>
ffffffffc02042de:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc02042e0:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list) {
ffffffffc02042e2:	00a40c63          	beq	s0,a0,ffffffffc02042fa <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc02042e6:	6118                	ld	a4,0(a0)
ffffffffc02042e8:	651c                	ld	a5,8(a0)
        list_del(le);
        kfree(le2vma(le, list_link));  //kfree vma        
ffffffffc02042ea:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc02042ec:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02042ee:	e398                	sd	a4,0(a5)
ffffffffc02042f0:	8f1fd0ef          	jal	ra,ffffffffc0201be0 <kfree>
    return listelm->next;
ffffffffc02042f4:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc02042f6:	fea418e3          	bne	s0,a0,ffffffffc02042e6 <mm_destroy+0x12>
    }
    kfree(mm); //kfree mm
ffffffffc02042fa:	8522                	mv	a0,s0
    mm=NULL;
}
ffffffffc02042fc:	6402                	ld	s0,0(sp)
ffffffffc02042fe:	60a2                	ld	ra,8(sp)
ffffffffc0204300:	0141                	addi	sp,sp,16
    kfree(mm); //kfree mm
ffffffffc0204302:	8dffd06f          	j	ffffffffc0201be0 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc0204306:	00004697          	auipc	a3,0x4
ffffffffc020430a:	dc268693          	addi	a3,a3,-574 # ffffffffc02080c8 <default_pmm_manager+0xd10>
ffffffffc020430e:	00003617          	auipc	a2,0x3
ffffffffc0204312:	9b260613          	addi	a2,a2,-1614 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0204316:	09400593          	li	a1,148
ffffffffc020431a:	00004517          	auipc	a0,0x4
ffffffffc020431e:	d3e50513          	addi	a0,a0,-706 # ffffffffc0208058 <default_pmm_manager+0xca0>
ffffffffc0204322:	958fc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0204326 <mm_map>:

int
mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
       struct vma_struct **vma_store) {
ffffffffc0204326:	7139                	addi	sp,sp,-64
ffffffffc0204328:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020432a:	6405                	lui	s0,0x1
ffffffffc020432c:	147d                	addi	s0,s0,-1
ffffffffc020432e:	77fd                	lui	a5,0xfffff
ffffffffc0204330:	9622                	add	a2,a2,s0
ffffffffc0204332:	962e                	add	a2,a2,a1
       struct vma_struct **vma_store) {
ffffffffc0204334:	f426                	sd	s1,40(sp)
ffffffffc0204336:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0204338:	00f5f4b3          	and	s1,a1,a5
       struct vma_struct **vma_store) {
ffffffffc020433c:	f04a                	sd	s2,32(sp)
ffffffffc020433e:	ec4e                	sd	s3,24(sp)
ffffffffc0204340:	e852                	sd	s4,16(sp)
ffffffffc0204342:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end)) {
ffffffffc0204344:	002005b7          	lui	a1,0x200
ffffffffc0204348:	00f67433          	and	s0,a2,a5
ffffffffc020434c:	06b4e363          	bltu	s1,a1,ffffffffc02043b2 <mm_map+0x8c>
ffffffffc0204350:	0684f163          	bgeu	s1,s0,ffffffffc02043b2 <mm_map+0x8c>
ffffffffc0204354:	4785                	li	a5,1
ffffffffc0204356:	07fe                	slli	a5,a5,0x1f
ffffffffc0204358:	0487ed63          	bltu	a5,s0,ffffffffc02043b2 <mm_map+0x8c>
ffffffffc020435c:	89aa                	mv	s3,a0
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc020435e:	cd21                	beqz	a0,ffffffffc02043b6 <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start) {
ffffffffc0204360:	85a6                	mv	a1,s1
ffffffffc0204362:	8ab6                	mv	s5,a3
ffffffffc0204364:	8a3a                	mv	s4,a4
ffffffffc0204366:	e5fff0ef          	jal	ra,ffffffffc02041c4 <find_vma>
ffffffffc020436a:	c501                	beqz	a0,ffffffffc0204372 <mm_map+0x4c>
ffffffffc020436c:	651c                	ld	a5,8(a0)
ffffffffc020436e:	0487e263          	bltu	a5,s0,ffffffffc02043b2 <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0204372:	03000513          	li	a0,48
ffffffffc0204376:	fbafd0ef          	jal	ra,ffffffffc0201b30 <kmalloc>
ffffffffc020437a:	892a                	mv	s2,a0
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc020437c:	5571                	li	a0,-4
    if (vma != NULL) {
ffffffffc020437e:	02090163          	beqz	s2,ffffffffc02043a0 <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL) {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0204382:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc0204384:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc0204388:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc020438c:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc0204390:	85ca                	mv	a1,s2
ffffffffc0204392:	e73ff0ef          	jal	ra,ffffffffc0204204 <insert_vma_struct>
    if (vma_store != NULL) {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc0204396:	4501                	li	a0,0
    if (vma_store != NULL) {
ffffffffc0204398:	000a0463          	beqz	s4,ffffffffc02043a0 <mm_map+0x7a>
        *vma_store = vma;
ffffffffc020439c:	012a3023          	sd	s2,0(s4)

out:
    return ret;
}
ffffffffc02043a0:	70e2                	ld	ra,56(sp)
ffffffffc02043a2:	7442                	ld	s0,48(sp)
ffffffffc02043a4:	74a2                	ld	s1,40(sp)
ffffffffc02043a6:	7902                	ld	s2,32(sp)
ffffffffc02043a8:	69e2                	ld	s3,24(sp)
ffffffffc02043aa:	6a42                	ld	s4,16(sp)
ffffffffc02043ac:	6aa2                	ld	s5,8(sp)
ffffffffc02043ae:	6121                	addi	sp,sp,64
ffffffffc02043b0:	8082                	ret
        return -E_INVAL;
ffffffffc02043b2:	5575                	li	a0,-3
ffffffffc02043b4:	b7f5                	j	ffffffffc02043a0 <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc02043b6:	00003697          	auipc	a3,0x3
ffffffffc02043ba:	78a68693          	addi	a3,a3,1930 # ffffffffc0207b40 <default_pmm_manager+0x788>
ffffffffc02043be:	00003617          	auipc	a2,0x3
ffffffffc02043c2:	90260613          	addi	a2,a2,-1790 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02043c6:	0a700593          	li	a1,167
ffffffffc02043ca:	00004517          	auipc	a0,0x4
ffffffffc02043ce:	c8e50513          	addi	a0,a0,-882 # ffffffffc0208058 <default_pmm_manager+0xca0>
ffffffffc02043d2:	8a8fc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02043d6 <dup_mmap>:

int
dup_mmap(struct mm_struct *to, struct mm_struct *from) {
ffffffffc02043d6:	7139                	addi	sp,sp,-64
ffffffffc02043d8:	fc06                	sd	ra,56(sp)
ffffffffc02043da:	f822                	sd	s0,48(sp)
ffffffffc02043dc:	f426                	sd	s1,40(sp)
ffffffffc02043de:	f04a                	sd	s2,32(sp)
ffffffffc02043e0:	ec4e                	sd	s3,24(sp)
ffffffffc02043e2:	e852                	sd	s4,16(sp)
ffffffffc02043e4:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc02043e6:	c52d                	beqz	a0,ffffffffc0204450 <dup_mmap+0x7a>
ffffffffc02043e8:	892a                	mv	s2,a0
ffffffffc02043ea:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc02043ec:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc02043ee:	e595                	bnez	a1,ffffffffc020441a <dup_mmap+0x44>
ffffffffc02043f0:	a085                	j	ffffffffc0204450 <dup_mmap+0x7a>
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
        if (nvma == NULL) {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc02043f2:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc02043f4:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_exit_out_size+0x1f4ec0>
        vma->vm_end = vm_end;
ffffffffc02043f8:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc02043fc:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc0204400:	e05ff0ef          	jal	ra,ffffffffc0204204 <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0) {
ffffffffc0204404:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8be0>
ffffffffc0204408:	fe843603          	ld	a2,-24(s0)
ffffffffc020440c:	6c8c                	ld	a1,24(s1)
ffffffffc020440e:	01893503          	ld	a0,24(s2)
ffffffffc0204412:	4701                	li	a4,0
ffffffffc0204414:	d31fe0ef          	jal	ra,ffffffffc0203144 <copy_range>
ffffffffc0204418:	e105                	bnez	a0,ffffffffc0204438 <dup_mmap+0x62>
    return listelm->prev;
ffffffffc020441a:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list) {
ffffffffc020441c:	02848863          	beq	s1,s0,ffffffffc020444c <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0204420:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0204424:	fe843a83          	ld	s5,-24(s0)
ffffffffc0204428:	ff043a03          	ld	s4,-16(s0)
ffffffffc020442c:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0204430:	f00fd0ef          	jal	ra,ffffffffc0201b30 <kmalloc>
ffffffffc0204434:	85aa                	mv	a1,a0
    if (vma != NULL) {
ffffffffc0204436:	fd55                	bnez	a0,ffffffffc02043f2 <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc0204438:	5571                	li	a0,-4
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc020443a:	70e2                	ld	ra,56(sp)
ffffffffc020443c:	7442                	ld	s0,48(sp)
ffffffffc020443e:	74a2                	ld	s1,40(sp)
ffffffffc0204440:	7902                	ld	s2,32(sp)
ffffffffc0204442:	69e2                	ld	s3,24(sp)
ffffffffc0204444:	6a42                	ld	s4,16(sp)
ffffffffc0204446:	6aa2                	ld	s5,8(sp)
ffffffffc0204448:	6121                	addi	sp,sp,64
ffffffffc020444a:	8082                	ret
    return 0;
ffffffffc020444c:	4501                	li	a0,0
ffffffffc020444e:	b7f5                	j	ffffffffc020443a <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0204450:	00004697          	auipc	a3,0x4
ffffffffc0204454:	c9068693          	addi	a3,a3,-880 # ffffffffc02080e0 <default_pmm_manager+0xd28>
ffffffffc0204458:	00003617          	auipc	a2,0x3
ffffffffc020445c:	86860613          	addi	a2,a2,-1944 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0204460:	0c000593          	li	a1,192
ffffffffc0204464:	00004517          	auipc	a0,0x4
ffffffffc0204468:	bf450513          	addi	a0,a0,-1036 # ffffffffc0208058 <default_pmm_manager+0xca0>
ffffffffc020446c:	80efc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0204470 <exit_mmap>:

void
exit_mmap(struct mm_struct *mm) {
ffffffffc0204470:	1101                	addi	sp,sp,-32
ffffffffc0204472:	ec06                	sd	ra,24(sp)
ffffffffc0204474:	e822                	sd	s0,16(sp)
ffffffffc0204476:	e426                	sd	s1,8(sp)
ffffffffc0204478:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc020447a:	c531                	beqz	a0,ffffffffc02044c6 <exit_mmap+0x56>
ffffffffc020447c:	591c                	lw	a5,48(a0)
ffffffffc020447e:	84aa                	mv	s1,a0
ffffffffc0204480:	e3b9                	bnez	a5,ffffffffc02044c6 <exit_mmap+0x56>
    return listelm->next;
ffffffffc0204482:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0204484:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list) {
ffffffffc0204488:	02850663          	beq	a0,s0,ffffffffc02044b4 <exit_mmap+0x44>
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc020448c:	ff043603          	ld	a2,-16(s0)
ffffffffc0204490:	fe843583          	ld	a1,-24(s0)
ffffffffc0204494:	854a                	mv	a0,s2
ffffffffc0204496:	babfd0ef          	jal	ra,ffffffffc0202040 <unmap_range>
ffffffffc020449a:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list) {
ffffffffc020449c:	fe8498e3          	bne	s1,s0,ffffffffc020448c <exit_mmap+0x1c>
ffffffffc02044a0:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list) {
ffffffffc02044a2:	00848c63          	beq	s1,s0,ffffffffc02044ba <exit_mmap+0x4a>
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02044a6:	ff043603          	ld	a2,-16(s0)
ffffffffc02044aa:	fe843583          	ld	a1,-24(s0)
ffffffffc02044ae:	854a                	mv	a0,s2
ffffffffc02044b0:	cd7fd0ef          	jal	ra,ffffffffc0202186 <exit_range>
ffffffffc02044b4:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list) {
ffffffffc02044b6:	fe8498e3          	bne	s1,s0,ffffffffc02044a6 <exit_mmap+0x36>
    }
}
ffffffffc02044ba:	60e2                	ld	ra,24(sp)
ffffffffc02044bc:	6442                	ld	s0,16(sp)
ffffffffc02044be:	64a2                	ld	s1,8(sp)
ffffffffc02044c0:	6902                	ld	s2,0(sp)
ffffffffc02044c2:	6105                	addi	sp,sp,32
ffffffffc02044c4:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02044c6:	00004697          	auipc	a3,0x4
ffffffffc02044ca:	c3a68693          	addi	a3,a3,-966 # ffffffffc0208100 <default_pmm_manager+0xd48>
ffffffffc02044ce:	00002617          	auipc	a2,0x2
ffffffffc02044d2:	7f260613          	addi	a2,a2,2034 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02044d6:	0d600593          	li	a1,214
ffffffffc02044da:	00004517          	auipc	a0,0x4
ffffffffc02044de:	b7e50513          	addi	a0,a0,-1154 # ffffffffc0208058 <default_pmm_manager+0xca0>
ffffffffc02044e2:	f99fb0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02044e6 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
ffffffffc02044e6:	7139                	addi	sp,sp,-64
ffffffffc02044e8:	f822                	sd	s0,48(sp)
ffffffffc02044ea:	f426                	sd	s1,40(sp)
ffffffffc02044ec:	fc06                	sd	ra,56(sp)
ffffffffc02044ee:	f04a                	sd	s2,32(sp)
ffffffffc02044f0:	ec4e                	sd	s3,24(sp)
ffffffffc02044f2:	e852                	sd	s4,16(sp)
ffffffffc02044f4:	e456                	sd	s5,8(sp)

static void
check_vma_struct(void) {
    // size_t nr_free_pages_store = nr_free_pages();

    struct mm_struct *mm = mm_create();
ffffffffc02044f6:	c59ff0ef          	jal	ra,ffffffffc020414e <mm_create>
    assert(mm != NULL);
ffffffffc02044fa:	84aa                	mv	s1,a0
ffffffffc02044fc:	03200413          	li	s0,50
ffffffffc0204500:	e919                	bnez	a0,ffffffffc0204516 <vmm_init+0x30>
ffffffffc0204502:	a991                	j	ffffffffc0204956 <vmm_init+0x470>
        vma->vm_start = vm_start;
ffffffffc0204504:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0204506:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0204508:	00052c23          	sw	zero,24(a0)

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i --) {
ffffffffc020450c:	146d                	addi	s0,s0,-5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc020450e:	8526                	mv	a0,s1
ffffffffc0204510:	cf5ff0ef          	jal	ra,ffffffffc0204204 <insert_vma_struct>
    for (i = step1; i >= 1; i --) {
ffffffffc0204514:	c80d                	beqz	s0,ffffffffc0204546 <vmm_init+0x60>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0204516:	03000513          	li	a0,48
ffffffffc020451a:	e16fd0ef          	jal	ra,ffffffffc0201b30 <kmalloc>
ffffffffc020451e:	85aa                	mv	a1,a0
ffffffffc0204520:	00240793          	addi	a5,s0,2
    if (vma != NULL) {
ffffffffc0204524:	f165                	bnez	a0,ffffffffc0204504 <vmm_init+0x1e>
        assert(vma != NULL);
ffffffffc0204526:	00003697          	auipc	a3,0x3
ffffffffc020452a:	65268693          	addi	a3,a3,1618 # ffffffffc0207b78 <default_pmm_manager+0x7c0>
ffffffffc020452e:	00002617          	auipc	a2,0x2
ffffffffc0204532:	79260613          	addi	a2,a2,1938 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0204536:	11300593          	li	a1,275
ffffffffc020453a:	00004517          	auipc	a0,0x4
ffffffffc020453e:	b1e50513          	addi	a0,a0,-1250 # ffffffffc0208058 <default_pmm_manager+0xca0>
ffffffffc0204542:	f39fb0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc0204546:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc020454a:	1f900913          	li	s2,505
ffffffffc020454e:	a819                	j	ffffffffc0204564 <vmm_init+0x7e>
        vma->vm_start = vm_start;
ffffffffc0204550:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0204552:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0204554:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0204558:	0415                	addi	s0,s0,5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc020455a:	8526                	mv	a0,s1
ffffffffc020455c:	ca9ff0ef          	jal	ra,ffffffffc0204204 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0204560:	03240a63          	beq	s0,s2,ffffffffc0204594 <vmm_init+0xae>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0204564:	03000513          	li	a0,48
ffffffffc0204568:	dc8fd0ef          	jal	ra,ffffffffc0201b30 <kmalloc>
ffffffffc020456c:	85aa                	mv	a1,a0
ffffffffc020456e:	00240793          	addi	a5,s0,2
    if (vma != NULL) {
ffffffffc0204572:	fd79                	bnez	a0,ffffffffc0204550 <vmm_init+0x6a>
        assert(vma != NULL);
ffffffffc0204574:	00003697          	auipc	a3,0x3
ffffffffc0204578:	60468693          	addi	a3,a3,1540 # ffffffffc0207b78 <default_pmm_manager+0x7c0>
ffffffffc020457c:	00002617          	auipc	a2,0x2
ffffffffc0204580:	74460613          	addi	a2,a2,1860 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0204584:	11900593          	li	a1,281
ffffffffc0204588:	00004517          	auipc	a0,0x4
ffffffffc020458c:	ad050513          	addi	a0,a0,-1328 # ffffffffc0208058 <default_pmm_manager+0xca0>
ffffffffc0204590:	eebfb0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc0204594:	649c                	ld	a5,8(s1)
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
        assert(le != &(mm->mmap_list));
ffffffffc0204596:	471d                	li	a4,7
    for (i = 1; i <= step2; i ++) {
ffffffffc0204598:	1fb00593          	li	a1,507
        assert(le != &(mm->mmap_list));
ffffffffc020459c:	2cf48d63          	beq	s1,a5,ffffffffc0204876 <vmm_init+0x390>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02045a0:	fe87b683          	ld	a3,-24(a5) # ffffffffffffefe8 <end+0x3fd4c54c>
ffffffffc02045a4:	ffe70613          	addi	a2,a4,-2
ffffffffc02045a8:	24d61763          	bne	a2,a3,ffffffffc02047f6 <vmm_init+0x310>
ffffffffc02045ac:	ff07b683          	ld	a3,-16(a5)
ffffffffc02045b0:	24e69363          	bne	a3,a4,ffffffffc02047f6 <vmm_init+0x310>
    for (i = 1; i <= step2; i ++) {
ffffffffc02045b4:	0715                	addi	a4,a4,5
ffffffffc02045b6:	679c                	ld	a5,8(a5)
ffffffffc02045b8:	feb712e3          	bne	a4,a1,ffffffffc020459c <vmm_init+0xb6>
ffffffffc02045bc:	4a1d                	li	s4,7
ffffffffc02045be:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc02045c0:	1f900a93          	li	s5,505
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc02045c4:	85a2                	mv	a1,s0
ffffffffc02045c6:	8526                	mv	a0,s1
ffffffffc02045c8:	bfdff0ef          	jal	ra,ffffffffc02041c4 <find_vma>
ffffffffc02045cc:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc02045ce:	30050463          	beqz	a0,ffffffffc02048d6 <vmm_init+0x3f0>
        struct vma_struct *vma2 = find_vma(mm, i+1);
ffffffffc02045d2:	00140593          	addi	a1,s0,1
ffffffffc02045d6:	8526                	mv	a0,s1
ffffffffc02045d8:	bedff0ef          	jal	ra,ffffffffc02041c4 <find_vma>
ffffffffc02045dc:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc02045de:	2c050c63          	beqz	a0,ffffffffc02048b6 <vmm_init+0x3d0>
        struct vma_struct *vma3 = find_vma(mm, i+2);
ffffffffc02045e2:	85d2                	mv	a1,s4
ffffffffc02045e4:	8526                	mv	a0,s1
ffffffffc02045e6:	bdfff0ef          	jal	ra,ffffffffc02041c4 <find_vma>
        assert(vma3 == NULL);
ffffffffc02045ea:	2a051663          	bnez	a0,ffffffffc0204896 <vmm_init+0x3b0>
        struct vma_struct *vma4 = find_vma(mm, i+3);
ffffffffc02045ee:	00340593          	addi	a1,s0,3
ffffffffc02045f2:	8526                	mv	a0,s1
ffffffffc02045f4:	bd1ff0ef          	jal	ra,ffffffffc02041c4 <find_vma>
        assert(vma4 == NULL);
ffffffffc02045f8:	30051f63          	bnez	a0,ffffffffc0204916 <vmm_init+0x430>
        struct vma_struct *vma5 = find_vma(mm, i+4);
ffffffffc02045fc:	00440593          	addi	a1,s0,4
ffffffffc0204600:	8526                	mv	a0,s1
ffffffffc0204602:	bc3ff0ef          	jal	ra,ffffffffc02041c4 <find_vma>
        assert(vma5 == NULL);
ffffffffc0204606:	2e051863          	bnez	a0,ffffffffc02048f6 <vmm_init+0x410>

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc020460a:	00893783          	ld	a5,8(s2)
ffffffffc020460e:	20879463          	bne	a5,s0,ffffffffc0204816 <vmm_init+0x330>
ffffffffc0204612:	01093783          	ld	a5,16(s2)
ffffffffc0204616:	20fa1063          	bne	s4,a5,ffffffffc0204816 <vmm_init+0x330>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc020461a:	0089b783          	ld	a5,8(s3)
ffffffffc020461e:	20879c63          	bne	a5,s0,ffffffffc0204836 <vmm_init+0x350>
ffffffffc0204622:	0109b783          	ld	a5,16(s3)
ffffffffc0204626:	20fa1863          	bne	s4,a5,ffffffffc0204836 <vmm_init+0x350>
    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc020462a:	0415                	addi	s0,s0,5
ffffffffc020462c:	0a15                	addi	s4,s4,5
ffffffffc020462e:	f9541be3          	bne	s0,s5,ffffffffc02045c4 <vmm_init+0xde>
ffffffffc0204632:	4411                	li	s0,4
    }

    for (i =4; i>=0; i--) {
ffffffffc0204634:	597d                	li	s2,-1
        struct vma_struct *vma_below_5= find_vma(mm,i);
ffffffffc0204636:	85a2                	mv	a1,s0
ffffffffc0204638:	8526                	mv	a0,s1
ffffffffc020463a:	b8bff0ef          	jal	ra,ffffffffc02041c4 <find_vma>
ffffffffc020463e:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL ) {
ffffffffc0204642:	c90d                	beqz	a0,ffffffffc0204674 <vmm_init+0x18e>
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
ffffffffc0204644:	6914                	ld	a3,16(a0)
ffffffffc0204646:	6510                	ld	a2,8(a0)
ffffffffc0204648:	00004517          	auipc	a0,0x4
ffffffffc020464c:	bd850513          	addi	a0,a0,-1064 # ffffffffc0208220 <default_pmm_manager+0xe68>
ffffffffc0204650:	b31fb0ef          	jal	ra,ffffffffc0200180 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0204654:	00004697          	auipc	a3,0x4
ffffffffc0204658:	bf468693          	addi	a3,a3,-1036 # ffffffffc0208248 <default_pmm_manager+0xe90>
ffffffffc020465c:	00002617          	auipc	a2,0x2
ffffffffc0204660:	66460613          	addi	a2,a2,1636 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0204664:	13b00593          	li	a1,315
ffffffffc0204668:	00004517          	auipc	a0,0x4
ffffffffc020466c:	9f050513          	addi	a0,a0,-1552 # ffffffffc0208058 <default_pmm_manager+0xca0>
ffffffffc0204670:	e0bfb0ef          	jal	ra,ffffffffc020047a <__panic>
    for (i =4; i>=0; i--) {
ffffffffc0204674:	147d                	addi	s0,s0,-1
ffffffffc0204676:	fd2410e3          	bne	s0,s2,ffffffffc0204636 <vmm_init+0x150>
    }

    mm_destroy(mm);
ffffffffc020467a:	8526                	mv	a0,s1
ffffffffc020467c:	c59ff0ef          	jal	ra,ffffffffc02042d4 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0204680:	00004517          	auipc	a0,0x4
ffffffffc0204684:	be050513          	addi	a0,a0,-1056 # ffffffffc0208260 <default_pmm_manager+0xea8>
ffffffffc0204688:	af9fb0ef          	jal	ra,ffffffffc0200180 <cprintf>
struct mm_struct *check_mm_struct;

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc020468c:	f54fd0ef          	jal	ra,ffffffffc0201de0 <nr_free_pages>
ffffffffc0204690:	892a                	mv	s2,a0

    check_mm_struct = mm_create();
ffffffffc0204692:	abdff0ef          	jal	ra,ffffffffc020414e <mm_create>
ffffffffc0204696:	000ae797          	auipc	a5,0xae
ffffffffc020469a:	3ca7bd23          	sd	a0,986(a5) # ffffffffc02b2a70 <check_mm_struct>
ffffffffc020469e:	842a                	mv	s0,a0
    assert(check_mm_struct != NULL);
ffffffffc02046a0:	28050b63          	beqz	a0,ffffffffc0204936 <vmm_init+0x450>

    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc02046a4:	000ae497          	auipc	s1,0xae
ffffffffc02046a8:	38c4b483          	ld	s1,908(s1) # ffffffffc02b2a30 <boot_pgdir>
    assert(pgdir[0] == 0);
ffffffffc02046ac:	609c                	ld	a5,0(s1)
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc02046ae:	ed04                	sd	s1,24(a0)
    assert(pgdir[0] == 0);
ffffffffc02046b0:	2e079f63          	bnez	a5,ffffffffc02049ae <vmm_init+0x4c8>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02046b4:	03000513          	li	a0,48
ffffffffc02046b8:	c78fd0ef          	jal	ra,ffffffffc0201b30 <kmalloc>
ffffffffc02046bc:	89aa                	mv	s3,a0
    if (vma != NULL) {
ffffffffc02046be:	18050c63          	beqz	a0,ffffffffc0204856 <vmm_init+0x370>
        vma->vm_end = vm_end;
ffffffffc02046c2:	002007b7          	lui	a5,0x200
ffffffffc02046c6:	00f9b823          	sd	a5,16(s3)
        vma->vm_flags = vm_flags;
ffffffffc02046ca:	4789                	li	a5,2

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc02046cc:	85aa                	mv	a1,a0
        vma->vm_flags = vm_flags;
ffffffffc02046ce:	00f9ac23          	sw	a5,24(s3)
    insert_vma_struct(mm, vma);
ffffffffc02046d2:	8522                	mv	a0,s0
        vma->vm_start = vm_start;
ffffffffc02046d4:	0009b423          	sd	zero,8(s3)
    insert_vma_struct(mm, vma);
ffffffffc02046d8:	b2dff0ef          	jal	ra,ffffffffc0204204 <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc02046dc:	10000593          	li	a1,256
ffffffffc02046e0:	8522                	mv	a0,s0
ffffffffc02046e2:	ae3ff0ef          	jal	ra,ffffffffc02041c4 <find_vma>
ffffffffc02046e6:	10000793          	li	a5,256

    int i, sum = 0;

    for (i = 0; i < 100; i ++) {
ffffffffc02046ea:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc02046ee:	2ea99063          	bne	s3,a0,ffffffffc02049ce <vmm_init+0x4e8>
        *(char *)(addr + i) = i;
ffffffffc02046f2:	00f78023          	sb	a5,0(a5) # 200000 <_binary_obj___user_exit_out_size+0x1f4eb8>
    for (i = 0; i < 100; i ++) {
ffffffffc02046f6:	0785                	addi	a5,a5,1
ffffffffc02046f8:	fee79de3          	bne	a5,a4,ffffffffc02046f2 <vmm_init+0x20c>
        sum += i;
ffffffffc02046fc:	6705                	lui	a4,0x1
ffffffffc02046fe:	10000793          	li	a5,256
ffffffffc0204702:	35670713          	addi	a4,a4,854 # 1356 <_binary_obj___user_faultread_out_size-0x887a>
    }
    for (i = 0; i < 100; i ++) {
ffffffffc0204706:	16400613          	li	a2,356
        sum -= *(char *)(addr + i);
ffffffffc020470a:	0007c683          	lbu	a3,0(a5)
    for (i = 0; i < 100; i ++) {
ffffffffc020470e:	0785                	addi	a5,a5,1
        sum -= *(char *)(addr + i);
ffffffffc0204710:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i ++) {
ffffffffc0204712:	fec79ce3          	bne	a5,a2,ffffffffc020470a <vmm_init+0x224>
    }

    assert(sum == 0);
ffffffffc0204716:	2e071863          	bnez	a4,ffffffffc0204a06 <vmm_init+0x520>
    return pa2page(PDE_ADDR(pde));
ffffffffc020471a:	609c                	ld	a5,0(s1)
    if (PPN(pa) >= npage) {
ffffffffc020471c:	000aea97          	auipc	s5,0xae
ffffffffc0204720:	31ca8a93          	addi	s5,s5,796 # ffffffffc02b2a38 <npage>
ffffffffc0204724:	000ab603          	ld	a2,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0204728:	078a                	slli	a5,a5,0x2
ffffffffc020472a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020472c:	2cc7f163          	bgeu	a5,a2,ffffffffc02049ee <vmm_init+0x508>
    return &pages[PPN(pa) - nbase];
ffffffffc0204730:	00004a17          	auipc	s4,0x4
ffffffffc0204734:	610a3a03          	ld	s4,1552(s4) # ffffffffc0208d40 <nbase>
ffffffffc0204738:	414787b3          	sub	a5,a5,s4
ffffffffc020473c:	079a                	slli	a5,a5,0x6
    return page - pages + nbase;
ffffffffc020473e:	8799                	srai	a5,a5,0x6
ffffffffc0204740:	97d2                	add	a5,a5,s4
    return KADDR(page2pa(page));
ffffffffc0204742:	00c79713          	slli	a4,a5,0xc
ffffffffc0204746:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0204748:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc020474c:	24c77563          	bgeu	a4,a2,ffffffffc0204996 <vmm_init+0x4b0>
ffffffffc0204750:	000ae997          	auipc	s3,0xae
ffffffffc0204754:	3009b983          	ld	s3,768(s3) # ffffffffc02b2a50 <va_pa_offset>

    pde_t *pd1=pgdir,*pd0=page2kva(pde2page(pgdir[0]));
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc0204758:	4581                	li	a1,0
ffffffffc020475a:	8526                	mv	a0,s1
ffffffffc020475c:	99b6                	add	s3,s3,a3
ffffffffc020475e:	cbbfd0ef          	jal	ra,ffffffffc0202418 <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc0204762:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage) {
ffffffffc0204766:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc020476a:	078a                	slli	a5,a5,0x2
ffffffffc020476c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020476e:	28e7f063          	bgeu	a5,a4,ffffffffc02049ee <vmm_init+0x508>
    return &pages[PPN(pa) - nbase];
ffffffffc0204772:	000ae997          	auipc	s3,0xae
ffffffffc0204776:	2ce98993          	addi	s3,s3,718 # ffffffffc02b2a40 <pages>
ffffffffc020477a:	0009b503          	ld	a0,0(s3)
ffffffffc020477e:	414787b3          	sub	a5,a5,s4
ffffffffc0204782:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd0[0]));
ffffffffc0204784:	953e                	add	a0,a0,a5
ffffffffc0204786:	4585                	li	a1,1
ffffffffc0204788:	e18fd0ef          	jal	ra,ffffffffc0201da0 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc020478c:	609c                	ld	a5,0(s1)
    if (PPN(pa) >= npage) {
ffffffffc020478e:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0204792:	078a                	slli	a5,a5,0x2
ffffffffc0204794:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0204796:	24e7fc63          	bgeu	a5,a4,ffffffffc02049ee <vmm_init+0x508>
    return &pages[PPN(pa) - nbase];
ffffffffc020479a:	0009b503          	ld	a0,0(s3)
ffffffffc020479e:	414787b3          	sub	a5,a5,s4
ffffffffc02047a2:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc02047a4:	4585                	li	a1,1
ffffffffc02047a6:	953e                	add	a0,a0,a5
ffffffffc02047a8:	df8fd0ef          	jal	ra,ffffffffc0201da0 <free_pages>
    pgdir[0] = 0;
ffffffffc02047ac:	0004b023          	sd	zero,0(s1)
  asm volatile("sfence.vma");
ffffffffc02047b0:	12000073          	sfence.vma
    flush_tlb();

    mm->pgdir = NULL;
    mm_destroy(mm);
ffffffffc02047b4:	8522                	mv	a0,s0
    mm->pgdir = NULL;
ffffffffc02047b6:	00043c23          	sd	zero,24(s0)
    mm_destroy(mm);
ffffffffc02047ba:	b1bff0ef          	jal	ra,ffffffffc02042d4 <mm_destroy>
    check_mm_struct = NULL;
ffffffffc02047be:	000ae797          	auipc	a5,0xae
ffffffffc02047c2:	2a07b923          	sd	zero,690(a5) # ffffffffc02b2a70 <check_mm_struct>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02047c6:	e1afd0ef          	jal	ra,ffffffffc0201de0 <nr_free_pages>
ffffffffc02047ca:	1aa91663          	bne	s2,a0,ffffffffc0204976 <vmm_init+0x490>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc02047ce:	00004517          	auipc	a0,0x4
ffffffffc02047d2:	b2250513          	addi	a0,a0,-1246 # ffffffffc02082f0 <default_pmm_manager+0xf38>
ffffffffc02047d6:	9abfb0ef          	jal	ra,ffffffffc0200180 <cprintf>
}
ffffffffc02047da:	7442                	ld	s0,48(sp)
ffffffffc02047dc:	70e2                	ld	ra,56(sp)
ffffffffc02047de:	74a2                	ld	s1,40(sp)
ffffffffc02047e0:	7902                	ld	s2,32(sp)
ffffffffc02047e2:	69e2                	ld	s3,24(sp)
ffffffffc02047e4:	6a42                	ld	s4,16(sp)
ffffffffc02047e6:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc02047e8:	00004517          	auipc	a0,0x4
ffffffffc02047ec:	b2850513          	addi	a0,a0,-1240 # ffffffffc0208310 <default_pmm_manager+0xf58>
}
ffffffffc02047f0:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc02047f2:	98ffb06f          	j	ffffffffc0200180 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02047f6:	00004697          	auipc	a3,0x4
ffffffffc02047fa:	94268693          	addi	a3,a3,-1726 # ffffffffc0208138 <default_pmm_manager+0xd80>
ffffffffc02047fe:	00002617          	auipc	a2,0x2
ffffffffc0204802:	4c260613          	addi	a2,a2,1218 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0204806:	12200593          	li	a1,290
ffffffffc020480a:	00004517          	auipc	a0,0x4
ffffffffc020480e:	84e50513          	addi	a0,a0,-1970 # ffffffffc0208058 <default_pmm_manager+0xca0>
ffffffffc0204812:	c69fb0ef          	jal	ra,ffffffffc020047a <__panic>
        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0204816:	00004697          	auipc	a3,0x4
ffffffffc020481a:	9aa68693          	addi	a3,a3,-1622 # ffffffffc02081c0 <default_pmm_manager+0xe08>
ffffffffc020481e:	00002617          	auipc	a2,0x2
ffffffffc0204822:	4a260613          	addi	a2,a2,1186 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0204826:	13200593          	li	a1,306
ffffffffc020482a:	00004517          	auipc	a0,0x4
ffffffffc020482e:	82e50513          	addi	a0,a0,-2002 # ffffffffc0208058 <default_pmm_manager+0xca0>
ffffffffc0204832:	c49fb0ef          	jal	ra,ffffffffc020047a <__panic>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0204836:	00004697          	auipc	a3,0x4
ffffffffc020483a:	9ba68693          	addi	a3,a3,-1606 # ffffffffc02081f0 <default_pmm_manager+0xe38>
ffffffffc020483e:	00002617          	auipc	a2,0x2
ffffffffc0204842:	48260613          	addi	a2,a2,1154 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0204846:	13300593          	li	a1,307
ffffffffc020484a:	00004517          	auipc	a0,0x4
ffffffffc020484e:	80e50513          	addi	a0,a0,-2034 # ffffffffc0208058 <default_pmm_manager+0xca0>
ffffffffc0204852:	c29fb0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(vma != NULL);
ffffffffc0204856:	00003697          	auipc	a3,0x3
ffffffffc020485a:	32268693          	addi	a3,a3,802 # ffffffffc0207b78 <default_pmm_manager+0x7c0>
ffffffffc020485e:	00002617          	auipc	a2,0x2
ffffffffc0204862:	46260613          	addi	a2,a2,1122 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0204866:	15200593          	li	a1,338
ffffffffc020486a:	00003517          	auipc	a0,0x3
ffffffffc020486e:	7ee50513          	addi	a0,a0,2030 # ffffffffc0208058 <default_pmm_manager+0xca0>
ffffffffc0204872:	c09fb0ef          	jal	ra,ffffffffc020047a <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0204876:	00004697          	auipc	a3,0x4
ffffffffc020487a:	8aa68693          	addi	a3,a3,-1878 # ffffffffc0208120 <default_pmm_manager+0xd68>
ffffffffc020487e:	00002617          	auipc	a2,0x2
ffffffffc0204882:	44260613          	addi	a2,a2,1090 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0204886:	12000593          	li	a1,288
ffffffffc020488a:	00003517          	auipc	a0,0x3
ffffffffc020488e:	7ce50513          	addi	a0,a0,1998 # ffffffffc0208058 <default_pmm_manager+0xca0>
ffffffffc0204892:	be9fb0ef          	jal	ra,ffffffffc020047a <__panic>
        assert(vma3 == NULL);
ffffffffc0204896:	00004697          	auipc	a3,0x4
ffffffffc020489a:	8fa68693          	addi	a3,a3,-1798 # ffffffffc0208190 <default_pmm_manager+0xdd8>
ffffffffc020489e:	00002617          	auipc	a2,0x2
ffffffffc02048a2:	42260613          	addi	a2,a2,1058 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02048a6:	12c00593          	li	a1,300
ffffffffc02048aa:	00003517          	auipc	a0,0x3
ffffffffc02048ae:	7ae50513          	addi	a0,a0,1966 # ffffffffc0208058 <default_pmm_manager+0xca0>
ffffffffc02048b2:	bc9fb0ef          	jal	ra,ffffffffc020047a <__panic>
        assert(vma2 != NULL);
ffffffffc02048b6:	00004697          	auipc	a3,0x4
ffffffffc02048ba:	8ca68693          	addi	a3,a3,-1846 # ffffffffc0208180 <default_pmm_manager+0xdc8>
ffffffffc02048be:	00002617          	auipc	a2,0x2
ffffffffc02048c2:	40260613          	addi	a2,a2,1026 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02048c6:	12a00593          	li	a1,298
ffffffffc02048ca:	00003517          	auipc	a0,0x3
ffffffffc02048ce:	78e50513          	addi	a0,a0,1934 # ffffffffc0208058 <default_pmm_manager+0xca0>
ffffffffc02048d2:	ba9fb0ef          	jal	ra,ffffffffc020047a <__panic>
        assert(vma1 != NULL);
ffffffffc02048d6:	00004697          	auipc	a3,0x4
ffffffffc02048da:	89a68693          	addi	a3,a3,-1894 # ffffffffc0208170 <default_pmm_manager+0xdb8>
ffffffffc02048de:	00002617          	auipc	a2,0x2
ffffffffc02048e2:	3e260613          	addi	a2,a2,994 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02048e6:	12800593          	li	a1,296
ffffffffc02048ea:	00003517          	auipc	a0,0x3
ffffffffc02048ee:	76e50513          	addi	a0,a0,1902 # ffffffffc0208058 <default_pmm_manager+0xca0>
ffffffffc02048f2:	b89fb0ef          	jal	ra,ffffffffc020047a <__panic>
        assert(vma5 == NULL);
ffffffffc02048f6:	00004697          	auipc	a3,0x4
ffffffffc02048fa:	8ba68693          	addi	a3,a3,-1862 # ffffffffc02081b0 <default_pmm_manager+0xdf8>
ffffffffc02048fe:	00002617          	auipc	a2,0x2
ffffffffc0204902:	3c260613          	addi	a2,a2,962 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0204906:	13000593          	li	a1,304
ffffffffc020490a:	00003517          	auipc	a0,0x3
ffffffffc020490e:	74e50513          	addi	a0,a0,1870 # ffffffffc0208058 <default_pmm_manager+0xca0>
ffffffffc0204912:	b69fb0ef          	jal	ra,ffffffffc020047a <__panic>
        assert(vma4 == NULL);
ffffffffc0204916:	00004697          	auipc	a3,0x4
ffffffffc020491a:	88a68693          	addi	a3,a3,-1910 # ffffffffc02081a0 <default_pmm_manager+0xde8>
ffffffffc020491e:	00002617          	auipc	a2,0x2
ffffffffc0204922:	3a260613          	addi	a2,a2,930 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0204926:	12e00593          	li	a1,302
ffffffffc020492a:	00003517          	auipc	a0,0x3
ffffffffc020492e:	72e50513          	addi	a0,a0,1838 # ffffffffc0208058 <default_pmm_manager+0xca0>
ffffffffc0204932:	b49fb0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(check_mm_struct != NULL);
ffffffffc0204936:	00004697          	auipc	a3,0x4
ffffffffc020493a:	94a68693          	addi	a3,a3,-1718 # ffffffffc0208280 <default_pmm_manager+0xec8>
ffffffffc020493e:	00002617          	auipc	a2,0x2
ffffffffc0204942:	38260613          	addi	a2,a2,898 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0204946:	14b00593          	li	a1,331
ffffffffc020494a:	00003517          	auipc	a0,0x3
ffffffffc020494e:	70e50513          	addi	a0,a0,1806 # ffffffffc0208058 <default_pmm_manager+0xca0>
ffffffffc0204952:	b29fb0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(mm != NULL);
ffffffffc0204956:	00003697          	auipc	a3,0x3
ffffffffc020495a:	1ea68693          	addi	a3,a3,490 # ffffffffc0207b40 <default_pmm_manager+0x788>
ffffffffc020495e:	00002617          	auipc	a2,0x2
ffffffffc0204962:	36260613          	addi	a2,a2,866 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0204966:	10c00593          	li	a1,268
ffffffffc020496a:	00003517          	auipc	a0,0x3
ffffffffc020496e:	6ee50513          	addi	a0,a0,1774 # ffffffffc0208058 <default_pmm_manager+0xca0>
ffffffffc0204972:	b09fb0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0204976:	00004697          	auipc	a3,0x4
ffffffffc020497a:	95268693          	addi	a3,a3,-1710 # ffffffffc02082c8 <default_pmm_manager+0xf10>
ffffffffc020497e:	00002617          	auipc	a2,0x2
ffffffffc0204982:	34260613          	addi	a2,a2,834 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0204986:	17000593          	li	a1,368
ffffffffc020498a:	00003517          	auipc	a0,0x3
ffffffffc020498e:	6ce50513          	addi	a0,a0,1742 # ffffffffc0208058 <default_pmm_manager+0xca0>
ffffffffc0204992:	ae9fb0ef          	jal	ra,ffffffffc020047a <__panic>
    return KADDR(page2pa(page));
ffffffffc0204996:	00003617          	auipc	a2,0x3
ffffffffc020499a:	a5a60613          	addi	a2,a2,-1446 # ffffffffc02073f0 <default_pmm_manager+0x38>
ffffffffc020499e:	06900593          	li	a1,105
ffffffffc02049a2:	00003517          	auipc	a0,0x3
ffffffffc02049a6:	a7650513          	addi	a0,a0,-1418 # ffffffffc0207418 <default_pmm_manager+0x60>
ffffffffc02049aa:	ad1fb0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgdir[0] == 0);
ffffffffc02049ae:	00003697          	auipc	a3,0x3
ffffffffc02049b2:	1ba68693          	addi	a3,a3,442 # ffffffffc0207b68 <default_pmm_manager+0x7b0>
ffffffffc02049b6:	00002617          	auipc	a2,0x2
ffffffffc02049ba:	30a60613          	addi	a2,a2,778 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02049be:	14f00593          	li	a1,335
ffffffffc02049c2:	00003517          	auipc	a0,0x3
ffffffffc02049c6:	69650513          	addi	a0,a0,1686 # ffffffffc0208058 <default_pmm_manager+0xca0>
ffffffffc02049ca:	ab1fb0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc02049ce:	00004697          	auipc	a3,0x4
ffffffffc02049d2:	8ca68693          	addi	a3,a3,-1846 # ffffffffc0208298 <default_pmm_manager+0xee0>
ffffffffc02049d6:	00002617          	auipc	a2,0x2
ffffffffc02049da:	2ea60613          	addi	a2,a2,746 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02049de:	15700593          	li	a1,343
ffffffffc02049e2:	00003517          	auipc	a0,0x3
ffffffffc02049e6:	67650513          	addi	a0,a0,1654 # ffffffffc0208058 <default_pmm_manager+0xca0>
ffffffffc02049ea:	a91fb0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02049ee:	00003617          	auipc	a2,0x3
ffffffffc02049f2:	ad260613          	addi	a2,a2,-1326 # ffffffffc02074c0 <default_pmm_manager+0x108>
ffffffffc02049f6:	06200593          	li	a1,98
ffffffffc02049fa:	00003517          	auipc	a0,0x3
ffffffffc02049fe:	a1e50513          	addi	a0,a0,-1506 # ffffffffc0207418 <default_pmm_manager+0x60>
ffffffffc0204a02:	a79fb0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(sum == 0);
ffffffffc0204a06:	00004697          	auipc	a3,0x4
ffffffffc0204a0a:	8b268693          	addi	a3,a3,-1870 # ffffffffc02082b8 <default_pmm_manager+0xf00>
ffffffffc0204a0e:	00002617          	auipc	a2,0x2
ffffffffc0204a12:	2b260613          	addi	a2,a2,690 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0204a16:	16300593          	li	a1,355
ffffffffc0204a1a:	00003517          	auipc	a0,0x3
ffffffffc0204a1e:	63e50513          	addi	a0,a0,1598 # ffffffffc0208058 <default_pmm_manager+0xca0>
ffffffffc0204a22:	a59fb0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0204a26 <do_pgfault>:
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc0204a26:	7179                	addi	sp,sp,-48
    int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0204a28:	85b2                	mv	a1,a2
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc0204a2a:	f022                	sd	s0,32(sp)
ffffffffc0204a2c:	ec26                	sd	s1,24(sp)
ffffffffc0204a2e:	f406                	sd	ra,40(sp)
ffffffffc0204a30:	e84a                	sd	s2,16(sp)
ffffffffc0204a32:	8432                	mv	s0,a2
ffffffffc0204a34:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0204a36:	f8eff0ef          	jal	ra,ffffffffc02041c4 <find_vma>

    pgfault_num++;
ffffffffc0204a3a:	000ae797          	auipc	a5,0xae
ffffffffc0204a3e:	03e7a783          	lw	a5,62(a5) # ffffffffc02b2a78 <pgfault_num>
ffffffffc0204a42:	2785                	addiw	a5,a5,1
ffffffffc0204a44:	000ae717          	auipc	a4,0xae
ffffffffc0204a48:	02f72a23          	sw	a5,52(a4) # ffffffffc02b2a78 <pgfault_num>
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {
ffffffffc0204a4c:	c541                	beqz	a0,ffffffffc0204ad4 <do_pgfault+0xae>
ffffffffc0204a4e:	651c                	ld	a5,8(a0)
ffffffffc0204a50:	08f46263          	bltu	s0,a5,ffffffffc0204ad4 <do_pgfault+0xae>
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0204a54:	4d1c                	lw	a5,24(a0)
    uint32_t perm = PTE_U;
ffffffffc0204a56:	4941                	li	s2,16
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0204a58:	8b89                	andi	a5,a5,2
ffffffffc0204a5a:	ebb9                	bnez	a5,ffffffffc0204ab0 <do_pgfault+0x8a>
        perm |= READ_WRITE;
    }
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0204a5c:	75fd                	lui	a1,0xfffff

    pte_t *ptep=NULL;
  
    // try to find a pte, if pte's PT(Page Table) isn't existed, then create a PT.
    // (notice the 3th parameter '1')
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc0204a5e:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0204a60:	8c6d                	and	s0,s0,a1
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc0204a62:	4605                	li	a2,1
ffffffffc0204a64:	85a2                	mv	a1,s0
ffffffffc0204a66:	bb4fd0ef          	jal	ra,ffffffffc0201e1a <get_pte>
ffffffffc0204a6a:	c551                	beqz	a0,ffffffffc0204af6 <do_pgfault+0xd0>
        cprintf("get_pte in do_pgfault failed\n");
        goto failed;
    }
    
    if (*ptep == 0) { // if the phy addr isn't exist, then alloc a page & map the phy addr with logical addr
ffffffffc0204a6c:	610c                	ld	a1,0(a0)
ffffffffc0204a6e:	c1b9                	beqz	a1,ffffffffc0204ab4 <do_pgfault+0x8e>
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {
ffffffffc0204a70:	000ae797          	auipc	a5,0xae
ffffffffc0204a74:	ff87a783          	lw	a5,-8(a5) # ffffffffc02b2a68 <swap_init_ok>
ffffffffc0204a78:	c7bd                	beqz	a5,ffffffffc0204ae6 <do_pgfault+0xc0>
            struct Page *page = NULL;
            // 你要编写的内容在这里，请基于上文说明以及下文的英文注释完成代码编写
            //(1）According to the mm AND addr, try
            //to load the content of right disk page
            //into the memory which page managed.
            swap_in(mm, addr, &page);
ffffffffc0204a7a:	85a2                	mv	a1,s0
ffffffffc0204a7c:	0030                	addi	a2,sp,8
ffffffffc0204a7e:	8526                	mv	a0,s1
            struct Page *page = NULL;
ffffffffc0204a80:	e402                	sd	zero,8(sp)
            swap_in(mm, addr, &page);
ffffffffc0204a82:	a40ff0ef          	jal	ra,ffffffffc0203cc2 <swap_in>
            //(2) According to the mm,
            //addr AND page, setup the
            //map of phy addr <--->
            //logical addr
            page_insert(mm->pgdir, page, addr, perm);
ffffffffc0204a86:	65a2                	ld	a1,8(sp)
ffffffffc0204a88:	6c88                	ld	a0,24(s1)
ffffffffc0204a8a:	86ca                	mv	a3,s2
ffffffffc0204a8c:	8622                	mv	a2,s0
ffffffffc0204a8e:	a27fd0ef          	jal	ra,ffffffffc02024b4 <page_insert>
            //(3) make the page swappable.
            swap_map_swappable(mm, addr, page, 1);
ffffffffc0204a92:	6622                	ld	a2,8(sp)
ffffffffc0204a94:	4685                	li	a3,1
ffffffffc0204a96:	85a2                	mv	a1,s0
ffffffffc0204a98:	8526                	mv	a0,s1
ffffffffc0204a9a:	908ff0ef          	jal	ra,ffffffffc0203ba2 <swap_map_swappable>
            page->pra_vaddr = addr;
ffffffffc0204a9e:	67a2                	ld	a5,8(sp)
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
   }

   ret = 0;
ffffffffc0204aa0:	4501                	li	a0,0
            page->pra_vaddr = addr;
ffffffffc0204aa2:	ff80                	sd	s0,56(a5)
failed:
    return ret;
}
ffffffffc0204aa4:	70a2                	ld	ra,40(sp)
ffffffffc0204aa6:	7402                	ld	s0,32(sp)
ffffffffc0204aa8:	64e2                	ld	s1,24(sp)
ffffffffc0204aaa:	6942                	ld	s2,16(sp)
ffffffffc0204aac:	6145                	addi	sp,sp,48
ffffffffc0204aae:	8082                	ret
        perm |= READ_WRITE;
ffffffffc0204ab0:	495d                	li	s2,23
ffffffffc0204ab2:	b76d                	j	ffffffffc0204a5c <do_pgfault+0x36>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc0204ab4:	6c88                	ld	a0,24(s1)
ffffffffc0204ab6:	864a                	mv	a2,s2
ffffffffc0204ab8:	85a2                	mv	a1,s0
ffffffffc0204aba:	8c1fe0ef          	jal	ra,ffffffffc020337a <pgdir_alloc_page>
ffffffffc0204abe:	87aa                	mv	a5,a0
   ret = 0;
ffffffffc0204ac0:	4501                	li	a0,0
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc0204ac2:	f3ed                	bnez	a5,ffffffffc0204aa4 <do_pgfault+0x7e>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc0204ac4:	00004517          	auipc	a0,0x4
ffffffffc0204ac8:	8b450513          	addi	a0,a0,-1868 # ffffffffc0208378 <default_pmm_manager+0xfc0>
ffffffffc0204acc:	eb4fb0ef          	jal	ra,ffffffffc0200180 <cprintf>
    ret = -E_NO_MEM;
ffffffffc0204ad0:	5571                	li	a0,-4
            goto failed;
ffffffffc0204ad2:	bfc9                	j	ffffffffc0204aa4 <do_pgfault+0x7e>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc0204ad4:	85a2                	mv	a1,s0
ffffffffc0204ad6:	00004517          	auipc	a0,0x4
ffffffffc0204ada:	85250513          	addi	a0,a0,-1966 # ffffffffc0208328 <default_pmm_manager+0xf70>
ffffffffc0204ade:	ea2fb0ef          	jal	ra,ffffffffc0200180 <cprintf>
    int ret = -E_INVAL;
ffffffffc0204ae2:	5575                	li	a0,-3
        goto failed;
ffffffffc0204ae4:	b7c1                	j	ffffffffc0204aa4 <do_pgfault+0x7e>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc0204ae6:	00004517          	auipc	a0,0x4
ffffffffc0204aea:	8ba50513          	addi	a0,a0,-1862 # ffffffffc02083a0 <default_pmm_manager+0xfe8>
ffffffffc0204aee:	e92fb0ef          	jal	ra,ffffffffc0200180 <cprintf>
    ret = -E_NO_MEM;
ffffffffc0204af2:	5571                	li	a0,-4
            goto failed;
ffffffffc0204af4:	bf45                	j	ffffffffc0204aa4 <do_pgfault+0x7e>
        cprintf("get_pte in do_pgfault failed\n");
ffffffffc0204af6:	00004517          	auipc	a0,0x4
ffffffffc0204afa:	86250513          	addi	a0,a0,-1950 # ffffffffc0208358 <default_pmm_manager+0xfa0>
ffffffffc0204afe:	e82fb0ef          	jal	ra,ffffffffc0200180 <cprintf>
    ret = -E_NO_MEM;
ffffffffc0204b02:	5571                	li	a0,-4
        goto failed;
ffffffffc0204b04:	b745                	j	ffffffffc0204aa4 <do_pgfault+0x7e>

ffffffffc0204b06 <user_mem_check>:

bool
user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write) {
ffffffffc0204b06:	7179                	addi	sp,sp,-48
ffffffffc0204b08:	f022                	sd	s0,32(sp)
ffffffffc0204b0a:	f406                	sd	ra,40(sp)
ffffffffc0204b0c:	ec26                	sd	s1,24(sp)
ffffffffc0204b0e:	e84a                	sd	s2,16(sp)
ffffffffc0204b10:	e44e                	sd	s3,8(sp)
ffffffffc0204b12:	e052                	sd	s4,0(sp)
ffffffffc0204b14:	842e                	mv	s0,a1
    if (mm != NULL) {
ffffffffc0204b16:	c135                	beqz	a0,ffffffffc0204b7a <user_mem_check+0x74>
        if (!USER_ACCESS(addr, addr + len)) {
ffffffffc0204b18:	002007b7          	lui	a5,0x200
ffffffffc0204b1c:	04f5e663          	bltu	a1,a5,ffffffffc0204b68 <user_mem_check+0x62>
ffffffffc0204b20:	00c584b3          	add	s1,a1,a2
ffffffffc0204b24:	0495f263          	bgeu	a1,s1,ffffffffc0204b68 <user_mem_check+0x62>
ffffffffc0204b28:	4785                	li	a5,1
ffffffffc0204b2a:	07fe                	slli	a5,a5,0x1f
ffffffffc0204b2c:	0297ee63          	bltu	a5,s1,ffffffffc0204b68 <user_mem_check+0x62>
ffffffffc0204b30:	892a                	mv	s2,a0
ffffffffc0204b32:	89b6                	mv	s3,a3
            }
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK)) {
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc0204b34:	6a05                	lui	s4,0x1
ffffffffc0204b36:	a821                	j	ffffffffc0204b4e <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc0204b38:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc0204b3c:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK)) {
ffffffffc0204b3e:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc0204b40:	c685                	beqz	a3,ffffffffc0204b68 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK)) {
ffffffffc0204b42:	c399                	beqz	a5,ffffffffc0204b48 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc0204b44:	02e46263          	bltu	s0,a4,ffffffffc0204b68 <user_mem_check+0x62>
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0204b48:	6900                	ld	s0,16(a0)
        while (start < end) {
ffffffffc0204b4a:	04947663          	bgeu	s0,s1,ffffffffc0204b96 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start) {
ffffffffc0204b4e:	85a2                	mv	a1,s0
ffffffffc0204b50:	854a                	mv	a0,s2
ffffffffc0204b52:	e72ff0ef          	jal	ra,ffffffffc02041c4 <find_vma>
ffffffffc0204b56:	c909                	beqz	a0,ffffffffc0204b68 <user_mem_check+0x62>
ffffffffc0204b58:	6518                	ld	a4,8(a0)
ffffffffc0204b5a:	00e46763          	bltu	s0,a4,ffffffffc0204b68 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc0204b5e:	4d1c                	lw	a5,24(a0)
ffffffffc0204b60:	fc099ce3          	bnez	s3,ffffffffc0204b38 <user_mem_check+0x32>
ffffffffc0204b64:	8b85                	andi	a5,a5,1
ffffffffc0204b66:	f3ed                	bnez	a5,ffffffffc0204b48 <user_mem_check+0x42>
            return 0;
ffffffffc0204b68:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc0204b6a:	70a2                	ld	ra,40(sp)
ffffffffc0204b6c:	7402                	ld	s0,32(sp)
ffffffffc0204b6e:	64e2                	ld	s1,24(sp)
ffffffffc0204b70:	6942                	ld	s2,16(sp)
ffffffffc0204b72:	69a2                	ld	s3,8(sp)
ffffffffc0204b74:	6a02                	ld	s4,0(sp)
ffffffffc0204b76:	6145                	addi	sp,sp,48
ffffffffc0204b78:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0204b7a:	c02007b7          	lui	a5,0xc0200
ffffffffc0204b7e:	4501                	li	a0,0
ffffffffc0204b80:	fef5e5e3          	bltu	a1,a5,ffffffffc0204b6a <user_mem_check+0x64>
ffffffffc0204b84:	962e                	add	a2,a2,a1
ffffffffc0204b86:	fec5f2e3          	bgeu	a1,a2,ffffffffc0204b6a <user_mem_check+0x64>
ffffffffc0204b8a:	c8000537          	lui	a0,0xc8000
ffffffffc0204b8e:	0505                	addi	a0,a0,1
ffffffffc0204b90:	00a63533          	sltu	a0,a2,a0
ffffffffc0204b94:	bfd9                	j	ffffffffc0204b6a <user_mem_check+0x64>
        return 1;
ffffffffc0204b96:	4505                	li	a0,1
ffffffffc0204b98:	bfc9                	j	ffffffffc0204b6a <user_mem_check+0x64>

ffffffffc0204b9a <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc0204b9a:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204b9c:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc0204b9e:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204ba0:	a4dfb0ef          	jal	ra,ffffffffc02005ec <ide_device_valid>
ffffffffc0204ba4:	cd01                	beqz	a0,ffffffffc0204bbc <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204ba6:	4505                	li	a0,1
ffffffffc0204ba8:	a4bfb0ef          	jal	ra,ffffffffc02005f2 <ide_device_size>
}
ffffffffc0204bac:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204bae:	810d                	srli	a0,a0,0x3
ffffffffc0204bb0:	000ae797          	auipc	a5,0xae
ffffffffc0204bb4:	eaa7b423          	sd	a0,-344(a5) # ffffffffc02b2a58 <max_swap_offset>
}
ffffffffc0204bb8:	0141                	addi	sp,sp,16
ffffffffc0204bba:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0204bbc:	00004617          	auipc	a2,0x4
ffffffffc0204bc0:	80c60613          	addi	a2,a2,-2036 # ffffffffc02083c8 <default_pmm_manager+0x1010>
ffffffffc0204bc4:	45b5                	li	a1,13
ffffffffc0204bc6:	00004517          	auipc	a0,0x4
ffffffffc0204bca:	82250513          	addi	a0,a0,-2014 # ffffffffc02083e8 <default_pmm_manager+0x1030>
ffffffffc0204bce:	8adfb0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0204bd2 <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {
ffffffffc0204bd2:	1141                	addi	sp,sp,-16
ffffffffc0204bd4:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204bd6:	00855793          	srli	a5,a0,0x8
ffffffffc0204bda:	cbb1                	beqz	a5,ffffffffc0204c2e <swapfs_read+0x5c>
ffffffffc0204bdc:	000ae717          	auipc	a4,0xae
ffffffffc0204be0:	e7c73703          	ld	a4,-388(a4) # ffffffffc02b2a58 <max_swap_offset>
ffffffffc0204be4:	04e7f563          	bgeu	a5,a4,ffffffffc0204c2e <swapfs_read+0x5c>
    return page - pages + nbase;
ffffffffc0204be8:	000ae617          	auipc	a2,0xae
ffffffffc0204bec:	e5863603          	ld	a2,-424(a2) # ffffffffc02b2a40 <pages>
ffffffffc0204bf0:	8d91                	sub	a1,a1,a2
ffffffffc0204bf2:	4065d613          	srai	a2,a1,0x6
ffffffffc0204bf6:	00004717          	auipc	a4,0x4
ffffffffc0204bfa:	14a73703          	ld	a4,330(a4) # ffffffffc0208d40 <nbase>
ffffffffc0204bfe:	963a                	add	a2,a2,a4
    return KADDR(page2pa(page));
ffffffffc0204c00:	00c61713          	slli	a4,a2,0xc
ffffffffc0204c04:	8331                	srli	a4,a4,0xc
ffffffffc0204c06:	000ae697          	auipc	a3,0xae
ffffffffc0204c0a:	e326b683          	ld	a3,-462(a3) # ffffffffc02b2a38 <npage>
ffffffffc0204c0e:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204c12:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc0204c14:	02d77963          	bgeu	a4,a3,ffffffffc0204c46 <swapfs_read+0x74>
}
ffffffffc0204c18:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204c1a:	000ae797          	auipc	a5,0xae
ffffffffc0204c1e:	e367b783          	ld	a5,-458(a5) # ffffffffc02b2a50 <va_pa_offset>
ffffffffc0204c22:	46a1                	li	a3,8
ffffffffc0204c24:	963e                	add	a2,a2,a5
ffffffffc0204c26:	4505                	li	a0,1
}
ffffffffc0204c28:	0141                	addi	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204c2a:	9cffb06f          	j	ffffffffc02005f8 <ide_read_secs>
ffffffffc0204c2e:	86aa                	mv	a3,a0
ffffffffc0204c30:	00003617          	auipc	a2,0x3
ffffffffc0204c34:	7d060613          	addi	a2,a2,2000 # ffffffffc0208400 <default_pmm_manager+0x1048>
ffffffffc0204c38:	45d1                	li	a1,20
ffffffffc0204c3a:	00003517          	auipc	a0,0x3
ffffffffc0204c3e:	7ae50513          	addi	a0,a0,1966 # ffffffffc02083e8 <default_pmm_manager+0x1030>
ffffffffc0204c42:	839fb0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc0204c46:	86b2                	mv	a3,a2
ffffffffc0204c48:	06900593          	li	a1,105
ffffffffc0204c4c:	00002617          	auipc	a2,0x2
ffffffffc0204c50:	7a460613          	addi	a2,a2,1956 # ffffffffc02073f0 <default_pmm_manager+0x38>
ffffffffc0204c54:	00002517          	auipc	a0,0x2
ffffffffc0204c58:	7c450513          	addi	a0,a0,1988 # ffffffffc0207418 <default_pmm_manager+0x60>
ffffffffc0204c5c:	81ffb0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0204c60 <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc0204c60:	1141                	addi	sp,sp,-16
ffffffffc0204c62:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204c64:	00855793          	srli	a5,a0,0x8
ffffffffc0204c68:	cbb1                	beqz	a5,ffffffffc0204cbc <swapfs_write+0x5c>
ffffffffc0204c6a:	000ae717          	auipc	a4,0xae
ffffffffc0204c6e:	dee73703          	ld	a4,-530(a4) # ffffffffc02b2a58 <max_swap_offset>
ffffffffc0204c72:	04e7f563          	bgeu	a5,a4,ffffffffc0204cbc <swapfs_write+0x5c>
    return page - pages + nbase;
ffffffffc0204c76:	000ae617          	auipc	a2,0xae
ffffffffc0204c7a:	dca63603          	ld	a2,-566(a2) # ffffffffc02b2a40 <pages>
ffffffffc0204c7e:	8d91                	sub	a1,a1,a2
ffffffffc0204c80:	4065d613          	srai	a2,a1,0x6
ffffffffc0204c84:	00004717          	auipc	a4,0x4
ffffffffc0204c88:	0bc73703          	ld	a4,188(a4) # ffffffffc0208d40 <nbase>
ffffffffc0204c8c:	963a                	add	a2,a2,a4
    return KADDR(page2pa(page));
ffffffffc0204c8e:	00c61713          	slli	a4,a2,0xc
ffffffffc0204c92:	8331                	srli	a4,a4,0xc
ffffffffc0204c94:	000ae697          	auipc	a3,0xae
ffffffffc0204c98:	da46b683          	ld	a3,-604(a3) # ffffffffc02b2a38 <npage>
ffffffffc0204c9c:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204ca0:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc0204ca2:	02d77963          	bgeu	a4,a3,ffffffffc0204cd4 <swapfs_write+0x74>
}
ffffffffc0204ca6:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204ca8:	000ae797          	auipc	a5,0xae
ffffffffc0204cac:	da87b783          	ld	a5,-600(a5) # ffffffffc02b2a50 <va_pa_offset>
ffffffffc0204cb0:	46a1                	li	a3,8
ffffffffc0204cb2:	963e                	add	a2,a2,a5
ffffffffc0204cb4:	4505                	li	a0,1
}
ffffffffc0204cb6:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204cb8:	965fb06f          	j	ffffffffc020061c <ide_write_secs>
ffffffffc0204cbc:	86aa                	mv	a3,a0
ffffffffc0204cbe:	00003617          	auipc	a2,0x3
ffffffffc0204cc2:	74260613          	addi	a2,a2,1858 # ffffffffc0208400 <default_pmm_manager+0x1048>
ffffffffc0204cc6:	45e5                	li	a1,25
ffffffffc0204cc8:	00003517          	auipc	a0,0x3
ffffffffc0204ccc:	72050513          	addi	a0,a0,1824 # ffffffffc02083e8 <default_pmm_manager+0x1030>
ffffffffc0204cd0:	faafb0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc0204cd4:	86b2                	mv	a3,a2
ffffffffc0204cd6:	06900593          	li	a1,105
ffffffffc0204cda:	00002617          	auipc	a2,0x2
ffffffffc0204cde:	71660613          	addi	a2,a2,1814 # ffffffffc02073f0 <default_pmm_manager+0x38>
ffffffffc0204ce2:	00002517          	auipc	a0,0x2
ffffffffc0204ce6:	73650513          	addi	a0,a0,1846 # ffffffffc0207418 <default_pmm_manager+0x60>
ffffffffc0204cea:	f90fb0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0204cee <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0204cee:	8526                	mv	a0,s1
	jalr s0
ffffffffc0204cf0:	9402                	jalr	s0

	jal do_exit
ffffffffc0204cf2:	64a000ef          	jal	ra,ffffffffc020533c <do_exit>

ffffffffc0204cf6 <alloc_proc>:
void forkrets(struct trapframe *tf);
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void) {
ffffffffc0204cf6:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204cf8:	10800513          	li	a0,264
alloc_proc(void) {
ffffffffc0204cfc:	e022                	sd	s0,0(sp)
ffffffffc0204cfe:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204d00:	e31fc0ef          	jal	ra,ffffffffc0201b30 <kmalloc>
ffffffffc0204d04:	842a                	mv	s0,a0
    if (proc != NULL) {
ffffffffc0204d06:	cd21                	beqz	a0,ffffffffc0204d5e <alloc_proc+0x68>
     /*
     * below fields(add in LAB5) in proc_struct need to be initialized  
     *       uint32_t wait_state;                        // waiting state
     *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
     */
    proc->state = PROC_UNINIT;
ffffffffc0204d08:	57fd                	li	a5,-1
ffffffffc0204d0a:	1782                	slli	a5,a5,0x20
ffffffffc0204d0c:	e11c                	sd	a5,0(a0)
    proc->runs = 0;
    proc->kstack = 0;
    proc->need_resched = 0;
    proc->parent = NULL;
    proc->mm = NULL;
    memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0204d0e:	07000613          	li	a2,112
ffffffffc0204d12:	4581                	li	a1,0
    proc->runs = 0;
ffffffffc0204d14:	00052423          	sw	zero,8(a0)
    proc->kstack = 0;
ffffffffc0204d18:	00053823          	sd	zero,16(a0)
    proc->need_resched = 0;
ffffffffc0204d1c:	00053c23          	sd	zero,24(a0)
    proc->parent = NULL;
ffffffffc0204d20:	02053023          	sd	zero,32(a0)
    proc->mm = NULL;
ffffffffc0204d24:	02053423          	sd	zero,40(a0)
    memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0204d28:	03050513          	addi	a0,a0,48
ffffffffc0204d2c:	0af010ef          	jal	ra,ffffffffc02065da <memset>
    proc->tf = NULL;
    proc->cr3 = boot_cr3;
ffffffffc0204d30:	000ae797          	auipc	a5,0xae
ffffffffc0204d34:	cf87b783          	ld	a5,-776(a5) # ffffffffc02b2a28 <boot_cr3>
    proc->tf = NULL;
ffffffffc0204d38:	0a043023          	sd	zero,160(s0)
    proc->cr3 = boot_cr3;
ffffffffc0204d3c:	f45c                	sd	a5,168(s0)
    proc->flags = 0;
ffffffffc0204d3e:	0a042823          	sw	zero,176(s0)
    memset(proc->name, 0, PROC_NAME_LEN);
ffffffffc0204d42:	463d                	li	a2,15
ffffffffc0204d44:	4581                	li	a1,0
ffffffffc0204d46:	0b440513          	addi	a0,s0,180
ffffffffc0204d4a:	091010ef          	jal	ra,ffffffffc02065da <memset>
    proc->wait_state = 0;
ffffffffc0204d4e:	0e042623          	sw	zero,236(s0)
    proc->cptr = proc->yptr = proc->optr = NULL;
ffffffffc0204d52:	10043023          	sd	zero,256(s0)
ffffffffc0204d56:	0e043c23          	sd	zero,248(s0)
ffffffffc0204d5a:	0e043823          	sd	zero,240(s0)
    
    }
    return proc;
}
ffffffffc0204d5e:	60a2                	ld	ra,8(sp)
ffffffffc0204d60:	8522                	mv	a0,s0
ffffffffc0204d62:	6402                	ld	s0,0(sp)
ffffffffc0204d64:	0141                	addi	sp,sp,16
ffffffffc0204d66:	8082                	ret

ffffffffc0204d68 <forkret>:
// forkret -- the first kernel entry point of a new thread/process
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void) {
    forkrets(current->tf);
ffffffffc0204d68:	000ae797          	auipc	a5,0xae
ffffffffc0204d6c:	d187b783          	ld	a5,-744(a5) # ffffffffc02b2a80 <current>
ffffffffc0204d70:	73c8                	ld	a0,160(a5)
ffffffffc0204d72:	83cfc06f          	j	ffffffffc0200dae <forkrets>

ffffffffc0204d76 <user_main>:

// user_main - kernel thread used to exec a user program
static int
user_main(void *arg) {
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204d76:	000ae797          	auipc	a5,0xae
ffffffffc0204d7a:	d0a7b783          	ld	a5,-758(a5) # ffffffffc02b2a80 <current>
ffffffffc0204d7e:	43cc                	lw	a1,4(a5)
user_main(void *arg) {
ffffffffc0204d80:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204d82:	00003617          	auipc	a2,0x3
ffffffffc0204d86:	69e60613          	addi	a2,a2,1694 # ffffffffc0208420 <default_pmm_manager+0x1068>
ffffffffc0204d8a:	00003517          	auipc	a0,0x3
ffffffffc0204d8e:	6a650513          	addi	a0,a0,1702 # ffffffffc0208430 <default_pmm_manager+0x1078>
user_main(void *arg) {
ffffffffc0204d92:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204d94:	becfb0ef          	jal	ra,ffffffffc0200180 <cprintf>
ffffffffc0204d98:	3fe06797          	auipc	a5,0x3fe06
ffffffffc0204d9c:	bf878793          	addi	a5,a5,-1032 # a990 <_binary_obj___user_forktest_out_size>
ffffffffc0204da0:	e43e                	sd	a5,8(sp)
ffffffffc0204da2:	00003517          	auipc	a0,0x3
ffffffffc0204da6:	67e50513          	addi	a0,a0,1662 # ffffffffc0208420 <default_pmm_manager+0x1068>
ffffffffc0204daa:	00046797          	auipc	a5,0x46
ffffffffc0204dae:	a3678793          	addi	a5,a5,-1482 # ffffffffc024a7e0 <_binary_obj___user_forktest_out_start>
ffffffffc0204db2:	f03e                	sd	a5,32(sp)
ffffffffc0204db4:	f42a                	sd	a0,40(sp)
    int64_t ret=0, len = strlen(name);
ffffffffc0204db6:	e802                	sd	zero,16(sp)
ffffffffc0204db8:	7a6010ef          	jal	ra,ffffffffc020655e <strlen>
ffffffffc0204dbc:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0204dbe:	4511                	li	a0,4
ffffffffc0204dc0:	55a2                	lw	a1,40(sp)
ffffffffc0204dc2:	4662                	lw	a2,24(sp)
ffffffffc0204dc4:	5682                	lw	a3,32(sp)
ffffffffc0204dc6:	4722                	lw	a4,8(sp)
ffffffffc0204dc8:	48a9                	li	a7,10
ffffffffc0204dca:	9002                	ebreak
ffffffffc0204dcc:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0204dce:	65c2                	ld	a1,16(sp)
ffffffffc0204dd0:	00003517          	auipc	a0,0x3
ffffffffc0204dd4:	68850513          	addi	a0,a0,1672 # ffffffffc0208458 <default_pmm_manager+0x10a0>
ffffffffc0204dd8:	ba8fb0ef          	jal	ra,ffffffffc0200180 <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc0204ddc:	00003617          	auipc	a2,0x3
ffffffffc0204de0:	68c60613          	addi	a2,a2,1676 # ffffffffc0208468 <default_pmm_manager+0x10b0>
ffffffffc0204de4:	34c00593          	li	a1,844
ffffffffc0204de8:	00003517          	auipc	a0,0x3
ffffffffc0204dec:	6a050513          	addi	a0,a0,1696 # ffffffffc0208488 <default_pmm_manager+0x10d0>
ffffffffc0204df0:	e8afb0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0204df4 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0204df4:	6d14                	ld	a3,24(a0)
put_pgdir(struct mm_struct *mm) {
ffffffffc0204df6:	1141                	addi	sp,sp,-16
ffffffffc0204df8:	e406                	sd	ra,8(sp)
ffffffffc0204dfa:	c02007b7          	lui	a5,0xc0200
ffffffffc0204dfe:	02f6ee63          	bltu	a3,a5,ffffffffc0204e3a <put_pgdir+0x46>
ffffffffc0204e02:	000ae517          	auipc	a0,0xae
ffffffffc0204e06:	c4e53503          	ld	a0,-946(a0) # ffffffffc02b2a50 <va_pa_offset>
ffffffffc0204e0a:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage) {
ffffffffc0204e0c:	82b1                	srli	a3,a3,0xc
ffffffffc0204e0e:	000ae797          	auipc	a5,0xae
ffffffffc0204e12:	c2a7b783          	ld	a5,-982(a5) # ffffffffc02b2a38 <npage>
ffffffffc0204e16:	02f6fe63          	bgeu	a3,a5,ffffffffc0204e52 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0204e1a:	00004517          	auipc	a0,0x4
ffffffffc0204e1e:	f2653503          	ld	a0,-218(a0) # ffffffffc0208d40 <nbase>
}
ffffffffc0204e22:	60a2                	ld	ra,8(sp)
ffffffffc0204e24:	8e89                	sub	a3,a3,a0
ffffffffc0204e26:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0204e28:	000ae517          	auipc	a0,0xae
ffffffffc0204e2c:	c1853503          	ld	a0,-1000(a0) # ffffffffc02b2a40 <pages>
ffffffffc0204e30:	4585                	li	a1,1
ffffffffc0204e32:	9536                	add	a0,a0,a3
}
ffffffffc0204e34:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0204e36:	f6bfc06f          	j	ffffffffc0201da0 <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0204e3a:	00002617          	auipc	a2,0x2
ffffffffc0204e3e:	65e60613          	addi	a2,a2,1630 # ffffffffc0207498 <default_pmm_manager+0xe0>
ffffffffc0204e42:	06e00593          	li	a1,110
ffffffffc0204e46:	00002517          	auipc	a0,0x2
ffffffffc0204e4a:	5d250513          	addi	a0,a0,1490 # ffffffffc0207418 <default_pmm_manager+0x60>
ffffffffc0204e4e:	e2cfb0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204e52:	00002617          	auipc	a2,0x2
ffffffffc0204e56:	66e60613          	addi	a2,a2,1646 # ffffffffc02074c0 <default_pmm_manager+0x108>
ffffffffc0204e5a:	06200593          	li	a1,98
ffffffffc0204e5e:	00002517          	auipc	a0,0x2
ffffffffc0204e62:	5ba50513          	addi	a0,a0,1466 # ffffffffc0207418 <default_pmm_manager+0x60>
ffffffffc0204e66:	e14fb0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0204e6a <proc_run>:
proc_run(struct proc_struct *proc) {
ffffffffc0204e6a:	7179                	addi	sp,sp,-48
ffffffffc0204e6c:	ec4a                	sd	s2,24(sp)
    if (proc != current) {
ffffffffc0204e6e:	000ae917          	auipc	s2,0xae
ffffffffc0204e72:	c1290913          	addi	s2,s2,-1006 # ffffffffc02b2a80 <current>
proc_run(struct proc_struct *proc) {
ffffffffc0204e76:	f026                	sd	s1,32(sp)
    if (proc != current) {
ffffffffc0204e78:	00093483          	ld	s1,0(s2)
proc_run(struct proc_struct *proc) {
ffffffffc0204e7c:	f406                	sd	ra,40(sp)
ffffffffc0204e7e:	e84e                	sd	s3,16(sp)
    if (proc != current) {
ffffffffc0204e80:	02a48863          	beq	s1,a0,ffffffffc0204eb0 <proc_run+0x46>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204e84:	100027f3          	csrr	a5,sstatus
ffffffffc0204e88:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204e8a:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204e8c:	ef9d                	bnez	a5,ffffffffc0204eca <proc_run+0x60>

#define barrier() __asm__ __volatile__ ("fence" ::: "memory")

static inline void
lcr3(unsigned long cr3) {
    write_csr(satp, 0x8000000000000000 | (cr3 >> RISCV_PGSHIFT));
ffffffffc0204e8e:	755c                	ld	a5,168(a0)
ffffffffc0204e90:	577d                	li	a4,-1
ffffffffc0204e92:	177e                	slli	a4,a4,0x3f
ffffffffc0204e94:	83b1                	srli	a5,a5,0xc
            current = proc;
ffffffffc0204e96:	00a93023          	sd	a0,0(s2)
ffffffffc0204e9a:	8fd9                	or	a5,a5,a4
ffffffffc0204e9c:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(next->context));
ffffffffc0204ea0:	03050593          	addi	a1,a0,48
ffffffffc0204ea4:	03048513          	addi	a0,s1,48
ffffffffc0204ea8:	05c010ef          	jal	ra,ffffffffc0205f04 <switch_to>
    if (flag) {
ffffffffc0204eac:	00099863          	bnez	s3,ffffffffc0204ebc <proc_run+0x52>
}
ffffffffc0204eb0:	70a2                	ld	ra,40(sp)
ffffffffc0204eb2:	7482                	ld	s1,32(sp)
ffffffffc0204eb4:	6962                	ld	s2,24(sp)
ffffffffc0204eb6:	69c2                	ld	s3,16(sp)
ffffffffc0204eb8:	6145                	addi	sp,sp,48
ffffffffc0204eba:	8082                	ret
ffffffffc0204ebc:	70a2                	ld	ra,40(sp)
ffffffffc0204ebe:	7482                	ld	s1,32(sp)
ffffffffc0204ec0:	6962                	ld	s2,24(sp)
ffffffffc0204ec2:	69c2                	ld	s3,16(sp)
ffffffffc0204ec4:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0204ec6:	f7afb06f          	j	ffffffffc0200640 <intr_enable>
ffffffffc0204eca:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0204ecc:	f7afb0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        return 1;
ffffffffc0204ed0:	6522                	ld	a0,8(sp)
ffffffffc0204ed2:	4985                	li	s3,1
ffffffffc0204ed4:	bf6d                	j	ffffffffc0204e8e <proc_run+0x24>

ffffffffc0204ed6 <do_fork>:
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc0204ed6:	7159                	addi	sp,sp,-112
ffffffffc0204ed8:	e8ca                	sd	s2,80(sp)
    if (nr_process >= MAX_PROCESS) {
ffffffffc0204eda:	000ae917          	auipc	s2,0xae
ffffffffc0204ede:	bbe90913          	addi	s2,s2,-1090 # ffffffffc02b2a98 <nr_process>
ffffffffc0204ee2:	00092703          	lw	a4,0(s2)
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc0204ee6:	f486                	sd	ra,104(sp)
ffffffffc0204ee8:	f0a2                	sd	s0,96(sp)
ffffffffc0204eea:	eca6                	sd	s1,88(sp)
ffffffffc0204eec:	e4ce                	sd	s3,72(sp)
ffffffffc0204eee:	e0d2                	sd	s4,64(sp)
ffffffffc0204ef0:	fc56                	sd	s5,56(sp)
ffffffffc0204ef2:	f85a                	sd	s6,48(sp)
ffffffffc0204ef4:	f45e                	sd	s7,40(sp)
ffffffffc0204ef6:	f062                	sd	s8,32(sp)
ffffffffc0204ef8:	ec66                	sd	s9,24(sp)
ffffffffc0204efa:	e86a                	sd	s10,16(sp)
ffffffffc0204efc:	e46e                	sd	s11,8(sp)
    if (nr_process >= MAX_PROCESS) {
ffffffffc0204efe:	6785                	lui	a5,0x1
ffffffffc0204f00:	34f75463          	bge	a4,a5,ffffffffc0205248 <do_fork+0x372>
ffffffffc0204f04:	8a2a                	mv	s4,a0
ffffffffc0204f06:	89ae                	mv	s3,a1
ffffffffc0204f08:	8432                	mv	s0,a2
    proc = alloc_proc();
ffffffffc0204f0a:	dedff0ef          	jal	ra,ffffffffc0204cf6 <alloc_proc>
ffffffffc0204f0e:	84aa                	mv	s1,a0
    if(proc==NULL){
ffffffffc0204f10:	2c050c63          	beqz	a0,ffffffffc02051e8 <do_fork+0x312>
    proc->parent = current;
ffffffffc0204f14:	000aea97          	auipc	s5,0xae
ffffffffc0204f18:	b6ca8a93          	addi	s5,s5,-1172 # ffffffffc02b2a80 <current>
ffffffffc0204f1c:	000ab783          	ld	a5,0(s5)
    assert(current->wait_state == 0);
ffffffffc0204f20:	0ec7a703          	lw	a4,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8ae4>
    proc->parent = current;
ffffffffc0204f24:	f11c                	sd	a5,32(a0)
    assert(current->wait_state == 0);
ffffffffc0204f26:	38071763          	bnez	a4,ffffffffc02052b4 <do_fork+0x3de>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204f2a:	4509                	li	a0,2
ffffffffc0204f2c:	de3fc0ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
    if (page != NULL) {
ffffffffc0204f30:	2c050b63          	beqz	a0,ffffffffc0205206 <do_fork+0x330>
    return page - pages + nbase;
ffffffffc0204f34:	000aed97          	auipc	s11,0xae
ffffffffc0204f38:	b0cd8d93          	addi	s11,s11,-1268 # ffffffffc02b2a40 <pages>
ffffffffc0204f3c:	000db683          	ld	a3,0(s11)
    return KADDR(page2pa(page));
ffffffffc0204f40:	000aed17          	auipc	s10,0xae
ffffffffc0204f44:	af8d0d13          	addi	s10,s10,-1288 # ffffffffc02b2a38 <npage>
    return page - pages + nbase;
ffffffffc0204f48:	00004c97          	auipc	s9,0x4
ffffffffc0204f4c:	df8cbc83          	ld	s9,-520(s9) # ffffffffc0208d40 <nbase>
ffffffffc0204f50:	40d506b3          	sub	a3,a0,a3
ffffffffc0204f54:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204f56:	5c7d                	li	s8,-1
ffffffffc0204f58:	000d3783          	ld	a5,0(s10)
    return page - pages + nbase;
ffffffffc0204f5c:	96e6                	add	a3,a3,s9
    return KADDR(page2pa(page));
ffffffffc0204f5e:	00cc5c13          	srli	s8,s8,0xc
ffffffffc0204f62:	0186f733          	and	a4,a3,s8
    return page2ppn(page) << PGSHIFT;
ffffffffc0204f66:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204f68:	30f77d63          	bgeu	a4,a5,ffffffffc0205282 <do_fork+0x3ac>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0204f6c:	000ab703          	ld	a4,0(s5)
ffffffffc0204f70:	000aea97          	auipc	s5,0xae
ffffffffc0204f74:	ae0a8a93          	addi	s5,s5,-1312 # ffffffffc02b2a50 <va_pa_offset>
ffffffffc0204f78:	000ab783          	ld	a5,0(s5)
ffffffffc0204f7c:	02873b83          	ld	s7,40(a4)
ffffffffc0204f80:	96be                	add	a3,a3,a5
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0204f82:	e894                	sd	a3,16(s1)
    if (oldmm == NULL) {
ffffffffc0204f84:	020b8863          	beqz	s7,ffffffffc0204fb4 <do_fork+0xde>
    if (clone_flags & CLONE_VM) {
ffffffffc0204f88:	100a7a13          	andi	s4,s4,256
ffffffffc0204f8c:	1c0a0563          	beqz	s4,ffffffffc0205156 <do_fork+0x280>
}

static inline int
mm_count_inc(struct mm_struct *mm) {
    mm->mm_count += 1;
ffffffffc0204f90:	030ba703          	lw	a4,48(s7)
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc0204f94:	018bb783          	ld	a5,24(s7)
ffffffffc0204f98:	c02006b7          	lui	a3,0xc0200
ffffffffc0204f9c:	2705                	addiw	a4,a4,1
ffffffffc0204f9e:	02eba823          	sw	a4,48(s7)
    proc->mm = mm;
ffffffffc0204fa2:	0374b423          	sd	s7,40(s1)
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc0204fa6:	2ed7ea63          	bltu	a5,a3,ffffffffc020529a <do_fork+0x3c4>
ffffffffc0204faa:	000ab703          	ld	a4,0(s5)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204fae:	6894                	ld	a3,16(s1)
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc0204fb0:	8f99                	sub	a5,a5,a4
ffffffffc0204fb2:	f4dc                	sd	a5,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204fb4:	6709                	lui	a4,0x2
ffffffffc0204fb6:	ee070713          	addi	a4,a4,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cf0>
ffffffffc0204fba:	9736                	add	a4,a4,a3
    *(proc->tf) = *tf;
ffffffffc0204fbc:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204fbe:	f0d8                	sd	a4,160(s1)
    *(proc->tf) = *tf;
ffffffffc0204fc0:	87ba                	mv	a5,a4
ffffffffc0204fc2:	12040313          	addi	t1,s0,288
ffffffffc0204fc6:	00063883          	ld	a7,0(a2)
ffffffffc0204fca:	00863803          	ld	a6,8(a2)
ffffffffc0204fce:	6a08                	ld	a0,16(a2)
ffffffffc0204fd0:	6e0c                	ld	a1,24(a2)
ffffffffc0204fd2:	0117b023          	sd	a7,0(a5)
ffffffffc0204fd6:	0107b423          	sd	a6,8(a5)
ffffffffc0204fda:	eb88                	sd	a0,16(a5)
ffffffffc0204fdc:	ef8c                	sd	a1,24(a5)
ffffffffc0204fde:	02060613          	addi	a2,a2,32
ffffffffc0204fe2:	02078793          	addi	a5,a5,32
ffffffffc0204fe6:	fe6610e3          	bne	a2,t1,ffffffffc0204fc6 <do_fork+0xf0>
    proc->tf->gpr.a0 = 0;
ffffffffc0204fea:	04073823          	sd	zero,80(a4)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf - 4 : esp;
ffffffffc0204fee:	12098e63          	beqz	s3,ffffffffc020512a <do_fork+0x254>
ffffffffc0204ff2:	01373823          	sd	s3,16(a4)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204ff6:	00000797          	auipc	a5,0x0
ffffffffc0204ffa:	d7278793          	addi	a5,a5,-654 # ffffffffc0204d68 <forkret>
ffffffffc0204ffe:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0205000:	fc98                	sd	a4,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205002:	100027f3          	csrr	a5,sstatus
ffffffffc0205006:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205008:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020500a:	14079263          	bnez	a5,ffffffffc020514e <do_fork+0x278>
    if (++ last_pid >= MAX_PID) {
ffffffffc020500e:	000a2817          	auipc	a6,0xa2
ffffffffc0205012:	52a80813          	addi	a6,a6,1322 # ffffffffc02a7538 <last_pid.1>
ffffffffc0205016:	00082783          	lw	a5,0(a6)
ffffffffc020501a:	6709                	lui	a4,0x2
ffffffffc020501c:	0017851b          	addiw	a0,a5,1
ffffffffc0205020:	00a82023          	sw	a0,0(a6)
ffffffffc0205024:	08e55c63          	bge	a0,a4,ffffffffc02050bc <do_fork+0x1e6>
    if (last_pid >= next_safe) {
ffffffffc0205028:	000a2317          	auipc	t1,0xa2
ffffffffc020502c:	51430313          	addi	t1,t1,1300 # ffffffffc02a753c <next_safe.0>
ffffffffc0205030:	00032783          	lw	a5,0(t1)
ffffffffc0205034:	000ae417          	auipc	s0,0xae
ffffffffc0205038:	9c440413          	addi	s0,s0,-1596 # ffffffffc02b29f8 <proc_list>
ffffffffc020503c:	08f55863          	bge	a0,a5,ffffffffc02050cc <do_fork+0x1f6>
        proc->pid = get_pid();
ffffffffc0205040:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0205042:	45a9                	li	a1,10
ffffffffc0205044:	2501                	sext.w	a0,a0
ffffffffc0205046:	114010ef          	jal	ra,ffffffffc020615a <hash32>
ffffffffc020504a:	02051793          	slli	a5,a0,0x20
ffffffffc020504e:	000aa717          	auipc	a4,0xaa
ffffffffc0205052:	9aa70713          	addi	a4,a4,-1622 # ffffffffc02ae9f8 <hash_list>
ffffffffc0205056:	83f1                	srli	a5,a5,0x1c
ffffffffc0205058:	97ba                	add	a5,a5,a4
    __list_add(elm, listelm, listelm->next);
ffffffffc020505a:	6788                	ld	a0,8(a5)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc020505c:	7090                	ld	a2,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc020505e:	0d848713          	addi	a4,s1,216
    prev->next = next->prev = elm;
ffffffffc0205062:	e118                	sd	a4,0(a0)
    __list_add(elm, listelm, listelm->next);
ffffffffc0205064:	640c                	ld	a1,8(s0)
    prev->next = next->prev = elm;
ffffffffc0205066:	e798                	sd	a4,8(a5)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc0205068:	7a74                	ld	a3,240(a2)
    list_add(&proc_list, &(proc->list_link));
ffffffffc020506a:	0c848713          	addi	a4,s1,200
    elm->next = next;
ffffffffc020506e:	f0e8                	sd	a0,224(s1)
    elm->prev = prev;
ffffffffc0205070:	ecfc                	sd	a5,216(s1)
    prev->next = next->prev = elm;
ffffffffc0205072:	e198                	sd	a4,0(a1)
ffffffffc0205074:	e418                	sd	a4,8(s0)
    elm->next = next;
ffffffffc0205076:	e8ec                	sd	a1,208(s1)
    elm->prev = prev;
ffffffffc0205078:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc020507a:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc020507e:	10d4b023          	sd	a3,256(s1)
ffffffffc0205082:	c291                	beqz	a3,ffffffffc0205086 <do_fork+0x1b0>
        proc->optr->yptr = proc;
ffffffffc0205084:	fee4                	sd	s1,248(a3)
    nr_process ++;
ffffffffc0205086:	00092783          	lw	a5,0(s2)
    proc->parent->cptr = proc;
ffffffffc020508a:	fa64                	sd	s1,240(a2)
    nr_process ++;
ffffffffc020508c:	2785                	addiw	a5,a5,1
ffffffffc020508e:	00f92023          	sw	a5,0(s2)
    if (flag) {
ffffffffc0205092:	14099d63          	bnez	s3,ffffffffc02051ec <do_fork+0x316>
    wakeup_proc(proc);
ffffffffc0205096:	8526                	mv	a0,s1
ffffffffc0205098:	6d7000ef          	jal	ra,ffffffffc0205f6e <wakeup_proc>
    ret = proc->pid;
ffffffffc020509c:	40c8                	lw	a0,4(s1)
}
ffffffffc020509e:	70a6                	ld	ra,104(sp)
ffffffffc02050a0:	7406                	ld	s0,96(sp)
ffffffffc02050a2:	64e6                	ld	s1,88(sp)
ffffffffc02050a4:	6946                	ld	s2,80(sp)
ffffffffc02050a6:	69a6                	ld	s3,72(sp)
ffffffffc02050a8:	6a06                	ld	s4,64(sp)
ffffffffc02050aa:	7ae2                	ld	s5,56(sp)
ffffffffc02050ac:	7b42                	ld	s6,48(sp)
ffffffffc02050ae:	7ba2                	ld	s7,40(sp)
ffffffffc02050b0:	7c02                	ld	s8,32(sp)
ffffffffc02050b2:	6ce2                	ld	s9,24(sp)
ffffffffc02050b4:	6d42                	ld	s10,16(sp)
ffffffffc02050b6:	6da2                	ld	s11,8(sp)
ffffffffc02050b8:	6165                	addi	sp,sp,112
ffffffffc02050ba:	8082                	ret
        last_pid = 1;
ffffffffc02050bc:	4785                	li	a5,1
ffffffffc02050be:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc02050c2:	4505                	li	a0,1
ffffffffc02050c4:	000a2317          	auipc	t1,0xa2
ffffffffc02050c8:	47830313          	addi	t1,t1,1144 # ffffffffc02a753c <next_safe.0>
    return listelm->next;
ffffffffc02050cc:	000ae417          	auipc	s0,0xae
ffffffffc02050d0:	92c40413          	addi	s0,s0,-1748 # ffffffffc02b29f8 <proc_list>
ffffffffc02050d4:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc02050d8:	6789                	lui	a5,0x2
ffffffffc02050da:	00f32023          	sw	a5,0(t1)
ffffffffc02050de:	86aa                	mv	a3,a0
ffffffffc02050e0:	4581                	li	a1,0
        while ((le = list_next(le)) != list) {
ffffffffc02050e2:	6e89                	lui	t4,0x2
ffffffffc02050e4:	108e0c63          	beq	t3,s0,ffffffffc02051fc <do_fork+0x326>
ffffffffc02050e8:	88ae                	mv	a7,a1
ffffffffc02050ea:	87f2                	mv	a5,t3
ffffffffc02050ec:	6609                	lui	a2,0x2
ffffffffc02050ee:	a811                	j	ffffffffc0205102 <do_fork+0x22c>
            else if (proc->pid > last_pid && next_safe > proc->pid) {
ffffffffc02050f0:	00e6d663          	bge	a3,a4,ffffffffc02050fc <do_fork+0x226>
ffffffffc02050f4:	00c75463          	bge	a4,a2,ffffffffc02050fc <do_fork+0x226>
ffffffffc02050f8:	863a                	mv	a2,a4
ffffffffc02050fa:	4885                	li	a7,1
ffffffffc02050fc:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc02050fe:	00878d63          	beq	a5,s0,ffffffffc0205118 <do_fork+0x242>
            if (proc->pid == last_pid) {
ffffffffc0205102:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7c94>
ffffffffc0205106:	fed715e3          	bne	a4,a3,ffffffffc02050f0 <do_fork+0x21a>
                if (++ last_pid >= next_safe) {
ffffffffc020510a:	2685                	addiw	a3,a3,1
ffffffffc020510c:	0ec6d363          	bge	a3,a2,ffffffffc02051f2 <do_fork+0x31c>
ffffffffc0205110:	679c                	ld	a5,8(a5)
ffffffffc0205112:	4585                	li	a1,1
        while ((le = list_next(le)) != list) {
ffffffffc0205114:	fe8797e3          	bne	a5,s0,ffffffffc0205102 <do_fork+0x22c>
ffffffffc0205118:	c581                	beqz	a1,ffffffffc0205120 <do_fork+0x24a>
ffffffffc020511a:	00d82023          	sw	a3,0(a6)
ffffffffc020511e:	8536                	mv	a0,a3
ffffffffc0205120:	f20880e3          	beqz	a7,ffffffffc0205040 <do_fork+0x16a>
ffffffffc0205124:	00c32023          	sw	a2,0(t1)
ffffffffc0205128:	bf21                	j	ffffffffc0205040 <do_fork+0x16a>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf - 4 : esp;
ffffffffc020512a:	6989                	lui	s3,0x2
ffffffffc020512c:	edc98993          	addi	s3,s3,-292 # 1edc <_binary_obj___user_faultread_out_size-0x7cf4>
ffffffffc0205130:	99b6                	add	s3,s3,a3
ffffffffc0205132:	01373823          	sd	s3,16(a4)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0205136:	00000797          	auipc	a5,0x0
ffffffffc020513a:	c3278793          	addi	a5,a5,-974 # ffffffffc0204d68 <forkret>
ffffffffc020513e:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0205140:	fc98                	sd	a4,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205142:	100027f3          	csrr	a5,sstatus
ffffffffc0205146:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205148:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020514a:	ec0782e3          	beqz	a5,ffffffffc020500e <do_fork+0x138>
        intr_disable();
ffffffffc020514e:	cf8fb0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        return 1;
ffffffffc0205152:	4985                	li	s3,1
ffffffffc0205154:	bd6d                	j	ffffffffc020500e <do_fork+0x138>
    if ((mm = mm_create()) == NULL) {
ffffffffc0205156:	ff9fe0ef          	jal	ra,ffffffffc020414e <mm_create>
ffffffffc020515a:	8b2a                	mv	s6,a0
ffffffffc020515c:	c159                	beqz	a0,ffffffffc02051e2 <do_fork+0x30c>
    if ((page = alloc_page()) == NULL) {
ffffffffc020515e:	4505                	li	a0,1
ffffffffc0205160:	baffc0ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc0205164:	cd25                	beqz	a0,ffffffffc02051dc <do_fork+0x306>
    return page - pages + nbase;
ffffffffc0205166:	000db683          	ld	a3,0(s11)
    return KADDR(page2pa(page));
ffffffffc020516a:	000d3783          	ld	a5,0(s10)
    return page - pages + nbase;
ffffffffc020516e:	40d506b3          	sub	a3,a0,a3
ffffffffc0205172:	8699                	srai	a3,a3,0x6
ffffffffc0205174:	96e6                	add	a3,a3,s9
    return KADDR(page2pa(page));
ffffffffc0205176:	0186fc33          	and	s8,a3,s8
    return page2ppn(page) << PGSHIFT;
ffffffffc020517a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020517c:	10fc7363          	bgeu	s8,a5,ffffffffc0205282 <do_fork+0x3ac>
ffffffffc0205180:	000aba03          	ld	s4,0(s5)
    memcpy(pgdir, boot_pgdir, PGSIZE);
ffffffffc0205184:	6605                	lui	a2,0x1
ffffffffc0205186:	000ae597          	auipc	a1,0xae
ffffffffc020518a:	8aa5b583          	ld	a1,-1878(a1) # ffffffffc02b2a30 <boot_pgdir>
ffffffffc020518e:	9a36                	add	s4,s4,a3
ffffffffc0205190:	8552                	mv	a0,s4
ffffffffc0205192:	45a010ef          	jal	ra,ffffffffc02065ec <memcpy>
}

static inline void
lock_mm(struct mm_struct *mm) {
    if (mm != NULL) {
        lock(&(mm->mm_lock));
ffffffffc0205196:	038b8c13          	addi	s8,s7,56
    mm->pgdir = pgdir;
ffffffffc020519a:	014b3c23          	sd	s4,24(s6)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020519e:	4785                	li	a5,1
ffffffffc02051a0:	40fc37af          	amoor.d	a5,a5,(s8)
    return !test_and_set_bit(0, lock);
}

static inline void
lock(lock_t *lock) {
    while (!try_lock(lock)) {
ffffffffc02051a4:	8b85                	andi	a5,a5,1
ffffffffc02051a6:	4a05                	li	s4,1
ffffffffc02051a8:	c799                	beqz	a5,ffffffffc02051b6 <do_fork+0x2e0>
        schedule();
ffffffffc02051aa:	645000ef          	jal	ra,ffffffffc0205fee <schedule>
ffffffffc02051ae:	414c37af          	amoor.d	a5,s4,(s8)
    while (!try_lock(lock)) {
ffffffffc02051b2:	8b85                	andi	a5,a5,1
ffffffffc02051b4:	fbfd                	bnez	a5,ffffffffc02051aa <do_fork+0x2d4>
        ret = dup_mmap(mm, oldmm);
ffffffffc02051b6:	85de                	mv	a1,s7
ffffffffc02051b8:	855a                	mv	a0,s6
ffffffffc02051ba:	a1cff0ef          	jal	ra,ffffffffc02043d6 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02051be:	57f9                	li	a5,-2
ffffffffc02051c0:	60fc37af          	amoand.d	a5,a5,(s8)
ffffffffc02051c4:	8b85                	andi	a5,a5,1
    }
}

static inline void
unlock(lock_t *lock) {
    if (!test_and_clear_bit(0, lock)) {
ffffffffc02051c6:	10078763          	beqz	a5,ffffffffc02052d4 <do_fork+0x3fe>
good_mm:
ffffffffc02051ca:	8bda                	mv	s7,s6
    if (ret != 0) {
ffffffffc02051cc:	dc0502e3          	beqz	a0,ffffffffc0204f90 <do_fork+0xba>
    exit_mmap(mm);
ffffffffc02051d0:	855a                	mv	a0,s6
ffffffffc02051d2:	a9eff0ef          	jal	ra,ffffffffc0204470 <exit_mmap>
    put_pgdir(mm);
ffffffffc02051d6:	855a                	mv	a0,s6
ffffffffc02051d8:	c1dff0ef          	jal	ra,ffffffffc0204df4 <put_pgdir>
    mm_destroy(mm);
ffffffffc02051dc:	855a                	mv	a0,s6
ffffffffc02051de:	8f6ff0ef          	jal	ra,ffffffffc02042d4 <mm_destroy>
    kfree(proc);
ffffffffc02051e2:	8526                	mv	a0,s1
ffffffffc02051e4:	9fdfc0ef          	jal	ra,ffffffffc0201be0 <kfree>
    ret = -E_NO_MEM;
ffffffffc02051e8:	5571                	li	a0,-4
    return ret;
ffffffffc02051ea:	bd55                	j	ffffffffc020509e <do_fork+0x1c8>
        intr_enable();
ffffffffc02051ec:	c54fb0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc02051f0:	b55d                	j	ffffffffc0205096 <do_fork+0x1c0>
                    if (last_pid >= MAX_PID) {
ffffffffc02051f2:	01d6c363          	blt	a3,t4,ffffffffc02051f8 <do_fork+0x322>
                        last_pid = 1;
ffffffffc02051f6:	4685                	li	a3,1
                    goto repeat;
ffffffffc02051f8:	4585                	li	a1,1
ffffffffc02051fa:	b5ed                	j	ffffffffc02050e4 <do_fork+0x20e>
ffffffffc02051fc:	c9a1                	beqz	a1,ffffffffc020524c <do_fork+0x376>
ffffffffc02051fe:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc0205202:	8536                	mv	a0,a3
ffffffffc0205204:	bd35                	j	ffffffffc0205040 <do_fork+0x16a>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0205206:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc0205208:	c02007b7          	lui	a5,0xc0200
ffffffffc020520c:	04f6ef63          	bltu	a3,a5,ffffffffc020526a <do_fork+0x394>
ffffffffc0205210:	000ae797          	auipc	a5,0xae
ffffffffc0205214:	8407b783          	ld	a5,-1984(a5) # ffffffffc02b2a50 <va_pa_offset>
ffffffffc0205218:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage) {
ffffffffc020521c:	83b1                	srli	a5,a5,0xc
ffffffffc020521e:	000ae717          	auipc	a4,0xae
ffffffffc0205222:	81a73703          	ld	a4,-2022(a4) # ffffffffc02b2a38 <npage>
ffffffffc0205226:	02e7f663          	bgeu	a5,a4,ffffffffc0205252 <do_fork+0x37c>
    return &pages[PPN(pa) - nbase];
ffffffffc020522a:	00004717          	auipc	a4,0x4
ffffffffc020522e:	b1673703          	ld	a4,-1258(a4) # ffffffffc0208d40 <nbase>
ffffffffc0205232:	8f99                	sub	a5,a5,a4
ffffffffc0205234:	079a                	slli	a5,a5,0x6
ffffffffc0205236:	000ae517          	auipc	a0,0xae
ffffffffc020523a:	80a53503          	ld	a0,-2038(a0) # ffffffffc02b2a40 <pages>
ffffffffc020523e:	4589                	li	a1,2
ffffffffc0205240:	953e                	add	a0,a0,a5
ffffffffc0205242:	b5ffc0ef          	jal	ra,ffffffffc0201da0 <free_pages>
}
ffffffffc0205246:	bf71                	j	ffffffffc02051e2 <do_fork+0x30c>
    int ret = -E_NO_FREE_PROC;
ffffffffc0205248:	556d                	li	a0,-5
ffffffffc020524a:	bd91                	j	ffffffffc020509e <do_fork+0x1c8>
    return last_pid;
ffffffffc020524c:	00082503          	lw	a0,0(a6)
ffffffffc0205250:	bbc5                	j	ffffffffc0205040 <do_fork+0x16a>
        panic("pa2page called with invalid pa");
ffffffffc0205252:	00002617          	auipc	a2,0x2
ffffffffc0205256:	26e60613          	addi	a2,a2,622 # ffffffffc02074c0 <default_pmm_manager+0x108>
ffffffffc020525a:	06200593          	li	a1,98
ffffffffc020525e:	00002517          	auipc	a0,0x2
ffffffffc0205262:	1ba50513          	addi	a0,a0,442 # ffffffffc0207418 <default_pmm_manager+0x60>
ffffffffc0205266:	a14fb0ef          	jal	ra,ffffffffc020047a <__panic>
    return pa2page(PADDR(kva));
ffffffffc020526a:	00002617          	auipc	a2,0x2
ffffffffc020526e:	22e60613          	addi	a2,a2,558 # ffffffffc0207498 <default_pmm_manager+0xe0>
ffffffffc0205272:	06e00593          	li	a1,110
ffffffffc0205276:	00002517          	auipc	a0,0x2
ffffffffc020527a:	1a250513          	addi	a0,a0,418 # ffffffffc0207418 <default_pmm_manager+0x60>
ffffffffc020527e:	9fcfb0ef          	jal	ra,ffffffffc020047a <__panic>
    return KADDR(page2pa(page));
ffffffffc0205282:	00002617          	auipc	a2,0x2
ffffffffc0205286:	16e60613          	addi	a2,a2,366 # ffffffffc02073f0 <default_pmm_manager+0x38>
ffffffffc020528a:	06900593          	li	a1,105
ffffffffc020528e:	00002517          	auipc	a0,0x2
ffffffffc0205292:	18a50513          	addi	a0,a0,394 # ffffffffc0207418 <default_pmm_manager+0x60>
ffffffffc0205296:	9e4fb0ef          	jal	ra,ffffffffc020047a <__panic>
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc020529a:	86be                	mv	a3,a5
ffffffffc020529c:	00002617          	auipc	a2,0x2
ffffffffc02052a0:	1fc60613          	addi	a2,a2,508 # ffffffffc0207498 <default_pmm_manager+0xe0>
ffffffffc02052a4:	16400593          	li	a1,356
ffffffffc02052a8:	00003517          	auipc	a0,0x3
ffffffffc02052ac:	1e050513          	addi	a0,a0,480 # ffffffffc0208488 <default_pmm_manager+0x10d0>
ffffffffc02052b0:	9cafb0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(current->wait_state == 0);
ffffffffc02052b4:	00003697          	auipc	a3,0x3
ffffffffc02052b8:	1ec68693          	addi	a3,a3,492 # ffffffffc02084a0 <default_pmm_manager+0x10e8>
ffffffffc02052bc:	00002617          	auipc	a2,0x2
ffffffffc02052c0:	a0460613          	addi	a2,a2,-1532 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02052c4:	1a300593          	li	a1,419
ffffffffc02052c8:	00003517          	auipc	a0,0x3
ffffffffc02052cc:	1c050513          	addi	a0,a0,448 # ffffffffc0208488 <default_pmm_manager+0x10d0>
ffffffffc02052d0:	9aafb0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("Unlock failed.\n");
ffffffffc02052d4:	00003617          	auipc	a2,0x3
ffffffffc02052d8:	1ec60613          	addi	a2,a2,492 # ffffffffc02084c0 <default_pmm_manager+0x1108>
ffffffffc02052dc:	03100593          	li	a1,49
ffffffffc02052e0:	00003517          	auipc	a0,0x3
ffffffffc02052e4:	1f050513          	addi	a0,a0,496 # ffffffffc02084d0 <default_pmm_manager+0x1118>
ffffffffc02052e8:	992fb0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02052ec <kernel_thread>:
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc02052ec:	7129                	addi	sp,sp,-320
ffffffffc02052ee:	fa22                	sd	s0,304(sp)
ffffffffc02052f0:	f626                	sd	s1,296(sp)
ffffffffc02052f2:	f24a                	sd	s2,288(sp)
ffffffffc02052f4:	84ae                	mv	s1,a1
ffffffffc02052f6:	892a                	mv	s2,a0
ffffffffc02052f8:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02052fa:	4581                	li	a1,0
ffffffffc02052fc:	12000613          	li	a2,288
ffffffffc0205300:	850a                	mv	a0,sp
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc0205302:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0205304:	2d6010ef          	jal	ra,ffffffffc02065da <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0205308:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc020530a:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc020530c:	100027f3          	csrr	a5,sstatus
ffffffffc0205310:	edd7f793          	andi	a5,a5,-291
ffffffffc0205314:	1207e793          	ori	a5,a5,288
ffffffffc0205318:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020531a:	860a                	mv	a2,sp
ffffffffc020531c:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0205320:	00000797          	auipc	a5,0x0
ffffffffc0205324:	9ce78793          	addi	a5,a5,-1586 # ffffffffc0204cee <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0205328:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020532a:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020532c:	babff0ef          	jal	ra,ffffffffc0204ed6 <do_fork>
}
ffffffffc0205330:	70f2                	ld	ra,312(sp)
ffffffffc0205332:	7452                	ld	s0,304(sp)
ffffffffc0205334:	74b2                	ld	s1,296(sp)
ffffffffc0205336:	7912                	ld	s2,288(sp)
ffffffffc0205338:	6131                	addi	sp,sp,320
ffffffffc020533a:	8082                	ret

ffffffffc020533c <do_exit>:
do_exit(int error_code) {
ffffffffc020533c:	7179                	addi	sp,sp,-48
ffffffffc020533e:	f022                	sd	s0,32(sp)
    if (current == idleproc) {
ffffffffc0205340:	000ad417          	auipc	s0,0xad
ffffffffc0205344:	74040413          	addi	s0,s0,1856 # ffffffffc02b2a80 <current>
ffffffffc0205348:	601c                	ld	a5,0(s0)
do_exit(int error_code) {
ffffffffc020534a:	f406                	sd	ra,40(sp)
ffffffffc020534c:	ec26                	sd	s1,24(sp)
ffffffffc020534e:	e84a                	sd	s2,16(sp)
ffffffffc0205350:	e44e                	sd	s3,8(sp)
ffffffffc0205352:	e052                	sd	s4,0(sp)
    if (current == idleproc) {
ffffffffc0205354:	000ad717          	auipc	a4,0xad
ffffffffc0205358:	73473703          	ld	a4,1844(a4) # ffffffffc02b2a88 <idleproc>
ffffffffc020535c:	0ce78c63          	beq	a5,a4,ffffffffc0205434 <do_exit+0xf8>
    if (current == initproc) {
ffffffffc0205360:	000ad497          	auipc	s1,0xad
ffffffffc0205364:	73048493          	addi	s1,s1,1840 # ffffffffc02b2a90 <initproc>
ffffffffc0205368:	6098                	ld	a4,0(s1)
ffffffffc020536a:	0ee78b63          	beq	a5,a4,ffffffffc0205460 <do_exit+0x124>
    struct mm_struct *mm = current->mm;
ffffffffc020536e:	0287b983          	ld	s3,40(a5)
ffffffffc0205372:	892a                	mv	s2,a0
    if (mm != NULL) {
ffffffffc0205374:	02098663          	beqz	s3,ffffffffc02053a0 <do_exit+0x64>
ffffffffc0205378:	000ad797          	auipc	a5,0xad
ffffffffc020537c:	6b07b783          	ld	a5,1712(a5) # ffffffffc02b2a28 <boot_cr3>
ffffffffc0205380:	577d                	li	a4,-1
ffffffffc0205382:	177e                	slli	a4,a4,0x3f
ffffffffc0205384:	83b1                	srli	a5,a5,0xc
ffffffffc0205386:	8fd9                	or	a5,a5,a4
ffffffffc0205388:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc020538c:	0309a783          	lw	a5,48(s3)
ffffffffc0205390:	fff7871b          	addiw	a4,a5,-1
ffffffffc0205394:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0) {
ffffffffc0205398:	cb55                	beqz	a4,ffffffffc020544c <do_exit+0x110>
        current->mm = NULL;
ffffffffc020539a:	601c                	ld	a5,0(s0)
ffffffffc020539c:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc02053a0:	601c                	ld	a5,0(s0)
ffffffffc02053a2:	470d                	li	a4,3
ffffffffc02053a4:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc02053a6:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02053aa:	100027f3          	csrr	a5,sstatus
ffffffffc02053ae:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02053b0:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02053b2:	e3f9                	bnez	a5,ffffffffc0205478 <do_exit+0x13c>
        proc = current->parent;
ffffffffc02053b4:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD) {
ffffffffc02053b6:	800007b7          	lui	a5,0x80000
ffffffffc02053ba:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc02053bc:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD) {
ffffffffc02053be:	0ec52703          	lw	a4,236(a0)
ffffffffc02053c2:	0af70f63          	beq	a4,a5,ffffffffc0205480 <do_exit+0x144>
        while (current->cptr != NULL) {
ffffffffc02053c6:	6018                	ld	a4,0(s0)
ffffffffc02053c8:	7b7c                	ld	a5,240(a4)
ffffffffc02053ca:	c3a1                	beqz	a5,ffffffffc020540a <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD) {
ffffffffc02053cc:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE) {
ffffffffc02053d0:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD) {
ffffffffc02053d2:	0985                	addi	s3,s3,1
ffffffffc02053d4:	a021                	j	ffffffffc02053dc <do_exit+0xa0>
        while (current->cptr != NULL) {
ffffffffc02053d6:	6018                	ld	a4,0(s0)
ffffffffc02053d8:	7b7c                	ld	a5,240(a4)
ffffffffc02053da:	cb85                	beqz	a5,ffffffffc020540a <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc02053dc:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff4fb8>
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc02053e0:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc02053e2:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc02053e4:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc02053e6:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc02053ea:	10e7b023          	sd	a4,256(a5)
ffffffffc02053ee:	c311                	beqz	a4,ffffffffc02053f2 <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc02053f0:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE) {
ffffffffc02053f2:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc02053f4:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc02053f6:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE) {
ffffffffc02053f8:	fd271fe3          	bne	a4,s2,ffffffffc02053d6 <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD) {
ffffffffc02053fc:	0ec52783          	lw	a5,236(a0)
ffffffffc0205400:	fd379be3          	bne	a5,s3,ffffffffc02053d6 <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc0205404:	36b000ef          	jal	ra,ffffffffc0205f6e <wakeup_proc>
ffffffffc0205408:	b7f9                	j	ffffffffc02053d6 <do_exit+0x9a>
    if (flag) {
ffffffffc020540a:	020a1263          	bnez	s4,ffffffffc020542e <do_exit+0xf2>
    schedule();
ffffffffc020540e:	3e1000ef          	jal	ra,ffffffffc0205fee <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc0205412:	601c                	ld	a5,0(s0)
ffffffffc0205414:	00003617          	auipc	a2,0x3
ffffffffc0205418:	0f460613          	addi	a2,a2,244 # ffffffffc0208508 <default_pmm_manager+0x1150>
ffffffffc020541c:	20300593          	li	a1,515
ffffffffc0205420:	43d4                	lw	a3,4(a5)
ffffffffc0205422:	00003517          	auipc	a0,0x3
ffffffffc0205426:	06650513          	addi	a0,a0,102 # ffffffffc0208488 <default_pmm_manager+0x10d0>
ffffffffc020542a:	850fb0ef          	jal	ra,ffffffffc020047a <__panic>
        intr_enable();
ffffffffc020542e:	a12fb0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0205432:	bff1                	j	ffffffffc020540e <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc0205434:	00003617          	auipc	a2,0x3
ffffffffc0205438:	0b460613          	addi	a2,a2,180 # ffffffffc02084e8 <default_pmm_manager+0x1130>
ffffffffc020543c:	1d700593          	li	a1,471
ffffffffc0205440:	00003517          	auipc	a0,0x3
ffffffffc0205444:	04850513          	addi	a0,a0,72 # ffffffffc0208488 <default_pmm_manager+0x10d0>
ffffffffc0205448:	832fb0ef          	jal	ra,ffffffffc020047a <__panic>
            exit_mmap(mm);
ffffffffc020544c:	854e                	mv	a0,s3
ffffffffc020544e:	822ff0ef          	jal	ra,ffffffffc0204470 <exit_mmap>
            put_pgdir(mm);
ffffffffc0205452:	854e                	mv	a0,s3
ffffffffc0205454:	9a1ff0ef          	jal	ra,ffffffffc0204df4 <put_pgdir>
            mm_destroy(mm);
ffffffffc0205458:	854e                	mv	a0,s3
ffffffffc020545a:	e7bfe0ef          	jal	ra,ffffffffc02042d4 <mm_destroy>
ffffffffc020545e:	bf35                	j	ffffffffc020539a <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc0205460:	00003617          	auipc	a2,0x3
ffffffffc0205464:	09860613          	addi	a2,a2,152 # ffffffffc02084f8 <default_pmm_manager+0x1140>
ffffffffc0205468:	1da00593          	li	a1,474
ffffffffc020546c:	00003517          	auipc	a0,0x3
ffffffffc0205470:	01c50513          	addi	a0,a0,28 # ffffffffc0208488 <default_pmm_manager+0x10d0>
ffffffffc0205474:	806fb0ef          	jal	ra,ffffffffc020047a <__panic>
        intr_disable();
ffffffffc0205478:	9cefb0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        return 1;
ffffffffc020547c:	4a05                	li	s4,1
ffffffffc020547e:	bf1d                	j	ffffffffc02053b4 <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc0205480:	2ef000ef          	jal	ra,ffffffffc0205f6e <wakeup_proc>
ffffffffc0205484:	b789                	j	ffffffffc02053c6 <do_exit+0x8a>

ffffffffc0205486 <do_wait.part.0>:
do_wait(int pid, int *code_store) {
ffffffffc0205486:	715d                	addi	sp,sp,-80
ffffffffc0205488:	fc26                	sd	s1,56(sp)
ffffffffc020548a:	f84a                	sd	s2,48(sp)
        current->wait_state = WT_CHILD;
ffffffffc020548c:	800004b7          	lui	s1,0x80000
    if (0 < pid && pid < MAX_PID) {
ffffffffc0205490:	6909                	lui	s2,0x2
do_wait(int pid, int *code_store) {
ffffffffc0205492:	f44e                	sd	s3,40(sp)
ffffffffc0205494:	f052                	sd	s4,32(sp)
ffffffffc0205496:	ec56                	sd	s5,24(sp)
ffffffffc0205498:	e85a                	sd	s6,16(sp)
ffffffffc020549a:	e45e                	sd	s7,8(sp)
ffffffffc020549c:	e486                	sd	ra,72(sp)
ffffffffc020549e:	e0a2                	sd	s0,64(sp)
ffffffffc02054a0:	8b2a                	mv	s6,a0
ffffffffc02054a2:	89ae                	mv	s3,a1
        proc = current->cptr;
ffffffffc02054a4:	000adb97          	auipc	s7,0xad
ffffffffc02054a8:	5dcb8b93          	addi	s7,s7,1500 # ffffffffc02b2a80 <current>
    if (0 < pid && pid < MAX_PID) {
ffffffffc02054ac:	00050a9b          	sext.w	s5,a0
ffffffffc02054b0:	fff50a1b          	addiw	s4,a0,-1
ffffffffc02054b4:	1979                	addi	s2,s2,-2
        current->wait_state = WT_CHILD;
ffffffffc02054b6:	0485                	addi	s1,s1,1
    if (pid != 0) {
ffffffffc02054b8:	060b0f63          	beqz	s6,ffffffffc0205536 <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID) {
ffffffffc02054bc:	03496763          	bltu	s2,s4,ffffffffc02054ea <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02054c0:	45a9                	li	a1,10
ffffffffc02054c2:	8556                	mv	a0,s5
ffffffffc02054c4:	497000ef          	jal	ra,ffffffffc020615a <hash32>
ffffffffc02054c8:	02051713          	slli	a4,a0,0x20
ffffffffc02054cc:	8371                	srli	a4,a4,0x1c
ffffffffc02054ce:	000a9797          	auipc	a5,0xa9
ffffffffc02054d2:	52a78793          	addi	a5,a5,1322 # ffffffffc02ae9f8 <hash_list>
ffffffffc02054d6:	973e                	add	a4,a4,a5
ffffffffc02054d8:	843a                	mv	s0,a4
        while ((le = list_next(le)) != list) {
ffffffffc02054da:	a029                	j	ffffffffc02054e4 <do_wait.part.0+0x5e>
            if (proc->pid == pid) {
ffffffffc02054dc:	f2c42783          	lw	a5,-212(s0)
ffffffffc02054e0:	03678163          	beq	a5,s6,ffffffffc0205502 <do_wait.part.0+0x7c>
ffffffffc02054e4:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list) {
ffffffffc02054e6:	fe871be3          	bne	a4,s0,ffffffffc02054dc <do_wait.part.0+0x56>
    return -E_BAD_PROC;
ffffffffc02054ea:	5579                	li	a0,-2
}
ffffffffc02054ec:	60a6                	ld	ra,72(sp)
ffffffffc02054ee:	6406                	ld	s0,64(sp)
ffffffffc02054f0:	74e2                	ld	s1,56(sp)
ffffffffc02054f2:	7942                	ld	s2,48(sp)
ffffffffc02054f4:	79a2                	ld	s3,40(sp)
ffffffffc02054f6:	7a02                	ld	s4,32(sp)
ffffffffc02054f8:	6ae2                	ld	s5,24(sp)
ffffffffc02054fa:	6b42                	ld	s6,16(sp)
ffffffffc02054fc:	6ba2                	ld	s7,8(sp)
ffffffffc02054fe:	6161                	addi	sp,sp,80
ffffffffc0205500:	8082                	ret
        if (proc != NULL && proc->parent == current) {
ffffffffc0205502:	000bb683          	ld	a3,0(s7)
ffffffffc0205506:	f4843783          	ld	a5,-184(s0)
ffffffffc020550a:	fed790e3          	bne	a5,a3,ffffffffc02054ea <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE) {
ffffffffc020550e:	f2842703          	lw	a4,-216(s0)
ffffffffc0205512:	478d                	li	a5,3
ffffffffc0205514:	0ef70b63          	beq	a4,a5,ffffffffc020560a <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc0205518:	4785                	li	a5,1
ffffffffc020551a:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc020551c:	0e96a623          	sw	s1,236(a3)
        schedule();
ffffffffc0205520:	2cf000ef          	jal	ra,ffffffffc0205fee <schedule>
        if (current->flags & PF_EXITING) {
ffffffffc0205524:	000bb783          	ld	a5,0(s7)
ffffffffc0205528:	0b07a783          	lw	a5,176(a5)
ffffffffc020552c:	8b85                	andi	a5,a5,1
ffffffffc020552e:	d7c9                	beqz	a5,ffffffffc02054b8 <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc0205530:	555d                	li	a0,-9
ffffffffc0205532:	e0bff0ef          	jal	ra,ffffffffc020533c <do_exit>
        proc = current->cptr;
ffffffffc0205536:	000bb683          	ld	a3,0(s7)
ffffffffc020553a:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr) {
ffffffffc020553c:	d45d                	beqz	s0,ffffffffc02054ea <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE) {
ffffffffc020553e:	470d                	li	a4,3
ffffffffc0205540:	a021                	j	ffffffffc0205548 <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr) {
ffffffffc0205542:	10043403          	ld	s0,256(s0)
ffffffffc0205546:	d869                	beqz	s0,ffffffffc0205518 <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE) {
ffffffffc0205548:	401c                	lw	a5,0(s0)
ffffffffc020554a:	fee79ce3          	bne	a5,a4,ffffffffc0205542 <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc) {
ffffffffc020554e:	000ad797          	auipc	a5,0xad
ffffffffc0205552:	53a7b783          	ld	a5,1338(a5) # ffffffffc02b2a88 <idleproc>
ffffffffc0205556:	0c878963          	beq	a5,s0,ffffffffc0205628 <do_wait.part.0+0x1a2>
ffffffffc020555a:	000ad797          	auipc	a5,0xad
ffffffffc020555e:	5367b783          	ld	a5,1334(a5) # ffffffffc02b2a90 <initproc>
ffffffffc0205562:	0cf40363          	beq	s0,a5,ffffffffc0205628 <do_wait.part.0+0x1a2>
    if (code_store != NULL) {
ffffffffc0205566:	00098663          	beqz	s3,ffffffffc0205572 <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc020556a:	0e842783          	lw	a5,232(s0)
ffffffffc020556e:	00f9a023          	sw	a5,0(s3) # ffffffff80000000 <_binary_obj___user_exit_out_size+0xffffffff7fff4eb8>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205572:	100027f3          	csrr	a5,sstatus
ffffffffc0205576:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205578:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020557a:	e7c1                	bnez	a5,ffffffffc0205602 <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc020557c:	6c70                	ld	a2,216(s0)
ffffffffc020557e:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL) {
ffffffffc0205580:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc0205584:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc0205586:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0205588:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020558a:	6470                	ld	a2,200(s0)
ffffffffc020558c:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc020558e:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0205590:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL) {
ffffffffc0205592:	c319                	beqz	a4,ffffffffc0205598 <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc0205594:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL) {
ffffffffc0205596:	7c7c                	ld	a5,248(s0)
ffffffffc0205598:	c3b5                	beqz	a5,ffffffffc02055fc <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc020559a:	10e7b023          	sd	a4,256(a5)
    nr_process --;
ffffffffc020559e:	000ad717          	auipc	a4,0xad
ffffffffc02055a2:	4fa70713          	addi	a4,a4,1274 # ffffffffc02b2a98 <nr_process>
ffffffffc02055a6:	431c                	lw	a5,0(a4)
ffffffffc02055a8:	37fd                	addiw	a5,a5,-1
ffffffffc02055aa:	c31c                	sw	a5,0(a4)
    if (flag) {
ffffffffc02055ac:	e5a9                	bnez	a1,ffffffffc02055f6 <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02055ae:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc02055b0:	c02007b7          	lui	a5,0xc0200
ffffffffc02055b4:	04f6ee63          	bltu	a3,a5,ffffffffc0205610 <do_wait.part.0+0x18a>
ffffffffc02055b8:	000ad797          	auipc	a5,0xad
ffffffffc02055bc:	4987b783          	ld	a5,1176(a5) # ffffffffc02b2a50 <va_pa_offset>
ffffffffc02055c0:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage) {
ffffffffc02055c2:	82b1                	srli	a3,a3,0xc
ffffffffc02055c4:	000ad797          	auipc	a5,0xad
ffffffffc02055c8:	4747b783          	ld	a5,1140(a5) # ffffffffc02b2a38 <npage>
ffffffffc02055cc:	06f6fa63          	bgeu	a3,a5,ffffffffc0205640 <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc02055d0:	00003517          	auipc	a0,0x3
ffffffffc02055d4:	77053503          	ld	a0,1904(a0) # ffffffffc0208d40 <nbase>
ffffffffc02055d8:	8e89                	sub	a3,a3,a0
ffffffffc02055da:	069a                	slli	a3,a3,0x6
ffffffffc02055dc:	000ad517          	auipc	a0,0xad
ffffffffc02055e0:	46453503          	ld	a0,1124(a0) # ffffffffc02b2a40 <pages>
ffffffffc02055e4:	9536                	add	a0,a0,a3
ffffffffc02055e6:	4589                	li	a1,2
ffffffffc02055e8:	fb8fc0ef          	jal	ra,ffffffffc0201da0 <free_pages>
    kfree(proc);
ffffffffc02055ec:	8522                	mv	a0,s0
ffffffffc02055ee:	df2fc0ef          	jal	ra,ffffffffc0201be0 <kfree>
    return 0;
ffffffffc02055f2:	4501                	li	a0,0
ffffffffc02055f4:	bde5                	j	ffffffffc02054ec <do_wait.part.0+0x66>
        intr_enable();
ffffffffc02055f6:	84afb0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc02055fa:	bf55                	j	ffffffffc02055ae <do_wait.part.0+0x128>
       proc->parent->cptr = proc->optr;
ffffffffc02055fc:	701c                	ld	a5,32(s0)
ffffffffc02055fe:	fbf8                	sd	a4,240(a5)
ffffffffc0205600:	bf79                	j	ffffffffc020559e <do_wait.part.0+0x118>
        intr_disable();
ffffffffc0205602:	844fb0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        return 1;
ffffffffc0205606:	4585                	li	a1,1
ffffffffc0205608:	bf95                	j	ffffffffc020557c <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc020560a:	f2840413          	addi	s0,s0,-216
ffffffffc020560e:	b781                	j	ffffffffc020554e <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc0205610:	00002617          	auipc	a2,0x2
ffffffffc0205614:	e8860613          	addi	a2,a2,-376 # ffffffffc0207498 <default_pmm_manager+0xe0>
ffffffffc0205618:	06e00593          	li	a1,110
ffffffffc020561c:	00002517          	auipc	a0,0x2
ffffffffc0205620:	dfc50513          	addi	a0,a0,-516 # ffffffffc0207418 <default_pmm_manager+0x60>
ffffffffc0205624:	e57fa0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc0205628:	00003617          	auipc	a2,0x3
ffffffffc020562c:	f0060613          	addi	a2,a2,-256 # ffffffffc0208528 <default_pmm_manager+0x1170>
ffffffffc0205630:	2fa00593          	li	a1,762
ffffffffc0205634:	00003517          	auipc	a0,0x3
ffffffffc0205638:	e5450513          	addi	a0,a0,-428 # ffffffffc0208488 <default_pmm_manager+0x10d0>
ffffffffc020563c:	e3ffa0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0205640:	00002617          	auipc	a2,0x2
ffffffffc0205644:	e8060613          	addi	a2,a2,-384 # ffffffffc02074c0 <default_pmm_manager+0x108>
ffffffffc0205648:	06200593          	li	a1,98
ffffffffc020564c:	00002517          	auipc	a0,0x2
ffffffffc0205650:	dcc50513          	addi	a0,a0,-564 # ffffffffc0207418 <default_pmm_manager+0x60>
ffffffffc0205654:	e27fa0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0205658 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg) {
ffffffffc0205658:	1141                	addi	sp,sp,-16
ffffffffc020565a:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc020565c:	f84fc0ef          	jal	ra,ffffffffc0201de0 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc0205660:	cccfc0ef          	jal	ra,ffffffffc0201b2c <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc0205664:	4601                	li	a2,0
ffffffffc0205666:	4581                	li	a1,0
ffffffffc0205668:	fffff517          	auipc	a0,0xfffff
ffffffffc020566c:	70e50513          	addi	a0,a0,1806 # ffffffffc0204d76 <user_main>
ffffffffc0205670:	c7dff0ef          	jal	ra,ffffffffc02052ec <kernel_thread>
    if (pid <= 0) {
ffffffffc0205674:	00a04563          	bgtz	a0,ffffffffc020567e <init_main+0x26>
ffffffffc0205678:	a071                	j	ffffffffc0205704 <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0) {
        schedule();
ffffffffc020567a:	175000ef          	jal	ra,ffffffffc0205fee <schedule>
    if (code_store != NULL) {
ffffffffc020567e:	4581                	li	a1,0
ffffffffc0205680:	4501                	li	a0,0
ffffffffc0205682:	e05ff0ef          	jal	ra,ffffffffc0205486 <do_wait.part.0>
    while (do_wait(0, NULL) == 0) {
ffffffffc0205686:	d975                	beqz	a0,ffffffffc020567a <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc0205688:	00003517          	auipc	a0,0x3
ffffffffc020568c:	ee050513          	addi	a0,a0,-288 # ffffffffc0208568 <default_pmm_manager+0x11b0>
ffffffffc0205690:	af1fa0ef          	jal	ra,ffffffffc0200180 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0205694:	000ad797          	auipc	a5,0xad
ffffffffc0205698:	3fc7b783          	ld	a5,1020(a5) # ffffffffc02b2a90 <initproc>
ffffffffc020569c:	7bf8                	ld	a4,240(a5)
ffffffffc020569e:	e339                	bnez	a4,ffffffffc02056e4 <init_main+0x8c>
ffffffffc02056a0:	7ff8                	ld	a4,248(a5)
ffffffffc02056a2:	e329                	bnez	a4,ffffffffc02056e4 <init_main+0x8c>
ffffffffc02056a4:	1007b703          	ld	a4,256(a5)
ffffffffc02056a8:	ef15                	bnez	a4,ffffffffc02056e4 <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc02056aa:	000ad697          	auipc	a3,0xad
ffffffffc02056ae:	3ee6a683          	lw	a3,1006(a3) # ffffffffc02b2a98 <nr_process>
ffffffffc02056b2:	4709                	li	a4,2
ffffffffc02056b4:	0ae69463          	bne	a3,a4,ffffffffc020575c <init_main+0x104>
    return listelm->next;
ffffffffc02056b8:	000ad697          	auipc	a3,0xad
ffffffffc02056bc:	34068693          	addi	a3,a3,832 # ffffffffc02b29f8 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02056c0:	6698                	ld	a4,8(a3)
ffffffffc02056c2:	0c878793          	addi	a5,a5,200
ffffffffc02056c6:	06f71b63          	bne	a4,a5,ffffffffc020573c <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02056ca:	629c                	ld	a5,0(a3)
ffffffffc02056cc:	04f71863          	bne	a4,a5,ffffffffc020571c <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc02056d0:	00003517          	auipc	a0,0x3
ffffffffc02056d4:	f8050513          	addi	a0,a0,-128 # ffffffffc0208650 <default_pmm_manager+0x1298>
ffffffffc02056d8:	aa9fa0ef          	jal	ra,ffffffffc0200180 <cprintf>
    return 0;
}
ffffffffc02056dc:	60a2                	ld	ra,8(sp)
ffffffffc02056de:	4501                	li	a0,0
ffffffffc02056e0:	0141                	addi	sp,sp,16
ffffffffc02056e2:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02056e4:	00003697          	auipc	a3,0x3
ffffffffc02056e8:	eac68693          	addi	a3,a3,-340 # ffffffffc0208590 <default_pmm_manager+0x11d8>
ffffffffc02056ec:	00001617          	auipc	a2,0x1
ffffffffc02056f0:	5d460613          	addi	a2,a2,1492 # ffffffffc0206cc0 <commands+0x450>
ffffffffc02056f4:	35f00593          	li	a1,863
ffffffffc02056f8:	00003517          	auipc	a0,0x3
ffffffffc02056fc:	d9050513          	addi	a0,a0,-624 # ffffffffc0208488 <default_pmm_manager+0x10d0>
ffffffffc0205700:	d7bfa0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("create user_main failed.\n");
ffffffffc0205704:	00003617          	auipc	a2,0x3
ffffffffc0205708:	e4460613          	addi	a2,a2,-444 # ffffffffc0208548 <default_pmm_manager+0x1190>
ffffffffc020570c:	35700593          	li	a1,855
ffffffffc0205710:	00003517          	auipc	a0,0x3
ffffffffc0205714:	d7850513          	addi	a0,a0,-648 # ffffffffc0208488 <default_pmm_manager+0x10d0>
ffffffffc0205718:	d63fa0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020571c:	00003697          	auipc	a3,0x3
ffffffffc0205720:	f0468693          	addi	a3,a3,-252 # ffffffffc0208620 <default_pmm_manager+0x1268>
ffffffffc0205724:	00001617          	auipc	a2,0x1
ffffffffc0205728:	59c60613          	addi	a2,a2,1436 # ffffffffc0206cc0 <commands+0x450>
ffffffffc020572c:	36200593          	li	a1,866
ffffffffc0205730:	00003517          	auipc	a0,0x3
ffffffffc0205734:	d5850513          	addi	a0,a0,-680 # ffffffffc0208488 <default_pmm_manager+0x10d0>
ffffffffc0205738:	d43fa0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc020573c:	00003697          	auipc	a3,0x3
ffffffffc0205740:	eb468693          	addi	a3,a3,-332 # ffffffffc02085f0 <default_pmm_manager+0x1238>
ffffffffc0205744:	00001617          	auipc	a2,0x1
ffffffffc0205748:	57c60613          	addi	a2,a2,1404 # ffffffffc0206cc0 <commands+0x450>
ffffffffc020574c:	36100593          	li	a1,865
ffffffffc0205750:	00003517          	auipc	a0,0x3
ffffffffc0205754:	d3850513          	addi	a0,a0,-712 # ffffffffc0208488 <default_pmm_manager+0x10d0>
ffffffffc0205758:	d23fa0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(nr_process == 2);
ffffffffc020575c:	00003697          	auipc	a3,0x3
ffffffffc0205760:	e8468693          	addi	a3,a3,-380 # ffffffffc02085e0 <default_pmm_manager+0x1228>
ffffffffc0205764:	00001617          	auipc	a2,0x1
ffffffffc0205768:	55c60613          	addi	a2,a2,1372 # ffffffffc0206cc0 <commands+0x450>
ffffffffc020576c:	36000593          	li	a1,864
ffffffffc0205770:	00003517          	auipc	a0,0x3
ffffffffc0205774:	d1850513          	addi	a0,a0,-744 # ffffffffc0208488 <default_pmm_manager+0x10d0>
ffffffffc0205778:	d03fa0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc020577c <do_execve>:
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc020577c:	7171                	addi	sp,sp,-176
ffffffffc020577e:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0205780:	000add97          	auipc	s11,0xad
ffffffffc0205784:	300d8d93          	addi	s11,s11,768 # ffffffffc02b2a80 <current>
ffffffffc0205788:	000db783          	ld	a5,0(s11)
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc020578c:	e54e                	sd	s3,136(sp)
ffffffffc020578e:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0205790:	0287b983          	ld	s3,40(a5)
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc0205794:	e94a                	sd	s2,144(sp)
ffffffffc0205796:	f4de                	sd	s7,104(sp)
ffffffffc0205798:	892a                	mv	s2,a0
ffffffffc020579a:	8bb2                	mv	s7,a2
ffffffffc020579c:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) {
ffffffffc020579e:	862e                	mv	a2,a1
ffffffffc02057a0:	4681                	li	a3,0
ffffffffc02057a2:	85aa                	mv	a1,a0
ffffffffc02057a4:	854e                	mv	a0,s3
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc02057a6:	f506                	sd	ra,168(sp)
ffffffffc02057a8:	f122                	sd	s0,160(sp)
ffffffffc02057aa:	e152                	sd	s4,128(sp)
ffffffffc02057ac:	fcd6                	sd	s5,120(sp)
ffffffffc02057ae:	f8da                	sd	s6,112(sp)
ffffffffc02057b0:	f0e2                	sd	s8,96(sp)
ffffffffc02057b2:	ece6                	sd	s9,88(sp)
ffffffffc02057b4:	e8ea                	sd	s10,80(sp)
ffffffffc02057b6:	f05e                	sd	s7,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) {
ffffffffc02057b8:	b4eff0ef          	jal	ra,ffffffffc0204b06 <user_mem_check>
ffffffffc02057bc:	40050863          	beqz	a0,ffffffffc0205bcc <do_execve+0x450>
    memset(local_name, 0, sizeof(local_name));
ffffffffc02057c0:	4641                	li	a2,16
ffffffffc02057c2:	4581                	li	a1,0
ffffffffc02057c4:	1808                	addi	a0,sp,48
ffffffffc02057c6:	615000ef          	jal	ra,ffffffffc02065da <memset>
    memcpy(local_name, name, len);
ffffffffc02057ca:	47bd                	li	a5,15
ffffffffc02057cc:	8626                	mv	a2,s1
ffffffffc02057ce:	1e97e063          	bltu	a5,s1,ffffffffc02059ae <do_execve+0x232>
ffffffffc02057d2:	85ca                	mv	a1,s2
ffffffffc02057d4:	1808                	addi	a0,sp,48
ffffffffc02057d6:	617000ef          	jal	ra,ffffffffc02065ec <memcpy>
    if (mm != NULL) {
ffffffffc02057da:	1e098163          	beqz	s3,ffffffffc02059bc <do_execve+0x240>
        cputs("mm != NULL");
ffffffffc02057de:	00002517          	auipc	a0,0x2
ffffffffc02057e2:	36250513          	addi	a0,a0,866 # ffffffffc0207b40 <default_pmm_manager+0x788>
ffffffffc02057e6:	9d3fa0ef          	jal	ra,ffffffffc02001b8 <cputs>
ffffffffc02057ea:	000ad797          	auipc	a5,0xad
ffffffffc02057ee:	23e7b783          	ld	a5,574(a5) # ffffffffc02b2a28 <boot_cr3>
ffffffffc02057f2:	577d                	li	a4,-1
ffffffffc02057f4:	177e                	slli	a4,a4,0x3f
ffffffffc02057f6:	83b1                	srli	a5,a5,0xc
ffffffffc02057f8:	8fd9                	or	a5,a5,a4
ffffffffc02057fa:	18079073          	csrw	satp,a5
ffffffffc02057fe:	0309a783          	lw	a5,48(s3)
ffffffffc0205802:	fff7871b          	addiw	a4,a5,-1
ffffffffc0205806:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0) {
ffffffffc020580a:	2c070263          	beqz	a4,ffffffffc0205ace <do_execve+0x352>
        current->mm = NULL;
ffffffffc020580e:	000db783          	ld	a5,0(s11)
ffffffffc0205812:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL) {
ffffffffc0205816:	939fe0ef          	jal	ra,ffffffffc020414e <mm_create>
ffffffffc020581a:	84aa                	mv	s1,a0
ffffffffc020581c:	1c050b63          	beqz	a0,ffffffffc02059f2 <do_execve+0x276>
    if ((page = alloc_page()) == NULL) {
ffffffffc0205820:	4505                	li	a0,1
ffffffffc0205822:	cecfc0ef          	jal	ra,ffffffffc0201d0e <alloc_pages>
ffffffffc0205826:	3a050763          	beqz	a0,ffffffffc0205bd4 <do_execve+0x458>
    return page - pages + nbase;
ffffffffc020582a:	000adc97          	auipc	s9,0xad
ffffffffc020582e:	216c8c93          	addi	s9,s9,534 # ffffffffc02b2a40 <pages>
ffffffffc0205832:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc0205836:	000adc17          	auipc	s8,0xad
ffffffffc020583a:	202c0c13          	addi	s8,s8,514 # ffffffffc02b2a38 <npage>
    return page - pages + nbase;
ffffffffc020583e:	00003717          	auipc	a4,0x3
ffffffffc0205842:	50273703          	ld	a4,1282(a4) # ffffffffc0208d40 <nbase>
ffffffffc0205846:	40d506b3          	sub	a3,a0,a3
ffffffffc020584a:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc020584c:	5afd                	li	s5,-1
ffffffffc020584e:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc0205852:	96ba                	add	a3,a3,a4
ffffffffc0205854:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc0205856:	00cad713          	srli	a4,s5,0xc
ffffffffc020585a:	ec3a                	sd	a4,24(sp)
ffffffffc020585c:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc020585e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205860:	36f77e63          	bgeu	a4,a5,ffffffffc0205bdc <do_execve+0x460>
ffffffffc0205864:	000adb17          	auipc	s6,0xad
ffffffffc0205868:	1ecb0b13          	addi	s6,s6,492 # ffffffffc02b2a50 <va_pa_offset>
ffffffffc020586c:	000b3903          	ld	s2,0(s6)
    memcpy(pgdir, boot_pgdir, PGSIZE);
ffffffffc0205870:	6605                	lui	a2,0x1
ffffffffc0205872:	000ad597          	auipc	a1,0xad
ffffffffc0205876:	1be5b583          	ld	a1,446(a1) # ffffffffc02b2a30 <boot_pgdir>
ffffffffc020587a:	9936                	add	s2,s2,a3
ffffffffc020587c:	854a                	mv	a0,s2
ffffffffc020587e:	56f000ef          	jal	ra,ffffffffc02065ec <memcpy>
    if (elf->e_magic != ELF_MAGIC) {
ffffffffc0205882:	7782                	ld	a5,32(sp)
ffffffffc0205884:	4398                	lw	a4,0(a5)
ffffffffc0205886:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc020588a:	0124bc23          	sd	s2,24(s1) # ffffffff80000018 <_binary_obj___user_exit_out_size+0xffffffff7fff4ed0>
    if (elf->e_magic != ELF_MAGIC) {
ffffffffc020588e:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b9437>
ffffffffc0205892:	14f71663          	bne	a4,a5,ffffffffc02059de <do_execve+0x262>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0205896:	7682                	ld	a3,32(sp)
ffffffffc0205898:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc020589c:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02058a0:	00371793          	slli	a5,a4,0x3
ffffffffc02058a4:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc02058a6:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02058a8:	078e                	slli	a5,a5,0x3
ffffffffc02058aa:	97ce                	add	a5,a5,s3
ffffffffc02058ac:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph ++) {
ffffffffc02058ae:	00f9fc63          	bgeu	s3,a5,ffffffffc02058c6 <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD) {
ffffffffc02058b2:	0009a783          	lw	a5,0(s3)
ffffffffc02058b6:	4705                	li	a4,1
ffffffffc02058b8:	12e78f63          	beq	a5,a4,ffffffffc02059f6 <do_execve+0x27a>
    for (; ph < ph_end; ph ++) {
ffffffffc02058bc:	77a2                	ld	a5,40(sp)
ffffffffc02058be:	03898993          	addi	s3,s3,56
ffffffffc02058c2:	fef9e8e3          	bltu	s3,a5,ffffffffc02058b2 <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0) {
ffffffffc02058c6:	4701                	li	a4,0
ffffffffc02058c8:	46ad                	li	a3,11
ffffffffc02058ca:	00100637          	lui	a2,0x100
ffffffffc02058ce:	7ff005b7          	lui	a1,0x7ff00
ffffffffc02058d2:	8526                	mv	a0,s1
ffffffffc02058d4:	a53fe0ef          	jal	ra,ffffffffc0204326 <mm_map>
ffffffffc02058d8:	8a2a                	mv	s4,a0
ffffffffc02058da:	1e051063          	bnez	a0,ffffffffc0205aba <do_execve+0x33e>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-PGSIZE , PTE_USER) != NULL);
ffffffffc02058de:	6c88                	ld	a0,24(s1)
ffffffffc02058e0:	467d                	li	a2,31
ffffffffc02058e2:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc02058e6:	a95fd0ef          	jal	ra,ffffffffc020337a <pgdir_alloc_page>
ffffffffc02058ea:	38050163          	beqz	a0,ffffffffc0205c6c <do_execve+0x4f0>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-2*PGSIZE , PTE_USER) != NULL);
ffffffffc02058ee:	6c88                	ld	a0,24(s1)
ffffffffc02058f0:	467d                	li	a2,31
ffffffffc02058f2:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc02058f6:	a85fd0ef          	jal	ra,ffffffffc020337a <pgdir_alloc_page>
ffffffffc02058fa:	34050963          	beqz	a0,ffffffffc0205c4c <do_execve+0x4d0>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-3*PGSIZE , PTE_USER) != NULL);
ffffffffc02058fe:	6c88                	ld	a0,24(s1)
ffffffffc0205900:	467d                	li	a2,31
ffffffffc0205902:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0205906:	a75fd0ef          	jal	ra,ffffffffc020337a <pgdir_alloc_page>
ffffffffc020590a:	32050163          	beqz	a0,ffffffffc0205c2c <do_execve+0x4b0>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-4*PGSIZE , PTE_USER) != NULL);
ffffffffc020590e:	6c88                	ld	a0,24(s1)
ffffffffc0205910:	467d                	li	a2,31
ffffffffc0205912:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0205916:	a65fd0ef          	jal	ra,ffffffffc020337a <pgdir_alloc_page>
ffffffffc020591a:	2e050963          	beqz	a0,ffffffffc0205c0c <do_execve+0x490>
    mm->mm_count += 1;
ffffffffc020591e:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc0205920:	000db603          	ld	a2,0(s11)
    current->cr3 = PADDR(mm->pgdir);
ffffffffc0205924:	6c94                	ld	a3,24(s1)
ffffffffc0205926:	2785                	addiw	a5,a5,1
ffffffffc0205928:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc020592a:	f604                	sd	s1,40(a2)
    current->cr3 = PADDR(mm->pgdir);
ffffffffc020592c:	c02007b7          	lui	a5,0xc0200
ffffffffc0205930:	2cf6e263          	bltu	a3,a5,ffffffffc0205bf4 <do_execve+0x478>
ffffffffc0205934:	000b3783          	ld	a5,0(s6)
ffffffffc0205938:	577d                	li	a4,-1
ffffffffc020593a:	177e                	slli	a4,a4,0x3f
ffffffffc020593c:	8e9d                	sub	a3,a3,a5
ffffffffc020593e:	00c6d793          	srli	a5,a3,0xc
ffffffffc0205942:	f654                	sd	a3,168(a2)
ffffffffc0205944:	8fd9                	or	a5,a5,a4
ffffffffc0205946:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc020594a:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc020594c:	4581                	li	a1,0
ffffffffc020594e:	12000613          	li	a2,288
ffffffffc0205952:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0205954:	10043903          	ld	s2,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0205958:	483000ef          	jal	ra,ffffffffc02065da <memset>
    tf->epc = elf->e_entry;
ffffffffc020595c:	7782                	ld	a5,32(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020595e:	000db483          	ld	s1,0(s11)
    tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE);
ffffffffc0205962:	edf97913          	andi	s2,s2,-289
    tf->epc = elf->e_entry;
ffffffffc0205966:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc0205968:	4785                	li	a5,1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020596a:	0b448493          	addi	s1,s1,180
    tf->gpr.sp = USTACKTOP;
ffffffffc020596e:	07fe                	slli	a5,a5,0x1f
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205970:	4641                	li	a2,16
ffffffffc0205972:	4581                	li	a1,0
    tf->gpr.sp = USTACKTOP;
ffffffffc0205974:	e81c                	sd	a5,16(s0)
    tf->epc = elf->e_entry;
ffffffffc0205976:	10e43423          	sd	a4,264(s0)
    tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE);
ffffffffc020597a:	11243023          	sd	s2,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020597e:	8526                	mv	a0,s1
ffffffffc0205980:	45b000ef          	jal	ra,ffffffffc02065da <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205984:	463d                	li	a2,15
ffffffffc0205986:	180c                	addi	a1,sp,48
ffffffffc0205988:	8526                	mv	a0,s1
ffffffffc020598a:	463000ef          	jal	ra,ffffffffc02065ec <memcpy>
}
ffffffffc020598e:	70aa                	ld	ra,168(sp)
ffffffffc0205990:	740a                	ld	s0,160(sp)
ffffffffc0205992:	64ea                	ld	s1,152(sp)
ffffffffc0205994:	694a                	ld	s2,144(sp)
ffffffffc0205996:	69aa                	ld	s3,136(sp)
ffffffffc0205998:	7ae6                	ld	s5,120(sp)
ffffffffc020599a:	7b46                	ld	s6,112(sp)
ffffffffc020599c:	7ba6                	ld	s7,104(sp)
ffffffffc020599e:	7c06                	ld	s8,96(sp)
ffffffffc02059a0:	6ce6                	ld	s9,88(sp)
ffffffffc02059a2:	6d46                	ld	s10,80(sp)
ffffffffc02059a4:	6da6                	ld	s11,72(sp)
ffffffffc02059a6:	8552                	mv	a0,s4
ffffffffc02059a8:	6a0a                	ld	s4,128(sp)
ffffffffc02059aa:	614d                	addi	sp,sp,176
ffffffffc02059ac:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc02059ae:	463d                	li	a2,15
ffffffffc02059b0:	85ca                	mv	a1,s2
ffffffffc02059b2:	1808                	addi	a0,sp,48
ffffffffc02059b4:	439000ef          	jal	ra,ffffffffc02065ec <memcpy>
    if (mm != NULL) {
ffffffffc02059b8:	e20993e3          	bnez	s3,ffffffffc02057de <do_execve+0x62>
    if (current->mm != NULL) {
ffffffffc02059bc:	000db783          	ld	a5,0(s11)
ffffffffc02059c0:	779c                	ld	a5,40(a5)
ffffffffc02059c2:	e4078ae3          	beqz	a5,ffffffffc0205816 <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc02059c6:	00003617          	auipc	a2,0x3
ffffffffc02059ca:	caa60613          	addi	a2,a2,-854 # ffffffffc0208670 <default_pmm_manager+0x12b8>
ffffffffc02059ce:	20d00593          	li	a1,525
ffffffffc02059d2:	00003517          	auipc	a0,0x3
ffffffffc02059d6:	ab650513          	addi	a0,a0,-1354 # ffffffffc0208488 <default_pmm_manager+0x10d0>
ffffffffc02059da:	aa1fa0ef          	jal	ra,ffffffffc020047a <__panic>
    put_pgdir(mm);
ffffffffc02059de:	8526                	mv	a0,s1
ffffffffc02059e0:	c14ff0ef          	jal	ra,ffffffffc0204df4 <put_pgdir>
    mm_destroy(mm);
ffffffffc02059e4:	8526                	mv	a0,s1
ffffffffc02059e6:	8effe0ef          	jal	ra,ffffffffc02042d4 <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc02059ea:	5a61                	li	s4,-8
    do_exit(ret);
ffffffffc02059ec:	8552                	mv	a0,s4
ffffffffc02059ee:	94fff0ef          	jal	ra,ffffffffc020533c <do_exit>
    int ret = -E_NO_MEM;
ffffffffc02059f2:	5a71                	li	s4,-4
ffffffffc02059f4:	bfe5                	j	ffffffffc02059ec <do_execve+0x270>
        if (ph->p_filesz > ph->p_memsz) {
ffffffffc02059f6:	0289b603          	ld	a2,40(s3)
ffffffffc02059fa:	0209b783          	ld	a5,32(s3)
ffffffffc02059fe:	1cf66d63          	bltu	a2,a5,ffffffffc0205bd8 <do_execve+0x45c>
        if (ph->p_flags & ELF_PF_X) vm_flags |= VM_EXEC;
ffffffffc0205a02:	0049a783          	lw	a5,4(s3)
ffffffffc0205a06:	0017f693          	andi	a3,a5,1
ffffffffc0205a0a:	c291                	beqz	a3,ffffffffc0205a0e <do_execve+0x292>
ffffffffc0205a0c:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205a0e:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205a12:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205a14:	e779                	bnez	a4,ffffffffc0205ae2 <do_execve+0x366>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0205a16:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205a18:	c781                	beqz	a5,ffffffffc0205a20 <do_execve+0x2a4>
ffffffffc0205a1a:	0016e693          	ori	a3,a3,1
        if (vm_flags & VM_READ) perm |= PTE_R;
ffffffffc0205a1e:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R);
ffffffffc0205a20:	0026f793          	andi	a5,a3,2
ffffffffc0205a24:	e3f1                	bnez	a5,ffffffffc0205ae8 <do_execve+0x36c>
        if (vm_flags & VM_EXEC) perm |= PTE_X;
ffffffffc0205a26:	0046f793          	andi	a5,a3,4
ffffffffc0205a2a:	c399                	beqz	a5,ffffffffc0205a30 <do_execve+0x2b4>
ffffffffc0205a2c:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0) {
ffffffffc0205a30:	0109b583          	ld	a1,16(s3)
ffffffffc0205a34:	4701                	li	a4,0
ffffffffc0205a36:	8526                	mv	a0,s1
ffffffffc0205a38:	8effe0ef          	jal	ra,ffffffffc0204326 <mm_map>
ffffffffc0205a3c:	8a2a                	mv	s4,a0
ffffffffc0205a3e:	ed35                	bnez	a0,ffffffffc0205aba <do_execve+0x33e>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205a40:	0109bb83          	ld	s7,16(s3)
ffffffffc0205a44:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0205a46:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205a4a:	0089b903          	ld	s2,8(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205a4e:	00fbfab3          	and	s5,s7,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205a52:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc0205a54:	9a5e                	add	s4,s4,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205a56:	993e                	add	s2,s2,a5
        while (start < end) {
ffffffffc0205a58:	054be963          	bltu	s7,s4,ffffffffc0205aaa <do_execve+0x32e>
ffffffffc0205a5c:	aa95                	j	ffffffffc0205bd0 <do_execve+0x454>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205a5e:	6785                	lui	a5,0x1
ffffffffc0205a60:	415b8533          	sub	a0,s7,s5
ffffffffc0205a64:	9abe                	add	s5,s5,a5
ffffffffc0205a66:	417a8633          	sub	a2,s5,s7
            if (end < la) {
ffffffffc0205a6a:	015a7463          	bgeu	s4,s5,ffffffffc0205a72 <do_execve+0x2f6>
                size -= la - end;
ffffffffc0205a6e:	417a0633          	sub	a2,s4,s7
    return page - pages + nbase;
ffffffffc0205a72:	000cb683          	ld	a3,0(s9)
ffffffffc0205a76:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0205a78:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0205a7c:	40d406b3          	sub	a3,s0,a3
ffffffffc0205a80:	8699                	srai	a3,a3,0x6
ffffffffc0205a82:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205a84:	67e2                	ld	a5,24(sp)
ffffffffc0205a86:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205a8a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205a8c:	14b87863          	bgeu	a6,a1,ffffffffc0205bdc <do_execve+0x460>
ffffffffc0205a90:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205a94:	85ca                	mv	a1,s2
            start += size, from += size;
ffffffffc0205a96:	9bb2                	add	s7,s7,a2
ffffffffc0205a98:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205a9a:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0205a9c:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205a9e:	34f000ef          	jal	ra,ffffffffc02065ec <memcpy>
            start += size, from += size;
ffffffffc0205aa2:	6622                	ld	a2,8(sp)
ffffffffc0205aa4:	9932                	add	s2,s2,a2
        while (start < end) {
ffffffffc0205aa6:	054bf363          	bgeu	s7,s4,ffffffffc0205aec <do_execve+0x370>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
ffffffffc0205aaa:	6c88                	ld	a0,24(s1)
ffffffffc0205aac:	866a                	mv	a2,s10
ffffffffc0205aae:	85d6                	mv	a1,s5
ffffffffc0205ab0:	8cbfd0ef          	jal	ra,ffffffffc020337a <pgdir_alloc_page>
ffffffffc0205ab4:	842a                	mv	s0,a0
ffffffffc0205ab6:	f545                	bnez	a0,ffffffffc0205a5e <do_execve+0x2e2>
        ret = -E_NO_MEM;
ffffffffc0205ab8:	5a71                	li	s4,-4
    exit_mmap(mm);
ffffffffc0205aba:	8526                	mv	a0,s1
ffffffffc0205abc:	9b5fe0ef          	jal	ra,ffffffffc0204470 <exit_mmap>
    put_pgdir(mm);
ffffffffc0205ac0:	8526                	mv	a0,s1
ffffffffc0205ac2:	b32ff0ef          	jal	ra,ffffffffc0204df4 <put_pgdir>
    mm_destroy(mm);
ffffffffc0205ac6:	8526                	mv	a0,s1
ffffffffc0205ac8:	80dfe0ef          	jal	ra,ffffffffc02042d4 <mm_destroy>
    return ret;
ffffffffc0205acc:	b705                	j	ffffffffc02059ec <do_execve+0x270>
            exit_mmap(mm);
ffffffffc0205ace:	854e                	mv	a0,s3
ffffffffc0205ad0:	9a1fe0ef          	jal	ra,ffffffffc0204470 <exit_mmap>
            put_pgdir(mm);
ffffffffc0205ad4:	854e                	mv	a0,s3
ffffffffc0205ad6:	b1eff0ef          	jal	ra,ffffffffc0204df4 <put_pgdir>
            mm_destroy(mm);
ffffffffc0205ada:	854e                	mv	a0,s3
ffffffffc0205adc:	ff8fe0ef          	jal	ra,ffffffffc02042d4 <mm_destroy>
ffffffffc0205ae0:	b33d                	j	ffffffffc020580e <do_execve+0x92>
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205ae2:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205ae6:	fb95                	bnez	a5,ffffffffc0205a1a <do_execve+0x29e>
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R);
ffffffffc0205ae8:	4d5d                	li	s10,23
ffffffffc0205aea:	bf35                	j	ffffffffc0205a26 <do_execve+0x2aa>
        end = ph->p_va + ph->p_memsz;
ffffffffc0205aec:	0109b683          	ld	a3,16(s3)
ffffffffc0205af0:	0289b903          	ld	s2,40(s3)
ffffffffc0205af4:	9936                	add	s2,s2,a3
        if (start < la) {
ffffffffc0205af6:	075bfd63          	bgeu	s7,s5,ffffffffc0205b70 <do_execve+0x3f4>
            if (start == end) {
ffffffffc0205afa:	dd7901e3          	beq	s2,s7,ffffffffc02058bc <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0205afe:	6785                	lui	a5,0x1
ffffffffc0205b00:	00fb8533          	add	a0,s7,a5
ffffffffc0205b04:	41550533          	sub	a0,a0,s5
                size -= la - end;
ffffffffc0205b08:	41790a33          	sub	s4,s2,s7
            if (end < la) {
ffffffffc0205b0c:	0b597d63          	bgeu	s2,s5,ffffffffc0205bc6 <do_execve+0x44a>
    return page - pages + nbase;
ffffffffc0205b10:	000cb683          	ld	a3,0(s9)
ffffffffc0205b14:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0205b16:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0205b1a:	40d406b3          	sub	a3,s0,a3
ffffffffc0205b1e:	8699                	srai	a3,a3,0x6
ffffffffc0205b20:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205b22:	67e2                	ld	a5,24(sp)
ffffffffc0205b24:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205b28:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205b2a:	0ac5f963          	bgeu	a1,a2,ffffffffc0205bdc <do_execve+0x460>
ffffffffc0205b2e:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0205b32:	8652                	mv	a2,s4
ffffffffc0205b34:	4581                	li	a1,0
ffffffffc0205b36:	96c2                	add	a3,a3,a6
ffffffffc0205b38:	9536                	add	a0,a0,a3
ffffffffc0205b3a:	2a1000ef          	jal	ra,ffffffffc02065da <memset>
            start += size;
ffffffffc0205b3e:	017a0733          	add	a4,s4,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0205b42:	03597463          	bgeu	s2,s5,ffffffffc0205b6a <do_execve+0x3ee>
ffffffffc0205b46:	d6e90be3          	beq	s2,a4,ffffffffc02058bc <do_execve+0x140>
ffffffffc0205b4a:	00003697          	auipc	a3,0x3
ffffffffc0205b4e:	b4e68693          	addi	a3,a3,-1202 # ffffffffc0208698 <default_pmm_manager+0x12e0>
ffffffffc0205b52:	00001617          	auipc	a2,0x1
ffffffffc0205b56:	16e60613          	addi	a2,a2,366 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0205b5a:	26200593          	li	a1,610
ffffffffc0205b5e:	00003517          	auipc	a0,0x3
ffffffffc0205b62:	92a50513          	addi	a0,a0,-1750 # ffffffffc0208488 <default_pmm_manager+0x10d0>
ffffffffc0205b66:	915fa0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc0205b6a:	ff5710e3          	bne	a4,s5,ffffffffc0205b4a <do_execve+0x3ce>
ffffffffc0205b6e:	8bd6                	mv	s7,s5
        while (start < end) {
ffffffffc0205b70:	d52bf6e3          	bgeu	s7,s2,ffffffffc02058bc <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
ffffffffc0205b74:	6c88                	ld	a0,24(s1)
ffffffffc0205b76:	866a                	mv	a2,s10
ffffffffc0205b78:	85d6                	mv	a1,s5
ffffffffc0205b7a:	801fd0ef          	jal	ra,ffffffffc020337a <pgdir_alloc_page>
ffffffffc0205b7e:	842a                	mv	s0,a0
ffffffffc0205b80:	dd05                	beqz	a0,ffffffffc0205ab8 <do_execve+0x33c>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205b82:	6785                	lui	a5,0x1
ffffffffc0205b84:	415b8533          	sub	a0,s7,s5
ffffffffc0205b88:	9abe                	add	s5,s5,a5
ffffffffc0205b8a:	417a8633          	sub	a2,s5,s7
            if (end < la) {
ffffffffc0205b8e:	01597463          	bgeu	s2,s5,ffffffffc0205b96 <do_execve+0x41a>
                size -= la - end;
ffffffffc0205b92:	41790633          	sub	a2,s2,s7
    return page - pages + nbase;
ffffffffc0205b96:	000cb683          	ld	a3,0(s9)
ffffffffc0205b9a:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0205b9c:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0205ba0:	40d406b3          	sub	a3,s0,a3
ffffffffc0205ba4:	8699                	srai	a3,a3,0x6
ffffffffc0205ba6:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205ba8:	67e2                	ld	a5,24(sp)
ffffffffc0205baa:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205bae:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205bb0:	02b87663          	bgeu	a6,a1,ffffffffc0205bdc <do_execve+0x460>
ffffffffc0205bb4:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0205bb8:	4581                	li	a1,0
            start += size;
ffffffffc0205bba:	9bb2                	add	s7,s7,a2
ffffffffc0205bbc:	96c2                	add	a3,a3,a6
            memset(page2kva(page) + off, 0, size);
ffffffffc0205bbe:	9536                	add	a0,a0,a3
ffffffffc0205bc0:	21b000ef          	jal	ra,ffffffffc02065da <memset>
ffffffffc0205bc4:	b775                	j	ffffffffc0205b70 <do_execve+0x3f4>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0205bc6:	417a8a33          	sub	s4,s5,s7
ffffffffc0205bca:	b799                	j	ffffffffc0205b10 <do_execve+0x394>
        return -E_INVAL;
ffffffffc0205bcc:	5a75                	li	s4,-3
ffffffffc0205bce:	b3c1                	j	ffffffffc020598e <do_execve+0x212>
        while (start < end) {
ffffffffc0205bd0:	86de                	mv	a3,s7
ffffffffc0205bd2:	bf39                	j	ffffffffc0205af0 <do_execve+0x374>
    int ret = -E_NO_MEM;
ffffffffc0205bd4:	5a71                	li	s4,-4
ffffffffc0205bd6:	bdc5                	j	ffffffffc0205ac6 <do_execve+0x34a>
            ret = -E_INVAL_ELF;
ffffffffc0205bd8:	5a61                	li	s4,-8
ffffffffc0205bda:	b5c5                	j	ffffffffc0205aba <do_execve+0x33e>
ffffffffc0205bdc:	00002617          	auipc	a2,0x2
ffffffffc0205be0:	81460613          	addi	a2,a2,-2028 # ffffffffc02073f0 <default_pmm_manager+0x38>
ffffffffc0205be4:	06900593          	li	a1,105
ffffffffc0205be8:	00002517          	auipc	a0,0x2
ffffffffc0205bec:	83050513          	addi	a0,a0,-2000 # ffffffffc0207418 <default_pmm_manager+0x60>
ffffffffc0205bf0:	88bfa0ef          	jal	ra,ffffffffc020047a <__panic>
    current->cr3 = PADDR(mm->pgdir);
ffffffffc0205bf4:	00002617          	auipc	a2,0x2
ffffffffc0205bf8:	8a460613          	addi	a2,a2,-1884 # ffffffffc0207498 <default_pmm_manager+0xe0>
ffffffffc0205bfc:	27d00593          	li	a1,637
ffffffffc0205c00:	00003517          	auipc	a0,0x3
ffffffffc0205c04:	88850513          	addi	a0,a0,-1912 # ffffffffc0208488 <default_pmm_manager+0x10d0>
ffffffffc0205c08:	873fa0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-4*PGSIZE , PTE_USER) != NULL);
ffffffffc0205c0c:	00003697          	auipc	a3,0x3
ffffffffc0205c10:	ba468693          	addi	a3,a3,-1116 # ffffffffc02087b0 <default_pmm_manager+0x13f8>
ffffffffc0205c14:	00001617          	auipc	a2,0x1
ffffffffc0205c18:	0ac60613          	addi	a2,a2,172 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0205c1c:	27800593          	li	a1,632
ffffffffc0205c20:	00003517          	auipc	a0,0x3
ffffffffc0205c24:	86850513          	addi	a0,a0,-1944 # ffffffffc0208488 <default_pmm_manager+0x10d0>
ffffffffc0205c28:	853fa0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-3*PGSIZE , PTE_USER) != NULL);
ffffffffc0205c2c:	00003697          	auipc	a3,0x3
ffffffffc0205c30:	b3c68693          	addi	a3,a3,-1220 # ffffffffc0208768 <default_pmm_manager+0x13b0>
ffffffffc0205c34:	00001617          	auipc	a2,0x1
ffffffffc0205c38:	08c60613          	addi	a2,a2,140 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0205c3c:	27700593          	li	a1,631
ffffffffc0205c40:	00003517          	auipc	a0,0x3
ffffffffc0205c44:	84850513          	addi	a0,a0,-1976 # ffffffffc0208488 <default_pmm_manager+0x10d0>
ffffffffc0205c48:	833fa0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-2*PGSIZE , PTE_USER) != NULL);
ffffffffc0205c4c:	00003697          	auipc	a3,0x3
ffffffffc0205c50:	ad468693          	addi	a3,a3,-1324 # ffffffffc0208720 <default_pmm_manager+0x1368>
ffffffffc0205c54:	00001617          	auipc	a2,0x1
ffffffffc0205c58:	06c60613          	addi	a2,a2,108 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0205c5c:	27600593          	li	a1,630
ffffffffc0205c60:	00003517          	auipc	a0,0x3
ffffffffc0205c64:	82850513          	addi	a0,a0,-2008 # ffffffffc0208488 <default_pmm_manager+0x10d0>
ffffffffc0205c68:	813fa0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-PGSIZE , PTE_USER) != NULL);
ffffffffc0205c6c:	00003697          	auipc	a3,0x3
ffffffffc0205c70:	a6c68693          	addi	a3,a3,-1428 # ffffffffc02086d8 <default_pmm_manager+0x1320>
ffffffffc0205c74:	00001617          	auipc	a2,0x1
ffffffffc0205c78:	04c60613          	addi	a2,a2,76 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0205c7c:	27500593          	li	a1,629
ffffffffc0205c80:	00003517          	auipc	a0,0x3
ffffffffc0205c84:	80850513          	addi	a0,a0,-2040 # ffffffffc0208488 <default_pmm_manager+0x10d0>
ffffffffc0205c88:	ff2fa0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0205c8c <do_yield>:
    current->need_resched = 1;
ffffffffc0205c8c:	000ad797          	auipc	a5,0xad
ffffffffc0205c90:	df47b783          	ld	a5,-524(a5) # ffffffffc02b2a80 <current>
ffffffffc0205c94:	4705                	li	a4,1
ffffffffc0205c96:	ef98                	sd	a4,24(a5)
}
ffffffffc0205c98:	4501                	li	a0,0
ffffffffc0205c9a:	8082                	ret

ffffffffc0205c9c <do_wait>:
do_wait(int pid, int *code_store) {
ffffffffc0205c9c:	1101                	addi	sp,sp,-32
ffffffffc0205c9e:	e822                	sd	s0,16(sp)
ffffffffc0205ca0:	e426                	sd	s1,8(sp)
ffffffffc0205ca2:	ec06                	sd	ra,24(sp)
ffffffffc0205ca4:	842e                	mv	s0,a1
ffffffffc0205ca6:	84aa                	mv	s1,a0
    if (code_store != NULL) {
ffffffffc0205ca8:	c999                	beqz	a1,ffffffffc0205cbe <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0205caa:	000ad797          	auipc	a5,0xad
ffffffffc0205cae:	dd67b783          	ld	a5,-554(a5) # ffffffffc02b2a80 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1)) {
ffffffffc0205cb2:	7788                	ld	a0,40(a5)
ffffffffc0205cb4:	4685                	li	a3,1
ffffffffc0205cb6:	4611                	li	a2,4
ffffffffc0205cb8:	e4ffe0ef          	jal	ra,ffffffffc0204b06 <user_mem_check>
ffffffffc0205cbc:	c909                	beqz	a0,ffffffffc0205cce <do_wait+0x32>
ffffffffc0205cbe:	85a2                	mv	a1,s0
}
ffffffffc0205cc0:	6442                	ld	s0,16(sp)
ffffffffc0205cc2:	60e2                	ld	ra,24(sp)
ffffffffc0205cc4:	8526                	mv	a0,s1
ffffffffc0205cc6:	64a2                	ld	s1,8(sp)
ffffffffc0205cc8:	6105                	addi	sp,sp,32
ffffffffc0205cca:	fbcff06f          	j	ffffffffc0205486 <do_wait.part.0>
ffffffffc0205cce:	60e2                	ld	ra,24(sp)
ffffffffc0205cd0:	6442                	ld	s0,16(sp)
ffffffffc0205cd2:	64a2                	ld	s1,8(sp)
ffffffffc0205cd4:	5575                	li	a0,-3
ffffffffc0205cd6:	6105                	addi	sp,sp,32
ffffffffc0205cd8:	8082                	ret

ffffffffc0205cda <do_kill>:
do_kill(int pid) {
ffffffffc0205cda:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID) {
ffffffffc0205cdc:	6789                	lui	a5,0x2
do_kill(int pid) {
ffffffffc0205cde:	e406                	sd	ra,8(sp)
ffffffffc0205ce0:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID) {
ffffffffc0205ce2:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205ce6:	17f9                	addi	a5,a5,-2
ffffffffc0205ce8:	02e7e863          	bltu	a5,a4,ffffffffc0205d18 <do_kill+0x3e>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205cec:	842a                	mv	s0,a0
ffffffffc0205cee:	45a9                	li	a1,10
ffffffffc0205cf0:	2501                	sext.w	a0,a0
ffffffffc0205cf2:	468000ef          	jal	ra,ffffffffc020615a <hash32>
ffffffffc0205cf6:	02051693          	slli	a3,a0,0x20
ffffffffc0205cfa:	82f1                	srli	a3,a3,0x1c
ffffffffc0205cfc:	000a9797          	auipc	a5,0xa9
ffffffffc0205d00:	cfc78793          	addi	a5,a5,-772 # ffffffffc02ae9f8 <hash_list>
ffffffffc0205d04:	96be                	add	a3,a3,a5
ffffffffc0205d06:	8536                	mv	a0,a3
        while ((le = list_next(le)) != list) {
ffffffffc0205d08:	a029                	j	ffffffffc0205d12 <do_kill+0x38>
            if (proc->pid == pid) {
ffffffffc0205d0a:	f2c52703          	lw	a4,-212(a0)
ffffffffc0205d0e:	00870b63          	beq	a4,s0,ffffffffc0205d24 <do_kill+0x4a>
ffffffffc0205d12:	6508                	ld	a0,8(a0)
        while ((le = list_next(le)) != list) {
ffffffffc0205d14:	fea69be3          	bne	a3,a0,ffffffffc0205d0a <do_kill+0x30>
    return -E_INVAL;
ffffffffc0205d18:	5475                	li	s0,-3
}
ffffffffc0205d1a:	60a2                	ld	ra,8(sp)
ffffffffc0205d1c:	8522                	mv	a0,s0
ffffffffc0205d1e:	6402                	ld	s0,0(sp)
ffffffffc0205d20:	0141                	addi	sp,sp,16
ffffffffc0205d22:	8082                	ret
        if (!(proc->flags & PF_EXITING)) {
ffffffffc0205d24:	fd852703          	lw	a4,-40(a0)
ffffffffc0205d28:	00177693          	andi	a3,a4,1
ffffffffc0205d2c:	e295                	bnez	a3,ffffffffc0205d50 <do_kill+0x76>
            if (proc->wait_state & WT_INTERRUPTED) {
ffffffffc0205d2e:	4954                	lw	a3,20(a0)
            proc->flags |= PF_EXITING;
ffffffffc0205d30:	00176713          	ori	a4,a4,1
ffffffffc0205d34:	fce52c23          	sw	a4,-40(a0)
            return 0;
ffffffffc0205d38:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED) {
ffffffffc0205d3a:	fe06d0e3          	bgez	a3,ffffffffc0205d1a <do_kill+0x40>
                wakeup_proc(proc);
ffffffffc0205d3e:	f2850513          	addi	a0,a0,-216
ffffffffc0205d42:	22c000ef          	jal	ra,ffffffffc0205f6e <wakeup_proc>
}
ffffffffc0205d46:	60a2                	ld	ra,8(sp)
ffffffffc0205d48:	8522                	mv	a0,s0
ffffffffc0205d4a:	6402                	ld	s0,0(sp)
ffffffffc0205d4c:	0141                	addi	sp,sp,16
ffffffffc0205d4e:	8082                	ret
        return -E_KILLED;
ffffffffc0205d50:	545d                	li	s0,-9
ffffffffc0205d52:	b7e1                	j	ffffffffc0205d1a <do_kill+0x40>

ffffffffc0205d54 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and 
//           - create the second kernel thread init_main
void
proc_init(void) {
ffffffffc0205d54:	1101                	addi	sp,sp,-32
ffffffffc0205d56:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0205d58:	000ad797          	auipc	a5,0xad
ffffffffc0205d5c:	ca078793          	addi	a5,a5,-864 # ffffffffc02b29f8 <proc_list>
ffffffffc0205d60:	ec06                	sd	ra,24(sp)
ffffffffc0205d62:	e822                	sd	s0,16(sp)
ffffffffc0205d64:	e04a                	sd	s2,0(sp)
ffffffffc0205d66:	000a9497          	auipc	s1,0xa9
ffffffffc0205d6a:	c9248493          	addi	s1,s1,-878 # ffffffffc02ae9f8 <hash_list>
ffffffffc0205d6e:	e79c                	sd	a5,8(a5)
ffffffffc0205d70:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i ++) {
ffffffffc0205d72:	000ad717          	auipc	a4,0xad
ffffffffc0205d76:	c8670713          	addi	a4,a4,-890 # ffffffffc02b29f8 <proc_list>
ffffffffc0205d7a:	87a6                	mv	a5,s1
ffffffffc0205d7c:	e79c                	sd	a5,8(a5)
ffffffffc0205d7e:	e39c                	sd	a5,0(a5)
ffffffffc0205d80:	07c1                	addi	a5,a5,16
ffffffffc0205d82:	fef71de3          	bne	a4,a5,ffffffffc0205d7c <proc_init+0x28>
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL) {
ffffffffc0205d86:	f71fe0ef          	jal	ra,ffffffffc0204cf6 <alloc_proc>
ffffffffc0205d8a:	000ad917          	auipc	s2,0xad
ffffffffc0205d8e:	cfe90913          	addi	s2,s2,-770 # ffffffffc02b2a88 <idleproc>
ffffffffc0205d92:	00a93023          	sd	a0,0(s2)
ffffffffc0205d96:	0e050e63          	beqz	a0,ffffffffc0205e92 <proc_init+0x13e>
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0205d9a:	4789                	li	a5,2
ffffffffc0205d9c:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205d9e:	00003797          	auipc	a5,0x3
ffffffffc0205da2:	26278793          	addi	a5,a5,610 # ffffffffc0209000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205da6:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205daa:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc0205dac:	4785                	li	a5,1
ffffffffc0205dae:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205db0:	4641                	li	a2,16
ffffffffc0205db2:	4581                	li	a1,0
ffffffffc0205db4:	8522                	mv	a0,s0
ffffffffc0205db6:	025000ef          	jal	ra,ffffffffc02065da <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205dba:	463d                	li	a2,15
ffffffffc0205dbc:	00003597          	auipc	a1,0x3
ffffffffc0205dc0:	a5458593          	addi	a1,a1,-1452 # ffffffffc0208810 <default_pmm_manager+0x1458>
ffffffffc0205dc4:	8522                	mv	a0,s0
ffffffffc0205dc6:	027000ef          	jal	ra,ffffffffc02065ec <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process ++;
ffffffffc0205dca:	000ad717          	auipc	a4,0xad
ffffffffc0205dce:	cce70713          	addi	a4,a4,-818 # ffffffffc02b2a98 <nr_process>
ffffffffc0205dd2:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0205dd4:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205dd8:	4601                	li	a2,0
    nr_process ++;
ffffffffc0205dda:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205ddc:	4581                	li	a1,0
ffffffffc0205dde:	00000517          	auipc	a0,0x0
ffffffffc0205de2:	87a50513          	addi	a0,a0,-1926 # ffffffffc0205658 <init_main>
    nr_process ++;
ffffffffc0205de6:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0205de8:	000ad797          	auipc	a5,0xad
ffffffffc0205dec:	c8d7bc23          	sd	a3,-872(a5) # ffffffffc02b2a80 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205df0:	cfcff0ef          	jal	ra,ffffffffc02052ec <kernel_thread>
ffffffffc0205df4:	842a                	mv	s0,a0
    if (pid <= 0) {
ffffffffc0205df6:	08a05263          	blez	a0,ffffffffc0205e7a <proc_init+0x126>
    if (0 < pid && pid < MAX_PID) {
ffffffffc0205dfa:	6789                	lui	a5,0x2
ffffffffc0205dfc:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205e00:	17f9                	addi	a5,a5,-2
ffffffffc0205e02:	2501                	sext.w	a0,a0
ffffffffc0205e04:	02e7e263          	bltu	a5,a4,ffffffffc0205e28 <proc_init+0xd4>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205e08:	45a9                	li	a1,10
ffffffffc0205e0a:	350000ef          	jal	ra,ffffffffc020615a <hash32>
ffffffffc0205e0e:	02051693          	slli	a3,a0,0x20
ffffffffc0205e12:	82f1                	srli	a3,a3,0x1c
ffffffffc0205e14:	96a6                	add	a3,a3,s1
ffffffffc0205e16:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list) {
ffffffffc0205e18:	a029                	j	ffffffffc0205e22 <proc_init+0xce>
            if (proc->pid == pid) {
ffffffffc0205e1a:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7ca4>
ffffffffc0205e1e:	04870b63          	beq	a4,s0,ffffffffc0205e74 <proc_init+0x120>
    return listelm->next;
ffffffffc0205e22:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc0205e24:	fef69be3          	bne	a3,a5,ffffffffc0205e1a <proc_init+0xc6>
    return NULL;
ffffffffc0205e28:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205e2a:	0b478493          	addi	s1,a5,180
ffffffffc0205e2e:	4641                	li	a2,16
ffffffffc0205e30:	4581                	li	a1,0
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0205e32:	000ad417          	auipc	s0,0xad
ffffffffc0205e36:	c5e40413          	addi	s0,s0,-930 # ffffffffc02b2a90 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205e3a:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0205e3c:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205e3e:	79c000ef          	jal	ra,ffffffffc02065da <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205e42:	463d                	li	a2,15
ffffffffc0205e44:	00003597          	auipc	a1,0x3
ffffffffc0205e48:	9f458593          	addi	a1,a1,-1548 # ffffffffc0208838 <default_pmm_manager+0x1480>
ffffffffc0205e4c:	8526                	mv	a0,s1
ffffffffc0205e4e:	79e000ef          	jal	ra,ffffffffc02065ec <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205e52:	00093783          	ld	a5,0(s2)
ffffffffc0205e56:	cbb5                	beqz	a5,ffffffffc0205eca <proc_init+0x176>
ffffffffc0205e58:	43dc                	lw	a5,4(a5)
ffffffffc0205e5a:	eba5                	bnez	a5,ffffffffc0205eca <proc_init+0x176>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205e5c:	601c                	ld	a5,0(s0)
ffffffffc0205e5e:	c7b1                	beqz	a5,ffffffffc0205eaa <proc_init+0x156>
ffffffffc0205e60:	43d8                	lw	a4,4(a5)
ffffffffc0205e62:	4785                	li	a5,1
ffffffffc0205e64:	04f71363          	bne	a4,a5,ffffffffc0205eaa <proc_init+0x156>
}
ffffffffc0205e68:	60e2                	ld	ra,24(sp)
ffffffffc0205e6a:	6442                	ld	s0,16(sp)
ffffffffc0205e6c:	64a2                	ld	s1,8(sp)
ffffffffc0205e6e:	6902                	ld	s2,0(sp)
ffffffffc0205e70:	6105                	addi	sp,sp,32
ffffffffc0205e72:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0205e74:	f2878793          	addi	a5,a5,-216
ffffffffc0205e78:	bf4d                	j	ffffffffc0205e2a <proc_init+0xd6>
        panic("create init_main failed.\n");
ffffffffc0205e7a:	00003617          	auipc	a2,0x3
ffffffffc0205e7e:	99e60613          	addi	a2,a2,-1634 # ffffffffc0208818 <default_pmm_manager+0x1460>
ffffffffc0205e82:	38200593          	li	a1,898
ffffffffc0205e86:	00002517          	auipc	a0,0x2
ffffffffc0205e8a:	60250513          	addi	a0,a0,1538 # ffffffffc0208488 <default_pmm_manager+0x10d0>
ffffffffc0205e8e:	decfa0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0205e92:	00003617          	auipc	a2,0x3
ffffffffc0205e96:	96660613          	addi	a2,a2,-1690 # ffffffffc02087f8 <default_pmm_manager+0x1440>
ffffffffc0205e9a:	37400593          	li	a1,884
ffffffffc0205e9e:	00002517          	auipc	a0,0x2
ffffffffc0205ea2:	5ea50513          	addi	a0,a0,1514 # ffffffffc0208488 <default_pmm_manager+0x10d0>
ffffffffc0205ea6:	dd4fa0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205eaa:	00003697          	auipc	a3,0x3
ffffffffc0205eae:	9be68693          	addi	a3,a3,-1602 # ffffffffc0208868 <default_pmm_manager+0x14b0>
ffffffffc0205eb2:	00001617          	auipc	a2,0x1
ffffffffc0205eb6:	e0e60613          	addi	a2,a2,-498 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0205eba:	38900593          	li	a1,905
ffffffffc0205ebe:	00002517          	auipc	a0,0x2
ffffffffc0205ec2:	5ca50513          	addi	a0,a0,1482 # ffffffffc0208488 <default_pmm_manager+0x10d0>
ffffffffc0205ec6:	db4fa0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205eca:	00003697          	auipc	a3,0x3
ffffffffc0205ece:	97668693          	addi	a3,a3,-1674 # ffffffffc0208840 <default_pmm_manager+0x1488>
ffffffffc0205ed2:	00001617          	auipc	a2,0x1
ffffffffc0205ed6:	dee60613          	addi	a2,a2,-530 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0205eda:	38800593          	li	a1,904
ffffffffc0205ede:	00002517          	auipc	a0,0x2
ffffffffc0205ee2:	5aa50513          	addi	a0,a0,1450 # ffffffffc0208488 <default_pmm_manager+0x10d0>
ffffffffc0205ee6:	d94fa0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0205eea <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void
cpu_idle(void) {
ffffffffc0205eea:	1141                	addi	sp,sp,-16
ffffffffc0205eec:	e022                	sd	s0,0(sp)
ffffffffc0205eee:	e406                	sd	ra,8(sp)
ffffffffc0205ef0:	000ad417          	auipc	s0,0xad
ffffffffc0205ef4:	b9040413          	addi	s0,s0,-1136 # ffffffffc02b2a80 <current>
    while (1) {
        if (current->need_resched) {
ffffffffc0205ef8:	6018                	ld	a4,0(s0)
ffffffffc0205efa:	6f1c                	ld	a5,24(a4)
ffffffffc0205efc:	dffd                	beqz	a5,ffffffffc0205efa <cpu_idle+0x10>
            schedule();
ffffffffc0205efe:	0f0000ef          	jal	ra,ffffffffc0205fee <schedule>
ffffffffc0205f02:	bfdd                	j	ffffffffc0205ef8 <cpu_idle+0xe>

ffffffffc0205f04 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0205f04:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0205f08:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0205f0c:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0205f0e:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0205f10:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0205f14:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0205f18:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0205f1c:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0205f20:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0205f24:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0205f28:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0205f2c:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0205f30:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0205f34:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0205f38:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0205f3c:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0205f40:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0205f42:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0205f44:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0205f48:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0205f4c:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0205f50:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0205f54:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0205f58:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0205f5c:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0205f60:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0205f64:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0205f68:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0205f6c:	8082                	ret

ffffffffc0205f6e <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205f6e:	4118                	lw	a4,0(a0)
wakeup_proc(struct proc_struct *proc) {
ffffffffc0205f70:	1101                	addi	sp,sp,-32
ffffffffc0205f72:	ec06                	sd	ra,24(sp)
ffffffffc0205f74:	e822                	sd	s0,16(sp)
ffffffffc0205f76:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205f78:	478d                	li	a5,3
ffffffffc0205f7a:	04f70b63          	beq	a4,a5,ffffffffc0205fd0 <wakeup_proc+0x62>
ffffffffc0205f7e:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205f80:	100027f3          	csrr	a5,sstatus
ffffffffc0205f84:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205f86:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205f88:	ef9d                	bnez	a5,ffffffffc0205fc6 <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE) {
ffffffffc0205f8a:	4789                	li	a5,2
ffffffffc0205f8c:	02f70163          	beq	a4,a5,ffffffffc0205fae <wakeup_proc+0x40>
            proc->state = PROC_RUNNABLE;
ffffffffc0205f90:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc0205f92:	0e042623          	sw	zero,236(s0)
    if (flag) {
ffffffffc0205f96:	e491                	bnez	s1,ffffffffc0205fa2 <wakeup_proc+0x34>
        else {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205f98:	60e2                	ld	ra,24(sp)
ffffffffc0205f9a:	6442                	ld	s0,16(sp)
ffffffffc0205f9c:	64a2                	ld	s1,8(sp)
ffffffffc0205f9e:	6105                	addi	sp,sp,32
ffffffffc0205fa0:	8082                	ret
ffffffffc0205fa2:	6442                	ld	s0,16(sp)
ffffffffc0205fa4:	60e2                	ld	ra,24(sp)
ffffffffc0205fa6:	64a2                	ld	s1,8(sp)
ffffffffc0205fa8:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205faa:	e96fa06f          	j	ffffffffc0200640 <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc0205fae:	00003617          	auipc	a2,0x3
ffffffffc0205fb2:	91a60613          	addi	a2,a2,-1766 # ffffffffc02088c8 <default_pmm_manager+0x1510>
ffffffffc0205fb6:	45c9                	li	a1,18
ffffffffc0205fb8:	00003517          	auipc	a0,0x3
ffffffffc0205fbc:	8f850513          	addi	a0,a0,-1800 # ffffffffc02088b0 <default_pmm_manager+0x14f8>
ffffffffc0205fc0:	d22fa0ef          	jal	ra,ffffffffc02004e2 <__warn>
ffffffffc0205fc4:	bfc9                	j	ffffffffc0205f96 <wakeup_proc+0x28>
        intr_disable();
ffffffffc0205fc6:	e80fa0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        if (proc->state != PROC_RUNNABLE) {
ffffffffc0205fca:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc0205fcc:	4485                	li	s1,1
ffffffffc0205fce:	bf75                	j	ffffffffc0205f8a <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205fd0:	00003697          	auipc	a3,0x3
ffffffffc0205fd4:	8c068693          	addi	a3,a3,-1856 # ffffffffc0208890 <default_pmm_manager+0x14d8>
ffffffffc0205fd8:	00001617          	auipc	a2,0x1
ffffffffc0205fdc:	ce860613          	addi	a2,a2,-792 # ffffffffc0206cc0 <commands+0x450>
ffffffffc0205fe0:	45a5                	li	a1,9
ffffffffc0205fe2:	00003517          	auipc	a0,0x3
ffffffffc0205fe6:	8ce50513          	addi	a0,a0,-1842 # ffffffffc02088b0 <default_pmm_manager+0x14f8>
ffffffffc0205fea:	c90fa0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0205fee <schedule>:

void
schedule(void) {
ffffffffc0205fee:	1141                	addi	sp,sp,-16
ffffffffc0205ff0:	e406                	sd	ra,8(sp)
ffffffffc0205ff2:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205ff4:	100027f3          	csrr	a5,sstatus
ffffffffc0205ff8:	8b89                	andi	a5,a5,2
ffffffffc0205ffa:	4401                	li	s0,0
ffffffffc0205ffc:	efbd                	bnez	a5,ffffffffc020607a <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0205ffe:	000ad897          	auipc	a7,0xad
ffffffffc0206002:	a828b883          	ld	a7,-1406(a7) # ffffffffc02b2a80 <current>
ffffffffc0206006:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020600a:	000ad517          	auipc	a0,0xad
ffffffffc020600e:	a7e53503          	ld	a0,-1410(a0) # ffffffffc02b2a88 <idleproc>
ffffffffc0206012:	04a88e63          	beq	a7,a0,ffffffffc020606e <schedule+0x80>
ffffffffc0206016:	0c888693          	addi	a3,a7,200
ffffffffc020601a:	000ad617          	auipc	a2,0xad
ffffffffc020601e:	9de60613          	addi	a2,a2,-1570 # ffffffffc02b29f8 <proc_list>
        le = last;
ffffffffc0206022:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc0206024:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc0206026:	4809                	li	a6,2
ffffffffc0206028:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc020602a:	00c78863          	beq	a5,a2,ffffffffc020603a <schedule+0x4c>
                if (next->state == PROC_RUNNABLE) {
ffffffffc020602e:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc0206032:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc0206036:	03070163          	beq	a4,a6,ffffffffc0206058 <schedule+0x6a>
                    break;
                }
            }
        } while (le != last);
ffffffffc020603a:	fef697e3          	bne	a3,a5,ffffffffc0206028 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc020603e:	ed89                	bnez	a1,ffffffffc0206058 <schedule+0x6a>
            next = idleproc;
        }
        next->runs ++;
ffffffffc0206040:	451c                	lw	a5,8(a0)
ffffffffc0206042:	2785                	addiw	a5,a5,1
ffffffffc0206044:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc0206046:	00a88463          	beq	a7,a0,ffffffffc020604e <schedule+0x60>
            proc_run(next);
ffffffffc020604a:	e21fe0ef          	jal	ra,ffffffffc0204e6a <proc_run>
    if (flag) {
ffffffffc020604e:	e819                	bnez	s0,ffffffffc0206064 <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0206050:	60a2                	ld	ra,8(sp)
ffffffffc0206052:	6402                	ld	s0,0(sp)
ffffffffc0206054:	0141                	addi	sp,sp,16
ffffffffc0206056:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0206058:	4198                	lw	a4,0(a1)
ffffffffc020605a:	4789                	li	a5,2
ffffffffc020605c:	fef712e3          	bne	a4,a5,ffffffffc0206040 <schedule+0x52>
ffffffffc0206060:	852e                	mv	a0,a1
ffffffffc0206062:	bff9                	j	ffffffffc0206040 <schedule+0x52>
}
ffffffffc0206064:	6402                	ld	s0,0(sp)
ffffffffc0206066:	60a2                	ld	ra,8(sp)
ffffffffc0206068:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc020606a:	dd6fa06f          	j	ffffffffc0200640 <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020606e:	000ad617          	auipc	a2,0xad
ffffffffc0206072:	98a60613          	addi	a2,a2,-1654 # ffffffffc02b29f8 <proc_list>
ffffffffc0206076:	86b2                	mv	a3,a2
ffffffffc0206078:	b76d                	j	ffffffffc0206022 <schedule+0x34>
        intr_disable();
ffffffffc020607a:	dccfa0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        return 1;
ffffffffc020607e:	4405                	li	s0,1
ffffffffc0206080:	bfbd                	j	ffffffffc0205ffe <schedule+0x10>

ffffffffc0206082 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc0206082:	000ad797          	auipc	a5,0xad
ffffffffc0206086:	9fe7b783          	ld	a5,-1538(a5) # ffffffffc02b2a80 <current>
}
ffffffffc020608a:	43c8                	lw	a0,4(a5)
ffffffffc020608c:	8082                	ret

ffffffffc020608e <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc020608e:	4501                	li	a0,0
ffffffffc0206090:	8082                	ret

ffffffffc0206092 <sys_putc>:
    cputchar(c);
ffffffffc0206092:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc0206094:	1141                	addi	sp,sp,-16
ffffffffc0206096:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc0206098:	91efa0ef          	jal	ra,ffffffffc02001b6 <cputchar>
}
ffffffffc020609c:	60a2                	ld	ra,8(sp)
ffffffffc020609e:	4501                	li	a0,0
ffffffffc02060a0:	0141                	addi	sp,sp,16
ffffffffc02060a2:	8082                	ret

ffffffffc02060a4 <sys_kill>:
    return do_kill(pid);
ffffffffc02060a4:	4108                	lw	a0,0(a0)
ffffffffc02060a6:	c35ff06f          	j	ffffffffc0205cda <do_kill>

ffffffffc02060aa <sys_yield>:
    return do_yield();
ffffffffc02060aa:	be3ff06f          	j	ffffffffc0205c8c <do_yield>

ffffffffc02060ae <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc02060ae:	6d14                	ld	a3,24(a0)
ffffffffc02060b0:	6910                	ld	a2,16(a0)
ffffffffc02060b2:	650c                	ld	a1,8(a0)
ffffffffc02060b4:	6108                	ld	a0,0(a0)
ffffffffc02060b6:	ec6ff06f          	j	ffffffffc020577c <do_execve>

ffffffffc02060ba <sys_wait>:
    return do_wait(pid, store);
ffffffffc02060ba:	650c                	ld	a1,8(a0)
ffffffffc02060bc:	4108                	lw	a0,0(a0)
ffffffffc02060be:	bdfff06f          	j	ffffffffc0205c9c <do_wait>

ffffffffc02060c2 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc02060c2:	000ad797          	auipc	a5,0xad
ffffffffc02060c6:	9be7b783          	ld	a5,-1602(a5) # ffffffffc02b2a80 <current>
ffffffffc02060ca:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc02060cc:	4501                	li	a0,0
ffffffffc02060ce:	6a0c                	ld	a1,16(a2)
ffffffffc02060d0:	e07fe06f          	j	ffffffffc0204ed6 <do_fork>

ffffffffc02060d4 <sys_exit>:
    return do_exit(error_code);
ffffffffc02060d4:	4108                	lw	a0,0(a0)
ffffffffc02060d6:	a66ff06f          	j	ffffffffc020533c <do_exit>

ffffffffc02060da <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc02060da:	715d                	addi	sp,sp,-80
ffffffffc02060dc:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc02060de:	000ad497          	auipc	s1,0xad
ffffffffc02060e2:	9a248493          	addi	s1,s1,-1630 # ffffffffc02b2a80 <current>
ffffffffc02060e6:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc02060e8:	e0a2                	sd	s0,64(sp)
ffffffffc02060ea:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc02060ec:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc02060ee:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02060f0:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc02060f2:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02060f6:	0327ee63          	bltu	a5,s2,ffffffffc0206132 <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc02060fa:	00391713          	slli	a4,s2,0x3
ffffffffc02060fe:	00003797          	auipc	a5,0x3
ffffffffc0206102:	83278793          	addi	a5,a5,-1998 # ffffffffc0208930 <syscalls>
ffffffffc0206106:	97ba                	add	a5,a5,a4
ffffffffc0206108:	639c                	ld	a5,0(a5)
ffffffffc020610a:	c785                	beqz	a5,ffffffffc0206132 <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc020610c:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc020610e:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc0206110:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc0206112:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc0206114:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc0206116:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc0206118:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc020611a:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc020611c:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc020611e:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0206120:	0028                	addi	a0,sp,8
ffffffffc0206122:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc0206124:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0206126:	e828                	sd	a0,80(s0)
}
ffffffffc0206128:	6406                	ld	s0,64(sp)
ffffffffc020612a:	74e2                	ld	s1,56(sp)
ffffffffc020612c:	7942                	ld	s2,48(sp)
ffffffffc020612e:	6161                	addi	sp,sp,80
ffffffffc0206130:	8082                	ret
    print_trapframe(tf);
ffffffffc0206132:	8522                	mv	a0,s0
ffffffffc0206134:	f00fa0ef          	jal	ra,ffffffffc0200834 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc0206138:	609c                	ld	a5,0(s1)
ffffffffc020613a:	86ca                	mv	a3,s2
ffffffffc020613c:	00002617          	auipc	a2,0x2
ffffffffc0206140:	7ac60613          	addi	a2,a2,1964 # ffffffffc02088e8 <default_pmm_manager+0x1530>
ffffffffc0206144:	43d8                	lw	a4,4(a5)
ffffffffc0206146:	06200593          	li	a1,98
ffffffffc020614a:	0b478793          	addi	a5,a5,180
ffffffffc020614e:	00002517          	auipc	a0,0x2
ffffffffc0206152:	7ca50513          	addi	a0,a0,1994 # ffffffffc0208918 <default_pmm_manager+0x1560>
ffffffffc0206156:	b24fa0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc020615a <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc020615a:	9e3707b7          	lui	a5,0x9e370
ffffffffc020615e:	2785                	addiw	a5,a5,1
ffffffffc0206160:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc0206164:	02000793          	li	a5,32
ffffffffc0206168:	9f8d                	subw	a5,a5,a1
}
ffffffffc020616a:	00f5553b          	srlw	a0,a0,a5
ffffffffc020616e:	8082                	ret

ffffffffc0206170 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0206170:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0206174:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0206176:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020617a:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020617c:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0206180:	f022                	sd	s0,32(sp)
ffffffffc0206182:	ec26                	sd	s1,24(sp)
ffffffffc0206184:	e84a                	sd	s2,16(sp)
ffffffffc0206186:	f406                	sd	ra,40(sp)
ffffffffc0206188:	e44e                	sd	s3,8(sp)
ffffffffc020618a:	84aa                	mv	s1,a0
ffffffffc020618c:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020618e:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0206192:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0206194:	03067e63          	bgeu	a2,a6,ffffffffc02061d0 <printnum+0x60>
ffffffffc0206198:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020619a:	00805763          	blez	s0,ffffffffc02061a8 <printnum+0x38>
ffffffffc020619e:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02061a0:	85ca                	mv	a1,s2
ffffffffc02061a2:	854e                	mv	a0,s3
ffffffffc02061a4:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02061a6:	fc65                	bnez	s0,ffffffffc020619e <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02061a8:	1a02                	slli	s4,s4,0x20
ffffffffc02061aa:	00003797          	auipc	a5,0x3
ffffffffc02061ae:	88678793          	addi	a5,a5,-1914 # ffffffffc0208a30 <syscalls+0x100>
ffffffffc02061b2:	020a5a13          	srli	s4,s4,0x20
ffffffffc02061b6:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc02061b8:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02061ba:	000a4503          	lbu	a0,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bd0>
}
ffffffffc02061be:	70a2                	ld	ra,40(sp)
ffffffffc02061c0:	69a2                	ld	s3,8(sp)
ffffffffc02061c2:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02061c4:	85ca                	mv	a1,s2
ffffffffc02061c6:	87a6                	mv	a5,s1
}
ffffffffc02061c8:	6942                	ld	s2,16(sp)
ffffffffc02061ca:	64e2                	ld	s1,24(sp)
ffffffffc02061cc:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02061ce:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02061d0:	03065633          	divu	a2,a2,a6
ffffffffc02061d4:	8722                	mv	a4,s0
ffffffffc02061d6:	f9bff0ef          	jal	ra,ffffffffc0206170 <printnum>
ffffffffc02061da:	b7f9                	j	ffffffffc02061a8 <printnum+0x38>

ffffffffc02061dc <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02061dc:	7119                	addi	sp,sp,-128
ffffffffc02061de:	f4a6                	sd	s1,104(sp)
ffffffffc02061e0:	f0ca                	sd	s2,96(sp)
ffffffffc02061e2:	ecce                	sd	s3,88(sp)
ffffffffc02061e4:	e8d2                	sd	s4,80(sp)
ffffffffc02061e6:	e4d6                	sd	s5,72(sp)
ffffffffc02061e8:	e0da                	sd	s6,64(sp)
ffffffffc02061ea:	fc5e                	sd	s7,56(sp)
ffffffffc02061ec:	f06a                	sd	s10,32(sp)
ffffffffc02061ee:	fc86                	sd	ra,120(sp)
ffffffffc02061f0:	f8a2                	sd	s0,112(sp)
ffffffffc02061f2:	f862                	sd	s8,48(sp)
ffffffffc02061f4:	f466                	sd	s9,40(sp)
ffffffffc02061f6:	ec6e                	sd	s11,24(sp)
ffffffffc02061f8:	892a                	mv	s2,a0
ffffffffc02061fa:	84ae                	mv	s1,a1
ffffffffc02061fc:	8d32                	mv	s10,a2
ffffffffc02061fe:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0206200:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0206204:	5b7d                	li	s6,-1
ffffffffc0206206:	00003a97          	auipc	s5,0x3
ffffffffc020620a:	856a8a93          	addi	s5,s5,-1962 # ffffffffc0208a5c <syscalls+0x12c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020620e:	00003b97          	auipc	s7,0x3
ffffffffc0206212:	a6ab8b93          	addi	s7,s7,-1430 # ffffffffc0208c78 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0206216:	000d4503          	lbu	a0,0(s10)
ffffffffc020621a:	001d0413          	addi	s0,s10,1
ffffffffc020621e:	01350a63          	beq	a0,s3,ffffffffc0206232 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0206222:	c121                	beqz	a0,ffffffffc0206262 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0206224:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0206226:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0206228:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020622a:	fff44503          	lbu	a0,-1(s0)
ffffffffc020622e:	ff351ae3          	bne	a0,s3,ffffffffc0206222 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206232:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0206236:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc020623a:	4c81                	li	s9,0
ffffffffc020623c:	4881                	li	a7,0
        width = precision = -1;
ffffffffc020623e:	5c7d                	li	s8,-1
ffffffffc0206240:	5dfd                	li	s11,-1
ffffffffc0206242:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0206246:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206248:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020624c:	0ff5f593          	andi	a1,a1,255
ffffffffc0206250:	00140d13          	addi	s10,s0,1
ffffffffc0206254:	04b56263          	bltu	a0,a1,ffffffffc0206298 <vprintfmt+0xbc>
ffffffffc0206258:	058a                	slli	a1,a1,0x2
ffffffffc020625a:	95d6                	add	a1,a1,s5
ffffffffc020625c:	4194                	lw	a3,0(a1)
ffffffffc020625e:	96d6                	add	a3,a3,s5
ffffffffc0206260:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0206262:	70e6                	ld	ra,120(sp)
ffffffffc0206264:	7446                	ld	s0,112(sp)
ffffffffc0206266:	74a6                	ld	s1,104(sp)
ffffffffc0206268:	7906                	ld	s2,96(sp)
ffffffffc020626a:	69e6                	ld	s3,88(sp)
ffffffffc020626c:	6a46                	ld	s4,80(sp)
ffffffffc020626e:	6aa6                	ld	s5,72(sp)
ffffffffc0206270:	6b06                	ld	s6,64(sp)
ffffffffc0206272:	7be2                	ld	s7,56(sp)
ffffffffc0206274:	7c42                	ld	s8,48(sp)
ffffffffc0206276:	7ca2                	ld	s9,40(sp)
ffffffffc0206278:	7d02                	ld	s10,32(sp)
ffffffffc020627a:	6de2                	ld	s11,24(sp)
ffffffffc020627c:	6109                	addi	sp,sp,128
ffffffffc020627e:	8082                	ret
            padc = '0';
ffffffffc0206280:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0206282:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206286:	846a                	mv	s0,s10
ffffffffc0206288:	00140d13          	addi	s10,s0,1
ffffffffc020628c:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0206290:	0ff5f593          	andi	a1,a1,255
ffffffffc0206294:	fcb572e3          	bgeu	a0,a1,ffffffffc0206258 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0206298:	85a6                	mv	a1,s1
ffffffffc020629a:	02500513          	li	a0,37
ffffffffc020629e:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02062a0:	fff44783          	lbu	a5,-1(s0)
ffffffffc02062a4:	8d22                	mv	s10,s0
ffffffffc02062a6:	f73788e3          	beq	a5,s3,ffffffffc0206216 <vprintfmt+0x3a>
ffffffffc02062aa:	ffed4783          	lbu	a5,-2(s10)
ffffffffc02062ae:	1d7d                	addi	s10,s10,-1
ffffffffc02062b0:	ff379de3          	bne	a5,s3,ffffffffc02062aa <vprintfmt+0xce>
ffffffffc02062b4:	b78d                	j	ffffffffc0206216 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc02062b6:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc02062ba:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02062be:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02062c0:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02062c4:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02062c8:	02d86463          	bltu	a6,a3,ffffffffc02062f0 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc02062cc:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02062d0:	002c169b          	slliw	a3,s8,0x2
ffffffffc02062d4:	0186873b          	addw	a4,a3,s8
ffffffffc02062d8:	0017171b          	slliw	a4,a4,0x1
ffffffffc02062dc:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02062de:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02062e2:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02062e4:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02062e8:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02062ec:	fed870e3          	bgeu	a6,a3,ffffffffc02062cc <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02062f0:	f40ddce3          	bgez	s11,ffffffffc0206248 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02062f4:	8de2                	mv	s11,s8
ffffffffc02062f6:	5c7d                	li	s8,-1
ffffffffc02062f8:	bf81                	j	ffffffffc0206248 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02062fa:	fffdc693          	not	a3,s11
ffffffffc02062fe:	96fd                	srai	a3,a3,0x3f
ffffffffc0206300:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206304:	00144603          	lbu	a2,1(s0)
ffffffffc0206308:	2d81                	sext.w	s11,s11
ffffffffc020630a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020630c:	bf35                	j	ffffffffc0206248 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc020630e:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206312:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0206316:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206318:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc020631a:	bfd9                	j	ffffffffc02062f0 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc020631c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020631e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0206322:	01174463          	blt	a4,a7,ffffffffc020632a <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0206326:	1a088e63          	beqz	a7,ffffffffc02064e2 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc020632a:	000a3603          	ld	a2,0(s4)
ffffffffc020632e:	46c1                	li	a3,16
ffffffffc0206330:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0206332:	2781                	sext.w	a5,a5
ffffffffc0206334:	876e                	mv	a4,s11
ffffffffc0206336:	85a6                	mv	a1,s1
ffffffffc0206338:	854a                	mv	a0,s2
ffffffffc020633a:	e37ff0ef          	jal	ra,ffffffffc0206170 <printnum>
            break;
ffffffffc020633e:	bde1                	j	ffffffffc0206216 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0206340:	000a2503          	lw	a0,0(s4)
ffffffffc0206344:	85a6                	mv	a1,s1
ffffffffc0206346:	0a21                	addi	s4,s4,8
ffffffffc0206348:	9902                	jalr	s2
            break;
ffffffffc020634a:	b5f1                	j	ffffffffc0206216 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020634c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020634e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0206352:	01174463          	blt	a4,a7,ffffffffc020635a <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0206356:	18088163          	beqz	a7,ffffffffc02064d8 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc020635a:	000a3603          	ld	a2,0(s4)
ffffffffc020635e:	46a9                	li	a3,10
ffffffffc0206360:	8a2e                	mv	s4,a1
ffffffffc0206362:	bfc1                	j	ffffffffc0206332 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206364:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0206368:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020636a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020636c:	bdf1                	j	ffffffffc0206248 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc020636e:	85a6                	mv	a1,s1
ffffffffc0206370:	02500513          	li	a0,37
ffffffffc0206374:	9902                	jalr	s2
            break;
ffffffffc0206376:	b545                	j	ffffffffc0206216 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206378:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc020637c:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020637e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0206380:	b5e1                	j	ffffffffc0206248 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0206382:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0206384:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0206388:	01174463          	blt	a4,a7,ffffffffc0206390 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc020638c:	14088163          	beqz	a7,ffffffffc02064ce <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0206390:	000a3603          	ld	a2,0(s4)
ffffffffc0206394:	46a1                	li	a3,8
ffffffffc0206396:	8a2e                	mv	s4,a1
ffffffffc0206398:	bf69                	j	ffffffffc0206332 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc020639a:	03000513          	li	a0,48
ffffffffc020639e:	85a6                	mv	a1,s1
ffffffffc02063a0:	e03e                	sd	a5,0(sp)
ffffffffc02063a2:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02063a4:	85a6                	mv	a1,s1
ffffffffc02063a6:	07800513          	li	a0,120
ffffffffc02063aa:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02063ac:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02063ae:	6782                	ld	a5,0(sp)
ffffffffc02063b0:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02063b2:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc02063b6:	bfb5                	j	ffffffffc0206332 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02063b8:	000a3403          	ld	s0,0(s4)
ffffffffc02063bc:	008a0713          	addi	a4,s4,8
ffffffffc02063c0:	e03a                	sd	a4,0(sp)
ffffffffc02063c2:	14040263          	beqz	s0,ffffffffc0206506 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc02063c6:	0fb05763          	blez	s11,ffffffffc02064b4 <vprintfmt+0x2d8>
ffffffffc02063ca:	02d00693          	li	a3,45
ffffffffc02063ce:	0cd79163          	bne	a5,a3,ffffffffc0206490 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02063d2:	00044783          	lbu	a5,0(s0)
ffffffffc02063d6:	0007851b          	sext.w	a0,a5
ffffffffc02063da:	cf85                	beqz	a5,ffffffffc0206412 <vprintfmt+0x236>
ffffffffc02063dc:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02063e0:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02063e4:	000c4563          	bltz	s8,ffffffffc02063ee <vprintfmt+0x212>
ffffffffc02063e8:	3c7d                	addiw	s8,s8,-1
ffffffffc02063ea:	036c0263          	beq	s8,s6,ffffffffc020640e <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02063ee:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02063f0:	0e0c8e63          	beqz	s9,ffffffffc02064ec <vprintfmt+0x310>
ffffffffc02063f4:	3781                	addiw	a5,a5,-32
ffffffffc02063f6:	0ef47b63          	bgeu	s0,a5,ffffffffc02064ec <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02063fa:	03f00513          	li	a0,63
ffffffffc02063fe:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0206400:	000a4783          	lbu	a5,0(s4)
ffffffffc0206404:	3dfd                	addiw	s11,s11,-1
ffffffffc0206406:	0a05                	addi	s4,s4,1
ffffffffc0206408:	0007851b          	sext.w	a0,a5
ffffffffc020640c:	ffe1                	bnez	a5,ffffffffc02063e4 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc020640e:	01b05963          	blez	s11,ffffffffc0206420 <vprintfmt+0x244>
ffffffffc0206412:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0206414:	85a6                	mv	a1,s1
ffffffffc0206416:	02000513          	li	a0,32
ffffffffc020641a:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020641c:	fe0d9be3          	bnez	s11,ffffffffc0206412 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0206420:	6a02                	ld	s4,0(sp)
ffffffffc0206422:	bbd5                	j	ffffffffc0206216 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0206424:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0206426:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc020642a:	01174463          	blt	a4,a7,ffffffffc0206432 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc020642e:	08088d63          	beqz	a7,ffffffffc02064c8 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0206432:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0206436:	0a044d63          	bltz	s0,ffffffffc02064f0 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc020643a:	8622                	mv	a2,s0
ffffffffc020643c:	8a66                	mv	s4,s9
ffffffffc020643e:	46a9                	li	a3,10
ffffffffc0206440:	bdcd                	j	ffffffffc0206332 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0206442:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0206446:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc0206448:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc020644a:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc020644e:	8fb5                	xor	a5,a5,a3
ffffffffc0206450:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0206454:	02d74163          	blt	a4,a3,ffffffffc0206476 <vprintfmt+0x29a>
ffffffffc0206458:	00369793          	slli	a5,a3,0x3
ffffffffc020645c:	97de                	add	a5,a5,s7
ffffffffc020645e:	639c                	ld	a5,0(a5)
ffffffffc0206460:	cb99                	beqz	a5,ffffffffc0206476 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0206462:	86be                	mv	a3,a5
ffffffffc0206464:	00000617          	auipc	a2,0x0
ffffffffc0206468:	1cc60613          	addi	a2,a2,460 # ffffffffc0206630 <etext+0x2c>
ffffffffc020646c:	85a6                	mv	a1,s1
ffffffffc020646e:	854a                	mv	a0,s2
ffffffffc0206470:	0ce000ef          	jal	ra,ffffffffc020653e <printfmt>
ffffffffc0206474:	b34d                	j	ffffffffc0206216 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0206476:	00002617          	auipc	a2,0x2
ffffffffc020647a:	5da60613          	addi	a2,a2,1498 # ffffffffc0208a50 <syscalls+0x120>
ffffffffc020647e:	85a6                	mv	a1,s1
ffffffffc0206480:	854a                	mv	a0,s2
ffffffffc0206482:	0bc000ef          	jal	ra,ffffffffc020653e <printfmt>
ffffffffc0206486:	bb41                	j	ffffffffc0206216 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0206488:	00002417          	auipc	s0,0x2
ffffffffc020648c:	5c040413          	addi	s0,s0,1472 # ffffffffc0208a48 <syscalls+0x118>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0206490:	85e2                	mv	a1,s8
ffffffffc0206492:	8522                	mv	a0,s0
ffffffffc0206494:	e43e                	sd	a5,8(sp)
ffffffffc0206496:	0e2000ef          	jal	ra,ffffffffc0206578 <strnlen>
ffffffffc020649a:	40ad8dbb          	subw	s11,s11,a0
ffffffffc020649e:	01b05b63          	blez	s11,ffffffffc02064b4 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc02064a2:	67a2                	ld	a5,8(sp)
ffffffffc02064a4:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02064a8:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02064aa:	85a6                	mv	a1,s1
ffffffffc02064ac:	8552                	mv	a0,s4
ffffffffc02064ae:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02064b0:	fe0d9ce3          	bnez	s11,ffffffffc02064a8 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02064b4:	00044783          	lbu	a5,0(s0)
ffffffffc02064b8:	00140a13          	addi	s4,s0,1
ffffffffc02064bc:	0007851b          	sext.w	a0,a5
ffffffffc02064c0:	d3a5                	beqz	a5,ffffffffc0206420 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02064c2:	05e00413          	li	s0,94
ffffffffc02064c6:	bf39                	j	ffffffffc02063e4 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc02064c8:	000a2403          	lw	s0,0(s4)
ffffffffc02064cc:	b7ad                	j	ffffffffc0206436 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc02064ce:	000a6603          	lwu	a2,0(s4)
ffffffffc02064d2:	46a1                	li	a3,8
ffffffffc02064d4:	8a2e                	mv	s4,a1
ffffffffc02064d6:	bdb1                	j	ffffffffc0206332 <vprintfmt+0x156>
ffffffffc02064d8:	000a6603          	lwu	a2,0(s4)
ffffffffc02064dc:	46a9                	li	a3,10
ffffffffc02064de:	8a2e                	mv	s4,a1
ffffffffc02064e0:	bd89                	j	ffffffffc0206332 <vprintfmt+0x156>
ffffffffc02064e2:	000a6603          	lwu	a2,0(s4)
ffffffffc02064e6:	46c1                	li	a3,16
ffffffffc02064e8:	8a2e                	mv	s4,a1
ffffffffc02064ea:	b5a1                	j	ffffffffc0206332 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02064ec:	9902                	jalr	s2
ffffffffc02064ee:	bf09                	j	ffffffffc0206400 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02064f0:	85a6                	mv	a1,s1
ffffffffc02064f2:	02d00513          	li	a0,45
ffffffffc02064f6:	e03e                	sd	a5,0(sp)
ffffffffc02064f8:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02064fa:	6782                	ld	a5,0(sp)
ffffffffc02064fc:	8a66                	mv	s4,s9
ffffffffc02064fe:	40800633          	neg	a2,s0
ffffffffc0206502:	46a9                	li	a3,10
ffffffffc0206504:	b53d                	j	ffffffffc0206332 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0206506:	03b05163          	blez	s11,ffffffffc0206528 <vprintfmt+0x34c>
ffffffffc020650a:	02d00693          	li	a3,45
ffffffffc020650e:	f6d79de3          	bne	a5,a3,ffffffffc0206488 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0206512:	00002417          	auipc	s0,0x2
ffffffffc0206516:	53640413          	addi	s0,s0,1334 # ffffffffc0208a48 <syscalls+0x118>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020651a:	02800793          	li	a5,40
ffffffffc020651e:	02800513          	li	a0,40
ffffffffc0206522:	00140a13          	addi	s4,s0,1
ffffffffc0206526:	bd6d                	j	ffffffffc02063e0 <vprintfmt+0x204>
ffffffffc0206528:	00002a17          	auipc	s4,0x2
ffffffffc020652c:	521a0a13          	addi	s4,s4,1313 # ffffffffc0208a49 <syscalls+0x119>
ffffffffc0206530:	02800513          	li	a0,40
ffffffffc0206534:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0206538:	05e00413          	li	s0,94
ffffffffc020653c:	b565                	j	ffffffffc02063e4 <vprintfmt+0x208>

ffffffffc020653e <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020653e:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0206540:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0206544:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0206546:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0206548:	ec06                	sd	ra,24(sp)
ffffffffc020654a:	f83a                	sd	a4,48(sp)
ffffffffc020654c:	fc3e                	sd	a5,56(sp)
ffffffffc020654e:	e0c2                	sd	a6,64(sp)
ffffffffc0206550:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0206552:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0206554:	c89ff0ef          	jal	ra,ffffffffc02061dc <vprintfmt>
}
ffffffffc0206558:	60e2                	ld	ra,24(sp)
ffffffffc020655a:	6161                	addi	sp,sp,80
ffffffffc020655c:	8082                	ret

ffffffffc020655e <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc020655e:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0206562:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0206564:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0206566:	cb81                	beqz	a5,ffffffffc0206576 <strlen+0x18>
        cnt ++;
ffffffffc0206568:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc020656a:	00a707b3          	add	a5,a4,a0
ffffffffc020656e:	0007c783          	lbu	a5,0(a5)
ffffffffc0206572:	fbfd                	bnez	a5,ffffffffc0206568 <strlen+0xa>
ffffffffc0206574:	8082                	ret
    }
    return cnt;
}
ffffffffc0206576:	8082                	ret

ffffffffc0206578 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0206578:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc020657a:	e589                	bnez	a1,ffffffffc0206584 <strnlen+0xc>
ffffffffc020657c:	a811                	j	ffffffffc0206590 <strnlen+0x18>
        cnt ++;
ffffffffc020657e:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0206580:	00f58863          	beq	a1,a5,ffffffffc0206590 <strnlen+0x18>
ffffffffc0206584:	00f50733          	add	a4,a0,a5
ffffffffc0206588:	00074703          	lbu	a4,0(a4)
ffffffffc020658c:	fb6d                	bnez	a4,ffffffffc020657e <strnlen+0x6>
ffffffffc020658e:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0206590:	852e                	mv	a0,a1
ffffffffc0206592:	8082                	ret

ffffffffc0206594 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0206594:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0206596:	0005c703          	lbu	a4,0(a1)
ffffffffc020659a:	0785                	addi	a5,a5,1
ffffffffc020659c:	0585                	addi	a1,a1,1
ffffffffc020659e:	fee78fa3          	sb	a4,-1(a5)
ffffffffc02065a2:	fb75                	bnez	a4,ffffffffc0206596 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc02065a4:	8082                	ret

ffffffffc02065a6 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02065a6:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02065aa:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02065ae:	cb89                	beqz	a5,ffffffffc02065c0 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc02065b0:	0505                	addi	a0,a0,1
ffffffffc02065b2:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02065b4:	fee789e3          	beq	a5,a4,ffffffffc02065a6 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02065b8:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02065bc:	9d19                	subw	a0,a0,a4
ffffffffc02065be:	8082                	ret
ffffffffc02065c0:	4501                	li	a0,0
ffffffffc02065c2:	bfed                	j	ffffffffc02065bc <strcmp+0x16>

ffffffffc02065c4 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02065c4:	00054783          	lbu	a5,0(a0)
ffffffffc02065c8:	c799                	beqz	a5,ffffffffc02065d6 <strchr+0x12>
        if (*s == c) {
ffffffffc02065ca:	00f58763          	beq	a1,a5,ffffffffc02065d8 <strchr+0x14>
    while (*s != '\0') {
ffffffffc02065ce:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc02065d2:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc02065d4:	fbfd                	bnez	a5,ffffffffc02065ca <strchr+0x6>
    }
    return NULL;
ffffffffc02065d6:	4501                	li	a0,0
}
ffffffffc02065d8:	8082                	ret

ffffffffc02065da <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02065da:	ca01                	beqz	a2,ffffffffc02065ea <memset+0x10>
ffffffffc02065dc:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02065de:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02065e0:	0785                	addi	a5,a5,1
ffffffffc02065e2:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02065e6:	fec79de3          	bne	a5,a2,ffffffffc02065e0 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02065ea:	8082                	ret

ffffffffc02065ec <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc02065ec:	ca19                	beqz	a2,ffffffffc0206602 <memcpy+0x16>
ffffffffc02065ee:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc02065f0:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc02065f2:	0005c703          	lbu	a4,0(a1)
ffffffffc02065f6:	0585                	addi	a1,a1,1
ffffffffc02065f8:	0785                	addi	a5,a5,1
ffffffffc02065fa:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc02065fe:	fec59ae3          	bne	a1,a2,ffffffffc02065f2 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0206602:	8082                	ret
