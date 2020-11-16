.section	.data
	hello_world:	.asciz "Hello world!\n"
	hello_size = . - hello_world
	main_pre_encrypt:	.asciz "main routine before encryption:\n"
	main_pre_size = . - main_pre_encrypt
	main_post_encrypt:	.asciz "main routine after encryption:\n"
	main_post_size = . - main_post_encrypt
	main_post_decrypt:	.asciz "main routine after decryption:\n"
	main_decrypt_size = . - main_post_decrypt

.section	.text
	.global	main
	.extern	print_instructions
	
main:
	jmp	encrypt
after_decrypt:
	pushq	%rbp		# function prologue
	movq	%rsp, %rbp
	leaq	hello_world(%rip), %rsi	# address of buffer to print 
	movq	$hello_size, %rdx	# string length in rdx
	leal	(1), %edi	# stdout
	leal	(1), %eax	# write syscall
	syscall
	movq	%rbp, %rsp	# function epilogue
	popq	%rbp
	ret
encrypt:
	leaq	main_pre_encrypt(%rip), %rsi	# address of buffer to print
	movq	$main_pre_size, %rdx			# number of bytes to write
	leal	(1), %edi						# stdout
	leal	(1), %eax						# write syscall
	syscall
	leaq	encrypt_loop(%rip), %rcx		# everything will be encrypted up to encrypt_loop
	leaq	main(%rip), %rdx
	subq	%rdx, %rcx			# size of main routine
	pushq	%rbx				# save this to store number of bytes
	leaq	(%rcx), %rbx		# save number of bytes in rbx
	leaq	main(%rip), %rdi	# address of "buffer"
	leaq	(%rcx), %rsi		# number of bytes
	call	print_instructions
	leaq	main(%rip), %rdi	# store main address for mprotect call
	xorl	%esi, %esi			# change protections for the whole page
	leal	(0x07), %edx		# make page read, write, and executable
	jmp		change_protections
# before encrypting, it is necessary to get the page size and make it writable
get_page_size:
	# preserve callee saved registers
	pushq	%rbx
	pushq	%r12
	pushq	%r13
	pushq	%r14
	# this will be used to hold the page table size
	leal	(4096), %ebx
	# this will contain the address returned by mmap
	xorl	%r12d, %r12d
	# This will hold the result of munmap
	xorl	%r13d, %r13d
	# used for lea
	xorl	%r14d, %r14d
size_loop:
	# set address to zero. Kernel will choose
	xorl	%edi, %edi
	# twice ebx goes into length
	leaq	(%r14,%rbx,2), %rsi
	# PROT_NONE
	leal	(0x0), %edx
	# MAP_ANONYMOUS | MAP_PRIVATE
	leaq	(0x22), %r10
	# don't care about the file descriptor
	leaq	(-1), %r8
	# no offset from address
	leaq	(0), %r9
	# 9 for mmap syscall
	leal	(9), %eax
	syscall
	# check to see if a valid address was returned
	cmp		$0, %rax
	# indicate that mapping was bad
	jle		map_failed
	# save the address in r12
	leaq	(%rax), %r12
	# store the address in rdi for munmap syscall
	leaq	(%rax), %rdi
	# store address + n in rdi
	addq	%rbx, %rdi
	# length
	leaq	(%rbx), %rsi
	# munmap syscall
	leal	(11), %eax
	syscall
	# result stored in eax, save it in %r13
	leaq	(%rax), %r13
	# put the address back into rdi for munmap syscall
	leaq	(%r12), %rdi
	# twice n is put into rsi for total length allocated
	leaq	(%r14,%rbx,2), %rsi
	# munmap syscall number
	leal	(11), %eax
	syscall
	cmp		$0, %r13
	je		got_page_size
	# multiply rbx by 2
	salq	%rbx
	jmp		size_loop
got_page_size:
	leaq	(%rbx), %rax
	popq	%r14
	popq	%r13
	popq	%r12
	popq	%rbx
	# we've gotten this far, return page size to change_protections
	jmp		align_address
change_protections:
	# save the arguments getting page size
	pushq	%rdi
	pushq	%rsi
	pushq	%rdx
	jmp		get_page_size
align_address:
	# restore arguments after making function call
	popq	%rdx
	popq	%rsi
	popq	%rdi
	# negate the page size
	negq	%rax
	# and it with rdi in order to align rdi on page boundary
	andq	%rax, %rdi
	cmp		$0, %rsi
	jnz		call_mprotect
	# rax is now positive to reflect length argument
	negq	%rax
	# set the length argument
	leaq	(%rax), %rsi
call_mprotect:
	# syscall 10 for mprotect
	leal	(10), %eax
	syscall
	cmp		$0, %eax
	jl		mprotect_failed
prepare_encrypt:
	leaq	main(%rip), %rdx	# put address in rdx for encrypting
	leal	(0x49), %edi		# 'i'
	leaq	(%rbx), %rcx		# store counter in rcx
	jmp		encrypt_loop
map_failed:
	# return -1 to indicate that the mapping failed
	leal	(-1), %eax
	popq	%r14
	popq	%r13
	popq	%r12
	popq	%rbx
	popq	%rdx
	popq	%rsi
	popq	%rdi
	popq	%rbx
	movq	%rbp, %rsp
	popq	%rbp
	ret
# call to mprotect failed, return error
mprotect_failed:
	popq	%rdx
	popq	%rsi
	popq	%rdi
	popq	%rbx
	leal	(-2), %eax
	movq	%rbp, %rsp
	popq	%rbp
	ret
# everything up until this point can be encrypted
encrypt_loop:
	xorb	%dil, (%rdx)		# xor instruction with 'i'
	incq	%rdx				# move to next instruction
	decq	%rcx
	cmp		$0, %rcx			# have we reached the end of main?
	jz		decrypt				# break out of loop
	jmp		encrypt_loop
decrypt:
	leaq	main_post_encrypt(%rip), %rsi	# address of buffer to print
	movq	$main_post_size, %rdx			# number of bytes to write
	leal	(1), %edi						# stdout
	leal	(1), %eax						# write syscall
	syscall
	leaq	main(%rip), %rdi	# prepare to print bytes of main routine
	leaq	(%rbx), %rsi		# store number of bytes into rsi
	call	print_instructions
	leaq	main(%rip), %rdx	# prepare to decrypt main
	leal	(0x49), %edi		# use edi for xor
	leaq	(%rbx), %rcx
decrypt_loop:
	xorb	%dil, (%rdx)		# xor instruction with 'i' to reset
	incq	%rdx				# move to next instruction
	decq	%rcx
	cmp		$0, %rcx			# have we reached the end of main?
	jz		finish_decrypt		# exit loop if so
	jmp		decrypt_loop		# go back to main once we have finished
finish_decrypt:
	leaq	main_post_decrypt(%rip), %rsi	# address of buffer to print
	movq	$main_decrypt_size, %rdx		# number of bytes to write
	leal	(1), %edi						# stdout
	leal	(1), %eax						# write syscall
	syscall
	leaq	main(%rip), %rdi	# prepare to print bytes after decryption
	leaq	(%rbx), %rsi		# number of bytes to print
	call	print_instructions	# get the instructions after decryption
	popq	%rbx				# we don't need rbx anymore
	jmp		after_decrypt		# go to body of program and execute
