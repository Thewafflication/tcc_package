typedef float _Complex complex_float;
typedef double _Complex complex_double;
typedef long double _Complex complex_long_double;

#define FLOAT_IMAGINARY 3.5fi
#define DOUBLE_IMAGINARY 2.5i
#define LONG_DOUBLE_IMAGINARY 4.5Li
#define J_IMAGINARY 5.5j

static union {
    complex_float value;
    float parts[2];
} static_float = { .value = FLOAT_IMAGINARY };

static union {
    complex_double value;
    double parts[2];
} static_double = { .value = DOUBLE_IMAGINARY };

static union {
    complex_long_double value;
    long double parts[2];
} static_long_double = { .value = LONG_DOUBLE_IMAGINARY };

static union {
    complex_double value;
    double parts[2];
} static_constructed = { .value = __builtin_complex(-0.0, -0.0) };

static int real_count;
static int imaginary_count;

static double next_real(void)
{
    ++real_count;
    return 6.25;
}

static double next_imaginary(void)
{
    ++imaginary_count;
    return -7.5;
}

static int is_negative_zero(double value)
{
    union {
        double value;
        unsigned long long bits;
    } representation = { value };

    return representation.bits == 0x8000000000000000ULL;
}

int main(void)
{
    union {
        complex_double value;
        double parts[2];
    } automatic = {
        .value = __builtin_complex(next_real(), next_imaginary())
    };
    union {
        complex_double value;
        double parts[2];
    } copied = { .value = 0.0i };
    union {
        complex_double value;
        double parts[2];
    } j_value = { .value = J_IMAGINARY };
    complex_double braced = { 8.0i };
    complex_double array[2] = { 9.0i, 10.0i };
    struct {
        complex_double member;
    } aggregate = { 11.0i };
    double *braced_parts = (double *)&braced;
    double *array_parts = (double *)array;
    double *aggregate_parts = (double *)&aggregate.member;
    complex_double *pointer = &automatic.value;

    copied.value = *pointer;

    return !(static_float.parts[0] == 0.0f
             && static_float.parts[1] == 3.5f
             && static_double.parts[0] == 0.0
             && static_double.parts[1] == 2.5
             && static_long_double.parts[0] == 0.0L
             && static_long_double.parts[1] == 4.5L
             && is_negative_zero(static_constructed.parts[0])
             && is_negative_zero(static_constructed.parts[1])
             && automatic.parts[0] == 6.25
             && automatic.parts[1] == -7.5
             && copied.parts[0] == 6.25
             && copied.parts[1] == -7.5
             && j_value.parts[0] == 0.0
             && j_value.parts[1] == 5.5
             && braced_parts[0] == 0.0
             && braced_parts[1] == 8.0
             && array_parts[1] == 9.0
             && array_parts[3] == 10.0
             && aggregate_parts[1] == 11.0
             && real_count == 1
             && imaginary_count == 1);
}
