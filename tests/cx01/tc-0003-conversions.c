typedef float _Complex complex_float;
typedef double _Complex complex_double;
typedef long double _Complex complex_long_double;

static union {
    complex_double value;
    double parts[2];
} static_real = { .value = 3.25 };

static union {
    complex_float value;
    float parts[2];
} static_narrow = {
    .value = (complex_float)__builtin_complex(4.5, -2.0)
};

int main(void)
{
    union {
        complex_double value;
        double parts[2];
    } from_integer = { .value = 7 };
    union {
        complex_float value;
        float parts[2];
    } narrow = {
        .value = (complex_float)__builtin_complex(7.25, -8.5)
    };
    union {
        complex_long_double value;
        long double parts[2];
    } widen = { .value = (complex_long_double)narrow.value };
    complex_double zero = __builtin_complex(0.0, 0.0);
    complex_double imaginary = 1.0i;
    complex_double selected_true;
    complex_double selected_false;
    complex_double values[2] = { zero, imaginary };
    int index = 0;
    int first_truth = !!values[index++];
    int second_truth = !!values[index++];
    int condition = 1;
    double real = __builtin_complex(9.5, 2.0);
    int integer = __builtin_complex(10.75, 4.0);
    _Bool zero_bool = zero;
    _Bool imaginary_bool = imaginary;
    double *true_parts;
    double *false_parts;

    selected_true = condition ? narrow.value : from_integer.value;
    condition = 0;
    selected_false = condition ? narrow.value : from_integer.value;
    true_parts = (double *)&selected_true;
    false_parts = (double *)&selected_false;

    return !(static_real.parts[0] == 3.25
             && static_real.parts[1] == 0.0
             && static_narrow.parts[0] == 4.5f
             && static_narrow.parts[1] == -2.0f
             && from_integer.parts[0] == 7.0
             && from_integer.parts[1] == 0.0
             && narrow.parts[0] == 7.25f
             && narrow.parts[1] == -8.5f
             && widen.parts[0] == 7.25L
             && widen.parts[1] == -8.5L
             && real == 9.5
             && integer == 10
             && !zero_bool
             && imaginary_bool
             && !zero
             && !!imaginary
             && (imaginary ? 1 : 0)
             && !(zero ? 1 : 0)
             && (imaginary && 1)
             && (zero || 1)
             && first_truth == 0
             && second_truth == 1
             && index == 2
             && true_parts[0] == 7.25
             && true_parts[1] == -8.5
             && false_parts[0] == 7.0
             && false_parts[1] == 0.0);
}
