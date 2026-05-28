.section .text

.macro	vmovdy from, through, to
	vmovd		\from, \through
	vpbroadcastd	\through, \to
.endm


.macro	BinarySearchBody
	movl	$-1, %eax
0:
	cmp	%esi, %ecx	# while (l <= r)
	jg	3f

	leal	(%ecx, %esi), %ebx	# k = l + r
	shr	$0x1, %ebx		# k = (l + r) / 2

	cmpl	(%rdi, %rbx, 4), %edx	# if (haystack[k] == needle)
	je	2f
	jg	1f

	leal	-1(%ebx), %esi	# r = k - 1
	jmp	0b

1:
	leal	+1(%ebx), %ecx	# l = k + 1
	jmp	0b

2:
	movl	%ebx, %eax
3:
.endm


.globl	BinarySearch
.type	BinarySearch, @function
# int	BinarySearch(int32 haystack[] -> %rdi, int32 n -> %esi, int32 needle -> %edx);
BinarySearch:
	xorl	%ecx, %ecx	# l = 0
	decl	%esi		# r = n - 1

	BinarySearchBody

	retq


.globl	BSearch
.type	BSearch, @function
# int	BSearch(int32 haystack[] -> %rdi, int32 n -> %esi, int32 needle -> %edx);
BSearch:
	.equ	programCount, 8
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

	# needles		-> %ymm0
	# progIdxs		-> %ymm1
	# ls			-> %ymm2
	# k			-> %ymm3
	# elements		-> %ymm4
	# gatherMaskInit	-> %ymm5
	# gatherMask		-> %ymm6
	# ltMask		-> %ymm7

	# NOTE(anton2920): this is optimized for total processing latency.
	vpcmpeqd	%ymm5, %ymm5, %ymm5	# gatherMask = {-1, -1, -1, -1, -1, -1, -1, -1}
	vmovdy	%edx, %xmm0, %ymm0	# needles = {ndl, ndl, ndl, ndl, ndl, ndl, ndl, ndl}
	vmovdqa	programIndicies, %ymm1	# programIndicies = {0, 1, 2, 3, 4, 5, 6, 7}

	xorl	%ecx, %ecx	# l = 0

BSearch_while_bsearch:
	# NOTE(anton2920): this is optimized for throughput.
	vmovdy	%ecx, %xmm2, %ymm2	# ls = {l, l, l, l, l, l, l, l}
	movl	%esi, %eax		# tmp = r + 1
	movl	%eax, 32*4(%rsp)	# kmem[32] = r + 1

	subl	%ecx, %eax		# tmp = r + 1 - l
	decl	%esi			# r -= 1
	cmpl	$programCount, %eax	# while (tmp > programCount)
	jle	BSearch_while_bsearch_end

	shr	$0x3, %eax		# tmp = tmp / programCount
	vmovdy	%eax, %xmm3, %ymm3	# k = {tmp, tmp, tmp, tmp, tmp, tmp, tmp, tmp}
	vpmulld	%ymm3, %ymm1, %ymm3	# k *= programIndicies
	vpaddd	%ymm3, %ymm2, %ymm3	# k += ls => k = ((r - l + 1) / programCount) * programIndicies + ls

	vmovdqa		%ymm5, %ymm6			# gatherMask = gatherMaskInit
	vpgatherdd	%ymm6, (%rdi, %ymm3, 4), %ymm4	# elements = haystack[k] & gatherMask

	vpcmpgtd	%ymm0, %ymm4, %ymm7	# ltMask   = needles < elements
	vmovmskps	%ymm7, %ebx		# rindex   = extract_sign_bits(ltMask)
	vmovdqa		%ymm3, (%rsp)		# kmem = k

	tzcntl	%ebx, %ebx	# rindex = trailing_zeros_count(rindex)
	leal	-1(%ebx), %eax  # lindex = rindex - 1
	and	$0b111, %eax	# lindex = lindex & 0b111

	movl	(%rsp, %rax, 4), %ecx	# l = kmem[lindex]
	incl	%ecx			# l += 1
	movl	(%rsp, %rbx, 4), %esi	# r = kmem[rindex]
	jmp	BSearch_while_bsearch

