#include <complex.h>
#include <float.h>

#ifndef complex
#error complex macro missing
#endif
#ifndef _Complex_I
#error _Complex_I macro missing
#endif
#ifndef I
#error I macro missing
#endif
#ifdef imaginary
#error imaginary must be absent while _Imaginary is unsupported
#endif
#ifdef _Imaginary_I
#error _Imaginary_I must be absent while _Imaginary is unsupported
#endif

_Static_assert(_Generic(CMPLX(1, 2), double complex: 1, default: 0),
               "CMPLX type");
_Static_assert(_Generic(CMPLXF(1, 2), float complex: 1, default: 0),
               "CMPLXF type");
_Static_assert(_Generic(CMPLXL(1, 2), long double complex: 1, default: 0),
               "CMPLXL type");
#ifdef _WIN32
_Static_assert(LDBL_MANT_DIG == DBL_MANT_DIG,
               "Windows long double model");
_Static_assert(LDBL_MAX_EXP == DBL_MAX_EXP,
               "Windows long double exponent range");
#endif

#define DECLARE_UNARY(name)                                             \
    double complex (*use_##name)(double complex) = name;               \
    float complex (*use_##name##f)(float complex) = name##f;           \
    long double complex (*use_##name##l)(long double complex) = name##l

#define DECLARE_REAL(name)                                              \
    double (*use_##name)(double complex) = name;                       \
    float (*use_##name##f)(float complex) = name##f;                   \
    long double (*use_##name##l)(long double complex) = name##l

DECLARE_UNARY(cacos);
DECLARE_UNARY(casin);
DECLARE_UNARY(catan);
DECLARE_UNARY(ccos);
DECLARE_UNARY(csin);
DECLARE_UNARY(ctan);
DECLARE_UNARY(cacosh);
DECLARE_UNARY(casinh);
DECLARE_UNARY(catanh);
DECLARE_UNARY(ccosh);
DECLARE_UNARY(csinh);
DECLARE_UNARY(ctanh);
DECLARE_UNARY(cexp);
DECLARE_UNARY(clog);
DECLARE_UNARY(conj);
DECLARE_UNARY(cproj);
DECLARE_UNARY(csqrt);
DECLARE_REAL(cabs);
DECLARE_REAL(carg);
DECLARE_REAL(cimag);
DECLARE_REAL(creal);

double complex (*use_cpow)(double complex, double complex) = cpow;
float complex (*use_cpowf)(float complex, float complex) = cpowf;
long double complex (*use_cpowl)(long double complex,
                                 long double complex) = cpowl;

int main(void)
{
    double complex z = CMPLX(0.25, -0.5);
    float complex f = CMPLXF(0.25f, -0.5f);
    long double complex l = CMPLXL(0.25L, -0.5L);
    return use_cexp(z) == 0 || use_cexpf(f) == 0 || use_cexpl(l) == 0;
}
