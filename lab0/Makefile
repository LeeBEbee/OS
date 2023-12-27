# 设置项目名为lab1，和项目大小
PROJ	:= lab1
EMPTY	:=
SPACE	:= $(EMPTY) $(EMPTY)
SLASH	:= /

V       := @

# 设置GCC前缀，如果没有定义的话，默认为riscv64-unknown-elf-
#ifndef GCCPREFIX
GCCPREFIX := riscv64-unknown-elf-
#endif

# 设置QEMU，如果没有定义的话，默认为qemu-system-riscv64
ifndef QEMU
QEMU := qemu-system-riscv64
endif


# eliminate default suffix rules
.SUFFIXES: .c .S .h


# delete target files if there is an error (or make is interrupted)
.DELETE_ON_ERROR:


# define compiler and flags
HOSTCC		:= gcc
HOSTCFLAGS	:= -Wall -O2

GDB		:= $(GCCPREFIX)gdb

CC		:= $(GCCPREFIX)gcc
CFLAGS  := -mcmodel=medany -std=gnu99 -Wno-unused -Werror
CFLAGS	+= -fno-builtin -Wall -O2 -nostdinc $(DEFS)
CFLAGS	+= -fno-stack-protector -ffunction-sections -fdata-sections
CFLAGS	+= -g
CTYPE	:= c S

# 定义链接器和链接标志
LD      := $(GCCPREFIX)ld
LDFLAGS	:= -m elf64lriscv
LDFLAGS	+= -nostdlib --gc-sections

OBJCOPY := $(GCCPREFIX)objcopy
OBJDUMP := $(GCCPREFIX)objdump

# 定义一些常用的命令
COPY	:= cp
MKDIR   := mkdir -p
MV		:= mv
RM		:= rm -f
AWK		:= awk
SED		:= sed
SH		:= sh
TR		:= tr
TOUCH	:= touch -c

# 定义对象目录和二进制目录
OBJDIR	:= obj
BINDIR	:= bin

ALLOBJS	:=
ALLDEPS	:=
TARGETS	:=

# 包含外部的makefile文件
include tools/function.mk

listf_cc = $(call listf,$(1),$(CTYPE))

# 定义一些函数用来操作文件
# for cc
add_files_cc = $(call add_files,$(1),$(CC),$(CFLAGS) $(3),$(2),$(4))
create_target_cc = $(call create_target,$(1),$(2),$(3),$(CC),$(CFLAGS))

# for hostcc
add_files_host = $(call add_files,$(1),$(HOSTCC),$(HOSTCFLAGS),$(2),$(3))
create_target_host = $(call create_target,$(1),$(2),$(3),$(HOSTCC),$(HOSTCFLAGS))

cgtype = $(patsubst %.$(2),%.$(3),$(1))
objfile = $(call toobj,$(1))
asmfile = $(call cgtype,$(call toobj,$(1)),o,asm)
outfile = $(call cgtype,$(call toobj,$(1)),o,out)
symfile = $(call cgtype,$(call toobj,$(1)),o,sym)

# 定义一个shell函数用来匹配模式
# for match pattern
match = $(shell echo $(2) | $(AWK) '{for(i=1;i<=NF;i++){if(match("$(1)","^"$$(i)"$$")){exit 1;}}}'; echo $$?)

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# include kernel/user

INCLUDE	+= libs 

CFLAGS	+= $(addprefix -I,$(INCLUDE))

LIBDIR	+= libs

$(call add_files_cc,$(call listf_cc,$(LIBDIR)),libs,)

# -------------------------------------------------------------------
# kernel
# 添加包含的内核头文件目录
KINCLUDE	+= kern/debug/ \
			   kern/driver/ \
			   kern/trap/ \
			   kern/libs/\
			   kern/mm/ \
			   kern/arch/

# 添加内核源代码目录
KSRCDIR		+= kern/init \
			   kern/debug \
			   kern/libs \
			   kern/driver \
			   kern/trap \
			   kern/mm

# 将包含的目录添加到编译器标志中
KCFLAGS		+= $(addprefix -I,$(KINCLUDE))

# 添加所有的.c文件，并将它们编译为.o文件
$(call add_files_cc,$(call listf_cc,$(KSRCDIR)),kernel,$(KCFLAGS))

