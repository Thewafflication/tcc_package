#include <complex.h>
#include <tgmath.h>

int main(void)
{
    double complex value = exp(CMPLX(0.0, 1.0));
    return cimag(value) == 0.0;
}
