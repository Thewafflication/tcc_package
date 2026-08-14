#include <complex.h>
#include <math.h>

static int close_value(double actual, double expected, double tolerance)
{
    return fabs(actual - expected) <= tolerance;
}

static int close_complex(double complex actual, double complex expected,
                         double tolerance)
{
    return close_value(creal(actual), creal(expected), tolerance)
        && close_value(cimag(actual), cimag(expected), tolerance);
}

int main(void)
{
    double complex z = CMPLX(0.25, -0.5);
    double complex e = cexp(CMPLX(1.0, 1.0));
    double complex power = cpow(CMPLX(1.0, 1.0), CMPLX(2.0, 0.0));
    double complex root = csqrt(CMPLX(-4.0, 0.0));
    double complex round_trip;

    if (!close_complex(e, CMPLX(1.4686939399158851,
                                2.2873552871788423), 2e-14))
        return 1;
    if (!close_complex(power, CMPLX(0.0, 2.0), 2e-13))
        return 2;
    if (!close_complex(root, CMPLX(0.0, 2.0), 2e-14))
        return 3;
    round_trip = clog(cexp(z));
    if (!close_complex(round_trip, z, 2e-13))
        return 4;
    round_trip = catan(ctan(z));
    if (!close_complex(round_trip, z, 3e-13))
        return 5;
    round_trip = casin(csin(z));
    if (!close_complex(round_trip, z, 3e-13))
        return 6;
    round_trip = cacos(ccos(z));
    if (!close_complex(round_trip, z, 3e-13))
        return 7;
    round_trip = casinh(csinh(z));
    if (!close_complex(round_trip, z, 3e-13))
        return 8;
    round_trip = catanh(ctanh(z));
    if (!close_complex(round_trip, z, 3e-13))
        return 9;
    round_trip = cacosh(ccosh(CMPLX(1.0, 0.25)));
    if (!close_complex(round_trip, CMPLX(1.0, 0.25), 3e-13))
        return 10;
    if (!close_complex(ccos(z), ccosh(CMPLX(0.5, 0.25)), 3e-13))
        return 11;
    if (cabsf(cexpf(CMPLXF(0.25f, -0.5f))) <= 0.0f)
        return 12;
    if (cabsl(csqrtl(CMPLXL(3.0L, 4.0L))) <= 0.0L)
        return 13;
    return 0;
}
