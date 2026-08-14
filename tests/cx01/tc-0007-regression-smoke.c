#include <stdarg.h>

#if defined(CX_EXPECT_X86) && !defined(__i386__)
#error "expected an i386 compiler"
#endif
#if defined(CX_EXPECT_X64) && !defined(__x86_64__)
#error "expected an x86-64 compiler"
#endif
#if defined(CX_EXPECT_ARM64) && !defined(__aarch64__)
#error "expected an AArch64 compiler"
#endif

struct pair {
    int left;
    int right;
};

static struct pair make_pair(int left, int right)
{
    struct pair result = { left, right };
    return result;
}

static int sum(int count, ...)
{
    va_list arguments;
    int index;
    int result = 0;

    va_start(arguments, count);
    for (index = 0; index < count; ++index)
        result += va_arg(arguments, int);
    va_end(arguments);
    return result;
}

int main(void)
{
    struct pair value = make_pair(17, 25);

    return value.left != 17 || value.right != 25 || sum(3, 2, 3, 5) != 10;
}
