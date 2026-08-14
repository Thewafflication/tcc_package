# CX1 Verification and Closeout

**Status:** Pass

**Date:** 2026-08-13

**Branch:** `complex_numbers`

**TinyCC baseline:** `2ba12e83b3599ca8f5d50c179fe5138fe956f0c9`

## Verified Result

CX1 implements the C99 compiler-language portion of `_Complex` for `float`,
`double`, and `long double`: types and layout, constants and construction,
conversions and truth, operators, storage, calls and returns, variadic access,
and the target ABI paths in the approved matrix.

GNU imaginary `i`/`j` suffixes and `__builtin_complex` are included only as
the compatibility surface required to compile an unmodified prevalent
`<complex.h>` implementation. No broader GNU complex-language claim is made.

## Final Matrix

| Target | Result | Evidence |
| --- | --- | --- |
| Windows x86 | Pass, 7/7 CTest groups | Native semantic, package, and mixed-compiler ABI runs under `out/test-evidence/cx01/` |
| Windows x64 | Pass, 7/7 CTest groups | Native semantic, package, and mixed-compiler ABI runs under `out/test-evidence/cx01/` |
| Windows ARM64 | Pass, 7/7 applicable CTest groups | Compile and object/ABI inspection; not labeled native execution |
| Linux x86-64 | Pass | Native and GCC-oracle checks, musl build, and upstream `make test` evidence |

The pinned musl revision
`f21a96538f78fa8e2040831b4209b35f2fb581da` force-built all 68 sources under
`src/complex` with TinyCC. Its unmodified `<complex.h>` probe passed. The final
TinyCC upstream Linux suite reported `ALL TESTS PASSED`.

Traceability passed for 10 requirements, 7 controlled test specifications,
and 7 automated implementations. The WSP common-tool self-test suite passed,
as did PowerShell and shell syntax checks and the 100-column source check for
the CX1 test implementation.

## Review Disposition

All material findings are resolved and rerun. The only deferred item is the
low-severity debugger type-presentation follow-up in `CX1-F-0009`; it does not
affect object representation, execution, or a CX1 requirement.

## Explicit Non-claims

CX1 does not implement `_Imaginary`, a complete Windows complex math library,
or IEC 60559 Annex G behavior. ARM64 execution was unavailable on this host,
so the closeout claims cross-compilation and ABI inspection only for that
target. These boundaries remain CX2 work and are not silent fallbacks.
