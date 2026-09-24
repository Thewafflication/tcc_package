# x86 SIMD support

TinyCC now supports 128-bit SIMD C values and the SSE/SSE2 intrinsic interfaces
on i386 and x86-64. SSE2 is the compatibility priority because it is part of
the x86-64 baseline and is available on many older 32-bit CPUs. Generated SIMD
code requires the corresponding CPU and OS support; there is no automatic
runtime dispatch or auto-vectorization.

This page describes implemented support. SSE3/SSSE3, SSE4, AVX-family
intrinsics, and ARM64 NEON/SVE are planned in the
[SIMD expansion roadmap](simd-roadmap.md). An ARM64 package build does not
currently imply an ARM SIMD intrinsic interface.

## C types, intrinsics and ABI

`<xmmintrin.h>` defines `__m128`; `<emmintrin.h>` additionally defines `__m128d`
and `__m128i`. They are distinct, 16-byte-sized, 16-byte-aligned compiler types.
`<mmintrin.h>` supplies the 8-byte-sized, 8-byte-aligned `__m64` type and MMX
interfaces, including the MMX forms used by SSE/SSE2 and legacy `_m_*` aliases.
Assignments, initialization, arrays, struct members, explicit vector bit casts,
function pointers and vector returns are supported. i386 local storage is
aligned at runtime even when the caller's stack is only four-byte aligned.
Use intrinsics to operate on lanes: GCC `vector_size`, vector subscripting and
C arithmetic operators on vectors are not implemented.

The headers cover constructors, aligned and unaligned loads/stores, packed and
scalar arithmetic, square roots, approximate reciprocals, comparisons, logical
operations, shuffles, integer wrapping/saturating arithmetic, packing/unpacking,
shifts, multiplication, conversions, masks, MXCSR, fences, streaming vector
stores and masked stores. COMI/UCOMI results, word insertion/extraction, cache
control, aligned allocation, transpose and convenience load/store forms are
included. Immediate shuffles require compile-time values in 0..255; extraction
and insertion require valid lane indices. Scalar-count shifts accept runtime
counts. Generic comparison intrinsics accept the eight SSE predicates (0..7).
Arguments are evaluated once. Scalar forms preserve the
upper lanes where the instruction requires it. The internal checked primitive
`__builtin_tcc_simd` shares its operation catalogue with the installed headers.

Values remain addressable in compiler-managed storage; builtins emit native
SSE/SSE2 instructions. Assignments of 128-bit vector values use a vector
load/store pair instead of a general structure copy (bounds-checked builds
retain the checked copy path). `_mm_load_si128`, `_mm_subs_epu16`, and
`_mm_store_si128` expand at the call site, removing wrapper calls from the
SSE2 hash-slide loop in issue #4. Each argument is evaluated once; taking
their addresses or using parenthesized calls still uses the function forms.
Other wrappers can still introduce calls. Vector temporaries remain in
memory; this does not add register allocation across intrinsic operations
or impose SSE2 on scalar-only i386 code. Callers retain responsibility for
CPU/OS feature checks.
MMX temporaries are stored to memory and followed by EMMS when no live MMX
register values are needed, allowing ordinary C scalar arithmetic to use x87.
COMI/UCOMI use ordered comparisons: unordered equality/less/less-equal are
false and unordered inequality is true, consistent with current Clang headers.

The supported call paths are:

- Windows x64: vector parameters passed by reference and returns in XMM0.
- Windows i386 cdecl: the first three vector parameters in XMM0–XMM2, excess
  vector parameters by reference, and returns in XMM0. Vector arguments require
  a non-variadic prototype; other conventions are diagnosed.
- System V x86-64: up to eight XMM argument registers, aligned stack overflow,
  XMM0 returns, and vector varargs occupying one full XMM save slot. Single
  vector aggregate wrappers retain the SSE/SSEUP classification. Mixed
  integer/SSE structs and unions use both register banks, with whole-argument
  stack fallback when either bank is exhausted. Mixed varargs preserve va_copy.
- System V i386: vector register arguments and aligned stack overflow are
  tested against GCC, including aggregate callbacks and vector varargs.
  Cdecl outgoing stacks are aligned even for calls without vector parameters.

MMX arguments use MM0–MM2 on i386, XMM registers on System V x86-64, and
integer registers on Windows x64. Windows packed vector members retain their
natural alignment to match MSVC layout.

