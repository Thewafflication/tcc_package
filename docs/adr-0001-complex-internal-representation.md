# ADR-0001: Represent Complex Scalars with Flagged Two-Element Aggregates

**Content type:** Architecture decision record

**Status:** Accepted on 2026-08-12

**Date:** 2026-08-12

## Context

TinyCC encodes a type in `CType` and a current expression value in `SValue`.
`SValue` and each backend are optimized for one scalar register, with limited
two-register support for selected ABI types. Implementing complex values as a
new paired register scalar would require coordinated changes to every load,
store, spill, arithmetic, call, return, and constant path.

The C standard requires each complex type to have the representation and
alignment of an array of two corresponding real values, real part first.
TinyCC already has mature aggregate storage and ABI classification paths.

## Decision Drivers

- Preserve standard object representation and pointer aliasing behavior.
- Reuse existing cross-target aggregate call/return machinery where ABI rules
  agree.
- Keep arithmetic and conversion policy in the common front end.
- Make the type distinguishable from a user structure and retain scalar C
  semantics.
- Permit explicit target hooks for ABIs with a special complex class.

## Considered Options

1. A flagged internal two-element aggregate with scalar front-end semantics.
2. A new paired-register `SValue` representation implemented in every backend.
3. Lower all operations to opaque runtime helper calls.

## Decision

Represent each complex type internally as `VT_STRUCT | VT_COMPLEX` referring to
a canonical two-field aggregate of the corresponding real type. Reserve a
previously unused `CType.t` flag for `VT_COMPLEX`. Central predicates and
constructors own all recognition; user code cannot name the internal fields.

Constants retain two host `long double` components. Nonconstant complex
results are materialized once into aligned temporaries, and common front-end
code performs component conversions and operations with existing real scalar
generators. Aggregate storage and ABI classification are reused only after an
oracle confirms the target rule. A target with a special complex ABI class
receives an explicit hook rather than being forced through the aggregate path.

## Consequences

### Positive

- Common implementation covers storage and most target ABIs.
- Layout follows the standard by construction.
- Arithmetic changes remain largely backend-independent.
- Existing aggregate copy and temporary-lifetime machinery is reused.

### Negative

- Every generic `VT_STRUCT` check must be reviewed for complex scalar behavior.
- Materialized temporaries may generate less efficient code than a dedicated
  paired-register representation.
- AMD64 System V `long double _Complex` and any other special classes require
  target-specific treatment.
- Semantic lvalue rules need an explicit distinction from internal addressable
  temporaries.

### Follow-up

- Prove classification with mixed GCC/TinyCC caller and callee tests.
- Add a semantic-rvalue marker or equivalent guard for addressability tests.
- Revisit register pairing only after correctness and ABI evidence establish a
  performance need.

## References

- `TCC-CX-REQ-0002`, `TCC-CX-REQ-0006`, and `TCC-CX-REQ-0007`
- WG14 N1570 6.2.5 paragraph 13
- TinyCC `CType`, `SValue`, aggregate assignment, and `gfunc_sret` paths