# 读取“kernel”和“libs”包中的对象文件
KOBJS	= $(call read_packet,kernel libs)

# create kernel target
kernel = $(call totarget,kernel)

# “kernel”目标依赖于“tools/kernel.ld”
$(kernel): tools/kernel.ld

$(kernel): $(KOBJS)
	@echo + ld $@
	$(V)$(LD) $(LDFLAGS) -T tools/kernel.ld -o $@ $(KOBJS)
	@$(OBJDUMP) -S $@ > $(call asmfile,kernel)
	@$(OBJDUMP) -t $@ | $(SED) '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > $(call symfile,kernel)

# 创建“kernel”目标
$(call create_target,kernel)

# -------------------------------------------------------------------
# create ucore.img
UCOREIMG	:= $(call totarget,ucore.img)


$(UCOREIMG): $(kernel)
	$(OBJCOPY) $(kernel) --strip-all -O binary $@

$(call create_target,ucore.img)

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

$(call finish_all)

# 忽略所有依赖的目标

IGNORE_ALLDEPS	= clean \
				  dist-clean \
				  grade \
				  touch \
				  print-.+ \
				  handin

# 如果当前的Make命令目标不在IGNORE_ALLDEPS列表中，则包含所有的依赖
ifeq ($(call match,$(MAKECMDGOALS),$(IGNORE_ALLDEPS)),0)
-include $(ALLDEPS)
endif

# files for grade script

# 定义所有目标文件
TARGETS: $(TARGETS)

# 设置默认目标为TARGETS
.DEFAULT_GOAL := TARGETS

# 声明qemu为伪目标
.PHONY: qemu 
qemu: $(UCOREIMG) $(SWAPIMG) $(SFSIMG)
#	$(V)$(QEMU) -kernel $(UCOREIMG) -nographic
	$(V)$(QEMU) \
		-machine virt \
		-nographic \
		-bios default \
		-device loader,file=$(UCOREIMG),addr=0x80200000

#addr=0x80200000指定了内核映像在内存中的加载地址

debug: $(UCOREIMG) $(SWAPIMG) $(SFSIMG)
	$(V)$(QEMU) \
		-machine virt \
		-nographic \
		-bios default \
		-device loader,file=$(UCOREIMG),addr=0x80200000\
		-s -S

gdb:
	riscv64-unknown-elf-gdb \
    -ex 'file bin/kernel' \
    -ex 'set arch riscv:rv64' \
    -ex 'target remote localhost:1234'

	
.PHONY: grade touch
#这行声明了grade和touch是伪目标

GRADE_GDB_IN	:= .gdb.in
GRADE_QEMU_OUT	:= .qemu.out
HANDIN			:= proj$(PROJ)-handin.tar.gz

TOUCH_FILES		:= kern/trap/trap.c

MAKEOPTS		:= --quiet --no-print-directory

grade:
	$(V)$(MAKE) $(MAKEOPTS) clean
	$(V)$(SH) tools/grade.sh

touch:
	$(V)$(foreach f,$(TOUCH_FILES),$(TOUCH) $(f))

print-%:
	@echo $($(shell echo $(patsubst print-%,%,$@) | $(TR) [a-z] [A-Z]))

.PHONY: clean dist-clean handin packall tags
clean:
	$(V)$(RM) $(GRADE_GDB_IN) $(GRADE_QEMU_OUT) cscope* tags
	-$(RM) -r $(OBJDIR) $(BINDIR)

dist-clean: clean
	-$(RM) $(HANDIN)

handin: packall
	@echo Please visit http://learn.tsinghua.edu.cn and upload $(HANDIN). Thanks!

packall: clean
	@$(RM) -f $(HANDIN)
	@tar -czf $(HANDIN) `find . -type f -o -type d | grep -v '^\.*$$' | grep -vF '$(HANDIN)'`

tags:
	@echo TAGS ALL
	$(V)rm -f cscope.files cscope.in.out cscope.out cscope.po.out tags
	$(V)find . -type f -name "*.[chS]" >cscope.files
	$(V)cscope -bq 
	$(V)ctags -L cscope.files
