#include <emmintrin.h>
#include <stdarg.h>
#ifdef _MSC_VER
#define EXPORT __declspec(dllexport)
#elif defined(_WIN32)
#define EXPORT __attribute__((dllexport))
#else
#define EXPORT
#endif
EXPORT __m128 peer_five(__m128 a,__m128 b,__m128 c,__m128 d,__m128 e,int n)
{ return _mm_add_ps(_mm_add_ps(a,b),_mm_add_ps(_mm_add_ps(c,d),_mm_add_ps(e,_mm_set1_ps((float)n)))); }
EXPORT __m128 peer_mixed(int n,__m128 a,double d,__m128 b,int k)
{ return _mm_add_ps(_mm_add_ps(a,b),_mm_set1_ps((float)(n+d+k))); }
EXPORT __m128d peer_double(__m128d a,__m128d b) { return _mm_mul_pd(a,b); }
EXPORT __m128i peer_integer(__m128i a,__m128i b) { return _mm_add_epi32(a,b); }
typedef __m128 (*callback)(__m128,__m128,__m128,__m128,__m128,int);
EXPORT __m128 peer_callback(callback f)
{ __m128 a=_mm_setr_ps(1,2,3,4); return f(a,a,a,a,a,3); }
EXPORT __m128 peer_nine(__m128 a,__m128 b,__m128 c,__m128 d,__m128 e,
                      __m128 f,__m128 g,__m128 h,__m128 i)
{ return _mm_add_ps(peer_five(a,b,c,d,e,0),_mm_add_ps(_mm_add_ps(f,g),_mm_add_ps(h,i))); }
#if !defined(_WIN32) || defined(_WIN64)
EXPORT __m128 peer_variadic(int n,...)
{
    va_list ap; __m128 r=_mm_setzero_ps(); int i;
    va_start(ap,n);
    for(i=0;i<n;++i) r=_mm_add_ps(r,va_arg(ap,__m128));
    va_end(ap); return r;
}
typedef __m128 (*var_callback)(int,...);
EXPORT __m128 peer_var_callback(var_callback f)
{ __m128 a=_mm_setr_ps(1,2,3,4); return f(9,a,a,a,a,a,a,a,a,a); }
#endif
struct vector_box { __m128 v; };
EXPORT struct vector_box peer_box(struct vector_box a)
{ a.v=_mm_add_ps(a.v,a.v); return a; }
EXPORT struct vector_box peer_box_callback(struct vector_box (*f)(struct vector_box))
{ struct vector_box a; a.v=_mm_setr_ps(1,2,3,4); return f(a); }
#include "abi-edges.h"
EXPORT struct vector_array peer_array(struct vector_array a) { return a; }
EXPORT struct vector_pair peer_pair(struct vector_pair a) { __m128 t=a.v[0]; a.v[0]=a.v[1]; a.v[1]=t; return a; }
EXPORT union vector_union peer_union(union vector_union a) { return a; }
EXPORT union vector_integer peer_vi(union vector_integer a) { return a; }
EXPORT struct mixed_si peer_si(struct mixed_si a) { a.i+=7; a.d+=2; return a; }
EXPORT struct mixed_is peer_is(struct mixed_is a) { a.i+=7; a.d+=2; return a; }
EXPORT struct packed_vector peer_packed(struct packed_vector a) { a.c++; return a; }
EXPORT struct mixed_si peer_si_callback(struct mixed_si (*f)(struct mixed_si))
{ struct mixed_si a; a.d=2; a.i=3; return f(a); }
EXPORT __m64 peer_mmx5(__m64 a,__m64 b,__m64 c,__m64 d,__m64 e)
{
    union { __m64 m; unsigned v[2]; } x,y,z,w,t;
    x.m=a; y.m=b; z.m=c; w.m=d; t.m=e;
    x.v[0]+=y.v[0]+z.v[0]+w.v[0]+t.v[0];
    x.v[1]+=y.v[1]+z.v[1]+w.v[1]+t.v[1];
    return x.m;
}
EXPORT __m64 peer_mmx_callback(__m64 (*f)(__m64,__m64,__m64,__m64,__m64))
{ union { __m64 m; int v[2]; } a; a.v[0]=1; a.v[1]=2; return f(a.m,a.m,a.m,a.m,a.m); }
EXPORT struct mixed_si peer_exhaust(int a,int b,int c,int d,int e,int f,struct mixed_si v,double last)
{ v.i+=a+b+c+d+e+f; v.d+=last; return v; }
#if !defined(_WIN32) || defined(_WIN64)
EXPORT struct mixed_si peer_va_mixed(int n,...)
{
 va_list ap, copy; struct mixed_si r={0,0}, a, b; int k;
 va_start(ap,n); va_copy(copy,ap);
 for(k=0;k<n;++k) { a=va_arg(ap,struct mixed_si); b=va_arg(copy,struct mixed_si);
   if(a.d!=b.d || a.i!=b.i) { r.i=-999; break; }
   r.d+=a.d; r.i+=a.i;
 }
 va_end(copy); va_end(ap); return r;
}
EXPORT struct mixed_si peer_va_callback(struct mixed_si (*f)(int,...))
{ struct mixed_si a; a.d=2; a.i=3; return f(9,a,a,a,a,a,a,a,a,a); }
#endif
