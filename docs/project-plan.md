# TinyCC `_Complex` Implementation Program

**Document ID:** `TCC-CX-PLAN-0001`

**Status:** CX1 and CX2 completed

## Objective

Add C99 `_Complex` language support to TinyCC without regressing existing
targets, while preserving the representation and calling conventions expected
by C implementations that interoperate with TinyCC.

## Scope Boundary

CX1 includes:

- `float _Complex`, `double _Complex`, and `long double _Complex`;
- object representation, type identity, qualifiers, pointers, arrays, and
  `sizeof`/alignment;
- real/complex and complex/complex conversions;
- initialization, assignment, truth testing, equality, unary operations, and
  `+`, `-`, `*`, `/` including compound assignment;
- the usual arithmetic conversions;
- automatic and static storage;
- function arguments, returns, and variadic access;
- GNU imaginary floating suffixes and `__builtin_complex` needed by prevalent
  `<complex.h>` implementations; and
- compilation of the musl complex subsystem plus upstream regression tests.

CX1 excludes `_Imaginary` types, an IEC 60559 Annex G conformance claim,
implementation of the complete complex transcendental library on Windows, and
native ARM64 execution that is unavailable on the current host. Those items
remain visible follow-up work rather than silent fallbacks.

## Milestones

| Milestone | Outcome | Exit gate |
| --- | --- | --- |
| CX0 | Process, baseline, requirements, design, and tests are reviewable | Maintainer approves scope and representation decision |
| CX1 | C99 `_Complex` compiler-language implementation | Controlled tests, ABI oracles, musl compilation, and upstream regressions pass |
| CX2 | Hosted library and exceptional-value hardening | `TC-1001` through `TC-1008` and the regression matrix pass |

CX1 met its exit gate on 2026-08-13. See
`docs/milestones/cx01-verification.md` for the verified matrix and explicit
non-claims.

CX2 met its exit gate on 2026-08-13. See
`docs/milestones/cx02-verification.md` for its verified matrix and remaining
non-claims.

## Dependencies

- TinyCC `mob` commit `2ba12e83b3599ca8f5d50c179fe5138fe956f0c9`;
- WSP commit `2198ccab08f969a789448767fe7017b774369adc`;
- WG14 N1570 clauses 6.2.5, 6.3.1.6–8, 6.5, 6.7.2, and 7.3;
- the applicable i386, AMD64, Microsoft x64, and AAPCS64 calling conventions;
- GCC as the native Linux semantic and ABI oracle where available; and
- the existing Windows x86, x64, and ARM64 package build paths.

## Risks and Controls

| Risk | Control |
| --- | --- |
| Scalar semantics leak from an aggregate lowering | Dedicated type flag, centralized predicates, negative lvalue/operator tests |
| ABI differs from an ordinary two-field aggregate | Per-target oracle objects and explicit ABI hooks, especially AMD64 `long double _Complex` |
| Operand side effects are evaluated more than once | Materialize each complex operand once before component operations |
| Static initializers lose imaginary data or signed zero | Paired constant representation and byte-level initializer tests |
| Multiply/divide mishandle exceptional values | Do not claim Annex G in CX1; retain signed-zero/NaN/Inf cases as CX2 gates unless required for core correctness |
| Front-end change regresses non-complex types | Full upstream suite plus source review of shared conversion/operator paths |
| Cross-target output builds but violates ABI | Mixed-compiler caller/callee tests and object inspection; no execution claim for unavailable hardware |
| Feature scope grows into a math library | Enforce the CX1 language/library boundary and create CX2 requirements for library work |

## CX1 Forecast

The initial planning estimate is 180,000 working tokens: 22k baseline/plan,
18k specify, 25k design, 70k implement, 15k review, 25k verify/evidence, and 5k
close. This is a forecast for maintainer approval, not a completion shortcut.
A forecast above 216,000 tokens requires replanning before further expansion.

## Rollback

The feature is isolated to the TinyCC submodule, project-owned documentation,
and test automation. Rollback restores the pinned TinyCC gitlink and removes
CX1-owned CTest registrations; it does not alter installed compilers or
published packages.

## Program Exit

The program can represent `_Complex` as implemented only after CX1 closes.
The Windows hosted C99 complex-library surface is complete after CX2. Full
IEC 60559 Annex G conformance remains a separate, explicitly named claim.
