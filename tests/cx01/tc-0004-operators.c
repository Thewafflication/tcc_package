typedef float _Complex complex_float;
typedef double _Complex complex_double;

static union {
    complex_double value;
    double parts[2];
} static_product = {
    .value = __builtin_complex(3.0, 4.0)
           * __builtin_complex(1.0, -2.0)
};

static int close_enough(double left, double right)
{
    double difference = left - right;

    if (difference < 0.0)
        difference = -difference;
    return difference < 0.000000001;
}

static int matches(complex_double value, double real, double imaginary)
{
    double *parts = (double *)&value;

    return close_enough(parts[0], real)
        && close_enough(parts[1], imaginary);
}

int main(void)
{
    complex_double left = __builtin_complex(3.0, 4.0);
    complex_double right = __builtin_complex(1.0, -2.0);
    complex_float narrow = __builtin_complex(0.5f, 1.5f);
    complex_double compound;
    complex_double operands[2] = { left, right };
    volatile complex_double volatile_left = left;
    volatile complex_double volatile_right = right;
    int left_index = 0;
    int right_index = 1;
    complex_double evaluated_once =
        operands[left_index++] * operands[right_index++];

    _Static_assert(__builtin_types_compatible_p(
                       __typeof__(narrow + 1.0), complex_double),
                   "usual arithmetic conversion");

    if (!matches(left + right, 4.0, 2.0)
        || !matches(left - right, 2.0, 6.0)
        || !matches(left * right, 11.0, -2.0)
        || !matches(left / right, -1.0, 2.0)
        || !matches(-left, -3.0, -4.0)
        || !matches(+left, 3.0, 4.0)
        || !matches(2.0 + left, 5.0, 4.0)
        || !matches(narrow + 1.0, 1.5, 1.5)
        || !matches(evaluated_once, 11.0, -2.0)
        || !matches(volatile_left * volatile_right, 11.0, -2.0)
        || left_index != 1
        || right_index != 2
        || !(left == __builtin_complex(3.0, 4.0))
        || left != __builtin_complex(3.0, 4.0)
        || !(left != right)
        || left == right
        || static_product.parts[0] != 11.0
        || static_product.parts[1] != -2.0)
        return 1;

    compound = left;
    compound += right;
    if (!matches(compound, 4.0, 2.0))
        return 2;
    compound = left;
    compound -= right;
    if (!matches(compound, 2.0, 6.0))
        return 3;
    compound = left;
    compound *= right;
    if (!matches(compound, 11.0, -2.0))
        return 4;
    compound = left;
    compound /= right;
    if (!matches(compound, -1.0, 2.0))
        return 5;

    return 0;
}
