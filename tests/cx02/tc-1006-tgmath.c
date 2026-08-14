#include <tgmath.h>

_Static_assert(_Generic(exp((float complex)0),
                        float complex: 1, default: 0),
               "float complex exp selection");
_Static_assert(_Generic(sqrt((double complex)0),
                        double complex: 1, default: 0),
               "double complex sqrt selection");
_Static_assert(_Generic(pow((long double complex)0, 2.0L),
                        long double complex: 1, default: 0),
               "long double complex pow selection");
_Static_assert(_Generic(fabs((float complex)0), float: 1, default: 0),
               "complex fabs selection");
_Static_assert(_Generic(exp(0.0), double: 1, default: 0),
               "real exp selection");

int main(void)
{
    double complex z = __builtin_complex(1.0, 1.0);
    double complex squared = pow(z, 2.0);
    double complex exponential = exp(z);

    if (fabs(z) < 1.414 || fabs(z) > 1.415)
        return 1;
    if (creal(squared) > 1e-12 || creal(squared) < -1e-12)
        return 2;
    if (cimag(squared) < 1.999 || cimag(squared) > 2.001)
        return 3;
    if (cimag(exponential) == 0.0)
        return 4;
    return 0;
}
