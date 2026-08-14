#include <stdarg.h>

typedef float _Complex complex_float;
typedef double _Complex complex_double;
typedef long double _Complex complex_long_double;

#ifdef _WIN32
#define CX_EXPORT __declspec(dllexport)
#else
#define CX_EXPORT
#endif

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

CX_EXPORT complex_float cx_float_identity(complex_float value)
{
    return value;
}

CX_EXPORT complex_float cx_float_constant(void)
{
    float_parts result = { .parts = { 1.0f, 2.0f } };
    return result.value;
}

CX_EXPORT complex_double cx_double_identity(complex_double value)
{
    return value;
}

CX_EXPORT complex_long_double cx_long_double_identity(complex_long_double value)
{
    return value;
}

CX_EXPORT complex_bundle cx_bundle_identity(complex_bundle value)
{
    return value;
}

CX_EXPORT complex_double cx_invoke_callback(
    complex_double (*callback)(complex_double), complex_double value)
{
    return callback(value);
}

CX_EXPORT int cx_check_variadic(int marker, ...)
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
    return marker == 23
        && narrow.parts[0] == 1.0f && narrow.parts[1] == 2.0f
        && normal.parts[0] == 3.0 && normal.parts[1] == 4.0
        && wide.parts[0] == 5.0L && wide.parts[1] == 6.0L;
}
