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

complex_float cx_float_identity(complex_float value);
complex_float cx_float_constant(void);
complex_double cx_double_identity(complex_double value);
complex_long_double cx_long_double_identity(complex_long_double value);
complex_bundle cx_bundle_identity(complex_bundle value);
complex_double cx_invoke_callback(
    complex_double (*callback)(complex_double), complex_double value);
int cx_check_variadic(int marker, ...);

static complex_double callback_identity(complex_double value)
{
    return value;
}

int main(void)
{
    float_parts narrow = { .parts = { 1.0f, 2.0f } };
    double_parts normal = { .parts = { 3.0, 4.0 } };
    long_double_parts wide = { .parts = { 5.0L, 6.0L } };
    float_parts constant = { .value = cx_float_constant() };
    float_parts echoed_narrow = { .value = cx_float_identity(narrow.value) };
    double_parts echoed_normal = { .value = cx_double_identity(normal.value) };
    long_double_parts echoed_wide = {
        .value = cx_long_double_identity(wide.value)
    };
    double_parts callback_result = {
        .value = cx_invoke_callback(callback_identity, normal.value)
    };
    complex_bundle input_bundle = {
        narrow.value, normal.value, wide.value
    };
    complex_bundle output_bundle = cx_bundle_identity(input_bundle);
    float *bundle_narrow = (float *)&output_bundle.narrow;
    double *bundle_normal = (double *)&output_bundle.normal;
    long double *bundle_wide = (long double *)&output_bundle.wide;

    if (constant.parts[0] != 1.0f || constant.parts[1] != 2.0f)
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
    if (!cx_check_variadic(23, narrow.value, normal.value, wide.value))
        return 7;
    return 0;
}
