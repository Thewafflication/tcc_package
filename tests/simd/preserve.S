/* Check Windows x64 nonvolatile XMM registers around a C callback. */
#ifdef __x86_64__
.text
.globl check_xmm_preserved
check_xmm_preserved:
    subq $72, %rsp
    movups %xmm6, 32(%rsp)
    movups %xmm15, 48(%rsp)
    pcmpeqd %xmm6, %xmm6
    movaps %xmm6, %xmm15
    call *%rcx
    pmovmskb %xmm6, %eax
    pmovmskb %xmm15, %edx
    andl %edx, %eax
    cmpl $65535, %eax
    sete %al
    movzbl %al, %eax
    movups 32(%rsp), %xmm6
    movups 48(%rsp), %xmm15
    addq $72, %rsp
    ret
#endif
