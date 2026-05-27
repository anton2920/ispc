.section .text

.macro	vmovdy from, through, to
	vmovd		\from, \through
	vpbroadcastd	\through, \to
.endm

.globl	BSearchProper
.type	BSearchProper, @function
# int	BSearchProper(int32 haystack[] -> %rdi, int32 n -> %esi, int32 needle -> %edx);
BSearchProper:
	.equ	programCount, 8
	.equ	programMask,  (1<<programCount) - 1
	.equ	tzcntLast,    4*8  # sizeof(*haystack) * 8
	.equ	chunkSize,    64*4 # max(programCount, tzcntLast+1) * sizeof(int32)

	pushq	%rbp
	movq	%rsp, %rbp
	subq	$chunkSize, %rsp
	andq	$-32, %rsp

	# Variables mapping:
	# haystack		-> %rdi
	# n			-> %esi
	# needle		-> %edx

	# tmp /lindex/ret	-> %eax
	# tmp2/rindex		-> %ebx
	# l   /i		-> %ecx
	# r			-> %esi (destroys 'n')
	# tmp32			-> %r8

	# needles		-> %ymm0
	# progIdxs		-> %ymm1
	# ls			-> %ymm2
	# k			-> %ymm3
	# elements		-> %ymm4
	# gatherMaskInit	-> %ymm5
	# gatherMask		-> %ymm6
	# ltMask		-> %ymm7

	movq		$32, %r8		# tmp32 = 32
	vpcmpeqd	%ymm5, %ymm5, %ymm5	# gatherMask = {-1, -1, -1, -1, -1, -1, -1, -1}

	xorl	%ecx, %ecx	# l = 0
	decl	%esi		# r = n - 1

	vmovdy	%edx, %xmm0, %ymm0	# needles = {ndl, ndl, ndl, ndl, ndl, ndl, ndl, ndl}
	vmovdqa	programIndicies, %ymm1	# programIndicies = {0, 1, 2, 3, 4, 5, 6, 7}

.loop:
	leal	1(%esi), %eax		# tmp = r + 1
	movl	%eax, (%rsp, %r8, 4)	# kmem[tmp32] = r + 1

	vmovdqa	%ymm5, %ymm6		# gatherMask = gatherMaskInit
	subl	%ecx, %eax		# tmp = r + 1 - l
	cmpl	$programCount, %eax	# while (tmp > programCount)
	jle	.end

	vmovdy	%ecx, %xmm2, %ymm2	# ls = {l, l, l, l, l, l, l, l}

	shr	$0x3, %eax		# tmp = tmp / programCount
	vmovdy	%eax, %xmm3, %ymm3	# k = {tmp, tmp, tmp, tmp, tmp, tmp, tmp, tmp}
	vpmulld	%ymm3, %ymm1, %ymm3	# k *= programIndicies
	vpaddd	%ymm3, %ymm2, %ymm3	# k += ls => k = ((r - l + 1) / programCount) * programIndicies + ls

	vpgatherdd	%ymm6, (%rdi, %ymm3, 4), %ymm4	# elements = haystack[k] & gatherMask
	vpcmpgtd	%ymm0, %ymm4, %ymm7		# ltMask   = needles < elements
	vmovmskps	%ymm7, %ebx			# rindex   = extract_sign_bits(ltMask)

	vmovdqa	%ymm3, (%rsp)	# kmem = k

	movzbl	%bl, %ebx	# rindex = rindex & 0xFF
	tzcntl	%ebx, %ebx	# rindex = trailing_zeros_count(rindex)
	leal	-1(%ebx), %eax  # lindex = rindex - 1
	and	$0b111, %eax	# lindex = lindex & 0b111

	movl	(%rsp, %rax, 4), %ecx	# l = kmem[lindex]
	incl	%ecx			# l += 1
	movl	(%rsp, %rbx, 4), %esi	# r = kmem[rindex]
	decl	%esi			# r -= 1

	jmp	.loop
.end:
	movl	%esi, %eax	# ret = r
	cmpl	%esi, %ecx	# if (l > r)
	jg	.fin		# goto .fin

	movl	$-1, %eax	# ret = -1
	leal	-2(%ecx), %ecx	# i = l - 2
.loop2:
	incl	%ecx		# i += 1
	cmpl	%esi, %ecx	# while (i <= r)
	jg	.fin

	cmpl	%edx, (%rdi, %rcx, 4)	# if (haystack[i] == needle)
	jne	.loop2			# goto .loop2

	movl	%ecx, %eax	# ret = i
