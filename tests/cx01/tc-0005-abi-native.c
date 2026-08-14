#include <stdarg.h>

typedef float _Complex complex_float;
typedef double _Complex complex_double;
typedef long double _Complex complex_long_double;

typedef union {
    complex_float value;
    float parts[2];
} float_parts;

typedef union {
    complex_double value;
    double parts[2];
} double_parts;

typedef union {
    complex_long_double value;
    long double parts[2];
} long_double_parts;

typedef struct {
    complex_float narrow;
    complex_double normal;
    complex_long_double wide;
} complex_bundle;

static complex_float float_constant(void)
{
    return __builtin_complex(1.0f, 2.0f);
}

static complex_float float_identity(complex_float value)
{
    return value;
}

static complex_double double_identity(complex_double value)
{
    return value;
}

static complex_long_double long_double_identity(complex_long_double value)
{
    return value;
}

static complex_bundle bundle_identity(complex_bundle value)
{
    return value;
}

static complex_double invoke_callback(
    complex_double (*callback)(complex_double), complex_double value)
{
    return callback(value);
}

static int check_variadic(int marker, ...)
{
    va_list arguments;
    float_parts narrow;
    double_parts normal;
    long_double_parts wide;

    va_start(arguments, marker);
    narrow.value = va_arg(arguments, complex_float);
    normal.value = va_arg(arguments, complex_double);
    wide.value = va_arg(arguments, complex_long_double);
    va_end(arguments);
    return marker == 17
        && narrow.parts[0] == 1.0f && narrow.parts[1] == 2.0f
        && normal.parts[0] == 3.0 && normal.parts[1] == 4.0
        && wide.parts[0] == 5.0L && wide.parts[1] == 6.0L;
}

int main(void)
{
    float_parts narrow = { .value = __builtin_complex(1.0f, 2.0f) };
    double_parts normal = { .value = __builtin_complex(3.0, 4.0) };
    long_double_parts wide = { .value = __builtin_complex(5.0L, 6.0L) };
    float_parts returned_narrow = { .value = float_constant() };
    float_parts echoed_narrow = { .value = float_identity(narrow.value) };
    double_parts echoed_normal = { .value = double_identity(normal.value) };
    long_double_parts echoed_wide = {
        .value = long_double_identity(wide.value)
    };
    double_parts callback_result = {
        .value = invoke_callback(double_identity, normal.value)
    };
    complex_bundle input_bundle = {
        narrow.value, normal.value, wide.value
    };
    complex_bundle output_bundle = bundle_identity(input_bundle);
    float *bundle_narrow = (float *)&output_bundle.narrow;
    double *bundle_normal = (double *)&output_bundle.normal;
    long double *bundle_wide = (long double *)&output_bundle.wide;

    if (returned_narrow.parts[0] != 1.0f
        || returned_narrow.parts[1] != 2.0f)
        return 1;
    if (echoed_narrow.parts[0] != 1.0f || echoed_narrow.parts[1] != 2.0f)
        return 2;
    if (echoed_normal.parts[0] != 3.0 || echoed_normal.parts[1] != 4.0)
        return 3;
    if (echoed_wide.parts[0] != 5.0L || echoed_wide.parts[1] != 6.0L)
        return 4;
    if (callback_result.parts[0] != 3.0 || callback_result.parts[1] != 4.0)
        return 5;
    if (bundle_narrow[0] != 1.0f || bundle_narrow[1] != 2.0f
        || bundle_normal[0] != 3.0 || bundle_normal[1] != 4.0
        || bundle_wide[0] != 5.0L || bundle_wide[1] != 6.0L)
        return 6;
    if (!check_variadic(17, narrow.value, normal.value, wide.value))
        return 7;
    return 0;
}
