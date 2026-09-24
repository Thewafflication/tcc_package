#include <emmintrin.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <limits.h>
#define CHECK(x) do { if (!(x)) { printf("FAIL line %d: %s\n", __LINE__, #x); return 1; } } while (0)
static int calls;
static __m128 tick(float x) { ++calls; return _mm_set1_ps(x); }
static __m128 combine(__m128 a,__m128 b,__m128 c,__m128 d,__m128 e,int n)
{ return _mm_add_ps(_mm_add_ps(a,b),_mm_add_ps(_mm_add_ps(c,d),_mm_add_ps(e,_mm_set1_ps((float)n)))); }
static __m128 (*volatile indirect)(__m128,__m128,__m128,__m128,__m128,int)=combine;
struct aligned_record { char c; __m128 v; };
static __m128 global_vector={1,2,3,4};
static __m128 asm_add(__m128 a,__m128 b)
{ __asm__("addps %1,%0" : "+x"(a) : "x"(b) : "xmm7"); return a; }
static __m128 asm_tied(__m128 a,__m128 b)
{ __m128 r; __asm__("movaps %1,%0; mulps %2,%0" : "=&x"(r) : "x"(a),"x"(b) : "xmm0"); return r; }
#if defined(_WIN32) && defined(__x86_64__)
extern int check_xmm_preserved(void (*)(void));
static void destroy_xmm(void)
{ __asm__("pxor %%xmm6,%%xmm6; pxor %%xmm15,%%xmm15" ::: "xmm6", "xmm15"); }
#endif
int main(void)
{
    __m128 a=_mm_setr_ps(1,2,3,4),b=_mm_set1_ps(2),r;
    __m128i n; __m128d d; union { __m128i i; int i32[4]; signed char i8[16]; } u;
    __m128 array[3]; struct aligned_record rec;
    unsigned oldcsr; float f[4]; double df[2];
    unsigned char raw[64], maskout[16]; int i;
    CHECK(sizeof(__m128)==16 && sizeof(__m128i)==16 && sizeof(__m128d)==16);
    CHECK(__alignof__(__m128)==16 && __alignof__(__m128i)==16 && __alignof__(__m128d)==16);
    CHECK(!((uintptr_t)&a & 15)); CHECK(!((uintptr_t)&array & 15));
    CHECK(!((uintptr_t)&rec.v & 15)); CHECK(!((uintptr_t)&global_vector & 15));
    CHECK(!__builtin_types_compatible_p(__m128,__m128i));
    CHECK(!__builtin_types_compatible_p(__m128d,__m128));
    _mm_storeu_ps(f,_mm_add_ps(a,b)); CHECK(f[0]==3 && f[3]==6);
    _mm_storeu_ps(f,indirect(a,b,b,b,b,3)); CHECK(f[0]==12 && f[3]==15);
    calls=0; r=_mm_shuffle_ps(tick(1),tick(2),_MM_SHUFFLE(0,0,0,0));
    CHECK(calls==2); _mm_storeu_ps(f,r); CHECK(f[0]==1 && f[3]==2);
    _mm_storeu_ps(f,asm_add(a,b)); CHECK(f[0]==3 && f[3]==6);
    _mm_storeu_ps(f,asm_tied(a,b)); CHECK(f[0]==2 && f[3]==8);
#if defined(_WIN32) && defined(__x86_64__)
    CHECK(check_xmm_preserved(destroy_xmm));
#endif
    n=_mm_cvttps_epi32(_mm_setr_ps(1.9f,-2.9f,3.5f,4.5f));
    u.i=n; CHECK(u.i32[0]==1 && u.i32[1]==-2 && u.i32[2]==3 && u.i32[3]==4);
    n=_mm_shuffle_epi32(n,27); u.i=n; CHECK(u.i32[0]==4 && u.i32[3]==1);
    u.i=_mm_adds_epi8(_mm_set1_epi8(120),_mm_set1_epi8(30)); CHECK(u.i8[0]==127 && u.i8[15]==127);
    u.i=_mm_add_epi32(_mm_set1_epi32(INT_MAX),_mm_set1_epi32(1)); CHECK(u.i32[0]==INT_MIN);
    u.i=_mm_slli_epi32(_mm_set1_epi32(1),31); CHECK(u.i32[0]==INT_MIN);
    u.i=_mm_srli_epi32(u.i,31); CHECK(u.i32[0]==1);
    u.i=_mm_slli_epi32(u.i,255); CHECK(u.i32[0]==0);
    u.i=_mm_slli_si128(_mm_set1_epi8(1),15); CHECK(u.i8[0]==0 && u.i8[15]==1);
    CHECK(_mm_movemask_epi8(_mm_set1_epi8(-1))==65535);
    CHECK(_mm_movemask_ps(_mm_cmplt_ps(a,b))==1);
    _mm_storeu_ps(f,_mm_cmpgt_ss(a,b)); CHECK(f[1]==2 && f[3]==4);
    u.i=_mm_set_epi32(0x7fc00000,0,0,0x7fc00000);
    CHECK(_mm_movemask_ps(_mm_cmpunord_ps(_mm_castsi128_ps(u.i),a))==9);
    d=_mm_mul_pd(_mm_setr_pd(1.5,-2),_mm_set1_pd(2));
    _mm_storeu_pd(df,d); CHECK(df[0]==3 && df[1]==-4);
    _mm_storeu_pd(df,_mm_sqrt_sd(_mm_setr_pd(99,7),_mm_setr_pd(16,88)));
    CHECK(df[0]==4 && df[1]==7);
    CHECK(_mm_cvttss_si32(_mm_set_ss(-3.9f))==-3);
    CHECK(_mm_cvttsd_si32(_mm_set_sd(12.9))==12);
#ifdef __x86_64__
    CHECK(_mm_cvttsd_si64(_mm_set_sd(4294967297.0))==4294967297LL);
    CHECK(_mm_cvtsd_f64(_mm_cvtsi64_sd(_mm_setzero_pd(),4294967297LL))==4294967297.0);
#endif
    oldcsr=_mm_getcsr(); _MM_SET_ROUNDING_MODE(_MM_ROUND_DOWN);
    CHECK(_mm_cvtss_si32(_mm_set_ss(3.9f))==3);
    _mm_setcsr(oldcsr); CHECK(_mm_getcsr()==oldcsr);
    _mm_storeu_ps((float *)(raw+1),a); _mm_storeu_ps(f,_mm_loadu_ps((float *)(raw+1)));
    CHECK(f[0]==1 && f[3]==4);
    memset(maskout,0x55,sizeof maskout);
    _mm_maskmoveu_si128(_mm_set1_epi8(42),_mm_set_epi64x(0,-1), (char *)maskout);
    _mm_sfence();
    for(i=0;i<16;++i) CHECK(maskout[i]==(i<8?42:0x55));
    _mm_store_ps((float *)&array[0],a); _mm_storeu_ps(f,_mm_load_ps((float *)&array[0]));
    CHECK(f[3]==4);
    puts("SIMD C types, alignment, calls, intrinsics and inline assembly passed");
    return 0;
}
