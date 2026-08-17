# TinyCC `_Complex` CX2 Requirements

**Document ID:** `TCC-CX-REQSET-0002`

**Status:** Approved continuation of the CX2 program scope

**Source:** ISO/IEC 9899:2011 clauses 7.3 and 7.25; DWARF base-type
encoding; CX1 residual risks

## TCC-CX-REQ-1001 — Hosted Header Surface

The Windows package shall provide `<complex.h>` with the C99 complex macros,
all three precision declarations for every function in clause 7.3, and the
C11 `CMPLX`, `CMPLXF`, and `CMPLXL` construction macros.

`imaginary` and `_Imaginary_I` shall not be defined while `_Imaginary` types
are unsupported.

**Verification:** `TC-1001` header, declaration, macro, and link coverage.

## TCC-CX-REQ-1002 — Basic Complex Functions

The hosted library shall implement `cabs`, `carg`, `creal`, `cimag`, `conj`,
and `cproj` in float, double, and long-double variants, preserving required
signed-zero and infinity behavior.

**Verification:** `TC-1002` value and representation checks.

## TCC-CX-REQ-1003 — Elementary Complex Functions

The hosted library shall implement all C99 complex exponential, logarithmic,
power, square-root, trigonometric, inverse-trigonometric, hyperbolic, and
inverse-hyperbolic functions in all three precisions. Finite representative
values shall agree with an independent oracle within the allocated tolerance.

**Verification:** `TC-1003` differential and identity corpus.

## TCC-CX-REQ-1004 — Exceptional Values

The hosted library shall implement the C-required special cases allocated by
the CX2 design for signed zero, infinity, and NaN. The test record shall
distinguish value classification and component sign.

**Verification:** `TC-1004` exceptional-value decision table.

## TCC-CX-REQ-1005 — Arithmetic Range Hardening

Nonconstant complex multiplication and division shall use runtime recovery
where direct textbook formulas produce spurious NaNs or overflow for finite
or infinite IEEE operands. Ordinary finite behavior and single evaluation
shall remain unchanged. Translation-time constant folding retains the CX1
language rules and is outside the CX2 Annex-G non-claim. Compiler-generated
helper calls and their separately compiled entries shall use the same target
calling convention.

**Verification:** `TC-1005` scaled, subnormal, infinite, side-effect, and
private helper-ABI cases.

## TCC-CX-REQ-1006 — Type-generic Math

`<tgmath.h>` shall select the corresponding complex function for complex
arguments and the existing real function for real arguments, including mixed
precision `pow` and `fabs`/`cabs` selection.

**Verification:** `TC-1006` compile-time type and runtime dispatch checks.

## TCC-CX-REQ-1007 — Debug Type Identity

DWARF output for each complex precision shall use a complex floating base type
with the correct byte size and standard spelling rather than exposing the
internal aggregate fields.

**Verification:** `TC-1007` debug-information inspection.

## TCC-CX-REQ-1008 — Integration and Regression

The CX1 suite, package builds, pinned musl integration, and upstream TinyCC
tests shall continue to pass after CX2. Native execution claims remain limited
to available hosts.

**Verification:** `TC-1008` package and upstream regression matrix.
