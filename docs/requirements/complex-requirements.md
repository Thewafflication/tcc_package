# TinyCC `_Complex` Requirements

**Document ID:** `TCC-CX-REQSET-0001`

**Status:** Approved for CX1 implementation on 2026-08-12

**Source:** ISO/IEC 9899:1999 as corrected, reflected by WG14 N1256 and N1570;
TinyCC/musl compatibility objective

## TCC-CX-REQ-0001 — Complex Type Specifiers

TinyCC shall accept and distinguish `float _Complex`, `double _Complex`, and
`long double _Complex`, including the permitted ordering of their specifiers,
while diagnosing incomplete or invalid specifier combinations.

**Verification:** `TC-0001` syntax, type-compatibility, and negative tests.

## TCC-CX-REQ-0002 — Representation and Alignment

Each supported complex type shall have the size, alignment, and ordered object
representation of exactly two elements of its corresponding real type, with
the real part first and imaginary part second.

**Verification:** `TC-0001` compile-time assertions and byte-level inspection.

## TCC-CX-REQ-0003 — Construction and Constants

TinyCC shall construct complex values without losing NaNs, infinities, or the
sign of zero, and shall support the imaginary floating suffix and
`__builtin_complex` forms required by the targeted system `<complex.h>`
headers.

**Verification:** `TC-0002` constant and object-byte cases.

## TCC-CX-REQ-0004 — Conversions and Scalar Conditions

TinyCC shall implement complex-to-complex, real-to-complex, and
complex-to-real conversions according to the corresponding real conversions.
Conversion to `_Bool` and conditional testing shall be false only when both
components compare equal to zero.

**Verification:** `TC-0003` equivalence partitions across all real and complex
precisions, zero signs, and conditional contexts.

## TCC-CX-REQ-0005 — Operators

TinyCC shall apply the usual arithmetic conversions and implement unary `+`
and `-`, binary `+`, `-`, `*`, and `/`, equality and inequality, logical
operators, the conditional operator, simple assignment, and the corresponding
compound assignments for complex operands. Operators constrained to real or
integer operands shall reject complex operands.

**Verification:** `TC-0004` table-driven semantic oracle and negative
constraints.

## TCC-CX-REQ-0006 — Objects and Initialization

TinyCC shall correctly create, initialize, copy, address, dereference, index,
qualify, and store complex automatic, static, array, aggregate-member, and
pointer-designated objects without evaluating a source expression more than
once.

**Verification:** `TC-0002` storage-duration, aliasing, side-effect, and
initializer tests.

## TCC-CX-REQ-0007 — Function and Variadic ABI

For each claimed target, TinyCC shall pass and return every supported complex
type, including nested calls and applicable variadic access, according to that
target's C ABI and shall interoperate with the designated reference compiler.

**Verification:** `TC-0005` mixed-compiler caller/callee and object-classification
tests for x86, x64, ARM64, and native x86-64 Linux.

## TCC-CX-REQ-0008 — Diagnostics and Type Introspection

TinyCC shall print meaningful complex type names, support complex types in
`sizeof`, alignment, `typeof`, `_Generic`, and
`__builtin_types_compatible_p`, and issue stable diagnostics for invalid
declarations, casts, operands, or initializers.

**Verification:** `TC-0001` positive and negative introspection cases.

## TCC-CX-REQ-0009 — Regression and Target Matrix

The feature shall build with the supported package toolchains and shall not
cause a required pre-existing TinyCC regression test to fail. Evidence shall
distinguish native execution, emulation, cross-execution, and build-only
results.

**Verification:** `TC-0007` package builds and upstream regression suites.

## TCC-CX-REQ-0010 — Musl Compatibility

The implemented compiler shall compile musl's `<complex.h>` consumers and
complex source subsystem without an `_Complex`, imaginary-literal,
construction, operator, initializer, or function-ABI compiler failure.
Unrelated musl build failures shall remain recorded as separate findings.

**Verification:** `TC-0006` pinned musl compile procedure and failure triage.

## Explicit Non-Claims

CX1 does not implement `_Imaginary`, does not claim IEC 60559 Annex G
conformance, and does not claim that the Windows package supplies every C99
complex transcendental function. These exclusions require new controlled
requirements before implementation.
