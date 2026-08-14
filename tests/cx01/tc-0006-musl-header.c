#include <complex.h>

typedef union {
    double complex value;
    double parts[2];
} complex_parts;

#if defined(__STDC_NO_COMPLEX__)
#error "TinyCC must not advertise __STDC_NO_COMPLEX__"
#endif

int main(void)
{
    complex_parts from_i = { .value = 2.0 + 3.0 * I };
    complex_parts from_macro = { .value = CMPLX(-4.0, 5.0) };
    double (*real_function)(double complex) = (creal);
    double (*imaginary_function)(double complex) = (cimag);

    return !(from_i.parts[0] == 2.0
             && from_i.parts[1] == 3.0
             && from_macro.parts[0] == -4.0
             && from_macro.parts[1] == 5.0
             && creal(from_macro.value) == -4.0
             && cimag(from_macro.value) == 5.0
             && real_function(from_i.value) == 2.0
             && imaginary_function(from_i.value) == 3.0);
}
