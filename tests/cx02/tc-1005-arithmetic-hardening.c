#include <float.h>
#include <math.h>

static volatile double left_real;
static volatile double left_imaginary;
static volatile double right_real;
static volatile double right_imaginary;
static int left_evaluations;
static int right_evaluations;

static double _Complex left(void)
{
    ++left_evaluations;
    return __builtin_complex(left_real, left_imaginary);
}

static double _Complex right(void)
{
    ++right_evaluations;
    return __builtin_complex(right_real, right_imaginary);
}

static double real_part(double _Complex z)
{
    union { double _Complex z; double part[2]; } value;
    value.z = z;
    return value.part[0];
}

static double imaginary_part(double _Complex z)
{
    union { double _Complex z; double part[2]; } value;
    value.z = z;
    return value.part[1];
}

static float real_partf(float _Complex z)
{
    union { float _Complex z; float part[2]; } value;
    value.z = z;
    return value.part[0];
}

static float imaginary_partf(float _Complex z)
{
    union { float _Complex z; float part[2]; } value;
    value.z = z;
    return value.part[1];
}

static long double real_partl(long double _Complex z)
{
    union { long double _Complex z; long double part[2]; } value;
    value.z = z;
    return value.part[0];
}

static long double imaginary_partl(long double _Complex z)
{
    union { long double _Complex z; long double part[2]; } value;
    value.z = z;
    return value.part[1];
}

int main(void)
{
    double _Complex value;
    volatile float maximum_float = FLT_MAX;
    volatile long double maximum_long_double = LDBL_MAX;
    float _Complex float_value;
    long double _Complex long_double_value;

    left_real = DBL_MAX;
    left_imaginary = DBL_MAX;
    right_real = DBL_MAX;
    right_imaginary = DBL_MAX;
    value = left() / right();
    if (left_evaluations != 1 || right_evaluations != 1)
        return 1;
    if (fabs(real_part(value) - 1.0) > 1e-15)
        return 2;
    if (imaginary_part(value) != 0.0)
        return 3;

    left_real = INFINITY;
    left_imaginary = INFINITY;
    right_real = 0.0;
    right_imaginary = 1.0;
    value = left() * right();
    if (!isinf(real_part(value)) || !signbit(real_part(value)))
        return 4;
    if (!isinf(imaginary_part(value)) || signbit(imaginary_part(value)))
        return 5;

    left_real = DBL_MAX;
    left_imaginary = DBL_MAX;
    right_real = 2.0;
    right_imaginary = 2.0;
    value = left() * right();
    if (real_part(value) != 0.0 || signbit(real_part(value)))
        return 6;
    if (!isinf(imaginary_part(value))
        || signbit(imaginary_part(value)))
        return 7;

    left_real = 1.0;
    left_imaginary = -2.0;
    right_real = INFINITY;
    right_imaginary = INFINITY;
    value = left() / right();
    if (real_part(value) != 0.0 || imaginary_part(value) != 0.0)
        return 8;

    float_value = __builtin_complex(maximum_float, maximum_float)
        / __builtin_complex(maximum_float, maximum_float);
    if (fabsf(real_partf(float_value) - 1.0f) > 1e-6f
        || imaginary_partf(float_value) != 0.0f)
        return 9;

    long_double_value = __builtin_complex(maximum_long_double,
                                           maximum_long_double)
        / __builtin_complex(maximum_long_double, maximum_long_double);
    if (fabsl(real_partl(long_double_value) - 1.0L) > 1e-15L
        || imaginary_partl(long_double_value) != 0.0L)
        return 10;

    left_real = DBL_MIN;
    left_imaginary = DBL_MIN;
    right_real = DBL_MAX / 2;
    right_imaginary = nextafter(right_real, 0.0);
    value = left() * right();
    if (real_part(value) < DBL_EPSILON / 2
        || real_part(value) > DBL_EPSILON * 2)
        return 11;
    if (!isfinite(imaginary_part(value))
        || imaginary_part(value) < 3.9
        || imaginary_part(value) > 4.1)
        return 12;
    return 0;
}