.fin:
	movq	%rbp, %rsp
	popq	%rbp
	retq


.globl	BinarySearchOpt
.type	BinarySearchOpt, @function
# int	BinarySearchOpt(int32 haystack[] -> %rdi, int32 n -> %esi, int32 needle -> %edx);
BinarySearchOpt:
	.equ	programCount, 8
	.equ	programMask,  (1<<programCount) - 1
	.equ	tzcntLast,    4*8  # sizeof(*haystack) * 8
	.equ	chunkSize,    64*4 # max(programCount, tzcntLast+1) * sizeof(int32)

	pushq	%rbp
	movq	%rsp, %rbp
	subq	$chunkSize, %rsp
	andq	$-32, %rsp

	# Variables mapping:
	# haystack		-> %rdi
	# n			-> %esi
	# needle		-> %edx

	# tmp /lindex/ret	-> %eax
	# tmp2/rindex		-> %ebx
	# l   /i		-> %ecx
	# r			-> %esi (destroys 'n')
	# tmp32			-> %r8

	# needles		-> %ymm0
	# progIdxs		-> %ymm1
	# ls			-> %ymm2
	# k			-> %ymm3
	# elements		-> %ymm4
	# gatherMaskInit	-> %ymm5
	# gatherMask		-> %ymm6
	# ltMask		-> %ymm7

	movq		$32, %r8		# tmp32 = 32
	vpcmpeqd	%ymm5, %ymm5, %ymm5	# gatherMask = {-1, -1, -1, -1, -1, -1, -1, -1}

	xorl	%ecx, %ecx	# l = 0
	decl	%esi		# r = n - 1

	leal	1(%esi), %eax		# tmp = r + 1
	cmpl	$programCount, %eax	# while (tmp > programCount)
	jle	.Lloop

	vmovdy	%edx, %xmm0, %ymm0	# needles = {ndl, ndl, ndl, ndl, ndl, ndl, ndl, ndl}
	movl	%esi, (%rsp, %r8, 4)	# kmem[tmp32] = r
	vmovdqa	programIndicies, %ymm1	# programIndicies = {0, 1, 2, 3, 4, 5, 6, 7}

	shr	$0x3, %eax		# tmp = tmp / programCount
	vmovdy	%eax, %xmm3, %ymm3	# k = {tmp, tmp, tmp, tmp, tmp, tmp, tmp, tmp}
	vpmulld	%ymm3, %ymm1, %ymm3	# k *= programIndicies => k = ((r - l + 1) / programCount) * programIndicies

	vpgatherdd	%ymm5, (%rdi, %ymm3, 4), %ymm4	# elements = haystack[k] & gatherMask
	vpcmpgtd	%ymm0, %ymm4, %ymm7		# ltMask   = needles < elements
	vmovmskps	%ymm7, %ebx			# rindex   = extract_sign_bits(ltMask)

	vmovdqa	%ymm3, (%rsp)	# kmem = k

	movzbl	%bl, %ebx	# rindex = rindex & 0xFF
	tzcntl	%ebx, %ebx	# rindex = trailing_zeros_count(rindex)
	leal	-1(%ebx), %eax  # lindex = rindex - 1
	and	$0b111, %eax	# lindex = lindex & 0b111

	movl	(%rsp, %rax, 4), %ecx	# l = kmem[lindex]
	movl	(%rsp, %rbx, 4), %esi	# r = kmem[rindex]

	movl	$-1, %eax
.Lloop:
	cmp	%esi, %ecx	# while (l <= r)
	jg	.Lfin

	leal	(%ecx, %esi), %ebx	# tmp = l + r
	shr	$0x1, %ebx		# tmp = (l + r) / 2

	cmpl	(%rdi, %rbx, 4), %edx	# if (haystack[k] == needle)
	je	.Lend
	jg	.LupdateL

	leal	-1(%ebx), %esi	# r = k - 1
	jmp	.Lloop

.LupdateL:
	leal	+1(%ebx), %ecx	# l = k + 1
	jmp .Lloop

.Lend:
	movl	%ebx, %eax

.Lfin:
	movq	%rbp, %rsp
	popq	%rbp
	retq

.align 32
programIndicies:
	.int	0
	.int	1
	.int	2
	.int	3
	.int	4
	.int	5
	.int	6
	.int	7

.section .note.GNU-stack,"",@progbits
