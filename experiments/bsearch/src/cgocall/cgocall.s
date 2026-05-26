/* From "textflag.h". */
#define NOSPLIT	4

TEXT ·CGOCall(SB), 4, $-24
	MOVL	needle+20(FP), DX
	MOVL	n+16(FP), SI
	MOVQ	haystack+8(FP), DI
	MOVQ	n+0(FP), AX
	CALL	AX
	MOVL	AX, ret+24(FP)
	RET
