typedef float _Complex complex_float;
typedef _Complex float reordered_complex_float;
typedef double _Complex complex_double;
typedef _Complex double reordered_complex_double;
typedef long double _Complex complex_long_double;
typedef long _Complex double reordered_complex_long_double;
typedef _Complex long double leading_complex_long_double;

_Static_assert(sizeof(complex_float) == 2 * sizeof(float),
               "float complex size");
_Static_assert(sizeof(complex_double) == 2 * sizeof(double),
               "double complex size");
_Static_assert(sizeof(complex_long_double) == 2 * sizeof(long double),
               "long double complex size");

_Static_assert(__alignof__(complex_float) == __alignof__(float),
               "float complex alignment");
_Static_assert(__alignof__(complex_double) == __alignof__(double),
               "double complex alignment");
_Static_assert(__alignof__(complex_long_double) == __alignof__(long double),
               "long double complex alignment");

_Static_assert(__builtin_types_compatible_p(complex_float,
                                            reordered_complex_float),
               "float complex specifier order");
_Static_assert(__builtin_types_compatible_p(complex_double,
                                            reordered_complex_double),
               "double complex specifier order");
_Static_assert(__builtin_types_compatible_p(
                   complex_long_double, reordered_complex_long_double),
               "long double complex specifier order");
_Static_assert(__builtin_types_compatible_p(
                   complex_long_double, leading_complex_long_double),
               "leading complex specifier order");
_Static_assert(!__builtin_types_compatible_p(complex_float, complex_double),
               "complex precision identity");
_Static_assert(!__builtin_types_compatible_p(complex_double,
                                             complex_long_double),
               "long double complex identity");

_Static_assert(_Generic(*(complex_float *)0, complex_float: 1, default: 0),
               "generic float complex selection");
_Static_assert(_Generic(*(complex_double *)0, complex_double: 1, default: 0),
               "generic double complex selection");

struct complex_holder {
    complex_float first;
    const complex_double second;
    volatile complex_long_double third;
};

int main(void)
{
    complex_float values[3];
    complex_double *pointer = 0;
    struct complex_holder holder;

    return sizeof(values) != 6 * sizeof(float)
        || sizeof(*pointer) != 2 * sizeof(double)
        || sizeof(holder) == 0;
}
