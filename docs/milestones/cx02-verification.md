# CX2 Verification and Closeout

**Status:** Pass

**Date:** 2026-08-13

**Branch:** `complex_numbers`

**TinyCC baseline:** `2ba12e83b3599ca8f5d50c179fe5138fe956f0c9`

**WSP baseline:** `2198ccab08f969a789448767fe7017b774369adc`

## Verified Result

CX2 completes `TCC-CX-REQ-1001` through `TCC-CX-REQ-1008`. The Windows
package provides the complete C99 clause 7.3 function family in float, double,
and long-double forms, together with the C11 `CMPLX` construction macros.

Nonconstant complex multiply and divide operations use range-aware runtime
helpers. The hosted functions cover allocated finite and exceptional cases,
`<tgmath.h>` selects complex functions including mixed `pow`, and DWARF uses
`DW_ATE_complex_float` base types instead of exposing internal fields.

## Final Matrix

| Target | Result | Evidence |
| --- | --- | --- |
| Windows x86 | Pass, 15/15 CTest groups | Native CX1 regression and CX2 `TC-1001` through `TC-1008` |
| Windows x64 | Pass, 15/15 CTest groups | Native CX1 regression and CX2 `TC-1001` through `TC-1008` |
| Windows ARM64 | Pass, 15/15 applicable groups | Compile, link, package, and object inspection; no native execution claim |
| Linux x86-64 | Pass | Hardened arithmetic, type-generic runtime, DWARF inspection, and upstream suite |
| musl x86-64 | Pass | All 68 pinned complex sources rebuilt with the final compiler |

The final three Windows targets were executed concurrently after evidence IDs
were made process-unique; all 45 groups passed. The Linux upstream suite
reported `ALL TESTS PASSED`. The pinned musl revision
`f21a96538f78fa8e2040831b4209b35f2fb581da` rebuilt 68 complex objects.

Linux DWARF inspection found complex-float encoding 3 at 8, 16, and 32 bytes
for float, double, and native long double. Windows object inspection found the
expected 8- and 16-byte encodings for its double-width long-double ABI.

## Quality Gates

Traceability passes for 18 requirements, 15 controlled specifications, and 15
automated implementations. The WSP common-tool self-tests, PowerShell parser
checks, shell syntax checks, C source width check, and root/submodule whitespace
checks pass. All eight recorded CX2 findings are resolved and rerun.

## Explicit Non-claims

CX2 does not implement `_Imaginary`, `imaginary`, or `_Imaginary_I`. It does
not claim full IEC 60559 Annex G conformance, signaling-NaN semantics, or
floating-point exception flags. Translation-time exceptional constant folding
retains the CX1 rules and is not represented as Annex-G hardened.

ARM64 execution was unavailable on this host. ARM64 closeout therefore claims
successful compiler/package generation and object-level inspection only.

## Post-release correction — rc.1443

The selected WCRT ARM64 integration exposed a private helper-ABI mismatch that
the original compile-only operator gate did not inspect. TinyCC now represents
`__tcc_muldc3`, `__tcc_divdc3`, `__tcc_mulxc3`, and `__tcc_divxc3` with their
complete prototypes during lowering. The extended `TC-1005` gate checks the
ARM64 PE register assignments in generated objects, and upstream test 149
executes all three complex precisions through multiplication and division.