Windows x64 and System V x86-64 vector varargs are tested in both directions.
Windows i386 vector varargs are rejected, matching MSVC's inability to compile
that interface. `__vectorcall` and i386 SIMD conventions other than cdecl are
not implemented. This does not claim complete coverage of every aggregate ABI.

SIMD inline assembly supports `x`, `+x`, early-clobber and matching constraints
for these 128-bit types and scalar floats/doubles, plus explicit XMM register
variables and XMM clobbers. XMM6–XMM15 are preserved when used or clobbered on
Windows x64. MMX inline-assembly constraints are not implemented.

Header coverage is tracked against Clang 19 public MMX/SSE/SSE2 names in
`tests/simd/header-interfaces.json`, with compile coverage of 406 wrappers.
PREFETCHW hints and AVX comparison predicates are outside this milestone;
GCC vector extensions and unaligned vector typedef aliases are not provided.

## Assembler

Both x86 backends share `tinycc/x86-simd-asm.h`. Supported forms include
packed/scalar floating-point operations, conversions, integer operations,
shuffles, streaming and masked stores, all eight named comparison predicates,
MXCSR, prefetch, cache-line flush and fences. i386 supports XMM0–XMM7 and x86-64
supports XMM0–XMM15, including extended-register and indexed addressing.
Invalid register banks, widths and immediate ranges are diagnosed.

This fixes the old `rcpss` encoding, missing SSE2 prefixes on XMM `pavgb`/`pavgw`,
and mandatory-prefix ordering before REX on 64-bit scalar conversions.

## Verification

```powershell
cmake --preset x64-debug
cmake --build out/build/x64-debug --target tinycc
ctest --test-dir out/build/x64-debug -L simd --output-on-failure
```

Run these tests explicitly: the current GitHub packaging workflow builds
packages and verifies release signatures, but does not run the SIMD suites.
Adding required SIMD execution gates to CI is part of the roadmap.

CTest tests both named x86 cross-compilers in each package. The assembler tests
compare exact bytes and lengths against GNU assembler fixtures: 414 i386 and
665 x86-64 cases. Runtime tests cover alignment, lane preservation, immediate
zero and boundary counts, saturation, wrapping, NaNs, conversion rounding,
unaligned and masked memory operations, side effects and inline assembly.
Negative C tests check malformed builtins, incompatible types, nonconstant
immediates, const destinations and invalid clobbers.

The suite also checks nested hash-slide intrinsics, argument side effects,
function forms and vector assignments. `tests/simd/slide-hash.c` compares
scalar and SSE2 results across all unsigned 16-bit inputs, then prints timings
for the issue #4 workload on both x86 and x64. Only correctness gates the
test; timings are informational and depend on the host. To run it separately:

```powershell
out/build/x64-debug/package/x86_64-win32-tcc.exe tests/simd/slide-hash.c -o out/slide-hash-x64.exe
out/slide-hash-x64.exe
out/build/x64-debug/package/i386-win32-tcc.exe tests/simd/slide-hash.c -o out/slide-hash-x86.exe
out/slide-hash-x86.exe
```

Independent MSVC DLL tests cover vector parameters/returns, mixed scalar/vector
arguments, nine-vector calls, callbacks, vector arrays/unions, packed vectors,
mixed aggregates, MMX, register exhaustion and x64 varargs with va_copy.
They require Visual Studio C++ build tools. Test evidence is retained under
`out/test-evidence/simd` and `out/test-evidence/simd-abi`.

Run `python3 tests/simd/generate-fixtures.py` on Linux/WSL to regenerate the
assembler fixtures. `tests/simd/run-linux.sh` runs the C tests and GCC ABI
interop against an already-built native Linux TinyCC. Its optional fourth
argument selects `32` or `64` for the GCC peer (default `64`). The original
assembler execution test can skip unsupported CPUs; the C/ABI tests require
SSE2 and do not attempt to execute safely on pre-SSE2 systems.

## Next priorities

The proposed [SIMD expansion roadmap](simd-roadmap.md) covers SSE3/SSSE3,
SSE4, AVX/AVX2/FMA, and AVX-512, alongside ARM64 NEON and later SVE/SVE2.
It defines shared foundations, target-specific milestones, runtime feature
policy, ABI work, and validation/release gates.

Instruction definitions follow the
[Intel architecture manuals](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html).
