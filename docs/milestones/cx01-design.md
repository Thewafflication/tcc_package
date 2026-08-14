# CX1 Design — C99 `_Complex` Language Support

**Status:** Implemented and verified

**Date:** 2026-08-12

## Type Model

Reserve an unused `CType.t` bit as `VT_COMPLEX`. A complex type has basic type
`VT_STRUCT`, the complex flag, and a reference to one of three canonical
two-member internal aggregates. Central helpers identify complex types, obtain
the corresponding real type, and obtain the canonical result type.

Type comparison, spelling, declaration parsing, `sizeof`, alignment, pointer
derivation, `_Generic`, `typeof`, and diagnostics use the scalar complex
identity. Internal fields are not entered as user-visible members.

## Values and Constants

Extend constant storage with real and imaginary host `long double` components.
Tokenization distinguishes real floating tokens from GNU imaginary `i`/`j`
tokens while preserving macro token serialization. `__builtin_complex` creates
a result from two same-precision real operands without evaluating either more
than once or normalizing exceptional bit patterns.

Nonconstant complex values are addressable internal temporaries. A semantic
rvalue marker prevents internal addressability from making expressions such as
`&(a + b)` valid C lvalues.

## Conversion and Operations

Conversion helpers split a complex value into its two corresponding real
components exactly once. Real-to-complex supplies a positive or unsigned zero
imaginary component. Complex-to-real discards the imaginary component after
the source expression has been evaluated. `_Bool` combines comparisons of both
components.

The usual arithmetic conversion selects the widest corresponding real type
and a complex result if either operand is complex. Addition, subtraction,
negation, equality, and inequality operate component-wise. Multiplication and
division initially use reviewed finite-domain formulas and do not create an
Annex G claim; exceptional-value findings are retained for CX2 unless they
violate a CX1 requirement.

## Storage and Initialization

The internal aggregate has no padding beyond that of two adjacent real array
elements. Automatic results use aligned stack temporaries. Static initializers
write both component representations with the existing target-aware real
floating writers. Aggregate, array, member, pointer, qualified, and compound
assignment paths treat complex as scalar at the language boundary and as a
fixed two-part object only inside controlled helpers.

## Calls, Returns, and Variadic Access

The implementation first routes complex values through the target's aggregate
classifier and compares emitted behavior with the reference compiler. A target
where complex values have a distinct ABI class receives an explicit classifier,
pack/unpack, call, and return hook. AMD64 System V `long double _Complex` is a
known candidate for special handling.

Mixed-compiler tests build all four caller/callee combinations where tooling is
available. Variadic tests compare both direct reads and sentinel arguments so
register-save-area or stack-slot mistakes are observable.

## Diagnostics and Debug Information

Type strings use standard spellings. Invalid real-only, integer-only, or
aggregate-only operations reject complex operands before backend generation.
Debug metadata is inspected but does not block the first slice unless it
misrepresents object size or corrupts generated output; any representation gap
becomes a controlled finding.

## Failure and Rollback Behavior

No hidden fallback converts complex values to real. A missing target ABI path
fails clearly during compilation or a required test. Each slice remains
bisectable, and the superproject gitlink identifies the exact TinyCC baseline.

## Traceability

The controlled specifications in `docs/tests/cx01/` are authoritative.
Project-owned runners will include each test/requirement relationship in the
execution record and generated report.
