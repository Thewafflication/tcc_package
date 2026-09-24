#ifndef SIMD_ABI_EDGES_H
#define SIMD_ABI_EDGES_H
struct vector_array { __m128 v[1]; };
struct vector_pair { __m128 v[2]; };
union vector_union { __m128 v; double d[2]; };
union vector_integer { __m128 v; long long i; };
struct mixed_si { double d; long long i; };
struct mixed_is { long long i; double d; };
#pragma pack(push,1)
struct packed_vector { char c; __m128 v; };
#pragma pack(pop)
#endif
