# CX1 Findings Log

**Status:** Closed; CX2 follow-up resolved

## CX0-F-0001 — Empty-runner traceability validation

**Phase injected:** CX0 verification setup

**Phase detected:** CX0 planning review

**Severity:** Low

**Status:** Resolved

`wsp/tools/Test-Traceability.ps1` rejects an empty test-implementation file
array before it applies `-AllowManualTests`. The proposed CX1 package has no
runner by design before the implementation gate, so the common tool cannot yet
perform its normal end-to-end check.

A direct audit found ten canonical requirements, ten allocation records, seven
test specifications, and no missing allocation or test back-reference. Slice
1 added the first automated runner, after which the normal WSP tool passed for
ten requirements, seven specifications, and one implementation.

## CX0-F-0002 — WSL configure line endings

**Phase injected:** Existing TinyCC checkout

**Phase detected:** CX0 baseline

**Severity:** Medium

**Status:** Resolved

The WSL shell cannot execute the checked-out CRLF `tinycc/configure` script.
The CX1 runner will create a normalized, ignored source copy under `out/` and
record its provenance. It must not edit the controlled submodule merely to
prepare a Linux build.

The final Linux build and regression runs used the normalized ignored source
copy. The controlled TinyCC submodule files were not rewritten for the host.

## CX0-F-0003 — Bare `_Complex` planning error

**Phase injected:** CX0 requirements

**Phase detected:** Slice 1 oracle preparation

**Severity:** Medium

**Status:** Resolved

The proposed `TCC-CX-REQ-0001` incorrectly referred to an omitted `double`
specifier. A strict C11 GCC oracle accepts `float _Complex`,
`double _Complex`, and `long double _Complex` in either order, but rejects
bare `_Complex` and `long _Complex`. The requirement was corrected before
production implementation and the rejected forms remain negative tests.

## CX1-F-0004 — Direct `float _Complex` return corruption

**Phase injected:** Slice 5 ABI lowering

**Phase detected:** Slice 5 mixed-compiler verification

**Severity:** High

**Status:** Resolved

A direct constant return could be ABI-retyped before both components were
materialized. Materializing the complex value before return classification
fixed the corruption. Native and mixed-compiler x86/x64 return tests pass.

## CX1-F-0005 — System V `long double _Complex` return class

**Phase injected:** Slice 5 generic aggregate routing

**Phase detected:** Slice 5 GCC ABI oracle

**Severity:** High

**Status:** Resolved

The generic aggregate return path did not implement the System V x87/x87up
result convention. An explicit AMD64 System V transfer hook now returns the
real and imaginary components through the expected x87 registers. Both GCC to
TinyCC and TinyCC to GCC directions pass.

## CX1-F-0006 — ARM64 complex truth-test nontermination

**Phase injected:** Slice 3 scalar truth lowering

**Phase detected:** ARM64 package verification

**Severity:** High

**Status:** Resolved

Register allocation could cycle while directly lowering the two-component
truth expression. Complex truth now lowers to inequality with complex zero,
which shares the reviewed equality path and terminates on all package targets.

## CX1-F-0007 — x87 conversion component reversal

**Phase injected:** Slice 3 precision conversion

**Phase detected:** Linux native conversion verification

**Severity:** High

**Status:** Resolved

Converting `float _Complex` to `long double _Complex` left both components on
the x87 stack in an order that reversed the result. The real component is now
converted and spilled before the imaginary component. Native and
mixed-compiler Linux tests pass.

## CX1-F-0008 — Complex increment/decrement accepted

**Phase injected:** Existing shared increment lowering

**Phase detected:** Final operator constraint review

**Severity:** Medium

**Status:** Resolved

Prefix and postfix increment/decrement reached the generic add-and-store path
even though C restricts those operators to real and pointer operands. The
front end now rejects complex operands, and the negative operator suite passes
on x86, x64, and ARM64.

## CX1-F-0009 — Debug type identity uses the internal aggregate

**Phase injected:** Slice 1 aggregate-backed representation

**Phase detected:** Final source review

**Severity:** Low

**Status:** Resolved by CX2

The current debug-information path describes a complex object through its
anonymous two-field internal aggregate rather than a dedicated complex base
type. Object size and generated code remain correct, and CX1 contains no
debugger presentation requirement. CX2 now emits a dedicated
`DW_ATE_complex_float` base type, verified by `TCC-CX-TC-1007`.
