/* Issue #4: non-gating timings; correctness is checked for every table lane.
   Run only on a CPU/OS supporting SSE2, like the other SIMD C tests. */
#include <emmintrin.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

static unsigned short table[32768] __attribute__((aligned(16)));
static unsigned short expected[32768];

static void scalar(void)
{
    unsigned i;
    for (i = 0; i < 32768; ++i) {
        unsigned value = table[i];
        table[i] = value >= 32768 ? value - 32768 : 0;
    }
}

static void intrinsic(void)
{
    unsigned i;
    __m128i wsize = _mm_set1_epi16((short)32768);
    for (i = 0; i < 32768; i += 8) {
        __m128i value = _mm_load_si128((const __m128i *)(table + i));
        value = _mm_subs_epu16(value, wsize);
        _mm_store_si128((__m128i *)(table + i), value);
    }
}

int main(void)
{
    unsigned i;
    int mode;
    /* Visit all 65536 unsigned inputs, including both sides of saturation. */
    for (mode = 0; mode < 2; ++mode) {
        for (i = 0; i < 32768; ++i)
            table[i] = i + mode * 32768;
        scalar();
        memcpy(expected, table, sizeof table);
        for (i = 0; i < 32768; ++i)
            table[i] = i + mode * 32768;
        intrinsic();
        if (memcmp(expected, table, sizeof table)) return 1;
    }
    for (mode = 0; mode < 2; ++mode) {
        clock_t start;
        memset(table, 0, sizeof table);
        start = clock();
        for (i = 0; i < 4096; ++i) {
            table[i] = 65535;
            if (mode) intrinsic(); else scalar();
        }
        printf("%s: %.3f seconds; check=%u\n", mode ? "SSE2" : "scalar",
               (double)(clock() - start) / CLOCKS_PER_SEC,
               (unsigned)table[4095]);
        if (table[4095] != 32767) return 1;
    }
    return 0;
}
