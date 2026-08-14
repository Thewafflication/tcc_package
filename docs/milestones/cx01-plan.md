# CX1 Plan — C99 `_Complex` Language Support

**Milestone:** CX1

**Status:** Completed and verified as of 2026-08-13

**Baseline:** TinyCC `2ba12e83b3599ca8f5d50c179fe5138fe956f0c9` and WSP
`2198ccab08f969a789448767fe7017b774369adc`

## Objective and Scope

Implement `TCC-CX-REQ-0001` through `TCC-CX-REQ-0010` within the boundary in
`docs/project-plan.md`. The implementation is a compiler-language milestone;
the complete Windows complex math library and Annex G are not included.

## Deliverables

1. Reviewed type, constant, conversion, operator, storage, and ABI changes in
   the TinyCC submodule.
2. Controlled `TCC-CX-TC-0001` through `TCC-CX-TC-0007` specifications and automated
   procedures.
3. CTest dispatch with preserved execution evidence and traceability checks.
4. Windows x86/x64 execution, ARM64 build/ABI evidence, Linux x86-64 oracle
   evidence, and musl subsystem compilation.
5. Requirements/design/source/test review, findings log, and closeout record.

## Implementation Slices

| Slice | Content | Required gate before next slice |
| --- | --- | --- |
| 1 | Type flag, canonical types, parser, printing, size/alignment | TCC-CX-TC-0001 type and layout subset |
| 2 | Paired constants, imaginary suffix, construction, initialization | TCC-CX-TC-0002 constant/static subset |
| 3 | Conversions, truth, equality, conditional behavior | TCC-CX-TC-0003 |
| 4 | Arithmetic and compound assignment | TCC-CX-TC-0004 finite/reference corpus |
| 5 | Calls, returns, varargs, target ABI exceptions | TCC-CX-TC-0005 per available matrix entry |
| 6 | Musl compile, upstream regressions, package matrix | TCC-CX-TC-0006/0007 |

## Review

Review covers every generic `VT_STRUCT`, `is_float`, conversion, initializer,
condition, function-call, return, vararg, debug-type, and token-serialization
path affected by the new flag. Findings record severity, injection/removal
phase, resolution, and rerun evidence.

## Verification Matrix

| Target | Host | Required CX1 evidence |
| --- | --- | --- |
| Windows x86 | Windows x64 bootstrap, native WOW64 execution | Build, controlled execution, ABI |
| Windows x64 | Windows x64 | Build, controlled execution, ABI |
| Windows ARM64 | Windows x64 cross compiler | Build and object/ABI inspection; native result remains Not run |
| Linux x86-64 | WSL x86-64 | Native controlled tests, GCC oracle, upstream suite |

## Exit Criteria

CX1 exits only when every requirement has an applicable passed test, no
material review finding is unresolved, Windows x86/x64 and Linux x86-64 native
gates pass, ARM64 build/inspection passes without being mislabeled native,
musl's complex subsystem compiles, and all required upstream regressions pass.

The milestone cannot close until the product owner approves the CX1 scope,
explicit non-claims, and ADR-0001.

The scope, explicit non-claims, and ADR-0001 were approved before
implementation. Final results and evidence are recorded in
`docs/milestones/cx01-verification.md`.
