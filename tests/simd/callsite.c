#include <emmintrin.h>
#include <stdio.h>
#include <string.h>

#define CHECK(x) do { if (!(x)) { printf("FAIL line %d\n", __LINE__); return 1; } } while (0)
typedef union { __m128i v; unsigned short lane[8]; } words;
static int loads, stores, values;
static const __m128i *source(const words *p) { ++loads; return &p->v; }
static __m128i *destination(words *p) { ++stores; return &p->v; }
static __m128i value(__m128i v) { ++values; return v; }
static __m128i (*volatile load_fn)(const __m128i *) = _mm_load_si128;
static __m128i (*volatile sub_fn)(__m128i, __m128i) = _mm_subs_epu16;
static void (*volatile store_fn)(__m128i *, __m128i) = _mm_store_si128;

int main(void)
{
    words a, b, c, d;
    __m128 f, g;
    __m128d x, y;
    float fs[4];
    double ds[2];
    volatile double scalar = 1.25;
    double sum;
    unsigned i;
    for (i = 0; i < 8; ++i) {
        a.lane[i] = i * 9362;
        b.lane[i] = 32768;
    }
    _mm_store_si128(destination(&c),
        _mm_subs_epu16(_mm_load_si128(source(&a)), value(b.v)));
    CHECK(loads == 1 && stores == 1 && values == 1);
    for (i = 0; i < 8; ++i)
        CHECK(c.lane[i] == (a.lane[i] >= 32768 ? a.lane[i] - 32768 : 0));
    store_fn(&d.v, sub_fn(load_fn(&a.v), b.v));
    CHECK(!memcmp(&c, &d, sizeof c));
    (_mm_store_si128)(&d.v, (_mm_subs_epu16)((_mm_load_si128)(&a.v), b.v));
    CHECK(!memcmp(&c, &d, sizeof c));
    c.v = _mm_subs_epu16(_mm_subs_epu16(a.v, b.v),
                         _mm_subs_epu16(b.v, a.v));
    CHECK(!memcmp(&c, &d, sizeof c));
    a.v = b.v = c.v;
    a.v = a.v;
    _mm_store_si128(&a.v, _mm_load_si128(&a.v));
    CHECK(!memcmp(&a, &d, sizeof a) && !memcmp(&b, &d, sizeof b));
    /* The vector-copy fast path also serves floating vectors and casts. */
    f = _mm_setr_ps(1, 2, 3, 4);
    g = f;
    sum = scalar + ((g = f), scalar);
    CHECK(sum == 2.5);
    _mm_storeu_ps(fs, g);
    CHECK(fs[0] == 1 && fs[3] == 4);
    x = _mm_setr_pd(1.5, 2.5);
    y = x;
    _mm_storeu_pd(ds, y);
    CHECK(ds[0] == 1.5 && ds[1] == 2.5);
    a.v = (__m128i)g;
    g = (__m128)a.v;
    _mm_storeu_ps(fs, g);
    CHECK(fs[0] == 1 && fs[3] == 4);
    puts("SIMD call-site evaluation, function forms and vector copies passed");
    return 0;
}
