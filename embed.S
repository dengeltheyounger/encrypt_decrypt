.section	.bss
	.lcomm	buffer, 512
.section	.text
	.global	main
main:
	pushq	%rbp
	movq	%rsp, %rbp
# This part of the program opens the target file and parses the elf header
# for now it is assumed that a target is provided over command line
open_file:
	# open syscall
	leal	(2), %eax
	# rsi contains argv array, add second element to rdi
	movq	8(%rsi), %rdi
	# rsi should not have any flags
	xorl	%esi, %esi
	xorl	%edx, %edx
	syscall
	cmp		$0, %rax
	jl		exit
load_magic:
	# lead fd into edi
	leal	(%eax), %edi
	# read syscall
	leal	(0), %eax
	# load buffer into rsi
	leaq	buffer(%rip), %rsi
	# read four bytes
	leal	(4), %edx
	syscall
check_magic:
	# clear ecx in order to store bytes
	xorl	%ecx, %ecx
	# store buffer in rdx
	leaq	buffer(%rip), %rdx
	movb	(%rdx), %cl
	# check for 0x7f part of header
	cmp		$0x7f, %cl
	jne		exit
	# move to next index
	incq	%rdx
	movb	(%rdx), %cl
	# check for E
	cmp		$'E', %cl
	jne		exit
	# move to next buffer
	incq	%rdx
	movb	(%rdx), %cl
	cmp		$'L', %cl
	jne		exit
	incq	%rdx
	movb	(%rdx), %cl
	cmp		$'F', %cl
	jne		exit
move_after_magic:
	# lseek syscall
	leal	(8), %eax
	# fd was stored in edi
	# 4 bytes offset
	leal	(4), %esi
	# offset is relative to beginning of file
	leal	(0), %edx
	syscall
load_after_magic:
	# read syscall
	leal	(0), %eax
	# rdi contains fd
	# rsi contains buffer
	leaq	buffer(%rip), %rsi
	leal	(2), %edx
	# get next two parts from header
	syscall
check_after_magic:
	# ecx will contain class and data
	xorl	%ecx, %ecx
	# edx will contain buffer
	leaq	buffer(%rip), %rdx
	# load class into ecx
	movb	(%rdx), %cl
	# check to make sure that the machine is 64 bit
	cmp		$2, %cl
	jne		exit
	# move to data
	incq	%rdx
	# store in cl
	movb	(%rdx), %cl
	# check to make sure that machine is little endian
	cmp		$1, %cl
move_type:
	# lseek syscall
	leal	(8), %eax
	# fd stored in edi
	# go to offset 16
	leal	(0x10), %esi
	# offset is relative to beginning of file
	leal	(0), %edx
	syscall
load_type:
	# read syscall
	leal	(0), %eax
	# rdi contains fd
	# rsi contains buffer
	leaq	buffer(%rip), %rsi
	leal	(2), %edx
	# get the two bytes that represent the object file type
	syscall
check_type:
	# ecx will contain the object file type
	xorl	%ecx, %ecx
	# load buffer into rdx
	leaq	buffer(%rip), %rdx
	# move half word into %ecx
	movw	(%rdx), %cx
	# check if executable
	cmp		$0x02, %cx
	je		good_type
	# check if dyn, which is how PIE is usually interpreted
	cmp		$0x03, %cx
	jne		exit
move_section_entry:
	leal	(8), %eax
	# fd stored in edi
	# go to offset 0x28
	leal	(0x28), %esi
	# offset if relative to beginning of file
	leal	(0), %edx
	syscall
load_section_entry:
	# read syscall
	leal	(0), %eax
	# rdi contains fd
	# rsi contains buffer
	leaq	buffer(%rip), %rsi
	# get 8 bytes
	leal	(8), %edx
	syscall
get_section_entry:
	# ecx will contain the offset of section header table
	leal	%ecx, %ecx
	# load buffer into rdx
	leaq	buffer(%rip), %rdx
	movq	(%rdx), %rcx
	# save
	pushq	%rcx
exit:
	movq	%rbp, %rsp
	popq	%rbp
	ret
