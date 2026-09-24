/* Windows cdecl (i386) / Windows x64.  Only volatile registers are modified. */
#ifdef __i386__
#define ARGS movl 4(%esp), %eax; movl 8(%esp), %ecx; movl 12(%esp), %edx
#define A (%eax)
#define B (%ecx)
#define C (%edx)
#else
#define ARGS
#define A (%rcx)
#define B (%rdx)
#define C (%r8)
#endif
#define NAME(n) n
.text
.globl NAME(vec_float)
NAME(vec_float):
    ARGS
    movups A, %xmm0
    movups B, %xmm1
    addps %xmm1, %xmm0
    movups %xmm0, C
    ret
.globl NAME(vec_double)
NAME(vec_double):
    ARGS
    movupd A, %xmm0
    movupd B, %xmm1
    mulpd %xmm1, %xmm0
    movupd %xmm0, C
    ret
.globl NAME(vec_integer)
NAME(vec_integer):
    ARGS
    movdqu A, %xmm0
    movdqu B, %xmm1
    paddd %xmm1, %xmm0
    pshufd $27, %xmm0, %xmm0
    movdqu %xmm0, C
    ret
.globl NAME(vec_convert)
NAME(vec_convert):
    ARGS
    movups A, %xmm0
    cvttps2dq %xmm0, %xmm0
    movdqu %xmm0, C
    ret
