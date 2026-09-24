#include <emmintrin.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <limits.h>
#define CHECK(x) do { if (!(x)) { _mm_empty(); printf("header failure %d: %s\n",__LINE__,#x); return 1; } } while(0)
static volatile int count=4;
int main(void)
{
    __m128 a=_mm_setr_ps(1,2,3,4),b,c,d;
    __m128d da=_mm_setr_pd(1,2),db;
    __m128i i; __m64 m;
    union { __m128 f; unsigned u[4]; } nan;
    union { __m64 v; short w[4]; unsigned char b[8]; int d[2]; } u;
    float f[4]; double df[2]; unsigned char bytes[64]; int j; unsigned csr;
    void *p;
    CHECK(sizeof(__m64)==8 && __alignof__(__m64)==8);
#ifdef __TINYC__
    {
        float scalar=2; double wide=3;
        register __m128 fixed __asm__("xmm3") = _mm_set1_ps(4);
        __asm__("addss %1,%0" : "+x"(scalar) : "x"(1.0f));
        __asm__("addsd %1,%0" : "+x"(wide) : "x"(2.0));
        __asm__("addps %0,%0" : "+x"(fixed));
        _mm_storeu_ps(f,fixed);
        CHECK(scalar==3 && wide==5 && f[0]==8 && f[3]==8);
    }
#endif
    CHECK(_mm_comieq_ss(a,a) && _mm_comilt_ss(a,_mm_set_ss(2)));
    CHECK(_mm_comige_sd(da,da) && _mm_ucomigt_sd(_mm_set_sd(3),da));
    nan.u[0]=0x7fc00000; nan.u[1]=nan.u[2]=nan.u[3]=0;
    csr=_mm_getcsr(); _mm_setcsr((csr|_MM_MASK_MASK)&~_MM_EXCEPT_MASK);
#ifdef __TINYC__
    CHECK(!_mm_comieq_ss(nan.f,a)); CHECK(_mm_getcsr()&_MM_EXCEPT_INVALID);
    _MM_SET_EXCEPTION_STATE(0);
    CHECK(_mm_ucomineq_ss(nan.f,a)); CHECK(!(_mm_getcsr()&_MM_EXCEPT_INVALID));
#endif
    _mm_setcsr(csr);
    i=_mm_insert_epi16(_mm_setzero_si128(),65535,7); CHECK(_mm_extract_epi16(i,7)==65535);
    i=_mm_slli_epi32(_mm_set1_epi32(3),count); CHECK(_mm_cvtsi128_si32(i)==48);
    i=_mm_slli_epi32(i,256); CHECK(_mm_cvtsi128_si32(i)==0);
    memset(bytes,0xcc,sizeof bytes); _mm_storeu_si16(bytes+1,_mm_set1_epi32(0x12345678));
    CHECK(bytes[0]==0xcc && bytes[1]==0x78 && bytes[2]==0x56 && bytes[3]==0xcc);
    CHECK(_mm_cvtsi128_si32(_mm_loadu_si16(bytes+1))==0x5678);
    _mm_storeu_si32(bytes+3,_mm_set1_epi32(0x12345678)); CHECK(_mm_cvtsi128_si32(_mm_loadu_si32(bytes+3))==0x12345678);
    _mm_storeu_si64(bytes+1,_mm_set1_epi64x(0x1122334455667788LL));
    CHECK(_mm_cvtsi128_si64(_mm_loadu_si64(bytes+1))==0x1122334455667788LL);
    df[0]=9; db=_mm_loadh_pd(da,df); _mm_storeu_pd(df,db); CHECK(df[0]==1 && df[1]==9);
    db=_mm_loadl_pd(da,df+1); _mm_storeu_pd(df,db); CHECK(df[0]==9 && df[1]==2);
    p=_mm_malloc(64,32); CHECK(p && !((uintptr_t)p&31));
    _mm_store_pd(p,_mm_setr_pd(3,7)); _mm_storeu_pd(df,_mm_loadr_pd(p)); CHECK(df[0]==7 && df[1]==3);
    _mm_storer_pd(p,da); _mm_storeu_pd(df,_mm_load_pd(p)); CHECK(df[0]==2 && df[1]==1);
    _mm_stream_si32(p,1234); _mm_sfence(); CHECK(*(int *)p==1234);
#ifdef __x86_64__
    _mm_stream_si64(p,0x1122334455667788LL); _mm_sfence(); CHECK(*(long long *)p==0x1122334455667788LL);
#endif
    _mm_prefetch(p,_MM_HINT_T0); _mm_clflush(p); _mm_mfence(); _mm_pause(); _mm_free(p);
    b=_mm_setr_ps(5,6,7,8); c=_mm_setr_ps(9,10,11,12); d=_mm_setr_ps(13,14,15,16);
    _MM_TRANSPOSE4_PS(a,b,c,d); _mm_storeu_ps(f,c); CHECK(f[0]==3 && f[1]==7 && f[2]==11 && f[3]==15);
    u.v=_mm_adds_pi16(_mm_set1_pi16(32000),_mm_set1_pi16(1000)); CHECK(u.w[0]==32767 && u.w[3]==32767);
    u.v=_mm_insert_pi16(u.v,123,2); CHECK(_mm_extract_pi16(u.v,2)==123);
    u.v=_mm_shuffle_pi16(u.v,0xaa); CHECK(u.w[0]==123 && u.w[3]==123);
    u.v=_mm_slli_pi16(_mm_set1_pi16(3),count); CHECK(u.w[0]==48);
    CHECK(_mm_movemask_pi8(_mm_set1_pi8(-1))==255);
    memset(bytes,0,sizeof bytes); _mm_maskmove_si64(_mm_set1_pi8(7),_mm_set_pi8(-1,0,-1,0,-1,0,-1,0),(char *)bytes); _mm_sfence();
    for(j=0;j<8;++j) CHECK(bytes[j]==(j&1?7:0));
    m=_mm_set_pi32(-2,3); a=_mm_cvtpi32_ps(_mm_setzero_ps(),m); _mm_storeu_ps(f,a); _mm_empty(); CHECK(f[0]==3 && f[1]==-2);
    m=_mm_cvtps_pi16(_mm_setr_ps(1,2,30000,-30000)); u.v=m; _mm_empty(); CHECK(u.w[0]==1 && u.w[3]==-30000);
    a=_mm_cvtpu8_ps(_mm_set_pi8(0,0,0,0,255,128,2,1)); _mm_storeu_ps(f,a); _mm_empty(); CHECK(f[0]==1 && f[2]==128 && f[3]==255);
    db=_mm_cvtpi32_pd(_mm_set_pi32(-7,5)); _mm_storeu_pd(df,db); _mm_empty(); CHECK(df[0]==5 && df[1]==-7);
    u.v=_mm_cvttpd_pi32(_mm_setr_pd(3.75,-2.75)); _mm_empty(); CHECK(u.d[0]==3 && u.d[1]==-2);
    i=_mm_set_epi64(_mm_set1_pi32(2),_mm_set1_pi32(1)); m=_mm_movepi64_pi64(i); CHECK(_mm_cvtsi64_si32(m)==1); _mm_empty();
    puts("Complete SSE/SSE2 header runtime checks passed"); return 0;
}