BSearch_while_bsearch_end:
	movl	%esi, %eax	# ret = r
	cmpl	%esi, %ecx	# if (l > r)
	jg	BSearch_end	# goto BSearch_end

	movl	$-1, %eax	# ret = -1
	leal	-2(%ecx), %ecx	# i = l - 2
BSearch_while_lsearch:
	incl	%ecx		# i += 1
	cmpl	%esi, %ecx	# while (i <= r)
	jg	BSearch_end

	cmpl	%edx, (%rdi, %rcx, 4)	# while (haystack[i] != needle)
	jne	BSearch_while_lsearch

	movl	%ecx, %eax	# ret = i

BSearch_end:
	movq	%rbp, %rsp
	popq	%rbp
	retq


.globl	BinarySearchOpt
.type	BinarySearchOpt, @function
# int	BinarySearchOpt(int32 haystack[] -> %rdi, int32 n -> %esi, int32 needle -> %edx);
BinarySearchOpt:
	.equ	programCount, 8
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

	# needles		-> %ymm0
	# progIdxs		-> %ymm1
	# ls			-> %ymm2
	# k			-> %ymm3
	# elements		-> %ymm4
	# gatherMaskInit	-> %ymm5
	# gatherMask		-> %ymm6
	# ltMask		-> %ymm7

	# NOTE(anton2920): this is optimized for total processing latency.
	movl	%esi, %eax	# tmp = n
	xorl	%ecx, %ecx	# l = 0

	vpcmpeqd	%ymm5, %ymm5, %ymm5	# gatherMask = {-1, -1, -1, -1, -1, -1, -1, -1}

	decl	%esi			# r = n - 1
	movl	%esi, 32*4(%rsp)	# kmem[32] = r

	vmovdy	%edx, %xmm0, %ymm0	# needles = {ndl, ndl, ndl, ndl, ndl, ndl, ndl, ndl}
	vmovdqa	programIndicies, %ymm1	# programIndicies = {0, 1, 2, 3, 4, 5, 6, 7}

	shr	$0x3, %eax		# tmp = tmp / programCount
	vmovdy	%eax, %xmm3, %ymm3	# k = {tmp, tmp, tmp, tmp, tmp, tmp, tmp, tmp}

	vpmulld	%ymm3, %ymm1, %ymm3	# k *= programIndicies => k = (n / programCount) * programIndicies

	vpgatherdd	%ymm5, (%rdi, %ymm3, 4), %ymm4	# elements = haystack[k] & gatherMask
	vpcmpgtd	%ymm0, %ymm4, %ymm7		# ltMask   = needles < elements
	vmovmskps	%ymm7, %ebx			# rindex   = extract_sign_bits(ltMask)

	tzcntl	%ebx, %ebx	# rindex = trailing_zeros_count(rindex)

	vmovdqa	%ymm3, (%rsp)	# kmem = k

	leal	-1(%ebx), %eax  # lindex = rindex - 1
	and	$0b111, %eax	# lindex = lindex & 0b111

	movl	(%rsp, %rax, 4), %ecx	# l = kmem[lindex]
	movl	(%rsp, %rbx, 4), %esi	# r = kmem[rindex]

BinarySearchOpt_binsearch:
	BinarySearchBody

	movq	%rbp, %rsp
	popq	%rbp
	retq


