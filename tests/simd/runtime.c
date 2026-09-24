/* External assembly keeps the platform ABI explicit.  No SIMD C ABI assumed. */
#include <stdio.h>
#include <string.h>
#include <windows.h>

void vec_float(const void *, const void *, void *);
void vec_double(const void *, const void *, void *);
void vec_integer(const void *, const void *, void *);
void vec_convert(const void *, const void *, void *);

int main(void)
{
    float a[4] = { 1, -2, 3, 0.5f }, b[4] = { 4, 2, -1, 0.5f };
    float f[4], ef[4] = { 5, 0, 2, 1 };
    double da[2] = { 1.5, -2 }, db[2] = { 2, 4 };
    double d[2], ed[2] = { 3, -8 };
    int ia[4] = { 1, -2, 3, 4 }, ib[4] = { 4, 3, 2, 1 };
    int n[4], en[4] = { 5, 5, 1, 5 };
    float c[4] = { 1.9f, -2.9f, 0.5f, 123.75f };
    int ec[4] = { 1, -2, 0, 123 };
    if (!IsProcessorFeaturePresent(10)) {
        puts("SKIP: operating system does not report SSE2 support");
        return 0;
    }
    vec_float(a, b, f);
    vec_double(da, db, d);
    vec_integer(ia, ib, n);
    if (memcmp(f, ef, sizeof f) || memcmp(d, ed, sizeof d) ||
        memcmp(n, en, sizeof n)) {
        puts("FAIL: SIMD arithmetic or shuffle");
        return 1;
    }
    vec_convert(c, c, n);
    if (memcmp(n, ec, sizeof n)) {
        puts("FAIL: truncating conversion");
        return 1;
    }
    puts("SSE/SSE2 execution: float, double, integer, shuffle, conversion passed");
    return 0;
}
