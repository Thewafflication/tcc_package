#include <complex.h>
#include <math.h>

static int close_value(double actual, double expected, double tolerance)
{
    return fabs(actual - expected) <= tolerance;
}

int main(void)
{
    double complex z = CMPLX(3.0, -4.0);
    double complex reflected = conj(z);
    double complex projected = cproj(CMPLX(-INFINITY, -2.0));
    float complex f = CMPLXF(5.0f, 12.0f);
    long double complex l = CMPLXL(8.0L, 15.0L);

    if (creal(z) != 3.0 || cimag(z) != -4.0 || cabs(z) != 5.0)
        return 1;
    if (creal(reflected) != 3.0 || cimag(reflected) != 4.0)
        return 2;
    if (!close_value(carg(CMPLX(0.0, 1.0)),
                     1.5707963267948966, 1e-15))
        return 3;
    if (!isinf(creal(projected)) || signbit(creal(projected)))
        return 4;
    if (cimag(projected) != 0.0 || !signbit(cimag(projected)))
        return 5;
    if (cabsf(f) != 13.0f || cabsl(l) != 17.0L)
        return 6;
    return 0;
}