.globl	BinarySearchOpt2
.type	BinarySearchOpt2, @function
# int	BinarySearchOpt2(int32 haystack[] -> %rdi, int32 n -> %esi, int32 needle -> %edx);
BinarySearchOpt2:
	.equ	programCount, 16
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
	# rindexHi		-> %r8d

	# needles		-> %ymm0
	# progIdxs1		-> %ymm1
	# progIdxs2		-> %ymm8	<-- new
	# ls			-> %ymm2
	# k1			-> %ymm3
	# k2			-> %ymm9	<-- new
	# elements1		-> %ymm4
	# elements2		-> %ymm10	<-- new
	# gatherMask1		-> %ymm5
	# gatherMask2		-> %ymm6
	# ltMask1		-> %ymm7
	# ltMask2		-> %ymm11	<-- new

	# NOTE(anton2920): this is optimized for total processing latency.
	movl	%esi, %eax		# tmp = n (r + 1);	0 cycles, mov elimination.
	xorl	%ecx, %ecx		# l = 0;		0 cycles, zero idiom.

	vpcmpeqd	%ymm5, %ymm5, %ymm5	# gatherMask1 = {-1, -1, -1, -1, -1, -1, -1, -1}; 1 cycle, port 1.
	vpcmpeqd	%ymm6, %ymm6, %ymm6	# gatherMask2 = {-1, -1, -1, -1, -1, -1, -1, -1}; 1 cycle, port 0.

	decl	%esi			# r = n - 1; 1 cycle, port 5.
	movl	%esi, 32*4(%rsp)	# kmem[32] = r; 4 cycles, ports 7 and 4.

	vmovdy	%edx, %xmm0, %ymm0	# needles = {ndl, ndl, ndl, ndl, ndl, ndl, ndl, ndl}; 3+3 cycles, port 5
	vmovdqa	programIndicies1, %ymm1	# programIndicies1 = {0, 1, 2, 3, 4, 5, 6, 7}; 5 cycles, port 2.
	vmovdqa	programIndicies2, %ymm8	# programIndicies2 = {8, 9, A, B, C, D, E, F}; 5 cycles, port 3.

	shr	$0x4, %eax		# tmp = tmp / programCount; 1 cycle, port 6
	vmovdy	%eax, %xmm3, %ymm3	# k1 = {tmp, tmp, tmp, tmp, tmp, tmp, tmp, tmp}; 3+3 cycles, port 5
	vmovdqa	%ymm3, %ymm9		# k2 = k1; 0 cycles, mov elimination.

	vpmulld	%ymm3, %ymm1, %ymm3	# k1 *= programIndicies => k = (n / programCount) * programIndicies1
	vpmulld	%ymm9, %ymm8, %ymm9	# k2 *= programIndicies => k = (n / programCount) * programIndicies2

	vpgatherdd	%ymm5, (%rdi, %ymm3, 4), %ymm4	# elements1 = haystack[k1] & gatherMask1
	vpgatherdd	%ymm6, (%rdi, %ymm9, 4), %ymm10	# elements2 = haystack[k2] & gatherMask2

	vpcmpgtd	%ymm0, %ymm4,  %ymm7	# ltMask1 = needles < elements1
	vmovmskps	%ymm7, %ebx		# rindexLo  = extract_sign_bits(ltMask1)
	vpcmpgtd	%ymm0, %ymm10, %ymm11	# ltMask2 = needles < elements2
	vmovmskps	%ymm11, %r8d		# rindexHi  = extract_sign_bits(ltMask2)
	vmovdqa		%ymm3, (%rsp)		# kmem + 0 = k1

	shl	$0x8, %r8d	# rindexHi <<= 8
	orl	%r8d, %ebx	# rindex = rindexHi | rindexLo
	tzcntl	%ebx, %ebx	# rindex = trailing_zeros_count(rindex)

	vmovdqa	%ymm9, 8*4(%rsp)	# kmem + 8 = k2

	leal	-1(%ebx), %eax  # lindex = rindex - 1
	and	$0b1111, %eax	# lindex = lindex & 0b1111

	movl	(%rsp, %rax, 4), %ecx	# l = kmem[lindex]
	movl	(%rsp, %rbx, 4), %esi	# r = kmem[rindex]

BinarySearchOpt2_binsearch:
	BinarySearchBody

	movq	%rbp, %rsp
	popq	%rbp
	retq


.align 32
programIndicies:
programIndicies1:
	.int	0
	.int	1
	.int	2
	.int	3
	.int	4
	.int	5
	.int	6
	.int	7

.align 32
programIndicies2:
	.int	8
	.int	9
	.int	10
	.int	11
	.int	12
	.int	13
	.int	14
	.int	15

.section .note.GNU-stack,"",@progbits
