#include <complex.h>
#include <math.h>

int main(void)
{
    double complex value;
    double nan_value = NAN;

    value = cproj(CMPLX(-INFINITY, -2.0));
    if (!isinf(creal(value)) || signbit(creal(value)))
        return 1;
    if (cimag(value) != 0 || !signbit(cimag(value)))
        return 2;

    value = csqrt(CMPLX(-INFINITY, -0.0));
    if (creal(value) != 0 || signbit(creal(value)))
        return 3;
    if (!isinf(cimag(value)) || !signbit(cimag(value)))
        return 4;

    value = cexp(CMPLX(-INFINITY, -0.0));
    if (creal(value) != 0 || signbit(creal(value)))
        return 5;
    if (cimag(value) != 0 || !signbit(cimag(value)))
        return 6;

    value = clog(CMPLX(-0.0, 0.0));
    if (!isinf(creal(value)) || !signbit(creal(value)))
        return 7;
    if (!(cimag(value) > 3.14 && cimag(value) < 3.15))
        return 8;

    value = csinh(CMPLX(INFINITY, 0.0));
    if (!isinf(creal(value)) || cimag(value) != 0)
        return 9;
    value = ctanh(CMPLX(INFINITY, 2.0));
    if (creal(value) != 1.0 || cimag(value) != 0.0)
        return 10;
    value = cexp(CMPLX(1.0, nan_value));
    if (!isnan(creal(value)) || !isnan(cimag(value)))
        return 11;
    return 0;
}
