#include <emmintrin.h>
#ifdef _WIN32
#include <windows.h>
#else
#include <dlfcn.h>
#define HMODULE void *
#define LoadLibraryA(p) dlopen(p, RTLD_NOW)
#define GetProcAddress dlsym
#define FreeLibrary dlclose
#endif
#include <stdio.h>
#include <stdarg.h>
#define CHECK(x) do { if (!(x)) { printf("ABI failure at line %d\n",__LINE__); return 1; } } while(0)
static __m128 callback(__m128 a,__m128 b,__m128 c,__m128 d,__m128 e,int n)
{ return _mm_add_ps(_mm_add_ps(a,b),_mm_add_ps(_mm_add_ps(c,d),_mm_add_ps(e,_mm_set1_ps((float)n)))); }
#if !defined(_WIN32) || defined(_WIN64)
static __m128 var_callback(int n,...)
{
 va_list ap; __m128 r=_mm_setzero_ps(); int i;
 va_start(ap,n);
 for(i=0;i<n;++i) r=_mm_add_ps(r,va_arg(ap,__m128));
 va_end(ap); return r;
}
#endif
struct vector_box { __m128 v; };
static struct vector_box box_callback(struct vector_box a)
{ a.v=_mm_add_ps(a.v,a.v); return a; }
#include "abi-edges.h"
static struct mixed_si si_callback(struct mixed_si a) { a.i+=7; a.d+=2; return a; }
static __m64 mmx_callback(__m64 a,__m64 b,__m64 c,__m64 d,__m64 e)
{ return _mm_add_pi32(_mm_add_pi32(a,b),_mm_add_pi32(c,_mm_add_pi32(d,e))); }
#if !defined(_WIN32) || defined(_WIN64)
static struct mixed_si va_mixed(int n,...)
{
 va_list ap, copy; struct mixed_si r={0,0}, a, b; int k;
 va_start(ap,n); va_copy(copy,ap);
 for(k=0;k<n;++k) { a=va_arg(ap,struct mixed_si); b=va_arg(copy,struct mixed_si);
   if(a.d!=b.d || a.i!=b.i) { r.i=-999; break; }
   r.d+=a.d; r.i+=a.i;
 }
 va_end(copy); va_end(ap); return r;
}
#endif
static int edges(HMODULE dll)
{
    float f[4]; __m128 a=_mm_setr_ps(1,2,3,4);
    struct vector_array va; struct vector_pair vp;
    union vector_union vu; union vector_integer vi;
    struct mixed_si si; struct mixed_is is; struct packed_vector packed;
    __m64 m;
    struct vector_array (*fa)(struct vector_array)=(void *)GetProcAddress(dll,"peer_array");
    struct vector_pair (*fp)(struct vector_pair)=(void *)GetProcAddress(dll,"peer_pair");
    union vector_union (*fu)(union vector_union)=(void *)GetProcAddress(dll,"peer_union");
    union vector_integer (*fi)(union vector_integer)=(void *)GetProcAddress(dll,"peer_vi");
    struct mixed_si (*fsi)(struct mixed_si)=(void *)GetProcAddress(dll,"peer_si");
    struct mixed_is (*fis)(struct mixed_is)=(void *)GetProcAddress(dll,"peer_is");
    struct packed_vector (*fpk)(struct packed_vector)=(void *)GetProcAddress(dll,"peer_packed");
    struct mixed_si (*fcb)(struct mixed_si (*)(struct mixed_si))=(void *)GetProcAddress(dll,"peer_si_callback");
    __m64 (*fm)(__m64,__m64,__m64,__m64,__m64)=(void *)GetProcAddress(dll,"peer_mmx5");
    __m64 (*fmc)(__m64 (*)(__m64,__m64,__m64,__m64,__m64))=(void *)GetProcAddress(dll,"peer_mmx_callback");
    struct mixed_si (*fex)(int,int,int,int,int,int,struct mixed_si,double)=(void *)GetProcAddress(dll,"peer_exhaust");
    CHECK(fa && fp && fu && fi && fsi && fis && fpk && fcb && fm && fmc && fex);
    va.v[0]=a; va=fa(va); _mm_storeu_ps(f,va.v[0]); CHECK(f[0]==1 && f[3]==4);
    vp.v[0]=a; vp.v[1]=_mm_set1_ps(9); vp=fp(vp); _mm_storeu_ps(f,vp.v[0]); CHECK(f[0]==9); _mm_storeu_ps(f,vp.v[1]); CHECK(f[3]==4);
    vu.v=a; vu=fu(vu); _mm_storeu_ps(f,vu.v); CHECK(f[0]==1 && f[3]==4);
    vi.v=a; vi=fi(vi); _mm_storeu_ps(f,vi.v); CHECK(f[0]==1 && f[3]==4);
    si.d=2; si.i=3; si=fsi(si); CHECK(si.d==4 && si.i==10);
    is.d=2; is.i=3; is=fis(is); CHECK(is.d==4 && is.i==10);
    packed.c=5; packed.v=a; packed=fpk(packed); CHECK(packed.c==6); _mm_storeu_ps(f,packed.v); CHECK(f[0]==1 && f[3]==4);
    si=fcb(si_callback); CHECK(si.d==4 && si.i==10);
    si.d=2; si.i=3; si=fex(1,2,3,4,5,6,si,4.0); CHECK(si.i==24 && si.d==6);
#if !defined(_WIN32) || defined(_WIN64)
    {
        struct mixed_si (*fv)(int,...)=(void *)GetProcAddress(dll,"peer_va_mixed");
        struct mixed_si (*fvc)(struct mixed_si (*)(int,...))=(void *)GetProcAddress(dll,"peer_va_callback");
        CHECK(fv && fvc); si.d=2; si.i=3; si=fv(1,si); CHECK(si.d==2 && si.i==3);
        si=fv(9,si,si,si,si,si,si,si,si,si); CHECK(si.d==18 && si.i==27);
        si=fvc(va_mixed); CHECK(si.d==18 && si.i==27);
    }
#endif
    m=_mm_set_pi32(2,1); m=fm(m,m,m,m,m); CHECK(_mm_cvtsi64_si32(m)==5); _mm_empty();
    m=fmc(mmx_callback); CHECK(_mm_cvtsi64_si32(m)==5); _mm_empty();
    return 0;
}
int main(int argc,char **argv)
{
 HMODULE dll; float f[4]; double d[2]; int n[4]; __m128 a=_mm_setr_ps(1,2,3,4);
 __m128 (*five)(__m128,__m128,__m128,__m128,__m128,int);
 __m128 (*nine)(__m128,__m128,__m128,__m128,__m128,__m128,__m128,__m128,__m128);
 __m128 (*variadic)(int,...);
 __m128 (*vcb)(__m128 (*)(int,...));
 struct vector_box box, (*box_fn)(struct vector_box);
 struct vector_box (*box_cb)(struct vector_box (*)(struct vector_box));
 __m128 (*mixed)(int,__m128,double,__m128,int);
 __m128 (*cb)(__m128 (*)(__m128,__m128,__m128,__m128,__m128,int));
 __m128d (*pd)(__m128d,__m128d); __m128i (*pi)(__m128i,__m128i);
 CHECK(argc==2); dll=LoadLibraryA(argv[1]); CHECK(dll!=0);
 five=(void *)GetProcAddress(dll,"peer_five"); mixed=(void *)GetProcAddress(dll,"peer_mixed");
 pd=(void *)GetProcAddress(dll,"peer_double"); pi=(void *)GetProcAddress(dll,"peer_integer");
 cb=(void *)GetProcAddress(dll,"peer_callback"); CHECK(five && mixed && pd && pi && cb);
 nine=(void *)GetProcAddress(dll,"peer_nine");
 CHECK(nine);
 box_fn=(void *)GetProcAddress(dll,"peer_box"); CHECK(box_fn);
 box.v=a; box=box_fn(box); _mm_storeu_ps(f,box.v); CHECK(f[0]==2 && f[3]==8);
 box_cb=(void *)GetProcAddress(dll,"peer_box_callback"); CHECK(box_cb);
 box=box_cb(box_callback); _mm_storeu_ps(f,box.v); CHECK(f[0]==2 && f[3]==8);
 _mm_storeu_ps(f,nine(a,a,a,a,a,a,a,a,a)); CHECK(f[0]==9 && f[3]==36);
#if !defined(_WIN32) || defined(_WIN64)
 variadic=(void *)GetProcAddress(dll,"peer_variadic");
 vcb=(void *)GetProcAddress(dll,"peer_var_callback"); CHECK(variadic && vcb);
 _mm_storeu_ps(f,variadic(9,a,a,a,a,a,a,a,a,a)); CHECK(f[0]==9 && f[3]==36);
 _mm_storeu_ps(f,vcb(var_callback)); CHECK(f[0]==9 && f[3]==36);
#endif
 _mm_storeu_ps(f,five(a,a,a,a,a,2)); CHECK(f[0]==7 && f[3]==22);
 _mm_storeu_ps(f,mixed(1,a,2.0,a,3)); CHECK(f[0]==8 && f[3]==14);
 _mm_storeu_ps(f,cb(callback)); CHECK(f[0]==8 && f[3]==23);
 _mm_storeu_pd(d,pd(_mm_set1_pd(2),_mm_setr_pd(3,4))); CHECK(d[0]==6 && d[1]==8);
 _mm_storeu_si128((__m128i *)n,pi(_mm_set1_epi32(5),_mm_set1_epi32(7))); CHECK(n[0]==12 && n[3]==12);
 CHECK(edges(dll)==0);
 FreeLibrary(dll); puts("SIMD external ABI and callback passed"); return 0;
}
